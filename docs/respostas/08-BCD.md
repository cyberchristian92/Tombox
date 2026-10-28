# Resposta à Revisão dos Blocos B, C e D

Todas as pendências e desalinhamentos apontados em `docs/prompts/08BCD-revisao.md` foram integralmente corrigidos e testados.

---

## 1. Fotos (Bloco C)
1. **Captura Nativa no Android:**
   - Adicionada a tela `CapturaFotoScreen` (`lib/features/bem/screens/captura_foto_screen.dart`) usando o pacote `camera` nativo.
   - O botão de disparo possui estilo retangular estrito v2 (`BorderRadius.circular(4)`), com visor de enquadramento patrimonial e contagem de fotos.
   - Na tela do bem (`bem_screen.dart`), tocar em "Tirar foto" no Android abre diretamente a câmera nativa, sem oferecer picker de galeria.
   - Na Web (`kIsWeb`), o app abre o seletor de arquivo do sistema operacional.
   - A opção de foto simulada sintética só é disponibilizada se o `modoDiagnostico` estiver explicitamente ativo no perfil.
2. **Formato e Compressão WebP:**
   - Integrado `flutter_image_compress: 2.5.1` (MIT), registrado em `docs/BIBLIOTECAS.md`.
   - No Android, `FotoService.processarBytesAsync` gera WebP qualidade 60, lado maior no máximo 1024 px, sem metadados EXIF (`keepExif: false`), com miniatura de 160 px.
   - Na Web e testes unitários, mantém fallback em Dart puro com `image`.
   - Todos os textos da interface foram limpos: não citam extensões ("WebP/JPEG"), exibindo apenas "Foto anexada" e o tamanho real em KB.

---

## 2. Sincronização e P2P (Bloco D)
1. **Remoção de Mocks:**
   - Foram eliminados os nós mockados hardcoded em `sincronizacao_screen.dart`.
   - Se nenhum aparelho for encontrado na rede, o app exibe com honestidade:
     > *"Nenhum outro aparelho encontrado na rede Wi-Fi. Certifique-se de que outro celular com o Tombox está conectado à mesma rede e com o app aberto."*
2. **Descoberta de Serviço com `nsd` (mDNS/DNS-SD):**
   - Integrado `nsd: 5.0.1` (MIT), registrado em `docs/BIBLIOTECAS.md`.
   - Anuncia o serviço `_tombox._tcp` na porta local 8086 com registro TXT contendo a impressão digital curta (`fp`).
   - Descobre outros aparelhos e os lista dinamicamente com IP, porta e chave pública curta.
   - Na Web (`kIsWeb`), exibe o aviso institucional:
     > *"Na prévia web, a sincronização em rede local não está disponível por restrições do navegador. Use a exportação/importação do pacote .tombox abaixo."*
3. **Autenticação Mútua por Desafio (Challenge-Response):**
   - Implementado no servidor embutido (`transporte_local.dart`):
     - `GET /sync/desafio`: Gera nonce seguro com expiração de 5 minutos.
     - `POST /sync/autenticar`: Recebe `{desafio, publicKey, assinatura}`. Valida a assinatura Ed25519 e confere se a chave pertence a um membro ativo da unidade (projetado por `MembroService.obterMembros(db)`).
     - Rotas protegidas (`/sync/resumo`, `/sync/eventos`, `/sync/fotos/*`) exigem `Authorization: Bearer <token>`.
4. **Troca Real:**
   - O botão "Sincronizar agora" executa a reconciliação causal com o nó remoto selecionado:
     1. Autenticação mútua;
     2. Diff de relógio vetorial (`ResumoSincronizacao`);
     3. Envio de eventos faltantes no peer (`POST /sync/eventos`);
     4. Obtenção de eventos faltantes no local (`GET /sync/eventos`);
     5. Download das fotos faltantes referenciadas nos eventos (`GET /sync/fotos/$hash`);
     6. Exibição do resumo real: *"X eventos recebidos, Y enviados, Z fotos transferidas."*

---

## 3. Identidade e Auditoria (Bloco B)
1. **Selo da Linha do Tempo:**
   - Atualizado para `"assinatura verificada"` (sem símbolo "✓" e sem citar o algoritmo "Ed25519").
   - Quando a assinatura for inválida, exibe `"assinatura inválida"` em vermelho (`AppTokens.statusSemCadastro`).
2. **Modal de Proveniência:**
   - Removida a menção ao jargão técnico "W3C PROV-O" da interface.
   - Exibe a frase natural prevista na seção 11.1 da arquitetura (ex: *"Fabricante: Dell. Lido da etiqueta do fabricante, revisado por Rosilene em 27/10."*).
3. **Identidade do Aparelho em Mais:**
   - Verificado que a impressão curta (`ED25-XXXX-XXXX`) é calculada em tempo real a partir da chave pública Ed25519 gravada no `FlutterSecureStorage` do dispositivo.

---

## 4. Guia Passo a Passo: Teste com 2 Celulares na Mesma Rede Wi-Fi

1. **Instalação:**
   - Instale o APK gerado (`build/app/outputs/flutter-apk/app-debug.apk`) em dois aparelhos Android (Aparelho A e Aparelho B).
2. **Conexão de Rede:**
   - Conecte ambos os aparelhos à mesma rede Wi-Fi local (ou conecte o Aparelho B no roteador Wi-Fi / Hotspot portátil do Aparelho A).
3. **Carga e Membros:**
   - No **Aparelho A** (Gestor):
     - Vá em **Mais > Gestão e governança > Membros e comissão**.
     - Toque em **Convidar conferente** e gere o QR Code de convite.
   - No **Aparelho B** (Conferente):
     - Escaneie o QR Code do Aparelho A para ingressar na mesma comissão de inventário com sua chave Ed25519 própria.
4. **Operação Desconectada:**
   - No Aparelho A, confira bens na Sala 101 e anexe fotos.
   - No Aparelho B, confira bens na Sala 102 e anexe fotos.
5. **Sincronização P2P:**
   - Em ambos os aparelhos, abra a aba **Mais > Sincronização P2P**.
   - O serviço mDNS `_tombox._tcp` identificará o outro celular na rede local automaticamente.
   - Toque em **Sincronizar agora** (ou no ícone de sincronizar ao lado do aparelho remoto).
   - O handshake de desafio mútuo valida a chave Ed25519 de membro ativo.
   - Os eventos e fotos são transferidos via HTTP local na porta 8086.
   - Ambos os aparelhos convergem para 100% de consistência com histórico auditado e fotos disponíveis.
