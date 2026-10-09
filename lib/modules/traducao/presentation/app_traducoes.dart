import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

class AppTraducoes extends Translations {
  final Map<String, Map<String, String>> _chaves = {};

  @override
  Map<String, Map<String, String>> get keys => _chaves;

  Future<void> carregar() async {
    await _arquivo('pt_BR', 'assets/idi/pt_BR.json');
    await _arquivo('en_US', 'assets/idi/en_US.json');
  }

  Future<void> _arquivo(String locale, String caminho) async {
    final bruto = await rootBundle.loadString(caminho);
    final map = jsonDecode(bruto) as Map<String, dynamic>;
    _chaves[locale] = map.map((k, v) => MapEntry(k, v.toString()));
  }
}
