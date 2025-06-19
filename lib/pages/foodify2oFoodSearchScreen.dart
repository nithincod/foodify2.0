import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

class Food {
  final String name;
  final String quantity;
  final String calories;
  final String protein;
  final String fat;
  final String carbs;

  Food({
    required this.name,
    required this.quantity,
    required this.calories,
    required this.protein,
    required this.fat,
    required this.carbs,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      name: json['food']['label'].toString(),
      quantity: json['measures'] != null && json['measures'].isNotEmpty
          ? json['measures'][0]['label']
          : '1 unit',
      calories: (json['food']['nutrients']['ENERC_KCAL'] as num?)
              ?.toStringAsFixed(0) ??
          '0',
      protein:
          (json['food']['nutrients']['PROCNT'] as num?)?.toStringAsFixed(1) ??
              '0',
      fat:
          (json['food']['nutrients']['FAT'] as num?)?.toStringAsFixed(1) ?? '0',
      carbs:
          (json['food']['nutrients']['CHOCDF'] as num?)?.toStringAsFixed(1) ??
              '0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'calories': calories,
      'protein': protein,
      'fat': fat,
      'carbs': carbs,
    };
  }
}

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  TextEditingController searchController = TextEditingController();
  List<Food> foodItems = [];
  Timer? _debounce;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      fetchFoodData(query);
    });
  }

  Future<Map<String, int>> getTotalCalories(String date) async {
  String email = _auth.currentUser!.email!;

  Map<String, int> mealCalories = {
    'Breakfast': 0,
    'Lunch': 0,
    'Snacks': 0,
    'Dinner': 0,
  };

  for (String mealType in mealCalories.keys) {
    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(email)
        .collection('meals')
        .doc(date)
        .collection(mealType)
        .get();

    int totalCalories = snapshot.docs.fold(0, (sum, doc) {
      int calories = int.tryParse(doc['calories'] ?? '0') ?? 0;
      return sum + calories;
    });

    mealCalories[mealType] = totalCalories;
  }
  return mealCalories;
}


  Future<void> fetchFoodData(String query) async {
    if (query.isEmpty) return;

    var url = Uri.parse(
      'https://api.edamam.com/api/food-database/v2/parser?app_id=85ed0cdf&app_key=2d02401030862b82b8ec3ab6bd50060d&ingr=$query&nutrition-type=cooking',
    );

    try {
      var response =
          await http.get(url, headers: {'accept': 'application/json'});
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        List<Food> items = [];

        if (data['parsed'] != null) {
          items.addAll(
              (data['parsed'] as List).map((item) => Food.fromJson(item)));
        }
        if (data['hints'] != null) {
          items.addAll(
              (data['hints'] as List).map((item) => Food.fromJson(item)));
        }

        setState(() {
          foodItems = items;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Request failed with status: \${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  Future<Map<String, double>> getTotalMacronutrients(String date) async {
    String email = _auth.currentUser!.email!;
    Map<String, double> totalMacronutrients = {
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    };

    List<String> mealTypes = ['breakfast', 'lunch', 'snacks', 'dinner'];

    for (String mealType in mealTypes) {
      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(email)
          .collection('meals')
          .doc(date)
          .collection(mealType)
          .get();

      for (var doc in snapshot.docs) {
        totalMacronutrients['protein'] = (totalMacronutrients['protein'] ?? 0) +
            (double.tryParse(doc['protein']?.toString() ?? '0') ?? 0);
        totalMacronutrients['carbs'] = (totalMacronutrients['carbs'] ?? 0) +
            (double.tryParse(doc['carbs']?.toString() ?? '0') ?? 0);
        totalMacronutrients['fat'] = (totalMacronutrients['fat'] ?? 0) +
            (double.tryParse(doc['fat']?.toString() ?? '0') ?? 0);
      }
    }

    debugPrint("Total Macronutrients for $date: $totalMacronutrients");
    return totalMacronutrients;
  }

  Future<void> saveFoodToFirebase(String mealType, Food food) async {
  try {
    String date = DateTime.now().toIso8601String().split('T')[0];
    String email = _auth.currentUser!.email!;

    await _firestore
        .collection('users')
        .doc(email)
        .collection('meals')
        .doc(date)
        .collection(mealType)
        .add(food.toJson());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${food.name} added to $mealType on $date')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to save: $e')),
    );
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Healthy Foods',
          style: TextStyle(
            color: Color.fromARGB(255, 96, 95, 95),
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xff4338CA),
                ),
                filled: true,
                fillColor: Colors.blue[50],
                hintText: 'Search for food',
                hintStyle: const TextStyle(
                    color: Colors.grey, fontWeight: FontWeight.w300),
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 20.0),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                ),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 64, 64, 64), width: 1.0),
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(255, 33, 33, 33), width: 2.0),
                  borderRadius: BorderRadius.all(Radius.circular(50.0)),
                ),
              ),
            ),
            Expanded(
              child: foodItems.isEmpty
                  ? const Center(child: Text('No results found'))
                  : ListView.builder(
                      itemCount: foodItems.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 3,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 20.0),
                            title: Text(
                              foodItems[index].name,
                              style: const TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              '${foodItems[index].quantity} - ${foodItems[index].calories} Cal | Protein: ${foodItems[index].protein}g | Fat: ${foodItems[index].fat}g | Carbs: ${foodItems[index].carbs}g',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 14.0),
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) {
                                saveFoodToFirebase(value, foodItems[index]);
                                getTotalCalories(DateTime.now()
                                    .toIso8601String()
                                    .split('T')[0]);
                                getTotalMacronutrients(DateTime.now()
                                    .toIso8601String()
                                    .split('T')[0]);
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                    value: "breakfast",
                                    child: Text("Breakfast")),
                                const PopupMenuItem(
                                    value: "lunch", child: Text("Lunch")),
                                const PopupMenuItem(
                                    value: "snacks", child: Text("Snacks")),
                                const PopupMenuItem(
                                    value: "dinner", child: Text("Dinner")),
                              ],
                              child: const Icon(Icons.add,
                                  color: Colors.orangeAccent),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
