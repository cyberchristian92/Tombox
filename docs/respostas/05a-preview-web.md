# Resposta: Prompt 05a Concluído (Prévia do App no Chrome)

Data: 27/10/2026  
Status: Concluído com sucesso (App rodando no Chrome, dados de demonstração carregados, zero regressões no Android).

---

## 1. O que foi implementado

O objetivo deste prompt foi habilitar a execução visual do app no Google Chrome (macOS) mantendo o alvo principal estritamente no Android, com foco em validação de design, fluxo de telas e experiência do usuário.

### 1.1 Suporte à Plataforma Web & Drift SQLite WASM
- Inicialização da pasta web no Flutter (`app/web/`).
- Para suportar a persistência com `drift` sem regressão no Android:
  - Adicionados os binários `sqlite3.wasm` e o worker `drift_worker.js` em `app/web/`.
  - Configurado `DriftWebOptions` em `lib/data/local/app_database.dart`:
    ```dart
    AppDatabase([QueryExecutor? e])
        : super(
            e ??
                driftDatabase(
                  name: 'tombox_db',
                  web: DriftWebOptions(
                    sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                    driftWorker: Uri.parse('drift_worker.js'),
                  ),
                ),
          );
    ```
  - Com essa configuração, no Chrome o app utiliza o motor WebAssembly oficial do SQLite com backend em IndexedDB persistente, enquanto no Android continua utilizando o driver nativo SQLite via `sqlite3_flutter_libs`.

### 1.2 Isolamento de Câmera e ML Kit na Web (`ConferenciaScreen`)
- O hardware de câmera e as bibliotecas ML Kit (OCR e Barcode) são dependências nativas mobile do Android.
- Em `lib/features/conferencia/screens/conferencia_screen.dart`:
  - Utilizado `kIsWeb` no ciclo de inicialização `_inicializarPipelineECamera()` para contornar a inicialização de hardware na web.
  - Implementada a visão de fallback específica para web na área do viewport da câmera:
    - Ícone indicativo `videocam_off_outlined`.
    - Mensagem em destaque: **"Câmera disponível apenas no app Android"**.
    - Subtítulo informativo: *"Esta é uma prévia web visual para validação de design e navegação."*
    - Botão interativo **"Simular Leitura de Plaqueta"**: permite disparar o pipeline de validação e conferência (lendo um bem esperado e movendo-o para a aba "Lidos"), permitindo ao avaliador testar o fluxo completo da tela.
  - Toda a estrutura da tela de conferência foi preservada intacta:
    - Indicador de progresso superior e contador ("X de Y bens conferidos").
    - Três abas de conferência: **Lidos**, **Faltando** e **Outra Sala**.
    - Bottom sheet com detalhes do bem, botões de ação e navegação.

---

## 2. Dados de Demonstração Carregados

- O app foi iniciado via `flutter run -d chrome --web-port=8080`.
- Na tela inicial de **Unidades & Carga**:
  - Acionado o botão de importação do arquivo de demonstração (`unidade_demo.csv` - Comarca de Breves).
  - O motor de importação processou 302 linhas, gerando:
    - 1 unidade cadastrada: **Comarca de Breves** (Fórum Juiz Manoel Ribeiro).
    - 18 salas/locais cadastrados (distribuídos entre Prédio Principal e Anexo, Térreo e 1º Andar).
    - 300 bens patrimoniais associados com plaquetas reais, números de tombamento, descrições e estados de conservação.
- Navegação testada e validada:
  - **Tela de Unidades**: lista a Comarca de Breves com total de bens e salas.
  - **Tela de Salas**: lista as 18 salas agrupadas por prédio/pavimento, mostrando barras de progresso de conferência.
  - **Tela de Conferência**: renderiza os bens esperados da sala, permitindo navegar entre as abas e simular leituras.

---

## 3. Validação de Integridade e Compatibilidade Android

Todas as validações obrigatórias foram executadas com sucesso:

1. **Análise Estática (`flutter analyze`)**:
   ```text
   Analyzing app...
   No issues found! (ran in 8.0s)
   ```
2. **Testes de Regressão (`flutter test`)**:
   - 37 testes unitários e de widget executados.
   - 100% de aprovação (0 falhas).
3. **Compilação Android Debug (`flutter build apk --debug`)**:
   ```text
   ✓ Built build/app/outputs/flutter-apk/app-debug.apk
   ```
   Compilação bem-sucedida, comprovando que o suporte web não causou nenhuma regressão no ecossistema Android.
4. **Compilação Web (`flutter build web`)**:
   ```text
   ✓ Built build/web
   ```

---

## 4. Estado Atual e Disponibilidade

Conforme solicitado, o processo `flutter run -d chrome` foi **mantido ativo em segundo plano**.
O app continua aberto e acessível na janela do Google Chrome para avaliação visual do design e navegação.

* **Commit realizado**: `"app: prévia web para revisão de design"`
