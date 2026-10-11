"""Prepara as peças do pergaminho do Mapa Mágico (art/ArtesEmGeral/mapa_*.jpg).

Uso:  python art/tools/preparar_mapa.py
Saída em art/map/parchment/ (destinos de art/specs/cenario/mapa_pergaminho.json):
  - folha: o papel inteiro; o fundo escuro em volta vira transparente;
  - borda, vincos, vinheta: camadas de "multiplicar" entregues sobre branco; viram tinta
    com transparência pela luminosidade (branco = invisível), desenhadas por cima de tudo;
  - cartela, escala, rosa_ventos: peças avulsas com o fundo branco removido.
"""
from PIL import Image, ImageOps
from preparar_assets import tirar_fundo, caber, ROOT, SRC

OUT = ROOT / "art" / "map" / "parchment"


def folha(img: Image.Image) -> Image.Image:
    rgb = img.convert("RGB")
    a = rgb.convert("L").point(lambda v: 0 if v < 28 else (255 if v > 60 else (v - 28) * 8))
    out = rgb.convert("RGBA")
    out.putalpha(a)
    return out.crop(out.getbbox())


def multiplicar(img: Image.Image, forca: float = 1.0) -> Image.Image:
    """Camada de multiplicar → RGBA: a cor fica, a transparência vem do quanto escurece o branco."""
    rgb = img.convert("RGB")
    lum = rgb.convert("L")
    alpha = ImageOps.invert(lum).point(lambda v: min(255, int(v * 1.6 * forca)))
    tinta = rgb.point(lambda v: int(v * 0.55))
    tinta.putalpha(alpha)
    return tinta


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    f = folha(Image.open(SRC / "mapa_folha.jpg"))
    f.thumbnail((1600, 1600), Image.LANCZOS)
    f.save(OUT / "folha.png", optimize=True)
    for nome, forca, tam in (("borda", 1.0, (1168, 784)), ("vincos", 0.8, (1168, 784)), ("vinheta", 0.7, (584, 392))):
        m = multiplicar(Image.open(SRC / f"mapa_{nome}.jpg"), forca)
        m.resize(tam, Image.LANCZOS).save(OUT / f"{nome}.png", optimize=True)
    r = multiplicar(Image.open(SRC / "mapa_rosa_ventos.jpg"), 3.0)
    caber(r.crop(r.getbbox()), (160, 200), False).save(OUT / "rosa_ventos.png", optimize=True)
    for nome, alvo, tam in (("cartela", "cartela", (420, 160)), ("escala", "escala", (240, 48))):
        peca = tirar_fundo(Image.open(SRC / f"mapa_{nome}.jpg"))
        peca = peca.crop(peca.getbbox())
        caber(peca, tam, False).save(OUT / f"{alvo}.png", optimize=True)
    for p in sorted(OUT.glob("*.png")):
        print(p.name, Image.open(p).size)


if __name__ == "__main__":
    main()
