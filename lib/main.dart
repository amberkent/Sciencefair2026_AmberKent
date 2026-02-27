import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WelcomePage()
));

// --- WELCOME PAGE ---
class WelcomePage extends StatelessWidget {
  Future<void> _launchURL(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _showInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Scientific Criteria"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("This app identifies Hyper-Palatable Food (HPF) clusters:"),
            const SizedBox(height: 15),
            InkWell(
              onTap: () => _launchURL('https://onlinelibrary.wiley.com/doi/full/10.1002/oby.22639'),
              child: const Text("Fazzino et al. (2019)", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _launchURL('https://www.nature.com/articles/s43016-022-00688-4#access-options'),
              child: const Text("Nature Food (2023)", style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close")),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Welcome to", style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white)),
                const SizedBox(height: 10),
                Text("Snacksnap", style: GoogleFonts.pacifico(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                const Text("Scan barcodes to discover food info!", style: TextStyle(fontSize: 18, color: Colors.white70), textAlign: TextAlign.center),
                const SizedBox(height: 50),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => PhotoApp()));
                  },
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), backgroundColor: Colors.white, foregroundColor: Colors.blue),
                  child: const Text("Get Started", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Info button moved up
          Positioned(
            bottom: 100,
            left: 20,
            child: GestureDetector(
              onTap: () => _showInfoDialog(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "Info",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- MAIN SCANNING PAGE ---
class PhotoApp extends StatefulWidget {
  @override
  _PhotoAppState createState() => _PhotoAppState();
}

class _PhotoAppState extends State<PhotoApp> {
  File? _image;
  final _picker = ImagePicker();
  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);

  Future<Map<String, dynamic>?> _lookupFoodData(String barcode) async {
    final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 1) return data['product'];
      }
    } catch (e) {
      print('Error looking up food: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> _searchFoodByName(String foodName) async {
    final url = Uri.parse('https://world.openfoodfacts.org/cgi/search.pl?search_terms=$foodName&search_simple=1&action=process&json=1&page_size=10');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['products'] != null && data['products'].isNotEmpty) {
          return List<Map<String, dynamic>>.from(data['products']);
        }
      }
    } catch (e) {
      print('Error searching food: $e');
    }
    return [];
  }

  Future<void> _takePhotoAndScan() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() { _image = File(photo.path); });

    final inputImage = InputImage.fromFilePath(photo.path);
    final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

    if (barcodes.isEmpty) {
      _showMessage("No barcode found", "Try getting closer or improving light.");
      setState(() { _image = null; });
    } else {
      String barcodeValue = barcodes.first.rawValue ?? "";
      final foodData = await _lookupFoodData(barcodeValue);

      if (foodData != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NutritionDetailsPage(barcode: barcodeValue, foodData: foodData),
          ),
        ).then((_) {
          setState(() {
            _image = null;
          });
        });
      } else {
        _showMessage("Barcode: $barcodeValue", "Food not found in database");
        setState(() { _image = null; });
      }
    }
  }

  void _showFoodSearchDialog() {
    final TextEditingController foodController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Search Food"),
        content: TextField(
          controller: foodController,
          decoration: const InputDecoration(
            hintText: "Type food name (e.g., Coca Cola)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              String foodName = foodController.text.trim();
              Navigator.pop(context);

              if (foodName.isNotEmpty) {
                setState(() { _image = File(''); });

                final results = await _searchFoodByName(foodName);

                setState(() { _image = null; });

                if (results.isNotEmpty && mounted) {
                  _showFoodResults(results);
                } else {
                  _showMessage("No Results", "No food found with name: $foodName");
                }
              }
            },
            child: const Text("Search"),
          ),
        ],
      ),
    );
  }

  void _showFoodResults(List<Map<String, dynamic>> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Select a Food"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: results.length,
            itemBuilder: (context, index) {
              final product = results[index];
              String productName = product['product_name'] ?? 'Unknown Product';
              String brands = product['brands'] ?? '';
              String imageUrl = product['image_front_small_url'] ?? '';

              return ListTile(
                leading: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, width: 50, height: 50, fit: BoxFit.contain)
                    : const Icon(Icons.fastfood),
                title: Text(productName),
                subtitle: Text(brands),
                onTap: () {
                  Navigator.pop(context);
                  String barcode = product['code'] ?? '';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NutritionDetailsPage(barcode: barcode, foodData: product),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
        ],
      ),
    );
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
      ),
    );
  }

  @override
  void dispose() {
    _barcodeScanner.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Snacksnap",
          style: GoogleFonts.pacifico(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          Center(
            child: _image == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 300,
                  height: 300,
                  child: FloatingActionButton(
                    heroTag: "scanBtn",
                    onPressed: _takePhotoAndScan,
                    backgroundColor: Colors.lightBlue[50],
                    foregroundColor: Colors.blue,
                    child: const Icon(Icons.qr_code_scanner, size: 270),
                  ),
                ),
              ],
            )
                : const CircularProgressIndicator(color: Colors.blue),
          ),
          if (_image == null)
            Positioned(
              top: 110,
              right: 130,
              child: Column(
                children: [
                  Text(
                    "Click and\nscan barcode",
                    style: GoogleFonts.pacifico(
                      fontSize: 30,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Icon(Icons.arrow_downward, size: 40, color: Colors.white),
                ],
              ),
            ),
          // Text search button in bottom right
          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              heroTag: "textBtn",
              onPressed: _showFoodSearchDialog,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.text_fields, color: Colors.white, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HYPER-PALATABLE FOOD CHECKER (Based on Fazzino et al., 2019) ---
class HyperPalatableChecker {
  final bool isHyperPalatable;
  final List<String> problematicNutrients;
  final String clusterName;
  final Color color;
  final IconData icon;
  final bool isLiquid;

  HyperPalatableChecker({
    required this.isHyperPalatable,
    required this.problematicNutrients,
    required this.clusterName,
    required this.color,
    required this.icon,
    required this.isLiquid,
  });

  static HyperPalatableChecker evaluate(Map<String, dynamic> nutriments, Map<String, dynamic> foodData) {
    // Check if product is a beverage/liquid
    List<String> categories = [];
    if (foodData['categories'] != null) {
      categories = foodData['categories'].toString().toLowerCase().split(',');
    }

    String productName = (foodData['product_name'] ?? '').toLowerCase();

    bool isLiquid = categories.any((cat) =>
    cat.contains('beverage') ||
        cat.contains('drink') ||
        cat.contains('juice') ||
        cat.contains('soda') ||
        cat.contains('water') ||
        cat.contains('milk') ||
        cat.contains('tea') ||
        cat.contains('coffee')
    ) || productName.contains('drink') ||
        productName.contains('juice') ||
        productName.contains('soda') ||
        productName.contains('water') ||
        productName.contains('milk');

    if (isLiquid) {
      return HyperPalatableChecker(
        isHyperPalatable: false,
        problematicNutrients: [],
        clusterName: "",
        color: Colors.grey,
        icon: Icons.info_outline,
        isLiquid: true,
      );
    }

    // Extract values per 100g
    double caloriesTotal = (nutriments['energy-kcal_100g'] ?? 0).toDouble();
    double fatG = (nutriments['fat_100g'] ?? 0).toDouble();
    double sugarsG = (nutriments['sugars_100g'] ?? 0).toDouble();
    double carbsG = (nutriments['carbohydrates_100g'] ?? 0).toDouble();
    double sodiumG = (nutriments['sodium_100g'] ?? 0).toDouble();
    double saltG = (nutriments['salt_100g'] ?? 0).toDouble();

    // Calculate percentages
    double fatKcal = fatG * 9;
    double sugarKcal = sugarsG * 4;
    double carbsKcal = carbsG * 4;

    double percentCalFromFat = caloriesTotal > 0 ? (fatKcal / caloriesTotal) * 100 : 0;
    double percentCalFromSugar = caloriesTotal > 0 ? (sugarKcal / caloriesTotal) * 100 : 0;
    double percentCalFromCarbs = caloriesTotal > 0 ? (carbsKcal / caloriesTotal) * 100 : 0;

    // Salt as percentage of weight (g per 100g = %)
    double percentSaltByWeight = saltG;
    // Sodium as percentage of weight (used for the research criteria)
    double percentSodiumByWeight = sodiumG;

    List<String> problems = [];
    List<String> clusterNames = [];

    // Check the three HPF clusters
    bool cluster1 = percentCalFromFat > 25 && percentSodiumByWeight >= 0.30;
    bool cluster2 = percentCalFromFat > 20 && percentCalFromSugar > 20;
    bool cluster3 = percentCalFromCarbs > 40 && percentSodiumByWeight >= 0.30;

    // Track which clusters are triggered
    if (cluster1) {
      clusterNames.add("Cluster 1: Fat and Sodium");
    }
    if (cluster2) {
      clusterNames.add("Cluster 2: Fat and Sugar");
    }
    if (cluster3) {
      clusterNames.add("Cluster 3: Carbohydrates and Sodium");
    }

    // Check which nutrients are problematic based on clusters
    bool highFat = cluster1 || cluster2;
    bool highSalt = cluster1 || cluster3;
    bool highSugar = cluster2;
    bool highCarbs = cluster3;

    // Add problems to the list
    if (highFat) {
      problems.add("High Fat (${percentCalFromFat.toStringAsFixed(1)}% of calories)");
    }

    if (highSalt) {
      problems.add("High Salt (${percentSaltByWeight.toStringAsFixed(2)}% by weight)");
    }

    if (highSugar) {
      problems.add("High Sugar (${percentCalFromSugar.toStringAsFixed(1)}% of calories)");
    }

    if (highCarbs) {
      problems.add("High Carbohydrates (${percentCalFromCarbs.toStringAsFixed(1)}% of calories)");
    }

    if (problems.isEmpty) {
      return HyperPalatableChecker(
        isHyperPalatable: false,
        problematicNutrients: [],
        clusterName: "",
        color: Colors.green,
        icon: Icons.check,
        isLiquid: false,
      );
    } else {
      return HyperPalatableChecker(
        isHyperPalatable: true,
        problematicNutrients: problems,
        clusterName: clusterNames.join(", "),
        color: Colors.red,
        icon: Icons.close,
        isLiquid: false,
      );
    }
  }
}

// --- NUTRITION DETAILS PAGE ---
class NutritionDetailsPage extends StatelessWidget {
  final String barcode;
  final Map<String, dynamic> foodData;

  const NutritionDetailsPage({super.key, required this.barcode, required this.foodData});

  @override
  Widget build(BuildContext context) {
    String productName = foodData['product_name'] ?? 'Unknown Product';
    String brands = foodData['brands'] ?? 'Unknown Brand';
    String ingredients = foodData['ingredients_text'] ?? 'No ingredients listed';
    String imageUrl = foodData['image_front_url'] ?? "";

    var nutriments = foodData['nutriments'] ?? {};
    String calories = nutriments['energy-kcal_100g']?.toString() ?? 'N/A';
    String protein = nutriments['proteins_100g']?.toString() ?? 'N/A';
    String carbs = nutriments['carbohydrates_100g']?.toString() ?? 'N/A';
    String fat = nutriments['fat_100g']?.toString() ?? 'N/A';
    String sugar = nutriments['sugars_100g']?.toString() ?? 'N/A';
    String salt = nutriments['salt_100g']?.toString() ?? 'N/A';
    double saltValue = double.tryParse(salt) ?? 0;

    // Evaluate using scientific HPF criteria
    HyperPalatableChecker hpfCheck = HyperPalatableChecker.evaluate(nutriments, foodData);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Nutrition Facts",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.blue,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // IMAGE AT THE TOP
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, width: double.infinity, height: 250, fit: BoxFit.contain),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product name with health indicator
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        hpfCheck.icon,
                        color: hpfCheck.color,
                        size: 40,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text("Brand: $brands", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 12),

                  // Health Status - Simple and Clear
                  if (hpfCheck.isLiquid)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orangeAccent, width: 2),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orangeAccent, size: 24),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Cannot evaluate - This product is a beverage/liquid",
                              style: TextStyle(fontSize: 16, color: Colors.orangeAccent
                                  ,fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (hpfCheck.isHyperPalatable)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red, width: 2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "⚠️ Hyper-Palatable Food:",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...hpfCheck.clusterName.split(", ").map((cluster) => Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              cluster,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          )),
                          const SizedBox(height: 12),
                          const Text(
                            "Problematic nutrients:",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          ...hpfCheck.problematicNutrients.map((nutrient) => Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Row(
                              children: [
                                const Text("• ", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                Expanded(child: Text(nutrient, style: const TextStyle(fontSize: 16))),
                              ],
                            ),
                          )),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green, width: 2),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 24),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Not Hyper-Palatable - Balanced nutritional profile",
                              style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const Divider(height: 30),
                  const Text("Nutrition per 100g", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildNutrientRow("Calories", "$calories kcal"),
                  _buildNutrientRow("Protein", "${protein}g"),
                  _buildNutrientRow("Carbohydrates", "${carbs}g"),
                  _buildNutrientRow("Sugar", "${sugar}g"),
                  _buildNutrientRow("Fat", "${fat}g"),
                  _buildNutrientRow("Salt", "${salt}g (${saltValue.toStringAsFixed(2)}% of weight)"),
                  const Divider(height: 30),
                  const Text("Ingredients", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(ingredients),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}