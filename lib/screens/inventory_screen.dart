import 'package:flutter/material.dart';

import '../services/inventory_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Future<List<Map<String, dynamic>>> _inventoryFuture;

  @override
  void initState() {
    super.initState();
    _refreshInventory();
  }

  void _refreshInventory() {
    setState(() {
      _inventoryFuture = InventoryService.getInventory();
    });
  }

  void _showAddInventoryDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1.0');
    String unit = 'pezzi';
    String category = 'Dispensa';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi alla Dispensa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome Articolo'),
            ),
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantità'),
            ),
            DropdownButtonFormField<String>(
              value: unit,
              items: [
                'grammi',
                'kg',
                'ml',
                'litri',
                'pezzi',
                'confezioni',
              ].map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
              onChanged: (val) => unit = val!,
              decoration: const InputDecoration(labelText: 'Unità di Misura'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                double qty = double.tryParse(qtyController.text) ?? 1.0;
                await InventoryService.addInventoryItem(
                  nameController.text.trim(),
                  qty,
                  unit,
                  category,
                );
                Navigator.pop(context);
                _refreshInventory();
              }
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Dispensa vuota.'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: const Icon(Icons.kitchen, color: Colors.orange),
                title: Text(
                  item['item_name'],
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Categoria: ${item['category']}'),
                trailing: Text(
                  '${item['quantity']} ${item['unit']}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInventoryDialog,
        child: const Icon(Icons.add),
        tooltip: 'Aggiungi Articolo',
      ),
    );
  }
}
