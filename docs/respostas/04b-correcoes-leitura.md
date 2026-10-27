# Resposta: Prompt 04b Concluído (Correções na Leitura de Plaquetas - Revisão da Etapa 2)

Data: 27/10/2026  
Status: Concluído com sucesso (Zero erros no linter, 37 testes passando, todos os casos de teste do prompt validados).

---

## 1. O que foi implementado

### 1.1 Extração de Candidatos em Linhas com Texto Junto
- **Problema anterior**: Plaquetas reais que continham textos junto do número (como `PATRIMÔNIO 010001`, `TJPA Nº 010.001` ou `ESTADO DO PARÁ 0100O1`) uniam tudo em um único token (`PATRIMÔNIO010001`), excedendo o tamanho máximo permitido e sendo descartadas.
- **Solução implementada em `lib/domain/casamento/casamento_motor.dart`**:
  - `extrairCandidatosDeTexto(String linha)`:
    - Extrai sequências numéricas e com trocas confundíveis intercaladas por pontuação/separadores (`[0-9OILBSZG][0-9OILBSZG.\- ]{1,}[0-9OILBSZG]`).
    - Avalia palavras individuais da linha (`line.elements`), preservando a caixa delimitadora (`boundingBox`) específica de cada palavra para que a sobreposição gráfica recaia exatamente sobre a plaqueta.
    - Se a linha contiver múltiplos bens (ex: `010001 e 010002`), `extrairCandidatosDeTexto` e `avaliarLinhaCompleta` extraem e casam ambos independentemente.
    - Linhas puramente de texto descritivo (ex: `"TRIBUNAL DE JUSTIÇA DO ESTADO DO PARÁ"`) são descartadas e não consomem o limite de detecções.

### 1.2 Limite de Detecções por Quadro (15 detecções)
- **Problema anterior**: Linhas de texto descartadas ou informativas contavam para o limite de 15 detecções por quadro em `camera_pipeline.dart`.
- **Solução implementada**: O contador `detecCount` é incrementado estritamente para candidatos que passaram pelo filtro de formato (`validarCandidato`) ou códigos de barra válidos, impedindo que textos irrelevantes no ambiente consumam o orçamento do frame.

### 1.3 Eliminação de Falsos Vermelhos em Códigos de Barras
- **Problema anterior**: Qualquer código de barras comercial (como EAN-13 de fabricantes em monitores ou QR codes de URLs) que não pertencia à unidade gerava uma caixa vermelha alarmista na tela.
- **Solução implementada**:
  - `avaliarCodigoBarras` valida previamente o formato com `validarCandidato(limpo)`.
  - Códigos fora do formato de patrimônio (ex: EAN-13 `7891234567890` ou URLs `https://...`) são sumariamente descartados/ignorados.
  - Somente códigos com padrão e tamanho de tombamento legítimo que não constem na base da unidade são sinalizados com caixa vermelha.

### 1.4 Coordenadas, Escala e Modo Diagnóstico
- **Mapeamento de Coordenadas (`camera_overlay_painter.dart`)**:
  - Conversão de coordenadas levando em conta a rotação do sensor (`sensorOrientation` 90° / 270°), espelhamento de câmera frontal e enquadramento `BoxFit.cover` centralizado na tela.
- **Modo Diagnóstico (Pitch e Calibração)**:
  - Adicionado `modoDiagnosticoProvider` gerenciado via Riverpod.
  - Switch de ativação em **Configurações** (`configuracoes_screen.dart`).
  - Quando ativo, o pintor renderiza:
    1. Caixas e textos brutos lidos pelo OCR em cinza translúcido (`textosBrutos`).
    2. HUD superior de telemetria em tempo real com **FPS**, **tempo de processamento em ms** e quantidade de caixas ativas.

---

## 2. Testes Unitários de Regressão e Validação

Arquivo: `test/casamento/casamento_test.dart`
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
00:00 +13: CasamentoMotor - Regras de Decisão e Classificação Prompt 04b: Extração de candidatos com texto junto na mesma linha
00:00 +14: CasamentoMotor - Regras de Decisão e Classificação Prompt 04b: Códigos de barras espúrios descartados vs tombamento vermelho
00:00 +15: EstabilidadeFiltro - Temporal e Suavização Exige pelo menos 2 quadros dentro de 1 segundo para ser estável
00:00 +16: EstabilidadeFiltro - Temporal e Suavização Descarta quadros antigos (> 1s) para cálculo de estabilidade
00:00 +17: EstabilidadeFiltro - Temporal e Suavização Suaviza posição da caixa e remove após 1.5s sem detecção
00:00 +18: All tests passed!
```

Suíte global: 37 testes passaram sem nenhuma falha.

---

## 3. Commit Realizado

* Mensagem: `"app: correções da leitura de plaquetas"`
