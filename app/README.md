# Tombox Mobile (App do Conferente)

Aplicativo móvel offline-first desenvolvido em Flutter para o Desafio 2 (Inventário Patrimonial Digital) do Hackathon TJPA 2026.

---

## 1. Pré-requisitos

* **Flutter SDK**: `^3.47.8` (canal estável)
* **Dart SDK**: `^3.13.7`
* **Java**: OpenJDK 17 (`JAVA_HOME`)
* **Android SDK**: API 35/36 com command-line tools e build-tools configurados
* Dispositivo Android (ou emulador) com versão Android 7.0+ (minSdk 24).

---

## 2. Como Rodar o Aplicativo

No terminal, a partir do diretório `processamento/Tombox/app`:

```bash
# 1. Obter as dependências
flutter pub get

# 2. Executar no dispositivo conectado ou emulador
flutter run
```

---

## 3. Testes Automatizados e Análise de Código

```bash
# Executar a análise estática (linter com zero avisos)
flutter analyze

# Executar a suíte de testes unitários e de widgets
flutter test
```

---

## 4. Marca Trocável (Desacoplamento Visual)

O Tombox possui isolamento total entre lógica de negócio e identidade institucional:
* A configuração padrão fica em `assets/brand/brand.json`.
* O preset neutro alternativo fica em `assets/brand/presets/neutro.json`.
* Para alternar a marca em tempo de execução, acesse a tela de **Configurações** no app e selecione a identidade desejada.
* Se a imagem do logotipo (`logo.png`) não existir, o aplicativo renderiza automaticamente um fallback tipográfico e vetorial sem falhas.

---

## 5. Estrutura de Pastas

```
app/
  assets/brand/        logo e brand.json (marca trocável)
  assets/brand/presets/ preset neutro
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
