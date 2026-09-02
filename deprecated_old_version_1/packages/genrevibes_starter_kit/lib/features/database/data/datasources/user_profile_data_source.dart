import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/subscription_tier.dart';
import '../models/user_profile_model.dart';

/// Abstract interface for user profile data source
abstract class UserProfileDataSource {
  Future<UserProfileModel?> getUserProfile(String uid);
  Future<UserProfileModel?> getUserProfileByEmail(String email);
  Future<void> createUserProfile(UserProfileModel profile);
  Future<void> updateUserProfile(UserProfileModel profile);
  Future<void> updatePreferences(String uid, Map<String, dynamic> preferences);
  Future<void> incrementUsage(String uid, String usageKey);
  Future<void> updateSubscription({
    required String uid,
    required SubscriptionTier tier,
    String? subscriptionId,
    DateTime? startDate,
    DateTime? renewalDate,
    String? provider,
    Map<String, dynamic>? metadata,
  });
  Future<void> updateTrialStatus({
    required String uid,
    required bool isActive,
    DateTime? startDate,
    DateTime? endDate,
  });
  Stream<UserProfileModel?> userProfileStream(String uid);
  Future<void> updateLastActive(String uid);
  Future<void> deleteUserProfile(String uid);
}

/// Firestore implementation of user profile data source
class UserProfileDataSourceImpl implements UserProfileDataSource {
  final FirebaseFirestore _firestore;

  /// Collection path for user profiles
  static const String _usersCollection = 'users';

  /// Top-level subcollections (under the user doc) to delete when the account
  /// is removed. Empty by default so the generic kit doesn't assume any
  /// app-specific collections exist; hosts pass what they need (e.g. ['chats']).
  // TODO(feature-audit): chat-specific; strip from kit when audited
  final List<String> subcollectionsToDelete;

