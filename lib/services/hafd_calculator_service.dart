// lib/services/hafd_calculator_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hizb_model.dart';

class HafdCalculatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Données des 60 ahzab (simplifié - version complète à créer)
  // Cette table sera stockée dans Firestore
  static final List<Map<String, dynamic>> ahzabData = [
    // Juz 1
    {'hizbNumber': 1, 'startSura': 'الفاتحة', 'startSuraNumber': 1, 'startVerse': 1, 'endSura': 'البقرة', 'endSuraNumber': 2, 'endVerse': 25, 'juzNumber': 1},
    {'hizbNumber': 2, 'startSura': 'البقرة', 'startSuraNumber': 2, 'startVerse': 26, 'endSura': 'البقرة', 'endSuraNumber': 2, 'endVerse': 43, 'juzNumber': 1},
    
    // Juz 2
    {'hizbNumber': 3, 'startSura': 'البقرة', 'startSuraNumber': 2, 'startVerse': 44, 'endSura': 'البقرة', 'endSuraNumber': 2, 'endVerse': 59, 'juzNumber': 2},
    {'hizbNumber': 4, 'startSura': 'البقرة', 'startSuraNumber': 2, 'startVerse': 60, 'endSura': 'البقرة', 'endSuraNumber': 2, 'endVerse': 74, 'juzNumber': 2},
    
    // Juz 3
    {'hizbNumber': 5, 'startSura': 'البقرة', 'startSuraNumber': 2, 'startVerse': 75, 'endSura': 'البقرة', 'endSuraNumber': 2, 'endVerse': 91, 'juzNumber': 3},
    {'hizbNumber': 6, 'startSura': 'البقرة', 'startSuraNumber': 2, 'startVerse': 92, 'endSura': 'البقرة', 'endSuraNumber': 2, 'endVerse': 105, 'juzNumber': 3},
    
    // TODO: Continuer pour les 54 autres ahzab
    // Je vais te fournir la liste complète dans un fichier séparé
  ];

  /// Initialiser la table des ahzab dans Firestore (à faire une seule fois)
  Future<void> initializeAhzabInFirestore() async {
    try {
      WriteBatch batch = _firestore.batch();

      for (var hizbData in ahzabData) {
        DocumentReference docRef = _firestore
            .collection('quran_structure')
            .doc('ahzab')
            .collection('list')
            .doc(hizbData['hizbNumber'].toString());

        batch.set(docRef, hizbData);
      }

      await batch.commit();
      print('✅ Table des ahzab initialisée avec succès');
    } catch (e) {
      print('❌ Erreur lors de l\'initialisation: $e');
    }
  }

  /// Récupérer tous les ahzab depuis Firestore
  Future<List<HizbModel>> getAllAhzab() async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('quran_structure')
          .doc('ahzab')
          .collection('list')
          .orderBy('hizbNumber')
          .get();

      return snapshot.docs
          .map((doc) => HizbModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Erreur getAllAhzab: $e');
      return [];
    }
  }

  /// Trouver dans quel hizb se trouve un verset donné
  Future<HizbModel?> findHizbByVerse(int suraNumber, int verseNumber) async {
    List<HizbModel> allAhzab = await getAllAhzab();

    for (var hizb in allAhzab) {
      if (hizb.containsVerse(suraNumber, verseNumber)) {
        return hizb;
      }
    }

    return null;
  }

  /// Calculer le nombre d'ahzab complétés par un étudiant
  /// Basé sur tous ses followUps
  Future<Map<String, dynamic>> calculateStudentProgress(String studentId) async {
    try {
      // 1. Récupérer tous les followUps de l'étudiant
      QuerySnapshot followUpsSnapshot = await _firestore
          .collection('followUps')
          .where('studentId', isEqualTo: studentId)
          .orderBy('date')
          .get();

      if (followUpsSnapshot.docs.isEmpty) {
        return {
          'hafdCurrent': 0,
          'hafdProgress': 0.0,
          'currentHizb': 1,
          'totalVersesMemoized': 0,
        };
      }

      // 2. Extraire tous les versets mémorisés
      Set<String> memorizedVerses = {};

      for (var doc in followUpsSnapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        
        // Récupérer la sourate et les versets mémorisés
        String sura = data['sura'] ?? '';
        List<dynamic> days = data['days'] ?? [];

        // Pour chaque jour de la semaine
        for (var day in days) {
          int from = day['from'] ?? 0;
          int to = day['to'] ?? 0;

          // Marquer tous les versets de "from" à "to" comme mémorisés
          for (int verse = from; verse <= to; verse++) {
            memorizedVerses.add('$sura:$verse');
          }
        }
      }

      // 3. Mapper les versets aux ahzab
      List<HizbModel> allAhzab = await getAllAhzab();
      Set<int> completedAhzab = {};

      for (var hizb in allAhzab) {
        if (await _isHizbCompleted(hizb, memorizedVerses)) {
          completedAhzab.add(hizb.hizbNumber);
        }
      }

      // 4. Calculer la progression du hizb actuel
      int currentHizb = completedAhzab.length + 1;
      double currentHizbProgress = 0.0;

      if (currentHizb <= 60) {
        HizbModel? nextHizb = allAhzab.firstWhere(
          (h) => h.hizbNumber == currentHizb,
          orElse: () => allAhzab.first,
        );
        currentHizbProgress = await _calculateHizbProgress(nextHizb, memorizedVerses);
      }

      return {
        'hafdCurrent': completedAhzab.length,
        'hafdProgress': currentHizbProgress,
        'currentHizb': currentHizb,
        'totalVersesMemoized': memorizedVerses.length,
        'completedAhzabList': completedAhzab.toList()..sort(),
      };
    } catch (e) {
      print('Erreur calculateStudentProgress: $e');
      return {
        'hafdCurrent': 0,
        'hafdProgress': 0.0,
        'currentHizb': 1,
        'totalVersesMemoized': 0,
      };
    }
  }

  /// Vérifier si un hizb est complètement mémorisé
  Future<bool> _isHizbCompleted(HizbModel hizb, Set<String> memorizedVerses) async {
    // Simplification : on considère qu'un hizb fait environ 20 versets
    // TODO: Calculer précisément tous les versets du hizb
    
    int requiredVerses = 0;
    int memorizedCount = 0;

    // Compter les versets mémorisés dans ce hizb
    for (int sura = hizb.startSuraNumber; sura <= hizb.endSuraNumber; sura++) {
      int startVerse = (sura == hizb.startSuraNumber) ? hizb.startVerse : 1;
      int endVerse = (sura == hizb.endSuraNumber) ? hizb.endVerse : 300; // Max verses

      for (int verse = startVerse; verse <= endVerse; verse++) {
        String suraName = await _getSuraName(sura);
        requiredVerses++;
        if (memorizedVerses.contains('$suraName:$verse')) {
          memorizedCount++;
        }
      }
    }

    // Considérer complété si au moins 90% mémorisé
    return memorizedCount >= (requiredVerses * 0.9);
  }

  /// Calculer la progression d'un hizb (0.0 à 1.0)
  Future<double> _calculateHizbProgress(HizbModel hizb, Set<String> memorizedVerses) async {
    int totalVerses = 0;
    int memorizedCount = 0;

    for (int sura = hizb.startSuraNumber; sura <= hizb.endSuraNumber; sura++) {
      int startVerse = (sura == hizb.startSuraNumber) ? hizb.startVerse : 1;
      int endVerse = (sura == hizb.endSuraNumber) ? hizb.endVerse : 300;

      for (int verse = startVerse; verse <= endVerse; verse++) {
        String suraName = await _getSuraName(sura);
        totalVerses++;
        if (memorizedVerses.contains('$suraName:$verse')) {
          memorizedCount++;
        }
      }
    }

    return totalVerses > 0 ? memorizedCount / totalVerses : 0.0;
  }

  /// Obtenir le nom d'une sourate à partir de son numéro
  Future<String> _getSuraName(int suraNumber) async {
    // Table de correspondance simplifiée
    const suraNames = {
      1: 'الفاتحة',
      2: 'البقرة',
      3: 'آل عمران',
      4: 'النساء',
      5: 'المائدة',
      // TODO: Ajouter toutes les 114 sourates
    };

    return suraNames[suraNumber] ?? 'غير معروف';
  }

  /// Mettre à jour automatiquement le hafdCurrent d'un étudiant
  /// À appeler après chaque ajout/modification de followUp
  Future<void> updateStudentHafd(String studentId) async {
    try {
      Map<String, dynamic> progress = await calculateStudentProgress(studentId);

      await _firestore.collection('users').doc(studentId).update({
        'hafdCurrent': progress['hafdCurrent'],
        'hafdProgress': progress['hafdProgress'],
        'lastCalculatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Hafḍ mis à jour pour l\'étudiant $studentId: ${progress['hafdCurrent']} ahzab');
    } catch (e) {
      print('❌ Erreur updateStudentHafd: $e');
    }
  }
}