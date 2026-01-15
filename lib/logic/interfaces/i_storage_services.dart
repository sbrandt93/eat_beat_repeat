abstract class IStorageService {
  Future<void> saveJsonToFile(String fileName, Map<String, dynamic> jsonData);
  Future<Map<String, dynamic>> loadJsonFromFile(String fileName);
}
