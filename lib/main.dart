import 'dart:async';
import 'package:flutter/material.dart';
import 'deposit.dart';
import 'deposit_repo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PocketBase Deposits',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
      home: const DepositPage(),
    );
  }
}

class DepositPage extends StatefulWidget {
  const DepositPage({super.key});
  @override
  State<DepositPage> createState() => _DepositPageState();
}

class _DepositPageState extends State<DepositPage> {
  final _repo = DepositRepo();

  late Future<List<Deposit>> _future;
  StreamSubscription<void>? _rtSub;

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _future = _repo.getAll();
    _rtSub = _repo.subscribe().listen((_) {
      setState(() {
        _future = _repo.getAll();
      });
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _amountCtrl.dispose();
    _rtSub?.cancel();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameCtrl.text.trim();
    final age = int.tryParse(_ageCtrl.text.trim());
    final amount = num.tryParse(_amountCtrl.text.trim());

    if (name.isEmpty || age == null || amount == null) {
      _snack('กรอกข้อมูลให้ครบ/ถูกต้อง');
      return;
    }
    if (age < 0 || age > 120) {
      _snack('อายุต้องอยู่ระหว่าง 0–120');
      return;
    }
    if (amount < 0) {
      _snack('จำนวนเงินต้องไม่ติดลบ');
      return;
    }

    await _repo.create(name: name, age: age, amount: amount);
    _nameCtrl.clear();
    _ageCtrl.clear();
    _amountCtrl.clear();

    setState(() => _future = _repo.getAll());
  }

  Future<void> _edit(Deposit d) async {
    final nameCtrl = TextEditingController(text: d.name);
    final ageCtrl = TextEditingController(text: d.age.toString());
    final amtCtrl = TextEditingController(text: d.amount.toString());

    final updated = await showDialog<({String name, int age, num amount})>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('แก้ไขข้อมูลฝากเงิน'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'ชื่อ')),
            TextField(
              controller: ageCtrl,
              decoration: const InputDecoration(labelText: 'อายุ'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ยกเลิก')),
          FilledButton(
            onPressed: () {
              final n = nameCtrl.text.trim();
              final a = int.tryParse(ageCtrl.text.trim());
              final m = num.tryParse(amtCtrl.text.trim());
              if (n.isEmpty || a == null || m == null || a < 0 || a > 120 || m < 0) {
                _snack('ข้อมูลไม่ถูกต้อง');
                return;
              }
              Navigator.pop(ctx, (name: n, age: a, amount: m));
            },
            child: const Text('บันทึก'),
          ),
        ],
      ),
    );

    if (updated == null) return;
    await _repo.update(d, name: updated.name, age: updated.age, amount: updated.amount);
    setState(() => _future = _repo.getAll());
  }

  Future<void> _delete(Deposit d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ลบรายการของ "${d.name}" จำนวน ${d.amount}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(d.id);
    setState(() => _future = _repo.getAll());
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ฝากเงิน (PocketBase + Flutter)')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'ชื่อ', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _ageCtrl,
                    decoration: const InputDecoration(labelText: 'อายุ', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _amountCtrl,
                    decoration: const InputDecoration(labelText: 'จำนวนเงิน', border: OutlineInputBorder()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onSubmitted: (_) => _create(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: _create, child: const Text('ฝาก')),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Deposit>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('เกิดข้อผิดพลาด: ${snap.error}'));
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(child: Text('ยังไม่มีข้อมูล'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = items[i];
                    return ListTile(
                      title: Text('${d.name} • อายุ ${d.age} ปี'),
                      subtitle: Text('จำนวนเงิน: ${d.amount}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit), onPressed: () => _edit(d)),
                          IconButton(icon: const Icon(Icons.delete), onPressed: () => _delete(d)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
