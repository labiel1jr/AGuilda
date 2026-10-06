"""Prepara os retratos gerados (JPEG 1024x1024 com fundo branco ou xadrez falso)
para o jogo: remove o fundo a partir das bordas e salva PNG RGBA 256x256.

Uso:  python art/tools/preparar_retratos.py
Entrada: art/portraits/originais/<id>.jpg   Saída: art/portraits/<id>.png
         art/geralimagem/originais/inicial.jpg -> art/geralimagem/titulo.png
"""
from collections import deque
from pathlib import Path

from PIL import Image

RAIZ = Path(__file__).resolve().parents[1]
TAMANHO = 256


def eh_fundo(r, g, b):
    # branco e cinza claro do xadrez falso: claros e sem saturação
    return min(r, g, b) >= 185 and max(r, g, b) - min(r, g, b) <= 24


def eh_borda_clara(r, g, b):
    # halo de compressão JPEG em volta do recorte
    return min(r, g, b) >= 160 and max(r, g, b) - min(r, g, b) <= 34


def remover_fundo(img: Image.Image) -> Image.Image:
    img = img.convert("RGBA")
    w, h = img.size
    px = img.load()
    fundo = bytearray(w * h)
    fila = deque()
    for x in range(w):
        fila.append((x, 0))
        fila.append((x, h - 1))
    for y in range(h):
        fila.append((0, y))
        fila.append((w - 1, y))
    while fila:
        x, y = fila.popleft()
        i = y * w + x
        if fundo[i]:
            continue
        r, g, b, _ = px[x, y]
        if not eh_fundo(r, g, b):
            continue
        fundo[i] = 1
        if x > 0: fila.append((x - 1, y))
        if x < w - 1: fila.append((x + 1, y))
        if y > 0: fila.append((x, y - 1))
        if y < h - 1: fila.append((x, y + 1))
    # duas passadas para tirar o halo claro colado ao fundo
    for _ in range(2):
        novos = []
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                i = y * w + x
                if fundo[i]:
                    continue
                if fundo[i - 1] or fundo[i + 1] or fundo[i - w] or fundo[i + w]:
                    r, g, b, _ = px[x, y]
                    if eh_borda_clara(r, g, b):
                        novos.append(i)
        for i in novos:
            fundo[i] = 1
    for i, f in enumerate(fundo):
        if f:
            x, y = i % w, i // w
            px[x, y] = (0, 0, 0, 0)
    return img


def main():
    origem = RAIZ / "portraits" / "originais"
    for jpg in sorted(origem.glob("*.jpg")):
        img = remover_fundo(Image.open(jpg))
        # reduz em alfa pré-multiplicado para não sujar a borda de preto
        img = img.convert("RGBa").resize((TAMANHO, TAMANHO), Image.LANCZOS).convert("RGBA")
        destino = RAIZ / "portraits" / (jpg.stem + ".png")
        img.save(destino, optimize=True)
        transparente = sum(1 for a in img.getchannel("A").getdata() if a == 0) / (TAMANHO * TAMANHO)
        print(f"{destino.name}: {TAMANHO}x{TAMANHO}, {transparente:.0%} transparente")

    tela = RAIZ / "geralimagem" / "originais" / "inicial.jpg"
    if tela.exists():
        destino = RAIZ / "geralimagem" / "titulo.png"
        Image.open(tela).convert("RGB").save(destino, optimize=True)
        print(f"{destino.name}: {Image.open(destino).size}")


if __name__ == "__main__":
    main()
