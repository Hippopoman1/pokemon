import 'dart:async';
import 'package:pocketbase/pocketbase.dart';
import 'pb.dart';
import 'deposit.dart';

class DepositRepo {
  final _pb = PB.instance;

  Future<List<Deposit>> getAll() async {
    final rs = await _pb.collection('deposits').getFullList(sort: '-created');
    return rs.map(Deposit.fromRecord).toList();
  }

  Future<Deposit> create({
    required String name,
    required int age,
    required num amount,
  }) async {
    final r = await _pb.collection('deposits').create(body: {
      'name': name,
      'age': age,
      'amount': amount,
    });
    return Deposit.fromRecord(r);
  }

  Future<Deposit> update(
    Deposit d, {
    String? name,
    int? age,
    num? amount,
  }) async {
    final r = await _pb.collection('deposits').update(d.id, body: {
      'name': name ?? d.name,
      'age': age ?? d.age,
      'amount': amount ?? d.amount,
    });
    return Deposit.fromRecord(r);
  }

  Future<void> delete(String id) async {
    await _pb.collection('deposits').delete(id);
  }

  /// realtime: ถ้ามีการเปลี่ยนแปลง จะยิง event เพื่อให้ UI รีโหลด
  Stream<void> subscribe() {
    final c = StreamController<void>();
    _pb.collection('deposits').subscribe('*', (_) => c.add(null));
    c.onCancel = () => _pb.collection('deposits').unsubscribe('*');
    return c.stream;
  }
}
