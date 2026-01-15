import 'dart:convert';
import 'dart:io';
import 'package:eat_beat_repeat/logic/interfaces/i_storage_service.dart';
import 'package:path_provider/path_provider.dart';

class LocalStorageService implements IStorageService {
  static Future<String> _localPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<void> saveJsonToFile(String fileName, dynamic data) async {
    final path = await _localPath();
    final file = File('$path/$fileName');
    // Sicherstellen, dass die Datei synchron gespeichert wird
    await file.writeAsString(json.encode(data));
  }

  @override
  Future<Map<String, dynamic>> loadJsonFromFile(String fileName) async {
    final path = await _localPath();
    final file = File('$path/$fileName');

    // Prüfen, ob die Datei existiert
    if (await file.exists()) {
      try {
        final content = await file.readAsString();
        // Gibt eine leere Liste zurück, falls der Inhalt leer ist oder nicht deserialisiert werden kann
        if (content.isEmpty) return {};

        final decoded = json.decode(content);
        // Sicherstellen, dass wir eine Map zurückgeben
        return (decoded is Map<String, dynamic>) ? decoded : {};
      } catch (e) {
        // Fehlerbehandlung beim Lesen/Parsen
        return {};
      }
    }
    // Datei existiert nicht
    return {};
  }
}
