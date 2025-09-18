# Localization Guide

This project uses Flutter's built-in internationalization (gen-l10n) with explicit output configuration via `l10n.yaml`.

## Key Files
- `l10n.yaml`: Configures arb directory, output directory, class name, etc.
- `lib/l10n/*.arb`: ARB files containing localized strings.
- `lib/l10n/gen/app_localizations.dart`: Generated localization classes (do not edit manually).
- `lib/widgets/language_picker_sheet.dart`: Re-usable bottom sheet for switching language.
- `providers/language_provider.dart`: Persists and applies chosen locale.

## Adding a New String
1. Open `lib/l10n/app_en.arb`.
2. Add a key/value pair, e.g.:
```json
  "profileTitle": "Profile"
```
3. Add the same key with translation to each other ARB file (e.g. `app_fr.arb`).
4. Run:
```
flutter gen-l10n
```
5. Use it in code:
```dart
final loc = AppLocalizations.of(context);
Text(loc.profileTitle);
```

## Adding a New Locale
1. Copy `app_en.arb` to `app_es.arb` (for Spanish, for example).
2. Translate each value.
3. Run:
```
flutter gen-l10n
```
4. The locale will automatically be included because gen-l10n detects ARB files in the folder.
5. Add language selection UI (if desired) by updating `LanguagePickerSheet` with a radio entry:
```dart
RadioListTile<String>(
  title: const Text('Español'),
  value: 'es',
  groupValue: current,
  onChanged: (v) { if (v!=null) { langProvider.setLocale(const Locale('es')); Navigator.pop(context); } },
)
```

## Dynamic / Parameterized Strings
Use ICU placeholders:
```json
"greeting": "Hello {name}!"
```
Then in Dart:
```dart
Text(AppLocalizations.of(context).greeting(name));
```
(After regenerating, a method will be created.)

## Plurals
```json
"messageCount": "{count, plural, =0{No messages} =1{1 message} other{{count} messages}}"
```
Usage:
```dart
loc.messageCount(count)
```

## Best Practices
- Keep keys semantic (e.g., `loginButton`, `errorNetwork`) not presentation-based.
- Group related keys logically (auth, splash, home) with consistent prefixes if needed.
- Avoid string concatenation; prefer adding full phrases to ARB.
- Regenerate after every ARB change before committing.

## Troubleshooting
| Issue | Cause | Fix |
|-------|-------|-----|
| AppLocalizations import fails | Generation not run or wrong path | Run `flutter gen-l10n`; check `l10n.yaml` paths |
| Missing translation warning | Key absent in a locale file | Add key to all ARB files, regenerate |
| Old strings still showing | Hot reload caching | Perform full restart |

## Persisted Locale
`LanguageProvider` stores the chosen locale in `SharedPreferences` under `selected_locale`. Reset logic can be added if you want a "System" option.

## Adding a 'System Default' Option
1. Add a radio with value `system` (or similar) in `LanguagePickerSheet`.
2. Implement `resetToSystem()` in `LanguageProvider` and call it when selected.

---
This document should be updated whenever new localization patterns (plurals, genders, formatting) are introduced.

## Recent Key Additions (Service & Garage Flows)
The following groups of keys were added to support full localization of service management, garage setup/edit, and service request flows:

### Garage Setup / Edit
- createGarageProfileHeading / createGarageProfileIntro
- garageNameHint / garageNameRequired
- garageAddressHint / garageAddressRequired
- garageDescriptionHint
- garageWorkingHoursHint
- selectedCoordinatesLabel (placeholders: lat, lng)
- mapTapToChooseLocation / mapTapToSetLocation
- savingInProgress

### Service Management
- addServiceDescription
- failedToLoadServices
- minutesUnit

### Service Request (Customer)
- fetchingCurrentLocation
- serviceDetailsHeading / yourLocationHeading / additionalDetailsHeading
- currentLocationLabel (placeholders: lat, lng)
- locationNotAvailable
- addressOptionalLabel / addressOptionalHint
- descriptionOptionalLabel / descriptionOptionalHint
- submitRequestButton

### Map Picker
- locationSelectedSuccess
- useLocation (button label)
- recenter / gpsFixed (buttons)

### CSV / Reporting (Earlier Batch)
Keys prefixed with reportCsv* plus csvDownloadedAndCopied, csvSavedAndCopiedWithPath( path ), shareFailedWithError( error ), exportFailedWithError( error ).

## Naming Conventions (Extended)
- Use a functional prefix for grouped flows: serviceRequest*, garage*, reportCsv*, requestRespond*, requestStatus*.
- For headings vs. labels: Prefer `*Heading` for section titles, `*Label` for form field labels, and `*Hint` for helper/placeholder text.
- Optional field labels explicitly include `(Optional)` in the value, not the key name; key names use Optional suffix (e.g., descriptionOptionalLabel).
- Dynamic placeholders always appear at the end of the key with a clearly described placeholder block in ARB (e.g., `@currentLocationLabel`).
- Status variants (Accepted / Rejected / etc.) use consistent `status*` naming for single-word statuses; action result messages use past tense or neutral: `serviceAddedSuccess`, `garageUpdateFailed`.

