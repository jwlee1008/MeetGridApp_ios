import 'package:flutter/material.dart';

@immutable
class TimeSlot {
  const TimeSlot({required this.dateKey, required this.startHour});

  final String dateKey;
  final int startHour;

  String get id => '$dateKey-$startHour';

  Map<String, dynamic> toMap() => {'dateKey': dateKey, 'startHour': startHour};

  factory TimeSlot.fromMap(Map<String, dynamic> data) {
    return TimeSlot(
      dateKey: data['dateKey'] as String? ?? '',
      startHour: (data['startHour'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TimeSlot &&
        other.dateKey == dateKey &&
        other.startHour == startHour;
  }

  @override
  int get hashCode => Object.hash(dateKey, startHour);
}

@immutable
class Member {
  const Member({required this.id, required this.name, required this.color});

  final String id;
  final String name;
  final MemberColor color;

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'color': color.name};

  factory Member.fromMap(Map<String, dynamic> data) {
    return Member(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '친구',
      color: MemberColor.fromName(data['color'] as String?),
    );
  }
}

enum MemberColor {
  teal,
  coral,
  violet,
  amber,
  mint,
  blue;

  static MemberColor fromName(String? value) {
    return MemberColor.values.firstWhere(
      (color) => color.name == value,
      orElse: () => MemberColor.teal,
    );
  }

  Color get fill {
    return switch (this) {
      MemberColor.teal => const Color(0xFF58B7C9),
      MemberColor.coral => const Color(0xFFFF8E7A),
      MemberColor.violet => const Color(0xFF9B8CFF),
      MemberColor.amber => const Color(0xFFF4B84B),
      MemberColor.mint => const Color(0xFF62CFA7),
      MemberColor.blue => const Color(0xFF6EA8FE),
    };
  }

  Color get softFill => fill.withValues(alpha: 0.14);
}

@immutable
class FriendGroup {
  const FriendGroup({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.members,
    required this.memberIDs,
    required this.availability,
    this.confirmedSlot,
  });

  final String id;
  final String name;
  final String inviteCode;
  final List<Member> members;
  final List<String> memberIDs;
  final Map<String, Set<TimeSlot>> availability;
  final TimeSlot? confirmedSlot;

  FriendGroup copyWith({
    String? id,
    String? name,
    String? inviteCode,
    List<Member>? members,
    List<String>? memberIDs,
    Map<String, Set<TimeSlot>>? availability,
    Object? confirmedSlot = _sentinel,
  }) {
    return FriendGroup(
      id: id ?? this.id,
      name: name ?? this.name,
      inviteCode: inviteCode ?? this.inviteCode,
      members: members ?? this.members,
      memberIDs: memberIDs ?? this.memberIDs,
      availability: availability ?? this.availability,
      confirmedSlot: identical(confirmedSlot, _sentinel)
          ? this.confirmedSlot
          : confirmedSlot as TimeSlot?,
    );
  }
}

const Object _sentinel = Object();

@immutable
class SlotOverlap {
  const SlotOverlap({
    required this.slot,
    required this.availableMemberIds,
    required this.totalMembers,
  });

  final TimeSlot slot;
  final Set<String> availableMemberIds;
  final int totalMembers;

  int get count => availableMemberIds.length;
  bool get isPerfect => count == totalMembers && totalMembers > 0;
}

class ScheduleCatalog {
  ScheduleCatalog({DateTime? now}) : now = now ?? DateTime.now();

  final DateTime now;

  static const List<int> hours = [
    9,
    10,
    11,
    12,
    13,
    14,
    15,
    16,
    17,
    18,
    19,
    20,
    21,
    22,
  ];

  List<DateTime> get days {
    final today = DateTime(now.year, now.month, now.day);
    return List.generate(30, (index) => today.add(Duration(days: index)));
  }

  static String dateKey(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final year = normalized.year.toString().padLeft(4, '0');
    final month = normalized.month.toString().padLeft(2, '0');
    final day = normalized.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String weekdayLabel(DateTime date) {
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[date.weekday - 1];
  }

  static String displayDate(DateTime date) {
    return '${date.month}.${date.day}';
  }

  static String displaySlot(TimeSlot slot) {
    return '${slot.dateKey.substring(5).replaceAll('-', '.')} ${slot.startHour}:00';
  }
}

class ScheduleCalculator {
  static List<SlotOverlap> recommendations(FriendGroup group) {
    final allSlots = <TimeSlot>{};
    for (final slots in group.availability.values) {
      allSlots.addAll(slots);
    }

    final overlaps = allSlots.map((slot) {
      final ids = group.memberIDs.where((id) {
        return group.availability[id]?.contains(slot) ?? false;
      }).toSet();
      return SlotOverlap(
        slot: slot,
        availableMemberIds: ids,
        totalMembers: group.memberIDs.length,
      );
    }).toList();

    overlaps.sort((a, b) {
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      final byDate = a.slot.dateKey.compareTo(b.slot.dateKey);
      if (byDate != 0) return byDate;
      return a.slot.startHour.compareTo(b.slot.startHour);
    });

    return overlaps.take(8).toList();
  }

  static Map<String, SlotOverlap> bestByDate(FriendGroup group) {
    final best = <String, SlotOverlap>{};
    for (final overlap in recommendations(group)) {
      final current = best[overlap.slot.dateKey];
      if (current == null || overlap.count > current.count) {
        best[overlap.slot.dateKey] = overlap;
      }
    }
    return best;
  }
}

class SampleData {
  static FriendGroup group() {
    final catalog = ScheduleCatalog();
    final keys = catalog.days.map(ScheduleCatalog.dateKey).toList();
    const me = 'local-user';
    const mina = 'mina';
    const jun = 'jun';
    const seo = 'seo';

    return FriendGroup(
      id: 'sample-group',
      name: '기말 뒤풀이 약속',
      inviteCode: 'MGT-4281',
      memberIDs: const [me, mina, jun, seo],
      members: const [
        Member(id: me, name: '나', color: MemberColor.teal),
        Member(id: mina, name: '민아', color: MemberColor.coral),
        Member(id: jun, name: '준호', color: MemberColor.violet),
        Member(id: seo, name: '서연', color: MemberColor.amber),
      ],
      availability: {
        me: {
          TimeSlot(dateKey: keys[1], startHour: 18),
          TimeSlot(dateKey: keys[1], startHour: 19),
          TimeSlot(dateKey: keys[2], startHour: 17),
          TimeSlot(dateKey: keys[4], startHour: 20),
        },
        mina: {
          TimeSlot(dateKey: keys[1], startHour: 18),
          TimeSlot(dateKey: keys[1], startHour: 19),
          TimeSlot(dateKey: keys[3], startHour: 18),
          TimeSlot(dateKey: keys[4], startHour: 20),
        },
        jun: {
          TimeSlot(dateKey: keys[1], startHour: 19),
          TimeSlot(dateKey: keys[2], startHour: 17),
          TimeSlot(dateKey: keys[4], startHour: 20),
        },
        seo: {
          TimeSlot(dateKey: keys[1], startHour: 18),
          TimeSlot(dateKey: keys[1], startHour: 19),
          TimeSlot(dateKey: keys[4], startHour: 20),
          TimeSlot(dateKey: keys[5], startHour: 16),
        },
      },
      confirmedSlot: null,
    );
  }
}
