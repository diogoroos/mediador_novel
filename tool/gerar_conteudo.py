#!/usr/bin/env python3
"""Gera tileset, sprites de 4 direções, mapas tmj e assets/conteudo/catalogo.json."""

import json
import shutil
import struct
import zlib
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[1]
IMG = RAIZ / "assets" / "images"
SPR = IMG / "spr"
TILE = IMG / "tile"
MAPA = IMG / "map"
KNIGHT = RAIZ / "bonfire" / "example" / "assets" / "images" / "player"
W, H = 36, 22
TW = 16

def png(w, h, rgba):
    raw = b"".join(b"\x00" + rgba[y * w * 4 : (y + 1) * w * 4] for y in range(h))

    def chunk(tag, data):
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
    return b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(raw, 9)) + chunk(b"IEND", b"")

def fill(w, h, color):
    r, g, b, a = color
    return bytearray([r, g, b, a] * (w * h))

def pix(buf, w, x, y, color):
    if x < 0 or y < 0 or x >= w:
        return
    i = (y * w + x) * 4
    buf[i : i + 4] = bytes(color)

def rect(buf, w, x, y, rw, rh, color):
    for yy in range(y, y + rh):
        for xx in range(x, x + rw):
            pix(buf, w, xx, yy, color)

def tile_chao():
    cores = [
        (74, 140, 58, 255),
        (46, 110, 170, 255),
        (168, 132, 74, 255),
        (18, 22, 28, 255),
        (28, 92, 40, 255),
        (186, 92, 140, 255),
        (120, 118, 112, 255),
        (210, 186, 96, 255),
    ]
    w, h = TW * len(cores), TW
    buf = fill(w, h, (0, 0, 0, 0))
    for i, cor in enumerate(cores):
        rect(buf, w, i * TW, 0, TW, TW, cor)
        if i == 1:
            rect(buf, w, i * TW + 2, 6, 12, 3, (180, 220, 240, 255))
        if i == 4:
            rect(buf, w, i * TW + 6, 2, 4, 8, (16, 60, 24, 255))
            rect(buf, w, i * TW + 4, 8, 8, 6, (20, 70, 28, 255))
        if i == 6:
            rect(buf, w, i * TW + 3, 3, 10, 10, (90, 88, 84, 255))
    (TILE / "chao.png").write_bytes(png(w, h, buf))

def boneco(nome, pele, roupa, marca, escamas=False):
    def quadro(ox, oy):
        buf = fill(32, 32, (0, 0, 0, 0))
        rect(buf, 32, 12, 4, 8, 8, pele)
        rect(buf, 32, 10, 12, 12, 10, roupa)
        rect(buf, 32, 8, 20, 4, 8, (40, 30, 24, 255))
        rect(buf, 32, 20, 20, 4, 8, (40, 30, 24, 255))
        pix(buf, 32, 14 + ox, 7 + oy, marca)
        pix(buf, 32, 18 + ox, 7 + oy, marca)
        if escamas:
            rect(buf, 32, 6, 16, 20, 6, roupa)
        return buf

    lados = {"dir": (1, 0), "esq": (-1, 0), "bai": (0, 1), "cim": (0, -1)}
    for lado, (ox, oy) in lados.items():
        (SPR / f"{nome}_{lado}.png").write_bytes(png(32, 32, quadro(ox, oy)))

def grade_vazia(gid=1):
    return [[gid for _ in range(W)] for _ in range(H)]

def borda(g, gid=4):
    for x in range(W):
        g[0][x] = gid
        g[H - 1][x] = gid
    for y in range(H):
        g[y][0] = gid
        g[y][W - 1] = gid

