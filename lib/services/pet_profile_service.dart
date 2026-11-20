import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PetProfile {
  final String name;
  final String breed;
  final String breedPhotoUrl;
  final String age;
  final List<String> careAreas;
  final DateTime? updatedAt;
  final String? gender;
  final String? microchip;

  const PetProfile({
    required this.name,
    required this.breed,
    required this.breedPhotoUrl,
    required this.age,
    required this.careAreas,
    this.updatedAt,
    this.gender,
    this.microchip,
  });

  factory PetProfile.fromMap(Map<String, dynamic> data) {
    List<String> parsedAreas = [];
    final rawAreas = data['careAreas'];
    if (rawAreas is List) {
      parsedAreas = rawAreas.map((e) => e.toString()).toList();
    }

    DateTime? parsedDate;
    final rawDate = data['updatedAt'];
    if (rawDate is Timestamp) {
      parsedDate = rawDate.toDate();
    } else if (rawDate is DateTime) {
      parsedDate = rawDate;
    }

    return PetProfile(
      name: (data['name'] as String?)?.trim().isNotEmpty == true
          ? (data['name'] as String).trim()
          : 'Pet',
      breed: (data['breed'] as String?)?.trim().isNotEmpty == true
          ? (data['breed'] as String).trim()
          : 'Golden Retriever',
      breedPhotoUrl: (data['breedPhotoUrl'] as String?) ?? '',
      age: (data['age'] as String?)?.trim().isNotEmpty == true
          ? (data['age'] as String).trim()
          : '3 years old',
      careAreas: parsedAreas,
      updatedAt: parsedDate,
      gender: data['gender'] as String?,
      microchip: data['microchip'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'breed': breed,
      'breedPhotoUrl': breedPhotoUrl,
      'age': age,
      'careAreas': careAreas,
      'updatedAt': FieldValue.serverTimestamp(),
      if (gender != null) 'gender': gender,
      if (microchip != null) 'microchip': microchip,
    };
  }

  PetProfile copyWith({
    String? name,
    String? breed,
    String? breedPhotoUrl,
    String? age,
    List<String>? careAreas,
    DateTime? updatedAt,
    String? gender,
    String? microchip,
  }) {
    return PetProfile(
      name: name ?? this.name,
      breed: breed ?? this.breed,
      breedPhotoUrl: breedPhotoUrl ?? this.breedPhotoUrl,
      age: age ?? this.age,
      careAreas: careAreas ?? this.careAreas,
      updatedAt: updatedAt ?? this.updatedAt,
      gender: gender ?? this.gender,
      microchip: microchip ?? this.microchip,
    );
  }
}

class PetProfileService {
  static final ValueNotifier<PetProfile?> petProfileNotifier =
      ValueNotifier<PetProfile?>(null);

  static PetProfile? get currentProfile => petProfileNotifier.value;
  static PetProfile? get localProfile => petProfileNotifier.value;

  static void setLocalProfile(PetProfile profile) {
    petProfileNotifier.value = profile;
  }

  static StreamSubscription<DocumentSnapshot>? _subscription;
  static String? _listeningUid;

  /// Start real-time Firestore sync for given UID
  static void listenToProfile(String uid) {
    if (_listeningUid == uid && _subscription != null) return;
    _listeningUid = uid;
    _subscription?.cancel();

    try {
      _subscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pet_profile')
          .doc('current')
          .snapshots()
          .listen((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          petProfileNotifier.value = PetProfile.fromMap(data);
        }
      }, onError: (e) {
        debugPrint('PetProfileService Firestore listen error: $e');
      });
    } catch (e) {
      debugPrint('PetProfileService listen exception: $e');
    }
  }

  /// Save pet profile to Firestore and update ValueNotifier immediately
  static Future<bool> saveProfile(String uid, PetProfile profile) async {
    petProfileNotifier.value = profile;
    bool savedToFirestore = false;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pet_profile')
          .doc('current')
          .set(profile.toMap(), SetOptions(merge: true));
      savedToFirestore = true;
    } catch (e) {
      debugPrint('Firestore pet profile save fallback to local memory: $e');
    }

    return savedToFirestore;
  }
}
