import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'firebase_config.dart';
import 'firebase_group_repository.dart';
import 'models.dart';

class MeetGridAppState extends ChangeNotifier {
  MeetGridAppState({FirebaseGroupRepository? repository}) {
    _repository = repository;
  }

  FirebaseGroupRepository? _repository;
  StreamSubscription<List<FriendGroup>>? _groupsSubscription;

  bool _isBooting = true;
  bool _isBusy = false;
  bool _firebaseReady = false;
  bool _demoMode = false;
  String? _userId;
  String _displayName = '나';
  String? _message;
  List<FriendGroup> _groups = [SampleData.group()];
  int _selectedGroupIndex = 0;
  int _selectedTab = 0;
  DateTime _selectedDate = ScheduleCatalog().days.first;

  bool get isBooting => _isBooting;
  bool get isBusy => _isBusy;
  bool get firebaseReady => _firebaseReady;
  bool get demoMode => _demoMode;
  bool get isSignedIn => _userId != null;
  String? get userId => _userId;
  String get displayName => _displayName;
  String? get message => _message;
  List<FriendGroup> get groups => _groups;
  int get selectedGroupIndex => _selectedGroupIndex;
  int get selectedTab => _selectedTab;
  DateTime get selectedDate => _selectedDate;

  FriendGroup? get selectedGroup {
    if (_groups.isEmpty) return null;
    final index = _selectedGroupIndex.clamp(0, _groups.length - 1);
    return _groups[index];
  }

  String get effectiveUserId => _userId ?? 'local-user';

