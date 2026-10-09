class SpriteFolha {
  SpriteFolha({
    required this.dir,
    required this.esq,
    required this.cim,
    required this.bai,
    this.quadros = 1,
    this.tam = 32,
  });

  final String dir;
  final String esq;
  final String cim;
  final String bai;
  final int quadros;
  final double tam;

  static SpriteFolha? from(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final dir = map['dir']?.toString();
    if (dir == null) return null;
    return SpriteFolha(
      dir: dir,
      esq: map['esq']?.toString() ?? dir,
      cim: map['cim']?.toString() ?? dir,
      bai: map['bai']?.toString() ?? dir,
      quadros: _int(map['quadros'], 1),
      tam: _num(map['tam'], 32),
    );
  }
}

class PortaCenario {
  PortaCenario({required this.x, required this.y, required this.h});

  final int x;
  final int y;
  final int h;

  static PortaCenario? from(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    return PortaCenario(x: _int(map['x']), y: _int(map['y']), h: _int(map['h'], 2));
  }
}

class Cenario {
  Cenario({
    required this.id,
    required this.map,
    required this.tileset,
    required this.grd,
    required this.solidos,
    required this.bor,
    required this.rep,
    this.prox,
    this.pod,
    this.porta,
  });

  final String id;
  final String map;
  final String tileset;
  final List<List<int>> grd;
  final List<int> solidos;
  final String bor;
  final String? prox;
  final String rep;
  final String? pod;
  final PortaCenario? porta;

  static Cenario fromMap(Map<String, dynamic> map) {
    final linhas = <List<int>>[];
    final bruto = map['grd'];
    if (bruto is List) {
      for (final linha in bruto) {
        if (linha is List) {
          linhas.add(linha.map(_int).toList());
        }
      }
    }
    return Cenario(
      id: map['id']?.toString() ?? 'cen',
      map: map['map']?.toString() ?? '',
      tileset: map['tileset']?.toString() ?? 'tile/chao.png',
      grd: linhas,
      solidos: (map['solidos'] as List?)?.map(_int).toList() ?? const [4],
      bor: map['bor']?.toString() ?? 'colisao',
      prox: map['prox']?.toString(),
      rep: map['rep']?.toString() ?? 'deitar',
      pod: map['pod']?.toString(),
      porta: PortaCenario.from(map['porta']),
    );
  }
}

class AtorDoc {
  AtorDoc({
    required this.id,
    required this.spr,
    required this.x,
    required this.y,
    required this.modo,
    this.tam = 32,
    this.quadros = 1,
    this.buraco,
    this.ateX,
    this.ateY,
    this.golpes = 1,
    this.tipRec,
  });

  final String id;
  final String spr;
  final int x;
  final int y;
  final String modo;
  final double tam;
  final int quadros;
  final List<int>? buraco;
  final int? ateX;
  final int? ateY;
  final int golpes;
  final String? tipRec;

  static AtorDoc fromMap(Map<String, dynamic> map) {
    List<int>? buraco;
    if (map['buraco'] is List) {
      buraco = (map['buraco'] as List).map(_int).toList();
    }
    return AtorDoc(
      id: map['id']?.toString() ?? 'ator',
      spr: map['spr']?.toString() ?? map['id']?.toString() ?? 'ator',
      x: _int(map['x']),
      y: _int(map['y']),
      modo: map['modo']?.toString() ?? 'parado',
      tam: _num(map['tam'], 32),
      quadros: _int(map['quadros'], 1),
      buraco: buraco,
      ateX: map['ateX'] == null ? null : _int(map['ateX']),
      ateY: map['ateY'] == null ? null : _int(map['ateY']),
      golpes: _int(map['golpes'], 1),
      tipRec: map['tipRec']?.toString(),
    );
  }
}

class Passo {
  Passo(this.map);

  final Map<String, dynamic> map;
  String get tip => map['tip']?.toString() ?? '';
  String? get npc => map['npc']?.toString();
  int get qtd => _int(map['qtd']);
  int get seg => _int(map['seg']);
  int get vezes => _int(map['vezes'], 1);
  int get x => _int(map['x']);
  int get y => _int(map['y']);
  int get ateX => _int(map['ateX']);
  double get dist => _num(map['dist']);
  String? get de => map['de']?.toString();
  String? get ate => map['ate']?.toString();
  String? get mis => map['mis']?.toString();
  String? get cap => map['cap']?.toString();
  String? get rec => map['rec']?.toString();
  String? get prox => map['prox']?.toString();
  String? get cor => map['cor']?.toString();
}

class OpcaoGuia {
  OpcaoGuia(this.map);
  final Map<String, dynamic> map;
  String get rot => map['rot']?.toString() ?? '';
  String? get prox => map['prox']?.toString();
  String? get efe => map['efe']?.toString();
  String? get mis => map['mis']?.toString();
}