def tmj(nome, grade):
    data = []
    for linha in grade:
        data.extend(linha)
    doc = {
        "compressionlevel": -1,
        "height": H,
        "width": W,
        "infinite": False,
        "orientation": "orthogonal",
        "renderorder": "right-down",
        "tileheight": TW,
        "tilewidth": TW,
        "type": "map",
        "version": "1.10",
        "tiledversion": "1.10.0",
        "nextlayerid": 2,
        "nextobjectid": 1,
        "layers": [
            {
                "data": data,
                "height": H,
                "width": W,
                "id": 1,
                "name": "chao",
                "opacity": 1,
                "type": "tilelayer",
                "visible": True,
                "x": 0,
                "y": 0,
            }
        ],
        "tilesets": [
            {
                "columns": 8,
                "firstgid": 1,
                "image": "../tile/chao.png",
                "imageheight": TW,
                "imagewidth": TW * 8,
                "margin": 0,
                "name": "chao",
                "spacing": 0,
                "tilecount": 8,
                "tileheight": TW,
                "tilewidth": TW,
            }
        ],
    }
    (MAPA / nome).write_text(json.dumps(doc), encoding="utf-8")

def campo():
    g = grade_vazia(1)
    borda(g)
    for y in range(9, 12):
        for x in range(2, 20):
            g[y][x] = 2
    for y in range(8, 14):
        g[y][W - 1] = 1
    return g

def eden():
    g = grade_vazia(8)
    borda(g)
    for y in range(4, 18):
        for x in range(6, 28):
            if (x + y) % 5 == 0:
                g[y][x] = 6
    for y in range(6, 16):
        g[y][W - 1] = 8
    g[8][22] = 5
    for y in range(3, 19):
        g[y][31] = 5
        g[y][32] = 5
    return g

def irmaos():
    g = grade_vazia(1)
    borda(g)
    for y in range(6, 10):
        for x in range(24, 30):
            g[y][x] = 3
    g[7][27] = 7
    return g

def noé():
    g = grade_vazia(3)
    borda(g)
    for y in range(4, 12):
        for x in range(16, 28):
            g[y][x] = 1
    for x in range(18, 26):
        g[14][x] = 5
    for y in range(3, 8):
        for x in range(4, 10):
            g[y][x] = 1
    return g

def hades():
    g = grade_vazia(7)
    borda(g, 4)
    return g

def spr(nome):
    return {lado: f"spr/{nome}_{lado}.png" for lado in ("dir", "esq", "cim", "bai")}

def ator(nome, x, y, modo="parado", extra=None):
    item = {"id": nome, "spr": nome, "x": x, "y": y, "modo": modo, "tam": 32, "quadros": 1}
    if extra:
        item.update(extra)
    return item

def cen(cid, arquivo, grade, bor, prox=None, rep="deitar", pod=None):
    return {
        "id": cid,
        "map": f"map/{arquivo}",
        "tileset": "tile/chao.png",
        "grd": grade,
        "solidos": [2, 4, 5, 7],
        "bor": bor,
        "prox": prox,
        "rep": rep,
        "pod": pod,
        "porta": {"x": W - 1, "y": 8, "h": 6} if bor == "portal" else None,
    }

def mis(mid, **kwargs):
    base = {
        "id": mid,
        "verMis": 1,
        "aceIte": [],
        "aceEmp": False,
        "aceSld": False,
        "aceAni": [],
        "podMis": False,
        "morteRoteiro": False,
        "cqtMis": {},
        "guia": None,
    }
    base.update(kwargs)
    return base

