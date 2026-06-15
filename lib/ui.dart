import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'models.dart';

class MeetGridTheme {
  static ThemeData light() {
    const seed = Color(0xFF58B7C9);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: Brightness.light,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color(0xFFF7FAFB),
      fontFamily: 'Arial',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(fontWeight: FontWeight.w800),
        titleLarge: TextStyle(fontWeight: FontWeight.w800),
        titleMedium: TextStyle(fontWeight: FontWeight.w700),
        bodyMedium: TextStyle(height: 1.35),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: Color(0xFFF7FAFB),
        foregroundColor: Color(0xFF14232A),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: seed.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFE5EEF1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: Color(0xFFE5EEF1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: seed, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: seed,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF23424C),
          side: const BorderSide(color: Color(0xFFDDE9ED)),
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class MeetGridHome extends StatelessWidget {
  const MeetGridHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<MeetGridAppState>(
      builder: (context, state, _) {
        if (state.isBooting) {
          return const _SplashScreen();
        }
        if (!state.isSignedIn) {
          return const _LoginScreen();
        }
        return const _MainShell();
      },
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AppMark(size: 92),
            SizedBox(height: 22),
            Text(
              'MeetGrid',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Color(0xFF14232A),
              ),
            ),
            SizedBox(height: 18),
            CircularProgressIndicator(strokeWidth: 3),
          ],
        ),
      ),
    );
  }
}

class _LoginScreen extends StatelessWidget {
  const _LoginScreen();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeetGridAppState>();
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(
            children: [
              const Spacer(),
              const _AppMark(size: 112),
              const SizedBox(height: 24),
              const Text(
                'MeetGrid',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF14232A),
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '친구들의 가능한 시간을 한눈에 모아봐요.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF71828A),
                ),
              ),
              const SizedBox(height: 34),
              FilledButton.icon(
                onPressed: state.isBusy ? null : state.signInWithGoogle,
                icon: state.isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.account_circle_rounded),
                label: const Text('Google로 시작'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : state.enterDemoMode,
                icon: const Icon(Icons.play_circle_outline_rounded),
                label: const Text('데모로 둘러보기'),
              ),
              if (state.message != null) ...[
                const SizedBox(height: 18),
                _InfoBanner(message: state.message!),
              ],
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _MainShell extends StatelessWidget {
  const _MainShell();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeetGridAppState>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'MeetGrid',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(
            tooltip: '로그아웃',
            onPressed: state.isBusy ? null : state.signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (state.message != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
                child: _InfoBanner(
                  message: state.message!,
                  onClose: state.clearMessage,
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: state.selectedTab,
                children: const [
                  _GroupsPage(),
                  _AvailabilityPage(),
                  _ResultsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: state.selectedTab,
        onDestinationSelected: state.selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2_rounded),
            label: '그룹',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: '시간표',
          ),
          NavigationDestination(
            icon: Icon(Icons.auto_graph_rounded),
            selectedIcon: Icon(Icons.check_circle_rounded),
            label: '결과',
          ),
        ],
      ),
    );
  }
}

class _GroupsPage extends StatefulWidget {
  const _GroupsPage();

