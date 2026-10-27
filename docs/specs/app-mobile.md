# Especificação do app do conferente (Tombox Mobile)

Pré-requisito: ler `docs/CONTEXTO.md`.

## 1. Stack

- Flutter estável e Dart 3. Android primeiro (minSdk 24); o código não deve impedir iOS depois.
- Pacotes recomendados (pode propor alternativa justificando):
  - `camera` para os quadros da câmera;
  - `google_mlkit_text_recognition` para OCR no aparelho;
  - `google_mlkit_barcode_scanning` para código de barras e QR, processando os mesmos quadros do OCR (um só pipeline de câmera);
  - `flutter_riverpod` para estado;
  - `drift` (SQLite) para dados locais;
  - `go_router` para navegação;
  - `file_picker` para importar CSV e `share_plus` para exportar;
  - `csv` para leitura e escrita;
  - `crypto` ou `cryptography` para SHA-256 (e Ed25519 numa etapa posterior);
  - `uuid` para identificadores de evento.
- Tudo funciona sem internet. Nenhuma chamada de rede no fluxo do app.
- Registrar cada biblioteca e sua licença em `docs/BIBLIOTECAS.md`.

## 2. Estrutura de pastas

```
app/
  assets/brand/        logo e brand.json (marca trocável)
  assets/demo/         CSV sintético de demonstração
  lib/
    brand/             leitura do brand.json e tema derivado
    core/              tema, rotas, utilitários, acessibilidade
    data/              banco (drift), repositórios, importação/exportação CSV
    domain/            modelos, normalização, casamento, eventos e hash
    features/
      unidades/        início e lista de unidades carregadas
      importacao/      importar CSV e relatório de qualidade
      salas/           lista de salas com progresso
      conferencia/     câmera, sobreposição de caixas, lista da sala
      bem/             ficha do bem, estado, observação, foto
      exportacao/      exportar CSV e JSON
      configuracoes/   conferente, aparelho, marca
  test/
```

## 3. Marca trocável

- `assets/brand/brand.json`:
  ```json
  {
    "appName": "Tombox",
    "instituicao": "Tribunal de Justiça do Estado do Pará",
    "siglaInstituicao": "TJPA",
    "logo": "assets/brand/logo.png",
    "cores": {
      "primaria": "#0B3D6E",
      "secundaria": "#C9A227",
      "fundo": "#F7F8FA",
      "texto": "#1A1A1A"
    }
  }
  ```
  As cores acima são provisórias e serão ajustadas ao manual de marca do TJPA.
- `lib/brand/` lê esse arquivo e gera o `ThemeData` (claro e escuro).
- Se o arquivo do logo não existir, mostrar o nome do app em texto. O app não pode quebrar sem logo.
- Criar também `assets/brand/presets/neutro.json` (sem instituição) para provar que a troca funciona.
- Nenhum outro arquivo pode conter "TJPA", "Tribunal" ou cores da instituição.

## 4. Modelo de dados (drift)

- **Unidade**: id, nome, data de importação, arquivo de origem.
- **Local**: id, unidade_id, nome, tipo (comarca, prédio, andar, sala), pai_id, caminho completo.
- **Bem**: tombamento (normalizado, chave), unidade_id, descrição, categoria, local_esperado_id, responsável (matrícula), número de série, fabricante, modelo, extras (JSON com colunas não reconhecidas).
- **ConferenciaSala**: local_id, status (não iniciada, em andamento, fechada), início, fim, conferente.
- **Evento** (imutável, nunca é editado nem apagado):
  - id (UUID v4), seq (inteiro crescente por aparelho), tipo, tombamento (opcional), local_id, aparelho_id, conferente, timestamp (ISO 8601 com fuso), payload (JSON), hash_foto (opcional), hash_anterior, hash.
  - Tipos: `LEITURA`, `CONFIRMACAO`, `ESTADO`, `OBSERVACAO`, `FOTO`, `ABERTURA_SALA`, `FECHAMENTO_SALA`, `LEITURA_MANUAL`.
  - `hash = SHA-256(JSON canônico do evento sem o campo hash)`, com chaves em ordem alfabética. O primeiro evento usa `hash_anterior = "0" * 64`.
- O estado atual de cada bem (encontrado, em outra sala, não localizado) é calculado a partir dos eventos, não guardado como verdade separada.

## 5. Importação de CSV

Formato de entrada (cabeçalho na primeira linha):

| Coluna | Obrigatória | Observação |
|---|---|---|
| tombamento | sim | número da plaqueta |
| descricao | sim | |
| local | sim | caminho: `Comarca / Prédio / Andar / Sala` |
| categoria | não | |
| responsavel_matricula | não | |
| numero_serie | não | |
| fabricante | não | |
| modelo | não | |

Regras:
- Detectar separador `;`, `,` ou tabulação. O `;` é o padrão do Excel em português.
- Detectar codificação UTF-8 (com ou sem BOM) ou Windows-1252.
- Reconhecer cabeçalhos com variações (maiúsculas, acentos, espaços, sinônimos como "patrimonio", "nº tombamento", "sala").
- Normalizar tombamento: remover espaços, pontos e hífens; trocar letra O por zero quando o resto for numérico; manter zeros à esquerda.
- Normalizar nomes de sala para comparação ("Sala 3", "SL 03" e "sala03" viram a mesma sala), mantendo o nome original para exibição.
- Colunas desconhecidas vão para `extras`.
- Não abortar no primeiro erro: gerar relatório de qualidade com duplicados, tombamentos inválidos, linhas sem local e linhas com número de colunas errado, indicando a linha.
- Reimportar a mesma unidade atualiza pelo tombamento, sem duplicar.

