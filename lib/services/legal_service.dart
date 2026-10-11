import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/legal_document_model.dart';

class LegalService {
  static final LegalService _instance = LegalService._internal();
  factory LegalService() => _instance;
  LegalService._internal();

  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore error LegalService: $e');
    }
    return null;
  }

  /// Charge les documents légaux avec sécurité timeout et fallback immédiat
  Future<List<LegalDocumentModel>> getLegalDocuments() async {
    final defaultDocs = [
      LegalDocumentModel.defaultReglement,
      LegalDocumentModel.defaultContrat,
      LegalDocumentModel.defaultRemboursement,
    ];

    final db = _db;
    if (db == null) return defaultDocs;

    try {
      final snap = await db
          .collection('legal_documents')
          .get()
          .timeout(const Duration(seconds: 3));

      if (snap.docs.isEmpty) {
        // Enregistrer les documents par défaut en tâche de fond
        unawaited(_seedDocuments(db));
        return defaultDocs;
      }

      final docs = snap.docs.map((d) => LegalDocumentModel.fromFirestore(d)).toList();
      return docs.isNotEmpty ? docs : defaultDocs;
    } catch (e) {
      debugPrint('LegalService getLegalDocuments fallback: $e');
      return defaultDocs;
    }
  }

  Future<void> _seedDocuments(FirebaseFirestore db) async {
    try {
      final batch = db.batch();
      for (final doc in [
        LegalDocumentModel.defaultReglement,
        LegalDocumentModel.defaultContrat,
        LegalDocumentModel.defaultRemboursement,
      ]) {
        batch.set(db.collection('legal_documents').doc(doc.id), doc.toMap(), SetOptions(merge: true));
      }
      await batch.commit().timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('LegalService _seedDocuments error: $e');
    }
  }

  /// Vérifie si l'utilisateur a accepté un document (avec cache local instantané)
  Future<bool> hasUserAccepted(String userId, String documentId) async {
    // 1. Vérification rapide dans SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final localAccepted = prefs.getBool('legal_accepted_${userId}_$documentId');
      if (localAccepted == true) return true;
    } catch (_) {}

    // 2. Vérification Firestore avec timeout sécurisé
    final db = _db;
    if (db == null) return false;

    try {
      final doc = await db
          .collection('legal_acceptances')
          .doc('${userId}_$documentId')
          .get()
          .timeout(const Duration(seconds: 3));

      final exists = doc.exists;
      if (exists) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('legal_accepted_${userId}_$documentId', true);
      }
      return exists;
    } catch (e) {
      debugPrint('LegalService hasUserAccepted fallback: $e');
      return false;
    }
  }

  /// Vérifie si l'utilisateur a accepté TOUS les documents requis
  Future<bool> hasUserAcceptedAll(String userId) async {
    final docs = await getLegalDocuments();
    for (final doc in docs) {
      final accepted = await hasUserAccepted(userId, doc.id);
      if (!accepted) return false;
    }
    return true;
  }

  /// Enregistre l'acceptation d'un document
  Future<void> recordAcceptance({
    required String userId,
    required String documentId,
    required String version,
  }) async {
    // 1. Sauvegarde locale instantanée
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('legal_accepted_${userId}_$documentId', true);
    } catch (_) {}

    // 2. Synchronisation Firestore avec timeout
    final db = _db;
    if (db == null) return;

    try {
      await db
          .collection('legal_acceptances')
          .doc('${userId}_$documentId')
          .set({
        'userId': userId,
        'documentId': documentId,
        'version': version,
        'acceptedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)).timeout(const Duration(seconds: 4));

      // Also update user document
      await db.collection('users').doc(userId).update({
        'legalAcceptances.$documentId': version,
      }).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('LegalService recordAcceptance Firestore error: $e');
    }
  }

  /// Stream du statut d'acceptation d'un user
  Stream<Map<String, bool>> getUserAcceptancesStream(
      String userId, List<String> docIds) async* {
    // Émettre immédiatement les valeurs depuis SharedPreferences
    final initial = <String, bool>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final id in docIds) {
        initial[id] = prefs.getBool('legal_accepted_${userId}_$id') ?? false;
      }
    } catch (_) {}
    yield initial;

    final db = _db;
    if (db == null) return;

    try {
      final snap = await db
          .collection('legal_acceptances')
          .where('userId', isEqualTo: userId)
          .get()
          .timeout(const Duration(seconds: 3));

      final accepted = <String, bool>{};
      for (final id in docIds) {
        accepted[id] = snap.docs.any((d) => d.id == '${userId}_$id') || (initial[id] == true);
      }
      yield accepted;
    } catch (e) {
      debugPrint('LegalService getUserAcceptancesStream fallback: $e');
    }
  }
}
