# Prompt 08: roteiro da noite (blocos A a G)

O usuário está dormindo e quer o app pronto e bem feito pela manhã. Trabalhe bloco por bloco, na ordem, sem parar para pedir confirmação. Quem coordena é o Claude, que revisa cada entrega e pode mandar correções.

## Leitura obrigatória antes de começar
1. `processamento/Tombox/docs/CONTEXTO.md`
2. `processamento/Tombox/docs/specs/arquitetura-v2.md` (app único, sincronização entre celulares, assinaturas, proveniência, homologação)
3. `processamento/Tombox/docs/specs/design-ui.md` (estrutura de telas)
4. `processamento/Tombox/docs/specs/design-ui-v2.md` (linguagem visual vigente: plaqueta e livro de tombo). Em conflito com o design-ui.md, vale o v2.
5. `processamento/Tombox/docs/design/direcao-visual-v2.png` (maquete; abra a imagem e siga)
6. `processamento/Tombox/docs/prompts/07b-revisao-visual.md` (bugs pendentes)

## Regras para todos os blocos
- Ao terminar cada bloco:
  - `flutter analyze` sem erros;
  - todos os testes passando;
  - `flutter build apk --debug` compilando;
  - prévia web funcionando;
  - commit com a mensagem indicada;
  - `git push origin main`;
  - resumo curto em `docs/respostas/08-<letra>.md` (o que fez, decisões, pendências).
- Se um bloco travar por mais de 40 minutos num problema, registre no resumo do bloco o que tentou, deixe o código compilando e siga para o próximo.
- Nunca use dados reais do TJPA. Nunca copie código do Homebox ou do Companion.
- Pacotes novos entram em `docs/BIBLIOTECAS.md` com licença. Só licenças permissivas (MIT, BSD, Apache, OFL).
- Comentários e textos da interface em português do Brasil.
- Lógica nova em Dart puro em `lib/domain/`, com testes unitários.

---

## Bloco A: redesenho v2 e bugs pendentes
Commit: "app: redesenho v2 (plaqueta e livro de tombo) e correções"

1. As fontes Barlow em TTF estão em `processamento/Tombox/app/assets/fonts/`. Registre no `pubspec.yaml` as famílias Barlow (400, 500, 600, 700), Barlow Semi Condensed (600) e Barlow Condensed (600, 700) e use em todo o app. Remova a Inter e qualquer outra fonte.
2. Reescreva o tema e os componentes conforme `design-ui-v2.md` (tokens, raios, sem sombras, divisórias, algarismos tabulares). Crie os componentes Plaqueta (pequena e grande), BarraSituacao, LegendaSituacao, LinhaSala, LinhaBem, Carimbo, ListaDados, LinhaDoTempo, BotaoPrincipal, Abas, BarraInferior e Esqueleto. Apague os componentes antigos que não servirem mais.
3. Refaça todas as telas (Início, Locais, Sala, Conferir, Bens, Ficha, Mais) seguindo a maquete.
4. Corrija todos os bugs de `07b-revisao-visual.md`, em especial:
   - dados zerados no Início;
   - camada cinza por cima das telas;
   - Ficha mostrando "Sem localização cadastrada";
   - textos apagados em Mais;
   - números no padrão brasileiro;
   - "Continuar conferência" só com sala em andamento;
   - nome fixo "Rosilene".
5. Capturas em 360×800 de todas as telas, em claro, e de Início e Ficha em escuro, em `docs/screenshots/` (substitua as antigas). Antes de salvar, espere o carregamento terminar. Confira por MD5 que todas são diferentes. Olhe cada uma e compare com a maquete; se divergir, corrija e capture de novo.

## Bloco B: identidade, assinatura e proveniência
Commit: "app: identidade Ed25519, eventos assinados e proveniência por campo"

1. Par Ed25519 por aparelho, chave privada em `flutter_secure_storage`, impressão digital curta exibida em Mais.
2. Novo formato de evento da seção 4 da arquitetura (autor, seq, hash_anterior, conhecidos, hash, assinatura), com migração dos eventos existentes no banco de demonstração (pode recriar a base de demo com eventos assinados).
3. Validação ao receber ou carregar: assinatura, continuidade de seq e hash por autor. Eventos inválidos vão para quarentena.
4. Proveniência por campo (seção 11.1) nos eventos que tocam atributos. Na Ficha, tocar num campo mostra a origem.
5. Linha do tempo da Ficha com "assinatura verificada" real.
6. Testes: assinatura válida e inválida, evento adulterado, seq com buraco, ordem determinística da projeção, proveniência.

