# Prompt 02: Etapa 0 (base do app)

Execute a Etapa 0 da seção 9 de `processamento/Tombox/docs/specs/app-mobile.md`, considerando as respostas e ajustes que combinamos.

Entregas:
1. Projeto Flutter em `processamento/Tombox/app` (organização `br.tombox`, nome do pacote `tombox`), Android como alvo principal.
2. Estrutura de pastas exatamente como na seção 2 da especificação.
3. Marca trocável (seção 3): `assets/brand/brand.json`, `assets/brand/presets/neutro.json`, `lib/brand/` gerando tema claro e escuro, logo com fallback em texto quando o arquivo não existir. Não inclua imagem de logo do TJPA: deixe o caminho `assets/brand/logo.png` previsto e funcionando sem o arquivo.
4. Rotas com `go_router` e telas vazias navegáveis: Início, Relatório de importação, Salas, Conferência, Ficha do bem, Exportar, Configurações.
5. Componentes base de acessibilidade: botões com alvo mínimo de 48 dp, textos que respeitam o tamanho de fonte do sistema, contraste AA.
6. `docs/BIBLIOTECAS.md` com cada pacote usado, versão e licença.
7. `app/README.md` explicando como rodar.
8. Teste simples que carrega o tema a partir do `brand.json` e outro com o preset neutro.

Critério de pronto: `flutter analyze` sem erros, `flutter test` passando, app abrindo no emulador ou celular Android e navegando entre as telas vazias. Faça um commit com a mensagem "app: etapa 0, base do projeto e marca trocável".

Ao terminar, me mostre a árvore de arquivos criada e o resultado de `flutter analyze` e `flutter test`.
