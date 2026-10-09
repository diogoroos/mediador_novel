import 'dart:convert';

import 'package:novel/core/cache/fabrica_banco.dart';
import 'package:novel/modules/jogo/domain/tenda.dart';
import 'package:sembast/sembast.dart';

class Progresso {
  Progresso({
    this.nome = '',
    this.nascimento = '',
    this.pais = 'BR',
    this.banido = false,
    this.cap = 'cap01',
    this.mis = 'mis01',
    this.passo = 0,
    this.vida = 100,
    this.vidaMax = 100,
    this.mana = 20,
    this.manaMax = 20,
    this.our = 0,
    this.pra = 0,
    this.bro = 0,
    this.moeda = 0,
    this.defesa = 0,
    this.danoArma = 0,
    this.cor = '',
    this.hades = false,
    this.guiaCalado = '',
    Set<String>? conquistas,
    TendaEstoque? tenda,
    List<Espaco>? mochila,
  })  : conquistas = conquistas ?? {},
        tenda = tenda ?? TendaEstoque(),
        mochila = mochila ?? [];

  String nome;
  String nascimento;
  String pais;
  bool banido;
  String cap;
  String mis;
  int passo;
  double vida;
  double vidaMax;
  double mana;
  double manaMax;
  int our;
  int pra;
  int bro;
  int moeda;
  int defesa;
  int danoArma;
  String cor;
  bool hades;
  String guiaCalado;
  final Set<String> conquistas;
  final TendaEstoque tenda;
  final List<Espaco> mochila;

  Map<String, dynamic> toMap() => {
        'nome': nome,
        'nascimento': nascimento,
        'pais': pais,
        'banido': banido,
        'cap': cap,
        'mis': mis,
        'passo': passo,
        'vida': vida,
        'vidaMax': vidaMax,
        'mana': mana,
        'manaMax': manaMax,
        'our': our,
        'pra': pra,
        'bro': bro,
        'moeda': moeda,
        'defesa': defesa,
        'danoArma': danoArma,
        'cor': cor,
        'hades': hades,
        'guiaCalado': guiaCalado,
        'conquistas': conquistas.toList(),
        'tenda': tenda.espacos.map((e) => e.toMap()).toList(),
        'mochila': mochila.map((e) => e.toMap()).toList(),
      };

  static Progresso fromMap(Map<String, dynamic> map) {
    return Progresso(
      nome: map['nome']?.toString() ?? '',
      nascimento: map['nascimento']?.toString() ?? '',
      pais: map['pais']?.toString() ?? 'BR',
      banido: map['banido'] == true,
      cap: map['cap']?.toString() ?? 'cap01',
      mis: map['mis']?.toString() ?? 'mis01',
      passo: map['passo'] is num ? (map['passo'] as num).toInt() : 0,
      vida: map['vida'] is num ? (map['vida'] as num).toDouble() : 100,
      vidaMax: map['vidaMax'] is num ? (map['vidaMax'] as num).toDouble() : 100,
      mana: map['mana'] is num ? (map['mana'] as num).toDouble() : 20,
      manaMax: map['manaMax'] is num ? (map['manaMax'] as num).toDouble() : 20,
      our: map['our'] is num ? (map['our'] as num).toInt() : 0,
      pra: map['pra'] is num ? (map['pra'] as num).toInt() : 0,
      bro: map['bro'] is num ? (map['bro'] as num).toInt() : 0,
      moeda: map['moeda'] is num ? (map['moeda'] as num).toInt() : 0,
      defesa: map['defesa'] is num ? (map['defesa'] as num).toInt() : 0,
      danoArma: map['danoArma'] is num ? (map['danoArma'] as num).toInt() : 0,
      cor: map['cor']?.toString() ?? '',
      hades: map['hades'] == true,
      guiaCalado: map['guiaCalado']?.toString() ?? '',
      conquistas: ((map['conquistas'] as List?) ?? const []).map((e) => '$e').toSet(),
      tenda: TendaEstoque(((map['tenda'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Espaco.fromMap(Map<String, dynamic>.from(e)))
          .toList()),
      mochila: ((map['mochila'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Espaco.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class CacheLocal {
  CacheLocal(this._db);

  final Database _db;
  static final _store = stringMapStoreFactory.store('novel');

  static Future<CacheLocal> abrir() async {
    final db = await fabricaBanco().openDatabase(await caminhoBanco());
    return CacheLocal(db);
  }

  Future<Progresso> lerProgresso() async {
    final bruto = await _store.record('progresso').get(_db);
    if (bruto == null) return Progresso();
    return Progresso.fromMap(Map<String, dynamic>.from(bruto));
  }

  Future<void> gravarProgresso(Progresso progresso) async {
    await _store.record('progresso').put(_db, progresso.toMap().map((k, v) => MapEntry(k, v as Object?)));
  }

  Future<List<String>?> lerPalavras(String pais) async {
    final bruto = await _store.record('blw_$pais').get(_db);
    if (bruto == null) return null;
    final data = DateTime.tryParse(bruto['dat']?.toString() ?? '');
    if (data == null || DateTime.now().difference(data).inDays > 10) return null;
    final lista = bruto['palavras'];
    if (lista is! List) return null;
    return lista.map((e) => '$e').toList();
  }

  Future<void> gravarPalavras(String pais, List<String> palavras) async {
    await _store.record('blw_$pais').put(_db, {
      'dat': DateTime.now().toIso8601String(),
      'palavras': palavras,
    });
  }

  Future<void> gravarRascunhoLocal(Map<String, dynamic> dados) async {
    await _store.record('rascunho').put(_db, {'json': jsonEncode(dados)});
  }
}
