import 'package:novel/modules/jogo/domain/tenda.dart';
import 'package:novel/modules/missao/domain/models/catalogo.dart';

bool itemAceito(Missao missao, Espaco espaco) {
  if (espaco.vazio) return false;
  final tip = espaco.tip ?? '';
  if (tip == 'sld') return missao.aceSld;
  if (tip == 'emp') return missao.aceEmp;
  if (tip == 'ani') return missao.aceAni.contains(espaco.id);
  return missao.aceIte.contains(tip);
}

List<Espaco> itensUsaveis(Missao missao, List<Espaco> todos) {
  return todos.where((e) => itemAceito(missao, e)).toList();
}
