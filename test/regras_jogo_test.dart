import 'package:flutter_test/flutter_test.dart';
import 'package:novel/modules/chat/domain/filtro_ofensa.dart';
import 'package:novel/modules/jogo/domain/acao_travada.dart';
import 'package:novel/modules/jogo/domain/tenda.dart';
import 'package:novel/modules/missao/domain/aceite.dart';
import 'package:novel/modules/missao/domain/conquista.dart';
import 'package:novel/modules/missao/domain/models/catalogo.dart';

void main() {
  test('segurar 2 segundos trava a ação e andar não limpa', () {
    final acao = AcaoTravada();
    acao.pointerDown(sobreObjetoPerto: false);
    acao.tickSegurando(const Duration(seconds: 2));
    acao.pointerUp();
    expect(acao.continua, isTrue);
    expect(acao.modo, ModoAcao.ataque);
    acao.pointerDown(sobreObjetoPerto: true);
    expect(acao.modo, ModoAcao.interagir);
    expect(acao.continua, isFalse);
  });

  test('clique em objeto nasce interação', () {
    final acao = AcaoTravada();
    acao.pointerDown(sobreObjetoPerto: true);
    acao.pointerUp();
    expect(acao.disparoUnico, isTrue);
    acao.consumirDisparo();
    expect(acao.modo, ModoAcao.nenhuma);
  });

  test('espaço de 2 segundos marca a pose', () {
    final pose = EspacoPose();
    pose.down();
    pose.tick(const Duration(seconds: 2), topDown: true);
    expect(pose.ativa, isTrue);
    expect(pose.up(), isFalse);
  });

  test('tenda empilha, divide e recusa sem espaço', () {
    final tenda = TendaEstoque();
    expect(tenda.guardar(const Espaco(id: 'mad', qtd: 2, tip: 'mad')), isTrue);
    expect(tenda.guardar(const Espaco(id: 'ped', qtd: 1, tip: 'ped')), isTrue);
    expect(tenda.empilhar(1, 0), isFalse);
    tenda.espacos[2] = const Espaco(id: 'mad', qtd: 1, tip: 'mad');
    expect(tenda.empilhar(2, 0), isTrue);
    expect(tenda.espacos[0].qtd, 3);
    expect(tenda.dividir(0), isTrue);
    expect(tenda.espacos[0].qtd, 2);
    for (var i = 0; i < tenda.espacos.length; i++) {
      if (tenda.espacos[i].vazio) {
        tenda.espacos[i] = const Espaco(id: 'x', qtd: 1, tip: 'ped');
      }
    }
    expect(tenda.dividir(0), isFalse);
  });

  test('missão sem o tipo deixa o item indisponível', () {
    final missao = Missao.fromMap({
      'id': 'mis01',
      'aceIte': ['mad'],
      'aceSld': false,
      'aceAni': ['ovelha'],
    });
    expect(itemAceito(missao, const Espaco(id: 'cajado1', qtd: 1, tip: 'caj')), isFalse);
    expect(itemAceito(missao, const Espaco(id: 'mad', qtd: 1, tip: 'mad')), isTrue);
    expect(itemAceito(missao, const Espaco(id: 'ovelha', qtd: 1, tip: 'ani')), isTrue);
    expect(podeConceder({'cap01/mis01'}, 'cap01', 'mis01'), isFalse);
    expect(podeConceder({}, 'cap01', 'mis01'), isTrue);
  });

  test('frase com palavra do país não passa', () {
    expect(frasePermitida('oi, idiota', ['idiota']), isFalse);
    expect(frasePermitida('oi', ['idiota']), isTrue);
  });
}
