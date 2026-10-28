#!/usr/bin/env python3
"""
Gera dados sintéticos de demonstração para o Tombox (Hackathon TJPA 2026).
Gera uma unidade sintética com 15 salas e cerca de 300 bens, incluindo
de propósito casos de teste para o relatório de qualidade (tombamento com letra 'O',
duplicados, formatos variados de sala e colunas extras).
"""

import os
import csv
import random
from faker import Faker

fake = Faker('pt_BR')
Faker.seed(20261027)
random.seed(20261027)

SALAS_BASE = [
    ("Comarca de Breves", "Fórum Juiz Vicente", "Térreo", "Sala 101 - Protocolo"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "Térreo", "Sala 102 - Secretaria"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "Térreo", "Sala 103 - Atendimento ao Cidadão"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "1º Andar", "Sala 201 - Gabinete da Vara Única"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "1º Andar", "Sala 202 - Assessoria Jurídica"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "1º Andar", "Sala 203 - Sala de Audiências A"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "1º Andar", "Sala 204 - Sala de Audiências B"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "1º Andar", "Sala 205 - Cejusc e Conciliação"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "2º Andar", "Sala 301 - Cartório Judicial"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "2º Andar", "Sala 302 - Sala dos Oficiais de Justiça"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "2º Andar", "Sala 303 - Arquivo Setorial"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "2º Andar", "Sala 304 - Núcleo de TI e Suporte"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "Anexo Administrativo", "Sala 401 - Almoxarifado"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "Anexo Administrativo", "Sala 402 - Copa e Convivência"),
    ("Comarca de Breves", "Fórum Juiz Vicente", "Anexo Administrativo", "Sala 403 - Sala de Treinamento"),
]

ITENS_POR_CATEGORIA = {
    "Equipamentos de Informática": [
        ("Computador Desktop", ["Dell", "Lenovo", "HP"], ["OptiPlex 7090", "ThinkCentre M70q", "ProDesk 400"]),
        ("Monitor LED 24\"", ["Dell", "LG", "Samsung"], ["P2419H", "24BL650", "T350"]),
        ("Notebook Corporativo", ["Dell", "Lenovo"], ["Latitude 3420", "ThinkPad E14"]),
        ("Impressora Multifuncional", ["Brother", "HP", "Epson"], ["DCP-L5652DN", "LaserJet Pro 4103", "EcoTank L3250"]),
        ("Nobreak 1200VA", ["APC", "SMS", "Ragtech"], ["Back-UPS", "Manager III", "Easy Way"]),
        ("Switch de Rede 24p", ["Cisco", "HP Aruba", "D-Link"], ["Catalyst 2960", "Instant On 1930", "DGS-1210"]),
    ],
    "Mobiliário": [
        ("Mesa em L com Gaveteiro", ["Cavaletti", "Flexform", "Mareli"], ["Linha Corp", "Operativa Plus", "Master L"]),
        ("Cadeira Giratória Ergonômica", ["Cavaletti", "Flexform", "Plaxmetal"], ["Yon 40101", "Uni Me", "Brizza"]),
        ("Armário Alto 2 Portas", ["Pandim", "W3", "Cavaletti"], ["Aço PA-120", "Arquivamento Luxo", "Corp 160"]),
        ("Arquivo de Aço 4 Gavetas", ["Pandim", "W3"], ["Gaveteiro 4G", "Arquivar Standard"]),
        ("Longarina 3 Lugares", ["Plaxmetal", "Cavaletti"], ["Aeroporto 3L", "Espera Standard"]),
        ("Mesa de Reunião Redonda", ["Flexform", "Mareli"], ["Meeting 120", "Linha Direct"]),
    ],
    "Aparelhos e Eletrodomésticos": [
        ("Aparelho de Ar Condicionado Split 18.000 BTU", ["Springer Midea", "LG", "Daikin"], ["Inverter AirV", "Dual Inverter", "EcoSwing"]),
        ("Bebedouro de Coluna Inox", ["IBBL", "Esmaltec", "Libell"], ["PDF300", "Bebedouro Coluna", "Press"]),
        ("Cafeteira Elétrica Industrial", ["Mondial", "Britânia", "Marchesoni"], ["Master Inox", "Café Fácil", "CF-06"]),
        ("Fragmentadora de Papel", ["Menno", "Aurora"], ["Corte Cruzado 12fl", "AS1219CE"]),
    ],
}

