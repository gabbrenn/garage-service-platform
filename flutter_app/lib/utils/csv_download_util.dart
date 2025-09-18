export 'csv_download_util_stub.dart' show CsvDownloadResult, CsvDownloadUtilPlatform;
import 'csv_download_util_stub.dart';
// Conditional: for web builds the html implementation is chosen; otherwise IO.
import 'csv_download_util_io.dart' if (dart.library.html) 'csv_download_util_web.dart';

/// Unified facade for CSV download across platforms.
class CsvDownloadUtil {
  static Future<CsvDownloadResult> downloadCsv(String filename, String content) =>
      getCsvDownloadPlatform().downloadCsv(filename, content);
}
