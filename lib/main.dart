import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'controllers/team_controller.dart';
import 'pages/pokemon_list_page.dart';
import 'pages/team_preview_page.dart';
import 'pages/getX.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GetStorage.init();
  Get.put(TeamController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Pokémon GO Team Builder',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const PokemonListPage(),
      getPages: [
        GetPage(name: '/preview', page: () => const TeamPreviewPage()),
        GetPage(name: '/about', page: () => const AboutPage()),
      ],
    );
  }
}
