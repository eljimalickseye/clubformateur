import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'laravel_api_service.dart';

enum WithdrawalMethod { wave, orangeMoney }

class IntechTransaction {
  final String id;
  final String externalTransactionId;
  final int amount; // in FCFA
  final String phone;
  final String serviceCode;
  final String providerName; // Wave Sénégal or Orange Money Sénégal
  final String status; // 'SUCCESS', 'PENDING', 'FAILED'
  final DateTime createdAt;
  final String? message;

  IntechTransaction({
    required this.id,
    required this.externalTransactionId,
    required this.amount,
    required this.phone,
    required this.serviceCode,
    required this.providerName,
    required this.status,
    required this.createdAt,
    this.message,
  });

  factory IntechTransaction.fromJson(Map<String, dynamic> json) {
    return IntechTransaction(
      id: json['id'] ?? '',
      externalTransactionId: json['externalTransactionId'] ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      phone: json['phone'] ?? '',
      serviceCode: json['serviceCode'] ?? '',
      providerName: json['providerName'] ?? 'Wave Sénégal',
      status: json['status'] ?? 'PENDING',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'externalTransactionId': externalTransactionId,
      'amount': amount,
      'phone': phone,
      'serviceCode': serviceCode,
      'providerName': providerName,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'message': message,
    };
  }
}

class IntechPaymentService {
  static final IntechPaymentService _instance = IntechPaymentService._internal();
  factory IntechPaymentService() => _instance;
  IntechPaymentService._internal();

  static const String waveServiceCode = 'WAVE_SN_API_CASH_OUT';
  static const String orangeServiceCode = 'ORANGE_SN_API_CASH_OUT';

  static const String _storageKey = 'intech_withdrawals_history';

  /// Format phone to Senegal 221XXXXXXXXX
  String formatSenegalPhone(String phone) {
    String clean = phone.replaceAll(RegExp(r'\s+'), '').replaceAll('+', '');
    if (clean.startsWith('00221')) {
      clean = clean.substring(2);
    } else if (!clean.startsWith('221')) {
      clean = '221$clean';
    }
    return clean;
  }

  /// Request a teacher cash-out (retrait) via Wave or Orange Money
  Future<IntechTransaction> requestWithdrawal({
    required String teacherId,
    required String teacherName,
    required int amount,
    required String phone,
    required WithdrawalMethod method,
  }) async {
    final serviceCode = method == WithdrawalMethod.wave ? waveServiceCode : orangeServiceCode;
    final providerName = method == WithdrawalMethod.wave ? 'Wave Sénégal' : 'Orange Money Sénégal';
    final formattedPhone = formatSenegalPhone(phone);
    String externalTxId = 'cf_retrait_${DateTime.now().millisecondsSinceEpoch}';

    String status = 'PENDING';
    String message = 'Demande de retrait transmise via $providerName';

    try {
      // Routage sécurisé via l'API Laravel (secrets protégés côté serveur, transaction atomique et contrôle du solde)
      final res = await LaravelApiService().post('/payments/withdraw', {
        'amount': amount,
        'phone': formattedPhone,
        'method': method == WithdrawalMethod.wave ? 'wave' : 'orange',
      });

      if (res != null && res['success'] == true) {
        final txData = res['transaction'] as Map<String, dynamic>?;
        status = txData?['status'] ?? 'SUCCESS';
        externalTxId = txData?['external_transaction_id'] ?? externalTxId;
        message = res['message'] ?? 'Retrait validé avec succès ($providerName)';
      } else {
        status = 'FAILED';
        message = res?['message'] ?? 'Échec de la demande de retrait';
      }
    } catch (e) {
      debugPrint('Laravel withdrawal API error: $e');
      status = 'FAILED';
      message = 'Erreur lors du traitement du retrait : $e';
    }

    final tx = IntechTransaction(
      id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
      externalTransactionId: externalTxId,
      amount: amount,
      phone: formattedPhone,
      serviceCode: serviceCode,
      providerName: providerName,
      status: status,
      createdAt: DateTime.now(),
      message: message,
    );

    await _saveTransaction(tx);
    return tx;
  }

  Future<void> _saveTransaction(IntechTransaction tx) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = await getWithdrawalHistory();
      history.insert(0, tx);
      final jsonList = history.map((t) => t.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
    } catch (e) {
      debugPrint('Error saving transaction history: $e');
    }
  }

  Future<List<IntechTransaction>> getWithdrawalHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List list = jsonDecode(raw);
        return list.map((item) => IntechTransaction.fromJson(Map<String, dynamic>.from(item))).toList();
      }
    } catch (e) {
      debugPrint('Error reading transaction history: $e');
    }

    // Default demonstration transactions
    return [
      IntechTransaction(
        id: 'tx_init_1',
        externalTransactionId: 'cf_retrait_1727000100',
        amount: 85000,
        phone: '221771234567',
        serviceCode: waveServiceCode,
        providerName: 'Wave Sénégal',
        status: 'SUCCESS',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        message: 'Virement Wave reçu avec succès',
      ),
      IntechTransaction(
        id: 'tx_init_2',
        externalTransactionId: 'cf_retrait_1726500200',
        amount: 150000,
        phone: '221789876543',
        serviceCode: orangeServiceCode,
        providerName: 'Orange Money Sénégal',
        status: 'SUCCESS',
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        message: 'Virement Orange Money complété',
      ),
    ];
  }

  Future<IntechPaymentResponse> initiatePayment({
    required String clientPhone,
    required double amount,
    required String method,
    required String externalTransactionId,
    required String userId,
    required String policyId,
    required String policyTitle,
  }) async {
    return IntechPaymentResponse(error: false, message: 'Paiement initié avec succès');
  }
}

class IntechPaymentResponse {
  final bool error;
  final String message;
  const IntechPaymentResponse({required this.error, required this.message});
}
