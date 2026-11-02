import 'package:file_picker/file_picker.dart';

import '../network/api_client.dart';

class UploadedHomieFile {
  const UploadedHomieFile({
    required this.url,
    required this.fileName,
    required this.mimeType,
    required this.size,
  });

  final String url;
  final String fileName;
  final String mimeType;
  final int size;
}

class FileUploadService {
  const FileUploadService(this._client);

  final ApiClient _client;

  Future<UploadedHomieFile?> pickAndUpload({
    required String category,
    bool imagesOnly = false,
    int maxSizeBytes = 10 * 1024 * 1024,
  }) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: imagesOnly
          ? const ['jpg', 'jpeg', 'png', 'webp']
          : const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      withData: true,
    );
    final file = result?.files.singleOrNull;
    if (file == null) return null;
    if (file.size > maxSizeBytes) {
      final maxMegabytes = maxSizeBytes / (1024 * 1024);
      final displaySize = maxMegabytes == maxMegabytes.roundToDouble()
          ? maxMegabytes.toInt().toString()
          : maxMegabytes.toStringAsFixed(1);
      throw StateError('Tệp không được vượt quá $displaySize MB.');
    }
    final bytes = file.bytes;
    if (bytes == null) throw StateError('Không thể đọc nội dung tệp đã chọn.');
    final mimeType = _mimeTypeFor(file.extension);
    final response = await _client.uploadFile(
      '/storage/upload',
      bytes: bytes,
      fileName: file.name,
      fieldName: 'file',
      mimeType: mimeType,
      fields: {'category': category},
    );
    return UploadedHomieFile(
      url: response['url'] as String? ?? '',
      fileName: response['fileName'] as String? ?? file.name,
      mimeType: response['mimeType'] as String? ?? mimeType,
      size: response['size'] as int? ?? file.size,
    );
  }

  String _mimeTypeFor(String? extension) => switch (extension?.toLowerCase()) {
    'jpg' || 'jpeg' => 'image/jpeg',
    'png' => 'image/png',
    'webp' => 'image/webp',
    'pdf' => 'application/pdf',
    _ => 'application/octet-stream',
  };
}
