# Novel

RPG bíblico. O Bonfire está em `bonfire/` e entra pelo `pubspec` como caminho.

Antes do Firebase, o jogo roda com o catálogo em `assets/conteudo/catalogo.json`. Na entrada, use "Jogar neste aparelho".

Depois de criar o projeto no console:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Isso substitui `lib/firebase_options.dart`. Em seguida abra o arquivo e deixe o app inicializar o Firebase: troque `configurado` para `true` se o arquivo gerado não tiver esse campo, ou copie a classe gerada e mantenha `static const bool configurado = true`.

```bash
export GOOGLE_APPLICATION_CREDENTIALS=/caminho/serviceAccount.json
export FIREBASE_STORAGE_BUCKET=seu-projeto.appspot.com
cd tool/seed && npm install && node seed.mjs
cd ../../functions && npm install
firebase deploy --only firestore:rules,storage,functions
```

Os documentos de missão guardam `gs://`. A leitura do Storage exige usuário autenticado. A escrita fica só no Admin SDK.
