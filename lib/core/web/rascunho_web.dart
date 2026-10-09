import 'package:web/web.dart' as web;

const _chave = 'novel_rascunho';

Future<void> gravarRascunho(String json) async {
  web.window.localStorage.setItem(_chave, json);
}

Future<String?> lerRascunho() async => web.window.localStorage.getItem(_chave);
