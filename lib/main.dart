import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'ui.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MeetGridApp());
}

class MeetGridApp extends StatelessWidget {
  const MeetGridApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MeetGridAppState()..start(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MeetGrid',
        theme: MeetGridTheme.light(),
        home: const MeetGridHome(),
      ),
    );
  }
}
