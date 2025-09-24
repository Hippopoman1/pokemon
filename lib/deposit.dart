import 'package:pocketbase/pocketbase.dart';

class Deposit {
  final String id;
  final String name;
  final int age;
  final num amount;

  Deposit({
    required this.id,
    required this.name,
    required this.age,
    required this.amount,
  });

  factory Deposit.fromRecord(RecordModel r) => Deposit(
        id: r.id,
        name: (r.data['name'] as String?) ?? '',
        age: ((r.data['age'] as num?) ?? 0).toInt(),
        amount: (r.data['amount'] as num?) ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'age': age,
        'amount': amount,
      };
}
