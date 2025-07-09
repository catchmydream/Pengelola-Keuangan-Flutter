import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Tambahkan ini
import 'package:intl/intl.dart';
import '../database/database_helper.dart';
import '../models/financial_transaction_model.dart';

class HomeScreen extends StatefulWidget {
  final int userId;

  HomeScreen({required this.userId});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _transactionType = 'income';
  List<FinancialTransaction> _transactions = [];
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;
  double _totalBalance = 0.0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadTransactions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatCurrency(double amount) {
    final formatter = NumberFormat.simpleCurrency(locale: 'id_ID');
    return formatter.format(amount);
  }

  String _formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd HH:mm').format(date);
  }

  void _loadTransactions() async {
    final transactions = await _dbHelper.getTransactions(widget.userId);
    double income = 0.0;
    double expense = 0.0;
    double balance = 0.0;

    // Menghitung total pemasukan, pengeluaran, dan saldo
    for (var transaction in transactions) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else if (transaction.type == 'expense') {
        expense += transaction.amount;
      }
    }

    balance = income - expense;

    setState(() {
      // Mengurutkan transaksi berdasarkan tanggal, yang terbaru di atas
      _transactions = transactions..sort((a, b) => b.date.compareTo(a.date));
      _totalIncome = income;
      _totalExpense = expense;
      _totalBalance = balance;
    });
  }

  void _addTransaction() async {
    final amount = double.tryParse(_amountController.text);
    final description = _descriptionController.text.trim();

    if (amount == null || amount <= 0 || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill out all fields with valid values')),
      );
      return;
    }

    final transaction = FinancialTransaction(
      userId: widget.userId,
      type: _transactionType,
      amount: amount,
      description: description,
      date: DateTime.now(),
    );

    await _dbHelper.insertTransaction(transaction);

    _amountController.clear();
    _descriptionController.clear();
    _loadTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction added successfully')),
    );
  }

  void _editTransaction(FinancialTransaction transaction) {
    _amountController.text = transaction.amount.toString();
    _descriptionController.text = transaction.description;
    String currentType = transaction.type;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Transaksi'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                value: currentType,
                onChanged: (value) {
                  setState(() {
                    currentType = value!;
                  });
                },
                items: [
                  DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                  DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                ],
              ),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(labelText: 'Jumlah'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: _descriptionController,
                decoration: InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(_amountController.text);
                final description = _descriptionController.text.trim();

                if (amount != null && description.isNotEmpty) {
                  final updatedTransaction = FinancialTransaction(
                    id: transaction.id,
                    userId: transaction.userId,
                    type: currentType,
                    amount: amount,
                    description: description,
                    date: DateTime.now(),
                  );

                  await _dbHelper.updateTransaction(updatedTransaction);
                  _loadTransactions();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Transaksi berhasil diperbarui')),
                  );
                }
              },
              child: Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _deleteTransaction(int transactionId) async {
    await _dbHelper.deleteTransaction(transactionId);
    _loadTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Transaction deleted successfully')),
    );
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _clearAllTransactions() async {
    await _dbHelper.clearTransactions(widget.userId);
    _loadTransactions();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data has been reset. All transactions cleared.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incomeTransactions =
        _transactions.where((transaction) => transaction.type == 'income').toList();
    final expenseTransactions =
        _transactions.where((transaction) => transaction.type == 'expense').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                DropdownButton<String>(
                  value: _transactionType,
                  onChanged: (value) {
                    setState(() {
                      _transactionType = value!;
                    });
                  },
                  items: [
                    DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                    DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                  ],
                ),
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(labelText: 'Jumlah'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Hanya angka
                  ],
                ),
                TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(labelText: 'Deskripsi'),
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _addTransaction,
                  child: Text('Tambah Transaksi'),
                ),
                SizedBox(height: 20.0),
                Column(
                  children: [
                    Text('Jumlah Uang', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      _formatCurrency(_totalBalance),
                      style: TextStyle(
                        fontSize: 24,
                        color: _totalBalance < 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Column(
                      children: [
                        Text('Total Pemasukan', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _formatCurrency(_totalIncome),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 30),
                    Column(
                      children: [
                        Text('Total Pengeluaran', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          _formatCurrency(_totalExpense),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.0),
                ElevatedButton(
                  onPressed: _clearAllTransactions,
                  child: Text('Tutup Buku'),
                ),
              ],
            ),
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(icon: Icon(Icons.arrow_upward), text: 'Pemasukan'),
              Tab(icon: Icon(Icons.arrow_downward), text: 'Pengeluaran'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                ListView.builder(
                  itemCount: incomeTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = incomeTransactions[index];
                    return ListTile(
                      title: Text('Pemasukan: ${transaction.description}'),
                      subtitle: Text(
                        'Jumlah: ${_formatCurrency(transaction.amount)}\n'
                        'Waktu: ${_formatDateTime(transaction.date)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editTransaction(transaction),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTransaction(transaction.id!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                ListView.builder(
                  itemCount: expenseTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = expenseTransactions[index];
                    return ListTile(
                      title: Text('Pengeluaran: ${transaction.description}'),
                      subtitle: Text(
                        'Jumlah: ${_formatCurrency(transaction.amount)}\n'
                        'Waktu: ${_formatDateTime(transaction.date)}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _editTransaction(transaction),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTransaction(transaction.id!),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
