# Prompt 06: Etapa 4 (eventos com cadeia de hashes)

Execute a Etapa 4 da seção 9 de `processamento/Tombox/docs/specs/app-mobile.md`.

Entregas:
1. Cada evento com `seq` crescente por aparelho, `hash_anterior` e `hash = SHA-256(JSON canônico sem o campo hash)`, chaves em ordem alfabética. Primeiro evento com `hash_anterior` igual a 64 zeros.
2. Função de verificação da cadeia que aponta o primeiro evento quebrado.
3. Tela em Configurações que mostra a verificação da cadeia ("cadeia íntegra, 342 eventos").
4. O JSON exportado inclui a cadeia completa e o hash do último evento.
5. Defina o formato do evento e do pacote exportado em `processamento/Tombox/schema/evento.schema.json` e `pacote.schema.json` (JSON Schema), para o sistema do gestor usar depois.
6. Testes: cadeia íntegra, evento alterado, evento removido, evento fora de ordem.

Commit "app: etapa 4, eventos encadeados e verificação".
