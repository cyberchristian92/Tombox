# Design v2 do Tombox (substitui as seções visuais do design-ui.md)

Maquete de referência: `docs/design/direcao-visual-v2.png` (Início, Sala e Ficha do bem) e o HTML em `docs/design/direcao-visual-v2.html`. Siga a maquete o mais fielmente possível: medidas, cores, fontes e hierarquia.

O usuário rejeitou a versão anterior porque estava "com cara de IA": tudo arredondado, cartões para tudo, chips coloridos, sombras, botão circular flutuante. A v2 usa um vocabulário do próprio mundo do patrimônio público: a plaqueta de alumínio gravada e o livro de tombo (registro em linhas).

A estrutura de telas, a navegação e o conteúdo do `design-ui.md` continuam valendo. Mudam a linguagem visual e alguns componentes.

## 1. Ideia central

- **Plaqueta:** o número de tombamento sempre aparece desenhado como plaqueta de alumínio. É o único elemento chamativo do app.
  - pequena nas listas;
  - grande no topo da Ficha do bem;
  - sobre a câmera, como etiqueta de cada leitura.
- **Livro de tombo:** listas em linhas sobre fundo branco, separadas por divisórias finas, ocupando a largura toda. Nada de um cartão por item.

## 2. Tokens

### Cores
| Nome | Hex | Uso |
|---|---|---|
| tinta | `#13365C` | barra superior, botão principal, aba ativa, links (vem do brand.json: primária) |
| papel | `#F2F4F6` | fundo das telas |
| branco | `#FFFFFF` | fundo das listas e blocos |
| grafite | `#1F2933` | texto principal |
| cinza | `#5B6672` | texto secundário |
| linha | `#D6DCE1` | divisórias e bordas |
| alumínio | `#DDE3E8`, borda `#A9B4BE`, rebite `#B7C1CA` | plaqueta |
| conferido | `#2F7D4F` | status |
| outra sala | `#B5781A` | status |
| sem cadastro / não localizado | `#B3261E` | status |
| pendente | `#98A2AD` | status |
| dourado da marca | `#C9A227` | só no selo "TJPA" da barra superior |

Modo escuro: papel `#11161C`, branco `#1A2129`, grafite `#E6EAEE`, cinza `#9AA5B1`, linha `#2C3640`, tinta `#7FA6D6` para links e aba ativa; a barra superior continua azul escura `#0F2B4A`; a plaqueta continua alumínio (é um objeto físico).

### Tipografia
- **Barlow** (Regular 400, Medium 500, SemiBold 600, Bold 700): texto em geral.
- **Barlow Semi Condensed SemiBold:** títulos de tela e de seção.
- **Barlow Condensed Bold:** número da plaqueta e contadores ("7/18").
- Todas embutidas em `assets/fonts` (licença OFL; registrar em BIBLIOTECAS.md).
- Algarismos tabulares em todo número (`FontFeature.tabularFigures()`).
- Escala: título de tela 26, título da ficha 22, seção 18, linha principal 15 a 17, secundário 13 a 15, navegação 12. Altura de linha 1,3 para texto corrido.
- Proibido: rótulos em maiúsculas espaçadas, uma palavra destacada em cor diferente dentro de um título, setas "→" em botões.

### Forma e espaço
- Raio: 4 em botões, blocos e plaqueta grande; 3 na plaqueta pequena e no carimbo; 2 em barras de progresso; 6 no botão Conferir da barra inferior; 0 nas linhas de lista. Nada acima de 6, exceto a borda superior de folhas inferiores (12).
- Sem sombras. Separação por divisórias de 1 px na cor linha.
- Espaçamento 4, 8, 12, 16, 20, 24. Margem lateral 16. Linhas de lista com 12 de padding vertical.
- Ícones de traço fino (Material Symbols Outlined com peso 300, ou Lucide), 22 px.

## 3. Componentes