## Bloco C: fotos mínimas
Commit: "app: fotos comprimidas e armazenamento por conteúdo"

1. Captura de foto pelo app na Ficha (Tirar foto) e no fluxo de bem novo. Galeria não é aceita.
2. Compressão conforme a seção 7 da arquitetura: lado maior 1024, WebP qualidade 60, sem EXIF, miniatura de 160. Arquivo nomeado pelo SHA-256 em pasta privada. Evento FOTO com hash e tamanho.
3. Galeria na Ficha e miniatura na LinhaBem.
4. Na web, aceitar seleção de arquivo para a prévia, mantendo a compressão.
5. Testes: imagem de teste grande sai com até 1024 px e menos de 120 KB, sem metadados; mesma foto não duplica.

## Bloco D: sincronização entre celulares
Commit: "app: sincronização em rede local e pacote .tombox"

1. Motor de sincronização em Dart puro (`lib/domain/sync/`): resumo por autor, cálculo do que falta, aplicação idempotente, quarentena. Testes com dois e três bancos em memória (convergência, idempotência, ordem diferente, evento inválido).
2. Transporte em rede local:
   - descoberta mDNS do serviço `_tombox._tcp` (por exemplo `bonsoir` ou `nsd`);
   - servidor HTTP leve no app (`shelf`);
   - autenticação mútua por desafio assinado;
   - troca de resumos, depois eventos, depois fotos por hash.
3. Pacote `.tombox` (zip com eventos e fotos) para exportar e importar por arquivo, validado como uma sincronização.
4. Tela de Sincronização (seção 4.8 do design-ui): aparelhos, último contato, pendências, "Sincronizar agora". IndicadorSync real na barra superior.
5. Se o mDNS ou o servidor não funcionarem no emulador ou na web, deixe a troca por pacote `.tombox` funcionando e documente.

## Bloco E: papéis, convite, homologação e divergências
Commit: "app: papéis, convite por QR, homologação e fila de divergências"

1. Perfis gestor e conferente. Criar unidade (gestor), convite por QR com código de uso único, entrada de membro, revogação.
2. Fila de divergências com causa provável e próximo passo; agrupamento em lote; conflitos lado a lado com fotos.
3. Homologação (seção 11.2): gestor aprova por sala ou em lote; o relatório oficial só usa o homologado.
4. Na prévia web, permitir trocar de perfil em Mais para demonstrar os dois papéis.
5. Testes de permissão por papel e de homologação.

## Bloco F: fechamento, termo e exportação
Commit: "app: fechamento de sala, termo assinado e exportação"

1. Fechar sala: resumo, assinatura do responsável na tela (`signature`), termo de responsabilidade em PDF (`pdf`) com lista de bens, divergências, hash do último evento e verificação. Evento TERMO_ASSINADO com hash do PDF.
2. Exportação:
   - CSV de resultado;
   - perfis de mapeamento de colunas (seção 11.3);
   - relatório PDF da unidade com verificação de assinaturas;
   - eventos em EPCIS JSON-LD (seção 11.5) e `docs/epcis.md` explicando o mapeamento.
3. Modo "entrada por leitor externo" (seção 11.4), aceitando leituras digitadas por leitor RFID ou de código de barras como teclado.

## Bloco G: bem novo com IA e cartela de QR
Commit: "app: bem novo com IA no aparelho e cartela de QR provisórios"

1. Fluxo em etapas (Local › Fotos › Revisar › Confirmar), na linguagem visual v2.
2. ML Kit Image Labeling para sugerir categoria (mapeamento de rótulos para categorias patrimoniais em arquivo editável), OCR da etiqueta do fabricante para marca, modelo e série, e aviso de duplicado pelo número de série.
3. Proveniência em cada campo sugerido.
4. Cartela de QR provisórios em PDF A4 (faixa por aparelho, formato `PROV-000-123`), em Mais.
5. Na web, a IA não roda: preencher com sugestão simulada claramente marcada como simulação.

## Ao terminar tudo
Atualize `processamento/Tombox/README.md` (o que é, como rodar, arquitetura, capturas) e escreva `docs/respostas/08-final.md` com o estado de cada bloco.
