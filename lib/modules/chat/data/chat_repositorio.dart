import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:novel/core/consts/core_consts.dart';
import 'package:novel/core/nucleo.dart';
import 'package:novel/modules/chat/domain/filtro_ofensa.dart';

class ChatRepositorio {
  Future<bool> publicar({
    required String texto,
    required String nome,
    required String uid,
    required String capMis,
    required List<String> palavras,
    String? paraNome,
  }) async {
    if (!frasePermitida(texto, palavras)) return false;
    if (!Nucleo.firebase) return true;
    try {
      await FirebaseFunctions.instance.httpsCallable('publicarMensagem').call({
        'txt': texto,
        'nomUsu': nome,
        'capMis': capMis,
        'paraNom': paraNome,
      });
      return true;
    } on FirebaseFunctionsException {
      await FirebaseFirestore.instance.collection(CoreConsts.collectionChat).add({
        'txt': texto,
        'nomUsu': nome,
        'ideUsu': uid,
        'capMis': capMis,
        'paraNom': paraNome,
        'datEnv': FieldValue.serverTimestamp(),
      });
      return true;
    }
  }
}

class PublicarMensagemUsecase {
  PublicarMensagemUsecase(this._repositorio);
  final ChatRepositorio _repositorio;
  Future<bool> call({
    required String texto,
    required String nome,
    required String uid,
    required String capMis,
    required List<String> palavras,
    String? paraNome,
  }) {
    return _repositorio.publicar(
      texto: texto,
      nome: nome,
      uid: uid,
      capMis: capMis,
      palavras: palavras,
      paraNome: paraNome,
    );
  }
}
