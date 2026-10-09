import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:novel/app/novel_app.dart';
import 'package:novel/core/cache/cache_local.dart';
import 'package:novel/core/nucleo.dart';
import 'package:novel/core/plataforma.dart';
import 'package:novel/firebase_options.dart';
import 'package:novel/modules/auth/data/auth_repositorio.dart';
import 'package:novel/modules/auth/presentation/sessao_controller.dart';
import 'package:novel/modules/jogo/presentation/jogo_controller.dart';
import 'package:novel/modules/missao/data/missao_repositorio.dart';
import 'package:novel/modules/traducao/presentation/app_traducoes.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (controlesToque()) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
  if (DefaultFirebaseOptions.configurado) {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      Nucleo.firebase = true;
    } catch (_) {
      Nucleo.firebase = false;
    }
  }
  final cache = await CacheLocal.abrir();
  final catalogo = await CarregarCatalogoUsecase(MissaoRepositorio()).call();
  final auth = AuthRepositorio();
  final progresso = await cache.lerProgresso();
  Get.put(SessaoController(cache, EntrarGoogleUsecase(auth), ReservarNomeUsecase(auth)));
  Get.put(JogoController(catalogo, cache, progresso));
  final traducoes = AppTraducoes();
  await traducoes.carregar();
  runApp(NovelApp(traducoes));
}
