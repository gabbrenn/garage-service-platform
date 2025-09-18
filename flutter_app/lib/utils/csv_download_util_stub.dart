class CsvDownloadResult {
  final String? filePath; // Non-web path
  final bool triggeredBrowserDownload; // Web
  const CsvDownloadResult({this.filePath, required this.triggeredBrowserDownload});
}

abstract class CsvDownloadUtilPlatform {
  Future<CsvDownloadResult> downloadCsv(String filename, String content);
}

