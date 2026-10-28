# Arquitetura v2: tudo no app, sincronização entre celulares

Esta especificação substitui a seção 6 do `CONTEXTO.md` (dois softwares). A partir de agora o Tombox é um app só. O sistema do gestor em Python sai do escopo; o gestor é um perfil dentro do app.

## 1. Princípios

- **Cada celular tem a cópia completa** dos dados das unidades de que participa. Perder um aparelho não perde dados.
- **Funciona sem internet.** Quando dois ou mais celulares da mesma unidade estão na mesma rede (ou próximos, por Bluetooth e Wi-Fi Direct), eles trocam o que falta.
- **Nada é sobrescrito.** Todo registro é um evento imutável. Juntar o banco de dois celulares é unir os conjuntos de eventos.
- **Não repúdio.** Cada evento é assinado pela chave do aparelho de quem o criou. Dá para provar quem registrou o quê, quando, e que nada foi alterado depois.
- **Rastreabilidade.** O estado atual de um bem (onde está, estado de conservação, situação) é sempre calculado a partir dos eventos, e a ficha mostra a linha do tempo completa.
- **Fotos mínimas.** Toda foto é comprimida no aparelho antes de ser guardada ou enviada.

## 2. Identidade e papéis

- No primeiro uso, o app gera um par de chaves **Ed25519** e guarda a chave privada no armazenamento seguro do Android (Keystore, via `flutter_secure_storage`). A chave privada nunca sai do aparelho.
- A identidade do membro tem nome, matrícula, chave pública e uma impressão digital curta da chave (8 a 12 caracteres, para conferência visual).
- Papéis:
  - **Gestor:** cria a unidade, convida e revoga membros, aprova divergências e conflitos, exporta relatórios oficiais.
  - **Conferente:** confere salas, registra estado, fotos, observações e bens novos.
- Uma pessoa pode ter papéis diferentes em unidades diferentes.

## 3. Unidade e membros

- **Criação:** o gestor importa o CSV da unidade. O app gera o evento `UNIDADE_CRIADA`, com o hash SHA-256 do CSV original e o identificador da unidade, assinado pelo gestor fundador. Cada bem importado gera um evento `BEM_IMPORTADO`.
- **Convite:** o gestor mostra um QR com o identificador da unidade, um código de convite de uso único com validade curta e o endereço do aparelho dele na rede local.
- **Entrada:** o novo aparelho lê o QR, envia sua chave pública e identidade. O gestor confirma na tela e o app gera `MEMBRO_ADICIONADO` (assinado pelo gestor, com o papel). Em seguida o novo aparelho recebe a cópia completa por sincronização.
- **Revogação:** `MEMBRO_REVOGADO`, assinado por um gestor. Eventos de um membro revogado criados depois da revogação são rejeitados por todos os aparelhos. Usado para aparelho perdido ou pessoa que saiu.

## 4. Eventos

Campos de todo evento:
- `id` (UUID v4), `unidade_id`, `tipo`, `autor` (chave pública), `seq` (crescente por autor), `hash_anterior` (último evento do mesmo autor), `conhecidos` (para cada autor conhecido, o hash do último evento visto, para ordem causal), `timestamp` (relógio do aparelho, com fuso), `payload` (JSON), `hash` (SHA-256 do JSON canônico sem `hash` e `assinatura`), `assinatura` (Ed25519 do `hash`).
- Tipos: `UNIDADE_CRIADA`, `BEM_IMPORTADO`, `MEMBRO_ADICIONADO`, `MEMBRO_REVOGADO`, `ABERTURA_SALA`, `LEITURA`, `CONFIRMACAO`, `LEITURA_MANUAL`, `ESTADO`, `OBSERVACAO`, `FOTO`, `MOVIMENTACAO`, `BEM_NOVO`, `FECHAMENTO_SALA`, `TERMO_ASSINADO`, `DIVERGENCIA_RESOLVIDA`, `ATRIBUTO_PROPOSTO`, `HOMOLOGACAO`.
- **Validação ao receber:** assinatura válida; autor é membro ativo da unidade naquele ponto da ordem causal; `seq` e `hash_anterior` contínuos para aquele autor; tipo permitido para o papel do autor. Evento inválido é guardado em quarentena e aparece numa tela de diagnóstico, nunca é aplicado.
- O relógio do celular pode estar errado. A ordem confiável é a causal (`conhecidos`); o `timestamp` serve para exibição e para desempate determinístico junto com o `hash`.

