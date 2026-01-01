// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'package:path_provider/path_provider.dart';
// import 'config/api_urls.dart';
// import 'api_client.dart';

// class AddProductScreen extends StatefulWidget {
//   const AddProductScreen({Key? key}) : super(key: key);

//   @override
//   State<AddProductScreen> createState() => _AddProductScreenState();
// }

// class _AddProductScreenState extends State<AddProductScreen> {
//   final _formKey = GlobalKey<FormState>();

//   final _nameController = TextEditingController();
//   final _priceController = TextEditingController();
//   final _descriptionController = TextEditingController();
//   final _stockController = TextEditingController();

//   final ImagePicker _picker = ImagePicker();

//   final Map<String, File?> _productImages = {
//     'Front View': null,
//     'Back View': null,
//     'Side View': null,
//     'Top View': null,
//     'Lifestyle': null,
//   };

//   String _selectedCategory = 'Clothing';

//   final List<String> _categories = [
//     'Clothing',
//     'Shoes',
//     'Accessories',
//     'Electronics',
//     'Bags',
//     'Sports',
//     'Home & Living',
//     'Beauty',
//     'Books',
//     'Toys',
//   ];

//   bool _isFeatured = false;
//   bool _isOnSale = false;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _priceController.dispose();
//     _descriptionController.dispose();
//     _stockController.dispose();
//     super.dispose();
//   }

//   // ---------- IMAGE PICK & COMPRESS ----------
//   Future<File?> _pickAndCompress(ImageSource source) async {
//     final XFile? picked = await _picker.pickImage(
//       source: source,
//       imageQuality: 100,
//     );

//     if (picked == null) return null;

//     final dir = await getTemporaryDirectory();
//     final targetPath =
//         '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

//     final compressed = await FlutterImageCompress.compressAndGetFile(
//       picked.path,
//       targetPath,
//       quality: 70,
//       minWidth: 1000,
//       minHeight: 1000,
//       format: CompressFormat.jpeg,
//     );

//     return compressed != null ? File(compressed.path) : null;
//   }

//   void _selectImage(String key) {
//     showModalBottomSheet(
//       context: context,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
//       ),
//       builder: (_) => SafeArea(
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               leading: const Icon(Icons.camera_alt),
//               title: const Text('Camera'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 final img = await _pickAndCompress(ImageSource.camera);
//                 if (img != null) {
//                   setState(() => _productImages[key] = img);
//                 }
//               },
//             ),
//             ListTile(
//               leading: const Icon(Icons.photo_library),
//               title: const Text('Gallery'),
//               onTap: () async {
//                 Navigator.pop(context);
//                 final img = await _pickAndCompress(ImageSource.gallery);
//                 if (img != null) {
//                   setState(() => _productImages[key] = img);
//                 }
//               },
//             ),
//             if (_productImages[key] != null)
//               ListTile(
//                 leading: const Icon(Icons.delete, color: Colors.red),
//                 title: const Text('Remove'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   setState(() => _productImages[key] = null);
//                 },
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ---------- SUBMIT ----------
//   void _handleSubmit() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_productImages['Front View'] == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Front view image is mandatory'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     final List<File> imagesToUpload = _productImages.values
//         .where((file) => file != null)
//         .cast<File>()
//         .toList();

//     final response = await ApiClient.multipartPost(
//       url: ApiUrls.addProduct,
//       fields: {
//         "name": _nameController.text,
//         "price": _priceController.text,
//         "description": _descriptionController.text,
//         "category": _selectedCategory,
//         "stock": _stockController.text,
//         "isFeatured": _isFeatured.toString(),
//         "isOnSale": _isOnSale.toString(),
//         "image_types": jsonEncode(_productImages.keys.toList()),
//       },
//       images: imagesToUpload, // List<File>
//     );

//     final responseBody = await response.stream.bytesToString();

