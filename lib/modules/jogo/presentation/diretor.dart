import 'package:bonfire/bonfire.dart';
import 'package:novel/modules/jogo/domain/acao_travada.dart';
import 'package:novel/modules/jogo/presentation/ator.dart';
import 'package:novel/modules/jogo/presentation/jogador.dart';
import 'package:novel/modules/jogo/presentation/montar_mapa.dart';
import 'package:novel/modules/missao/domain/models/catalogo.dart';

abstract class OuvinteCena {
  void mostrarSlides(List<String> textos);
  void mostrarBalao(List<String> textos);
  void mostrarGuia(NoGuia no);
  void irPara({String? cap, String? mis});
  void hud();
  void entrarHades();
  void ganhouRecurso(String tip, int qtd);
  void missaoCumprida();
}

class Diretor extends GameComponent {
  Diretor({
    required this.missao,
    required this.cenario,
    required this.locale,
    required this.ouvinte,
    required this.jogador,
    required this.passagem,
    this.portaAbertaInicial = false,
  });

  final Missao missao;
  final Cenario cenario;
  final String locale;
  final OuvinteCena ouvinte;
  final NovelPlayer jogador;
  int passagem;
  bool portaAbertaInicial;
  bool portaAberta = false;
  bool esperaUi = false;
  double tempo = 0;
  bool guiaAberto = false;
  bool cumprida = false;

  @override
  Future<void> onLoad() async {
    portaAberta = portaAbertaInicial || cenario.bor != 'portal';
    jogador.diretor = this;
    jogador.rep = cenario.rep;
    await super.onLoad();
  }

  Ator? ator(String? id) {
    if (id == null) return null;
    for (final item in gameRef.query<Ator>()) {
      if (item.id == id) return item;
    }
    return null;
  }

  bool perto(NovelPlayer player) {
    for (final item in gameRef.query<Ator>()) {
      if (item.position.distanceTo(player.position) < 42) return true;
    }
    return false;
  }

  Ator? sobPonto(Vector2 mundo, NovelPlayer player) {
    Ator? melhor;
    var menor = 42.0;
    for (final item in gameRef.query<Ator>()) {
      final centro = item.position + item.size / 2;
      final distMouse = centro.distanceTo(mundo);
      final distPlayer = item.position.distanceTo(player.position);
      if (distMouse < 24 && distPlayer < menor) {
        menor = distPlayer;
        melhor = item;
      }
    }
    return melhor;
  }

  void aplicarAcao(NovelPlayer player) {
    final modo = player.acao.modo;
    if (modo == ModoAcao.poder) {
      if (!missao.podMis || player.mana < 5) return;
      player.mana -= 5;
      _ferirProximo(player, player.danoArma + 4);
      ouvinte.hud();
      return;
    }
    final alvo = _maisPerto(player);
    if (modo == ModoAcao.interagir && alvo != null) {
      if (alvo.doc.modo == 'arrastar' && !alvo.colocado) {
        alvo.arrastando = true;
        return;
      }
      if (alvo.doc.modo == 'recurso') {
        alvo.golpesRestantes -= 1;
        ouvinte.ganhouRecurso(alvo.doc.tipRec ?? 'mad', 1);
        if (alvo.golpesRestantes <= 0) alvo.removeFromParent();
        if (!player.acao.continua) return;
        if (alvo.golpesRestantes <= 0) player.acao.encerrar();
        return;
      }
    }
    if (modo == ModoAcao.ataque) {
      if (alvo == null) return;
      final pedra = ator('pedra');
      final naPedra = pedra != null && alvo.position.distanceTo(pedra.position) < 36;
      final umGolpe = passoAtual?.tip == 'golpe' && naPedra;
      if (umGolpe) {
        alvo.golpesRestantes = 0;
      } else {
        alvo.golpesRestantes -= 1 + player.danoArma;
      }
      if (alvo.golpesRestantes <= 0) {
        alvo.removeFromParent();
        if (player.acao.continua) player.acao.encerrar();
      }
    }
  }

  void clique(Vector2 mundo, {bool poder = false}) {
    final sobre = sobPonto(mundo, jogador);
    jogador.acao.pointerDown(sobreObjetoPerto: sobre != null, poder: poder);
    if (sobre != null && sobre.doc.modo == 'arrastar') sobre.arrastando = true;
  }

  void soltar() => jogador.acao.pointerUp();

  Passo? get passoAtual {
    if (passagem < 0 || passagem >= missao.pas.length) return null;
    return missao.pas[passagem];
  }

  void uiPronta() {
    if (!esperaUi) return;
    esperaUi = false;
    _avancar();
  }

  void guiaEscolheu(OpcaoGuia opcao) {
    if (opcao.efe == 'calar') {
      guiaAberto = true;
      ator(missao.guia?.npc)?.removeFromParent();
      ouvinte.hud();
      return;
    }
    if (opcao.efe == 'missao' && opcao.mis != null) {
      ouvinte.irPara(mis: opcao.mis);
      return;
    }
    final prox = opcao.prox;
    final no = prox == null ? null : missao.guia?.nos[prox];
    if (no != null) ouvinte.mostrarGuia(no);
  }