def catalogo():
    g_campo, g_eden, g_irmaos, g_noe, g_hades = campo(), eden(), irmaos(), noé(), hades()
    tmj("cap01_campo.tmj", g_campo)
    tmj("cap01_eden.tmj", g_eden)
    tmj("cap02_irmaos.tmj", g_irmaos)
    tmj("cap03_noe.tmj", g_noe)
    tmj("hades.tmj", g_hades)
    return {
        "caps": [
            {
                "id": "cap01",
                "ordCap": 1,
                "munCap": "vel",
                "mis": [
                    mis(
                        "mis01",
                        cqtMis={"our": 0},
                        cen=[cen("cen01", "cap01_campo.tmj", g_campo, "portal", "cen02", rep="deitar")],
                        spr={"deus": spr("deus"), "leao": spr("leao"), "mamute": spr("mamute"), "dino": spr("dino")},
                        atores=[
                            ator("deus", 8, 16, "esperar"),
                            ator("leao", 6, 5),
                            ator("mamute", 14, 15),
                            ator("dino", 22, 6),
                        ],
                        pas=[
                            {"tip": "sld"},
                            {"tip": "seguir", "npc": "deus", "ateX": W - 3},
                            {"tip": "abrirPorta"},
                            {"tip": "entrar", "prox": "cen02", "mis": "mis02"},
                        ],
                        tra={
                            "pt_BR": {
                                "desMis": "Seguir Deus",
                                "sld01": "No princípio, o chão ainda estava quieto.",
                                "sld02": "Uma mão se estende. Acompanhe.",
                            },
                            "en_US": {
                                "desMis": "Follow God",
                                "sld01": "In the beginning, the ground was still quiet.",
                                "sld02": "A hand points the way. Follow.",
                            },
                        },
                    ),
                    mis(
                        "mis02",
                        cen=[cen("cen02", "cap01_eden.tmj", g_eden, "colisao", rep="deitar")],
                        spr={"mulher": spr("mulher"), "planta": spr("planta")},
                        atores=[
                            ator("planta", 10, 16, "arrastar", {"buraco": [12, 14]}),
                            ator("planta2", 18, 16, "arrastar", {"buraco": [16, 14], "spr": "planta"}),
                            ator("mulher", 20, 12, "fugir", {"ateX": 33, "ateY": 8}),
                        ],
                        pas=[{"tip": "arrastar", "qtd": 2}, {"tip": "avancar", "mis": "mis03"}],
                        tra={
                            "pt_BR": {"desMis": "Cobrir os dois buracos", "sld01": "Duas plantas esperam ao lado da terra aberta."},
                            "en_US": {"desMis": "Cover the two holes", "sld01": "Two plants wait beside the open ground."},
                        },
                    ),
                    mis(
                        "mis03",
                        cen=[cen("cen02", "cap01_eden.tmj", g_eden, "portal", "cen03", rep="deitar")],
                        spr={"eva": spr("eva"), "serpente": spr("serpente")},
                        atores=[
                            ator("arvore", 22, 8, "parado", {"spr": "arvore"}),
                            ator("serpente", 24, 8),
                        ],
                        pas=[
                            {"tip": "deitar"},
                            {"tip": "sld"},
                            {"tip": "surgir", "npc": "eva", "x": 8, "y": 14},
                            {"tip": "esperar", "seg": 120},
                            {"tip": "ir", "npc": "eva", "x": 22, "y": 9},
                            {"tip": "aproximar", "npc": "eva"},
                            {"tip": "sld"},
                            {"tip": "roupa", "cor": "pele"},
                            {"tip": "abrirPorta"},
                            {"tip": "entrar", "prox": "fim", "mis": "mis04"},
                        ],
                        tra={
                            "pt_BR": {
                                "desMis": "Descansar",
                                "sld01": "O sono vem. Quando você abre os olhos, há alguém ao lado.",
                                "sld02": "Ela come o fruto. A roupa agora é pele.",
                            },
                            "en_US": {
                                "desMis": "Rest",
                                "sld01": "Sleep comes. When you open your eyes, someone is beside you.",
                                "sld02": "She eats the fruit. The clothes are now skin.",
                            },
                        },
                    ),
                    mis(
                        "mis04",
                        cen=[cen("cen02", "cap01_eden.tmj", g_eden, "portal", None, rep="deitar")],
                        pas=[{"tip": "sair"}],
                        cqtMis={"our": 1},
                        tra={
                            "pt_BR": {"desMis": "Sair do jardim", "sld01": "O jardim fica para trás."},
                            "en_US": {"desMis": "Leave the garden", "sld01": "The garden stays behind."},
                        },
                    ),
                ],
            },
            {
                "id": "cap02",
                "ordCap": 2,
                "munCap": "vel",
                "mis": [
                    mis(
                        "mis01",
                        aceAni=["ovelha"],
                        morteRoteiro=True,
                        cqtMis={"our": 2},
                        cen=[cen("cen01", "cap02_irmaos.tmj", g_irmaos, "colisao", rep="ajoelhar")],
                        spr={"caim": spr("caim"), "ovelha": spr("ovelha")},
                        atores=[
                            ator("ovelha", 8, 14, "seguirJogador"),
                            ator("caim", 12, 16, "parado"),
                            ator("pedra", 27, 7, "parado", {"spr": "pedra"}),
                        ],
                        pas=[
                            {"tip": "levar", "npc": "ovelha", "x": 27, "y": 7},
                            {"tip": "golpe", "npc": "ovelha", "vezes": 1},
                            {"tip": "ir", "npc": "caim", "x": 26, "y": 8},
                            {"tip": "sld"},
                            {"tip": "lentidao"},
                            {"tip": "golpeNoUsuario", "npc": "caim"},
                            {"tip": "sld"},
                            {"tip": "capitulo", "cap": "cap03", "mis": "mis01"},
                        ],
                        tra={
                            "pt_BR": {
                                "desMis": "A oferta",
                                "sld01": "O irmão põe os vegetais ao lado da ovelha.",
                                "sld02": "A pedra cai uma vez. A missão se completa na morte.",
                            },
                            "en_US": {
                                "desMis": "The offering",
                                "sld01": "The brother lays the vegetables beside the sheep.",
                                "sld02": "The stone falls once. The mission ends in death.",
                            },
                        },
                    )
                ],
            },
            {
                "id": "cap03",
                "ordCap": 3,
                "munCap": "vel",
                "mis": [
                    mis(
                        "mis01",
                        aceIte=["mad"],
                        cqtMis={"mad": 8},
                        cen=[cen("cen01", "cap03_noe.tmj", g_noe, "colisao", rep="deitar")],
                        spr={
                            "noe": spr("noe"),
                            "aldeao": spr("aldeao"),
                            "gigante": spr("gigante"),
                            "anjo": spr("anjo"),
                        },
                        atores=[
                            ator("tenda", 30, 16, "parado", {"spr": "tenda"}),
                            ator("noe", 28, 16),
                            ator("aldeao", 20, 8),
                            ator("aldeao2", 22, 10, "parado", {"spr": "aldeao"}),
                            ator("gigante", 6, 5, "parado", {"tam": 48}),
                        ],
                        guia={
                            "npc": "anjo",
                            "raio": 140,
                            "nos": {
                                "ini": {
                                    "txt": "desGuia",
                                    "op": [
                                        {"rot": "opArca", "prox": "arca"},
                                        {"rot": "opCalar", "efe": "calar"},
                                    ],
                                },
                                "arca": {"txt": "txtArca", "op": [{"rot": "opMissao", "efe": "missao", "mis": "mis02"}]},
                            },
                        },
                        pas=[
                            {"tip": "afastar", "de": "tenda", "dist": 180},
                            {"tip": "voltar", "ate": "tenda", "dist": 70},
                            {"tip": "balao"},
                            {"tip": "avancar", "mis": "mis02"},
                        ],
                        tra={
                            "pt_BR": {
                                "desMis": "Andar e voltar à tenda",
                                "sld01": "A vila está cheia. Mais longe, os gigantes comem.",
                                "bal01": "Constrói uma arca.",
                                "bal02": "Junta madeira. Muita madeira.",
                                "desGuia": "Você viu a vila. A próxima tarefa é a arca.",
                                "opArca": "Falar da arca",
                                "opCalar": "Não me perturbe",
                                "txtArca": "A madeira está nas árvores ao sul da vila.",
                                "opMissao": "Aceitar a coleta",
                            },
                            "en_US": {
                                "desMis": "Walk and return to the tent",
                                "sld01": "The village is crowded. Farther out, the giants eat.",
                                "bal01": "Build an ark.",
                                "bal02": "Gather wood. A lot of wood.",
                                "desGuia": "You saw the village. The next task is the ark.",
                                "opArca": "Talk about the ark",
                                "opCalar": "Do not bother me",
                                "txtArca": "The wood is in the trees south of the village.",
                                "opMissao": "Accept the gathering",
                            },
                        },
                    ),
                    mis(
                        "mis02",
                        aceIte=["mad", "caj", "esc", "cor"],
                        cqtMis={"mad": 8},
                        cen=[cen("cen01", "cap03_noe.tmj", g_noe, "colisao", rep="deitar")],
                        spr={"arvore": spr("arvore")},
                        atores=[
                            ator("tenda", 30, 16, "parado", {"spr": "tenda"}),
                            ator("arvore", 19, 14, "recurso", {"tipRec": "mad", "golpes": 3}),
                            ator("arvore2", 21, 14, "recurso", {"spr": "arvore", "tipRec": "mad", "golpes": 3}),
                            ator("arvore3", 23, 14, "recurso", {"spr": "arvore", "tipRec": "mad", "golpes": 3}),
                        ],
                        pas=[{"tip": "coletar", "rec": "mad", "qtd": 8}],
                        tra={
                            "pt_BR": {"desMis": "Juntar madeira para a arca", "sld01": "Cada árvore cede madeira enquanto a ação continua."},
                            "en_US": {"desMis": "Gather wood for the ark", "sld01": "Each tree yields wood while the action continues."},
                        },
                    ),
                ],
            },
        ],
        "hades": {
            "cen": cen("had", "hades.tmj", g_hades, "colisao", rep="deitar"),
            "tra": {
                "pt_BR": {
                    "desMis": "Aprender",
                    "sld01": "Aqui não há dano nem compra.",
                    "perg": "Quem chama os mortos para fora deste descanso?",
                    "resp": "jesus",
                },
                "en_US": {
                    "desMis": "Learn",
                    "sld01": "Here there is no damage and no trade.",
                    "perg": "Who calls the dead out of this rest?",
                    "resp": "jesus",
                },
            },
            "placas": [
                {"x": 8, "y": 10, "txt": "sld01"},
                {"x": 18, "y": 12, "txt": "perg"},
            ],
        },
        "itens": [
            {"id": "cajado1", "tip": "caj", "rar": 30, "dan": 3, "def": 0, "comPag": True, "spr": "spr/cajado_dir.png"},
            {"id": "escudo1", "tip": "esc", "rar": 40, "dan": 0, "def": 1, "spr": "spr/escudo_dir.png"},
            {"id": "tinta", "tip": "cor", "rar": 15, "cor": "8C3A3A", "comPag": True, "spr": "spr/tinta_dir.png"},
        ],
        "paises": {
            "BR": {
                "nomPai": "Brasil",
                "moePai": "BRL",
                "simMoe": "R$",
                "blw": ["idiota", "burro", "porcaria"],
                "itm": [
                    {"id": "vida", "vlr": 9.9, "capMin": 1, "misMin": 1, "tip": "vida"},
                    {"id": "tinta", "vlr": 4.9, "capMin": 1, "misMin": 4, "tip": "cor"},
                    {"id": "cajado1", "vlr": 19.9, "capMin": 3, "misMin": 2, "tip": "caj"},
                ],
            },
            "US": {
                "nomPai": "United States",
                "moePai": "USD",
                "simMoe": "$",
                "blw": ["idiot", "stupid", "crap"],
                "itm": [
                    {"id": "vida", "vlr": 1.99, "capMin": 1, "misMin": 1, "tip": "vida"},
                    {"id": "tinta", "vlr": 0.99, "capMin": 1, "misMin": 4, "tip": "cor"},
                    {"id": "cajado1", "vlr": 3.99, "capMin": 3, "misMin": 2, "tip": "caj"},
                ],
            },
        },
    }