## 5. Estado e conflitos

- O estado (bens, locais, conferências, divergências) é uma projeção recalculada a partir dos eventos, de forma determinística: dois celulares com os mesmos eventos mostram exatamente o mesmo estado.
- **Conflito:** dois autores registram, sem terem visto um ao outro, informações incompatíveis sobre o mesmo bem (salas diferentes no mesmo período, estados diferentes). O app não escolhe sozinho: cria uma divergência com as duas versões e as fotos lado a lado, e um gestor resolve com `DIVERGENCIA_RESOLVIDA`.
- Divergências de inventário (bem não localizado, em outra sala, sem cadastro) seguem a fila com causa provável já definida e podem ser resolvidas em lote.

## 6. Sincronização

- **Descoberta:**
  - na mesma rede Wi-Fi: anúncio e busca por mDNS (serviço `_tombox._tcp`), com um servidor HTTP leve em cada app;
  - sem roteador: Nearby Connections do Android (Bluetooth e Wi-Fi Direct), numa etapa posterior.
- **Autenticação mútua:** cada lado assina um desafio com a sua chave; só sincronizam membros ativos da mesma unidade. O canal é cifrado com chave de sessão derivada por X25519.
- **Protocolo:**
  1. troca de resumos: para cada autor, o maior `seq` que cada lado tem;
  2. envio dos eventos que faltam, em lotes, em ordem de `seq` por autor;
  3. depois, as fotos que faltam, pedidas pelo hash, com prioridade baixa.
- **Quando:** automaticamente ao entrar numa rede onde há outro membro, e manualmente pelo botão "Sincronizar agora".
- O indicador de sincronização fica sempre visível no topo: aparelhos vistos, último contato, eventos e fotos pendentes.

## 7. Fotos

- Captura sempre pela câmera do app (galeria não é aceita para conferência).
- Processamento no aparelho, antes de guardar:
  - redimensionar para no máximo 1024 px no maior lado;
  - comprimir em WebP com qualidade por volta de 60 (`flutter_image_compress`), alvo de 30 a 80 KB;
  - remover metadados EXIF, inclusive localização;
  - gerar miniatura de 160 px para listas.
- O arquivo é nomeado pelo seu SHA-256 (armazenamento endereçado por conteúdo): sem duplicatas, e a sincronização pede só o que falta.
- O evento `FOTO` guarda o hash, o tamanho e a referência ao bem.

## 8. Armazenamento e segurança

- SQLite com `drift`, criptografado com SQLCipher; chave do banco protegida pelo Keystore e liberada por biometria ou PIN do aparelho.
- Fotos em pasta privada do app.
- Minimização LGPD: responsável identificado por matrícula; nenhuma localização GPS guardada.
- Backup e transporte por arquivo: pacote `.tombox` (zip com eventos e fotos), que o app importa e valida como se fosse uma sincronização.

## 9. IA no aparelho

- OCR de plaquetas e casamento com a lista (já implementado).
- Sugestão automática de sala: se a maior parte das leituras pertence a outra sala, o app pergunta "Você está na Sala 204?".
- Bem novo: categoria sugerida pela foto (ML Kit Image Labeling mapeado para categorias patrimoniais), OCR da etiqueta do fabricante para marca, modelo e número de série, e verificação de duplicado pelo número de série.

## 10. Exportação

- CSV de resultado e relatório PDF, gerados a partir do estado, pelo perfil gestor.
- O relatório traz o hash do último evento de cada autor e a verificação das assinaturas, para auditoria.

## 11. Proveniência, homologação e encaixe no TJPA

