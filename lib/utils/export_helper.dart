import 'export_helper_stub.dart'
    if (dart.library.html) 'export_helper_web.dart'
    if (dart.library.io) 'export_helper_mobile.dart';

class ExportHelper {
  static Future<void> saveAndShareFile({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    await saveAndShareFileImpl(
      bytes: bytes,
      filename: filename,
      mimeType: mimeType,
    );
  }
}
