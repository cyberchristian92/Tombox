# Resposta: Etapa 2 Concluída (Leitura de Plaquetas e Casamento com a Lista)

Data: 27/10/2026  
Status: Concluído com sucesso (Zero erros no linter, 35 testes passando, 16 testes unitários específicos do motor de casamento).

---

## 1. O que foi implementado

### 1.1 Módulo Puro de Casamento (`lib/domain/casamento/`)
Desenvolvido em Dart puro (sem nenhuma dependência do Flutter ou UI), permitindo execução e testes unitários 100% isolados:
1. **`CasamentoModels` (`casamento_models.dart`)**:
   - `RectDeteccao`: Representação pura de geometria e interpolação linear (`lerp`) sem dependência de `dart:ui`.
   - `DecisaoLeitura`: `confirmado`, `provavel`, `descartado`.
   - `ClassificacaoPlaqueta`:
     - **Verde**: Bem esperado na sala atual.
     - **Amarelo**: Bem pertencente à unidade, porém alocado em outra sala.
     - **Vermelho**: Código lido com confiança (ex: código de barras/QR) que não pertence à unidade.
   - `ResultadoCasamento`: Encapsula texto lido, normalizado, tombamento identificado, decisão, cor da caixa e bounding box.

2. **Distância Ponderada de Levenshtein (`distancia_ponderada.dart`)**:
   - Matriz DP de Levenshtein.
   - Pares confundíveis bidirecionais de OCR (`0/O`, `1/I`, `1/L`, `I/L`, `8/B`, `5/S`, `2/Z`, `6/G`) possuem custo reduzido de **0.3** por substituição.
   - Demais substituições, inserções e deleções possuem custo integral **1.0**.

