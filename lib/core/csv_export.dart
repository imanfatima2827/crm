import 'dart:convert';
import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// Escapes a single CSV field per RFC 4180: wrap in quotes if it contains
/// a comma, quote, or newline, doubling any internal quotes.
String _csvField(dynamic value) {
  final s = value?.toString() ?? '';
  if (s.contains(',') ||
      s.contains('"') ||
      s.contains('\n') ||
      s.contains('\r')) {
    return '"${s.replaceAll('"', '""')}"';
  }
  return s;
}

String _toCsv(List<String> headers, List<List<dynamic>> rows) {
  final buffer = StringBuffer();
  buffer.write(headers.map(_csvField).join(','));
  buffer.write('\r\n');
  for (final row in rows) {
    buffer.write(row.map(_csvField).join(','));
    buffer.write('\r\n');
  }
  return buffer.toString();
}

/// Converts rows to CSV and opens the platform share sheet so the person
/// can save it, email it, or drop it into Sheets/Excel — works the same
/// way on mobile, desktop, and web since it never touches the filesystem
/// directly, and has no dependency on the (frequently breaking) `csv`
/// package — the encoding itself is only a few lines of RFC 4180 quoting.
Future<void> exportAndShareCsv({
  required String filename,
  required List<String> headers,
  required List<List<dynamic>> rows,
  String? shareText,
}) async {
  final csvData = _toCsv(headers, rows);
  final bytes = Uint8List.fromList(utf8.encode(csvData));
  final file = XFile.fromData(bytes, mimeType: 'text/csv', name: filename);
  await SharePlus.instance.share(
    ShareParams(
      files: [file],
      fileNameOverrides: [filename],
      text: shareText ?? 'CRM export: $filename',
      subject: filename,
    ),
  );
}
