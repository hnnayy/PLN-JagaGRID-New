import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/tree_growth_provider.dart';
import '../../models/tree_growth.dart';
import 'tree_growth_form_page.dart';

class TreeGrowthListPage extends StatefulWidget {
  const TreeGrowthListPage({super.key});

  @override
  State<TreeGrowthListPage> createState() => _TreeGrowthListPageState();
}

class _TreeGrowthListPageState extends State<TreeGrowthListPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TreeGrowthProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF125E72), Color(0xFF14A2B9)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Master Pertumbuhan pohon',
              maxLines: 1,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              iconSize: 34,
              icon: const Icon(Icons.add_circle_outline, color: Colors.white),
              onPressed: () async {
                final created = await Navigator.push<TreeGrowth?>(
                  context,
                  MaterialPageRoute(builder: (_) => const TreeGrowthFormPage()),
                );
                if (created != null && mounted) {
                  await context.read<TreeGrowthProvider>().add(created.name, created.growthRate);
                }
              },
            ),
          ],
        ),
        body: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFFF5F7FA),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Consumer<TreeGrowthProvider>(
                  builder: (context, provider, _) {
                    if (provider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (provider.errorMessage != null) {
                      return Center(child: Text('Error: ${provider.errorMessage}'));
                    }
                    final items = provider.items;
                    if (items.isEmpty) {
                      return const Center(child: Text('Belum ada data. Tambahkan jenis pohon.'));
                    }
                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            elevation: 2,
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: InkWell(
                              onTap: () async {
                                final updated = await Navigator.push<TreeGrowth?>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TreeGrowthFormPage(item: item),
                                  ),
                                );
                                if (updated != null && context.mounted) {
                                  await context.read<TreeGrowthProvider>().update(updated);
                                }
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF14A2B9),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Center(
                                        child: Icon(Icons.eco, color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name,
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF2C3E50),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Pertumbuhan pohon: ${item.growthRate.round()} cm/tahun',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF7F8C8D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Color(0xFF0B5F6D)),
                                          onPressed: () async {
                                            final updated = await Navigator.push<TreeGrowth?>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => TreeGrowthFormPage(item: item),
                                              ),
                                            );
                                            if (updated != null && context.mounted) {
                                              await context.read<TreeGrowthProvider>().update(updated);
                                            }
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () async {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('Hapus Data'),
                                                content: Text('Hapus ${item.name}?'),
                                                actions: [
                                                  TextButton(onPressed: ()=>Navigator.pop(ctx,false), child: const Text('Batal')),
                                                  ElevatedButton(onPressed: ()=>Navigator.pop(ctx,true), child: const Text('Hapus')),
                                                ],
                                              ),
                                            );
                                            if (confirm == true && context.mounted) {
                                              await context.read<TreeGrowthProvider>().remove(item.id);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
