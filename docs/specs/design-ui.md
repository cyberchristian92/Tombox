# Design do app Tombox, tela por tela

Referências: as telas do Homebox (painel com estatísticas, cartões de item com foto, locais em árvore, ficha completa do item, etiquetas com cor) e o fluxo em etapas do Homebox Companion (escolher local, capturar, revisar, confirmar). Ideias, não código.

O app é uma ferramenta de campo: usado em pé, com uma mão, em sala com pouca luz, por pessoas que não são de TI. Cada tela tem uma ação principal óbvia.

## 1. Fundamentos visuais

- **Cores de marca:** vêm do `brand.json` (primária azul institucional, secundária dourada). Usadas em barra superior, botão principal e destaques. Nunca usadas para status.
- **Cores de status** (fixas, iguais em todo o app, com ícone junto para não depender só da cor):
  - encontrado: verde `#1E8E3E`, ícone de check;
  - outra sala: âmbar `#F29900`, ícone de setas;
  - não cadastrado / não localizado: vermelho `#D93025`, ícone de alerta;
  - pendente: cinza `#80868B`, ícone de relógio.
- **Superfícies:** fundo claro levemente acinzentado, cartões brancos com borda sutil e raio de 16; quase sem sombra. Modo escuro completo.
- **Tipografia:** Inter, embutida no app (funciona offline). Número de tombamento sempre em fonte monoespaçada (JetBrains Mono ou Roboto Mono), maior e em negrito, porque é a informação que o servidor procura com o olho.
- **Espaçamento:** escala 4, 8, 12, 16, 24, 32. Margem lateral de 16.
- **Ícones:** Material Symbols Rounded.
- **Alvos de toque:** mínimo de 48 dp; botões principais com 56 dp de altura.
- **Movimento:** transições curtas (150 a 250 ms); vibração e som curto opcional ao confirmar leitura.

## 2. Componentes

- **CartaoEstatistica:** ícone, número grande, rótulo, variação opcional ("+12 hoje").
- **CartaoBem:** miniatura da foto (ou ícone da categoria se não houver foto), tombamento em mono, descrição em até 2 linhas, chip do local em forma de caminho curto ("Térreo › Sala 103"), chip de situação com cor e ícone.
- **CartaoLocal:** nome, caminho acima em texto pequeno, progresso circular com "12/18", contagem de divergências se houver.
- **Migalhas (breadcrumb):** "Breves › Fórum › Térreo › Sala 103", cada parte tocável.
- **ChipStatus** e **ChipCategoria** (categoria com cor própria, como as etiquetas do Homebox).
- **EstadoVazio:** ícone grande, uma frase, uma ação ("Nenhuma unidade ainda. Importar CSV").
- **BarraBusca** com filtros em chips logo abaixo.
- **CabecalhoSecao:** título e "Ver tudo".
- **IndicadorSync:** ícone na barra superior com três estados (sincronizado, pendente com número, sem outros aparelhos), que abre a tela de Sincronização.

## 3. Navegação

- **Barra inferior com 5 posições:** Início, Locais, **Conferir** (botão central maior, elevado, com ícone de câmera), Bens, Mais.
- **Barra superior compacta:** nome da unidade ativa (toque troca de unidade), IndicadorSync e acesso à busca.
- Voltar sempre previsível; nenhuma tela sem saída.

## 4. Telas

### 4.1 Início (painel)
1. Unidade ativa e saudação curta.
2. Grade 2×2 de CartaoEstatistica: Bens, Conferidos (% e número), Divergências abertas, Salas pendentes.
3. Barra de progresso geral da unidade.
4. Cartão "Continuar conferência": última sala em andamento, progresso e botão "Continuar".
5. "Divergências recentes": 3 itens com ChipStatus e "Ver tudo".
6. "Últimos conferidos": carrossel horizontal de CartaoBem com foto.
7. "Locais": os prédios ou andares da unidade em CartaoLocal.
8. Sem unidade: EstadoVazio com "Importar CSV" e "Usar dados de demonstração".