class NoGuia {
  NoGuia(this.map);
  final Map<String, dynamic> map;
  String get txt => map['txt']?.toString() ?? '';
  List<OpcaoGuia> get op => ((map['op'] as List?) ?? const [])
      .whereType<Map>()
      .map((e) => OpcaoGuia(Map<String, dynamic>.from(e)))
      .toList();
}

class GuiaDoc {
  GuiaDoc({required this.npc, required this.raio, required this.nos});

  final String npc;
  final double raio;
  final Map<String, NoGuia> nos;

  static GuiaDoc? from(dynamic raw) {
    if (raw is! Map) return null;
    final map = Map<String, dynamic>.from(raw);
    final nos = <String, NoGuia>{};
    final bruto = map['nos'];
    if (bruto is Map) {
      bruto.forEach((chave, valor) {
        if (valor is Map) nos['$chave'] = NoGuia(Map<String, dynamic>.from(valor));
      });
    }
    return GuiaDoc(npc: map['npc']?.toString() ?? 'anjo', raio: _num(map['raio'], 120), nos: nos);
  }
}

class Missao {
  Missao({
    required this.id,
    required this.verMis,
    required this.aceIte,
    required this.aceEmp,
    required this.aceSld,
    required this.aceAni,
    required this.podMis,
    required this.morteRoteiro,
    required this.cqtMis,
    required this.cen,
    required this.spr,
    required this.atores,
    required this.pas,
    required this.textos,
    this.guia,
  });

  final String id;
  final int verMis;
  final List<String> aceIte;
  final bool aceEmp;
  final bool aceSld;
  final List<String> aceAni;
  final bool podMis;
  final bool morteRoteiro;
  final Map<String, dynamic> cqtMis;
  final List<Cenario> cen;
  final Map<String, SpriteFolha> spr;
  final List<AtorDoc> atores;
  final List<Passo> pas;
  final Map<String, Map<String, String>> textos;
  final GuiaDoc? guia;

  String tr(String locale, String chave) {
    final bloco = textos[locale] ?? textos['pt_BR'] ?? const {};
    return bloco[chave] ?? textos['pt_BR']?[chave] ?? chave;
  }

  List<String> lista(String locale, String prefixo) {
    final bloco = textos[locale] ?? textos['pt_BR'] ?? const {};
    final chaves = bloco.keys.where((c) => c.startsWith(prefixo)).toList()..sort();
    return chaves.map((c) => bloco[c] ?? '').toList();
  }

