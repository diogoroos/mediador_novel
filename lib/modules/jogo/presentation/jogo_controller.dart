import 'dart:math';

import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:novel/core/cache/cache_local.dart';
import 'package:novel/core/plataforma.dart';
import 'package:novel/modules/chat/data/chat_repositorio.dart';
import 'package:novel/modules/jogo/domain/tenda.dart';
import 'package:novel/modules/jogo/presentation/ator.dart';
import 'package:novel/modules/jogo/presentation/diretor.dart';
import 'package:novel/modules/jogo/presentation/jogador.dart';
import 'package:novel/modules/jogo/presentation/montar_mapa.dart';
import 'package:novel/modules/missao/domain/aceite.dart';
import 'package:novel/modules/missao/domain/conquista.dart';
import 'package:novel/modules/missao/domain/models/catalogo.dart';

class JogoController extends GetxController implements OuvinteCena {
  JogoController(this.catalogo, this.cache, this.progresso);

  final Catalogo catalogo;
  final CacheLocal cache;
  Progresso progresso;
  final chat = PublicarMensagemUsecase(ChatRepositorio());
  final _rng = Random();

  WorldMap? mundo;
  NovelPlayer? jogador;
  Diretor? diretor;
  final extras = <GameComponent>[];
  String chave = 'inicio';
  bool carregando = true;
  List<String> slides = [];
  int slideI = 0;
  List<String> balao = [];
  int balaoI = -1;
  NoGuia? guia;
  String painel = '';
  String aviso = '';
  bool hadesPergunta = false;
  bool novoMundo = false;
  final chatCtrl = TextEditingController();
  final hadesCtrl = TextEditingController();

  String get locale => Get.locale?.toString() ?? 'pt_BR';
  Missao? get missao => progresso.hades ? catalogo.hades : catalogo.mis(progresso.cap, progresso.mis);
  bool get toque => controlesToque();

  Future<void> montar() async {
    carregando = true;
    slides = [];
    guia = null;
    update(['cena', 'hud']);
    final atual = missao;
    if (atual == null || atual.cen.isEmpty) {
      carregando = false;
      update(['cena']);
      return;
    }
    final cenario = atual.cen.first;
    await carregarImagem(cenario.tileset);
    final mapa = await montarMapa(cenario);
    final anim = await animacaoFolha(folhaJogador);
    final player = NovelPlayer(position: Vector2(4 * 16, 16 * 16), animation: anim)
      ..mana = progresso.mana
      ..manaMax = progresso.manaMax
      ..danoArma = progresso.danoArma
      ..defesa = progresso.defesa
      ..cor = progresso.cor
      ..invulneravel = progresso.hades;
    player.life.initial(progresso.vidaMax);
    player.life.update(progresso.vida);
    final direcao = Diretor(
      missao: atual,
      cenario: cenario,
      locale: locale,
      ouvinte: this,
      jogador: player,
      passagem: progresso.passo,
    );
    player.diretor = direcao;
    final atores = <GameComponent>[];
    for (final doc in atual.atores) {
      final folha = atual.spr[doc.spr] ?? atual.spr[doc.id];
      if (folha == null) continue;
      atores.add(
        Ator(
          doc: doc,
          folha: (
            dir: animacao(folha.dir, folha.quadros, folha.tam),
            esq: animacao(folha.esq, folha.quadros, folha.tam),
            cim: animacao(folha.cim, folha.quadros, folha.tam),
            bai: animacao(folha.bai, folha.quadros, folha.tam),
          ),
          position: Vector2(doc.x * 16, doc.y * 16),
        ),
      );
    }
    for (final item in catalogo.itens) {
      if (progresso.mochila.any((e) => e.id == item.id)) continue;
      if (_rng.nextInt(100) >= item.rar) continue;
      final folha = SpriteFolha(dir: item.spr, esq: item.spr, cim: item.spr, bai: item.spr);
      atores.add(
        Ator(
          doc: AtorDoc(id: item.id, spr: item.id, x: 12, y: 12, modo: 'recurso', tipRec: item.tip, golpes: 1),
          folha: (
            dir: animacao(folha.dir, 1, 32),
            esq: animacao(folha.esq, 1, 32),
            cim: animacao(folha.cim, 1, 32),
            bai: animacao(folha.bai, 1, 32),
          ),
          position: Vector2(12 * 16, 12 * 16),
        ),
      );
    }
    for (final item in progresso.mochila) {
      if (!itemAceito(atual, item)) continue;
      if (item.tip != 'sld' && item.tip != 'emp' && item.tip != 'ani') continue;
      const folha = 'spr/aldeao_dir.png';
      atores.add(
        Ator(
          doc: AtorDoc(id: item.id ?? item.tip!, spr: item.tip!, x: 5, y: 16, modo: 'seguirJogador'),
          folha: (
            dir: animacao(folha, 1, 32),
            esq: animacao('spr/aldeao_esq.png', 1, 32),
            cim: animacao('spr/aldeao_cim.png', 1, 32),
            bai: animacao('spr/aldeao_bai.png', 1, 32),
          ),
          position: Vector2(5 * 16, 16 * 16),
        ),
      );
    }
    mundo = mapa;
    jogador = player;
    diretor = direcao;
    extras
      ..clear()
      ..add(direcao)
      ..addAll(atores);
    chave = '${progresso.cap}_${progresso.mis}_${progresso.hades}_${progresso.passo}';
    carregando = false;
    update(['cena', 'hud']);
  }

