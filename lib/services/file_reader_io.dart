import 'dart:io';
import 'dart:typed_data';

Future<String> readFileAsString(String path) async {
  final file = File(path);
  return await file.readAsString();
}

Future<Uint8List> readFileAsBytes(String path) async {
  final file = File(path);
  return await file.readAsBytes();
}
