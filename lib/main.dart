// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_fonts/google_fonts.dart';
//
// void main() => runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: WelcomePage()
// ));
//
// // --- WELCOME PAGE ---
// class WelcomePage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.blue,
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text("Welcome to", style: GoogleFonts.pacifico(fontSize: 28, color: Colors.white)),
//             const SizedBox(height: 10),
//             Text("Snacksnap", style: GoogleFonts.pacifico(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.white)),
//             const SizedBox(height: 20),
//             const Text("Scan barcodes to discover food info!", style: TextStyle(fontSize: 18, color: Colors.white70), textAlign: TextAlign.center),
//             const SizedBox(height: 50),
//             ElevatedButton(
//               onPressed: () {
//                 Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => PhotoApp()));
//               },
//               style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15), backgroundColor: Colors.white, foregroundColor: Colors.blue),
//               child: const Text("Get Started", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // --- MAIN SCANNING PAGE ---
// class PhotoApp extends StatefulWidget {
//   @override
//   _PhotoAppState createState() => _PhotoAppState();
// }
//
// class _PhotoAppState extends State<PhotoApp> {
//   File? _image;
//   final _picker = ImagePicker();
//   final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);
//
//   Future<Map<String, dynamic>?> _lookupFoodData(String barcode) async {
//     final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
//     try {
//       final response = await http.get(url);
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         if (data['status'] == 1) return data['product'];
//       }
//     } catch (e) {
//       print('Error looking up food: $e');
//     }
//     return null;
//   }
//
//   Future<void> _takePhotoAndScan() async {
//     final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
//     if (photo == null) return;
//
//     setState(() { _image = File(photo.path); });
//
//     final inputImage = InputImage.fromFilePath(photo.path);
//     final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
//
//     if (barcodes.isEmpty) {
//       _showMessage("No barcode found", "Try getting closer or improving light.");
//       setState(() { _image = null; }); // Reset if nothing found
//     } else {
//       String barcodeValue = barcodes.first.rawValue ?? "";
//       final foodData = await _lookupFoodData(barcodeValue);
//
//       if (foodData != null && mounted) {
//         // NAVIGATE to the new page
//         Navigator.of(context).push(
//           MaterialPageRoute(
//             builder: (context) => NutritionDetailsPage(barcode: barcodeValue, foodData: foodData),
//           ),
//         ).then((_) {
//           // THIS RUNS WHEN YOU CLICK THE BACK ARROW
//           setState(() {
//             _image = null; // Clears the image so the scan button shows again
//           });
//         });
//       } else {
//         _showMessage("Barcode: $barcodeValue", "Food not found in database");
//         setState(() { _image = null; }); // Reset if API fails
//       }
//     }
//   }
//
//   void _showMessage(String title, String message) {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _barcodeScanner.close();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           title: Text("Snacksnap", style: GoogleFonts.pacifico(fontSize: 32, fontWeight: FontWeight.bold,color: Colors.white),
//             backgroundColor: Colors.blue,
//           ),
//           bottom: Stack(
//             children: [
//               Center(
//                 child: _image == null
//                     ? Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     SizedBox(
//                       width: 300, height: 300,
//                       child: FloatingActionButton(
//                         heroTag: "scanBtn",
//                         onPressed: _takePhotoAndScan,
//                         backgroundColor: Colors.lightBlue[50],
//                         foregroundColor: Colors.blue,
//                         child: const Icon(Icons.qr_code_scanner, size: 270),
//                       ),
//                     ),
//                   ],
//                 )
//                     : const CircularProgressIndicator(color: Colors.white), // Show loading while scanning
//               ),
//               if (_image == null)
//                 Positioned(
//                   top: 110, right: 130,
//                   child: Column(
//                     children: [
//                       Text("Click and\nscan barcode",
//                           style: GoogleFonts.pacifico(fontSize: 30, color: Colors.blue, fontWeight: FontWeight.bold),
//                           textAlign: TextAlign.center
//                       ),
//                       const SizedBox(height: 10),
//                       const Icon(Icons.arrow_downward, size: 40, color: Colors.blue),
//                     ],
//                   ),
//                 ),
//             ],
//           ),
//         );
//     }
// }
//
// // --- NUTRITION DETAILS PAGE ---
// class NutritionDetailsPage extends StatelessWidget {
//   final String barcode;
//   final Map<String, dynamic> foodData;
//
//   const NutritionDetailsPage({super.key, required this.barcode, required this.foodData});
//
//   @override
//   Widget build(BuildContext context) {
//     String productName = foodData['product_name'] ?? 'Unknown Product';
//     String brands = foodData['brands'] ?? 'Unknown Brand';
//     String ingredients = foodData['ingredients_text'] ?? 'No ingredients listed';
//     String imageUrl = foodData['image_front_url'] ?? "";
//
//     var nutriments = foodData['nutriments'] ?? {};
//     String calories = nutriments['energy-kcal_100g']?.toString() ?? 'N/A';
//     String protein = nutriments['proteins_100g']?.toString() ?? 'N/A';
//     String carbs = nutriments['carbohydrates_100g']?.toString() ?? 'N/A';
//     String fat = nutriments['fat_100g']?.toString() ?? 'N/A';
//
//     return Scaffold(
//       appBar: AppBar(
//         // The back arrow appears here automatically!
//           title: const Text("Nutrition Facts"),
//           backgroundColor: Colors.purple
//       ),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (imageUrl.isNotEmpty)
//               Image.network(imageUrl, width: double.infinity, height: 250, fit: BoxFit.contain),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(productName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//                   Text("Brand: $brands", style: const TextStyle(fontSize: 18, color: Colors.grey)),
//                   const Divider(height: 30),
//                   const Text("Nutrition per 100g", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 10),
//                   _buildNutrientRow("Calories", "$calories kcal"),
//                   _buildNutrientRow("Protein", "${protein}g"),
//                   _buildNutrientRow("Carbohydrates", "${carbs}g"),
//                   _buildNutrientRow("Fat", "${fat}g"),
//                   const Divider(height: 30),
//                   const Text("Ingredients", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
//                   const SizedBox(height: 8),
//                   Text(ingredients),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildNutrientRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(label, style: const TextStyle(fontSize: 16)),
//           Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
//         ],
//       ),
//     );
//   }
// }
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