3. **Motor de Casamento (`casamento_motor.dart`)**:
   - **Normalização com trocas**: Converte para maiúsculas, remove espaços e pontuações (`. - / \`); quando a sequência for majoritariamente numérica (>= 50%), substitui letras confundíveis por dígitos (`O->0`, `I/L->1`, `B->8`, `S->5`, `Z->2`, `G->6`).
   - **Filtro de Candidatos**: Exige tamanho dentro da faixa dos bens da unidade (com tolerância de ±1) e no mínimo 60% de dígitos.
   - **Ordem de Busca e Regras de Decisão**:
     - *Busca Exata (distância 0.0)*: Avalia primeiro a sala atual (verde), depois a unidade (amarelo).
     - *Distância Ponderada*: Seleciona candidatos com distância $\le 1.0$. Exige que o melhor candidato tenha vantagem mínima de $\ge 0.5$ sobre o segundo para ser considerado **leitura provável**; em caso de empate ou margem insuficiente, o token é descartado.
     - *Códigos de Barras*: Avaliados com alta confiança (verde se da sala, amarelo se de outra sala, vermelho se inexistente na base).

4. **Filtro de Estabilidade Temporal e Suavização (`estabilidade_filtro.dart`)**:
   - Requer detecção em pelo menos **2 quadros dentro de uma janela de 1 segundo** antes de confirmar a plaqueta.
   - Suaviza a caixa delimitadora entre quadros consecutivos com interpolação linear (`lerp(0.6)`).
   - Mantém as caixas ativas por até **1,5 s** após deixarem de ser detectadas.
   - Cache de confirmação na sessão para evitar reprocessamento ou vibrações repetidas.

---

### 1.2 Pipeline de Câmera Unificado (`lib/features/conferencia/pipeline/`)
1. **Quadro Único**: O mesmo frame da câmera (`CameraImage`) é convertido via `CameraImageConverter` em `InputImage` do ML Kit e processado simultaneamente por:
   - `google_mlkit_text_recognition` (OCR Latin)
   - `google_mlkit_barcode_scanning` (Códigos de barra e QR codes)
2. **Desempenho e Limites (Seção 8 da spec)**:
   - Throttling de tempo: opera com intervalo de **200 ms** entre processamentos (faixa recomendada de 150 a 250 ms).
   - Limite por quadro: máximo de **15 detecções** processadas por frame.
   - Stream reativo de detecções alimentando a interface gráfica.

---

### 1.3 Registro de Eventos e Feedback Tátil (`lib/domain/eventos/evento_service.dart`)
- Registro de eventos imutáveis no SQLite (`LEITURA`, `CONFIRMACAO`, `LEITURA_MANUAL`, `FECHAMENTO_SALA`).
- Encadeamento criptográfico SHA-256 sobre JSON canônico com chaves ordenadas.
- Disparo de vibração tátil média (`HapticFeedback.mediumImpact()`) a cada leitura confirmada.

---

### 1.4 Tela de Conferência da Sala (`lib/features/conferencia/screens/conferencia_screen.dart`)
- **Visor em Tela Cheia**: Pré-visualização da câmera com fallback defensivo para desktop/emulador sem câmera física.
- **Sobreposição de Caixas (`CameraOverlayPainter`)**: Caixas desenhadas dinamicamente em tempo real sobre as plaquetas nas cores verde, amarela ou vermelha, com badges identificadoras e indicador `?` para prováveis.
- **Contador Superior**: Exibe em destaque "X de Y bens conferidos" e botão para "Fechar Sala".
- **Chip de Leitura Provável**: Quando uma plaqueta com OCR ruidoso atinge o critério de provável, surge o chip flutuante amarelo *"X? Toque para confirmar leitura provável"*, que confirma com 1 toque.
- **Abas Inferiores**:
  - *Lidos*: Bens esperados já conferidos.
  - *Faltando*: Bens esperados que ainda não foram localizados.
  - *Outra Sala*: Bens encontrados que pertencem a outra sala da unidade.
- **Controles da Câmera**:
  - Lanterna (toggle torch/off).
  - Modo Uma Plaqueta (zoom 2.0x com foco central).
  - Botão de busca manual de tombamento (registra evento `LEITURA_MANUAL`).
- **Fechamento de Sala**: Dialog com contagem de faltantes e transição para tela de exportação ao fechar.

---

## 2. Testes e Validação de Qualidade

### 2.1 Análise Estática (`flutter analyze`)
```text
Analyzing app...                                                
No issues found! (ran in 8.1s)
```

### 2.2 Testes Unitários do Motor de Casamento (`test/casamento/casamento_test.dart`)
16 testes unitários cobrindo todos os cenários da especificação:
```text
00:00 +0: Distância Ponderada de Levenshtein Distância entre strings idênticas é 0.0
00:00 +1: Distância Ponderada de Levenshtein Pares confundíveis (0/O, 1/I, 1/L, 8/B, 5/S, 2/Z, 6/G) custam 0.3
00:00 +2: Distância Ponderada de Levenshtein Múltiplos pares confundíveis somam 0.3 por substituição
00:00 +3: Distância Ponderada de Levenshtein Substituição de caracteres normais não-confundíveis custa 1.0
00:00 +4: Distância Ponderada de Levenshtein Inserção e deleção custam 1.0
00:00 +5: CasamentoMotor - Regras de Decisão e Classificação Leitura exata na sala atual retorna CONFIRMADO e VERDE
00:00 +6: CasamentoMotor - Regras de Decisão e Classificação Leitura exata de outra sala retorna CONFIRMADO e AMARELO
00:00 +7: CasamentoMotor - Regras de Decisão e Classificação Código de barras exato que não existe na unidade retorna VERMELHO
00:00 +8: CasamentoMotor - Regras de Decisão e Classificação OCR com normalização de trocas confundíveis resulta em CONFIRMADO
00:00 +9: CasamentoMotor - Regras de Decisão e Classificação Preserva zeros à esquerda e pontuações na leitura do OCR
00:00 +10: CasamentoMotor - Regras de Decisão e Classificação Leitura provável quando distância <= 1.0 e vantagem >= 0.5
00:00 +11: CasamentoMotor - Regras de Decisão e Classificação Descarta quando houver empate ou vantagem < 0.5 entre dois candidatos
00:00 +12: CasamentoMotor - Regras de Decisão e Classificação Descarta tokens que não atendem ao tamanho mínimo ou % de dígitos
00:00 +13: EstabilidadeFiltro - Temporal e Suavização Exige pelo menos 2 quadros dentro de 1 segundo para ser estável
00:00 +14: EstabilidadeFiltro - Temporal e Suavização Descarta quadros antigos (> 1s) para cálculo de estabilidade
00:00 +15: EstabilidadeFiltro - Temporal e Suavização Suaviza posição da caixa e remove após 1.5s sem detecção
00:00 +16: All tests passed!
```

### 2.3 Execução Geral da Suíte de Testes (`flutter test`)
35 testes cobrindo Banco Drift, Importador CSV, Brand/Temas, Rotas e Casamento:
```text
00:01 +35: All tests passed!
```

---

## 3. Commit Realizado

* Mensagem: `"app: etapa 2, leitura de plaquetas e casamento com a lista"`
