import 'package:novel/core/consts/core_consts.dart';

class Espaco {
  const Espaco({this.id, this.qtd = 0, this.tip, this.comprado = false});

  final String? id;
  final int qtd;
  final String? tip;
  final bool comprado;

  bool get vazio => id == null || qtd <= 0;

  Espaco copia({int? qtd}) => Espaco(id: id, qtd: qtd ?? this.qtd, tip: tip, comprado: comprado);

  Map<String, dynamic> toMap() => {'id': id, 'qtd': qtd, 'tip': tip, 'comprado': comprado};

  static Espaco fromMap(Map<String, dynamic> map) {
    return Espaco(
      id: map['id']?.toString(),
      qtd: map['qtd'] is num ? (map['qtd'] as num).toInt() : 0,
      tip: map['tip']?.toString(),
      comprado: map['comprado'] == true,
    );
  }
}

class TendaEstoque {
  TendaEstoque([List<Espaco>? espacos])
      : espacos = List<Espaco>.generate(
          CoreConsts.tendaEspacos,
          (i) => (espacos != null && i < espacos.length) ? espacos[i] : const Espaco(),
        );

  final List<Espaco> espacos;

  int? primeiroVazio() {
    for (var i = 0; i < espacos.length; i++) {
      if (espacos[i].vazio) return i;
    }
    return null;
  }

  bool guardar(Espaco item) {
    if (item.vazio) return false;
    for (var i = 0; i < espacos.length; i++) {
      final atual = espacos[i];
      if (atual.id == item.id) {
        espacos[i] = atual.copia(qtd: atual.qtd + item.qtd);
        return true;
      }
    }
    final vazio = primeiroVazio();
    if (vazio == null) return false;
    espacos[vazio] = item;
    return true;
  }

  bool empilhar(int origem, int destino) {
    if (origem == destino || origem < 0 || destino < 0) return false;
    final a = espacos[origem];
    final b = espacos[destino];
    if (a.vazio || b.vazio || a.id != b.id) return false;
    espacos[destino] = b.copia(qtd: b.qtd + a.qtd);
    espacos[origem] = const Espaco();
    return true;
  }

  bool dividir(int indice) {
    if (indice < 0 || indice >= espacos.length) return false;
    final atual = espacos[indice];
    if (atual.vazio || atual.qtd < 1) return false;
    final vazio = primeiroVazio();
    if (vazio == null) return false;
    espacos[indice] = atual.copia(qtd: atual.qtd - 1);
    if (espacos[indice].qtd <= 0) espacos[indice] = const Espaco();
    espacos[vazio] = Espaco(id: atual.id, qtd: 1, tip: atual.tip, comprado: atual.comprado);
    return true;
  }

  Espaco? retirar(int indice) {
    if (indice < 0 || indice >= espacos.length) return null;
    final atual = espacos[indice];
    if (atual.vazio) return null;
    espacos[indice] = const Espaco();
    return atual;
  }
}
