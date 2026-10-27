# Prompt 05a: prévia do app no Chrome

Quero ver o design das telas no Chrome deste Mac. O alvo continua sendo Android: a versão web é só uma prévia visual.

1. Faça o app rodar no Chrome com o mínimo de mudanças e sem quebrar o Android:
   - câmera e ML Kit não funcionam na web: na tela de Conferência, mostrar um placeholder com aviso "Câmera disponível apenas no app Android" e manter o resto da tela (contador, abas, botões);
   - o banco `drift` precisa de configuração própria na web (sqlite3 WASM). Se for rápido, configure; se não, use um banco em memória só na web, por importação condicional;
   - use importações condicionais (`dart.library.html` / `dart.library.io`) para isolar o que é só Android.
2. Rode `flutter run -d chrome` para abrir o app numa janela do Chrome, para eu navegar.
3. Na janela aberta, carregue os dados de demonstração para as telas aparecerem preenchidas.
4. Confirme que `flutter analyze` e `flutter test` continuam sem erros e que `flutter build apk --debug` ainda compila.
5. Faça commit "app: prévia web para revisão de design" e salve um resumo em `docs/respostas/05a-preview-web.md`.

Deixe o app rodando no Chrome ao terminar.
