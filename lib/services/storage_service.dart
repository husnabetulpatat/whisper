import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notebook.dart';
import '../models/whisper_page.dart';
import '../models/page_element.dart';

class StorageService {
  StorageService._();

  static const _notebooksKey = 'whisper_notebooks';

  static Future<void> saveNotebooks(List<Notebook> notebooks) async {
    final prefs = await SharedPreferences.getInstance();
    final json = notebooks.map((n) => n.toJson()).toList();
    await prefs.setString(_notebooksKey, jsonEncode(json));
  }

  static Future<List<Notebook>> loadNotebooks() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_notebooksKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list.map((n) => Notebook.fromJson(n)).toList();
  }
}