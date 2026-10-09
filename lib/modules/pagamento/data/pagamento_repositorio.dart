import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:novel/core/consts/core_consts.dart';
import 'package:novel/core/nucleo.dart';
import 'package:novel/modules/missao/domain/models/catalogo.dart';

class PagamentoRepositorio {
  Future<String?> cobrar({required String item, required String pais, required int cap, required int mis}) async {
    if (!Nucleo.firebase) return null;
    try {
      final resposta = await FirebaseFunctions.instance.httpsCallable('criarCobranca').call({
        'item': item,
        'pais': pais,
        'cap': cap,
        'mis': mis,
      });
      final dados = resposta.data;
      if (dados is Map) return dados['idePag']?.toString();
    } on FirebaseFunctionsException {
      final ref = FirebaseFirestore.instance.collection(CoreConsts.collectionPagamentos).doc();
      await ref.set({'ideIte': item, 'ideCtr': pais, 'cap': cap, 'mis': mis, 'staPag': 'P'});
      return ref.id;
    }
    return null;
  }
}

class CriarCobrancaUsecase {
  CriarCobrancaUsecase(this._repositorio);
  final PagamentoRepositorio _repositorio;
  Future<String?> call({required ItemPais item, required String pais, required int cap, required int mis}) {
    return _repositorio.cobrar(item: item.id, pais: pais, cap: cap, mis: mis);
  }
}