  Future<void> gravar() => cache.gravarProgresso(progresso);

  @override
  void mostrarSlides(List<String> textos) {
    slides = textos.isEmpty ? const ['...'] : textos;
    slideI = 0;
    update(['hud']);
  }

  void proximoSlide() {
    if (slideI + 1 < slides.length) {
      slideI += 1;
      update(['hud']);
      return;
    }
    slides = [];
    diretor?.uiPronta();
    update(['hud']);
  }

  @override
  void mostrarBalao(List<String> textos) {
    balao = textos.isEmpty ? const ['...'] : textos;
    balaoI = 0;
    update(['hud']);
  }

  void proximoBalao() {
    if (balaoI + 1 < balao.length) {
      balaoI += 1;
      update(['hud']);
      return;
    }
    balaoI = -1;
    diretor?.uiPronta();
    update(['hud']);
  }

  void relerBalao() {
    if (balao.isEmpty) return;
    balaoI = 0;
    update(['hud']);
  }

  @override
  void mostrarGuia(NoGuia no) {
    if (progresso.guiaCalado == '${progresso.cap}/${progresso.mis}') return;
    guia = no;
    update(['hud']);
  }

  void escolherGuia(OpcaoGuia opcao) {
    if (opcao.efe == 'calar') {
      progresso.guiaCalado = '${progresso.cap}/${progresso.mis}';
      gravar();
      guia = null;
    }
    diretor?.guiaEscolheu(opcao);
    if (opcao.prox == null) guia = null;
    update(['hud']);
  }

  @override
  void irPara({String? cap, String? mis}) {
    if (cap != null) progresso.cap = cap;
    if (mis != null) progresso.mis = mis;
    if (cap == null && mis == null) {
      final prox = catalogo.proxima(progresso.cap, progresso.mis);
      if (prox == null) {
        novoMundo = true;
        update(['hud']);
        return;
      }
      progresso.cap = prox.$1;
      progresso.mis = prox.$2;
    }
    progresso.passo = 0;
    progresso.hades = false;
    progresso.guiaCalado = '';
    gravar();
    montar();
  }

  @override
  void hud() {
    progresso.passo = diretor?.passagem ?? progresso.passo;
    progresso.vida = jogador?.life.value ?? progresso.vida;
    progresso.mana = jogador?.mana ?? progresso.mana;
    update(['hud']);
  }

