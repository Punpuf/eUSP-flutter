import 'meals_of_day.dart';

class MealsOfWeek {
  final int restaurantId;
  final String observation;
  final List<MealsOfDay> mealList;
  final int expirationDate;

  const MealsOfWeek({
    required this.restaurantId,
    required this.observation,
    required this.mealList,
    required this.expirationDate,
  });

  Map toJson() => {
    'restaurantId': restaurantId,
    'observation': observation,
    'mealList': mealList,
    'expirationDate': expirationDate,
  };
}