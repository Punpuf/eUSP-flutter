import 'dart:convert';

import 'package:eusp/vo/meals_of_day.dart';
import 'package:eusp/vo/meals_of_week.dart';
import 'package:eusp/vo/restaurant.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

List<Restaurant> parseRestaurants(Map params) {
  String responseBody = params['responseBody'];

  final parsed = jsonDecode(responseBody).cast<Map<String, dynamic>>();

  return parsed.map<Restaurant>((json) => Restaurant.fromJson(json)).toList();
}

Future<List<Restaurant>> fetchRestaurantList() async {
  final Map<String, String> qParams = {'alt': 'media'};
  final response = await http.get(Uri.https(
    'firebasestorage.googleapis.com',
    '/v0/b/e-bandejao-usp-beta.appspot.com/o/usp-restaurant-list.json',
    qParams,
  ));

  if (response.statusCode == 200) {
    return compute(parseRestaurants, {'responseBody': response.body});
  } else {
    throw Exception('Deu pane no sistema');
  }
}


MealsOfWeek parseMeals(Map params) {
  int restaurantId = params['restaurantId'];
  String responseBody = params['responseBody'];

  final parsed = json.decode(responseBody);

  bool hasError = parsed['message']['error'];
  if (hasError) throw(parsed['message']['message']);


  List<MealsOfDay> mealList =
  parsed['meals'].map<MealsOfDay>((json) => MealsOfDay.fromJson(json)).toList();
  String observation = parsed['observation']['observation'];
  int expirationDate = mealList.last.dateProcessedEnd;

  return MealsOfWeek(
    restaurantId: restaurantId,
    mealList: mealList,
    observation: observation,
    expirationDate: expirationDate,
  );
}

Future<MealsOfWeek> fetchRestaurantWeeklyMenu(int restaurantId) async {
  final Map<String, String> qParams = {'hash': '596df9effde6f877717b4e81fdb2ca9f'};
  final response = await http.get(Uri.https(
    'uspdigital.usp.br',
    '/rucard/servicos/menu/$restaurantId',
    qParams,
  ));

  if (response.statusCode == 200) {
    Map map = {};
    map['restaurantId'] = restaurantId;
    map['responseBody'] = response.body;
    return compute(parseMeals, map);
  } else {
    throw Exception('Deu pane no sistema');
  }
}