import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/api_service.dart';
import '../widgets/net_image.dart';
import 'category_form_screen.dart';

class CategoryListScreen extends StatefulWidget {
  const CategoryListScreen({super.key});

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  late Future<List<Category>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = ApiService.getCategories();
  }

  Future<void> _reload() async {
    final future = ApiService.getCategories();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _openForm([Category? c]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CategoryFormScreen(category: c)),
    );
    if (mounted && saved == true) await _reload();
  }

  Future<void> _delete(Category c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete category'),
        content: Text(
            'Delete "${c.name}"? Products in this category will also be deleted.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteCategory(c.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Category deleted')));
      await _reload();
    } catch (e) {
      // Server returns "Category has products" when it still has products
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(title: const Text('Categories'), scrolledUnderElevation: 0, actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(),
        elevation: 2,
        child: const Icon(Icons.add_rounded),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: TextField(
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search categories',
              filled: true,
              fillColor: scheme.surfaceContainerHighest.withAlpha(110),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: scheme.outlineVariant.withAlpha(90)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: scheme.primary, width: 2),
              ),
            ),
            onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
          ),
        ),
        Expanded(child: FutureBuilder<List<Category>>(
          future: _future,
          builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          final items = snap.data!.where((c) {
            if (_query.isEmpty) return true;
            return c.name.toLowerCase().contains(_query) ||
                (c.description ?? '').toLowerCase().contains(_query);
          }).toList();
          if (items.isEmpty) return const Center(child: Text('No categories'));
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final c = items[i];
                return _CategoryCard(
                  category: c,
                  onTap: () => _openForm(c),
                  onEdit: () => _openForm(c),
                  onDelete: () => _delete(c),
                );
              },
            ),
          );
        },
      )),
      ]),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({required this.category, required this.onTap, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant.withAlpha(90)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            NetImage(url: category.imageUrl, size: 70, placeholder: Icons.category_outlined),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(category.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 5),
              Text((category.description ?? '').isEmpty ? 'No description' : category.description!,
                  maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant)),
            ])),
            Column(children: [
              IconButton(visualDensity: VisualDensity.compact, tooltip: 'Edit category', icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
              IconButton(visualDensity: VisualDensity.compact, tooltip: 'Delete category', icon: Icon(Icons.delete_outline, color: scheme.error), onPressed: onDelete),
            ]),
          ]),
        ),
      ),
    );
  }
}
