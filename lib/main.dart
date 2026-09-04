import 'package:flutter/material.dart';

import 'database/database_helper.dart';
import 'services/finance_service.dart';
import 'screens/inventory_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.database;
  runApp(const PersonalErpApp());
}

class PersonalErpApp extends StatelessWidget {
  const PersonalErpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal ERP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MainNavigator(),
    );
  }
}

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FinanceHomeScreen(), // <-- Qui c'era il segnaposto, ora rimettiamo la schermata vera!
    const InventoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance),
            label: 'Finanza',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.kitchen), label: 'Dispensa'),
        ],
      ),
    );
  }
}

// ==========================================
// SCHERMATA FINANZA (ripristinata e integrata)
// ==========================================
class FinanceHomeScreen extends StatefulWidget {
  const FinanceHomeScreen({super.key});

  @override
  State<FinanceHomeScreen> createState() => _FinanceHomeScreenState();
}

class _FinanceHomeScreenState extends State<FinanceHomeScreen> {
  late Future<List<Map<String, dynamic>>> _accountsFuture;
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    setState(() {
      _accountsFuture = FinanceService.getAccounts();
      _transactionsFuture = FinanceService.getTransactions();
    });
  }

  void _showAddAccountDialog() {
    final nameController = TextEditingController();
    final balanceController = TextEditingController(text: '0.0');
    String type = 'Banca';
    String currency = 'EUR';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuovo Conto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome Conto'),
            ),
            TextField(
              controller: balanceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Saldo Iniziale'),
            ),
            DropdownButtonFormField<String>(
              value: type,
              items: [
                'Banca',
                'Contanti',
                'Investimento',
              ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
              onChanged: (val) => type = val!,
              decoration: const InputDecoration(labelText: 'Tipo Conto'),
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
                double balance = double.tryParse(balanceController.text) ?? 0.0;
                await FinanceService.addAccount(
                  nameController.text.trim(),
                  type,
                  balance,
                  currency,
                );
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

  void _showAddTransactionDialog(List<Map<String, dynamic>> accounts) {
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Crea prima almeno un conto bancario o cash!'),
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    final descController = TextEditingController();
    int selectedAccountId = accounts.first['id'];
    String category = 'Spesa';
    bool isExpense = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuova Transazione'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Text(
                          'Spesa (-)',
                          style: TextStyle(color: Colors.white),
                        ),
                        selected: isExpense,
                        selectedColor: Colors.red,
                        onSelected: (val) =>
                            setDialogState(() => isExpense = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text(
                          'Entrata (+)',
                          style: TextStyle(color: Colors.white),
                        ),
                        selected: !isExpense,
                        selectedColor: Colors.green,
                        onSelected: (val) =>
                            setDialogState(() => isExpense = false),
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Importo'),
                ),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(
                    labelText: 'Descrizione / Esercente',
                  ),
                ),
                DropdownButtonFormField<int>(
                  value: selectedAccountId,
                  items: accounts
                      .map(
                        (acc) => DropdownMenuItem<int>(
                          value: acc['id'] as int,
                          child: Text(acc['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setDialogState(() => selectedAccountId = val!),
                  decoration: const InputDecoration(
                    labelText: 'Conto di Riferimento',
                  ),
                ),
                DropdownButtonFormField<String>(
                  value: category,
                  items: ['Spesa', 'Bollette', 'Svago', 'Stipendio', 'Altro']
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (val) => setDialogState(() => category = val!),
                  decoration: const InputDecoration(labelText: 'Categoria'),
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
                double? rawAmount = double.tryParse(amountController.text);
                if (rawAmount != null && rawAmount > 0) {
                  double finalAmount = isExpense ? -rawAmount : rawAmount;
                  String dateStr = DateTime.now().toIso8601String().substring(
                    0,
                    10,
                  );

                  await FinanceService.addTransaction(
                    date: dateStr,
                    accountId: selectedAccountId,
                    amount: finalAmount,
                    category: category,
                    description: descController.text.trim(),
                  );

                  Navigator.pop(context);
                  _refreshData();
                }
              },
              child: const Text('Registra'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal ERP - Finanza'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _showAddAccountDialog,
            tooltip: 'Aggiungi Conto',
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'I Miei Conti',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            height: 120,
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _accountsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('Nessun conto registrato.'));
                }
                final accounts = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: accounts.length,
                  itemBuilder: (context, index) {
                    final acc = accounts[index];
                    return Container(
                      width: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                acc['name'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${acc['balance'].toStringAsFixed(2)} ${acc['currency']}',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: acc['balance'] >= 0
                                      ? Colors.green
                                      : Colors.red,
                                ),
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
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Ultime Transazioni',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _transactionsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('Nessuna transazione registrata.'),
                  );
                }
                final txs = snapshot.data!;
                return ListView.builder(
                  itemCount: txs.length,
                  itemBuilder: (context, index) {
                    final tx = txs[index];
                    double amount = tx['total_amount'];
                    bool isPositive = amount >= 0;
                    return ListTile(
                      leading: Icon(
                        isPositive ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      title: Text(
                        tx['description'].isEmpty
                            ? tx['category']
                            : tx['description'],
                      ),
                      subtitle: Text(
                        'Conto: ${tx['account_name'] ?? 'N/D'} • ${tx['date']}',
                      ),
                      trailing: Text(
                        '${isPositive ? '+' : ''}${amount.toStringAsFixed(2)} EUR',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FutureBuilder<List<Map<String, dynamic>>>(
        future: _accountsFuture,
        builder: (context, snapshot) {
          final accounts = snapshot.data ?? [];
          return FloatingActionButton(
            onPressed: () => _showAddTransactionDialog(accounts),
            child: const Icon(Icons.add),
            tooltip: 'Aggiungi Transazione',
          );
        },
      ),
    );
  }
}
