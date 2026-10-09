import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel/modules/comum/presentation/paginas.dart';
import 'package:novel/modules/jogo/presentation/jogo_page.dart';
import 'package:novel/modules/traducao/presentation/app_traducoes.dart';

class NovelApp extends StatelessWidget {
  const NovelApp(this.traducoes, {super.key});

  final AppTraducoes traducoes;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Novel',
      debugShowCheckedModeBanner: false,
      translations: traducoes,
      locale: const Locale('pt', 'BR'),
      fallbackLocale: const Locale('pt', 'BR'),
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF1C1914),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFD7A35A), surface: Color(0xFF1C1914)),
      ),
      initialRoute: '/entrada',
      getPages: [
        GetPage(name: '/entrada', page: () => const EntradaPage()),
        GetPage(name: '/cadastro', page: () => const CadastroPage()),
        GetPage(name: '/banido', page: () => const BanidoPage()),
        GetPage(name: '/jogo', page: () => const JogoPage()),
        GetPage(name: '/mapa', page: () => const MapaPage()),
        GetPage(name: '/amigos', page: () => const AmigosPage()),
        GetPage(name: '/loja', page: () => const LojaPage()),
      ],
    );
  }
}
