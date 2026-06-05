// Script to fix admin user's choyxonaId
// Run with: dart run fix_choyxona_id.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  final firestore = FirebaseFirestore.instance;
  
  // Find admin user
  final adminQuery = await firestore
      .collection('users')
      .where('email', isEqualTo: 'admin@gmail.com')
      .get();
  
  if (adminQuery.docs.isEmpty) {
    print('❌ Admin user not found');
    return;
  }
  
  final adminDoc = adminQuery.docs.first;
  final data = adminDoc.data();
  final currentChoyxonaId = data['choyxonaId'] as String?;
  
  print('Current choyxonaId: $currentChoyxonaId');
  
  if (currentChoyxonaId == null) {
    print('❌ choyxonaId is null');
    return;
  }
  
  // Remove extra quotes if present
  String fixedId = currentChoyxonaId;
  if (fixedId.startsWith('"') && fixedId.endsWith('"')) {
    fixedId = fixedId.substring(1, fixedId.length - 1);
    print('✅ Removing quotes: $fixedId');
  }
  
  // Update document
  await adminDoc.reference.update({'choyxonaId': fixedId});
  print('✅ Updated choyxonaId to: $fixedId');
}
