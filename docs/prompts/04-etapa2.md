# Prompt 04: Etapa 2 (leitura de plaquetas)

Execute a Etapa 2 da seção 9 de `processamento/Tombox/docs/specs/app-mobile.md`. Esta é a parte mais importante do projeto.

Entregas:
1. Módulo de casamento em `lib/domain/` exatamente como a seção 6: normalização com trocas confundíveis, filtro de candidatos, Levenshtein ponderado (0,3 para pares confundíveis), busca primeiro na sala e depois na unidade, regras de decisão (confirmado, provável, descartado), estabilidade de 2 quadros em 1 segundo e classificação verde, amarelo e vermelho. Esse módulo não pode depender de Flutter, para ser testado isoladamente.
2. Testes do casamento com todos os casos listados na seção 6, mais casos de borda que você identificar.
3. Pipeline de câmera único: o mesmo quadro alimenta OCR (`google_mlkit_text_recognition`) e código de barras (`google_mlkit_barcode_scanning`), processado fora da thread da interface, com os parâmetros da seção 8 (intervalo de 150 a 250 ms, máximo de 15 detecções, suavização 0,6, caixa some após 1,5 s, cache de confirmados).
4. Tela de Conferência da sala (seção 7, item 4): câmera em tela cheia, caixas coloridas sobre as plaquetas, contador "x de y lidos", chip de leitura provável com confirmação em um toque, painel inferior com abas lidos, faltando e de outra sala, lanterna, modo uma plaqueta e busca manual (evento LEITURA_MANUAL), vibração ao confirmar.
5. Cada leitura confirmada grava um evento LEITURA ou CONFIRMACAO no banco.

Critério de pronto: no celular, com o CSV de demonstração e plaquetas impressas, as caixas aparecem nas cores certas e o contador sobe. Commit "app: etapa 2, leitura de plaquetas e casamento com a lista".

Se o OCR ficar instável, me avise com números (taxa de acerto em 20 plaquetas) antes de mudar a abordagem.