  Future<void> start() async {
    _isBooting = true;
    notifyListeners();

    try {
      await Firebase.initializeApp(
        options: MeetGridFirebaseConfig.currentOptions,
      );
      _repository ??= FirebaseGroupRepository();
      _firebaseReady = true;
      final user = _repository!.currentUser;
      if (user != null) {
        _setUser(user.uid, user.displayName);
        _watchRemoteGroups(user.uid);
      } else {
        _message = 'Google로 로그인하면 그룹이 Firebase에 저장됩니다.';
      }
    } catch (error) {
      _firebaseReady = false;
      _demoMode = true;
      _userId = 'local-user';
      _message = 'Firebase 설정을 확인하는 동안 로컬 데모로 열었어요.';
    } finally {
      _isBooting = false;
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() async {
    final repository = _repository;
    if (!_firebaseReady || repository == null) {
      enterDemoMode();
      return;
    }

    await _runBusy(() async {
      try {
        final credential = await repository.signInWithGoogle();
        final user = credential.user;
        if (user == null) return;
        _setUser(user.uid, user.displayName);
        _demoMode = false;
        _message = '$_displayName님으로 로그인했어요.';
        _watchRemoteGroups(user.uid);
      } on AuthCancelledException {
        _message = 'Google 로그인을 취소했어요.';
      } catch (error) {
        _message = '로그인을 완료하지 못했어요. Firebase 설정을 다시 확인해 주세요.';
      }
    });
  }

  Future<void> signOut() async {
    await _runBusy(() async {
      await _groupsSubscription?.cancel();
      _groupsSubscription = null;
      if (_repository != null && _firebaseReady) {
        await _repository!.signOut();
      }
      _userId = null;
      _displayName = '나';
      _groups = [SampleData.group()];
      _selectedGroupIndex = 0;
      _demoMode = false;
      _message = '로그아웃했어요.';
    });
  }

  void enterDemoMode() {
    _demoMode = true;
    _userId = 'local-user';
    _displayName = '나';
    _groups = [SampleData.group()];
    _selectedGroupIndex = 0;
    _message = '로컬 데모 그룹으로 시작했어요.';
    notifyListeners();
  }

  void selectTab(int index) {
    _selectedTab = index;
    notifyListeners();
  }

  void selectGroup(int index) {
    _selectedGroupIndex = index.clamp(0, _groups.length - 1);
    notifyListeners();
  }

  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  Future<void> createGroup(String name) async {
    final cleaned = name.trim();
    await _runBusy(() async {
      if (_canUseRemote) {
        final group = await _repository!.createGroup(
          uid: effectiveUserId,
          displayName: _displayName,
          groupName: cleaned,
        );
        _message = '${group.name} 그룹을 만들었어요.';
      } else {
        final group = _localGroup(cleaned.isEmpty ? '새 약속 그룹' : cleaned);
        _groups = [group, ..._groups];
        _selectedGroupIndex = 0;
        _message = '${group.name} 그룹을 만들었어요.';
      }
    });
  }

  Future<void> joinGroup(String inviteCode) async {
    await _runBusy(() async {
      if (_canUseRemote) {
        try {
          await _repository!.joinGroupByInviteCode(
            uid: effectiveUserId,
            displayName: _displayName,
            inviteCode: inviteCode,
          );
          _message = '초대코드로 그룹에 참여했어요.';
        } on InviteCodeNotFoundException {
          _message = '해당 초대코드를 찾지 못했어요.';
        }
      } else {
        _message = '데모 모드에서는 샘플 초대코드 MGT-4281을 사용할 수 있어요.';
      }
    });
  }

  Future<void> toggleAvailability(TimeSlot slot) async {
    final group = selectedGroup;
    if (group == null) return;

    await _runBusy(() async {
      if (_canUseRemote && group.id != 'sample-group') {
        await _repository!.toggleAvailability(
          group: group,
          uid: effectiveUserId,
          slot: slot,
        );
      } else {
        _updateLocalSelectedGroup((current) {
          final slots = Set<TimeSlot>.from(
            current.availability[effectiveUserId] ?? {},
          );
          slots.contains(slot) ? slots.remove(slot) : slots.add(slot);
          return current.copyWith(
            availability: {...current.availability, effectiveUserId: slots},
          );
        });
      }
    }, silent: true);
  }

  Future<void> confirmSlot(TimeSlot slot) async {
    final group = selectedGroup;
    if (group == null) return;

    await _runBusy(() async {
      if (_canUseRemote && group.id != 'sample-group') {
        await _repository!.confirmSlot(group: group, slot: slot);
      } else {
        _updateLocalSelectedGroup(
          (current) => current.copyWith(confirmedSlot: slot),
        );
      }
      _message = '${ScheduleCatalog.displaySlot(slot)}로 확정했어요.';
    });
  }

  Future<void> clearConfirmedSlot() async {
    final group = selectedGroup;
    if (group == null) return;

    await _runBusy(() async {
      if (_canUseRemote && group.id != 'sample-group') {
        await _repository!.confirmSlot(group: group, slot: null);
      } else {
        _updateLocalSelectedGroup(
          (current) => current.copyWith(confirmedSlot: null),
        );
      }
      _message = '확정 시간을 비웠어요.';
    });
  }

  void clearMessage() {
    _message = null;
    notifyListeners();
  }

  bool get _canUseRemote => _firebaseReady && !_demoMode && _userId != null;

  void _setUser(String uid, String? displayName) {
    _userId = uid;
    final trimmed = displayName?.trim();
    _displayName = trimmed == null || trimmed.isEmpty ? '나' : trimmed;
  }

  void _watchRemoteGroups(String uid) {
    _groupsSubscription?.cancel();
    _groupsSubscription = _repository!
        .watchGroups(uid)
        .listen(
          (groups) {
            _groups = groups.isEmpty ? [SampleData.group()] : groups;
            _selectedGroupIndex = _selectedGroupIndex.clamp(
              0,
              _groups.length - 1,
            );
            notifyListeners();
          },
          onError: (_) {
            _message = '그룹 정보를 불러오지 못했어요. Firestore 규칙을 확인해 주세요.';
            notifyListeners();
          },
        );
  }

  Future<void> _runBusy(
    Future<void> Function() action, {
    bool silent = false,
  }) async {
    _isBusy = true;
    if (!silent) notifyListeners();
    try {
      await action();
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  void _updateLocalSelectedGroup(FriendGroup Function(FriendGroup) transform) {
    final group = selectedGroup;
    if (group == null) return;
    final updated = transform(group);
    _groups = [
      for (var index = 0; index < _groups.length; index++)
        if (index == _selectedGroupIndex) updated else _groups[index],
    ];
  }

  FriendGroup _localGroup(String name) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    return FriendGroup(
      id: id,
      name: name,
      inviteCode: 'MGT-${id.substring(id.length - 4)}',
      members: const [
        Member(id: 'local-user', name: '나', color: MemberColor.teal),
      ],
      memberIDs: const ['local-user'],
      availability: const {'local-user': <TimeSlot>{}},
    );
  }

  @override
  void dispose() {
    _groupsSubscription?.cancel();
    super.dispose();
  }
}
