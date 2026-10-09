import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:novel/core/consts/core_consts.dart';
import 'package:novel/core/nucleo.dart';

class AmigoPedido {
  AmigoPedido({required this.id, required this.de, required this.deNom, required this.para, required this.paraNom, required this.sta});

  final String id;
  final String de;
  final String deNom;
  final String para;
  final String paraNom;
  final String sta;
}

class AmigosRepositorio {
  Future<void> pedir({required String de, required String deNom, required String paraNom}) async {
    if (!Nucleo.firebase) return;
    final nome = await FirebaseFirestore.instance.collection(CoreConsts.collectionNomes).doc(paraNom).get();
    final para = nome.data()?['ideUsu']?.toString();
    if (para == null) throw StateError('nome');
    await FirebaseFirestore.instance.collection(CoreConsts.collectionAmigos).add({
      'de': de,
      'deNom': deNom,
      'para': para,
      'paraNom': paraNom,
      'sta': 'P',
    });
  }

  Future<List<AmigoPedido>> listar(String uid) async {
    if (!Nucleo.firebase) return const [];
    final db = FirebaseFirestore.instance.collection(CoreConsts.collectionAmigos);
    final comoDe = await db.where('de', isEqualTo: uid).get();
    final comoPara = await db.where('para', isEqualTo: uid).get();
    final itens = [...comoDe.docs, ...comoPara.docs];
    return itens.map((d) {
      final m = d.data();
      return AmigoPedido(
        id: d.id,
        de: m['de']?.toString() ?? '',
        deNom: m['deNom']?.toString() ?? '',
        para: m['para']?.toString() ?? '',
        paraNom: m['paraNom']?.toString() ?? '',
        sta: m['sta']?.toString() ?? 'P',
      );
    }).toList();
  }

  Future<void> atualizar(String id, String sta) async {
    if (!Nucleo.firebase) return;
    await FirebaseFirestore.instance.collection(CoreConsts.collectionAmigos).doc(id).update({'sta': sta});
  }

  Future<void> remover(String id) async {
    if (!Nucleo.firebase) return;
    await FirebaseFirestore.instance.collection(CoreConsts.collectionAmigos).doc(id).delete();
  }
}
