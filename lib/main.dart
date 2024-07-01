import 'package:campominado/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'components/boxes.dart';
import 'components/score.dart';

void main() async {
  await Hive.initFlutter();
  Hive.registerAdapter(ScoreAdapter());
  boxScores = await Hive.openBox<Score>('boxScores');
  // Definindo a orientação preferida do dispositivo para o modo retrato.
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