def main():
    SPR.mkdir(parents=True, exist_ok=True)
    TILE.mkdir(parents=True, exist_ok=True)
    MAPA.mkdir(parents=True, exist_ok=True)
    (RAIZ / "assets" / "conteudo").mkdir(parents=True, exist_ok=True)
    (RAIZ / "assets" / "idi").mkdir(parents=True, exist_ok=True)
    tile_chao()
    pares = {
        "deus": ((230, 210, 160, 255), (244, 228, 180, 255), (80, 60, 20, 255)),
        "mulher": ((210, 170, 140, 255), (150, 70, 90, 255), (40, 20, 20, 255)),
        "eva": ((214, 176, 150, 255), (120, 70, 40, 255), (30, 20, 16, 255)),
        "serpente": ((40, 120, 50, 255), (30, 90, 40, 255), (180, 220, 80, 255)),
        "leao": ((196, 140, 48, 255), (160, 100, 30, 255), (40, 20, 10, 255)),
        "mamute": ((110, 78, 52, 255), (80, 56, 40, 255), (20, 12, 8, 255)),
        "dino": ((70, 130, 70, 255), (50, 100, 55, 255), (20, 40, 20, 255)),
        "caim": ((190, 150, 110, 255), (90, 50, 30, 255), (20, 10, 8, 255)),
        "ovelha": ((230, 230, 220, 255), (200, 200, 190, 255), (40, 40, 40, 255)),
        "noe": ((200, 180, 150, 255), (70, 80, 110, 255), (240, 240, 240, 255)),
        "aldeao": ((180, 140, 110, 255), (100, 60, 50, 255), (20, 10, 10, 255)),
        "gigante": ((160, 120, 90, 255), (70, 40, 30, 255), (10, 8, 8, 255)),
        "anjo": ((240, 240, 250, 255), (250, 250, 255, 255), (200, 180, 80, 255)),
        "planta": ((40, 140, 50, 255), (30, 110, 40, 255), (180, 60, 80, 255)),
        "arvore": ((90, 60, 30, 255), (30, 100, 40, 255), (20, 60, 20, 255)),
        "pedra": ((130, 128, 120, 255), (90, 88, 84, 255), (40, 40, 40, 255)),
        "tenda": ((150, 90, 50, 255), (120, 60, 30, 255), (40, 20, 10, 255)),
        "cajado": ((120, 80, 40, 255), (90, 60, 30, 255), (200, 180, 80, 255)),
        "escudo": ((80, 100, 140, 255), (50, 70, 110, 255), (200, 200, 210, 255)),
        "tinta": ((140, 58, 58, 255), (100, 30, 30, 255), (240, 200, 200, 255)),
    }
    for nome, (pele, roupa, marca) in pares.items():
        boneco(nome, pele, roupa, marca, escamas=nome == "serpente")
    for origem, destino in (
        ("knight_idle.png", "usu_dir.png"),
        ("knight_idle_left.png", "usu_esq.png"),
        ("knight_idle.png", "usu_bai.png"),
        ("knight_idle.png", "usu_cim.png"),
        ("knight_run.png", "usu_corre_dir.png"),
        ("knight_run_left.png", "usu_corre_esq.png"),
    ):
        shutil.copy(KNIGHT / origem, SPR / destino)
    doc = catalogo()
    (RAIZ / "assets" / "conteudo" / "catalogo.json").write_text(
        json.dumps(doc, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print("conteudo gerado")

if __name__ == "__main__":
    main()
