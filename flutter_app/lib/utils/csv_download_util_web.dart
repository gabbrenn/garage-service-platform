// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'csv_download_util_stub.dart';

class CsvDownloadUtilWeb implements CsvDownloadUtilPlatform {
  @override
  Future<CsvDownloadResult> downloadCsv(String filename, String content) async {
    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final bytes = [content.codeUnits];
    final blob = html.Blob(bytes, 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', safeName)
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return const CsvDownloadResult(filePath: null, triggeredBrowserDownload: true);
  }
}
CsvDownloadUtilPlatform getCsvDownloadPlatform() => CsvDownloadUtilWeb();
