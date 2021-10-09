import 'package:eusp/vo/meals_of_week.dart';
import 'package:flutter/material.dart';

import 'networking.dart';

class CardapioScreen extends StatefulWidget {
  const CardapioScreen({Key? key}) : super(key: key);

  @override
  State<CardapioScreen> createState() => _CardapioScreenState();
}

class _CardapioScreenState extends State<CardapioScreen> {
  late Future<MealsOfWeek> futureMenu;
  
  @override
  void initState() {
    super.initState();
    futureMenu = fetchRestaurantWeeklyMenu(2);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('First Screen'),
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/login');
            },
            child: const Text('Launch screen'),
          ),
          const SizedBox(height: 32.0,),
          FutureBuilder(
            future: futureMenu,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                MealsOfWeek meals = snapshot.data! as MealsOfWeek;
                
                return Text(meals.toJson().toString());
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              
              return const CircularProgressIndicator();      
            }
          ),
        ],
      ),
    );
  }
}