  static Missao fromMap(Map<String, dynamic> map) {
    final spr = <String, SpriteFolha>{};
    if (map['spr'] is Map) {
      (map['spr'] as Map).forEach((chave, valor) {
        final folha = SpriteFolha.from(valor);
        if (folha != null) spr['$chave'] = folha;
      });
    }
    final textos = <String, Map<String, String>>{};
    if (map['tra'] is Map) {
      (map['tra'] as Map).forEach((locale, bloco) {
        if (bloco is Map) {
          textos['$locale'] = bloco.map((k, v) => MapEntry('$k', '$v'));
        }
      });
    }
    return Missao(
      id: map['id']?.toString() ?? 'mis',
      verMis: _int(map['verMis'], 1),
      aceIte: (map['aceIte'] as List?)?.map((e) => '$e').toList() ?? const [],
      aceEmp: map['aceEmp'] == true,
      aceSld: map['aceSld'] == true,
      aceAni: (map['aceAni'] as List?)?.map((e) => '$e').toList() ?? const [],
      podMis: map['podMis'] == true,
      morteRoteiro: map['morteRoteiro'] == true,
      cqtMis: map['cqtMis'] is Map ? Map<String, dynamic>.from(map['cqtMis'] as Map) : const {},
      cen: ((map['cen'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Cenario.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      spr: spr,
      atores: ((map['atores'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => AtorDoc.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      pas: ((map['pas'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Passo(Map<String, dynamic>.from(e)))
          .toList(),
      textos: textos,
      guia: GuiaDoc.from(map['guia']),
    );
  }
}

class Capitulo {
  Capitulo({required this.id, required this.ordCap, required this.munCap, required this.mis});

  final String id;
  final int ordCap;
  final String munCap;
  final List<Missao> mis;

  static Capitulo fromMap(Map<String, dynamic> map) {
    return Capitulo(
      id: map['id']?.toString() ?? 'cap',
      ordCap: _int(map['ordCap']),
      munCap: map['munCap']?.toString() ?? 'vel',
      mis: ((map['mis'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Missao.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class ItemCat {
  ItemCat({
    required this.id,
    required this.tip,
    required this.rar,
    required this.dan,
    required this.def,
    required this.spr,
    this.comPag = false,
    this.cor,
  });

  final String id;
  final String tip;
  final int rar;
  final int dan;
  final int def;
  final String spr;
  final bool comPag;
  final String? cor;

  static ItemCat fromMap(Map<String, dynamic> map) {
    return ItemCat(
      id: map['id']?.toString() ?? '',
      tip: map['tip']?.toString() ?? '',
      rar: _int(map['rar']),
      dan: _int(map['dan']),
      def: _int(map['def']),
      spr: map['spr']?.toString() ?? '',
      comPag: map['comPag'] == true,
      cor: map['cor']?.toString(),
    );
  }
}

class ItemPais {
  ItemPais({required this.id, required this.vlr, required this.capMin, required this.misMin, required this.tip});

  final String id;
  final double vlr;
  final int capMin;
  final int misMin;
  final String tip;

  bool liberado(int cap, int mis) => cap > capMin || (cap == capMin && mis >= misMin);
}

class PaisDoc {
  PaisDoc({required this.id, required this.nomPai, required this.moePai, required this.simMoe, required this.blw, required this.itm});

  final String id;
  final String nomPai;
  final String moePai;
  final String simMoe;
  final List<String> blw;
  final List<ItemPais> itm;
}

class Catalogo {
  Catalogo({required this.caps, required this.hades, required this.itens, required this.paises});

  final List<Capitulo> caps;
  final Missao? hades;
  final List<ItemCat> itens;
  final Map<String, PaisDoc> paises;

  Capitulo? cap(String id) {
    for (final c in caps) {
      if (c.id == id) return c;
    }
    return null;
  }

  Missao? mis(String capId, String misId) {
    final c = cap(capId);
    if (c == null) return null;
    for (final m in c.mis) {
      if (m.id == misId) return m;
    }
    return null;
  }

  (String, String)? proxima(String capId, String misId) {
    final c = cap(capId);
    if (c == null) return null;
    final i = c.mis.indexWhere((m) => m.id == misId);
    if (i >= 0 && i + 1 < c.mis.length) return (capId, c.mis[i + 1].id);
    final ordem = caps.indexWhere((e) => e.id == capId);
    if (ordem >= 0 && ordem + 1 < caps.length && caps[ordem + 1].mis.isNotEmpty) {
      return (caps[ordem + 1].id, caps[ordem + 1].mis.first.id);
    }
    return null;
  }

  int ordemCap(String id) => cap(id)?.ordCap ?? 1;

  int ordemMis(String capId, String misId) {
    final lista = cap(capId)?.mis ?? const [];
    final i = lista.indexWhere((m) => m.id == misId);
    return i < 0 ? 1 : i + 1;
  }

  bool desbloqueada(String capId, String misId, String capAtual, String misAtual) {
    final a = ordemCap(capId);
    final b = ordemCap(capAtual);
    if (a < b) return true;
    if (a > b) return false;
    return ordemMis(capId, misId) <= ordemMis(capAtual, misAtual);
  }

  static Catalogo fromJson(Map<String, dynamic> json) {
    final paises = <String, PaisDoc>{};
    if (json['paises'] is Map) {
      (json['paises'] as Map).forEach((id, bruto) {
        if (bruto is! Map) return;
        final map = Map<String, dynamic>.from(bruto);
        paises['$id'] = PaisDoc(
          id: '$id',
          nomPai: map['nomPai']?.toString() ?? '$id',
          moePai: map['moePai']?.toString() ?? '',
          simMoe: map['simMoe']?.toString() ?? '',
          blw: (map['blw'] as List?)?.map((e) => '$e').toList() ?? const [],
          itm: ((map['itm'] as List?) ?? const []).whereType<Map>().map((e) {
            final item = Map<String, dynamic>.from(e);
            return ItemPais(
              id: item['id']?.toString() ?? '',
              vlr: _num(item['vlr']),
              capMin: _int(item['capMin'], 1),
              misMin: _int(item['misMin'], 1),
              tip: item['tip']?.toString() ?? '',
            );
          }).toList(),
        );
      });
    }
    Missao? hades;
    if (json['hades'] is Map) {
      final h = Map<String, dynamic>.from(json['hades'] as Map);
      hades = Missao.fromMap({
        'id': 'hades',
        'cen': [h['cen']],
        'tra': h['tra'],
        'atores': const [],
        'pas': const [],
      });
    }
    return Catalogo(
      caps: ((json['caps'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => Capitulo.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      hades: hades,
      itens: ((json['itens'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ItemCat.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      paises: paises,
    );
  }
}

int _int(dynamic v, [int falha = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse('$v') ?? falha;
}

double _num(dynamic v, [double falha = 0]) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? falha;
}
