import 'package:hive/hive.dart';

part 'score.g.dart';

@HiveType(typeId: 1)
class Score {
  Score({
    required this.name,
    required this.time
  });

  @HiveField(0)
  String name;

  @HiveField(1)
  int time;

}