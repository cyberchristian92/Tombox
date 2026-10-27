# Prompt 01b: preparar o ambiente e iniciar a Etapa 0

Seu plano da Etapa 0 está aprovado. Antes, prepare o ambiente neste Mac (Apple Silicon, macOS).

## 1. Instalar o ambiente

Execute e verifique cada passo antes de seguir para o próximo:

1. Verifique se o Homebrew existe (`brew --version`). Se não existir, pare e me avise: a instalação pede a senha do usuário e ele mesmo vai digitar.
2. `brew install --cask flutter`
3. `brew install openjdk@17` e configure `JAVA_HOME` no `~/.zshrc`.
4. Para o Android, prefira as ferramentas de linha de comando, que não exigem o assistente gráfico:
   - `brew install --cask android-commandlinetools`
   - `sdkmanager "platform-tools" "platforms;android-35" "build-tools;35.0.0"`
   - configure `ANDROID_HOME` e o `PATH` no `~/.zshrc`;
   - `flutter config --android-sdk <caminho do SDK>`
   - `yes | flutter doctor --android-licenses`
5. Rode `flutter doctor -v`. Os itens Flutter e Android toolchain precisam ficar verdes. Xcode, Chrome e Android Studio podem ficar pendentes, porque o alvo é Android e o teste será em celular físico.
6. Se algum comando pedir senha de administrador, pare e me avise em vez de tentar contornar.

## 2. Executar a Etapa 0

Com o ambiente pronto, execute `processamento/Tombox/docs/prompts/02-etapa0.md` seguindo o plano que você propôs.

## 3. Registrar o resultado

Ao terminar, salve um resumo curto em `processamento/Tombox/docs/respostas/01b-ambiente-e-etapa0.md` com:
- o resultado final do `flutter doctor`;
- a árvore de arquivos criada em `app/`;
- a saída de `flutter analyze` e `flutter test`;
- pendências ou decisões que precisam da minha aprovação.

Faça isso ao fim de todas as etapas daqui em diante (um arquivo por etapa em `docs/respostas/`).