Fonte: `material/Relatorio_Inventario_Digital_TJPA_Pesquisa_Brasil_Internacional.pdf`. Segundo o relatório, o TJPA já tem um piloto RFID com a Thema, um pregão de 34.500 etiquetas e o sistema Thema-GRP. Ler etiqueta não é inovação; o Tombox complementa o que existe.

### 11.1 Proveniência por campo
Todo valor de atributo de um bem guarda de onde veio. No payload dos eventos que alteram ou propõem atributos (`BEM_IMPORTADO`, `BEM_NOVO`, `ESTADO`, `MOVIMENTACAO`, e um novo `ATRIBUTO_PROPOSTO`), cada campo é um objeto:
```json
{ "valor": "Dell", "fonte": "ocr_etiqueta_fabricante", "confianca": 0.93,
  "evidencia": "<sha256 da foto>", "revisado_por": "<chave pública>", "situacao": "revisado" }
```
- `fonte`: `importacao`, `leitura_codigo`, `ocr_plaqueta`, `ocr_etiqueta_fabricante`, `ia_classificacao`, `pessoa`, `rfid`.
- `situacao`: `sugerido` (IA ou OCR sem revisão), `revisado` (pessoa confirmou), `homologado` (gestor aprovou).
- A Ficha do bem mostra, ao tocar num campo, a origem do valor ("Fabricante: Dell. Lido da etiqueta do fabricante, revisado por Rosilene em 27/10").
- Valor sugerido por IA nunca é tratado como prova de estado físico, valor ou titularidade.

### 11.2 Homologação (conferir é diferente de aprovar)
No modelo do TJMA, o conferente registra e um setor responsável homologa.
- Registros do conferente entram como `revisado`.
- O gestor homologa por sala ou em lote, com o evento `HOMOLOGACAO` assinado, listando os eventos aprovados ou rejeitados.
- Só o que está homologado entra no relatório oficial e na exportação para o sistema patrimonial.

### 11.3 Exportação para o sistema patrimonial (Thema-GRP ou outro)
- O formato do sistema do TJPA não é público. A exportação tem um mapeamento de colunas configurável, salvo como perfil ("Thema-GRP", "Genérico"), em CSV com separador e codificação escolhidos.
- O perfil "Genérico" segue o CSV de resultado da especificação do app.

### 11.4 RFID como fonte opcional
- Onde o TJPA já tiver etiquetas RFID, um leitor por Bluetooth (como o Chainway R6, citado no relatório) pode entrar como mais uma fonte de leitura (`fonte: rfid`), pela entrada de teclado do leitor ou pelo SDK do fabricante.
- No protótipo: deixar a interface de fonte de leitura preparada e um modo "entrada por leitor externo" que aceita leituras digitadas pelo leitor como teclado. O SDK não entra.

### 11.5 Referências de padrão para o pitch
- **GS1 EPCIS 2.0:** cada evento do Tombox mapeia para um ObjectEvent: o quê (tombamento), quando (timestamp), onde (local), por quê (tipo: conferência, movimentação) e quem (autor). Documentar esse mapeamento em `docs/epcis.md` e oferecer exportação dos eventos em EPCIS JSON-LD como opção.
- **W3C PROV-O:** inspira a proveniência por campo (entidade, atividade, agente).
- **NIST SP 800-53 (família AU)** e **ISO 55001:** citar no pitch como base da trilha de auditoria e da gestão de ativos.

## 12. Etapas

- **Etapa 5:** correções de bugs e redesenho (ver `docs/specs/design-ui.md` e `docs/prompts/07-correcoes-e-redesenho.md`). Prioridade para o vídeo de 29/10.
- **Etapa 6:** identidade com Ed25519, assinatura de eventos, campos novos do evento e migração dos eventos existentes.
- **Etapa 7:** compressão de fotos e armazenamento endereçado por conteúdo.
- **Etapa 8:** sincronização em rede local (mDNS, HTTP, autenticação mútua, troca de resumos e eventos, depois fotos).
- **Etapa 9:** papéis, convite por QR, revogação, perfil gestor e fila de divergências com resolução em lote.
- **Etapa 10:** fechamento de sala com termo assinado e exportação de relatório.
- **Etapa 11 (se der tempo):** Nearby Connections sem roteador.
