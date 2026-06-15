import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'firebase_config.dart';
import 'models.dart';

class FirebaseGroupRepository {
  FirebaseGroupRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn ?? _buildGoogleSignIn();

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  static GoogleSignIn _buildGoogleSignIn() {
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final isAndroid = defaultTargetPlatform == TargetPlatform.android;
    return GoogleSignIn(
      clientId: isIOS ? MeetGridFirebaseConfig.iosClientId : null,
      serverClientId: isAndroid ? MeetGridFirebaseConfig.androidClientId : null,
      scopes: const ['email', 'profile'],
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    final account = await _googleSignIn.signIn();
    if (account == null) {
      throw const AuthCancelledException();
    }

    final auth = await account.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await Future.wait([_googleSignIn.signOut(), _auth.signOut()]);
  }

  Stream<List<FriendGroup>> watchGroups(String uid) {
    return _firestore
        .collection('groups')
        .where('memberIDs', arrayContains: uid)
        .snapshots()
        .map((snapshot) {
          final groups = snapshot.docs
              .map((doc) => _groupFromDoc(doc.id, doc.data()))
              .toList();
          groups.sort((a, b) => a.name.compareTo(b.name));
          return groups;
        });
  }

  Future<FriendGroup> createGroup({
    required String uid,
    required String displayName,
    required String groupName,
  }) async {
    final doc = _firestore.collection('groups').doc();
    final member = Member(
      id: uid,
      name: _safeName(displayName),
      color: MemberColor.teal,
    );
    final group = FriendGroup(
      id: doc.id,
      name: groupName.trim().isEmpty ? '새 약속 그룹' : groupName.trim(),
      inviteCode: _inviteCode(doc.id),
      members: [member],
      memberIDs: [uid],
      availability: {uid: <TimeSlot>{}},
    );

    await doc.set(_groupToMap(group));
    return group;
  }

  Future<void> joinGroupByInviteCode({
    required String uid,
    required String displayName,
    required String inviteCode,
  }) async {
    final code = inviteCode.trim().toUpperCase();
    if (code.isEmpty) return;

    final snapshot = await _firestore
        .collection('groups')
        .where('inviteCode', isEqualTo: code)
        .limit(1)
        .get();
    if (snapshot.docs.isEmpty) {
      throw InviteCodeNotFoundException(code);
    }

    final reference = snapshot.docs.first.reference;
    await _firestore.runTransaction((transaction) async {
      final fresh = await transaction.get(reference);
      final group = _groupFromDoc(fresh.id, fresh.data() ?? {});
      if (group.memberIDs.contains(uid)) return;

      final colors = MemberColor.values;
      final member = Member(
        id: uid,
        name: _safeName(displayName),
        color: colors[group.members.length % colors.length],
      );

      final updated = group.copyWith(
        members: [...group.members, member],
        memberIDs: [...group.memberIDs, uid],
        availability: {...group.availability, uid: <TimeSlot>{}},
      );

      transaction.set(reference, _groupToMap(updated), SetOptions(merge: true));
    });
  }

  Future<void> toggleAvailability({
    required FriendGroup group,
    required String uid,
    required TimeSlot slot,
  }) async {
    final current = Set<TimeSlot>.from(group.availability[uid] ?? {});
    if (current.contains(slot)) {
      current.remove(slot);
    } else {
      current.add(slot);
    }
    await _firestore.collection('groups').doc(group.id).set({
      'availability': {uid: current.map((slot) => slot.toMap()).toList()},
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> confirmSlot({
    required FriendGroup group,
    required TimeSlot? slot,
  }) async {
    await _firestore.collection('groups').doc(group.id).set({
      'confirmedSlot': slot?.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Map<String, dynamic> _groupToMap(FriendGroup group) {
    return {
      'name': group.name,
      'inviteCode': group.inviteCode,
      'memberIDs': group.memberIDs,
      'members': group.members.map((member) => member.toMap()).toList(),
      'availability': group.availability.map(
        (id, slots) => MapEntry(id, slots.map((slot) => slot.toMap()).toList()),
      ),
      'confirmedSlot': group.confirmedSlot?.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  FriendGroup _groupFromDoc(String id, Map<String, dynamic> data) {
    final rawMembers = data['members'];
    final members = rawMembers is List
        ? rawMembers
              .whereType<Map>()
              .map((item) => Member.fromMap(Map<String, dynamic>.from(item)))
              .toList()
        : <Member>[];
    final memberIDs =
        (data['memberIDs'] as List?)?.whereType<String>().toList() ??
        members.map((member) => member.id).toList();

    final rawAvailability = data['availability'];
    final availability = <String, Set<TimeSlot>>{};
    if (rawAvailability is Map) {
      for (final entry in rawAvailability.entries) {
        final rawSlots = entry.value;
        availability[entry.key.toString()] = rawSlots is List
            ? rawSlots
                  .whereType<Map>()
                  .map(
                    (item) => TimeSlot.fromMap(Map<String, dynamic>.from(item)),
                  )
                  .toSet()
            : <TimeSlot>{};
      }
    }

    final rawConfirmed = data['confirmedSlot'];
    return FriendGroup(
      id: id,
      name: data['name'] as String? ?? '약속 그룹',
      inviteCode: data['inviteCode'] as String? ?? _inviteCode(id),
      members: members,
      memberIDs: memberIDs,
      availability: availability,
      confirmedSlot: rawConfirmed is Map
          ? TimeSlot.fromMap(Map<String, dynamic>.from(rawConfirmed))
          : null,
    );
  }

  String _inviteCode(String id) {
    final normalized = id.toUpperCase().replaceAll(RegExp('[^A-Z0-9]'), '');
    final suffix = normalized.padRight(4, '0').substring(0, 4);
    return 'MGT-$suffix';
  }

  String _safeName(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return '나';
    return trimmed;
  }
}

class AuthCancelledException implements Exception {
  const AuthCancelledException();
}

class InviteCodeNotFoundException implements Exception {
  const InviteCodeNotFoundException(this.code);

  final String code;
}
