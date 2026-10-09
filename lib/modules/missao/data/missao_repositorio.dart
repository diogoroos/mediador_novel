import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:novel/core/consts/core_consts.dart';
import 'package:novel/core/nucleo.dart';
import 'package:novel/modules/missao/domain/models/catalogo.dart';

class MissaoRepositorio {
  Future<Catalogo> carregar() async {
    final local = await _local();
    if (!Nucleo.firebase) return local;
    try {
      final remoto = await _remoto();
      if (remoto.caps.isEmpty) return local;
      return remoto;
    } catch (_) {
      return local;
    }
  }

  Future<Catalogo> _local() async {
    final bruto = await rootBundle.loadString('assets/conteudo/catalogo.json');
    return Catalogo.fromJson(jsonDecode(bruto) as Map<String, dynamic>);
  }

  Future<Catalogo> _remoto() async {
    final db = FirebaseFirestore.instance;
    final capsSnap = await db.collection(CoreConsts.collectionCapitulos).get();
    final caps = <Map<String, dynamic>>[];
    for (final cap in capsSnap.docs) {
      final misSnap = await cap.reference.collection(CoreConsts.subMissoes).get();
      final mis = <Map<String, dynamic>>[];
      for (final doc in misSnap.docs) {
        final dados = doc.data();
        final traSnap = await doc.reference.collection(CoreConsts.subTraducoes).get();
        final tra = <String, dynamic>{};
        for (final t in traSnap.docs) {
          tra[t.id] = t.data();
        }
        dados['id'] = doc.id;
        dados['tra'] = tra;
        mis.add(dados);
      }
      mis.sort((a, b) => '${a['id']}'.compareTo('${b['id']}'));
      caps.add({'id': cap.id, ...cap.data(), 'mis': mis});
    }
    caps.sort((a, b) => (a['ordCap'] as num? ?? 0).compareTo(b['ordCap'] as num? ?? 0));
    final itens = await db.collection(CoreConsts.collectionItens).get();
    final paisesSnap = await db.collection(CoreConsts.collectionPaises).get();
    final paises = <String, dynamic>{};
    for (final pais in paisesSnap.docs) {
      final blw = await pais.reference.collection(CoreConsts.subPalavras).doc('v1').get();
      final itm = await pais.reference.collection(CoreConsts.subItensPais).get();
      paises[pais.id] = {
        ...pais.data(),
        'blw': (blw.data()?['palavras'] as List?) ?? const [],
        'itm': itm.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      };
    }
    final bruto = jsonDecode(await rootBundle.loadString('assets/conteudo/catalogo.json')) as Map<String, dynamic>;
    return Catalogo.fromJson({
      'caps': caps,
      'itens': itens.docs.map((d) => {'id': d.id, ...d.data()}).toList(),
      'paises': paises.isEmpty ? (bruto['paises'] ?? const {}) : paises,
      'hades': bruto['hades'],
    });
  }
}

class CarregarCatalogoUsecase {
  CarregarCatalogoUsecase(this._repositorio);
  final MissaoRepositorio _repositorio;
  Future<Catalogo> call() => _repositorio.carregar();
}
