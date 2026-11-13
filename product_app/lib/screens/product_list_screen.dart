import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/net_image.dart';
import 'product_form_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  late Future<List<Product>> _future;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = ApiService.getProducts();
  }

  Future<void> _reload() async {
    final future = ApiService.getProducts();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _openForm([Product? p]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: p)),
    );
    if (mounted && saved == true) await _reload();
  }

  Future<void> _delete(Product p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete product'),
        content: Text('Delete "${p.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ApiService.deleteProduct(p.id!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
      await _reload();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Products'),
        scrolledUnderElevation: 0,
        actions: [IconButton(onPressed: _reload, icon: const Icon(Icons.refresh))],
      ),
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
              hintText: 'Search name or barcode',
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
        Expanded(
          child: FutureBuilder<List<Product>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return Center(child: Padding(padding: const EdgeInsets.all(16), child: Text('${snap.error}', textAlign: TextAlign.center)));
              }
              final items = snap.data!.where((p) {
                if (_query.isEmpty) return true;
                return p.name.toLowerCase().contains(_query) || (p.barcode ?? '').toLowerCase().contains(_query);
              }).toList();
              if (items.isEmpty) return const Center(child: Text('No products'));
              return RefreshIndicator(
                onRefresh: () async => _reload(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final p = items[i];
                    return _ProductCard(product: p, onTap: () => _openForm(p), onEdit: () => _openForm(p), onDelete: () => _delete(p));
                  },
                ),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({required this.product, required this.onTap, required this.onEdit, required this.onDelete});

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
            NetImage(url: product.imageUrl, size: 70),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 5),
                Text(product.categoryName ?? 'Uncategorized', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: scheme.onSurfaceVariant)),
                const SizedBox(height: 5),
                Text('Qty ${product.qty}  •  \$${product.priceOut.toStringAsFixed(2)}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: scheme.primary, fontWeight: FontWeight.w600)),
              ]),
            ),
            Column(children: [
              IconButton(visualDensity: VisualDensity.compact, tooltip: 'Edit product', icon: const Icon(Icons.edit_outlined), onPressed: onEdit),
              IconButton(visualDensity: VisualDensity.compact, tooltip: 'Delete product', icon: Icon(Icons.delete_outline, color: scheme.error), onPressed: onDelete),
            ]),
          ]),
        ),
      ),
    );
  }
}
