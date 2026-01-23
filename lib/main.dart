// import 'dart:io';
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
// import 'package:http/http.dart' as http;
// import 'package:google_fonts/google_fonts.dart';
//
// void main() => runApp(MaterialApp(home: PhotoApp()));
//
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
//   Future<void> _getImage(ImageSource source) async {
//     final pickedFile = await _picker.pickImage(source: source);
//
//     if (pickedFile != null) {
//       setState(() {
//         _image = File(pickedFile.path);
//       });
//     }
//   }
//
//   Future<Map<String, dynamic>?> _lookupFoodData(String barcode) async {
//     final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
//
//     try {
//       final response = await http.get(url);
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//
//         if (data['status'] == 1) {
//           return data['product'];
//         }
//       }
//     } catch (e) {
//       print('Error looking up food: $e');
//     }
//
//     return null;
//   }
//
//   Future<void> _takePhotoAndScan() async {
//     final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
//
//     if (photo == null) return;
//
//     setState(() {
//       _image = File(photo.path);
//     });
//
//     final inputImage = InputImage.fromFilePath(photo.path);
//     final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);
//
//     if (barcodes.isEmpty) {
//       _showMessage("No barcode found", "Try getting closer or improving light.");
//     } else {
//       String barcodeValue = barcodes.first.rawValue ?? "";
//
//       // Look up food data
//       final foodData = await _lookupFoodData(barcodeValue);
//
//       if (foodData != null) {
//         _showFoodInfo(barcodeValue, foodData);
//       } else {
//         _showMessage("Barcode: $barcodeValue", "Food not found in database");
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
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("OK"),
//           )
//         ],
//       ),
//     );
//   }
//
//   void _showFoodInfo(String barcode, Map<String, dynamic> foodData) {
//     String productName = foodData['product_name'] ?? 'Unknown Product';
//     String brands = foodData['brands'] ?? 'Unknown Brand';
//     String ingredients = foodData['ingredients_text'] ?? 'No ingredients listed';
//
//     // Nutrition info
//     var nutriments = foodData['nutriments'] ?? {};
//     String calories = nutriments['energy-kcal_100g']?.toString() ?? 'N/A';
//     String protein = nutriments['proteins_100g']?.toString() ?? 'N/A';
//     String carbs = nutriments['carbohydrates_100g']?.toString() ?? 'N/A';
//     String fat = nutriments['fat_100g']?.toString() ?? 'N/A';
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(productName),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Barcode: $barcode', style: TextStyle(fontWeight: FontWeight.bold)),
//               SizedBox(height: 10),
//               Text('Brand: $brands'),
//               SizedBox(height: 10),
//               Text('Nutrition per 100g:', style: TextStyle(fontWeight: FontWeight.bold)),
//               Text('Calories: $calories kcal'),
//               Text('Protein: $protein g'),
//               Text('Carbs: $carbs g'),
//               Text('Fat: $fat g'),
//               SizedBox(height: 10),
//               Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
//               Text(ingredients),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text("OK"),
//           )
//         ],
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
//       backgroundColor: Colors.teal,
//       appBar: AppBar(
//         title: Text(
//           "Snacksnap",
//           style: GoogleFonts.pacifico(
//             fontSize: 32,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: Colors.purple,
//       ),
//       body: Center(
//         child: _image == null
//             ? Text('No image selected.')
//             : Image.file(_image!),
//       ),
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           FloatingActionButton(
//             onPressed: _takePhotoAndScan,
//             child: Icon(Icons.qr_code_scanner),
//             heroTag: "btn1",
//           ),
//           SizedBox(height: 10),
//           FloatingActionButton(
//             onPressed: () => _getImage(ImageSource.gallery),
//             child: Icon(Icons.photo_library),
//             heroTag: "btn2",
//           ),
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

void main() => runApp(MaterialApp(home: WelcomePage()));  // Changed to WelcomePage

// NEW: Welcome Page
class WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Welcome to",
              style: GoogleFonts.pacifico(
                fontSize: 28,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 10),
            Text(
              "Snacksnap",
              style: GoogleFonts.pacifico(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "Scan barcodes to discover food info!",
              style: TextStyle(
                fontSize: 18,
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 50),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => PhotoApp()),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue,
              ),
              child: Text(
                "Get Started",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoApp extends StatefulWidget {
  @override
  _PhotoAppState createState() => _PhotoAppState();
}

class _PhotoAppState extends State<PhotoApp> {
  File? _image;
  final _picker = ImagePicker();
  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.all]);

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<Map<String, dynamic>?> _lookupFoodData(String barcode) async {
    final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 1) {
          return data['product'];
        }
      }
    } catch (e) {
      print('Error looking up food: $e');
    }

    return null;
  }

  Future<void> _takePhotoAndScan() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo == null) return;

    setState(() {
      _image = File(photo.path);
    });

    final inputImage = InputImage.fromFilePath(photo.path);
    final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

    if (barcodes.isEmpty) {
      _showMessage("No barcode found", "Try getting closer or improving light.");
    } else {
      String barcodeValue = barcodes.first.rawValue ?? "";

      // Look up food data
      final foodData = await _lookupFoodData(barcodeValue);

      if (foodData != null) {
        _showFoodInfo(barcodeValue, foodData);
      } else {
        _showMessage("Barcode: $barcodeValue", "Food not found in database");
      }
    }
  }

  void _showMessage(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  void _showFoodInfo(String barcode, Map<String, dynamic> foodData) {
    String productName = foodData['product_name'] ?? 'Unknown Product';
    String brands = foodData['brands'] ?? 'Unknown Brand';
    String ingredients = foodData['ingredients_text'] ?? 'No ingredients listed';

    // Nutrition info
    var nutriments = foodData['nutriments'] ?? {};
    String calories = nutriments['energy-kcal_100g']?.toString() ?? 'N/A';
    String protein = nutriments['proteins_100g']?.toString() ?? 'N/A';
    String carbs = nutriments['carbohydrates_100g']?.toString() ?? 'N/A';
    String fat = nutriments['fat_100g']?.toString() ?? 'N/A';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(productName),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Barcode: $barcode', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text('Brand: $brands'),
              SizedBox(height: 10),
              Text('Nutrition per 100g:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Calories: $calories kcal'),
              Text('Protein: $protein g'),
              Text('Carbs: $carbs g'),
              Text('Fat: $fat g'),
              SizedBox(height: 10),
              Text('Ingredients:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(ingredients),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
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
      backgroundColor: Colors.teal,
      appBar: AppBar(
        title: Text(
          "Snacksnap",
          style: GoogleFonts.pacifico(
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.purple,
      ),
      body: Center(
        child: _image == null
            ? Text('No image selected.')
            : Image.file(_image!),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _takePhotoAndScan,
            child: Icon(Icons.qr_code_scanner),
            heroTag: "btn1",
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () => _getImage(ImageSource.gallery),
            child: Icon(Icons.photo_library),
            heroTag: "btn2",
          ),
        ],
      ),
    );
  }
}