//     final data = jsonDecode(responseBody);
//     if (response.statusCode == 200 || response.statusCode == 201) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(data['message'] ?? 'Product added successfully'),
//           backgroundColor: Color(0xFF10B981),
//         ),
//       );
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(data['error'] ?? 'Failed to add product'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     Navigator.pop(context, data);
//   }

//   // ---------- UI ----------
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: const Color(0xFFF9FAFB),
//       appBar: AppBar(
//         title: const Text('Add New Product'),
//         backgroundColor: const Color(0xFF4F46E5),
//         foregroundColor: Colors.white,
//         actions: [
//           TextButton(
//             onPressed: _handleSubmit,
//             child: const Text(
//               'Save',
//               style: TextStyle(color: Colors.white, fontSize: 16),
//             ),
//           ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _sectionTitle('Product Images'),
//               const SizedBox(height: 12),
//               _buildImageSection(),
//               const SizedBox(height: 24),

//               _sectionTitle('Basic Information'),
//               const SizedBox(height: 12),
//               _textField(
//                 controller: _nameController,
//                 label: 'Product Name',
//                 icon: Icons.shopping_bag_outlined,
//                 validator: (v) => v == null || v.isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 16),
//               _categoryDropdown(),
//               const SizedBox(height: 16),
//               _textField(
//                 controller: _descriptionController,
//                 label: 'Description',
//                 icon: Icons.description_outlined,
//                 maxLines: 4,
//                 validator: (v) => v == null || v.isEmpty ? 'Required' : null,
//               ),
//               const SizedBox(height: 24),

//               _sectionTitle('Pricing & Inventory'),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   Expanded(
//                     child: _textField(
//                       controller: _priceController,
//                       label: 'Price',
//                       icon: Icons.attach_money,
//                       keyboardType: const TextInputType.numberWithOptions(
//                         decimal: true,
//                       ),
//                       inputFormatters: [
//                         FilteringTextInputFormatter.allow(
//                           RegExp(r'^\d+\.?\d{0,2}'),
//                         ),
//                       ],
//                       validator: (v) =>
//                           v == null || v.isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     child: _textField(
//                       controller: _stockController,
//                       label: 'Stock',
//                       icon: Icons.inventory_2_outlined,
//                       keyboardType: TextInputType.number,
//                       inputFormatters: [FilteringTextInputFormatter.digitsOnly],
//                       validator: (v) =>
//                           v == null || v.isEmpty ? 'Required' : null,
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 24),

//               _switchTile(
//                 icon: Icons.star_outline,
//                 title: 'Featured Product',
//                 value: _isFeatured,
//                 onChanged: (v) => setState(() => _isFeatured = v),
//               ),
//               const SizedBox(height: 12),
//               _switchTile(
//                 icon: Icons.local_offer_outlined,
//                 title: 'On Sale',
//                 value: _isOnSale,
//                 onChanged: (v) => setState(() => _isOnSale = v),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ---------- WIDGETS ----------
//   Widget _buildImageSection() {
//     return GridView.count(
//       shrinkWrap: true,
//       physics: const NeverScrollableScrollPhysics(),
//       crossAxisCount: 8,
//       crossAxisSpacing: 9,
//       mainAxisSpacing: 9,
//       children: _productImages.keys.map((key) {
//         final img = _productImages[key];
//         return GestureDetector(
//           onTap: () => _selectImage(key),
//           child: Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               border: Border.all(
//                 color: key == 'Front View'
//                     ? const Color(0xFF4F46E5)
//                     : const Color(0xFFD1D5DB),
//                 width: key == 'Front View' ? 2 : 1,
//               ),
//               color: const Color(0xFFF3F4F6),
//             ),
//             child: img == null
//                 ? Column(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       const Icon(Icons.add_a_photo_outlined),
//                       const SizedBox(height: 6),
//                       Text(key, textAlign: TextAlign.center),
//                     ],
//                   )
//                 : ClipRRect(
//                     borderRadius: BorderRadius.circular(8),
//                     child: Image.file(img, fit: BoxFit.cover),
//                   ),
//           ),
//         );
//       }).toList(),
//     );
//   }

//   Widget _textField({
//     required TextEditingController controller,
//     required String label,
//     required IconData icon,
//     int maxLines = 1,
//     TextInputType? keyboardType,
//     List<TextInputFormatter>? inputFormatters,
//     String? Function(String?)? validator,
//   }) {
//     return TextFormField(
//       controller: controller,
//       maxLines: maxLines,
//       keyboardType: keyboardType,
//       inputFormatters: inputFormatters,
//       validator: validator,
//       decoration: InputDecoration(
//         labelText: label,
//         prefixIcon: Icon(icon),
//         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   Widget _categoryDropdown() {
//     return DropdownButtonFormField<String>(
//       value: _selectedCategory,
//       decoration: const InputDecoration(
//         labelText: 'Category',
//         border: OutlineInputBorder(),
//       ),
//       items: _categories
//           .map((c) => DropdownMenuItem(value: c, child: Text(c)))
//           .toList(),
//       onChanged: (v) => setState(() => _selectedCategory = v!),
//     );
//   }

//   Widget _switchTile({
//     required IconData icon,
//     required String title,
//     required bool value,
//     required Function(bool) onChanged,
//   }) {
//     return SwitchListTile(
//       value: value,
//       onChanged: onChanged,
//       title: Text(title),
//       secondary: Icon(icon),
//       activeColor: const Color(0xFF4F46E5),
//     );
//   }

//   Widget _sectionTitle(String text) {
//     return Text(
//       text,
//       style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//     );
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'config/api_urls.dart';
import 'api_client.dart';

// Helper class for Variations
class ProductVariation {
  String color;
  String size;
  int quantity;
  ProductVariation({
    required this.color,
    required this.size,
    required this.quantity,
  });

