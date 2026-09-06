import 'package:flutter/material.dart';

import '../services/kitchen_service.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen>
    with SingleTickerProviderStateMixin {
  late TabController _kitchenTabController;
  late Future<List<Map<String, dynamic>>> _scheduleFuture;
  late Future<List<Map<String, dynamic>>> _mealsFuture;

  @override
  void initState() {
    super.initState();
    _kitchenTabController = TabController(length: 2, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _kitchenTabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _scheduleFuture = KitchenService.getCalendarSchedule();
      _mealsFuture = KitchenService.getMeals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal ERP - Cucina & Calendario'),
        bottom: TabBar(
          controller: _kitchenTabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_view_week),
              text: 'Calendario Settimanale',
            ),
            Tab(icon: Icon(Icons.restaurant_menu), text: 'Ricette / Piatti'),
          ],
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([_scheduleFuture, _mealsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final schedule = snapshot.data![0] as List<Map<String, dynamic>>;
          final meals = snapshot.data![1] as List<Map<String, dynamic>>;

          return TabBarView(
            controller: _kitchenTabController,
            children: [
              _buildHorizontalCalendarTab(schedule, meals),
              _buildMealsTab(meals),
            ],
          );
        },
      ),
    );
  }

  // --- TAB 1: CALENDARIO ORIZZONTALE PER GIORNI + SLOT VERTICALI ---
  Widget _buildHorizontalCalendarTab(
    List<Map<String, dynamic>> schedule,
    List<Map<String, dynamic>> meals,
  ) {
    // Raggruppiamo i pasti per data (es. "2026-09-06")
    Map<String, List<Map<String, dynamic>>> groupedByDate = {};
    for (var item in schedule) {
      String date = item['date'] ?? '';
      groupedByDate.putIfAbsent(date, () => []);
      groupedByDate[date]!.add(item);
    }

    // Creiamo una lista fissa o dinamica di giorni da mostrare (es. gli ultimi 7 giorni o le date presenti)
    List<String> dates = groupedByDate.keys.toList()..sort();
    if (dates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Nessun pasto pianificato.'),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showAddSlotDialog(meals),
              icon: const Icon(Icons.add),
              label: const Text('Pianifica il primo slot'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Pulsante superiore per pianificare un nuovo slot
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddSlotDialog(meals),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Pianifica Slot nel Calendario'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(40),
            ),
          ),
        ),
        const Divider(height: 1),
        // Lista Orizzontale dei Giorni
        Expanded(
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.all(8.0),
            itemCount: dates.length,
            itemBuilder: (context, index) {
              String date = dates[index];
              List<Map<String, dynamic>> slots = groupedByDate[date]!;

              return Container(
                width: 220, // Larghezza della colonna del singolo giorno
                margin: const EdgeInsets.symmetric(horizontal: 6.0),
                child: Card(
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Intestazione Giorno (Orizzontale in cima alla colonna)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade800,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Center(
                            child: Text(
                              date,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Elenco Verticale dei singoli slot all'interno del giorno
                        Expanded(
                          child: ListView.builder(
                            itemCount: slots.length,
                            itemBuilder: (context, slotIndex) {
                              final slot = slots[slotIndex];
                              String slotName = slot['slot'] ?? 'Slot';
                              String mealName =
                                  slot['meal_name'] ?? slot['name'] ?? 'Pasto';
                              String contextType = slot['context'] ?? 'A Casa';
                              int consumed = slot['consumed'] ?? 0;

                              return Card(
                                color: Colors.grey.shade50,
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            slotName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.green,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            contextType,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        mealName,
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration: consumed == 1
                                              ? TextDecoration.lineThrough
                                              : null,
                                          color: consumed == 1
                                              ? Colors.grey
                                              : Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.end,
                                        children: [
                                          TextButton.icon(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: const Size(50, 25),
                                            ),
                                            onPressed: () async {
                                              // Tasto Consuma / Annulla Consumazione
                                              await KitchenService.toggleConsumed(
                                                slot['id'],
                                                consumed == 1 ? 0 : 1,
                                              );
                                              _refreshData();
                                            },
                                            icon: Icon(
                                              consumed == 1
                                                  ? Icons.undo
                                                  : Icons.check,
                                              size: 14,
                                            ),
                                            label: Text(
                                              consumed == 1
                                                  ? 'Ripristina'
                                                  : 'Consuma',
                                              style: const TextStyle(
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                              size: 16,
                                            ),
                                            tooltip: 'Elimina Slot',
                                            onPressed: () async {
                                              await KitchenService.deleteScheduleSlot(
                                                slot['id'],
                                              );
                                              _refreshData();
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- TAB 2: ELENCO RICETTE / PIATTI ---
  Widget _buildMealsTab(List<Map<String, dynamic>> meals) {
    if (meals.isEmpty) {
      return const Center(child: Text('Nessuna ricetta o piatto registrato.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12.0),
      itemCount: meals.length,
      itemBuilder: (context, index) {
        final meal = meals[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.restaurant, color: Colors.orange),
            title: Text(
              meal['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Ricetta registrata'),
          ),
        );
      },
    );
  }

  // --- DIALOG PER PIANIFICARE UN NUOVO SLOT ---
  void _showAddSlotDialog(List<Map<String, dynamic>> meals) {
    String selectedSlot = 'Colazione';
    String selectedContext = 'A Casa (Canonico)';

    // 1. Convertiamo in modo sicuro gestendo l'eventuale valore nullo
    int? selectedMealId = (meals.isNotEmpty && meals.first['id'] != null)
        ? (meals.first['id'] as num).toInt()
        : null;

    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Pianifica Slot nel Calendario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedSlot,
                  items: ['Colazione', 'Pranzo', 'Cena', 'Spuntino']
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => selectedSlot = val!),
                  decoration: const InputDecoration(
                    labelText: 'Slot Giornaliero',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedContext,
                  items: ['A Casa (Canonico)', 'Fuori Casa', 'Lavoro']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedContext = val!),
                  decoration: const InputDecoration(labelText: 'Contesto'),
                ),
                const SizedBox(height: 8),
                if (meals.isNotEmpty)
                  DropdownButtonFormField<int>(
                    // 2. Usiamo un operatore di sicurezza (?? 0) per evitare che passi un valore nullo al widget
                    value: selectedMealId ?? (meals.first['id'] as num).toInt(),
                    items: meals.map((m) {
                      int mealId = (m['id'] as num).toInt();
                      return DropdownMenuItem<int>(
                        value: mealId,
                        child: Text(m['name']),
                      );
                    }).toList(),
                    onChanged: (val) =>
                        setDialogState(() => selectedMealId = val),
                    decoration: const InputDecoration(
                      labelText: 'Piatto / Ricetta',
                    ),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      'Data: ${selectedDate.toIso8601String().substring(0, 10)}',
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2025),
                          lastDate: DateTime(2030),
                        );
                        if (picked != null) {
                          setDialogState(() => selectedDate = picked);
                        }
                      },
                      child: const Text('Cambia Data'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () async {
                // 3. Controlliamo che l'ID sia valido prima di procedere
                if (selectedMealId != null) {
                  String dateStr = selectedDate.toIso8601String().substring(
                    0,
                    10,
                  );
                  await KitchenService.addCalendarSchedule(
                    date: dateStr,
                    slot: selectedSlot,
                    mealId: selectedMealId!, // L'esclamativo (!) garantisce a Dart che qui la variabile non è null
                    context: selectedContext,
                  );
                  Navigator.pop(context);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Slot pianificato con successo!'),
                    ),
                  );
                }
              },
              child: const Text('Salva Pianificazione'),
            ),
          ],
        ),
      ),
    );
  }
}
