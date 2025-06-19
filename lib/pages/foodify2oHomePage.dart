import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Firestore integration


import '../services/AuthServices.dart'; // Assuming you have an AuthService
import '../utils/background.dart'; // Custom background widget
import '../utils/searchinput.dart'; // Custom search input widget
import 'foodify2oSnapPage.dart'; // Snap and track page
import 'foodifyTrackingPage.dart'; // Tracking page

class FoodCard {
  final String title;
  final String image;

  FoodCard({required this.title, required this.image});
}

class _Foodify2oData {
  


  Future<Map<String, double>> getTotalMacronutrients(String date) async {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    String email = _auth.currentUser?.email ?? '';
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

    debugPrint("Total Macronutrients for $date: $totalMacronutrients"); 
    return totalMacronutrients;
  }
}


String getCurrentDate() {
  DateTime now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
}

class Foodify2oHomePage extends StatefulWidget {
  Foodify2oHomePage({super.key});

  @override
  _Foodify2oHomePageState createState() => _Foodify2oHomePageState();
}

class _Foodify2oHomePageState extends State<Foodify2oHomePage>{
  final List<FoodCard> foodCards = [
    FoodCard(title: "Apple", image: "assets/images/apple.png"),
  ];

  final _Foodify2oData _foodify2oData = _Foodify2oData();
  Map<String, double> macronutrients = {
    'protein': 0,
    'carbs': 0,
    'fat': 0,
  };

@override
void initState() {
  super.initState();
  _fetchMealCalories();  
}

@override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when the page becomes visible again
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchMealCalories();
    });
  }



  Future<void> _fetchMealCalories() async {
    String currentDate = getCurrentDate();
    debugPrint("Fetching meal data for $currentDate");

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
    return Scaffold(
      body: SizedBox(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        child: Stack(
          children: [
            const Background(),
            SingleChildScrollView(
              child: Column(
                children: [
                  const IntroCard(),
                  SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: 320,
                    child: TrackingNutrientsCard(macronutrients: macronutrients),
                  ),
                  const TrackingCard(),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}


class IntroCard extends StatelessWidget {
  const IntroCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    void signout() {
      final authService = Provider.of<AuthService>(context, listen: false);
      authService.signOut();
    }

    return Container(
      margin: const EdgeInsets.only(top: 50.0, left: 15.0, right: 15.0),
      height: 220,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50.0),
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
      padding: const EdgeInsets.all(25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Let's Explore",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.25,
                      fontFamily: "BigBottom",
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Travel the world of Food",
                    style: TextStyle(
                      color: Colors.white.withOpacity(.75),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: signout, // Fixed callback issue
                child: const Icon(
                  Icons.logout_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              )
            ],
          ),
          const SizedBox(height: 15.0),
          SearchInput(
            textController: TextEditingController(),
            hintText: "Search",
          ),
          const SizedBox(height: 5.0),
        ],
      ),
    );
  }
}

class TrackingNutrientsCard extends StatelessWidget {
  final Map<String, double> macronutrients;

  const TrackingNutrientsCard({required this.macronutrients, super.key});

  @override
  Widget build(BuildContext context) {
    final double proteinGoal = 112.5;
    final double carbsGoal = 225;
    final double fatsGoal = 50;

    // Calculate percentages consumed
    final double proteinPercentage = (macronutrients['protein'] ?? 0) / proteinGoal * 100;
    final double carbsPercentage = (macronutrients['carbs'] ?? 0) / carbsGoal * 100;
    final double fatsPercentage = (macronutrients['fat'] ?? 0) / fatsGoal * 100;

    return Center(
      child: GestureDetector(
        onTap: () => {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TrackingFoodPage(),
            ),
          ),
        },
        child: Container(
          margin: const EdgeInsets.only(top: 0.0, left: 15.0, right: 15.0),
          width: MediaQuery.of(context).size.width * 0.94,
          height: 230,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50.0),
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
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // **Top Section**
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 1.5),
                        ),
                        child: const Icon(Icons.restaurant, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            "Track Food",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "Eat 1,800 Cal",
                            style: TextStyle(fontSize: 14, color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.photo_camera_outlined,
                            color: Colors.white),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => SnapTrackPage(appBarTitle: 'Snap and Track',),
                          ));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, color: Colors.orange),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 10),
              Container(height: 1, color: Colors.white24),

              // **Nutrient Stats**
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NutrientStat(label: "Protein", value: "${macronutrients['protein']?.toStringAsFixed(1) ?? '0'}g", percentage: proteinPercentage),
                  _NutrientStat(label: "Fats", value: "${macronutrients['fat']?.toStringAsFixed(1) ?? '0'}g", percentage: fatsPercentage),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NutrientStat(label: "Carbs", value: "${macronutrients['carbs']?.toStringAsFixed(1) ?? '0'}g", percentage: carbsPercentage),
                  _NutrientStat(label: "Fibre", value: "10g", percentage: 10), // Fixed fiber value
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// **Nutrient Stat Widget**
class _NutrientStat extends StatelessWidget {
  final String label;
  final String value;
  final double percentage;

  const _NutrientStat({
    required this.label,
    required this.value,
    required this.percentage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Clamp the percentage to ensure it doesn't exceed 100
    final double clampedPercentage = percentage.clamp(0, 100);

    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.42,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: $value",
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 3),
          Container(
            height: 5,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: Colors.white24, // Background color for the progress bar
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: clampedPercentage / 100, // Use clamped percentage
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.orange, // Progress bar color
                ),
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            "${clampedPercentage.toStringAsFixed(1)}%", // Display clamped percentage
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class TrackingCard extends StatelessWidget {
  const TrackingCard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
        width: MediaQuery.of(context).size.width * 0.94,
        height: 300,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50.0),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  left: 0,
                  child: _IconCard(
                    icon: Icons.directions_run,
                    color: Colors.purple.shade300,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: _IconCard(
                    icon: Icons.nightlight_round,
                    color: Colors.blue.shade200,
                  ),
                ),
                _IconCard(
                  icon: Icons.restaurant_menu,
                  color: Colors.orange.shade100,
                  isCenter: true,
                ),
              ],
            ),

            const SizedBox(height: 20),

            const Text(
              "Nothing Tracked Yet!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              "Log your meal, workout, water or sleep & get\n"
              "detailed feedback & suggestions",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),

            const SizedBox(height: 25),

            // **Button**
            ElevatedButton(
              onPressed: () {
                // Add navigation or functionality here
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text("Track Now",
                  style: TextStyle(fontSize: 14, color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

// **Reusable Icon Card**
class _IconCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final bool isCenter;

  const _IconCard(
      {required this.icon,
      required this.color,
      this.isCenter = false,
      Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isCenter ? 75 : 75,
      height: isCenter ? 75 : 75,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Icon(icon, size: isCenter ? 40 : 30, color: Colors.orange),
    );
  }
}

