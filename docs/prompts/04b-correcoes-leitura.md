# Prompt 04b: correções na leitura de plaquetas (revisão da Etapa 2)

Revisei `lib/domain/casamento/` e `lib/features/conferencia/pipeline/camera_pipeline.dart`. A lógica segue a especificação, mas há problemas que vão falhar no teste real. Corrija com testes.

## 1. Texto da plaqueta junto com outras palavras na mesma linha (crítico)

Hoje o pipeline manda a linha inteira do OCR (`line.text`) para o motor, e a normalização remove os espaços antes de avaliar. Uma plaqueta que diz `PATRIMÔNIO 010001`, `TJPA Nº 010.001` ou `ESTADO DO PARÁ 0100O1` vira um único token como `PATRIMÔNIO010001`. O token fica maior que o tamanho máximo e é descartado. Plaquetas reais quase sempre têm texto junto do número.

Correção:
- Extrair candidatos de cada linha de duas formas e avaliar cada um separadamente:
  - cada palavra (`line.elements`), usando a caixa da própria palavra;
  - sequências encontradas por expressão regular de caracteres numéricos ou confundíveis com separadores internos (por exemplo `[0-9OILBSZG][0-9OILBSZG.\- ]{2,}[0-9OILBSZG]`), normalizadas depois.
- A normalização não pode juntar palavras diferentes num token só.
- Testes obrigatórios: `PATRIMÔNIO 010001`, `TJPA Nº 010.001`, `ESTADO DO PARÁ 0100O1`, `Nº 010-001`, linha só com texto (deve descartar), linha com dois números de plaquetas diferentes (deve achar os dois).

## 2. Limite de detecções por quadro

O contador `detecCount` soma todas as linhas de texto, inclusive as que não são número de plaqueta. Numa sala com cartazes e etiquetas, o limite de 15 acaba antes de chegar nas plaquetas. Conte só os candidatos que passaram no filtro de formato.

## 3. Código de barras vermelho falso

Hoje qualquer código de barras que não esteja na unidade vira caixa vermelha. Monitores, impressoras e caixas têm códigos EAN do fabricante, e QR de outros sistemas também aparecem. Isso vai encher a tela de vermelho.

Correção: só classificar como vermelho quando o valor normalizado tiver formato de tombamento (mesma regra de `validarCandidato`). Fora disso, ignorar o código. Testes: EAN-13 de produto (ignorar), QR com URL (ignorar), código com formato de tombamento fora da unidade (vermelho).

## 4. Coordenadas das caixas na tela

As caixas do ML Kit vêm no espaço da imagem da câmera, que pode estar rotacionada (orientação do sensor) e em escala diferente da prévia. Garanta a conversão correta (rotação de 90 ou 270 graus, espelhamento se for câmera frontal, escala e corte da prévia) e crie um modo diagnóstico, ligado em Configurações, que:
- desenha também os textos brutos lidos pelo OCR, em cinza;
- mostra o tempo de processamento por quadro e quantos quadros por segundo estão sendo analisados.

Esse modo será usado para calibrar no celular e para medir desempenho no pitch.

## Critério de pronto

`flutter analyze` sem erros, todos os testes passando (incluindo os novos acima), commit "app: correções da leitura de plaquetas" e resumo em `docs/respostas/04b-correcoes-leitura.md`.
