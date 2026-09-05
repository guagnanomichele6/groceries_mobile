import 'package:flutter/material.dart';

import '../services/kitchen_service.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  late Future<List<Map<String, dynamic>>> _scheduleFuture;
  late Future<List<Map<String, dynamic>>> _mealsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _scheduleFuture = KitchenService.getCalendarSchedule();
      _mealsFuture = KitchenService.getMeals();
    });
  }

  void _showAddMealDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuovo Piatto / Ricetta'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: 'Nome Piatto'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                await KitchenService.addMeal(nameController.text.trim());
                Navigator.pop(context);
                _refreshData();
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          flexibleSpace: const Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TabBar(
                tabs: [
                  Tab(
                    text: 'Calendario Pasti',
                    icon: Icon(Icons.calendar_today),
                  ),
                  Tab(
                    text: 'Ricette / Piatti',
                    icon: Icon(Icons.restaurant_menu),
                  ),
                ],
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // TAB 1: Calendario
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _scheduleFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nessun pasto pianificato.'));
                }
                final schedule = snapshot.data!;
                return ListView.builder(
                  itemCount: schedule.length,
                  itemBuilder: (context, index) {
                    final item = schedule[index];
                    return ListTile(
                      leading: const Icon(Icons.fastfood, color: Colors.green),
                      title: Text(
                        item['meal_name'] ?? 'Pasto libero',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Data: ${item['date']} • Slot: ${item['slot']}',
                      ),
                      trailing: Text(
                        item['context'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            // TAB 2: Elenco Piatti
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _mealsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nessuna ricetta registrata.'),
                  );
                }
                final meals = snapshot.data!;
                return ListView.builder(
                  itemCount: meals.length,
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return ListTile(
                      leading: const Icon(Icons.book, color: Colors.blueAccent),
                      title: Text(
                        meal['name'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddMealDialog,
          child: const Icon(Icons.add),
          tooltip: 'Aggiungi Piatto',
        ),
      ),
    );
  }
}
