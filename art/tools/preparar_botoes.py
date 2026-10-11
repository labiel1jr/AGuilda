"""Recorta as peças de botão e os ícones de ação entregues em art/ArtesEmGeral (btn_*.jpg).

Uso:  python art/tools/preparar_botoes.py
Só o estado normal foi entregue; hover, pressionado e desativado são feitos por código
(UIKit, modulação da StyleBoxTexture). Saída em art/ui/.
"""
from pathlib import Path
from PIL import Image
from preparar_assets import tirar_fundo, caber, ROOT, SRC

UI = ROOT / "art" / "ui"
ICONES = UI / "icones"

# peça -> altura final da textura (px) — pequena para o 9-slice caber em botões de ~40 px
PECAS = {"madeira": 64, "perigo": 64, "pergaminho": 64, "escolha": 48, "medalhao": 96, "barra_hub": 64}

# folha de ícones: (linha, coluna) numa grade de 4 x 7; os rótulos da folha vieram desalinhados,
# então a correspondência é pelo desenho. Sobraram: tábuas em X (1,1), espada (2,1), pergaminho (2,2), seta (2,6).
LINHAS = [(0, 135), (140, 262), (285, 378), (400, 515)]
ICONE = {
    "voltar": (0, 0), "continuar": (0, 1), "confirmar": (0, 2), "comprar": (0, 3), "vender": (0, 4),
    "equipar": (0, 5), "remover": (0, 6), "construir": (1, 0), "treinar": (1, 2), "assistir_cena": (1, 3),
    "conversar": (1, 4), "seguir_viagem": (1, 6), "enfrentar": (2, 0), "comecar_capitulo": (2, 3),
    "abrir_guilda": (3, 1), "fechar": (3, 2), "ver_detalhes": (3, 3), "opcoes": (3, 4), "sair": (3, 5),
    "novo_jogo": (3, 6),
}


def recortar(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def main():
    UI.mkdir(parents=True, exist_ok=True)
    ICONES.mkdir(parents=True, exist_ok=True)
    for peca, alt in PECAS.items():
        img = tirar_fundo(Image.open(SRC / f"btn_{peca}.jpg"))
        if peca == "barra_hub":
            img = img.crop((0, 145, img.width, img.height))   # só a placa, sem as correntes
        img = recortar(img)
        out = img.resize((round(img.width * alt / img.height), alt), Image.LANCZOS)
        nome = "barra" if peca == "barra_hub" else peca
        out.save(UI / f"btn_{nome}_normal.png", optimize=True)
        print(nome, out.size)
    selo = caber(recortar(tirar_fundo(Image.open(SRC / "btn_selo_alvo.jpg"))), (128, 128), True)
    selo.save(UI / "selo_alvo.png", optimize=True)
    folha = tirar_fundo(Image.open(SRC / "btn_icones_acao.jpg"))
    larg = folha.width / 7
    for nome, (l, c) in ICONE.items():
        y0, y1 = LINHAS[l]
        cel = recortar(folha.crop((round(c * larg), y0, round((c + 1) * larg), y1)))
        caber(cel, (48, 48), True).save(ICONES / f"{nome}.png", optimize=True)
    print(len(ICONE), "ícones")


if __name__ == "__main__":
    main()
