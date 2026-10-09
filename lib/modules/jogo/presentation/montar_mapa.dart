import 'dart:ui' as ui;

import 'package:bonfire/bonfire.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:novel/core/nucleo.dart';
import 'package:novel/modules/missao/domain/models/catalogo.dart';

Future<ui.Image> carregarImagem(String caminho) async {
  if (Flame.images.containsKey(caminho)) {
    return Flame.images.fromCache(caminho);
  }
  if (caminho.startsWith('gs://') && Nucleo.firebase) {
    final bytes = await FirebaseStorage.instance.refFromURL(caminho).getData(8 * 1024 * 1024);
    if (bytes == null) throw StateError('sprite vazio: $caminho');
    final codec = await ui.instantiateImageCodec(bytes);
    final quadro = await codec.getNextFrame();
    Flame.images.add(caminho, quadro.image);
    return quadro.image;
  }
  return Flame.images.load(caminho);
}

Future<SpriteAnimation> animacao(String caminho, int quadros, double tam) async {
  final imagem = await carregarImagem(caminho);
  return SpriteAnimation.fromFrameData(
    imagem,
    SpriteAnimationData.sequenced(
      amount: quadros,
      stepTime: 0.12,
      textureSize: Vector2.all(tam),
    ),
  );
}

Future<SimpleDirectionAnimation> animacaoFolha(SpriteFolha folha) async {
  return SimpleDirectionAnimation(
    idleRight: animacao(folha.dir, folha.quadros, folha.tam),
    runRight: animacao(folha.dir, folha.quadros, folha.tam),
    idleLeft: animacao(folha.esq, folha.quadros, folha.tam),
    runLeft: animacao(folha.esq, folha.quadros, folha.tam),
    idleUp: animacao(folha.cim, folha.quadros, folha.tam),
    idleDown: animacao(folha.bai, folha.quadros, folha.tam),
    runUp: animacao(folha.cim, folha.quadros, folha.tam),
    runDown: animacao(folha.bai, folha.quadros, folha.tam),
  );
}

final folhaJogador = SpriteFolha(
  dir: 'spr/usu_dir.png',
  esq: 'spr/usu_esq.png',
  cim: 'spr/usu_cim.png',
  bai: 'spr/usu_bai.png',
  quadros: 6,
  tam: 16,
);

Future<WorldMap> montarMapa(Cenario cenario) async {
  await carregarImagem(cenario.tileset);
  final matriz = cenario.grd.map((linha) => linha.map((v) => v.toDouble()).toList()).toList();
  return MatrixMapGenerator.generate(
    layers: [MatrixLayer(matrix: matriz, axisInverted: true)],
    builder: (celula) {
      final gid = celula.value.toInt();
      final solido = cenario.solidos.contains(gid);
      return Tile(
        x: celula.position.x,
        y: celula.position.y,
        width: 16,
        height: 16,
        sprite: TileSprite(
          path: cenario.tileset,
          position: Vector2((gid - 1).clamp(0, 7).toDouble(), 0),
          size: Vector2.all(16),
        ),
        collisions: solido ? [RectangleHitbox(size: Vector2.all(16))] : null,
      );
    },
  );
}
