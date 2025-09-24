import 'dart:io';
import 'dart:math';
import 'package:pocketbase/pocketbase.dart';

Future<void> main() async {
  final baseUrl = Platform.environment['PB_URL'] ?? 'http://127.0.0.1:8090';
  final adminEmail = Platform.environment['ADMIN_EMAIL'];
  final adminPass  = Platform.environment['ADMIN_PASSWORD'];

  final pb = PocketBase(baseUrl);

  // ถ้า Create rule ไม่ได้เปิดเป็น public ให้ใส่ ADMIN_EMAIL/ADMIN_PASSWORD เป็น env เพื่อ login admin
  if (adminEmail != null && adminPass != null) {
    await pb.admins.authWithPassword(adminEmail, adminPass);
  }

  final names = [
    'สมชาย ใจดี','สมหญิง พอเพียง','ประวิทย์ รุ่งเรือง','สุชาดา ศรีสวัสดิ์','ธีรเดช จงเจริญ',
    'วราภรณ์ พัฒนกิจ','กมลชัย ตั้งมั่น','ชลธิชา อินทร์สุข','ณัฐพงศ์ แสงดาว','ศิริพร วัฒนะกุล',
  ];

  final rnd = Random(42);
  for (final n in names) {
    final age = 18 + rnd.nextInt(47);                  // 18–64
    final amount = ((500 + rnd.nextInt(9500))          // 500–9999
                    + rnd.nextDouble())                // เติมทศนิยม
                    .toStringAsFixed(2);

    final rec = await pb.collection('deposits').create(body: {
      'name': n,
      'age': age,
      'amount': num.parse(amount),
    });
    print('> created: ${rec.id} | $n | age=$age | amount=$amount');
  }

  print('✅ done.');
}