  Map<String, dynamic> toJson() => {
    'color': color,
    'size': size,
    'quantity': quantity,
  };
}

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);
  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _priceController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _longDescController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final Map<String, File?> _productImages = {
    'Front': null,
    'Back': null,
    'Side': null,
    'Label': null,
  };

  String _selectedCategory = 'Clothing';
  bool _isFeatured = false;
  bool _isOnSale = false;

  // New Variation List
  List<ProductVariation> _variations = [
    ProductVariation(color: 'White', size: 'S', quantity: 3),
    ProductVariation(color: 'White', size: 'M', quantity: 3),
    ProductVariation(color: 'White', size: 'L', quantity: 3),
    ProductVariation(color: 'Black', size: 'S', quantity: 3),
    ProductVariation(color: 'Black', size: 'M', quantity: 3),
    ProductVariation(color: 'Black', size: 'L', quantity: 3),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _priceController.dispose();
    _shortDescController.dispose();
    _longDescController.dispose();
    super.dispose();
  }

  // ---------- LOGIC ----------

  Future<File?> _pickAndCompress(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (picked == null) return null;
    final dir = await getTemporaryDirectory();
    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final compressed = await FlutterImageCompress.compressAndGetFile(
      picked.path,
      targetPath,
      quality: 70,
      minWidth: 1000,
      minHeight: 1000,
    );
    return compressed != null ? File(compressed.path) : null;
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_productImages['Front'] == null) {
      _showSnack('Front image is mandatory', Colors.red);
      return;
    }

    // Total Stock Calculation
    int totalStock = _variations.fold(0, (sum, item) => sum + item.quantity);

    final response = await ApiClient.multipartPost(
      url: ApiUrls.addProduct,
      fields: {
        "name": _nameController.text,
        "brand": _brandController.text,
        "price": _priceController.text,
        "short_description": _shortDescController.text,
        "description": _longDescController.text,
        "category": _selectedCategory,
        "stock": totalStock.toString(),
        "isFeatured": _isFeatured.toString(),
        "isOnSale": _isOnSale.toString(),
        "variations": jsonEncode(_variations.map((v) => v.toJson()).toList()),
      },
      images: _productImages.values
          .where((f) => f != null)
          .cast<File>()
          .toList(),
    );

    final responseBody = await response.stream.bytesToString();
    final data = jsonDecode(responseBody);
    if (response.statusCode == 200 || response.statusCode == 201) {
      _showSnack('Product added!', Colors.green);
      Navigator.pop(context, data);
    } else {
      _showSnack(data['error'] ?? 'Error', Colors.red);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  // ---------- UI COMPONENTS ----------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Product'),
        backgroundColor: const Color(0xFF4F46E5),
        actions: [
          IconButton(icon: Icon(Icons.check), onPressed: _handleSubmit),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Images'),
              _buildImageGrid(),
              const SizedBox(height: 20),

              _buildSectionHeader('Details'),
              _textField(_nameController, 'Product Name', Icons.shopping_bag),
              const SizedBox(height: 10),
              _textField(_brandController, 'Brand', Icons.copyright),
              const SizedBox(height: 10),
              _textField(
                _shortDescController,
                'Short Description',
                Icons.short_text,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              _textField(
                _longDescController,
                'Long Description',
                Icons.description,
                maxLines: 4,
              ),

              const SizedBox(height: 20),
              _buildSectionHeader('Inventory & Variations'),
              _buildVariationList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.indigo,
      ),
    ),
  );

  Widget _buildVariationList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          ..._variations.asMap().entries.map((entry) {
            int idx = entry.key;
            ProductVariation v = entry.value;
            return ListTile(
              title: Text("${v.color} - Size ${v.size}"),
              trailing: SizedBox(
                width: 100,
                child: TextFormField(
                  initialValue: v.quantity.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Qty', isDense: true),
                  onChanged: (val) =>
                      _variations[idx].quantity = int.tryParse(val) ?? 0,
                ),
              ),
            );
          }).toList(),
          TextButton.icon(
            onPressed: () {},
            icon: Icon(Icons.add),
            label: Text("Add Custom Variation"),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 4,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: _productImages.keys.map((key) {
        final img = _productImages[key];
        return GestureDetector(
          onTap: () => _selectImage(key),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: img == null
                ? Icon(Icons.add_a_photo)
                : Image.file(img, fit: BoxFit.cover),
          ),
        );
      }).toList(),
    );
  }

  // (SelectImage and Textfield helpers remain similar to your original code)
  void _selectImage(String key) {
    /* existing bottom sheet logic */
  }
  Widget _textField(
    TextEditingController ctrl,
    String lbl,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: lbl,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _switchTile(
    IconData icon,
    String title,
    bool val,
    Function(bool) fn,
  ) => SwitchListTile(
    secondary: Icon(icon),
    title: Text(title),
    value: val,
    onChanged: fn,
  );
}
