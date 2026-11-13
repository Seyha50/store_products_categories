import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product; // null = add, not null = edit
  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  final _barcode = TextEditingController();
  final _expire = TextEditingController();
  final _qty = TextEditingController();
  final _priceIn = TextEditingController();
  final _priceOut = TextEditingController();

  List<Category> _categories = [];
  int? _categoryId;
  XFile? _image;
  Uint8List? _imageBytes;
  bool _saving = false;

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    if (p != null) {
      _name.text = p.name;
      _desc.text = p.description ?? '';
      _barcode.text = p.barcode ?? '';
      _expire.text = p.expireDate ?? '';
      _qty.text = '${p.qty}';
      _priceIn.text = '${p.priceIn}';
      _priceOut.text = '${p.priceOut}';
      _categoryId = p.categoryId;
    }
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final c = await ApiService.getCategories();
      if (!mounted) return;
      setState(() => _categories = c);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  void dispose() {
    for (final c in [_name, _desc, _barcode, _expire, _qty, _priceIn, _priceOut]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) {
      final bytes = await x.readAsBytes();
      if (mounted) {
        setState(() {
          _image = x;
          _imageBytes = bytes;
        });
      }
    }
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_expire.text) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      _expire.text =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    var saved = false;
    try {
      await ApiService.saveProduct({
        'ProductName': _name.text.trim(),
        'Description': _desc.text.trim(),
        'CategoryID': '$_categoryId',
        if (_barcode.text.trim().isNotEmpty) 'Barcode': _barcode.text.trim(),
        if (_expire.text.isNotEmpty) 'Expiredate': _expire.text,
        'Qty': _qty.text.trim(),
        'UnitPriceIn': _priceIn.text.trim(),
        'UnitPriceOut': _priceOut.text.trim(),
      }, id: widget.product?.id, image: _image);
      if (!mounted) return;
      saved = true;
      setState(() => _saving = false);
      Navigator.of(context).pop<bool>(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted && !saved) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _number(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    return double.tryParse(v) == null ? 'Invalid number' : null;
  }

  InputDecoration _decoration(String label, {String? hint, Widget? suffixIcon}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: scheme.surfaceContainerHighest.withAlpha(110),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(90)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 2),
      ),
    );
  }

  Widget _sectionLabel(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(text.toUpperCase(),
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                )),
      );

  @override
  Widget build(BuildContext context) {
    final validCategory = _categories.any((c) => c.id == _categoryId);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Product' : 'Add Product'),
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
          _sectionLabel(context, 'Product image'),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 190,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Stack(fit: StackFit.expand, children: [
                if (_image != null)
                  Image.memory(_imageBytes!, fit: BoxFit.cover)
                else if (widget.product?.imageUrl != null)
                  Image.network(widget.product!.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(scheme))
                else
                  _imagePlaceholder(scheme),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface.withAlpha(220),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Change image',
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 26),
          _sectionLabel(context, 'Basic information'),
          TextFormField(
              controller: _name,
              decoration: _decoration('Product name', hint: 'Add Product name'),
              validator: _required),
          const SizedBox(height: 12),
          TextFormField(
              controller: _desc,
              maxLines: 3,
              decoration: _decoration('Description', hint: 'Add a short description')),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: validCategory ? _categoryId : null,
            decoration: _decoration('Category').copyWith(
              helperText: _categories.isEmpty ? 'No categories yet. Add one first.' : null,
            ),
            items: _categories
                .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => _categoryId = v),
            validator: (v) => v == null ? 'Select category' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: _barcode,
              decoration: _decoration('Barcode', hint: 'Optional')),
          const SizedBox(height: 26),
          _sectionLabel(context, 'Stock and pricing'),
          TextFormField(
            controller: _expire,
            readOnly: true,
            onTap: _pickDate,
            decoration: _decoration('Expiry date', hint: 'Optional',
              suffixIcon: _expire.text.isEmpty
                  ? const Icon(Icons.calendar_month_outlined)
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _expire.clear()),
                    )),
          ),
          const SizedBox(height: 12),
          TextFormField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: _decoration('Quantity'),
              validator: _number),
          const SizedBox(height: 12),
          TextFormField(
              controller: _priceIn,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('Purchase price', hint: '0.00'),
              validator: _number),
          const SizedBox(height: 12),
          TextFormField(
              controller: _priceOut,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: _decoration('Selling price', hint: '0.00'),
              validator: _number),
          const SizedBox(height: 28),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.check_rounded),
            label: Text(_isEdit ? 'SAVE CHANGES' : 'SAVE PRODUCT'),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _imagePlaceholder(ColorScheme scheme) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 42, color: scheme.primary),
          const SizedBox(height: 8),
          Text('Tap to add product image',
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      );
}
