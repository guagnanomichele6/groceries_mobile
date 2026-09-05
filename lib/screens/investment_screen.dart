import 'package:flutter/material.dart';

import '../services/investment_service.dart';

class InvestmentScreen extends StatefulWidget {
  const InvestmentScreen({super.key});

  @override
  State<InvestmentScreen> createState() => _InvestmentScreenState();
}

class _InvestmentScreenState extends State<InvestmentScreen> {
  late Future<List<Map<String, dynamic>>> _investmentsFuture;

  @override
  void initState() {
    super.initState();
    _refreshInvestments();
  }

  void _refreshInvestments() {
    setState(() {
      _investmentsFuture = InvestmentService.getInvestments();
    });
  }

  void _showAddInvestmentDialog() {
    final nameController = TextEditingController();
    final qtyController = TextEditingController(text: '1.0');
    final valController = TextEditingController(text: '0.0');
    String category = 'ETF';
    String accountName = 'Conto Principale';
    String currency = 'EUR';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aggiungi/Aggiorna Asset'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome Asset /Ticker',
                ),
              ),
              TextField(
                controller: qtyController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantità / Quote',
                ),
              ),
              TextField(
                controller: valController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valore Totale Attuale',
                ),
              ),
              DropdownButtonFormField<String>(
                value: category,
                items: ['ETF', 'Azioni', 'Crypto', 'Obbligazioni', 'Altro']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => category = val!,
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              TextField(
                controller: TextEditingController(text: accountName),
                decoration: const InputDecoration(
                  labelText: 'Conto/Deposito Associato',
                ),
                onChanged: (val) => accountName = val,
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
              if (nameController.text.isNotEmpty) {
                double qty = double.tryParse(qtyController.text) ?? 0.0;
                double val = double.tryParse(valController.text) ?? 0.0;
                await InvestmentService.saveInvestment(
                  assetName: nameController.text.trim(),
                  category: category,
                  accountName: accountName,
                  quantity: qty,
                  currentValue: val,
                  currency: currency,
                );
                Navigator.pop(context);
                _refreshInvestments();
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
        future: _investmentsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Nessun investimento registrato.'));
          }

          final investments = snapshot.data!;
          double totalPortfolioValue = investments.fold(
            0.0,
            (sum, item) => sum + (item['current_value'] as double),
          );

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Valore Totale Portafoglio:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${totalPortfolioValue.toStringAsFixed(2)} EUR',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: investments.length,
                  itemBuilder: (context, index) {
                    final inv = investments[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.trending_up,
                          color: Colors.green,
                        ),
                        title: Text(
                          inv['asset_name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Categoria: ${inv['category']} • Deposito: ${inv['account_name']} \nQuote: ${inv['quantity']}',
                        ),
                        isThreeLine: true,
                        trailing: Text(
                          '${inv['current_value'].toStringAsFixed(2)} ${inv['currency']}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddInvestmentDialog,
        child: const Icon(Icons.add),
        tooltip: 'Aggiungi Investimento',
      ),
    );
  }
}
