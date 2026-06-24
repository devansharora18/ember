import 'dart:typed_data';

Future<String> readFileAsString(String path) async {
  throw UnsupportedError('Cannot read files on this platform');
}

Future<Uint8List> readFileAsBytes(String path) async {
  throw UnsupportedError('Cannot read files on this platform');
}
