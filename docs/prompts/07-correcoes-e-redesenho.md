# Prompt 07: correções de bugs e redesenho

Leia antes:
- `processamento/Tombox/docs/specs/arquitetura-v2.md` (o projeto agora é só o app, com sincronização entre celulares; o sistema do gestor em Python saiu do escopo).
- `processamento/Tombox/docs/specs/design-ui.md` (design tela por tela).

O usuário revisou a prévia no Chrome e não aprovou o design: as telas parecem genéricas e há bugs. Esta etapa é prioridade máxima, porque o vídeo da triagem será gravado em 29/10.

## Parte A: bugs (com testes)

1. **Salas duplicadas.** Ao importar `assets/demo/unidade_demo.csv`, a tela de Salas mostra "Sala 103 - Atendimento ao Cidadão" duas vezes (uma com "0 de 0 lidos" e outra com "0 de 18") e "sala 102" separada de "Sala 102 - Secretaria". O relatório da Etapa 1 fala em 18 salas, mas o gerador cria 15.
   - Corrija a criação da árvore de locais e a normalização: variações do mesmo nome no mesmo prédio e andar viram uma sala só; uma variação só com número ("sala 102", "SL 102") se junta à sala daquele número no mesmo prédio e andar, se existir só uma.
   - Nenhum local pode ser criado em duplicidade por caminho.
   - Teste: importar o CSV de demonstração gera exatamente 15 salas, 300 bens únicos (302 linhas com 2 duplicadas) e nenhuma sala com 0 bens.
2. **Conferência com "0 de 0 bens".** A tela de Conferência não carrega os bens da sala. Corrija a ligação entre sala e bens esperados. Teste de widget ou de integração: abrir uma sala do demo mostra o total correto de bens.
3. **Títulos cortados** ("Conferência - Sal..."): nome da sala em até duas linhas, com as migalhas acima.

## Parte B: redesenho

Implemente o `design-ui.md`, nesta ordem:
1. Fundamentos: cores de status, tipografia Inter e fonte mono para tombamento embutidas, tema claro e escuro, escala de espaçamento e raio.
2. Componentes da seção 2 (CartaoEstatistica, CartaoBem, CartaoLocal, Migalhas, ChipStatus, ChipCategoria, EstadoVazio, BarraBusca, CabecalhoSecao, IndicadorSync visual, ainda sem sincronização real).
3. Navegação da seção 3: barra inferior com botão central Conferir e barra superior com unidade ativa.
4. Telas, nesta ordem: Início (4.1), Locais e Detalhe da sala (4.2), Conferir (4.3), Bens (4.4), Ficha do bem (4.5), Mais (4.9).
5. Remova a tela antiga de "Unidades" como início; a importação passa para o estado vazio do Início e para Mais.

Mantenha a prévia web funcionando (com o placeholder de câmera e o botão de simular leitura) e o build Android compilando.

## Parte C: revisão visual

1. Rode a prévia web em largura de celular (360 × 800) com os dados de demonstração.
2. Salve uma captura de cada tela em `processamento/Tombox/docs/screenshots/` com nomes como `01-inicio.png`, `02-locais.png`, `03-sala.png`, `04-conferir.png`, `05-bens.png`, `06-ficha.png`, `07-mais.png`, também em modo escuro para o Início e a Ficha.
3. Olhe cada captura com o critério da seção 6 do `design-ui.md`. Se alguma tela parecer formulário genérico ou tiver texto cortado, refaça antes de entregar.

## Entrega

`flutter analyze` sem erros, testes passando (incluindo os novos), commit "app: correções de salas e redesenho completo", resumo em `docs/respostas/07-correcoes-e-redesenho.md` e `git push origin main`. Deixe a prévia rodando no Chrome em `localhost:8080`.
