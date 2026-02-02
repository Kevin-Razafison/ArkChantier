import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chantier_model.dart';
import '../models/journal_model.dart';
import '../models/ouvrier_model.dart';
import '../models/materiel_model.dart'; // N'oublie pas l'import

class DataStorage {
  static const String _keyChantiers = 'chantiers_list';

  // --- GESTION DES CHANTIERS ---
  static Future<void> saveChantiers(List<Chantier> chantiers) async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedData = jsonEncode(chantiers.map((c) => c.toJson()).toList());
    await prefs.setString(_keyChantiers, encodedData);
  }

  static Future<List<Chantier>> loadChantiers() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString(_keyChantiers);
    if (savedData == null) return [];
    
    final List<dynamic> decodedData = jsonDecode(savedData);
    return decodedData.map((item) => Chantier.fromJson(item)).toList();
  }

  // --- GESTION DU JOURNAL (Par Chantier) ---
  static Future<void> saveJournal(String chantierId, List<JournalEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'journal_$chantierId';
    final String encodedData = jsonEncode(entries.map((e) => e.toJson()).toList());
    await prefs.setString(key, encodedData);
  }

  static Future<List<JournalEntry>> loadJournal(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'journal_$chantierId';
    final String? savedData = prefs.getString(key);
    if (savedData == null) return [];
    final List<dynamic> decodedData = jsonDecode(savedData);
    return decodedData.map((item) => JournalEntry.fromJson(item)).toList();
  }

  // --- GESTION DE L'ÉQUIPE (Par Chantier) ---
  static Future<void> saveTeam(String chantierId, List<Ouvrier> equipe) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'team_$chantierId';
    final String encodedData = jsonEncode(equipe.map((o) => o.toJson()).toList());
    await prefs.setString(key, encodedData);
  }

  static Future<List<Ouvrier>> loadTeam(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'team_$chantierId';
    final String? savedData = prefs.getString(key);
    if (savedData == null) return [];
    final List<dynamic> decodedData = jsonDecode(savedData);
    return decodedData.map((item) => Ouvrier.fromJson(item)).toList();
  }

  // --- NOUVEAU : GESTION DES MATÉRIELS (Par Chantier) ---
  static Future<void> saveMateriels(String chantierId, List<Materiel> materiels) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'materiels_$chantierId';
    final String encodedData = jsonEncode(materiels.map((m) => m.toJson()).toList());
    await prefs.setString(key, encodedData);
  }

  static Future<List<Materiel>> loadMateriels(String chantierId) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'materiels_$chantierId';
    final String? savedData = prefs.getString(key);
    if (savedData == null) return [];
    final List<dynamic> decodedData = jsonDecode(savedData);
    return decodedData.map((item) => Materiel.fromJson(item)).toList();
  }
}