import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class MigrationScript {
  static Future<void> migrateLocalToSaaS(String adminId) async {
    final prefs = await SharedPreferences.getInstance();
    final firestore = FirebaseFirestore.instance;

    // 1. Migrer les projets
    final projectsKey = 'projects_list';
    final projectsData = prefs.getString(projectsKey);

    if (projectsData != null) {
      final projects = json.decode(projectsData) as List;

      for (final project in projects) {
        // Ajouter l'adminId
        project['adminId'] = adminId;

        await firestore
            .collection('admins')
            .doc(adminId)
            .collection('projects')
            .doc(project['id'])
            .set(project);
      }
    }

    // 2. Migrer les utilisateurs
    final usersKey = 'users_list';
    final usersData = prefs.getString(usersKey);

    if (usersData != null) {
      final users = json.decode(usersData) as List;

      for (final user in users) {
        user['adminId'] = adminId;

        await firestore
            .collection('admins')
            .doc(adminId)
            .collection('users')
            .doc(user['id'])
            .set(user);
      }
    }

    // 3. Migrer les ouvriers
    final ouvriersKey = 'team_annuaire_global';
    final ouvriersData = prefs.getString(ouvriersKey);

    if (ouvriersData != null) {
      final ouvriers = json.decode(ouvriersData) as List;

      for (final ouvrier in ouvriers) {
        ouvrier['adminId'] = adminId;

        await firestore
            .collection('admins')
            .doc(adminId)
            .collection('ouvriers')
            .doc(ouvrier['id'])
            .set(ouvrier);
      }
    }

    debugPrint('Migration terminée pour l\'admin $adminId');
  }
}