Incluir `assets/demo/unidade_demo.csv` com uma unidade sintética de 15 salas e cerca de 300 bens. Gerar com script em `/tools` (Python + Faker pt_BR) e versionar o CSV gerado.

## 6. Casamento da leitura com a lista (núcleo, com testes)

Entrada: textos lidos pelo OCR (com posição no quadro) e códigos lidos pelo leitor de código de barras.

1. **Normalizar o texto lido:** maiúsculas, remover espaços, pontos e hífens. Em sequências majoritariamente numéricas, aplicar as trocas O→0, I→1, L→1, B→8, S→5, Z→2, G→6.
2. **Filtrar candidatos:** manter tokens com tamanho entre o menor e o maior tamanho de tombamento da unidade (com folga de 1) e pelo menos 60% de dígitos.
3. **Distância ponderada:** Levenshtein em que a substituição entre pares confundíveis (0/O, 1/I/L, 8/B, 5/S, 2/Z, 6/G) custa 0,3 e as demais custam 1.
4. **Ordem de busca:** primeiro os bens esperados da sala atual, depois os da unidade.
5. **Decisão:**
   - igual a um tombamento: leitura confirmada;
   - melhor distância ≤ 1,0, único melhor, e vantagem de pelo menos 0,5 sobre o segundo: leitura provável, que pede confirmação com um toque;
   - fora disso: descartar.
   - Código de barras ou QR com valor exato: confirmado.
6. **Estabilidade:** só mostrar a caixa quando o mesmo tombamento aparecer em pelo menos 2 quadros dentro de 1 segundo.
7. **Classificação:**
   - verde: o bem é esperado nesta sala;
   - amarelo: o bem é da unidade, mas de outra sala;
   - vermelho: código lido com confiança que não existe na unidade.

Testes obrigatórios: casos com cada troca confundível, número com zero à esquerda, número parcialmente lido, empate entre dois candidatos (deve descartar), leitura de outra sala, número inexistente.

## 7. Telas

1. **Início:** unidades carregadas, botões "Importar CSV" e "Carregar dados de demonstração".
2. **Relatório de importação:** totais, problemas encontrados por tipo e por linha, botão para continuar.
3. **Salas:** lista agrupada por prédio e andar, progresso "lidos x de y" e status.
4. **Conferência da sala (tela principal):**
   - câmera em tela cheia com caixas coloridas sobre as plaquetas;
   - contador no topo: "x de y lidos";
   - leituras prováveis aparecem como chip "12345? toque para confirmar";
   - painel inferior com abas: lidos, faltando, de outra sala;
   - botões: lanterna, modo uma plaqueta (aproxima e lê uma por vez) e busca manual (último recurso, gera evento `LEITURA_MANUAL`);
   - vibração curta a cada leitura confirmada;
   - botão "Fechar sala" com resumo antes de confirmar.
5. **Ficha do bem:** dados do cadastro, estado (bom, regular, ruim, inservível), observação e foto tirada na hora.
6. **Exportar:**
   - CSV de resultado: `tombamento;descricao;local_esperado;local_encontrado;situacao;estado;observacao;forma_leitura;conferente;data_hora`. Situação: encontrado, outra_sala, nao_localizado. Forma de leitura: ocr, codigo, manual.
   - JSON com todos os eventos e a cadeia de hashes.
   - Neutralizar células que começam com `= + - @` (CWE-1236).
   - Compartilhar pelo `share_plus`.
7. **Configurações:** nome e matrícula do conferente, identificador do aparelho (gerado uma vez), versão e marca ativa.

## 8. Desempenho da câmera

- Processar quadros fora da thread da interface.
- Limitar o OCR a um quadro a cada 150 a 250 ms, ajustável.
- No máximo 15 detecções por quadro.
- Suavizar a posição das caixas entre quadros (fator 0,6) e remover a caixa 1,5 s depois que sumir.
- Guardar em memória os tombamentos já confirmados na sessão, para não reprocessar.

## 9. Etapas de implementação

Cada etapa termina com `flutter analyze` sem erros, testes passando e um commit.

- **Etapa 0:** projeto Flutter em `/app`, estrutura de pastas, marca trocável, tema, rotas, telas vazias navegáveis, `docs/BIBLIOTECAS.md`.
- **Etapa 1:** banco drift, importação de CSV com relatório, dados de demonstração, telas Início, Relatório e Salas funcionando. Testes de importação e normalização.
- **Etapa 2:** câmera, OCR e código de barras num pipeline, casamento com a lista, caixas coloridas, contador, painel de lidos e faltando, confirmação com um toque. Testes do casamento.
- **Etapa 3:** ficha do bem, estado, observação, foto, fechamento de sala, exportação CSV e JSON.
- **Etapa 4:** eventos imutáveis com cadeia de hashes e verificação da cadeia. Testes da cadeia.

Etapas futuras (não fazer agora): cadastro de bem novo com IA no aparelho e QR provisório; termo de responsabilidade assinado em PDF; pacote assinado com Ed25519; pareamento com o gestor por QR e Wi-Fi local; banco criptografado.

## 10. Critério de pronto para o vídeo de 29/10

Num celular Android, com o CSV de demonstração e plaquetas sintéticas impressas: escolher uma sala, apontar a câmera para várias plaquetas, ver caixas verdes, amarelas e vermelhas aparecerem, confirmar uma leitura provável com um toque, ver o que falta e exportar o CSV de resultado.
