import 'package:flutter/material.dart';

import '../services/kitchen_service.dart';

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
    _loadData();
  }

  void _loadData() {
    setState(() {
      _inventoryFuture = KitchenService.getInventoryItems();
    });
  }

  // Dialog per aggiungere un nuovo elemento alla dispensa
  void _showAddDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1');
    String unit = 'pezzi';
    String category = 'Dispensa';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuovo Articolo in Dispensa'),
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
                items: ['pezzi', 'bustine', 'g', 'kg', 'ml', 'l']
                    .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                    .toList(),
                onChanged: (val) => setDialogState(() => unit = val!),
                decoration: const InputDecoration(labelText: 'Unità di misura'),
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
                final name = nameController.text.trim();
                final qty = double.tryParse(qtyController.text) ?? 0.0;
                if (name.isNotEmpty) {
                  await KitchenService.addInventoryItem(
                    name,
                    qty,
                    unit,
                    category,
                  );
                  Navigator.pop(context);
                  _loadData();
                }
              },
              child: const Text('Salva'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dispensa')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _inventoryFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;

          if (items.isEmpty) {
            return const Center(child: Text('La dispensa è vuota.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final id = (item['id'] as num).toInt();

              // Stampiamo in console la riga per capire le chiavi esatte del database
              print('DEBUG ITEM: $item');

              // Controlliamo diverse possibili chiavi per il nome
              final name =
                  item['name'] ??
                  item['title'] ??
                  item['item_name'] ??
                  'Senza Nome';
              final qty = item['quantity'] ?? item['qty'] ?? 0;
              final unit = item['unit'] ?? '';
              final category = item['category'] ?? 'Dispensa';

              return Dismissible(
                key: Key(id.toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  color: Colors.red,
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Conferma eliminazione"),
                        content: Text(
                          "Vuoi davvero rimuovere '$name' dalla dispensa?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Annulla"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Elimina"),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  await KitchenService.deleteInventoryItem(id);
                  _loadData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('$name rimosso dalla dispensa.')),
                  );
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.kitchen, color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Categoria: $category',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '$qty $unit',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          tooltip: 'Elimina',
                          onPressed: () async {
                            await KitchenService.deleteInventoryItem(id);
                            _loadData();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$name rimosso dalla dispensa.'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        tooltip: 'Aggiungi Articolo',
        child: const Icon(Icons.add),
      ),
    );
  }
}
