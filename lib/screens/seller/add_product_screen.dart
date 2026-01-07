import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:vora/providers/user_provider.dart';
import '../../config/api_urls.dart';
import '../../api_client.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({Key? key}) : super(key: key);

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _shortDescController = TextEditingController();
  final _longDescController = TextEditingController();
  final List<String> _colors = [];
  final List<String> _sizes = [];
  final Map<String, File?> _colorImages = {};
  final Map<String, Map<String, dynamic>> _variantData = {};
  final _colorInputController = TextEditingController();
  final List<String> _customColors = [];
  final ImagePicker _picker = ImagePicker();
  final Map<String, File?> _productImages = {'Lifestyle': null};
  String _selectedCategory = 'Clothing';
  final List<String> _categories = ['Clothing'];
  final Map<String, List<String>> _varients = {
    'Clothing': ['Colors', 'Sizes'],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _shortDescController.dispose();
    _longDescController.dispose();
    super.dispose();
  }

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
      format: CompressFormat.jpeg,
    );

    return compressed != null ? File(compressed.path) : null;
  }

  void _selectImage(String key) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _pickAndCompress(ImageSource.camera);
                if (img != null) {
                  setState(() => _colorImages[key] = img);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final img = await _pickAndCompress(ImageSource.gallery);
                if (img != null) {
                  setState(() => _colorImages[key] = img);
                }
              },
            ),
            if (_productImages[key] != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _colorImages[key] = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_colorImages.isEmpty ||
        _colorImages.values.every((file) => file == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'At least one lifestyle image for a color is mandatory',
          ),
        ),
      );
      return;
    }
    if (_selectedCategory == 'Clothing' &&
        (_colors.isEmpty || _sizes.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select at least one color and size')),
      );
      return;
    }
    List<File> imagesToUpload = [];
    Map<String, String> colorImageMapping = {};

    _colorImages.forEach((color, file) {
      if (file != null) {
        imagesToUpload.add(file);
        // Maps the color name to the file name so the backend knows which is which
        colorImageMapping[color] = file.path.split('/').last;
      }
    });

    // 4. Send Multipart Request
    try {
      final response = await ApiClient.multipartPost(
        url: ApiUrls.addProduct,
        fields: {
          "name": _nameController.text,
          "brand": _brandController.text,
          "category": _selectedCategory,
          "short_description": _shortDescController.text,
          "description": _longDescController.text,
          "variants": jsonEncode(_variantData),
          "color_image_map": jsonEncode(colorImageMapping),
          "selected_colors": jsonEncode(_colors),
          "selected_sizes": jsonEncode(_sizes),
        },
        images: imagesToUpload,
      );

      final responseBody = await response.stream.bytesToString();
      final data = jsonDecode(responseBody);

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Product added successfully'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
        // Navigator.pop(context, data);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['error'] ?? 'Failed to add product')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final Color primaryColor = userProvider.primaryColor;
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Add New Product'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _handleSubmit,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Basic Information'),
              const SizedBox(height: 12),
              _textField(
                controller: _nameController,
                label: 'Product Name',
                icon: Icons.shopping_bag_outlined,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _categoryDropdown()),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _textField(
                      controller: _brandController,
                      label: 'Brand',
                      icon: Icons.copyright,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _shortDescController,
                label: 'Short Description',
                icon: Icons.short_text,
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              _textField(
                controller: _longDescController,
                label: 'Long Description',
                icon: Icons.description,
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              _sectionTitle('Product Varients'),
              const SizedBox(height: 12),
              if (_varients[_selectedCategory]?.contains('Colors') ??
                  false) ...[
                _buildColorCreator(),
                const SizedBox(height: 16),
              ],

              if (_varients[_selectedCategory]?.contains('Sizes') ?? false) ...[
                Text(
                  "Select Available Sizes",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                _buildSizeChips(),
                const SizedBox(height: 16),
              ],

              if (_colors.isNotEmpty) ...[
                Text(
                  "Upload Images for Each Color",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 12),
                _buildColorImageUploaders(),
                const SizedBox(height: 24),
              ],

              if (_colors.isNotEmpty && _sizes.isNotEmpty) ...[
                _buildVariantGrid(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _categoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: const InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(),
      ),
      items: _categories
          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
          .toList(),
      onChanged: (v) => setState(() => _selectedCategory = v!),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildColorCreator() {
    final List<String> commonColors = [
      'White',
      'Black',
      'Red',
      'Blue',
      'Green',
      'Grey',
      'Yellow',
    ];
    final List<String> allAvailableColors = [...commonColors, ..._customColors];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Select Available Colors",
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ...allAvailableColors.map((colorName) {
              final isSelected = _colors.contains(colorName);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    isSelected
                        ? _colors.remove(colorName)
                        : _colors.add(colorName);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.indigo : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? Colors.indigo : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Icon(Icons.check, size: 16, color: Colors.white),
                      if (isSelected) const SizedBox(width: 4),
                      Text(
                        colorName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            ActionChip(
              avatar: const Icon(Icons.add, size: 18),
              label: const Text("Custom"),
              onPressed: () => _showCustomColorDialog(),
              backgroundColor: Colors.grey.shade100,
            ),
          ],
        ),
      ],
    );
  }

  void _showCustomColorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Custom Color"),
        content: TextField(
          controller: _colorInputController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: "e.g. Maroon or Teal",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              String newColor = _colorInputController.text.trim();
              if (newColor.isNotEmpty) {
                setState(() {
                  // 1. Add to the temporary custom list so it shows up as a chip
                  if (!_customColors.contains(newColor)) {
                    _customColors.add(newColor);
                  }
                  // 2. Automatically select it
                  if (!_colors.contains(newColor)) {
                    _colors.add(newColor);
                  }
                });
                _colorInputController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text("Add & Select"),
          ),
        ],
      ),
    );
  }

  Widget _buildSizeChips() {
    final List<String> allSizes = ['S', 'M', 'L', 'XL', 'XXL'];
    return Wrap(
      spacing: 8,
      children: allSizes.map((s) {
        final isSelected = _sizes.contains(s);
        return FilterChip(
          label: Text(s),
          selected: isSelected,
          onSelected: (val) {
            setState(() => val ? _sizes.add(s) : _sizes.remove(s));
          },
        );
      }).toList(),
    );
  }

  Widget _buildColorImageUploaders() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _colors.map((color) {
            final file = _colorImages[color];
            return Column(
              children: [
                GestureDetector(
                  onTap: () => _selectImage(color),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: file != null ? Colors.indigo : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: file == null
                        ? Icon(
                            Icons.add_a_photo_outlined,
                            color: Colors.grey[600],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(file, fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  color,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVariantGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 2,
                  child: Text(
                    "Variant",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    "Price",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Stock",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Variant Rows
          ..._colors.expand((color) {
            return _sizes.map((size) {
              String key = "$color-$size";
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[100]!)),
                ),
                child: Row(
                  children: [
                    // Label
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            color,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            "Size: $size",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Price Input
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _updateVariant(key, 'price', val),
                        decoration: _variantInputDecoration('\$'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Stock Input
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        onChanged: (val) => _updateVariant(key, 'stock', val),
                        decoration: _variantInputDecoration('Qty'),
                      ),
                    ),
                  ],
                ),
              );
            });
          }),
        ],
      ),
    );
  }

  InputDecoration _variantInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
    );
  }

  void _updateVariant(String key, String field, String value) {
    _variantData.putIfAbsent(key, () => {'price': 0, 'stock': 0});
    _variantData[key]![field] = double.tryParse(value) ?? 0;
  }
}
