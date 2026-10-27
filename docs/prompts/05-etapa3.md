# Prompt 05: Etapa 3 (ficha do bem, fechamento e exportação)

Execute a Etapa 3 da seção 9 de `processamento/Tombox/docs/specs/app-mobile.md`.

Entregas:
1. Ficha do bem: dados do cadastro, estado (bom, regular, ruim, inservível), observação e foto tirada na hora (não aceitar foto da galeria). Cada ação gera um evento (ESTADO, OBSERVACAO, FOTO), com o SHA-256 da foto no evento.
2. Fechamento de sala: resumo (encontrados, faltando, de outra sala) e evento FECHAMENTO_SALA. Sala fechada fica somente leitura.
3. Exportação: CSV de resultado com as colunas da seção 7, item 6, e JSON com todos os eventos. Neutralizar células que começam com `= + - @`. Compartilhar com `share_plus`.
4. Configurações: nome e matrícula do conferente e identificador do aparelho gerado uma vez.
5. Testes da exportação (colunas, situação calculada a partir dos eventos, neutralização de fórmulas).

Critério de pronto: conferir uma sala, fechar e exportar o CSV pelo WhatsApp. Commit "app: etapa 3, ficha do bem, fechamento de sala e exportação".
