import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/shimmer.dart';
import 'foodify2oHealthyReceipiesPage.dart';
import 'foodify2oSnapPage.dart';
import 'foodifyInsightsPage.dart';

class TrackingFoodPage extends StatefulWidget {
  @override
  _TrackingFoodPageState createState() => _TrackingFoodPageState();
}

class _Foodify2oData {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<Map<String, double>> getTotalMacronutrients(String date) async {
    String email = _auth.currentUser!.email!;
    Map<String, double> totalMacronutrients = {
      'protein': 0,
      'carbs': 0,
      'fat': 0,
    };

    List<String> mealTypes = ['breakfast', 'lunch', 'snacks', 'dinner'];

    for (String mealType in mealTypes) {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('meals')
          .doc(date)
          .collection(mealType)
          .get();

      for (var doc in snapshot.docs) {
        totalMacronutrients['protein'] =
            (totalMacronutrients['protein'] ?? 0) + (double.tryParse(doc['protein']?.toString() ?? '0') ?? 0);
        totalMacronutrients['carbs'] =
            (totalMacronutrients['carbs'] ?? 0) + (double.tryParse(doc['carbs']?.toString() ?? '0') ?? 0);
        totalMacronutrients['fat'] =
            (totalMacronutrients['fat'] ?? 0) + (double.tryParse(doc['fat']?.toString() ?? '0') ?? 0);
      }
    }
    return totalMacronutrients;
  }
}

