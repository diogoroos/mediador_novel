import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel/core/cache/cache_local.dart';
import 'package:novel/core/nucleo.dart';
import 'package:novel/core/web/rascunho.dart';
import 'package:novel/modules/auth/data/auth_repositorio.dart';

class SessaoController extends GetxController {
  SessaoController(this.cache, this.entrarGoogle, this.reservarNome);

  final CacheLocal cache;
  final EntrarGoogleUsecase entrarGoogle;
  final ReservarNomeUsecase reservarNome;
  final nomeCtrl = TextEditingController();
  final paisCtrl = TextEditingController(text: 'BR');
  DateTime nascimento = DateTime(2000, 1, 1);
  String aviso = '';
  String? uid;
  bool ocupado = false;

  Future<void> iniciar() async {
    final progresso = await cache.lerProgresso();
    final rascunho = await lerRascunho();
    if (rascunho != null && progresso.nome.isEmpty) {
      nomeCtrl.text = rascunho;
    }
    if (progresso.banido) {
      Get.offAllNamed('/banido');
      return;
    }
    if (progresso.nome.isNotEmpty) {
      Get.offAllNamed('/jogo');
    }
  }

  Future<void> google() async {
    ocupado = true;
    update();
    final user = await entrarGoogle();
    ocupado = false;
    if (user == null) {
      aviso = 'firebase_ausente'.tr;
      update();
      return;
    }
    uid = user.uid;
    final ban = await AuthRepositorio().banido(user.uid);
    if (ban) {
      final progresso = await cache.lerProgresso();
      progresso.banido = true;
      await cache.gravarProgresso(progresso);
      Get.offAllNamed('/banido');
      return;
    }
    Get.offAllNamed('/cadastro');
  }

  Future<void> aparelho() async {
    uid = 'local';
    Nucleo.firebase = Nucleo.firebase;
    Get.offAllNamed('/cadastro');
  }

  Future<void> gravarRascunhoNome(String nome) => gravarRascunho(nome);

  Future<void> confirmar() async {
    final nome = nomeCtrl.text.trim().toLowerCase();
    if (nome.length < 3) return;
    final progresso = await cache.lerProgresso();
    progresso.nome = nome;
    progresso.nascimento = '${nascimento.year}-${nascimento.month}-${nascimento.day}';
    progresso.pais = paisCtrl.text.trim().isEmpty ? 'BR' : paisCtrl.text.trim().toUpperCase();
    if (Nucleo.firebase && uid != null && uid != 'local') {
      try {
        await reservarNome(uid: uid!, nome: nome, nascimento: progresso.nascimento, pais: progresso.pais);
      } on NomeOcupado {
        aviso = 'nome_ocupado'.tr;
        update();
        return;
      }
    }
    await cache.gravarProgresso(progresso);
    Get.offAllNamed('/jogo');
  }
}
