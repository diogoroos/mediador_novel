const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { onRequest } = require('firebase-functions/v2/https');
const admin = require('firebase-admin');

admin.initializeApp();
const db = admin.firestore();

function exigirAuth(request) {
  if (!request.auth) throw new HttpsError('unauthenticated', 'auth');
  return request.auth.uid;
}

exports.publicarMensagem = onCall(async (request) => {
  const uid = exigirAuth(request);
  const txt = String(request.data.txt || '').slice(0, 240);
  const perfil = await db.collection('E010USU').doc(uid).get();
  const pais = perfil.get('ideCtr') || 'BR';
  const blw = await db.collection('E002CTR').doc(pais).collection('BLW').doc('v1').get();
  const palavras = blw.get('palavras') || [];
  const limpo = txt.toLowerCase();
  if (palavras.some((p) => limpo.includes(String(p).toLowerCase()))) {
    throw new HttpsError('failed-precondition', 'ofensa');
  }
  await db.collection('E030CHT').add({
    txt,
    ideUsu: uid,
    nomUsu: request.data.nomUsu || '',
    capMis: request.data.capMis || '',
    paraNom: request.data.paraNom || null,
    datEnv: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true };
});

exports.criarCobranca = onCall(async (request) => {
  const uid = exigirAuth(request);
  const item = String(request.data.item || '');
  const pais = String(request.data.pais || 'BR');
  const cap = Number(request.data.cap || 1);
  const mis = Number(request.data.mis || 1);
  const docItem = await db.collection('E002CTR').doc(pais).collection('ITM').doc(item).get();
  if (!docItem.exists) throw new HttpsError('not-found', 'item');
  const capMin = docItem.get('capMin') || 1;
  const misMin = docItem.get('misMin') || 1;
  const liberado = cap > capMin || (cap === capMin && mis >= misMin);
  if (!liberado) throw new HttpsError('failed-precondition', 'missao');
  const ref = db.collection('C100PAG').doc();
  await ref.set({
    ideUsu: uid,
    ideIte: item,
    ideCtr: pais,
    staPag: 'P',
    vlr: docItem.get('vlr') || 0,
    datCad: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { idePag: ref.id, staPag: 'P' };
});

exports.asaasWebhook = onRequest(async (req, res) => {
  const idePag = req.body && req.body.idePag;
  if (!idePag) {
    res.status(400).send('idePag');
    return;
  }
  await db.collection('C100PAG').doc(String(idePag)).set({ staPag: 'A' }, { merge: true });
  res.status(200).send('ok');
});

exports.concederConquista = onCall(async (request) => {
  const uid = exigirAuth(request);
  const cap = String(request.data.cap || '');
  const mis = String(request.data.mis || '');
  const chave = `${cap}/${mis}`;
  const ref = db.collection('E010USU').doc(uid).collection('PRG').doc(chave);
  const ja = await ref.get();
  if (ja.exists) return { ok: true, repetida: true };
  await ref.set({ cqtOk: true, dat: admin.firestore.FieldValue.serverTimestamp() });
  const ouro = Number(request.data.our || 0);
  if (ouro > 0) {
    await db.collection('E010USU').doc(uid).set({
      ourUsu: admin.firestore.FieldValue.increment(ouro),
    }, { merge: true });
  }
  return { ok: true };
});

exports.translateTexts = onCall(async (request) => {
  exigirAuth(request);
  const texts = request.data.texts || [];
  return { data: { translations: texts.map((t) => ({ translatedText: String(t) })) } };
});
