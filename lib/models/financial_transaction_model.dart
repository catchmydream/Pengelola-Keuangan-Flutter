class FinancialTransaction {
  final int? id; // ID transaksi, nullable karena akan di-generate oleh database
  final int userId; // ID user yang terkait dengan transaksi
  final String type; // Jenis transaksi: 'income' atau 'expense'
  final double amount; // Jumlah uang
  final String description; // Deskripsi transaksi
  final DateTime date; // Tanggal dan waktu transaksi

  FinancialTransaction({
    this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.description,
    required this.date,
  });

  // Konversi objek ke Map (untuk disimpan di database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type,
      'amount': amount,
      'description': description,
      'date': date.toIso8601String(), // Format ISO8601 menyimpan tanggal dan waktu lengkap
    };
  }

  // Factory method untuk membuat objek dari Map (diambil dari database)
  factory FinancialTransaction.fromMap(Map<String, dynamic> map) {
    return FinancialTransaction(
      id: map['id'],
      userId: map['userId'],
      type: map['type'],
      amount: map['amount'],
      description: map['description'],
      date: DateTime.parse(map['date']), // Parsing string ISO8601 ke DateTime
    );
  }
}