- **Plaqueta (pequena):** fundo alumínio, borda de 1 px, raio 3, padding 3×8, dois rebites (círculos de 5 px) antes e depois do número, número em Barlow Condensed Bold 17 com espaçamento de letra 0,06 em.
- **Plaqueta (grande):** largura total, 92 de altura, raio 4, rebites de 9 px nas extremidades, número em Barlow Condensed Bold 52 com espaçamento 0,08 em e, abaixo, "TJPA, patrimônio" em 11 (texto vem do brand.json; no preset neutro, só "Patrimônio").
- **Barra segmentada de situação:** altura 10, raio 2, segmentos conferido, outra sala, sem cadastro, pendente, proporcionais.
- **Legenda de situação:** linhas com quadrado de 10 px da cor, rótulo e número alinhado à direita em SemiBold, divisórias entre linhas.
- **Linha de sala:** nome em SemiBold 15 (uma linha, reticências), andar em 13 cinza, barra de progresso de 4 px abaixo, contador "7/18" em Barlow Condensed à direita.
- **Linha de bem:** plaqueta pequena à esquerda; descrição em 15 (até 2 linhas) e categoria em 13 cinza; à direita, marcador de situação (quadrado vazado cinza para pendente, cheio na cor para os demais). Miniatura da foto, quando houver, entra à direita do texto, 44×44, raio 2.
- **Carimbo:** borda de 1,5 px na cor da situação, raio 3, fundo branco, ícone de traço, título em SemiBold na cor da situação e linha de detalhe em cinza ("27/10 às 10:42, por Rosilene Silva").
- **Lista de dados (ficha):** rótulo cinza numa coluna de 118 px e valor em Medium, linhas com divisória.
- **Linha do tempo:** coluna de data e hora em 13 cinza, traço vertical fino, marcador quadrado de 7 px, texto do evento e detalhe ("assinatura verificada").
- **Botão principal:** 48 de altura, raio 4, fundo tinta, texto branco SemiBold 16, ícone de traço opcional à esquerda.
- **Abas:** texto com contagem em SemiBold, sublinhado de 2 px na aba ativa, divisória de 1 px abaixo.
- **Barra inferior:** fundo branco, divisória superior, 5 posições; "Conferir" é um botão retangular azul com raio 6 dentro da barra (ícone + texto), não um círculo flutuante.
- **Barra de ações da ficha:** 4 ações iguais separadas por divisórias verticais, ícone acima do texto.
- **Estado vazio:** ícone de traço grande em cinza, uma frase direta e um botão principal. Sem ilustração.
- **Carregando:** esqueleto em linhas cinza claro com as mesmas medidas da lista. Nunca mostrar zeros enquanto carrega.

## 4. Telas

- **Início:**
  - barra com unidade e selo;
  - título com o nome do prédio ou unidade e uma frase de contexto ("15 salas e 300 bens. Conferência iniciada em 27 de outubro.");
  - barra segmentada e legenda;
  - bloco "Em andamento" com a sala e o botão "Continuar conferência", ou "Próxima sala" com "Começar conferência";
  - seção Salas em linhas;
  - sem saudação nem cartões de número.
- **Locais:** árvore em linhas com recuo por nível (prédio › andar › sala), cada linha com contador e barrinha.
- **Sala:** migalhas em texto simples ("Breves, Fórum Juiz Vicente, Térreo"), título, responsável e progresso, barra, abas, linhas de bem e botão fixo "Conferir esta sala" no rodapé.
- **Conferir:**
  - caixas sobre as plaquetas com contorno retangular de 2 px na cor da situação, sem cantos arredondados;
  - etiqueta no canto superior esquerdo, com o número em Barlow Condensed;
  - topo translúcido escuro com sala e "12 de 18";
  - folha inferior com raio 12 só no topo;
  - confirmação com toast retangular.
- **Bens:** busca em campo retangular (raio 4), filtros como abas roláveis ou uma linha de seletores simples (não pílulas coloridas), lista em linhas.
- **Ficha:**
  - topo azul com plaqueta grande, descrição e categoria com local;
  - carimbo da situação;
  - lista de dados;
  - histórico em linha do tempo;
  - barra de ações fixa.
- **Mais:** lista em linhas agrupadas por título de seção (texto normal, não maiúsculo), ícone de traço, texto em grafite (contraste AA).

## 5. Textos

- Frases curtas e diretas, sem saudação, sem exclamação.
- Separar informações com vírgula ou ponto, não com "·".
- Números no padrão brasileiro (`intl`, pt_BR).

## 6. Verificação

Capturas de todas as telas em 360×800, claro e escuro, comparadas com a maquete. Se uma tela tiver cartão arredondado com sombra, pílula colorida, botão circular flutuante, overflow ou texto cortado, refazer.
