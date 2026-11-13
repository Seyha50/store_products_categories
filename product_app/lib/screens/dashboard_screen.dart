import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../widgets/net_image.dart';
import 'category_form_screen.dart';
import 'product_form_screen.dart';

class _DashData {
  final List<Product> products;
  final List<Category> categories;
  _DashData(this.products, this.categories);
}

class DashboardScreen extends StatefulWidget {
  final void Function(int index) onGoTo;
  const DashboardScreen({super.key, required this.onGoTo});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int lowStockLimit = 10;
  static const int expireDays = 30;

  late Future<_DashData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_DashData> _load() async {
    final r = await Future.wait([
      ApiService.getProducts(),
      ApiService.getCategories(),
    ]);
    return _DashData(r[0] as List<Product>, r[1] as List<Category>);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() {
      _future = future;
    });
    await future;
  }

  Future<void> _add(Widget form) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => form),
    );
    if (mounted && saved == true) await _reload();
  }

  String _money(double v) => '\$${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), actions: [
        IconButton(onPressed: _reload, icon: const Icon(Icons.refresh)),
      ]),
      body: FutureBuilder<_DashData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(onPressed: _reload, child: const Text('Retry')),
                ]),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => _reload(),
            child: _content(snap.data!),
          );
        },
      ),
    );
  }

  Widget _content(_DashData d) {
    final products = d.products;
    final totalQty = products.fold<int>(0, (s, p) => s + p.qty);
    final stockValue = products.fold<double>(0, (s, p) => s + p.qty * p.priceIn);

    final low = products.where((p) => p.qty <= lowStockLimit).toList()
      ..sort((a, b) => a.qty.compareTo(b.qty));

    final now = DateTime.now();
    final limit = now.add(const Duration(days: expireDays));
    final expiring = products
        .where((p) => p.expireDateTime != null && p.expireDateTime!.isBefore(limit))
        .toList()
      ..sort((a, b) => a.expireDateTime!.compareTo(b.expireDateTime!));

    final counts = <int, int>{};
    for (final p in products) {
      counts[p.categoryId] = (counts[p.categoryId] ?? 0) + 1;
    }
    final maxCount = counts.values.fold<int>(1, (m, v) => v > m ? v : m);

    return ListView(
      padding: const EdgeInsets.all(12),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // Quick actions
        Row(children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: () => _add(const ProductFormScreen()),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: FilledButton.tonalIcon(
              onPressed: () => _add(const CategoryFormScreen()),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Stat cards
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.7,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _StatCard(Icons.inventory_2, 'Products', '${products.length}', Colors.teal,
                onTap: () => widget.onGoTo(1)),
            _StatCard(Icons.category, 'Categories', '${d.categories.length}', Colors.indigo,
                onTap: () => widget.onGoTo(2)),
            _StatCard(Icons.layers, 'Total Qty', '$totalQty', Colors.orange),
            _StatCard(Icons.attach_money, 'Stock Value', _money(stockValue), Colors.green),
          ],
        ),

        // Low stock
        _SectionTitle('Low stock ($lowStockLimit)', low.length),
        if (low.isEmpty)
          const _EmptyNote('All products have enough stock.')
        else
          ...low.take(5).map((p) => _ProductRow(
                p,
                trailing: Text('Qty ${p.qty}',
                    style: TextStyle(
                        color: p.qty == 0 ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold)),
              )),

        // Expiring soon
        _SectionTitle('Expired / expiring in $expireDays days', expiring.length),
        if (expiring.isEmpty)
          const _EmptyNote('No products are close to expiry.')
        else
          ...expiring.take(5).map((p) {
            final days = p.expireDateTime!.difference(now).inDays;
            final expired = p.expireDateTime!.isBefore(DateTime(now.year, now.month, now.day));
            return _ProductRow(
              p,
              trailing: Text(
                expired ? 'Expired' : 'in $days d',
                style: TextStyle(
                    color: expired ? Colors.red : Colors.orange,
                    fontWeight: FontWeight.bold),
              ),
            );
          }),

        // Products per category
        _SectionTitle('Products by category', d.categories.length),
        if (d.categories.isEmpty)
          const _EmptyNote('No categories yet.')
        else
          ...d.categories.map((c) {
            final n = counts[c.id] ?? 0;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(c.name)),
                  Text('$n'),
                ]),
                const SizedBox(height: 4),
                LinearProgressIndicator(value: n / maxCount, minHeight: 8),
              ]),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard(this.icon, this.label, this.value, this.color, {this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            CircleAvatar(
              backgroundColor: color.withAlpha(40),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  Text(label, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final int count;
  const _SectionTitle(this.text, this.count);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 6),
      child: Row(children: [
        Expanded(
          child: Text(text,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ),
        Chip(label: Text('$count'), visualDensity: VisualDensity.compact),
      ]),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  final String text;
  const _EmptyNote(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      );
}

class _ProductRow extends StatelessWidget {
  final Product p;
  final Widget trailing;
  const _ProductRow(this.p, {required this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
      leading: NetImage(url: p.imageUrl, size: 40),
      title: Text(p.name),
      subtitle: Text(p.categoryName ?? '-'),
      trailing: trailing,
    );
  }
}
