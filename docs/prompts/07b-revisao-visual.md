# Prompt 07b: revisão visual do redesenho

Revisei as capturas em `docs/screenshots/`.

## 1. Capturas inválidas (refazer)

Os 9 arquivos de `docs/screenshots/` são idênticos (mesmo MD5): todos mostram a tela de Início. Nenhuma outra tela foi capturada. Refaça navegando de verdade até cada tela antes de capturar, e confirme que os arquivos são diferentes entre si (`md5`). Para Ficha, abra um bem real do demo. Para Sala, abra uma sala com bens. Para os modos escuros, troque o tema antes de capturar.

## 2. Erros na tela de Início

1. Os quatro CartaoEstatistica mostram o aviso "BOTTOM OVERFLOWED BY 15 PIXELS". Corrija o layout do componente: altura flexível ou proporção ajustada, número e rótulo sem estourar. Teste em 360 dp de largura e com fonte do sistema em 130%.
2. Números no padrão brasileiro: "0,0%" e não "0.0%"; milhar com ponto. Use `intl` com locale `pt_BR` em todo o app.
3. "Continuar conferência" só aparece se existir sala com status "em andamento". Se nenhuma sala foi iniciada, troque por "Começar conferência", com a primeira sala pendente sugerida.
4. "Olá, Rosilene" está fixo no código. Use o nome do conferente configurado em Mais. Se não houver nome, mostre só "Olá" e um aviso discreto para configurar o perfil.
5. Os textos auxiliares dos cartões ("Base ativa", "Nenhuma") não dizem nada. Use: Bens → "na unidade"; Conferidos → "+N hoje"; Divergências → "abertas"; Salas pendentes → "de 15".

## 2b. Outras telas (segunda rodada de capturas)

Na segunda rodada, 6 capturas ficaram diferentes, mas:
1. `01-inicio-dark.png` é igual a `01-inicio.png`, e `06-ficha.png` e `06-ficha-dark.png` são iguais a `05-bens.png`. Faltam a Ficha do bem e os modos escuros de verdade.
2. A tela de Locais (`02-locais.png`) aparece inteira acinzentada, como se houvesse uma camada escura por cima (diálogo, folha ou estado desabilitado). Descubra a causa e corrija.
3. Em Bens, o chip de local do CartaoBem fica cortado ("Té..."). Use o caminho curto ("Térreo › Sala 101") e deixe o chip ocupar a largura disponível; se não couber, mostre só a sala.
4. A tela Mais foi capturada em tema escuro enquanto as outras estão em claro. Capture tudo em claro e, separadamente, Início e Ficha em escuro.

## 3. Antes de entregar

1. Gere as capturas reais de todas as telas listadas no prompt 07, em claro, e Início e Ficha em escuro.
2. Olhe cada uma e verifique: nenhum aviso de overflow, nenhum texto cortado, números em formato brasileiro, nenhuma tela vazia sem EstadoVazio.
3. Liste no resumo o que você corrigiu ao olhar as capturas.

Commit "app: revisão visual do redesenho", resumo em `docs/respostas/07b-revisao-visual.md` e `git push origin main`.