## Placeholder Guidelines
When adding placeholders:
1. Add the raw string with placeholder markers `{placeholder}`.
2. Immediately add an `@key` metadata entry specifying the placeholders object (even if empty objects for default behavior).
3. Use descriptive placeholder names (`serviceName`, `error`, `path`, `lat`, `lng`).
4. In code, call the generated method with arguments in the order they appear in the string.

Example:
```jsonc
"deleteServiceConfirm": "Are you sure you want to delete \"{serviceName}\"?",
"@deleteServiceConfirm": { "placeholders": { "serviceName": {} } }
```
Dart usage:
```dart
loc.deleteServiceConfirm(service.name)
```

## Adding More Flows
For future features (e.g., notifications center, analytics, chat):
1. Draft English keys grouped by functional prefix.
2. Add to `app_en.arb`, duplicate into other locales with translations.
3. Include any placeholders + metadata.
4. Run generation and refactor screens replacing literals immediately to avoid drift.

## QA Checklist Before Commit
- [ ] No remaining `// TODO localize` markers (grep to confirm)
- [ ] All new keys present in every ARB locale
- [ ] `flutter gen-l10n` run successfully (no missing getter errors)
- [ ] Spot-check dynamic placeholder strings render correctly
- [ ] No hard-coded English in recently touched widgets (map picker, setup, edit, request)

---
Last updated: 2025-09-14

## New Additions: Garage Request Handling & Reporting (September 2025)

This section documents the keys added to complete localization for the garage-side service request handling workflows and the analytical daily report screen.

### Service Requests (Garage Side)
Core screen & states:
- serviceRequestsTitle
- errorLoadingRequests
- noRequestsYetLong

Customer / Garage metadata & map:
- customerLocationTitle
- distanceKmLabel(distance)
- garageLabel / customerLabel / addressLabel
- unknownCustomerLabel / noPhoneLabel
- viewLocationMap
- locationNotProvided

Per-request detail prefixes (all use dynamic placeholders):
- servicePrefix(value)
- descriptionPrefix(value)
- requestedAtPrefix(date)
- etaPrefix(eta)

Actions & statuses (some reused globally; new where needed):
- acceptRequestButton / rejectRequestButton
- startWorkButton / markCompleteButton
- acceptRequestTitle / rejectRequestTitle
- responseMessageLabel / acceptDefaultResponse / rejectDefaultResponse
- estimatedArrivalMinutesLabel / minutesExampleHint
- cancelButton
- statusInProgress (added to complement existing status keys)

Request response & status update feedback:
- requestRespondGenericSuccess(status)
- requestRespondFailed
- requestStatusUpdateSuccess
- requestStatusUpdateFailed

### Reporting / Analytics (Garage Daily Report)
AppBar & tooltips:
- dailyReportTitle
- exportCsvTooltip / shareSaveTooltip / selectDateRangeTooltip / refreshTooltip / toggleEtaChartTooltip

Empty state:
- noDataLabel

Summary metrics:
- summaryTitle
- periodLabel
- totalRequestsLabel
- avgPerDayLabel
- avgEtaLabel
- avgEtaPrefix(value) (if used in inline summaries)

Breakdown & chart headings:
- dailyBreakdownTitle
- requestsByStatusDaily
- averageEtaMinutes

CSV export and share/download feedback:
- csvDownloadedAndCopied
- csvSavedAndCopiedWithPath(path)
- generatedAtLabel / periodStartLabel / periodEndLabel / totalDaysLabel / avgRequestsPerDayLabel
- exportFailedGeneric / shareFailedGeneric

Status labels (consumed by report & request flows):
- statusPending / statusAccepted / statusRejected / statusInProgress / statusCompleted / statusCancelled

### Placeholder Usage Summary
| Key | Placeholder(s) | Notes |
|-----|----------------|-------|
| distanceKmLabel | distance | Numeric distance already formatted before passing if locale-specific formatting needed |
| servicePrefix | value | Shown as a labeled line (e.g., "Service: Oil Change") |
| descriptionPrefix | value | Similar pattern to servicePrefix |
| requestedAtPrefix | date | Date should be preformatted respecting locale (consider DateFormat) |
| etaPrefix | eta | Already formatted string (e.g., "30 min") |
| requestRespondGenericSuccess | status | Status passed in lowercase; consider mapping if you need localized status in message |
| csvSavedAndCopiedWithPath | path | Full file path displayed to user |

### Implementation Notes
1. Status chips and stacked bar legend use localization mapping functions rather than hard-coded enums.
2. CSV export currently keeps column headers for date & raw status codes in English (e.g., `Date`, `PENDING`); add keys later if those must be localized—many consumers expect stable English headers for data ingestion.
3. Added generic failure keys (exportFailedGeneric / shareFailedGeneric) to standardize snackbar messaging; if you later need richer error detail, add *WithError(error)* variants.
4. Time / date formatting is performed prior to insertion—if more locales are added beyond EN/FR, consider introducing helper utilities to ensure consistent formatting (e.g., via `intl` DateFormat patterns pulled from a central spot).

### Recommended Future Enhancements
- Add pluralization for request counts in aggregate summaries if languages with complex plurals are introduced.
- Introduce keys for CSV column headers (csvHeaderDate, csvHeaderAvgEta, etc.) if localization of exported data files becomes a requirement.
- Consolidate prefix-style keys (`servicePrefix`, etc.) under a structured pattern or consider moving to richer widget composition if formatting grows in complexity.

---
Document update applied: 2025-09-14 (garage flows finalized)
