import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';



class Restaurant {
  final int id;
  final String name;
  final String campusName;
  final String thumbnailUrl;
  final String address;
  final String latitude;
  final String longitude;
  final String phoneNumber;
  final String workingHours_weekday;
  final String workingHours_saturday;
  final String workingHours_sunday;
  final String cashierInfo;
  
  const Restaurant({
    required this.id,
    required this.name,
    required this.campusName,
    required this.thumbnailUrl,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.phoneNumber,
    required this.workingHours_weekday,
    required this.workingHours_saturday,
    required this.workingHours_sunday,
    required this.cashierInfo,
  });

  factory Restaurant.fromJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['id'],
      name: json['name'],
      campusName: json['campusName'],
      thumbnailUrl: json['thumbnailUrl'],
      address: json['address'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      phoneNumber: json['phoneNumber'],
      workingHours_weekday: json['workingHours_weekday'],
      workingHours_saturday: json['workingHours_saturday'],
      workingHours_sunday: json['workingHours_sunday'],
      cashierInfo: json['cashierInfo'],
    );
  }
}

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



void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
  
  
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  late Future<MealsOfWeek> futureMenu;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }


  @override
  void initState() {
    super.initState();  
    
    futureMenu = fetchRestaurantWeeklyMenu(2);
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
  
}
