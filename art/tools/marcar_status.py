"""Atualiza o status de produção dos assets no _indice.json e nos arquivos de categoria.

Uso:  python art/tools/marcar_status.py
Edite MARCAS abaixo: id -> (status, observação ou "").
"""
import json
from pathlib import Path

SPECS = Path(__file__).resolve().parents[2] / "art" / "specs"
CEN = SPECS / "cenario"

ITENS = ["espada_longa", "adaga_elfica", "cajado_runico", "alaude_encantado", "machado_anao", "arco_longo", "lamina_corvo",
         "gibao_couro", "manto_viajante", "cota_malha", "placas", "amuleto_coragem", "insignia_corvo", "brinco_sabio",
         "anel_amizade", "pocao_cura", "tonico", "pergaminho_forca"]
FERRAMENTAS = ["corda", "lanterna", "tocha", "pa", "picareta", "gazuas", "kit_cura", "mapa", "bussola", "luneta", "chave",
               "carta", "martelo", "ervas", "armadilha"]
HEROIS = ["theo", "lyssa", "mira", "senna", "bram", "vera", "corin"]

MARCAS = {}
for i in ITENS:
    MARCAS["item_" + i] = ("integrado", "ícone no Mercado, Baú e Equipamento (e no mercador da rota)")
for f in FERRAMENTAS:
    MARCAS["fer_" + f] = ("entregue", "ainda não há item de jogo que use")
for h in HEROIS:
    MARCAS["token_" + h] = ("integrado", "só o estado 'parado' foi entregue; faltam andando, chamando, ferido, aflito e virtude")
