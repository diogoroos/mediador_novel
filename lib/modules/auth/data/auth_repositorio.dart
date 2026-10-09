import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:novel/core/consts/core_consts.dart';
import 'package:novel/core/nucleo.dart';

class NomeOcupado implements Exception {}

class AuthRepositorio {
  Future<User?> entrarGoogle() async {
    if (!Nucleo.firebase) return null;
    final google = GoogleSignIn();
    final conta = await google.signIn();
    if (conta == null) return null;
    final auth = await conta.authentication;
    final credencial = GoogleAuthProvider.credential(accessToken: auth.accessToken, idToken: auth.idToken);
    final sessao = await FirebaseAuth.instance.signInWithCredential(credencial);
    return sessao.user;
  }

  Future<void> sair() async {
    if (!Nucleo.firebase) return;
    await GoogleSignIn().signOut();
    await FirebaseAuth.instance.signOut();
  }

  Future<void> reservarNome({
    required String uid,
    required String nome,
    required String nascimento,
    required String pais,
  }) async {
    final db = FirebaseFirestore.instance;
    final nomeRef = db.collection(CoreConsts.collectionNomes).doc(nome);
    await db.runTransaction((tx) async {
      final doc = await tx.get(nomeRef);
      if (doc.exists && doc.data()?['ideUsu'] != uid) throw NomeOcupado();
      tx.set(nomeRef, {'ideUsu': uid});
      tx.set(db.collection(CoreConsts.collectionUsuarios).doc(uid), {
        'nomUsu': nome,
        'datNas': nascimento,
        'ideCtr': pais,
        'banUsu': false,
        'ourUsu': 0,
      });
    });
  }

  Future<bool> banido(String uid) async {
    final doc = await FirebaseFirestore.instance.collection(CoreConsts.collectionUsuarios).doc(uid).get();
    return doc.data()?['banUsu'] == true;
  }
}

class EntrarGoogleUsecase {
  EntrarGoogleUsecase(this._repositorio);
  final AuthRepositorio _repositorio;
  Future<User?> call() => _repositorio.entrarGoogle();
}

class ReservarNomeUsecase {
  ReservarNomeUsecase(this._repositorio);
  final AuthRepositorio _repositorio;
  Future<void> call({required String uid, required String nome, required String nascimento, required String pais}) {
    return _repositorio.reservarNome(uid: uid, nome: nome, nascimento: nascimento, pais: pais);
  }
}