def gerar_dados(caminho_saida):
    os.makedirs(os.path.dirname(caminho_saida), exist_ok=True)
    linhas = []
    
    tombamento_seq = 10001
    tombamentos_gerados = []

    for i in range(300):
        comarca, predio, andar, sala = random.choice(SALAS_BASE)
        local_caminho = f"{comarca} / {predio} / {andar} / {sala}"

        # Injeta de propósito variações de escrita de sala para testar a normalização
        if i == 14:
            sala_base = SALAS_BASE[0]  # Sala 101 - Protocolo (Térreo)
            local_caminho = f"{sala_base[0]} / {sala_base[1]} / {sala_base[2]} / SL 101"
        elif i == 28:
            sala_base = SALAS_BASE[1]  # Sala 102 - Secretaria (Térreo)
            local_caminho = f"{sala_base[0]} / {sala_base[1]} / {sala_base[2]} / sala 102"
        elif i == 45:
            sala_base = SALAS_BASE[2]  # Sala 103 - Atendimento ao Cidadão (Térreo)
            local_caminho = f"{sala_base[0]} / {sala_base[1]} / {sala_base[2]} / Sala103"

        categoria = random.choice(list(ITENS_POR_CATEGORIA.keys()))
        descricao_base, fabricantes, modelos = random.choice(ITENS_POR_CATEGORIA[categoria])
        fabricante = random.choice(fabricantes)
        modelo = random.choice(modelos)
        descricao = f"{descricao_base} {fabricante} {modelo}"

        tombamento = str(tombamento_seq).zfill(6)
        tombamentos_gerados.append(tombamento)

        # Injeta de propósito problema: letra 'O' no lugar de zero (para o teste de normalização)
        if i == 5:
            tombamento_export = tombamento.replace("0", "O", 1)
        elif i == 19:
            tombamento_export = f"{tombamento[:3]}-{tombamento[3:]}" # formato com hífen
        elif i == 33:
            tombamento_export = f"{tombamento[:2]}.{tombamento[2:]}" # formato com ponto
        else:
            tombamento_export = tombamento

        matricula = f"TJ-{random.randint(10000, 99999)}"
        num_serie = f"{fabricante[:3].upper()}-{random.randint(1000000, 9999999)}"
        
        ano_aquisicao = random.choice([2019, 2020, 2021, 2022, 2023, 2024])
        valor_estimado = f"R$ {random.uniform(350.0, 6500.0):.2f}".replace('.', ',')

        linhas.append({
            "tombamento": tombamento_export,
            "descricao": descricao,
            "local": local_caminho,
            "categoria": categoria,
            "responsavel_matricula": matricula,
            "numero_serie": num_serie,
            "fabricante": fabricante,
            "modelo": modelo,
            "ano_aquisicao": ano_aquisicao,
            "valor_estimado": valor_estimado,
        })
        tombamento_seq += 1

    # Injeta de propósito 2 duplicados (mesmo tombamento reimportado com atualização de local ou descrição)
    duplicado_1 = dict(linhas[10])
    duplicado_1["descricao"] = duplicado_1["descricao"] + " (Atualizado)"
    linhas.append(duplicado_1)

    duplicado_2 = dict(linhas[50])
    duplicado_2["local"] = f"Comarca de Breves / Fórum Juiz Vicente / Térreo / Sala 101 - Protocolo"
    linhas.append(duplicado_2)

    # Escreve o CSV usando ';' como separador e UTF-8
    campos = [
        "tombamento",
        "descricao",
        "local",
        "categoria",
        "responsavel_matricula",
        "numero_serie",
        "fabricante",
        "modelo",
        "ano_aquisicao",
        "valor_estimado",
    ]

    with open(caminho_saida, mode="w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=campos, delimiter=";")
        writer.writeheader()
        for l in linhas:
            writer.writerow(l)

    print(f"Sucesso! Gerados {len(linhas)} bens sintéticos em: {caminho_saida}")

if __name__ == "__main__":
    destino = os.path.abspath(os.path.join(
        os.path.dirname(__file__), "..", "app", "assets", "demo", "unidade_demo.csv"
    ))
    gerar_dados(destino)
