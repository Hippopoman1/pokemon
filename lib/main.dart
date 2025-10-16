// prettier, modernized UI for your PocketBase + Flutter deposits page
// Notes:
// 1) Add dependency in pubspec.yaml for currency/number formatting
//    dependencies:
//      intl: ^0.19.0
// 2) This file assumes you still have deposit.dart and deposit_repo.dart as before.
// 3) You can replace your current main.dart with this entire file.

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' show FontFeature;
import 'package:intl/intl.dart';
import 'deposit.dart';
import 'deposit_repo.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final seed = const Color(0xFF0BAE94); // teal-ish
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PocketBase Deposits',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: seed,
        brightness: Brightness.light,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
          focusedBorder: OutlineInputBorder(borderSide: BorderSide(width: 1.6)),
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        cardTheme: CardThemeData(
          elevation: 1,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      ),
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

  // cached formatter
  final _thMoney = NumberFormat.currency(locale: 'th_TH', symbol: '฿');

  // search/filter
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _future = _repo.getAll();
    _rtSub = _repo.subscribe().listen((_) {
      setState(() {
        _future = _repo.getAll();
      });
    });
    _searchCtrl.addListener(() {
      setState(() => _query = _searchCtrl.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _rtSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _future = _repo.getAll());
    await _future;
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _openForm({Deposit? editing}) async {
    final nameCtrl = TextEditingController(text: editing?.name ?? '');
    final ageCtrl = TextEditingController(text: editing?.age.toString() ?? '');
    final amtCtrl = TextEditingController(text: editing?.amount.toString() ?? '');
    final formKey = GlobalKey<FormState>();

    final result = await showModalBottomSheet<({String name, int age, num amount})>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final insets = MediaQuery.of(ctx).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: insets),
          child: Form(
            key: formKey,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    editing == null ? 'เพิ่มรายการฝากเงิน' : 'แก้ไขรายการฝากเงิน',
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'ชื่อ'),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อ' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: ageCtrl,
                    decoration: const InputDecoration(labelText: 'อายุ'),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final x = int.tryParse(v?.trim() ?? '');
                      if (x == null) return 'กรุณากรอกอายุเป็นตัวเลข';
                      if (x < 0 || x > 120) return 'อายุต้องอยู่ระหว่าง 0–120';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: amtCtrl,
                    decoration: const InputDecoration(labelText: 'จำนวนเงิน'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final x = num.tryParse(v?.trim() ?? '');
                      if (x == null) return 'กรุณากรอกจำนวนเงินให้ถูกต้อง';
                      if (x < 0) return 'จำนวนเงินต้องไม่ติดลบ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: Text(editing == null ? 'บันทึก' : 'อัปเดต'),
                    onPressed: () {
                      if (!formKey.currentState!.validate()) return;
                      final n = nameCtrl.text.trim();
                      final a = int.parse(ageCtrl.text.trim());
                      final m = num.parse(amtCtrl.text.trim());
                      Navigator.pop(ctx, (name: n, age: a, amount: m));
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    if (editing == null) {
      await _repo.create(name: result.name, age: result.age, amount: result.amount);
      _snack('เพิ่มรายการเรียบร้อย');
    } else {
      await _repo.update(editing, name: result.name, age: result.age, amount: result.amount);
      _snack('อัปเดตรายการเรียบร้อย');
    }
    _refresh();
  }

  Future<void> _confirmDelete(Deposit d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ยืนยันการลบ'),
        content: Text('ลบรายการของ "${d.name}" จำนวน ${_thMoney.format(d.amount)}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          FilledButton.icon(
            icon: const Icon(Icons.delete_forever_rounded),
            label: const Text('ลบ'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _repo.delete(d.id);
      _snack('ลบรายการเรียบร้อย');
      _refresh();
    }
  }

  Widget _summary(List<Deposit> items) {
    final total = items.fold<num>(0, (s, e) => s + e.amount);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.secondaryContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ยอดรวมทั้งหมด', style: Theme.of(context).textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text(_thMoney.format(total), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Chip(
              label: Text('รายการ ${items.length}'),
              avatar: const Icon(Icons.list_alt_rounded, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(Deposit d) {
    final initials = d.name.isNotEmpty
        ? d.name.trim().split(RegExp(r"\s+")).map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _openForm(editing: d),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                child: Text(initials, style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _thMoney.format(d.amount),
                          style: const TextStyle(fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.cake_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text('อายุ ${d.age} ปี'),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tag_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text('#${d.id.substring(0, 6)}'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'ตัวเลือก',
                onSelected: (v) {
                  if (v == 'edit') _openForm(editing: d);
                  if (v == 'del') _confirmDelete(d);
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'edit', child: ListTile(leading: Icon(Icons.edit_rounded), title: Text('แก้ไข'))),
                  const PopupMenuItem(value: 'del', child: ListTile(leading: Icon(Icons.delete_rounded), title: Text('ลบ'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายการออมเงิน'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'รีเฟรช',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('ฝาก'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cs.surface, cs.surfaceVariant.withOpacity(.4)],
          ),
        ),
        child: Column(
          children: [
            // Search & quick actions
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'ค้นหาตามชื่อ...',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refresh,
                child: FutureBuilder<List<Deposit>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snap.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 42),
                              const SizedBox(height: 12),
                              Text('เกิดข้อผิดพลาด: ${snap.error}'),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: _refresh,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('ลองอีกครั้ง'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    var items = snap.data ?? [];
                    if (_query.isNotEmpty) {
                      items = items.where((e) => e.name.toLowerCase().contains(_query)).toList();
                    }

                    if (items.isEmpty) {
                      return ListView(
                        children: const [
                          SizedBox(height: 80),
                          Icon(Icons.inbox_rounded, size: 48),
                          SizedBox(height: 12),
                          Center(child: Text('ยังไม่มีข้อมูล')),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(bottom: 96),
                      itemCount: items.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) return _summary(items);
                        final d = items[index - 1];
                        return _tile(d);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
