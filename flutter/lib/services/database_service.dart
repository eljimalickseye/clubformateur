import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class DatabaseService {
  static const String _usersKey = 'olivia_db_users_v5';
  static const String _vehiclesKey = 'olivia_db_vehicles_v5';
  static const String _policiesKey = 'olivia_db_policies_v5';
  static const String _transactionsKey = 'olivia_db_transactions_v5';
  static const String _sessionKey = 'olivia_db_session_user_id_v5';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _seedDefaultsIfEmpty();
  }

  Future<void> _seedDefaultsIfEmpty() async {
    final usersRaw = _prefs?.getString(_usersKey);
    if (usersRaw == null || usersRaw.isEmpty) {
      final defaultUsers = {
        'serigne.fall@olivia.sn': {
          'id': 'user_serigne_fall',
          'fullName': 'Serigne Abdoulaye Fall',
          'email': 'serigne.fall@olivia.sn',
          'phoneNumber': '+221 77 845 12 34',
          'role': 'insured',
          'brokerCode': 'COURTIER-DAKAR-77',
          'brokerAgencyId': 'broker_dakar_77',
          'password': 'pass1234',
        },
        'courtier@assurcourtage.sn': {
          'id': 'broker_user_dakar',
          'fullName': 'Cabinet AssurCourtage Dakar',
          'email': 'courtier@assurcourtage.sn',
          'phoneNumber': '+221 33 821 00 00',
          'role': 'broker',
          'brokerCode': 'COURTIER-DAKAR-77',
          'brokerAgencyId': 'broker_dakar_77',
          'password': 'courtier123',
        },
      };
      await _prefs?.setString(_usersKey, jsonEncode(defaultUsers));

      // Seed Vehicle for Serigne Fall
      await saveVehicle(
        'user_serigne_fall',
        VehicleModel(
          id: 'veh_serigne_01',
          plateNumber: 'DK-5489-BG',
          make: 'Toyota',
          model: 'Corolla',
          year: 2022,
          chassisNumber: 'JT3HP10V5K019842',
          fiscalPower: 7,
          fuelType: 'Essence',
        ),
      );

      // Seed Policies for Serigne Fall
      final now = DateTime.now();
      await savePolicies('user_serigne_fall', [
        InsurancePolicy(
          id: 'pol_serigne_axa_01',
          policyNumber: 'POL-AXA-2025-9841',
          talonNumber: 'TAL-SN-2025-884920',
          companyName: 'AXA Assurances Sénégal',
          companyLogoPath: 'assets/images/axa_logo.png',
          coverageType: 'Formule Confort Plus CIMA',
          premiumAmount: 250000,
          startDate: now.subtract(const Duration(days: 337)),
          endDate: now.add(const Duration(days: 28)),
          status: PolicyStatus.active,
          vehicle: VehicleModel(
            id: 'veh_serigne_01',
            plateNumber: 'DK-5489-BG',
            make: 'Toyota',
            model: 'Corolla',
            year: 2022,
            chassisNumber: 'JT3HP10V5K019842',
            fiscalPower: 7,
            fuelType: 'Essence',
          ),
          qrData: 'OLIVIA:PASS_CIMA:DK-5489-BG:Serigne Abdoulaye Fall:COURTIER-DAKAR-77',
          brokerCode: 'COURTIER-DAKAR-77',
          brokerAgencyName: 'Cabinet AssurCourtage Dakar',
          clientName: 'Serigne Abdoulaye Fall',
          clientPhone: '+221 77 845 12 34',
          guarantees: [
            'Responsabilité Civile CIMA 100%',
            'Défense & Recours Juridique 100%',
            'Bris de Glaces (Sans franchise)',
            'Assistance Remorquage 24/7 Dakar & Régions',
          ],
        ),
      ]);
    }
  }

  // Session
  Future<void> saveSession(String userId) async {
    await init();
    await _prefs?.setString(_sessionKey, userId);
  }

  Future<String?> getActiveSession() async {
    await init();
    return _prefs?.getString(_sessionKey);
  }

  Future<void> clearSession() async {
    await init();
    await _prefs?.remove(_sessionKey);
  }

  // Users DB
  Future<Map<String, dynamic>> getAllUsers() async {
    await init();
    final raw = _prefs?.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<UserModel?> findUser(String emailOrPhone, String password) async {
    final users = await getAllUsers();
    final cleanInput = emailOrPhone.trim().toLowerCase();

    for (final entry in users.entries) {
      final u = entry.value as Map<String, dynamic>;
      final email = (u['email'] ?? '').toString().toLowerCase();
      final phone = (u['phoneNumber'] ?? '').toString().replaceAll(' ', '').toLowerCase();
      final inputPhone = cleanInput.replaceAll(' ', '').replaceAll('+221', '');

      if (email == cleanInput || (inputPhone.isNotEmpty && phone.contains(inputPhone))) {
        return UserModel(
          id: u['id'] ?? 'user_1',
          fullName: u['fullName'] ?? 'Assuré Olivia',
          email: u['email'] ?? emailOrPhone,
          phoneNumber: u['phoneNumber'] ?? '+221 77 845 12 34',
          role: (u['role'] == 'broker') ? UserRole.broker : UserRole.insured,
          brokerCode: u['brokerCode'] ?? 'COURTIER-DAKAR-77',
          brokerAgencyId: u['brokerAgencyId'] ?? 'broker_dakar_77',
        );
      }
    }

    // Dynamic auto-registration if new user
    final isBroker = cleanInput.contains('courtier') || cleanInput.contains('broker') || cleanInput.contains('courtage') || cleanInput.contains('assurcourtage');
    final newUser = UserModel(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      fullName: isBroker ? 'Cabinet AssurCourtage Dakar' : (emailOrPhone.contains('@') ? emailOrPhone.split('@').first : 'Nouvel Assuré'),
      email: emailOrPhone.contains('@') ? emailOrPhone : '$emailOrPhone@olivia.sn',
      phoneNumber: emailOrPhone.contains('@') ? '+221 77 100 20 30' : emailOrPhone,
      role: isBroker ? UserRole.broker : UserRole.insured,
      brokerCode: 'COURTIER-DAKAR-77',
      brokerAgencyId: 'broker_dakar_77',
    );
    await saveUser(newUser, password: password);
    return newUser;
  }

  Future<void> saveUser(UserModel user, {required String password}) async {
    final users = await getAllUsers();
    users[user.email.toLowerCase()] = {
      'id': user.id,
      'fullName': user.fullName,
      'email': user.email,
      'phoneNumber': user.phoneNumber,
      'role': user.role == UserRole.broker ? 'broker' : 'insured',
      'brokerCode': user.brokerCode,
      'brokerAgencyId': user.brokerAgencyId,
      'password': password,
    };
    await _prefs?.setString(_usersKey, jsonEncode(users));
  }

  // Vehicle Storage
  Future<void> saveVehicle(String userId, VehicleModel vehicle) async {
    await init();
    final raw = _prefs?.getString(_vehiclesKey);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try { map = jsonDecode(raw); } catch (_) {}
    }
    map[userId] = {
      'id': vehicle.id,
      'plateNumber': vehicle.plateNumber,
      'make': vehicle.make,
      'model': vehicle.model,
      'year': vehicle.year,
      'chassisNumber': vehicle.chassisNumber,
      'fiscalPower': vehicle.fiscalPower,
      'fuelType': vehicle.fuelType,
    };
    await _prefs?.setString(_vehiclesKey, jsonEncode(map));
  }

  Future<VehicleModel?> getVehicle(String userId) async {
    await init();
    final raw = _prefs?.getString(_vehiclesKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final v = map[userId];
      if (v != null) {
        return VehicleModel(
          id: v['id'] ?? 'veh_1',
          plateNumber: v['plateNumber'] ?? 'DK-5489-BG',
          make: v['make'] ?? 'Toyota',
          model: v['model'] ?? 'Corolla',
          year: v['year'] ?? 2022,
          chassisNumber: v['chassisNumber'] ?? 'SN-VIN-001',
          fiscalPower: v['fiscalPower'] ?? 7,
          fuelType: v['fuelType'] ?? 'Essence',
        );
      }
    } catch (_) {}
    return null;
  }

  // Policies Storage
  Future<void> savePolicies(String userId, List<InsurancePolicy> policies) async {
    await init();
    final raw = _prefs?.getString(_policiesKey);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try { map = jsonDecode(raw); } catch (_) {}
    }
    map[userId] = policies.map((p) => {
      'id': p.id,
      'policyNumber': p.policyNumber,
      'talonNumber': p.talonNumber,
      'companyName': p.companyName,
      'companyLogoPath': p.companyLogoPath,
      'coverageType': p.coverageType,
      'premiumAmount': p.premiumAmount,
      'startDate': p.startDate.toIso8601String(),
      'endDate': p.endDate.toIso8601String(),
      'status': p.status.index,
      'qrData': p.qrData,
      'brokerCode': p.brokerCode,
      'brokerAgencyName': p.brokerAgencyName,
      'clientName': p.clientName,
      'clientPhone': p.clientPhone,
      'guarantees': p.guarantees,
      'vehicle': {
        'id': p.vehicle.id,
        'plateNumber': p.vehicle.plateNumber,
        'make': p.vehicle.make,
        'model': p.vehicle.model,
        'year': p.vehicle.year,
        'chassisNumber': p.vehicle.chassisNumber,
        'fiscalPower': p.vehicle.fiscalPower,
        'fuelType': p.vehicle.fuelType,
      },
    }).toList();
    await _prefs?.setString(_policiesKey, jsonEncode(map));
  }

  Future<List<InsurancePolicy>?> getPolicies(String userId) async {
    await init();
    final raw = _prefs?.getString(_policiesKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = map[userId] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final vm = m['vehicle'] as Map<String, dynamic>? ?? {};
          return InsurancePolicy(
            id: m['id'] ?? 'pol_1',
            policyNumber: m['policyNumber'] ?? 'POL-AXA-2025-01',
            talonNumber: m['talonNumber'] ?? 'TAL-SN-2025-01',
            companyName: m['companyName'] ?? 'AXA Assurances Sénégal',
            companyLogoPath: m['companyLogoPath'] ?? 'assets/images/axa_logo.png',
            coverageType: m['coverageType'] ?? 'Formule Confort Plus',
            premiumAmount: (m['premiumAmount'] as num?)?.toDouble() ?? 250000.0,
            startDate: DateTime.tryParse(m['startDate'] ?? '') ?? DateTime.now().subtract(const Duration(days: 300)),
            endDate: DateTime.tryParse(m['endDate'] ?? '') ?? DateTime.now().add(const Duration(days: 65)),
            status: PolicyStatus.values[(m['status'] as int?) ?? 0],
            qrData: m['qrData'] ?? '',
            brokerCode: m['brokerCode'] ?? 'COURTIER-DAKAR-77',
            brokerAgencyName: m['brokerAgencyName'] ?? 'Cabinet AssurCourtage Dakar',
            clientName: m['clientName'],
            clientPhone: m['clientPhone'],
            guarantees: List<String>.from(m['guarantees'] ?? []),
            vehicle: VehicleModel(
              id: vm['id'] ?? 'veh_1',
              plateNumber: vm['plateNumber'] ?? 'DK-5489-BG',
              make: vm['make'] ?? 'Toyota',
              model: vm['model'] ?? 'Corolla',
              year: vm['year'] ?? 2022,
              chassisNumber: vm['chassisNumber'] ?? 'SN-VIN-001',
              fiscalPower: vm['fiscalPower'] ?? 7,
              fuelType: vm['fuelType'] ?? 'Essence',
            ),
          );
        }).toList();
      }
    } catch (_) {}
    return null;
  }

  // Transactions Storage
  Future<void> saveTransactions(String userId, List<TransactionModel> txs) async {
    await init();
    final raw = _prefs?.getString(_transactionsKey);
    Map<String, dynamic> map = {};
    if (raw != null && raw.isNotEmpty) {
      try { map = jsonDecode(raw); } catch (_) {}
    }
    map[userId] = txs.map((t) => {
      'id': t.id,
      'title': t.title,
      'subtitle': t.subtitle,
      'date': t.date.toIso8601String(),
      'amountFcfa': t.amountFcfa,
      'isPositive': t.isPositive,
      'status': t.status.index,
      'svgAsset': t.svgAsset,
    }).toList();
    await _prefs?.setString(_transactionsKey, jsonEncode(map));
  }

  Future<List<TransactionModel>?> getTransactions(String userId) async {
    await init();
    final raw = _prefs?.getString(_transactionsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final list = map[userId] as List<dynamic>?;
      if (list != null && list.isNotEmpty) {
        return list.map((item) {
          final m = item as Map<String, dynamic>;
          final isPos = m['isPositive'] == true;
          return TransactionModel(
            id: m['id'] ?? 'tx_1',
            title: m['title'] ?? 'Transaction',
            subtitle: m['subtitle'] ?? '',
            date: DateTime.tryParse(m['date'] ?? '') ?? DateTime.now(),
            amountFcfa: (m['amountFcfa'] as num?)?.toDouble() ?? 0.0,
            isPositive: isPos,
            status: TransactionStatus.values[(m['status'] as int?) ?? 0],
            icon: isPos ? Icons.card_giftcard_rounded : Icons.shield_rounded,
            svgAsset: m['svgAsset'] ?? 'assets/icons/shield_pay.svg',
            iconBgColor: isPos ? const Color(0xFFFFF1F2) : const Color(0xFFEEF2FF),
            iconColor: isPos ? const Color(0xFFF43F5E) : const Color(0xFF4F46E5),
          );
        }).toList();
      }
    } catch (_) {}
    return null;
  }
}