MARCAS.update({
    "token_sombra": ("integrado", ""),
    "token_balao": ("integrado", "tira de 4 quadros sobre quem chama"),
    "token_base": ("entregue", "reserva para heróis sem miniatura"),
    "rec_provisoes": ("integrado", "botão de provisões do mercador da rota"),
    "rec_moedas": ("entregue", "veio uma imagem com as 3 variações; recortada em ouro_pilha_pequena/pilha_media/bolsa_cheia"),
    "livro_aberto": ("integrado", "mesa de fundo da tela do Livro (escurecida); entregue em 1536×1024 (3:2), não 16:9"),
    "livro_pagina_esq": ("integrado", "textura da página esquerda"),
    "livro_pagina_dir": ("integrado", "textura da página direita"),
    "livro_lombada": ("integrado", ""),
    "livro_borda_ornamental": ("integrado", "moldura interna das páginas (9-slice 40 px)"),
    "livro_capa_fechada": ("integrado", "ícone do botão Livro no hub"),
    "icone_mestre": ("integrado", "ícone do projeto (Godot) e base do .ico provisório do Windows"),
    "icone_android_principal": ("integrado", "launcher_icons/main_192x192"),
    "icone_android_frente": ("integrado", "launcher_icons/adaptive_foreground_432x432 (símbolo reduzido à zona segura)"),
    "icone_android_fundo": ("integrado", "launcher_icons/adaptive_background_432x432"),
    "icone_android_mono": ("integrado", "launcher_icons/adaptive_monochrome_432x432"),
    "dado_d20_faces": ("integrado", "folha única com as 20 faces recortada em art/dice/d20_face_01..20; desvios a corrigir pelo artista: ponto só no 6 e 9 (veio no 7, 8 e 9, faltou no 6), vizinhos não seguem um d20 real"),
    "cena_par_bram_vera_sinergia": ("integrado", "cartão do resultado (sinergia e Ação de Vínculo de Vera e Bram); entregue só a versão de vitória"),
    "cena_par_lyssa_mira_sinergia": ("integrado", "cartão do resultado (sinergia de Lyssa e Mira)"),
    "cena_par_lyssa_theo_conflito": ("integrado", "cartão do resultado (conflito de Theo e Lyssa)"),
    "quadro_avisos": ("integrado", "veio como cena (quadro na praça); recortado o quadro com telhado e usado como moldura 9-slice do painel"),
    "cartaz_missao": ("integrado", "papel de cada pedido (9-slice 40); o furo de prego da arte substitui o prego desenhado"),
    "cartaz_selos": ("integrado", "comum, urgente (último dia), pessoal (missão pessoal) e lendário no canto do cartaz; o urgente veio aplicado sobre um cartaz e foi recortado só o lacre"),
    "cartaz_prego": ("entregue", "o furo da arte do cartaz já faz o papel; usado só se o cartaz não tiver arte"),
    "cartaz_vazio": ("integrado", "quadro sem pedidos"),
    "cartaz_arrancado": ("entregue", "tira de 4 quadros; o arrancar ainda é animado por código"),
    "restos_papel": ("entregue", "6 peças recortadas em art/guild/restos_1..6; ainda não espalhadas no quadro"),
    "cena_acao_vinculo": ("integrado", "cartão do resultado"),
    "cena_aflicao": ("integrado", "cartão do resultado"),
    "cena_cansaco": ("integrado", "cartão do resultado"),
    "cena_conflito": ("integrado", "cartão do resultado"),
    "cena_destaque_carisma": ("integrado", "cartão do resultado"),
    "cena_destaque_conhecimento": ("integrado", "cartão do resultado"),
    "cena_destaque_destreza": ("integrado", "cartão do resultado"),
    "cena_destaque_forca": ("integrado", "cartão do resultado"),
    "cena_destaque_resistencia": ("integrado", "cartão do resultado"),
    "cena_laco_lendario": ("integrado", "cartão do resultado"),
    "cena_sinergia": ("integrado", "cartão do resultado"),
    "cena_virtude": ("integrado", "cartão do resultado"),
    "cena_poderes": ("integrado", "cartão do resultado"),
    "cena_preparacao": ("integrado", "cartão do resultado"),
    "cena_fome": ("integrado", "cartão do resultado"),
    "cena_desgaste": ("integrado", "cartão do resultado"),
    "cena_sorte": ("integrado", "cartão do resultado"),
    "cena_azar": ("integrado", "cartão do resultado"),
    "cena_sozinho": ("integrado", "cartão do resultado"),
    "cena_povo": ("integrado", "cartão do resultado"),
    "btn_madeira": ("integrado", "só o estado normal foi entregue; hover, pressionado e desativado são modulação por código (UIKit.style_button)"),
    "btn_pergaminho": ("integrado", "só o estado normal; botões Voltar e Fechar"),
    "btn_escolha": ("integrado", "só o estado normal; escolhas de evento, bastidor, decisão, ultimato e rótulo; sem o cadeado do desativado"),
    "btn_perigo": ("integrado", "só o estado normal; botão Enfrentar o alvo"),
    "btn_medalhao": ("integrado", "só o estado normal; botões ◀ ▶ ☰"),
    "btn_barra_hub": ("integrado", "só o estado normal; correntes cortadas, usada só a placa nos botões do hub"),
    "btn_selo_alvo": ("integrado", "ícone do botão Enfrentar no mapa (sem a animação de carimbo)"),
    "btn_icones_acao": ("integrado", "folha 4x7 com rótulos desalinhados: recortada pelo desenho (art/tools/preparar_botoes.py); sobraram 4 desenhos sem uso"),
    "btn_tema": ("integrado", "feito por código em UIKit.style_button, não como .tres"),
    "icone_windows": ("planejado", "usando .ico provisório gerado da arte mestre (art/icon/icone.ico); falta a versão redesenhada em 16–32 px"),
})


def aplicar(a: dict) -> bool:
    if a["id"] not in MARCAS:
        return False
    st, obs = MARCAS[a["id"]]
    a["status"] = st
    if obs:
        a["observacoes"] = obs
    else:
        a.pop("observacoes", None)
    return True


def main():
    n = 0
    for f in list(CEN.glob("*.json")) + list((SPECS / "cenas").glob("*.json")) + [SPECS / "tokens_herois.json"]:
        if f.name.startswith("_"):
            continue
        data = json.loads(f.read_text(encoding="utf-8"))
        mudou = False
        for g in data.get("grupos", []):
            for a in g["assets"]:
                mudou |= aplicar(a)
        if mudou:
            f.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    idx_path = CEN / "_indice.json"
    idx = json.loads(idx_path.read_text(encoding="utf-8"))
    for a in idx["assets"]:
        n += aplicar(a)
    resumo = {}
    for a in idx["assets"]:
        resumo[a["status"]] = resumo.get(a["status"], 0) + 1
    idx["resumo_por_status"] = dict(sorted(resumo.items()))
    idx_path.write_text(json.dumps(idx, ensure_ascii=False, indent=2) + "\n", encoding="utf-8", newline="\n")
    print(n, "assets marcados;", idx["resumo_por_status"])


if __name__ == "__main__":
    main()