  @override
  State<_GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<_GroupsPage> {
  final _groupController = TextEditingController();
  final _inviteController = TextEditingController();

  @override
  void dispose() {
    _groupController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeetGridAppState>();
    final selected = state.selectedGroup;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Text(
          '${state.displayName}님, 어떤 약속을 맞출까요?',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 18),
        _SoftPanel(
          child: Column(
            children: [
              TextField(
                controller: _groupController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: '새 그룹 이름',
                  prefixIcon: Icon(Icons.add_circle_outline_rounded),
                ),
                onSubmitted: (_) => _createGroup(context),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: state.isBusy ? null : () => _createGroup(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('그룹 만들기'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SoftPanel(
          child: Column(
            children: [
              TextField(
                controller: _inviteController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: '초대코드',
                  prefixIcon: Icon(Icons.vpn_key_rounded),
                ),
                onSubmitted: (_) => _joinGroup(context),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: state.isBusy ? null : () => _joinGroup(context),
                icon: const Icon(Icons.login_rounded),
                label: const Text('초대코드로 참여'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            Text('내 그룹', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            if (state.demoMode)
              const _Pill(
                text: 'Demo',
                icon: Icons.bolt_rounded,
                color: Color(0xFFF4B84B),
              ),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < state.groups.length; index++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GroupTile(
              group: state.groups[index],
              selected: index == state.selectedGroupIndex,
              onTap: () => state.selectGroup(index),
            ),
          ),
        if (selected != null) ...[
          const SizedBox(height: 4),
          _MembersPanel(group: selected),
        ],
      ],
    );
  }

  void _createGroup(BuildContext context) {
    context.read<MeetGridAppState>().createGroup(_groupController.text);
    _groupController.clear();
  }

  void _joinGroup(BuildContext context) {
    context.read<MeetGridAppState>().joinGroup(_inviteController.text);
    _inviteController.clear();
  }
}

class _AvailabilityPage extends StatelessWidget {
  const _AvailabilityPage();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeetGridAppState>();
    final group = state.selectedGroup;
    if (group == null) {
      return const _EmptyState(
        icon: Icons.group_add_rounded,
        title: '그룹이 없어요',
        body: '먼저 약속 그룹을 만들어 주세요.',
      );
    }

    final catalog = ScheduleCatalog();
    final selectedKey = ScheduleCatalog.dateKey(state.selectedDate);
    final mySlots = group.availability[state.effectiveUserId] ?? {};
    final bestByDate = ScheduleCalculator.bestByDate(group);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: _GroupHeader(group: group),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 86,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, index) {
              final day = catalog.days[index];
              final key = ScheduleCatalog.dateKey(day);
              final best = bestByDate[key];
              return _DayChip(
                day: day,
                selected: key == selectedKey,
                overlapCount: best?.count ?? 0,
                totalMembers: group.memberIDs.length,
                onTap: () => state.selectDate(day),
              );
            },
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemCount: catalog.days.length,
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.45,
            ),
            itemCount: ScheduleCatalog.hours.length,
            itemBuilder: (context, index) {
              final hour = ScheduleCatalog.hours[index];
              final slot = TimeSlot(dateKey: selectedKey, startHour: hour);
              final selected = mySlots.contains(slot);
              final available = group.memberIDs.where((id) {
                return group.availability[id]?.contains(slot) ?? false;
              }).toList();
              return _TimeSlotButton(
                hour: hour,
                selected: selected,
                availableCount: available.length,
                totalMembers: group.memberIDs.length,
                onTap: () => state.toggleAvailability(slot),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultsPage extends StatelessWidget {
  const _ResultsPage();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<MeetGridAppState>();
    final group = state.selectedGroup;
    if (group == null) {
      return const _EmptyState(
        icon: Icons.auto_graph_rounded,
        title: '결과가 없어요',
        body: '그룹을 만들고 가능한 시간을 등록해 주세요.',
      );
    }

    final recommendations = ScheduleCalculator.recommendations(group);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _GroupHeader(group: group),
        const SizedBox(height: 14),
        if (group.confirmedSlot != null)
          _SoftPanel(
            accent: const Color(0xFF62CFA7),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE5F8F0),
                  foregroundColor: Color(0xFF2C9370),
                  child: Icon(Icons.check_rounded),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '확정된 약속 시간',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF668087),
                        ),
                      ),
                      Text(
                        ScheduleCatalog.displaySlot(group.confirmedSlot!),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: '확정 취소',
                  onPressed: state.clearConfirmedSlot,
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        Row(
          children: [
            Text('추천 시간', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            Text(
              '${group.memberIDs.length}명 기준',
              style: const TextStyle(
                color: Color(0xFF71828A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (recommendations.isEmpty)
          const _EmptyState(
            icon: Icons.touch_app_rounded,
            title: '아직 선택된 시간이 없어요',
            body: '시간표 탭에서 가능한 시간을 눌러보세요.',
          )
        else
          for (final overlap in recommendations)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecommendationTile(
                group: group,
                overlap: overlap,
                onConfirm: () => state.confirmSlot(overlap.slot),
              ),
            ),
      ],
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final FriendGroup group;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Row(
        children: [
          const _AppMark(size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(group.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 3),
                Text(
                  '초대코드 ${group.inviteCode}',
                  style: const TextStyle(
                    color: Color(0xFF71828A),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          _Pill(
            text: '${group.members.length}명',
            icon: Icons.person_rounded,
            color: const Color(0xFF58B7C9),
          ),
        ],
      ),
    );
  }
}

class _GroupTile extends StatelessWidget {
  const _GroupTile({
    required this.group,
    required this.selected,
    required this.onTap,
  });

  final FriendGroup group;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: selected
                  ? const Color(0xFF58B7C9)
                  : const Color(0xFFEAF1F3),
              width: selected ? 1.6 : 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0F2B4C55),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_off,
                color: selected
                    ? const Color(0xFF58B7C9)
                    : const Color(0xFFB4C1C6),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${group.inviteCode} · ${group.members.length}명 참여',
                      style: const TextStyle(
                        color: Color(0xFF71828A),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF9BAAB0)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembersPanel extends StatelessWidget {
  const _MembersPanel({required this.group});

  final FriendGroup group;

  @override
  Widget build(BuildContext context) {
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('참여 친구', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final member in group.members) _MemberChip(member: member),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({
    required this.group,
    required this.overlap,
    required this.onConfirm,
  });

  final FriendGroup group;
  final SlotOverlap overlap;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final ratio = overlap.totalMembers == 0
        ? 0.0
        : overlap.count / overlap.totalMembers;
    final color = overlap.isPerfect
        ? const Color(0xFF62CFA7)
        : const Color(0xFF58B7C9);
    return _SoftPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withValues(alpha: 0.14),
                foregroundColor: color,
                child: Icon(
                  overlap.isPerfect
                      ? Icons.done_all_rounded
                      : Icons.schedule_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ScheduleCatalog.displaySlot(overlap.slot),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${overlap.count}/${overlap.totalMembers}명 가능',
                      style: const TextStyle(
                        color: Color(0xFF71828A),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: '확정',
                onPressed: onConfirm,
                icon: const Icon(Icons.check_rounded),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: ratio,
              backgroundColor: const Color(0xFFEAF1F3),
              color: color,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final member in group.members)
                _AvailabilityAvatar(
                  member: member,
                  enabled: overlap.availableMemberIds.contains(member.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayChip extends StatelessWidget {
  const _DayChip({
    required this.day,
    required this.selected,
    required this.overlapCount,
    required this.totalMembers,
    required this.onTap,
  });

  final DateTime day;
  final bool selected;
  final int overlapCount;
  final int totalMembers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF58B7C9) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Ink(
          width: 76,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? const Color(0xFF58B7C9)
                  : const Color(0xFFEAF1F3),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ScheduleCatalog.weekdayLabel(day),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF71828A),
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                ScheduleCatalog.displayDate(day),
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF14232A),
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                totalMembers == 0 ? '-' : '$overlapCount/$totalMembers',
                style: TextStyle(
                  color: selected ? Colors.white70 : const Color(0xFF9BAAB0),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeSlotButton extends StatelessWidget {
  const _TimeSlotButton({
    required this.hour,
    required this.selected,
    required this.availableCount,
    required this.totalMembers,
    required this.onTap,
  });

  final int hour;
  final bool selected;
  final int availableCount;
  final int totalMembers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF58B7C9) : Colors.white;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: selected
                  ? const Color(0xFF58B7C9)
                  : const Color(0xFFEAF1F3),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A2B4C55),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: selected ? Colors.white : const Color(0xFF9BAAB0),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$hour:00',
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : const Color(0xFF14232A),
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      '$availableCount/$totalMembers명 가능',
                      style: TextStyle(
                        color: selected
                            ? Colors.white70
                            : const Color(0xFF71828A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MemberChip extends StatelessWidget {
  const _MemberChip({required this.member});

  final Member member;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: member.color.softFill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(radius: 5, backgroundColor: member.color.fill),
          const SizedBox(width: 6),
          Text(
            member.name,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: Color(0xFF23424C),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityAvatar extends StatelessWidget {
  const _AvailabilityAvatar({required this.member, required this.enabled});

  final Member member;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: enabled ? 1 : 0.35,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: enabled ? member.color.softFill : const Color(0xFFF0F4F5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              enabled
                  ? Icons.check_circle_rounded
                  : Icons.remove_circle_outline_rounded,
              size: 16,
              color: enabled ? member.color.fill : const Color(0xFF9BAAB0),
            ),
            const SizedBox(width: 5),
            Text(
              member.name,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftPanel extends StatelessWidget {
  const _SoftPanel({required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: accent?.withValues(alpha: 0.32) ?? const Color(0xFFEAF1F3),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F2B4C55),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.message, this.onClose});

  final String message;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FA),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD7EEF3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Color(0xFF3A9CAD)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Color(0xFF23424C),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (onClose != null)
            IconButton(
              tooltip: '닫기',
              onPressed: onClose,
              icon: const Icon(Icons.close_rounded),
            ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.icon, required this.color});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppMark extends StatelessWidget {
  const _AppMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: const [
          BoxShadow(
            color: Color(0x142B4C55),
            blurRadius: 28,
            offset: Offset(0, 14),
          ),
        ],
      ),
      child: Container(
        margin: EdgeInsets.all(size * 0.18),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF7FA),
          borderRadius: BorderRadius.circular(size * 0.16),
        ),
        child: Icon(
          Icons.calendar_month_rounded,
          size: size * 0.42,
          color: const Color(0xFF58B7C9),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 34,
              backgroundColor: const Color(0xFFEAF7FA),
              foregroundColor: const Color(0xFF58B7C9),
              child: Icon(icon, size: 34),
            ),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF71828A),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
