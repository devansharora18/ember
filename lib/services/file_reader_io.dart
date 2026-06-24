import 'dart:io';

Future<String> readFileAsString(String path) async {
  final file = File(path);
  return await file.readAsString();
}
