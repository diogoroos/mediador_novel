import 'package:firebase_core/firebase_core.dart';

/// Substituído por `flutterfire configure`. Enquanto [configurado] for falso,
/// o jogo usa o catálogo local e o cache do aparelho.
class DefaultFirebaseOptions {
  static const bool configurado = false;

  static FirebaseOptions get currentPlatform => throw UnsupportedError(
        'Rode flutterfire configure na raiz do projeto.',
      );
}