void main() => runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: WelcomePage()
));

// --- WELCOME PAGE ---
class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
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

  Future<void> _takePhotoAndScan() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() { _image = File(photo.path); });

    final inputImage = InputImage.fromFilePath(photo.path);
    final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

    if (barcodes.isEmpty) {
      _showMessage("No barcode found", "Try getting closer or improving light.");
      setState(() { _image = null; }); // Reset if nothing found
    } else {
      String barcodeValue = barcodes.first.rawValue ?? "";
      final foodData = await _lookupFoodData(barcodeValue);

      if (foodData != null && mounted) {
        // NAVIGATE to the new page
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => NutritionDetailsPage(barcode: barcodeValue, foodData: foodData),
          ),
        ).then((_) {
          // THIS RUNS WHEN YOU CLICK THE BACK ARROW
          setState(() {
            _image = null; // Clears the image so the scan button shows again
          });
        });
      } else {
        _showMessage("Barcode: $barcodeValue", "Food not found in database");
        setState(() { _image = null; }); // Reset if API fails
      }
    }
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
                : const CircularProgressIndicator(color: Colors.blue), // Show loading while scanning
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
                  const Icon(Icons.arrow_downward, size: 40, color: Colors.blue),
                ],
              ),
            ),
        ],
      ),
    );
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

    return Scaffold(
      appBar: AppBar(
        title: const Text("Nutrition Facts"),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl.isNotEmpty)
              Image.network(imageUrl, width: double.infinity, height: 250, fit: BoxFit.contain),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(productName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  Text("Brand: $brands", style: const TextStyle(fontSize: 18, color: Colors.grey)),
                  const Divider(height: 30),
                  const Text("Nutrition per 100g", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  _buildNutrientRow("Calories", "$calories kcal"),
                  _buildNutrientRow("Protein", "${protein}g"),
                  _buildNutrientRow("Carbohydrates", "${carbs}g"),
                  _buildNutrientRow("Fat", "${fat}g"),
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