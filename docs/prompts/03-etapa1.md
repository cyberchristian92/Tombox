# Prompt 03: Etapa 1 (dados e importação)

Execute a Etapa 1 da seção 9 de `processamento/Tombox/docs/specs/app-mobile.md`.

Entregas:
1. Banco local com `drift` com as tabelas da seção 4 (Unidade, Local, Bem, ConferenciaSala, Evento). A tabela Evento só aceita inserção.
2. Importação de CSV conforme a seção 5, com detecção de separador (`;`, `,`, tabulação), codificação (UTF-8 com ou sem BOM, Windows-1252), cabeçalhos com variações e sinônimos, normalização de tombamento e de nomes de sala, colunas extras e relatório de qualidade por linha. Reimportar atualiza pelo tombamento.
3. Criação da árvore de locais a partir do caminho `Comarca / Prédio / Andar / Sala`.
4. Script `processamento/Tombox/tools/gerar_dados_demo.py` (Python 3, Faker pt_BR) que gera uma unidade sintética com 15 salas e cerca de 300 bens, com alguns problemas de propósito (duplicado, tombamento com letra O, sala escrita de jeitos diferentes). Versione o CSV gerado em `app/assets/demo/unidade_demo.csv`.
5. Telas funcionando: Início (importar CSV e carregar demonstração), Relatório de importação e Salas (agrupadas por prédio e andar, com "lidos x de y").
6. Testes: separadores, codificações, cabeçalhos com sinônimos, normalização de tombamento (zeros à esquerda, letra O, pontos e hífens), duplicados, linha com colunas a mais ou a menos, reimportação sem duplicar.

Critério de pronto: importar o CSV de demonstração no celular e ver o relatório e a lista de salas. `flutter analyze` sem erros e testes passando. Commit "app: etapa 1, banco local e importação de CSV".
