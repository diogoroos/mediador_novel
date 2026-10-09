import 'package:bonfire/bonfire.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:novel/modules/jogo/domain/acao_travada.dart';
import 'package:novel/modules/jogo/presentation/diretor.dart';

class NovelPlayer extends SimplePlayer with WithCollision {
  NovelPlayer({required super.position, required SimpleDirectionAnimation animation})
      : super(size: Vector2.all(32), animation: animation, life: 100, speed: 80);

  Diretor? diretor;
  final acao = AcaoTravada();
  final pose = EspacoPose();
  bool deitado = false;
  bool ajoelhado = false;
  bool lento = false;
  bool naTenda = false;
  bool invulneravel = false;
  bool morteRoteiro = false;
  String rep = 'deitar';
  String cor = '';
  double mana = 20;
  double manaMax = 20;
  int danoArma = 0;
  int defesa = 0;
  bool _space = false;
  double _cooldown = 0;
  double _regen = 0;
  double _manaTempo = 0;

  @override
  Future<void> onLoad() async {
    add(RectangleHitbox(size: Vector2(16, 16), position: Vector2(8, 12)));
    life.onDieListener(() => diretor?.aoMorrer(roteiro: morteRoteiro));
    return super.onLoad();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final delta = Duration(microseconds: (dt * 1000000).round());
    final space = HardwareKeyboard.instance.logicalKeysPressed.contains(LogicalKeyboardKey.space);
    if (space && !_space) pose.down();
    if (!space && _space) {
      final curto = pose.up();
      if (curto) {
        acao.pointerDown(sobreObjetoPerto: diretor?.perto(this) ?? false);
        acao.pointerUp();
      }
    }
    _space = space;
    if (space) pose.tick(delta, topDown: true);
    if (pose.ativa) {
      deitado = rep == 'deitar';
      ajoelhado = rep == 'ajoelhar';
    }
    if ((deitado || ajoelhado) && isMoving) {
      pose.levantar();
      deitado = false;
      ajoelhado = false;
    }
    if (cor == 'pele') {
      paint.colorFilter = const ColorFilter.mode(Color(0xFFC4A574), BlendMode.modulate);
    } else if (cor.length == 6) {
      paint.colorFilter = ColorFilter.mode(Color(int.parse('FF$cor', radix: 16)), BlendMode.modulate);
    }
    angle = deitado ? -1.15 : 0;
    speed = lento ? 26 : 80;
    acao.tickSegurando(delta);
    _regenVida(dt);
    _regenMana(dt);
    _cooldown -= dt;
    final agindo = acao.modo == ModoAcao.ataque || acao.modo == ModoAcao.interagir || acao.modo == ModoAcao.poder;
    if (agindo && _cooldown <= 0 && (acao.continua || acao.disparoUnico || acao.modo == ModoAcao.poder)) {
      diretor?.aplicarAcao(this);
      if (acao.modo == ModoAcao.poder) {
        acao.encerrar();
      } else {
        acao.consumirDisparo();
      }
      _cooldown = 0.45;
    }
  }

  void _regenVida(double dt) {
    if (!(deitado || ajoelhado || naTenda)) return;
    _regen += dt;
    final espera = (deitado || ajoelhado) ? 5.0 : 10.0;
    if (_regen < espera) return;
    _regen = 0;
    life.add(life.max * 0.1);
    diretor?.vidaMudou();
  }

  void _regenMana(double dt) {
    _manaTempo += dt;
    final espera = (deitado || ajoelhado) ? 4.0 : 8.0;
    if (_manaTempo < espera) return;
    _manaTempo = 0;
    mana = (mana + manaMax * 0.1).clamp(0, manaMax);
    diretor?.vidaMudou();
  }

  void receberGolpe(double dano) {
    if (invulneravel) return;
    final liquido = (dano - defesa).clamp(1, 999).toDouble();
    life.remove(liquido);
    diretor?.vidaMudou();
  }
}
