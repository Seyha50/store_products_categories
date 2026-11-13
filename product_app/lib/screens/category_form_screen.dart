import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/category.dart';
import '../services/api_service.dart';

class CategoryFormScreen extends StatefulWidget {
  final Category? category; // null = add, not null = edit
  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  XFile? _image;
  Uint8List? _imageBytes;
  bool _saving = false;
  bool _imageError = false;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    if (c != null) {
      _name.text = c.name;
      _desc.text = c.description ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x != null) {
      setState(() {
        _image = x;
        _imageBytes = null;
        _imageError = false;
      });
      _imageBytes = await x.readAsBytes();
      if (mounted) setState(() {});
    }
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    // Laravel requires an image when creating a category
    final needImage = !_isEdit && _image == null;
    setState(() => _imageError = needImage);
    if (!formOk || needImage) return;

    setState(() => _saving = true);
    var saved = false;
    try {
      await ApiService.saveCategory({
        'category_name': _name.text.trim(),
        'description': _desc.text.trim(),
      }, id: widget.category?.id, image: _image);
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

  InputDecoration _decoration(String label, {String? hint}) {
    final scheme = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: label,
      hintText: hint,
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

  Widget _imagePlaceholder(ColorScheme scheme) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              size: 42, color: scheme.primary),
          const SizedBox(height: 8),
          Text('Tap to add category image',
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      );

  @override
  Widget build(BuildContext context) {
    final existingUrl = widget.category?.imageUrl;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Category' : 'Add Category'),
        scrolledUnderElevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
          _sectionLabel(context, 'Category image'),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 190,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: _imageError ? scheme.error : scheme.outlineVariant,
                    width: _imageError ? 2 : 1),
              ),
              child: Stack(fit: StackFit.expand, children: [
                if (_image != null && _imageBytes != null)
                  Image.memory(_imageBytes!, fit: BoxFit.cover)
                else if (existingUrl != null)
                  Image.network(existingUrl,
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
          if (_imageError)
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Text('Please choose an image',
                  style: TextStyle(color: scheme.error, fontSize: 12)),
            ),
          const SizedBox(height: 26),
          _sectionLabel(context, 'Category information'),
          TextFormField(
            controller: _name,
            maxLength: 50,
            decoration: _decoration('Category name', hint: 'Add a Category name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _desc,
            maxLength: 255,
            maxLines: 3,
            decoration: _decoration('Description', hint: 'Add a short description'),
          ),
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
              label: Text(_isEdit ? 'SAVE CHANGES' : 'SAVE CATEGORY'),
            ),
          ),
        ]),
      ),
    );
  }
}
