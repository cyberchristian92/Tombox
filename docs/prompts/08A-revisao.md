# Revisão do Bloco A (feita pelo Claude)

A linguagem v2 apareceu nas telas de Bens, Início e Mais (plaquetas, linhas, legenda, botão Conferir retangular). Bom trabalho. Faltam estes pontos antes de fechar o bloco.

## 1. Capturas pelo navegador não são confiáveis: troque por golden tests

As capturas de 13:02 mostram telas erradas ou em estado errado:
- `01-inicio.png` é o relatório de importação;
- `02` a `04` são iguais a `01`;
- `01-inicio-dark.png` está em tema claro;
- `06-ficha.png` é a lista de Bens;
- `05-bens.png` está vazia.

Em vez de automatizar o Chrome, gere as capturas com testes de widget determinísticos:
1. Crie `test/capturas/capturas_test.dart` que monta cada tela com `ProviderScope` e um banco drift em memória preenchido com o CSV de demonstração e algumas conferências simuladas: uma sala em andamento com 7 de 18, um bem em outra sala, um bem sem cadastro, um bem com histórico.
2. Carregue as fontes Barlow no teste com `FontLoader` (senão o teste usa a fonte Ahem e a captura fica ilegível).
3. Tamanho 360×800, `devicePixelRatio` 2, tema claro para todas as telas e escuro para Início e Ficha.
4. Grave os PNGs em `docs/screenshots/` com `matchesGoldenFile` ou capturando o `RepaintBoundary`.
5. Esses mesmos testes ficam como testes de regressão visual.

## 2. Bugs vistos nas capturas
1. **Abas cortadas** em Bens: "Conferidos (..." e "Pendentes (...". Use o formato "Pendentes 12" (sem parênteses), abas roláveis horizontalmente e rótulos curtos.
2. **Mais diz "Nenhuma unidade carregada"** com a unidade de Breves carregada. O provider da unidade ativa não está compartilhado entre as telas. Corrija a fonte única de verdade da unidade ativa.
3. **Barra superior** mostra "Tombox" em Bens e Mais e "Comarca de Breves" no Início. Deve mostrar sempre a unidade ativa; "Tombox" só quando não houver unidade.
4. **Início com unidade recém-carregada:** "Conferência iniciada em 28 de outubro" sem nenhuma conferência é falso. Mostre "Nenhuma sala conferida ainda" até a primeira leitura.
5. **Relatório de importação:** usa vários pontos de lista e caixas; reescreva na linguagem v2 (ListaDados e texto corrido curto) e troque "Continuar para Lista de Salas" por "Ver salas", sem seta.
6. **Perfil padrão** "Rosilene Silva" no `perfil_provider.dart`: mantenha só como perfil de demonstração carregado junto com os dados de demonstração. Num primeiro uso real, peça nome e matrícula.

## 3. Depois
Commit do Bloco A, push, resumo em `docs/respostas/08-A.md` e siga para o Bloco B.