### 4.2 Locais
- Árvore expansível: comarca › prédio › andar › sala, cada nível com contagem de bens e progresso.
- Busca de sala por nome ou número.
- **Detalhe da sala:**
  - cabeçalho com migalhas, nome da sala em duas linhas se precisar (nunca cortado), progresso circular e responsável;
  - botão principal "Conferir esta sala";
  - abas: Pendentes, Conferidos, De outra sala, Divergências, cada uma com contagem;
  - lista de CartaoBem;
  - ação secundária "QR da sala" (para imprimir e colar na porta).

### 4.3 Conferir (câmera)
1. Se aberto pela barra inferior sem sala escolhida: folha "Em qual sala você está?" com busca, salas recentes e a opção "Detectar pela leitura".
2. Câmera em tela cheia.
3. Topo translúcido: nome da sala, migalhas e "12 de 18" com barra fina.
4. Caixas coloridas com ícone e o tombamento sobre cada plaqueta.
5. Ao confirmar: vibração, toast curto com tombamento e descrição ("010234 · Monitor Dell 24 ✓").
6. Leitura provável: cartão flutuante com a descrição e a foto do bem candidato, botões "É este" e "Não é".
7. Folha inferior arrastável:
   - recolhida: três contadores coloridos (encontrados, outra sala, não cadastrados) e o último lido;
   - expandida: abas Lidos, Faltando, Outra sala.
8. Controles: lanterna, modo uma plaqueta, busca manual, trocar sala.
9. Sugestão automática de sala: se a maioria das leituras for de outra sala, aviso "Parece que você está na Sala 204. Trocar?".
10. "Fechar sala" no topo, com resumo antes de confirmar.

### 4.4 Bens
- BarraBusca por tombamento, descrição ou número de série.
- Filtros em chips: situação, estado, categoria, local.
- Alternar lista e grade; ordenar por tombamento, descrição ou última conferência.
- Lista com CartaoBem; rolagem fluida com centenas de itens.

### 4.5 Ficha do bem (passaporte)
1. Galeria: foto principal grande, miniaturas abaixo; tocar abre em tela cheia.
2. Tombamento em mono grande com botão de copiar; ChipStatus e ChipCategoria.
3. Descrição.
4. Local atual em migalhas tocáveis; se estiver fora do lugar, aviso com o local esperado.
5. Seções recolhíveis: Identificação (número de série, fabricante, modelo), Responsabilidade (matrícula do responsável), Conservação (estado atual e histórico).
6. Linha do tempo de eventos: ícone por tipo, quem (nome e impressão digital da chave), quando, aparelho e selo "assinatura verificada".
7. Ações fixas no rodapé: Registrar estado, Tirar foto, Observação, Mover para outra sala.

### 4.6 Bem novo (fluxo em etapas, no estilo do Companion)
Indicador de etapas no topo: Local › Fotos › Revisar › Confirmar.
1. Local já preenchido com a sala atual.
2. Fotos do bem e da etiqueta do fabricante.
3. Revisão dos campos sugeridos pela IA (categoria, descrição, marca, modelo, série), cada um editável, com aviso se o número de série já existe na unidade.
4. Confirmar e associar a etiqueta provisória (QR da cartela).

### 4.7 Divergências (perfil gestor)
- Fila agrupada por tipo, com causa provável e próximo passo.
- Agrupamento em lote ("10 bens da Sala 101 lidos na Sala 102") com uma aprovação.
- Conflitos com as duas versões e fotos lado a lado.

### 4.8 Sincronização
- Aparelhos da unidade: nome, papel, impressão digital da chave, último contato.
- Eventos e fotos pendentes, botão "Sincronizar agora".
- Convidar membro (gestor): mostra o QR de convite.

### 4.9 Mais
Perfil e papel, aparelho e impressão digital da chave, unidades, importar CSV, exportar resultados, gerar cartela de QR provisórios (PDF), marca ativa, modo diagnóstico, sobre e licenças.

## 5. Textos

- Português do Brasil, frases curtas, verbos no imperativo nos botões ("Conferir esta sala", "Importar CSV").
- Nada de termos técnicos na interface ("evento", "hash" e "Ed25519" só aparecem no modo diagnóstico e na linha do tempo como "assinatura verificada").

## 6. Critério de qualidade

- Nenhum texto cortado em telas de 360 dp de largura.
- Contraste AA em claro e escuro.
- Fonte do sistema em 130% sem quebrar layout.
- Telas comparáveis em acabamento a um app comercial: se uma tela parecer um formulário genérico, refazer.
