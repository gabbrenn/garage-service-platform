package com.garageservice.controller;

import com.garageservice.dto.DailyReportEntry;
import com.garageservice.dto.DailyReportResponse;
import com.garageservice.model.Garage;
import com.garageservice.repository.GarageRepository;
import com.garageservice.repository.ServiceRequestRepository;
import com.garageservice.security.UserPrincipal;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.*;

@CrossOrigin(origins = "*", maxAge = 3600)
@RestController
@RequestMapping("/api/reports")
public class ReportController {

    @Autowired
    private ServiceRequestRepository serviceRequestRepository;

    @Autowired
    private GarageRepository garageRepository;

    @GetMapping("/daily")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> getDailyReport(
            Authentication authentication,
            @RequestParam(value = "from", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(value = "to", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to
    ) {
        DailyReportResponse response = buildDailyReport(authentication, from, to);
        if (response == null) {
            return ResponseEntity.badRequest().body(Collections.singletonMap("message", "No garage found for this user"));
        }
        return ResponseEntity.ok(response);
    }

    @GetMapping("/daily/export")
    @PreAuthorize("hasRole('GARAGE_OWNER')")
    public ResponseEntity<?> exportDailyReport(
            Authentication authentication,
            @RequestParam(value = "from", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam(value = "to", required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to,
            @RequestParam(value = "format", required = false, defaultValue = "csv") String format
    ) {
        DailyReportResponse response = buildDailyReport(authentication, from, to);
        if (response == null) {
            return ResponseEntity.badRequest().body(Collections.singletonMap("message", "No garage found for this user"));
        }
        if ("pdf".equalsIgnoreCase(format)) {
            byte[] pdf = buildPdf(response);
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, filename("pdf", response))
                    .contentType(MediaType.APPLICATION_PDF)
                    .body(pdf);
        } else { // csv default
            String csv = buildCsv(response);
            MediaType csvType = MediaType.parseMediaType("text/csv");
            return ResponseEntity.ok()
                    .header(HttpHeaders.CONTENT_DISPOSITION, filename("csv", response))
                    .contentType(csvType)
                    .body(csv);
        }
    }

    private DailyReportResponse buildDailyReport(Authentication authentication, LocalDate from, LocalDate to) {
        UserPrincipal principal = (UserPrincipal) authentication.getPrincipal();
        Optional<Garage> garageOpt = garageRepository.findByUserId(principal.getId());
        if (garageOpt.isEmpty()) {
            return null;
        }
        Garage garage = garageOpt.get();

        LocalDate toDate = to != null ? to : LocalDate.now();
        LocalDate fromDate = from != null ? from : toDate.minusDays(6); // default last 7 days
        if (fromDate.isAfter(toDate)) {
            return null;
        }

        LocalDateTime fromDateTime = fromDate.atStartOfDay();
        LocalDateTime toDateTime = toDate.atTime(LocalTime.MAX);

        List<Object[]> statusRows = serviceRequestRepository.findDailyStatusCounts(garage.getId(), fromDateTime, toDateTime);
        List<Object[]> etaRows = serviceRequestRepository.findDailyAverageEta(garage.getId(), fromDateTime, toDateTime);

        Map<LocalDate, Map<String, Long>> statusMap = new HashMap<>();
        for (Object[] row : statusRows) {
            LocalDate day = convertToLocalDate(row[0]);
            String status = String.valueOf(row[1]);
            Long count = toLong(row[2]);
            statusMap.computeIfAbsent(day, d -> new HashMap<>()).put(status, count);
        }

        Map<LocalDate, Double> etaMap = new HashMap<>();
        for (Object[] row : etaRows) {
            LocalDate day = convertToLocalDate(row[0]);
            Double avg = row[1] != null ? ((Number) row[1]).doubleValue() : null;
            etaMap.put(day, avg);
        }

        List<DailyReportEntry> entries = new ArrayList<>();
        LocalDate cursor = toDate;
        while (!cursor.isBefore(fromDate)) {
            Map<String, Long> counts = statusMap.getOrDefault(cursor, Collections.emptyMap());
            Map<String, Long> countsCopy = new HashMap<>(counts);
            Double avgEta = etaMap.get(cursor);
            entries.add(new DailyReportEntry(cursor, countsCopy, avgEta));
            cursor = cursor.minusDays(1);
        }

        Double overallAvgEta = serviceRequestRepository.findOverallAverageEta(garage.getId(), fromDateTime, toDateTime);
        long totalRequests = statusRows.stream().map(row -> toLong(row[2])).reduce(0L, Long::sum);

        return new DailyReportResponse(
                garage.getId(),
                fromDate,
                toDate,
                entries,
                overallAvgEta != null ? round(overallAvgEta, 2) : null,
                totalRequests
        );
    }

    private String buildCsv(DailyReportResponse r) {
        StringBuilder sb = new StringBuilder();
        int totalDays = r.getEntries().size();
        double avgPerDay = totalDays == 0 ? 0d : (double) r.getTotalRequests() / totalDays;
        sb.append("GARAGE DAILY REPORT\n");
        sb.append("Generated At,").append(java.time.OffsetDateTime.now()).append('\n');
        sb.append("Period Start,").append(r.getFrom()).append('\n');
        sb.append("Period End,").append(r.getTo()).append('\n');
        sb.append("Total Days,").append(totalDays).append('\n');
        sb.append("Total Requests,").append(r.getTotalRequests()).append('\n');
        sb.append("Avg Requests/Day,").append(String.format(java.util.Locale.US, "%.2f", avgPerDay)).append('\n');
        sb.append("Overall Avg ETA (min),").append(r.getOverallAverageEta() == null ? "" : r.getOverallAverageEta()).append('\n');
        sb.append('\n');
        sb.append("Date,PENDING,ACCEPTED,IN_PROGRESS,COMPLETED,REJECTED,CANCELLED,TOTAL,Avg ETA (min)\n");
        // ascending chronological order (oldest first)
        List<DailyReportEntry> ascending = new ArrayList<>(r.getEntries());
        ascending.sort(Comparator.comparing(DailyReportEntry::getDay));
        for (DailyReportEntry e : ascending) {
            long pending = e.getStatusCounts().getOrDefault("PENDING", 0L);
            long accepted = e.getStatusCounts().getOrDefault("ACCEPTED", 0L);
            long inProgress = e.getStatusCounts().getOrDefault("IN_PROGRESS", 0L);
            long completed = e.getStatusCounts().getOrDefault("COMPLETED", 0L);
            long rejected = e.getStatusCounts().getOrDefault("REJECTED", 0L);
            long cancelled = e.getStatusCounts().getOrDefault("CANCELLED", 0L);
            long total = pending + accepted + inProgress + completed + rejected + cancelled;
            sb.append(e.getDay()).append(',')
                    .append(pending).append(',')
                    .append(accepted).append(',')
                    .append(inProgress).append(',')
                    .append(completed).append(',')
                    .append(rejected).append(',')
                    .append(cancelled).append(',')
                    .append(total).append(',')
                    .append(e.getAverageEstimatedArrivalMinutes() == null ? "" : e.getAverageEstimatedArrivalMinutes())
                    .append('\n');
        }
        return sb.toString();
    }

    private byte[] buildPdf(DailyReportResponse r) {
        try (org.apache.pdfbox.pdmodel.PDDocument doc = new org.apache.pdfbox.pdmodel.PDDocument()) {
            final int marginLeft = 50;
            final int startY = 750;
            final float leading = 14f;
            org.apache.pdfbox.pdmodel.PDPage page = new org.apache.pdfbox.pdmodel.PDPage();
            doc.addPage(page);
            org.apache.pdfbox.pdmodel.PDPageContentStream cs = new org.apache.pdfbox.pdmodel.PDPageContentStream(doc, page);
            cs.setLeading(leading);
            cs.beginText();
            cs.setFont(org.apache.pdfbox.pdmodel.font.PDType1Font.HELVETICA_BOLD, 14);
            cs.newLineAtOffset(marginLeft, startY);
            cs.showText("Garage Report");
            cs.newLine();
            cs.setFont(org.apache.pdfbox.pdmodel.font.PDType1Font.HELVETICA, 10);
            cs.showText("Period: " + r.getFrom() + " to " + r.getTo());
            cs.newLine();
            cs.showText("Total Requests: " + r.getTotalRequests());
            cs.newLine();
            cs.showText("Overall Avg ETA: " + (r.getOverallAverageEta() == null ? "-" : r.getOverallAverageEta()));
            cs.newLine();
            cs.newLine();
            cs.showText("Date       PEND ACC INPR COMP REJ CANC ETA");
            cs.newLine();
            int linesOnPage = 0;
            for (DailyReportEntry e : r.getEntries()) {
                String line = String.format("%s %5d %3d %4d %4d %3d %4d %s",
                        e.getDay(),
                        e.getStatusCounts().getOrDefault("PENDING", 0L),
                        e.getStatusCounts().getOrDefault("ACCEPTED", 0L),
                        e.getStatusCounts().getOrDefault("IN_PROGRESS", 0L),
                        e.getStatusCounts().getOrDefault("COMPLETED", 0L),
                        e.getStatusCounts().getOrDefault("REJECTED", 0L),
                        e.getStatusCounts().getOrDefault("CANCELLED", 0L),
                        e.getAverageEstimatedArrivalMinutes() == null ? "-" : e.getAverageEstimatedArrivalMinutes());
                cs.showText(line);
                cs.newLine();
                linesOnPage++;
                if (linesOnPage > 40) {
                    cs.endText();
                    cs.close();
                    page = new org.apache.pdfbox.pdmodel.PDPage();
                    doc.addPage(page);
                    cs = new org.apache.pdfbox.pdmodel.PDPageContentStream(doc, page);
                    cs.setLeading(leading);
                    cs.beginText();
                    cs.setFont(org.apache.pdfbox.pdmodel.font.PDType1Font.HELVETICA, 10);
                    cs.newLineAtOffset(marginLeft, startY);
                    cs.showText("Date       PEND ACC INPR COMP REJ CANC ETA");
                    cs.newLine();
                    linesOnPage = 0;
                }
            }
            cs.endText();
            cs.close();
            java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
            doc.save(baos);
            return baos.toByteArray();
        } catch (Exception e) {
            return ("PDF generation failed: " + e.getMessage()).getBytes();
        }
    }

    private Double round(Double value, int scale) {
        if (value == null) return null;
        double factor = Math.pow(10, scale);
        return Math.round(value * factor) / factor;
    }

    private Long toLong(Object o) {
        if (o == null) return 0L;
        if (o instanceof Long l) return l;
        if (o instanceof Integer i) return i.longValue();
        if (o instanceof Number n) return n.longValue();
        return Long.parseLong(o.toString());
    }

    private LocalDate convertToLocalDate(Object o) {
        if (o instanceof LocalDate ld) return ld;
        if (o instanceof java.sql.Date sd) return sd.toLocalDate();
        if (o instanceof java.time.LocalDateTime ldt) return ldt.toLocalDate();
        if (o instanceof java.sql.Timestamp ts) return ts.toLocalDateTime().toLocalDate();
        return LocalDate.parse(o.toString());
    }

    private String filename(String ext, DailyReportResponse r) {
        return "attachment; filename=report-" + r.getFrom() + "-" + r.getTo() + '.' + ext;
    }
}
