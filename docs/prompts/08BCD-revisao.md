# Revisão dos Blocos B, C e D (feita pelo Claude)

Os motores em Dart puro estão bons: assinatura, validador, quarentena, convergência com dois e três bancos e pacote `.tombox`, com testes. O problema está na ponta do app: algumas telas mostram coisas que o código não faz. Num pitch para um tribunal isso é pior do que não ter a função. Corrija antes de seguir.

## 1. Fotos (Bloco C)
1. **Captura pela câmera no Android.** Hoje a Ficha oferece "Selecionar foto do arquivo" e "Tirar foto simulada de teste". No Android, "Tirar foto" deve abrir a câmera do app (pacote `camera`, já instalado, numa tela simples de captura com botão retangular) e não deve oferecer galeria. Seleção de arquivo só na web (`kIsWeb`). A foto simulada só no modo diagnóstico.
2. **Formato.** O código grava JPEG qualidade 60, mas a interface diz "WebP". No Android, use `flutter_image_compress` (MIT) para gerar WebP qualidade 60 com lado maior 1024 e sem EXIF; na web e nos testes, mantenha o pacote `image` com JPEG. Os textos da interface não citam formato.
3. Teste continua valendo: até 1024 px, menos de 120 KB, sem metadados, sem duplicar.

## 2. Sincronização (Bloco D)
1. **A tela de Sincronização lista aparelhos fixos no código** (`sincronizacao_screen.dart`, linhas 29 e 38). Remova. A lista vem só de aparelhos realmente descobertos ou com que já houve troca.
2. **Descoberta mDNS:** adicione `bonsoir` (BSD-3) ou `nsd` (MIT): anunciar `_tombox._tcp` com a porta do servidor e a impressão curta; buscar e listar os que aparecem. Na web, a tela diz "Na prévia web, use o pacote .tombox" e esconde a busca.
3. **Autenticação mútua por desafio:** `GET /sync/desafio` devolve um nonce; o cliente manda `POST /sync/autenticar` com sua chave pública, o nonce assinado e um nonce dele; o servidor confere a assinatura, confere que a chave é de membro ativo da unidade e devolve o nonce do cliente assinado; o cliente confere. Sem isso, `resumo`, `eventos` e `fotos` respondem 401. Teste em Dart puro com dois servidores em portas locais (ou com `shelf` em memória).
4. **"Sincronizar agora"** executa a troca real com o aparelho escolhido: resumo, eventos que faltam, depois fotos por hash. Mostre o resultado em linha de texto ("12 eventos recebidos, 3 enviados, 2 fotos").
5. Registre em `docs/respostas/08-BCD.md` como testar com dois celulares na mesma rede Wi-Fi, passo a passo.

## 3. Identidade (Bloco B)
1. O selo da linha do tempo "Assinatura Ed25519 verificada ✓": sem o "✓" e sem o nome do algoritmo na interface. Texto: "assinatura verificada". Se a verificação falhar: "assinatura inválida" em vermelho.
2. O modal de proveniência não deve mostrar "W3C PROV-O" para o usuário. Mostre a frase da seção 11.1 da arquitetura ("Fabricante: Dell. Lido da etiqueta do fabricante, revisado por Rosilene em 27/10"). A referência ao padrão fica só na documentação.
3. Confira que a impressão curta em Mais vem da chave real gerada no aparelho (não um valor fixo).

## 4. Regra geral daqui em diante
Nenhuma tela mostra dado inventado como se fosse real. Quando algo só existe como simulação (web, diagnóstico), a interface diz "simulação" ali mesmo.

Commit "app: revisão dos blocos B, C e D", push, resumo em `docs/respostas/08-BCD.md`, e siga para o próximo bloco pendente.