  @override
  void entrarHades() {
    progresso.hades = true;
    progresso.vida = progresso.vidaMax;
    gravar();
    montar();
  }

  @override
  void ganhouRecurso(String tip, int qtd) {
    final i = progresso.mochila.indexWhere((e) => e.id == tip);
    if (i >= 0) {
      progresso.mochila[i] = progresso.mochila[i].copia(qtd: progresso.mochila[i].qtd + qtd);
    } else {
      progresso.mochila.add(Espaco(id: tip, qtd: qtd, tip: tip));
    }
    final total = progresso.mochila.where((e) => e.tip == tip).fold<int>(0, (s, e) => s + e.qtd);
    final meta = diretor?.passoAtual?.qtd ?? 0;
    diretor?.recursoContou(tip, total, meta);
    gravar();
    update(['hud']);
  }

  @override
  void missaoCumprida() {
    final chaveC = chaveConquista(progresso.cap, progresso.mis);
    if (podeConceder(progresso.conquistas, progresso.cap, progresso.mis)) {
      progresso.conquistas.add(chaveC);
      final ouro = missao?.cqtMis['our'];
      if (ouro is num) progresso.our += ouro.toInt();
    }
    final prox = catalogo.proxima(progresso.cap, progresso.mis);
    if (prox == null) {
      novoMundo = true;
      gravar();
      update(['hud']);
      return;
    }
    progresso.cap = prox.$1;
    progresso.mis = prox.$2;
    progresso.passo = 0;
    progresso.guiaCalado = '';
    gravar();
    montar();
  }

  void responderHades() {
    final esperado = (catalogo.hades?.tr(locale, 'resp') ?? 'jesus').toLowerCase();
    final dito = hadesCtrl.text.trim().toLowerCase();
    if (dito == esperado) {
      progresso.hades = false;
      novoMundo = true;
      gravar();
      update(['hud']);
      return;
    }
    progresso
      ..hades = false
      ..cap = 'cap01'
      ..mis = 'mis01'
      ..passo = 0
      ..our = 0
      ..vida = 100
      ..vidaMax = 100
      ..danoArma = 0
      ..defesa = 0
      ..cor = ''
      ..conquistas.clear();
    progresso.mochila.clear();
    for (var i = 0; i < progresso.tenda.espacos.length; i++) {
      progresso.tenda.espacos[i] = const Espaco();
    }
    aviso = 'hades_errado'.tr;
    gravar();
    montar();
  }

  void abrirPainel(String nome) {
    painel = painel == nome ? '' : nome;
    update(['hud']);
  }

  void dividirTenda(int indice) {
    progresso.tenda.dividir(indice);
    gravar();
    update(['hud']);
  }

  void retirarTenda(int indice) {
    final item = progresso.tenda.retirar(indice);
    if (item == null) return;
    progresso.mochila.add(item);
    gravar();
    update(['hud']);
  }

  void guardarNaTenda(int indice) {
    if (indice < 0 || indice >= progresso.mochila.length) return;
    final item = progresso.mochila[indice];
    if (!progresso.tenda.guardar(item)) return;
    progresso.mochila.removeAt(indice);
    gravar();
    update(['hud']);
  }

  Future<void> enviarChat() async {
    final texto = chatCtrl.text.trim();
    if (texto.isEmpty) return;
    final pais = catalogo.paises[progresso.pais];
    final ok = await chat(
      texto: texto,
      nome: progresso.nome,
      uid: progresso.nome,
      capMis: '${progresso.cap}_${progresso.mis}',
      palavras: pais?.blw ?? const [],
      paraNome: texto.startsWith('/') ? texto.split(' ').first.replaceFirst('/', '') : null,
    );
    aviso = ok ? '' : 'nao_enviada'.tr;
    if (ok) chatCtrl.clear();
    update(['hud']);
  }

  void clique(Vector2 mundo, {bool poder = false}) => diretor?.clique(mundo, poder: poder);

  void soltar() => diretor?.soltar();
}
