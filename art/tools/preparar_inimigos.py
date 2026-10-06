"""Prepara os cartazes de inimigos (JPEG 1024x1024 com fundo de parede, madeira
ou branco) para o jogo: remove o fundo a partir das bordas e salva PNG RGBA 256x256.

O fundo muda de imagem para imagem, então as cores de fundo são amostradas na
borda de cada imagem; tudo que for parecido com elas e estiver ligado à borda
vira transparente. O cartaz, o prego e o que sai da moldura têm outras cores e ficam.

Uso:  python art/tools/preparar_inimigos.py
Entrada: art/enemies/originais/<id>.jpg (ou .png — o formato é lido do conteúdo)   Saída: art/enemies/<id>.png
"""
from collections import deque
from pathlib import Path

from PIL import Image, ImageFilter

RAIZ = Path(__file__).resolve().parents[1] / "enemies"
TAMANHO = 256
LIMIAR = 40          # distância de cor para ser considerado fundo
LIMIAR_HALO = 70     # limpeza da borda do recorte
FECHAMENTO = 31      # px (ímpar): sela rasgos estreitos por onde o fundo vazaria para dentro do cartaz


def cores_da_borda(img: Image.Image, n: int = 32) -> list:
    w, h = img.size
    faixa = Image.new("RGB", (2 * (w + h), 3))
    px = faixa.load()
    src = img.load()
    i = 0
    for x in range(w):
        for k, y in enumerate((0, 1, h - 1)):
            px[i, k] = src[x, y]
        i += 1
    for x in range(w):
        for k, y in enumerate((2, h - 2, h - 3)):
            px[i, k] = src[x, y]
        i += 1
    for y in range(h):
        for k, x in enumerate((0, 1, w - 1)):
            px[i, k] = src[x, y]
        i += 1
    for y in range(h):
        for k, x in enumerate((2, w - 2, w - 3)):
            px[i, k] = src[x, y]
        i += 1
    pal = faixa.quantize(colors=n, method=Image.Quantize.MEDIANCUT).getpalette()[: n * 3]
    return [tuple(pal[j:j + 3]) for j in range(0, len(pal), 3)]


def perto(c, cores, limiar):
    r, g, b = c[:3]
    lim2 = limiar * limiar
    for (R, G, B) in cores:
        if (r - R) ** 2 + (g - G) ** 2 + (b - B) ** 2 <= lim2:
            return True
    return False


def remover_fundo(img: Image.Image) -> Image.Image:
    rgb = img.convert("RGB")
    cores = cores_da_borda(rgb)
    img = rgb.convert("RGBA")
    w, h = img.size
    px = img.load()
    fundo = bytearray(w * h)
    cache = {}

    def eh_fundo(c, limiar=LIMIAR):
        k = (c[0] >> 2, c[1] >> 2, c[2] >> 2, limiar)
        if k not in cache:
            cache[k] = perto(c, cores, limiar)
        return cache[k]

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
    # Fechamento: o que ficou dentro do contorno do cartaz (vazado por rasgos estreitos) volta
    mascara = Image.frombytes("L", (w, h), bytes(0 if f else 255 for f in fundo))
    fechada = mascara.filter(ImageFilter.MaxFilter(FECHAMENTO)).filter(ImageFilter.MinFilter(FECHAMENTO))
    dentro = fechada.tobytes()
    for i in range(w * h):
        if fundo[i] and dentro[i]:
            fundo[i] = 0
    # Furos fechados do papel que mostram o fundo branco da imagem original
    for i in range(w * h):
        if not fundo[i]:
            r, g, b, _ = px[i % w, i // w]
            if min(r, g, b) >= 225 and max(r, g, b) - min(r, g, b) <= 15 and perto((r, g, b), cores, LIMIAR):
                fundo[i] = 1
    # limpa o halo de compressão colado ao fundo
    for _ in range(2):
        novos = [y * w + x for y in range(1, h - 1) for x in range(1, w - 1)
                 if not fundo[y * w + x]
                 and (fundo[y * w + x - 1] or fundo[y * w + x + 1] or fundo[(y - 1) * w + x] or fundo[(y + 1) * w + x])
                 and eh_fundo(px[x, y], LIMIAR_HALO)]
        for i in novos:
            fundo[i] = 1
    for i, f in enumerate(fundo):
        if f:
            px[i % w, i // w] = (0, 0, 0, 0)
    # recorta a área útil e centraliza num quadrado
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        lado = max(img.size)
        quadro = Image.new("RGBA", (lado, lado), (0, 0, 0, 0))
        quadro.alpha_composite(img, ((lado - img.size[0]) // 2, (lado - img.size[1]) // 2))
        img = quadro
    return img


def main():
    for jpg in sorted(p for p in (RAIZ / "originais").glob("*.*") if p.suffix.lower() in (".jpg", ".jpeg", ".png")):
        img = remover_fundo(Image.open(jpg))
        img = img.convert("RGBa").resize((TAMANHO, TAMANHO), Image.LANCZOS).convert("RGBA")
        destino = RAIZ / (jpg.stem + ".png")
        img.save(destino, optimize=True)
        alfa = img.getchannel("A").tobytes()
        print(f"{destino.name}: {alfa.count(0) / len(alfa):.0%} transparente")


if __name__ == "__main__":
    main()
