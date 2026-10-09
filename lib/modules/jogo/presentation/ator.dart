import 'package:bonfire/bonfire.dart';
import 'package:novel/modules/missao/domain/models/catalogo.dart';

class Ator extends SimpleNpc with WithCollision {
  Ator({
    required this.doc,
    required this.folha,
    required super.position,
  }) : super(
          size: Vector2.all(doc.tam),
          speed: doc.modo == 'fugir' ? 90 : 46,
          animation: SimpleDirectionAnimation(
            idleRight: folha.dir,
            runRight: folha.dir,
            idleLeft: folha.esq,
            runLeft: folha.esq,
            idleUp: folha.cim,
            idleDown: folha.bai,
            runUp: folha.cim,
            runDown: folha.bai,
          ),
        );

  final AtorDoc doc;
  final ({Future<SpriteAnimation> dir, Future<SpriteAnimation> esq, Future<SpriteAnimation> cim, Future<SpriteAnimation> bai}) folha;

  int golpesRestantes = 1;
  bool colocado = false;
  bool arrastando = false;
  bool fugiu = false;

  String get id => doc.id;

  @override
  Future<void> onLoad() async {
    golpesRestantes = doc.golpes;
    add(RectangleHitbox(size: size * 0.6, position: size * 0.2));
    if (doc.modo == 'fugir') fugiu = true;
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final jogador = gameRef.player;
    if (arrastando && jogador != null) {
      position = jogador.position + Vector2(18, 4);
      final buraco = doc.buraco;
      if (buraco != null && buraco.length >= 2) {
        final alvo = Vector2(buraco[0] * 16, buraco[1] * 16);
        if (position.distanceTo(alvo) < 28) {
          position = alvo;
          arrastando = false;
          colocado = true;
          stop();
        }
      }
      return;
    }
    if (doc.modo == 'seguirJogador' && jogador != null) {
      if (position.distanceTo(jogador.position) > 36) {
        moveToward(jogador.position);
      } else {
        stop();
      }
    }
    if (fugiu && doc.ateX != null) {
      final alvo = Vector2((doc.ateX ?? 0) * 16, (doc.ateY ?? 0) * 16);
      if (position.distanceTo(alvo) > 8) {
        moveToward(alvo);
      } else {
        stop();
        fugiu = false;
      }
    }
  }
}
