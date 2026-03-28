import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> initializeEconomyMetrics() async {
  final firestore = FirebaseFirestore.instance;
  final economyRef = firestore.collection('system_metrics').doc('economy_v1');

  try {
    final doc = await economyRef.get();
    if (!doc.exists) {
      debugPrint('Initializing Economy Metrics...');
      await economyRef.set({
        'total_treasury_balance': 0.0,
        'total_bonuses_paid': 0.0,
        'total_credits_minted': 0.0,
        'last_updated': FieldValue.serverTimestamp(),
        'version': 'v1',
      });
      debugPrint('Economy Metrics Initialized.');
    } else {
      debugPrint('Economy Metrics already exists.');
    }
  } catch (e) {
    debugPrint('Error initializing economy: $e');
  }
}
