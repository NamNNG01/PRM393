import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<void> saveAndShareFileImpl({
  required List<int> bytes,
  required String filename,
  required String mimeType,
}) async {
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/$filename');
  await file.writeAsBytes(bytes, flush: true);
  final xFile = XFile(file.path, mimeType: mimeType);
  await Share.shareXFiles([xFile]);
}
