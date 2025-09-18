import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'csv_download_util_stub.dart';

class CsvDownloadUtilIO implements CsvDownloadUtilPlatform {
  @override
  Future<CsvDownloadResult> downloadCsv(String filename, String content) async {
    final safeName = filename.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$safeName');
    await file.writeAsString(content);
    return CsvDownloadResult(filePath: file.path, triggeredBrowserDownload: false);
  }
}
CsvDownloadUtilPlatform getCsvDownloadPlatform() => CsvDownloadUtilIO();
