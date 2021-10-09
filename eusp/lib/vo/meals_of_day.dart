import 'package:intl/intl.dart';

class MealsOfDay {
  final String date;
  final int dateProcessedStart;
  final int dateProcessedEnd;
  final String lunchMenu;
  final String lunchCalories;
  final String dinnerMenu;
  final String dinnerCalories;

  const MealsOfDay({
    required this.date,
    required this.dateProcessedStart,
    required this.dateProcessedEnd,
    required this.lunchMenu,
    required this.lunchCalories,
    required this.dinnerMenu,
    required this.dinnerCalories,
  });

  factory MealsOfDay.fromJson(Map<String, dynamic> json) {
    String date = json['date'] as String;
    DateTime tempDate = DateFormat("dd/MM/yyyy").parse(date);
    int timestampStart = tempDate.millisecondsSinceEpoch;
    int timestampEnd = (tempDate.add(const Duration(hours: 23, minutes: 59, seconds: 59))).millisecondsSinceEpoch;

    return MealsOfDay(
      date: date,
      dateProcessedStart: timestampStart, //json['albumId'] as int,
      dateProcessedEnd: timestampEnd,
      lunchMenu: json['lunch']['menu'],
      lunchCalories: json['lunch']['calories'],
      dinnerMenu: json['dinner']['menu'],
      dinnerCalories: json['dinner']['calories'],
    );
  }
}