  UserProfileDataSourceImpl({
    FirebaseFirestore? firestore,
    this.subcollectionsToDelete = const [],
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(_usersCollection);

  @override
  Future<UserProfileModel?> getUserProfile(String uid) async {
    final doc =
        await _usersRef.doc(uid).collection('userDetails').doc('profile').get();
    if (!doc.exists) return null;
    return UserProfileModel.fromFirestore(doc);
  }

  @override
  Future<UserProfileModel?> getUserProfileByEmail(String email) async {
    final cleanedEmail = email.trim().toLowerCase();
    if (kDebugMode) {
      print(
          'DEBUG PREFILL [DataSource SK]: Searching for email: "$cleanedEmail"');
    }

    // Search top-level users collection for the email
    final topQuery =
        await _usersRef.where('email', isEqualTo: cleanedEmail).limit(1).get();

    if (topQuery.docs.isNotEmpty) {
      // We found the user's UID. Now fetch their full profile from the subcollection.
      final uid = topQuery.docs.first.id;
      if (kDebugMode) {
        print('DEBUG PREFILL [DataSource SK]: Found top-level UID: "$uid"');
      }

      final profile = await getUserProfile(uid);

      // If profile exists in subcollection, return it.
      if (profile != null) {
        if (kDebugMode) {
          print(
              'DEBUG PREFILL [DataSource SK]: Found full profile in userDetails for UID "$uid", Name: "${profile.displayName}"');
        }
        return profile;
      }

      // Fallback: If they haven't been migrated to subcollection yet, return the top-level document
      if (kDebugMode) {
        print(
            'DEBUG PREFILL [DataSource SK]: Profile not found in userDetails, falling back to top-level doc for UID "$uid"');
      }
      return UserProfileModel.fromFirestore(topQuery.docs.first);
    }

    if (kDebugMode) {
      print(
          'DEBUG PREFILL [DataSource SK]: NO user found with email "$cleanedEmail"');
    }
    return null;
  }

  @override
  Future<void> createUserProfile(UserProfileModel profile) async {
    // Standardize email to lowercase for searchability
    final data = profile.toJson();
    if (data['email'] != null) {
      data['email'] = (data['email'] as String).toLowerCase();
    }

    // Write full profile to the subcollection
    await _usersRef
        .doc(profile.uid)
        .collection('userDetails')
        .doc('profile')
        .set(data);

    // Write just the email to the top-level document for index-free searching
    if (data['email'] != null) {
      await _usersRef.doc(profile.uid).set({
        'email': data['email'],
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> updateUserProfile(UserProfileModel profile) async {
    // Standardize email to lowercase for searchability
    final data = profile.toJson();
    if (data['email'] != null) {
      data['email'] = (data['email'] as String).toLowerCase();
    }

    // Update full profile in the subcollection
    await _usersRef
        .doc(profile.uid)
        .collection('userDetails')
        .doc('profile')
        .update(data);

    // Write just the email to the top-level document for index-free searching
    if (data['email'] != null) {
      await _usersRef.doc(profile.uid).set({
        'email': data['email'],
      }, SetOptions(merge: true));
    }
  }

  @override
  Future<void> updatePreferences(
    String uid,
    Map<String, dynamic> preferences,
  ) async {
    await _usersRef.doc(uid).collection('userDetails').doc('profile').update({
      'preferences': preferences,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> incrementUsage(String uid, String usageKey) async {
    await _usersRef.doc(uid).collection('userDetails').doc('profile').update({
      'usageStats.$usageKey': FieldValue.increment(1),
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> updateSubscription({
    required String uid,
    required SubscriptionTier tier,
    String? subscriptionId,
    DateTime? startDate,
    DateTime? renewalDate,
    String? provider,
    Map<String, dynamic>? metadata,
  }) async {
    final updates = <String, dynamic>{
      'tier': tier.value,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (subscriptionId != null) updates['subscriptionId'] = subscriptionId;
    if (startDate != null) {
      updates['subscriptionStartDate'] = startDate.toIso8601String();
    }
    if (renewalDate != null) {
      updates['subscriptionRenewalDate'] = renewalDate.toIso8601String();
    }
    if (provider != null) updates['subscriptionProvider'] = provider;
    if (metadata != null) updates['subscriptionMetadata'] = metadata;

    await _usersRef
        .doc(uid)
        .collection('userDetails')
        .doc('profile')
        .update(updates);
  }

  @override
  Future<void> updateTrialStatus({
    required String uid,
    required bool isActive,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final updates = <String, dynamic>{
      'isTrialActive': isActive,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    if (startDate != null) {
      updates['trialStartDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      updates['trialEndDate'] = endDate.toIso8601String();
    }

    await _usersRef
        .doc(uid)
        .collection('userDetails')
        .doc('profile')
        .update(updates);
  }

  @override
  Stream<UserProfileModel?> userProfileStream(String uid) {
    return _usersRef
        .doc(uid)
        .collection('userDetails')
        .doc('profile')
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return UserProfileModel.fromFirestore(doc);
    });
  }

  @override
  Future<void> updateLastActive(String uid) async {
    await _usersRef.doc(uid).collection('userDetails').doc('profile').update({
      'lastActiveAt': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<void> deleteUserProfile(String uid) async {
    // Delete subcollections first
    await _deleteSubcollections(uid);
    // Delete the nested userDetails profile
    await _usersRef.doc(uid).collection('userDetails').doc('profile').delete();
    // Delete the main document
    await _usersRef.doc(uid).delete();
  }

  Future<void> _deleteSubcollections(String uid) async {
    // Delete each host-configured subcollection. With the default empty list
    // this is a no-op, so the generic kit doesn't touch collections that may
    // not exist for a given app.
    // TODO(feature-audit): chat-specific deep-delete previously hardcoded
    // chats/messages; strip from kit when audited.
    for (final name in subcollectionsToDelete) {
      final ref = _usersRef.doc(uid).collection(name);
      final docs = await ref.get();
      for (final doc in docs.docs) {
        await doc.reference.delete();
      }
    }

    // Also delete any other documents in userDetails if they exist
    final detailsRef = _usersRef.doc(uid).collection('userDetails');
    final details = await detailsRef.get();
    for (final detail in details.docs) {
      await detail.reference.delete();
    }
  }
}
