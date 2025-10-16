// Run with:  dart run tool/seed_deposits.dart --count=200 [--collection=deposits] [--truncate]
// Env vars required:
//   PB_URL            (e.g. http://127.0.0.1:8090)
//   ADMIN_EMAIL       (PocketBase admin email)
//   ADMIN_PASSWORD    (PocketBase admin password)
//
// Windows PowerShell example:
//   $env:PB_URL="http://127.0.0.1:8090"; $env:ADMIN_EMAIL="admin@your.com"; $env:ADMIN_PASSWORD="yourPassword"; \
//   dart run tool/seed_deposits.dart --count=150 --truncate
//
// macOS/Linux bash example:
//   PB_URL=http://127.0.0.1:8090 ADMIN_EMAIL=admin@your.com ADMIN_PASSWORD=yourPassword \
//   dart run tool/seed_deposits.dart --count=150 --truncate
//
// pubspec.yaml dependencies:
//   dependencies:
//     pocketbase: ^0.18.1   // or your current version
//     faker: ^2.1.0

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:faker/faker.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:dotenv/dotenv.dart' as dotenv;

Future<void> main(List<String> args) async {
  // Load .env automatically if present (falls back to platform env)
  final dot = dotenv.DotEnv(includePlatformEnvironment: true)
    ..load([".env", ".env.local", ".env.development", ".env.production"]);
  final pbUrl = _env('PB_URL', dot);
  final adminEmail = _env('ADMIN_EMAIL', dot);
  final adminPassword = _env('ADMIN_PASSWORD', dot);

  if (pbUrl == null || adminEmail == null || adminPassword == null) {
    _err('Missing env vars. Please set PB_URL, ADMIN_EMAIL, ADMIN_PASSWORD');
    exit(64); // usage
  }

  // defaults
  var count = 100;
  var collection = 'deposits';
  var truncate = false;

  for (final a in args) {
    if (a.startsWith('--count=')) {
      count = int.tryParse(a.substring('--count='.length)) ?? count;
    } else if (a.startsWith('--collection=')) {
      collection = a.substring('--collection='.length);
    } else if (a == '--truncate') {
      truncate = true;
    }
  }

  final pb = PocketBase(pbUrl);

  stdout.writeln('[AUTH] Admin login as $adminEmail');
  await pb.admins.authWithPassword(adminEmail, adminPassword);
  stdout.writeln('[AUTH] ok');

  // Optionally truncate existing data in collection
  if (truncate) {
    stdout.writeln('[TRUNCATE] $collection ...');
    // Delete all in batches
    int deleted = 0;
    while (true) {
      final page = await pb.collection(collection).getList(page: 1, perPage: 200);
      if (page.items.isEmpty) break;
      for (final r in page.items) {
        await pb.collection(collection).delete(r.id);
        deleted++;
      }
      stdout.writeln('  deleted so far: $deleted');
      await Future.delayed(const Duration(milliseconds: 50));
    }
    stdout.writeln('[TRUNCATE] done, deleted $deleted records');
  }

  final faker = Faker();
  final rand = Random();

  stdout.writeln('[SEED] collection=$collection, count=$count');
  var created = 0;

  for (var i = 0; i < count; i++) {
    final name = faker.person.name();
    // Age 18–75 (weighted a bit older)
    final age = 18 + rand.nextInt(58) + (rand.nextBool() ? rand.nextInt(10) : 0);

    // Amount between 100.00 and 10,000.00 with two decimals
    final raw = 100 + rand.nextDouble() * 9900;
    final amount = double.parse(raw.toStringAsFixed(2));

    try {
      await pb.collection(collection).create(body: {
        'name': name,
        'age': age,
        'amount': amount,
      });
      created++;
    } catch (e) {
      _err('[ERROR] create failed at i=$i : $e');
    }

    if ((i + 1) % 25 == 0) {
      stdout.writeln('  inserted: ${i + 1}/$count');
      // tiny throttle to be gentle
      await Future.delayed(const Duration(milliseconds: 80));
    }
  }

  stdout.writeln('[SEED] done, inserted $created / $count');
}

String? _env(String key, dotenv.DotEnv dot) {
  final v = dot[key] ?? Platform.environment[key];
  if (v == null || v.isEmpty) return null;
  return v;
}

Never _err(String msg) {
  stderr.writeln(msg);
  throw Exception(msg);
}
