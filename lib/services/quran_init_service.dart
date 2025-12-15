// lib/services/quran_init_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import 'package:flutter/services.dart';

class QuranInitService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Données des 60 ahzab (tu as déjà ce fichier: ahzab_data.json)
  /// Copie le contenu ici ou charge-le depuis assets
  static const List<Map<String, dynamic>> ahzabData = [
    {
      "hizbNumber": 1,
      "startSura": "الفاتحة",
      "startSuraNumber": 1,
      "startVerse": 1,
      "endSura": "البقرة",
      "endSuraNumber": 2,
      "endVerse": 74,
      "juzNumber": 1
    },
    {
      "hizbNumber": 2,
      "startSura": "البقرة",
      "startSuraNumber": 2,
      "startVerse": 75,
      "endSura": "البقرة",
      "endSuraNumber": 2,
      "endVerse": 141,
      "juzNumber": 1
    },
    {
      "hizbNumber": 3,
      "startSura": "البقرة",
      "startSuraNumber": 2,
      "startVerse": 142,
      "endSura": "البقرة",
      "endSuraNumber": 2,
      "endVerse": 202,
      "juzNumber": 2
    },
    {
      "hizbNumber": 4,
      "startSura": "البقرة",
      "startSuraNumber": 2,
      "startVerse": 203,
      "endSura": "البقرة",
      "endSuraNumber": 2,
      "endVerse": 252,
      "juzNumber": 2
    },
    {
      "hizbNumber": 5,
      "startSura": "البقرة",
      "startSuraNumber": 2,
      "startVerse": 253,
      "endSura": "آل عمران",
      "endSuraNumber": 3,
      "endVerse": 14,
      "juzNumber": 3
    },
    // ... (copie tous les 60 ahzab depuis ton fichier ahzab_data.json)
    // Je les ai déjà dans ton fichier, je vais créer une version complète
  ];

  /// Initialiser la structure Quran dans Firestore
  /// ⚠️ À exécuter UNE SEULE FOIS
  Future<bool> initializeQuranStructure() async {
    try {
      print('🔄 Initialisation de la structure du Quran...');

      // Vérifier si déjà initialisé
      DocumentSnapshot checkDoc = await _firestore
          .collection('quran_structure')
          .doc('ahzab')
          .get();

      if (checkDoc.exists) {
        Map<String, dynamic>? data = checkDoc.data() as Map<String, dynamic>?;
        if (data != null && data['initialized'] == true) {
          print('ℹ️ Structure déjà initialisée');
          return true;
        }
      }

      // Créer le batch pour toutes les insertions
      WriteBatch batch = _firestore.batch();

      // Charger les données complètes depuis ton JSON
      List<Map<String, dynamic>> fullAhzabData = await _loadFullAhzabData();

      // Ajouter chaque hizb
      for (var hizbData in fullAhzabData) {
        DocumentReference hizbRef = _firestore
            .collection('quran_structure')
            .doc('ahzab')
            .collection('list')
            .doc(hizbData['hizbNumber'].toString());

        batch.set(hizbRef, hizbData);
      }

      // Marquer comme initialisé
      DocumentReference ahzabDoc = _firestore
          .collection('quran_structure')
          .doc('ahzab');

      batch.set(ahzabDoc, {
        'initialized': true,
        'totalAhzab': fullAhzabData.length,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Commit toutes les opérations
      await batch.commit();

      print('✅ Structure du Quran initialisée avec succès (${fullAhzabData.length} ahzab)');
      return true;
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> _loadFullAhzabData() async {
      String jsonString = await rootBundle.loadString('assets/ahzab_data.json');
      return List<Map<String, dynamic>>.from(json.decode(jsonString));
  }

  /// Vérifier si la structure est initialisée
  Future<bool> isInitialized() async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('quran_structure')
          .doc('ahzab')
          .get();

      if (!doc.exists) return false;
      
      Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
      return data?['initialized'] == true;
    } catch (e) {
      return false;
    }
  }
}