  @override
  void update(double dt) {
    super.update(dt);
    final player = gameRef.player;
    if (player is NovelPlayer) {
      final tenda = ator('tenda');
      player.naTenda = tenda != null && player.position.distanceTo(tenda.position) < 80;
    }
    _guia();
    final passo = passoAtual;
    if (passo == null || esperaUi || cumprida) return;
    switch (passo.tip) {
      case 'sld':
        esperaUi = true;
        ouvinte.mostrarSlides(missao.lista(locale, 'sld'));
      case 'seguir':
        final npc = ator(passo.npc);
        if (npc == null || player == null) return;
        final perto = npc.position.distanceTo(player.position) < 96;
        if (perto && player.isMoving) {
          npc.moveToward(Vector2(passo.ateX * 16, npc.position.y));
        } else {
          npc.stop();
        }
        if (npc.position.x >= (passo.ateX - 1) * 16) _avancar();
      case 'abrirPorta':
        portaAberta = true;
        _avancar();
      case 'entrar':
      case 'sair':
        if (portaAberta && player != null && player.position.x > (cenario.grd.first.length - 3) * 16) {
          esperaUi = true;
          if (passo.tip == 'entrar' && passo.mis != null) {
            ouvinte.irPara(mis: passo.mis);
          } else {
            ouvinte.irPara();
          }
        }
      case 'arrastar':
        final prontas = gameRef.query<Ator>().where((a) => a.colocado).length;
        if (prontas >= passo.qtd) _avancar();
      case 'avancar':
        esperaUi = true;
        ouvinte.irPara(mis: passo.mis);
      case 'deitar':
        if (player is NovelPlayer && player.deitado) _avancar();
      case 'surgir':
        _surgir(passo);
        _avancar();
      case 'esperar':
        tempo += dt;
        if (tempo >= passo.seg) {
          tempo = 0;
          _avancar();
        }
      case 'ir':
        final npc = ator(passo.npc);
        if (npc == null) return;
        final alvo = Vector2(passo.x * 16, passo.y * 16);
        if (npc.position.distanceTo(alvo) > 12) {
          npc.moveToward(alvo);
        } else {
          npc.stop();
          _avancar();
        }
      case 'aproximar':
        final npc = ator(passo.npc);
        if (npc != null && player != null && npc.position.distanceTo(player.position) < 40) {
          _avancar();
        }
      case 'roupa':
        if (player is NovelPlayer) player.cor = 'C4A574';
        _avancar();
      case 'levar':
        final npc = ator(passo.npc);
        if (npc != null && npc.position.distanceTo(Vector2(passo.x * 16, passo.y * 16)) < 28) {
          _avancar();
        }
      case 'golpe':
        if (ator(passo.npc) == null) _avancar();
      case 'lentidao':
        if (player is NovelPlayer) player.lento = true;
        _avancar();
      case 'golpeNoUsuario':
        final npc = ator(passo.npc);
        if (npc == null || player is! NovelPlayer) return;
        if (npc.position.distanceTo(player.position) > 28) {
          npc.moveToward(player.position);
        } else {
          npc.stop();
          player.morteRoteiro = true;
          player.receberGolpe(999);
        }
      case 'capitulo':
        esperaUi = true;
        ouvinte.irPara(cap: passo.cap, mis: passo.mis);
      case 'afastar':
        final ref = ator(passo.de);
        if (ref != null && player != null && player.position.distanceTo(ref.position) > passo.dist) {
          _avancar();
        }
      case 'voltar':
        final ref = ator(passo.ate);
        if (ref != null && player != null && player.position.distanceTo(ref.position) < passo.dist) {
          _avancar();
        }
      case 'balao':
        esperaUi = true;
        ouvinte.mostrarBalao(missao.lista(locale, 'bal'));
      case 'coletar':
        break;
    }
  }

  void recursoContou(String tip, int total, int meta) {
    if (passoAtual?.tip == 'coletar' && passoAtual?.rec == tip && total >= meta) {
      _avancar();
    }
  }

  void aoMorrer({required bool roteiro}) {
    if (roteiro) {
      _avancar();
      return;
    }
    ouvinte.entrarHades();
  }

  void vidaMudou() => ouvinte.hud();

  void _avancar() {
    if (cumprida) return;
    passagem += 1;
    tempo = 0;
    ouvinte.hud();
    if (passagem >= missao.pas.length) {
      cumprida = true;
      ouvinte.missaoCumprida();
    }
  }

  Future<void> _surgir(Passo passo) async {
    if (ator(passo.npc) != null) return;
    final folha = missao.spr[passo.npc];
    if (folha == null || passo.npc == null) return;
    gameRef.add(
      Ator(
        doc: AtorDoc(id: passo.npc!, spr: passo.npc!, x: passo.x, y: passo.y, modo: 'parado'),
        folha: (
          dir: animacao(folha.dir, folha.quadros, folha.tam),
          esq: animacao(folha.esq, folha.quadros, folha.tam),
          cim: animacao(folha.cim, folha.quadros, folha.tam),
          bai: animacao(folha.bai, folha.quadros, folha.tam),
        ),
        position: Vector2(passo.x * 16, passo.y * 16),
      ),
    );
  }

  void _guia() {
    final guia = missao.guia;
    if (guia == null || guiaAberto || esperaUi) return;
    final player = gameRef.player;
    if (player == null) return;
    if (player.position.distanceTo(Vector2(20 * 16, 8 * 16)) > guia.raio) return;
    guiaAberto = true;
    final no = guia.nos['ini'];
    if (no != null) ouvinte.mostrarGuia(no);
  }

  Ator? _maisPerto(NovelPlayer player) {
    Ator? melhor;
    var menor = 48.0;
    for (final item in gameRef.query<Ator>()) {
      final dist = item.position.distanceTo(player.position);
      if (dist < menor) {
        menor = dist;
        melhor = item;
      }
    }
    return melhor;
  }

  void _ferirProximo(NovelPlayer player, int dano) {
    final alvo = _maisPerto(player);
    if (alvo == null) return;
    alvo.golpesRestantes -= dano;
    if (alvo.golpesRestantes <= 0) alvo.removeFromParent();
  }
}
