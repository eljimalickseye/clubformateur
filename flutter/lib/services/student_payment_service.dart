import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/student_payment_model.dart';
import 'laravel_api_service.dart';

class StudentPaymentService {
  static final StudentPaymentService _instance = StudentPaymentService._internal();
  factory StudentPaymentService() => _instance;
  StudentPaymentService._internal() {
    _initCache();
  }

  static const String _cacheKey = 'local_student_payments_v2';
  final LaravelApiService _api = LaravelApiService();
  final StreamController<List<StudentPaymentModel>> _paymentsController =
      StreamController<List<StudentPaymentModel>>.broadcast();

  List<StudentPaymentModel> _cachedPayments = [];
  bool _initialized = false;

  FirebaseFirestore? get _db {
    try {
      if (Firebase.apps.isNotEmpty) return FirebaseFirestore.instance;
    } catch (e) {
      debugPrint('Firestore not ready StudentPaymentService: $e');
    }
    return null;
  }

  Future<void> _initCache() async {
    if (_initialized) return;
    _initialized = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw != null && raw.isNotEmpty) {
        _cachedPayments = (jsonDecode(raw) as List)
            .map((e) => StudentPaymentModel.fromMap(
                Map<String, dynamic>.from(e as Map), e['id']?.toString() ?? ''))
            .toList();
      }
    } catch (e) {
      debugPrint('StudentPaymentService cache error: $e');
    }

    _paymentsController.add(_cachedPayments);
    unawaited(_syncRemote());
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _cacheKey,
        jsonEncode(_cachedPayments.map((p) => p.toMap()).toList()),
      );
    } catch (e) {
      debugPrint('StudentPaymentService saveCache error: $e');
    }
  }

  Future<void> _syncRemote() async {
    // 1. Sync from Firestore
    try {
      final db = _db;
      if (db != null) {
        final snap = await db.collection('payments').limit(50).get().timeout(const Duration(seconds: 4));
        if (snap.docs.isNotEmpty) {
          final list = snap.docs
              .map((d) => StudentPaymentModel.fromMap(d.data(), d.id))
              .toList();
          if (list.isNotEmpty) {
            _cachedPayments = list;
            await _saveCache();
            _paymentsController.add(_cachedPayments);
            return;
          }
        }
      }
    } catch (e) {
      debugPrint('Firestore payments sync fallback: $e');
    }

    // 2. Sync from Laravel API
    try {
      final res = await _api.get('/payments');
      if (res != null && res['data'] is List) {
        final list = (res['data'] as List)
            .map((item) => StudentPaymentModel.fromMap(
                Map<String, dynamic>.from(item as Map), item['id']?.toString() ?? ''))
            .toList();
        if (list.isNotEmpty) {
          _cachedPayments = list;
          await _saveCache();
          _paymentsController.add(_cachedPayments);
        }
      }
    } catch (_) {}
  }

  /// Get stream of payments for a student
  Stream<List<StudentPaymentModel>> getStudentPaymentsStream(String studentId) async* {
    await _initCache();
    bool matches(StudentPaymentModel p) =>
        studentId.isNotEmpty && (p.studentId == studentId || p.studentId.isEmpty);

    yield _cachedPayments.where(matches).toList();
    yield* _paymentsController.stream.map((list) => list.where(matches).toList());
  }

  /// Record a payment (monthly tuition or course purchase)
  Future<String> recordPayment({
    required String studentId,
    required String studentName,
    String courseId = 'course_scolarite',
    String courseTitle = 'Scolarité mensuelle',
    required String monthLabel,
    required int amount,
    required String paymentMethod,
    String? transactionRef,
    bool isMonthlyFee = true,
  }) async {
    await _initCache();
    final id = 'pay_${DateTime.now().millisecondsSinceEpoch}';
    final trxRef = transactionRef ?? 'TRX-${paymentMethod.split(' ').first.toUpperCase()}-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final receiptNum = 'REC-${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${(1000 + _cachedPayments.length)}';

    final payment = StudentPaymentModel(
      id: id,
      studentId: studentId,
      studentName: studentName,
      courseId: courseId,
      courseTitle: courseTitle,
      monthLabel: monthLabel,
      amount: amount,
      paymentMethod: paymentMethod,
      transactionRef: trxRef,
      receiptNumber: receiptNum,
      status: 'COMPLETED',
      paidAt: DateTime.now(),
      isMonthlyFee: isMonthlyFee,
    );

    _cachedPayments = [payment, ..._cachedPayments];
    await _saveCache();
    _paymentsController.add(_cachedPayments);

    try {
      final db = _db;
      if (db != null) {
        await db.collection('payments').doc(id).set(payment.toMap()).timeout(const Duration(seconds: 4));
      }
    } catch (_) {}

    return id;
  }
}