class _TrackingFoodPageState extends State<TrackingFoodPage> {
  final _foodify2oData = _Foodify2oData();
  Map<String, int> mealCalories = {
    'breakfast': 0,
    'lunch': 0,
    'snacks': 0,
    'dinner': 0,
  };
  Map<String, double> macronutrients = {'protein': 0, 'carbs': 0, 'fat': 0};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchMealCalories();
    _fetchMacroNutrients();
  }

  Future<void> _fetchMealCalories() async {
    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final FirebaseAuth _auth = FirebaseAuth.instance;
      String email = _auth.currentUser!.email!;
      String date = DateTime.now().toString().split(' ')[0];

      for (String mealType in mealCalories.keys) {
        QuerySnapshot snapshot = await _firestore
            .collection('users')
            .doc(email)
            .collection('meals')

            .doc(date)
            .collection(mealType)
            .get();

        int totalCalories = snapshot.docs.fold(0, (sum, doc) {
          int calories = int.tryParse(doc['calories']?.toString() ?? '0') ?? 0;
          return sum + calories;
        });

        setState(() {
          mealCalories[mealType] = totalCalories;
        });
      }
    } catch (e) {
      debugPrint("Error fetching meal calories: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String getCurrentDate() {
    DateTime now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  Future<void> _fetchMacroNutrients() async {
    String currentDate = getCurrentDate();
    try {
      final data = await _foodify2oData.getTotalMacronutrients(currentDate);
      setState(() {
        macronutrients = data;
      });
    } catch (e) {
      debugPrint("Error fetching meal data: $e");
    }
  }
  

  @override
  Widget build(BuildContext context) {
    int totalCaloriesConsumed = mealCalories.values.fold(0, (sum, cal) => sum + cal);

    return PopScope(
        canPop: true,
    onPopInvoked: (bool didPop) async {
      if (didPop) return;
      try {
        final data = await _foodify2oData.getTotalMacronutrients(getCurrentDate());
        if (mounted) {
          setState(() {
            macronutrients = data;
          });
        }
      } catch (e) {
        debugPrint("Error fetching meal data: $e");
      }
    },


      child: Scaffold(
        body: Stack(
          children: [
            const Background(), // Ensure this widget is defined or imported
            SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // **App Bar Section**
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, size: 28),
                        ),
                        const Text("Today", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                        const Icon(Icons.settings, size: 28),
                      ],
                    ),
                  ),
      
                  // **Calories Summary Section**
                  Center(
                    child: Column(
                      children: [
                        const Icon(Icons.restaurant, size: 60, color: Colors.orange),
                        Text("$totalCaloriesConsumed of 1800", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                        const Text("Cal Eaten", style: TextStyle(fontSize: 16, color: Colors.black87)),
                      ],
                    ),
                  ),
      
                  const SizedBox(height: 20),
      
                  // **Horizontal Scroll Cards**
                  SizedBox(
                    height: 100,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildInsightsCard(context),
                        _buildReciepiesCard(context),
                        _buildSnapGalleriesCard(),
                        _buildSavedMealsCard(),
                      ],
                    ),
                  ),
      
                  // **Meal Sections**
                  Expanded(
                    child: _isLoading
                        ? ShimmerLoading() 
                        : ListView(
                            children: [
                              _buildMealSection(context, "Breakfast", "${mealCalories['breakfast'] ?? 0} of 450 Cal", "All you need is some breakfast ☀️🍳"),
                              _buildMealSection(context, "Lunch", "${mealCalories['lunch'] ?? 0} of 450 Cal", "Don't miss lunch 🍱 It's time to get a tasty meal"),
                              _buildMealSection(context, "Snack", "${mealCalories['snacks'] ?? 0} of 450 Cal", "Have a great healthy snack 🥗"),
                              _buildMealSection(context, "Dinner", "${mealCalories['dinner'] ?? 0} of 225 Cal", "Get energized by grabbing a morning snack 🥜"),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // **Meal Section Widget**
  Widget _buildMealSection(BuildContext context, String title, String calories, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Text(calories, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  const SizedBox(width: 5),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SnapTrackPage(
                            appBarTitle: 'Track $title',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.add_a_photo,
                      size: 20,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * .15,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.indigo[800]!.withOpacity(.15),
                  offset: const Offset(0, 10),
                  blurRadius: 0,
                  spreadRadius: 0,
                )
              ],
              gradient: const RadialGradient(
                colors: [Color(0xff0E5C9E), Color(0xff031965)],
                focal: Alignment.topCenter,
                radius: .85,
              ),
            ),
            child: Text(subtitle, style: const TextStyle(fontSize: 16, color: Colors.white)),
          ),
          const Divider(),
        ],
      ),
    );
  }

  // **Insights Card Widget**
  Widget _buildInsightsCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => InsightsPage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo[500]!.withOpacity(.15),
                offset: const Offset(0, 10),
                blurRadius: 0,
                spreadRadius: 0,
              )
            ],
            gradient: const RadialGradient(
              colors: [Color(0xff0E5C9E), Color(0xff031965)],
              focal: Alignment.topCenter,
              radius: .85,
            ),
          ),
          alignment: Alignment.center,
          child: const Text('Insights', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  // **Snap Galleries Card Widget**
  Widget _buildSnapGalleriesCard() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo[500]!.withOpacity(.15),
              offset: const Offset(0, 10),
              blurRadius: 0,
              spreadRadius: 0,
            )
          ],
          gradient: const RadialGradient(
            colors: [Color(0xff0E5C9E), Color(0xff031965)],
            focal: Alignment.topCenter,
            radius: .85,
          ),
        ),
        alignment: Alignment.center,
        child: const Text('SnapGalleries', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  // **Recipes Card Widget**
  Widget _buildReciepiesCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => RecipiesPage()),
        );
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          width: 150,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25.0),
            boxShadow: [
              BoxShadow(
                color: Colors.indigo[500]!.withOpacity(.15),
                offset: const Offset(0, 10),
                blurRadius: 0,
                spreadRadius: 0,
              )
            ],
            gradient: const RadialGradient(
              colors: [Color(0xff0E5C9E), Color(0xff031965)],
              focal: Alignment.topCenter,
              radius: .85,
            ),
          ),
          alignment: Alignment.center,
          child: const Text('Recipes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        ),
      ),
    );
  }

  // **Saved Meals Card Widget**
  Widget _buildSavedMealsCard() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25.0),
          boxShadow: [
            BoxShadow(
              color: Colors.indigo[500]!.withOpacity(.15),
              offset: const Offset(0, 10),
              blurRadius: 0,
              spreadRadius: 0,
            )
          ],
          gradient: const RadialGradient(
            colors: [Color(0xff0E5C9E), Color(0xff031965)],
            focal: Alignment.topCenter,
            radius: .85,
          ),
        ),
        alignment: Alignment.center,
        child: const Text('SavedMeals', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}