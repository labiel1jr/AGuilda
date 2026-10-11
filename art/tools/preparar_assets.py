"""Prepara as artes entregues em art/ArtesEmGeral/<id>.jpg para o jogo.

Para cada arquivo cujo nome é um id de art/specs/cenario/_indice.json:
  - lê o formato pelo conteúdo (há PNG com extensão .jpg);
  - remove o fundo branco a partir das bordas (exceto peças de imagem cheia);
  - recorta a área útil e salva PNG RGBA no 'destino' do asset, no tamanho de saída abaixo.

Uso:  python art/tools/preparar_assets.py
"""
import json
import re
from collections import deque
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
SRC = ROOT / "art" / "ArtesEmGeral"
INDICE = ROOT / "art" / "specs" / "cenario" / "_indice.json"

# Imagens cheias (sem recorte de fundo): id -> tamanho de saída
CHEIAS = {
    "icone_mestre": (512, 512),
    "icone_android_principal": (192, 192),
    "icone_android_fundo": (432, 432),
    "livro_aberto": (1536, 1024),
}
# Tamanho máximo de saída por prefixo (o tamanho_final da spec é o de exibição; guardamos 2x para nitidez)
SAIDA = [
    ("item_", (128, 128)), ("fer_", (128, 128)), ("rec_", (128, 128)),
    ("token_", (96, 128)), ("icone_android_", (432, 432)),
    ("livro_pagina", (600, 900)), ("livro_lombada", (64, 900)), ("livro_capa", (256, 384)),
    ("livro_borda", (256, 256)),
]
# Buracos fechados que mostram o fundo (anéis, arco): também ficam transparentes
BURACOS = ("item_anel_amizade", "item_brinco_sabio", "item_arco_longo")
QUADRADO = ("item_", "fer_", "rec_", "icone_android_frente", "icone_android_mono")


def eh_fundo(c):
    r, g, b = c[:3]
    return min(r, g, b) >= 222 and max(r, g, b) - min(r, g, b) <= 26


