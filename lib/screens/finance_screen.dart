import 'package:flutter/material.dart';

import '../services/finance_service.dart';

import '../services/recurring_service.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  late Future<List<Map<String, dynamic>>> _accountsFuture;
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 4, vsync: this);
    _refreshData();
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _accountsFuture = FinanceService.getAccounts();
      _transactionsFuture = FinanceService.getTransactions();
    });
  }

  // Dialog per aggiungere un conto
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
            DropdownButtonFormField<String>(
              value: currency,
              items: [
                'EUR',
                'JPY',
              ].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (val) => currency = val!,
              decoration: const InputDecoration(labelText: 'Valuta'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal ERP - Finanza'),
        bottom: TabBar(
          controller: _subTabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Conti'),
            Tab(text: 'Transazioni'),
            Tab(text: 'Giroconti'),
            Tab(text: 'Ricorrenti'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: _showAddAccountDialog,
            tooltip: 'Aggiungi Conto',
          ),
        ],
      ),
      body: FutureBuilder(
        future: Future.wait([_accountsFuture, _transactionsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final accounts = snapshot.data![0] as List<Map<String, dynamic>>;
          final transactions = snapshot.data![1] as List<Map<String, dynamic>>;

          return TabBarView(
            controller: _subTabController,
            children: [
              _buildAccountsTab(accounts),
              _buildTransactionsTab(accounts, transactions),
              _buildTransferTab(accounts),
              _buildRecurringTab(accounts),
            ],
          );
        },
      ),
    );
  }

  // --- TAB 1: CONTI ---
  Widget _buildAccountsTab(List<Map<String, dynamic>> accounts) {
    if (accounts.isEmpty) {
      return const Center(
        child: Text(
          'Nessun conto registrato. Clicca in alto a destra per aggiungerne uno.',
        ),
      );
    }
    return ListView.builder(
      itemCount: accounts.length,
      itemBuilder: (context, index) {
        final acc = accounts[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(
              acc['name'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Tipo: ${acc['type']}'),
            trailing: Text(
              '${acc['balance'].toStringAsFixed(2)} ${acc['currency']}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: acc['balance'] >= 0 ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }

  // --- TAB 2: TRANSAZIONI (Spesa / Entrata) ---
  Widget _buildTransactionsTab(
    List<Map<String, dynamic>> accounts,
    List<Map<String, dynamic>> transactions,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: ElevatedButton.icon(
            onPressed: () => _showAddTransactionDialog(accounts),
            icon: const Icon(Icons.add),
            label: const Text('Registra Spesa / Entrata'),
          ),
        ),
        const Divider(),
        Expanded(
          child: transactions.isEmpty
              ? const Center(child: Text('Nessuna transazione registrata.'))
              : ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final tx = transactions[index];
                    double amount = tx['total_amount'];
                    double fee = tx['fee'] ?? 0.0;
                    bool isPositive = amount >= 0;

                    String subtitle =
                        'Conto: ${tx['account_name'] ?? 'N/D'} • ${tx['date']}';
                    if (fee > 0)
                      subtitle += ' (Fee: ${fee.toStringAsFixed(2)})';

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
                      subtitle: Text(subtitle),
                      trailing: Text(
                        '${isPositive ? '+' : ''}${amount.toStringAsFixed(2)} ${tx['currency'] ?? 'EUR'}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPositive ? Colors.green : Colors.red,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // --- TAB 3: GIROCONTI ---
  Widget _buildTransferTab(List<Map<String, dynamic>> accounts) {
    if (accounts.length < 2) {
      return const Center(
        child: Text(
          'Hai bisogno di almeno 2 conti per effettuare un giroconto.',
        ),
      );
    }

    int fromAccId = accounts.first['id'];
    int toAccId = accounts[1]['id'];
    final amountController = TextEditingController();
    final feeController = TextEditingController(text: '0.0');
    final noteController = TextEditingController(text: 'Giroconto');

    return StatefulBuilder(
      builder: (context, setLocalState) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: fromAccId,
              items: accounts
                  .map(
                    (a) => DropdownMenuItem<int>(
                      value: a['id'],
                      child: Text('Da: ${a['name']}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setLocalState(() => fromAccId = val!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: toAccId,
              items: accounts
                  .map(
                    (a) => DropdownMenuItem<int>(
                      value: a['id'],
                      child: Text('A: ${a['name']}'),
                    ),
                  )
                  .toList(),
              onChanged: (val) => setLocalState(() => toAccId = val!),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Importo da trasferire',
              ),
            ),
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Commissione / Costo extra',
              ),
            ),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(labelText: 'Causale'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                double amount = double.tryParse(amountController.text) ?? 0.0;
                double fee = double.tryParse(feeController.text) ?? 0.0;
                if (amount > 0 && fromAccId != toAccId) {
                  await FinanceService.executeTransfer(
                    fromAccountId: fromAccId,
                    toAccountId: toAccId,
                    amount: amount,
                    fee: fee,
                    note: noteController.text.trim(),
                  );
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Giroconto eseguito!')),
                  );
                }
              },
              child: const Text('Esegui Giroconto'),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 4: SPESE & ENTRATE RICORRENTI ---
  Widget _buildRecurringTab(List<Map<String, dynamic>> accounts) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: RecurringService.getRecurringExpenses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final recurringList = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const Text(
              'Modelli Ricorrenti Attivi',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            recurringList.isEmpty
                ? const Text('Nessun modello ricorrente configurato.')
                : SizedBox(
                    height: 220,
                    child: ListView.builder(
                      itemCount: recurringList.length,
                      itemBuilder: (context, index) {
                        final rec = recurringList[index];
                        bool isSpesa = rec['op_type'] == 'Spesa';
                        return Card(
                          child: ListTile(
                            title: Text('${rec['name']} (${rec['op_type']})'),
                            subtitle: Text(
                              'Conto: ${rec['account_name'] ?? 'N/D'} • Categoria: ${rec['category']} • Frequenza: ${rec['frequency']}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${isSpesa ? '-' : '+'}${rec['amount'].toStringAsFixed(2)} ${rec['currency']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSpesa ? Colors.red : Colors.green,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.flash_on,
                                    color: Colors.orange,
                                  ),
                                  tooltip: 'Esegui questo mese',
                                  onPressed: () async {
                                    String dateStr = DateTime.now()
                                        .toIso8601String()
                                        .substring(0, 10);
                                    await RecurringService.executeRecurring(
                                      recurringId: rec['id'],
                                      name: rec['name'],
                                      accountId: rec['account_id'],
                                      amount: rec['amount'],
                                      currency: rec['currency'],
                                      category: rec['category'],
                                      opType: rec['op_type'],
                                      dateStr: dateStr,
                                    );
                                    _refreshData();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Eseguito modello '${rec['name']}'!",
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Elimina Modello',
                                  onPressed: () async {
                                    await RecurringService.deleteRecurringExpense(
                                      rec['id'],
                                    );
                                    setState(() {});
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
            const Divider(height: 32),
            const Text(
              'Crea Nuovo Modello Ricorrente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildAddRecurringForm(accounts),
          ],
        );
      },
    );
  }

  // Widget helper per il form di creazione modello ricorrente
  Widget _buildAddRecurringForm(List<Map<String, dynamic>> accounts) {
    if (accounts.isEmpty) {
      return const Text('Crea prima un conto per poter aggiungere un modello.');
    }

    final nameController = TextEditingController();
    final amountController = TextEditingController();
    String opType = 'Spesa';
    int selectedAccId = accounts.first['id'];
    String currency = accounts.first['currency'];
    String category = 'Bollette';
    String frequency = 'Mensile';
    String intervalValue = '1';

    return StatefulBuilder(
      builder: (context, setFormState) => Column(
        children: [
          TextField(
            controller: nameController,
            decoration: const InputDecoration(
              labelText: 'Nome Modello (es. Affitto, Stipendio)',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: opType,
                  items: ['Spesa', 'Entrata']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setFormState(() => opType = val!),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: selectedAccId,
                  items: accounts
                      .map(
                        (a) => DropdownMenuItem<int>(
                          value: a['id'],
                          child: Text(a['name']),
                        ),
                      )
                      .toList(),
                  onChanged: (val) => setFormState(() {
                    selectedAccId = val!;
                    currency = accounts.firstWhere(
                      (a) => a['id'] == val,
                    )['currency'];
                  }),
                  decoration: const InputDecoration(labelText: 'Conto'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Importo ($currency)'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: category,
                  items:
                      [
                            'Spesa',
                            'Mangiare/Bere fuori',
                            'Bollette',
                            'Trasporti',
                            'Abbonamenti',
                            'Sport',
                            'Telefonia/Internet',
                            'Viaggi',
                            'Investimenti',
                            'Trasferimento ad Altri',
                            'Giroconto',
                            'Regali',
                            'Altro',
                          ]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
                          .toList(),
                  onChanged: (val) => setFormState(() => category = val!),
                  decoration: const InputDecoration(labelText: 'Categoria'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              double amount = double.tryParse(amountController.text) ?? 0.0;
              if (nameController.text.isNotEmpty && amount > 0) {
                await RecurringService.addRecurringExpense(
                  name: nameController.text.trim(),
                  accountId: selectedAccId,
                  amount: amount,
                  currency: currency,
                  frequency: frequency,
                  intervalValue: intervalValue,
                  category: category,
                  opType: opType,
                );
                nameController.clear();
                amountController.clear();
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Modello ricorrente salvato!')),
                );
              }
            },
            child: const Text('➕ Salva Modello Ricorrente'),
          ),
        ],
      ),
    );
  }

  // Dialog per la singola transazione con supporto fee
  void _showAddTransactionDialog(List<Map<String, dynamic>> accounts) {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final feeController = TextEditingController(text: '0.0');
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
                        label: const Text('Spesa (-)'),
                        selected: isExpense,
                        selectedColor: Colors.red,
                        onSelected: (val) =>
                            setDialogState(() => isExpense = true),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ChoiceChip(
                        label: const Text('Entrata (+)'),
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
                  controller: feeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Commissione / Costo extra',
                  ),
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
                  items:
                      [
                            'Spesa',
                            'Mangiare/Bere fuori',
                            'Bollette',
                            'Trasporti',
                            'Abbonamenti',
                            'Sport',
                            'Telefonia/Internet',
                            'Viaggi',
                            'Investimenti',
                            'Trasferimento ad Altri',
                            'Giroconto',
                            'Regali',
                            'Altro',
                          ]
                          .map(
                            (c) => DropdownMenuItem(value: c, child: Text(c)),
                          )
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
                double fee = double.tryParse(feeController.text) ?? 0.0;
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
                    fee: fee,
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
}
