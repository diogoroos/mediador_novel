import { readFile, readdir } from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import admin from 'firebase-admin';

const aqui = path.dirname(fileURLToPath(import.meta.url));
const raiz = path.resolve(aqui, '../..');
const bucketNome = process.env.FIREBASE_STORAGE_BUCKET;
if (!bucketNome) {
  console.error('Defina FIREBASE_STORAGE_BUCKET, por exemplo novel-xxxxx.appspot.com');
  process.exit(1);
}

admin.initializeApp({
  credential: admin.credential.applicationDefault(),
  storageBucket: bucketNome,
});

const db = admin.firestore();
const bucket = admin.storage().bucket(bucketNome);

async function enviarPasta(dir, prefixo) {
  const itens = await readdir(dir, { withFileTypes: true });
  for (const item of itens) {
    const abs = path.join(dir, item.name);
    if (item.isDirectory()) {
      await enviarPasta(abs, `${prefixo}${item.name}/`);
    } else {
      const destino = `${prefixo}${item.name}`;
      await bucket.upload(abs, { destination: destino });
      console.log('storage', destino);
    }
  }
}

function gs(caminho) {
  if (!caminho || typeof caminho !== 'string') return caminho;
  if (caminho.startsWith('gs://')) return caminho;
  return `gs://${bucketNome}/${caminho}`;
}

function converterFolha(folha) {
  if (!folha || typeof folha !== 'object') return folha;
  const copia = { ...folha };
  for (const lado of ['dir', 'esq', 'cim', 'bai']) {
    if (copia[lado]) copia[lado] = gs(copia[lado]);
  }
  return copia;
}

const catalogo = JSON.parse(await readFile(path.join(raiz, 'assets/conteudo/catalogo.json'), 'utf8'));
await enviarPasta(path.join(raiz, 'assets/images'), '');

for (const cap of catalogo.caps) {
  const capRef = db.collection('E100CAP').doc(cap.id);
  await capRef.set({ ordCap: cap.ordCap, munCap: cap.munCap });
  for (const mis of cap.mis) {
    const { tra, ...resto } = mis;
    resto.spr = Object.fromEntries(Object.entries(resto.spr || {}).map(([k, v]) => [k, converterFolha(v)]));
    resto.cen = (resto.cen || []).map((cen) => ({ ...cen, tileset: gs(cen.tileset), map: gs(cen.map) }));
    await capRef.collection('MIS').doc(mis.id).set(resto);
    for (const [locale, textos] of Object.entries(tra || {})) {
      await capRef.collection('MIS').doc(mis.id).collection('TRA').doc(locale).set(textos);
    }
    console.log('missao', cap.id, mis.id);
  }
}

for (const item of catalogo.itens) {
  await db.collection('E050CAT').doc(item.id).set({ ...item, spr: gs(item.spr) });
}

for (const [id, pais] of Object.entries(catalogo.paises)) {
  const ref = db.collection('E002CTR').doc(id);
  await ref.set({ nomPai: pais.nomPai, moePai: pais.moePai, simMoe: pais.simMoe });
  await ref.collection('BLW').doc('v1').set({
    palavras: pais.blw,
    datAtu: admin.firestore.FieldValue.serverTimestamp(),
  });
  for (const item of pais.itm) {
    await ref.collection('ITM').doc(item.id).set(item);
  }
}

console.log('firebase populado');