def tirar_fundo(img: Image.Image, interno: bool = False, buracos: bool = False) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    fundo = bytearray(w * h)
    if interno:
        for i in range(w * h):
            if eh_fundo(px[i % w, i // w]):
                fundo[i] = 1
    else:
        fila = deque([(x, y) for x in range(w) for y in (0, h - 1)] + [(x, y) for y in range(h) for x in (0, w - 1)])
        while fila:
            x, y = fila.popleft()
            i = y * w + x
            if fundo[i] or not eh_fundo(px[x, y]):
                continue
            fundo[i] = 1
            if x > 0: fila.append((x - 1, y))
            if x < w - 1: fila.append((x + 1, y))
            if y > 0: fila.append((x, y - 1))
            if y < h - 1: fila.append((x, y + 1))
    if buracos:
        for i in range(w * h):
            r, g, b, _ = px[i % w, i // w]
            if min(r, g, b) >= 238 and max(r, g, b) - min(r, g, b) <= 18:
                fundo[i] = 1
    # halo claro de compressão colado ao fundo
    for _ in range(2):
        novos = []
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                i = y * w + x
                if not fundo[i] and (fundo[i - 1] or fundo[i + 1] or fundo[i - w] or fundo[i + w]):
                    r, g, b, _ = px[x, y]
                    if min(r, g, b) >= 200 and max(r, g, b) - min(r, g, b) <= 40:
                        novos.append(i)
        for i in novos:
            fundo[i] = 1
    for i, f in enumerate(fundo):
        if f:
            px[i % w, i // w] = (0, 0, 0, 0)
    return img


def sombra_por_luminancia(img: Image.Image) -> Image.Image:
    """Sombra suave: transparência pela claridade (branco = transparente)."""
    g = img.convert("L")
    a = g.point(lambda v: max(0, min(255, int((235 - v) * 255 / 200))))
    out = Image.new("RGBA", img.size, (30, 20, 12, 0))
    out.putalpha(a)
    return out


def caber(img: Image.Image, tam, quadrado: bool) -> Image.Image:
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
    img = img.convert("RGBa")
    img.thumbnail(tam, Image.LANCZOS)
    img = img.convert("RGBA")
    if quadrado:
        lado = max(img.size)
        q = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
        q.alpha_composite(img, ((lado - img.width) // 2, (lado - img.height) // 2))
        img = q
    return img


def _faixas(ocupado):
    """[(início, fim)] das sequências contínuas de True."""
    out, ini = [], None
    for i, v in enumerate(ocupado + [False]):
        if v and ini is None:
            ini = i
        elif not v and ini is not None:
            out.append((ini, i))
            ini = None
    return out


def celulas(img: Image.Image) -> list:
    """Células de uma folha em grade (pela transparência), em ordem de leitura."""
    a = img.getchannel("A")
    w, h = img.size
    px = a.load()
    linhas = _faixas([any(px[x, y] > 16 for x in range(0, w, 3)) for y in range(h)])
    out = []
    for y0, y1 in linhas:
        cols = _faixas([any(px[x, y] > 16 for y in range(y0, y1, 3)) for x in range(w)])
        for x0, x1 in cols:
            if x1 - x0 > 20 and y1 - y0 > 20:
                out.append((x0, y0, x1, y1))
    return out


def destino_png(dest: str, aid: str) -> list:
    """res://... com {var}/{estado} → lista de caminhos locais."""
    p = dest.replace("res://", "")
    if "{estado}" in p:
        p = p.replace("{estado}", "parado")
    return [ROOT / p]


def saida_de(aid: str):
    for pre, tam in SAIDA:
        if aid.startswith(pre):
            return tam
    return (256, 256)


def main():
    idx = json.loads(INDICE.read_text(encoding="utf-8"))
    ids = {a["id"]: a for a in idx["assets"]}
    feitos = []
    for f in sorted(SRC.iterdir()):
        if f.suffix.lower() not in (".jpg", ".jpeg", ".png"):
            continue
        aid = re.split(r"[.,]", f.name)[0]
        if aid.startswith("btn_"):
            continue   # botões: art/tools/preparar_botoes.py
        if aid not in ids:
            print("sem asset:", f.name)
            continue
        img = Image.open(f)
        img.load()
        dest = ids[aid]["destino"]
        if aid.startswith("cena_"):
            # cenas do resultado: imagem cheia (sem recorte), guardada em 2x da exibição
            out = img.convert("RGB")
            out.thumbnail((960, 400), Image.LANCZOS)
            alvos = destino_png(dest, aid)
        elif aid in CHEIAS:
            out = img.convert("RGB").resize(CHEIAS[aid], Image.LANCZOS) if aid != "livro_aberto" else img.convert("RGB")
            if aid == "livro_aberto":
                out.thumbnail(CHEIAS[aid], Image.LANCZOS)
            alvos = destino_png(dest, aid)
        elif aid == "token_sombra":
            out = caber(sombra_por_luminancia(img), (96, 32), False)
            alvos = destino_png(dest, aid)
        elif aid == "dado_d20_faces":
            # folha com as 20 faces em grade (linha a linha, 1 a 20): recorta cada célula com conteúdo
            limpa = img.convert("RGBA") if img.mode == "RGBA" else tirar_fundo(img)
            for n, cel in enumerate(celulas(limpa)[:20], start=1):
                alvo = ROOT / dest.replace("res://", "").replace("{var}", "%02d" % n)
                alvo.parent.mkdir(parents=True, exist_ok=True)
                caber(limpa.crop(cel), (128, 128), True).save(alvo, optimize=True)
                feitos.append((aid, alvo))
            continue
        elif aid == "rec_moedas":
            # três variações numa só imagem: duas pilhas em cima, a bolsa embaixo
            limpa = tirar_fundo(img)
            w, h = limpa.size
            partes = {"pilha_media": limpa.crop((0, 0, w * 52 // 100, h * 44 // 100)),
                      "pilha_pequena": limpa.crop((w * 56 // 100, 0, w, h * 44 // 100)),
                      "bolsa_cheia": limpa.crop((0, h * 47 // 100, w, h))}
            for var, parte in partes.items():
                alvo = ROOT / dest.replace("res://", "").replace("{var}", var)
                alvo.parent.mkdir(parents=True, exist_ok=True)
                caber(parte, (128, 128), True).save(alvo, optimize=True)
                feitos.append((aid, alvo))
            continue
        else:
            limpa = tirar_fundo(img, interno=(aid == "livro_borda_ornamental"), buracos=(aid in BURACOS))
            if aid == "token_balao":
                out = limpa
                bbox = out.getbbox()
                out = out.crop(bbox) if bbox else out
                out.thumbnail((4 * 48, 56), Image.LANCZOS)   # tira de 4 quadros
            elif aid in ("icone_android_frente", "icone_android_mono"):
                # ícone adaptativo: símbolo dentro da zona segura (264 de 432 px)
                simb = caber(limpa, (264, 264), True)
                out = Image.new("RGBA", (432, 432), (0, 0, 0, 0))
                out.alpha_composite(simb, ((432 - simb.width) // 2, (432 - simb.height) // 2))
            elif aid == "livro_borda_ornamental":
                out = limpa.resize((256, 256), Image.LANCZOS)
            else:
                out = caber(limpa, saida_de(aid), aid.startswith(QUADRADO))
            alvos = destino_png(dest, aid)
        for alvo in alvos:
            alvo.parent.mkdir(parents=True, exist_ok=True)
            out.save(alvo, optimize=True)
            feitos.append((aid, alvo))
    for aid, alvo in feitos:
        im = Image.open(alvo)
        print(f"{aid:28} -> {alvo.relative_to(ROOT)}  {im.size}")
    print(len(feitos), "arquivos")


if __name__ == "__main__":
    main()
