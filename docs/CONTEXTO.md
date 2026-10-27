# Tombox: contexto geral do projeto

Leia este arquivo inteiro antes de escrever qualquer código. Ele explica o problema, as regras e as decisões já tomadas.

## 1. O que é

Tombox é um sistema de inventário patrimonial que funciona sem internet. Ele está sendo desenvolvido para o Desafio 2 (Inventário patrimonial digital) do Hackathon do Tribunal de Justiça do Estado do Pará (TJPA) 2026, organizado pelo Laboratório de Inovação Pai d'Égua e pela Açaí Valley.

Pergunta do desafio: como tornar o inventário patrimonial do TJPA mais rápido, simples e confiável, usando tecnologias digitais e dispositivos móveis para facilitar a identificação, a conferência e a atualização dos bens?

## 2. O problema

O tribunal tem milhares de bens (móveis, computadores, equipamentos) espalhados por fóruns e prédios em Belém e nas comarcas do interior. Cada bem tem uma plaqueta com o número de tombamento. Hoje o inventário é manual: o servidor procura a plaqueta, anota o número, digita numa planilha e depois alguém junta as planilhas de todas as salas. Isso gera:
- erro de digitação e retrabalho;
- dificuldade de achar e ler plaquetas gastas, escondidas ou ausentes;
- bens que mudaram de sala sem registro;
- muito tempo para consolidar e investigar divergências;
- internet instável ou ausente no interior.

## 3. Quem usa

- **Conferente** (persona Rosilene, servidora de uma comarca do interior): vai às salas com o celular e confere os bens. Usa Android, WhatsApp e planilha. Não tem paciência para formulários longos. Prefere tocar a digitar.
- **Gestor de patrimônio** (persona Marcos, em Belém): prepara a conferência, recebe o trabalho dos conferentes, consolida e resolve divergências.
- **Responsável pela sala**: revisa o resultado da sua sala e assina o termo de responsabilidade.

## 4. Regras obrigatórias do edital

- Usar somente dados sintéticos. Nunca usar dados reais, sistemas internos ou credenciais do TJPA.
- Entrada e saída de dados por CSV ou planilha. A solução não pode depender de integração com sistemas do TJPA.
- O núcleo da solução precisa ser criado a partir de 21/10/2026. Bibliotecas e código aberto podem ser usados desde que identificados (manter `docs/BIBLIOTECAS.md` atualizado).
- Funcionar no celular, sem equipamento caro ou específico.
- Funcionar na capital e no interior: offline primeiro.
- Sem dupla digitação: nenhum número de tombamento deve precisar ser digitado no fluxo normal.
- O resultado precisa ser consolidado e exportado.

Critérios de avaliação: impacto 30%, viabilidade 30%, inovação 20%, usabilidade e acessibilidade 10%, apresentação 10%.

## 5. A solução em uma frase

O celular lê várias plaquetas de uma vez pela câmera, confere cada leitura com a lista de bens esperados da unidade, registra estado, foto e divergências sem internet, e o gestor junta o trabalho de vários conferentes num relatório único, com trilha de auditoria e termo assinado.

## 6. Arquitetura: dois softwares, um formato comum

Repositório único (monorepo):

```
/app      App do conferente (Flutter, Android primeiro). PRIMEIRA ENTREGA.
/gestor   Sistema do gestor (Python, Docker). Depois.
/schema   Formato dos dados trocados entre app e gestor (JSON Schema).
/tools    Geradores de dados sintéticos e de plaquetas para impressão.
/docs     Contexto, especificações, decisões, bibliotecas usadas.
```

- **App do conferente:** recebe a lista de bens da unidade, faz a conferência offline, grava tudo como eventos encadeados por hash e exporta o resultado.
- **Sistema do gestor:** importa e limpa a planilha, distribui salas, recebe os pacotes dos celulares, resolve conflitos e divergências, gera relatórios. Será feito depois.
- **Comunicação:** Wi-Fi local (o notebook do gestor expõe uma API) ou arquivo (WhatsApp, cabo, pen drive). Por enquanto, o app só importa CSV e exporta CSV e JSON por arquivo.

## 7. Referências estudadas (só ideias, nunca código)

Em `processamento/homebox` e `processamento/homebox-companion` estão dois projetos de referência. **Não copie código deles:** o Homebox é AGPL-3.0 e o Companion é GPL-3.0, e o Tombox é Apache-2.0. Pode ler para entender ideias. O resumo do que aproveitar está em `material/estudo-homebox-e-etapas.md`. Principais ideias:
- locais em árvore (comarca, prédio, andar, sala) e local escrito como caminho no CSV (`Comarca de Breves / Fórum / Térreo / Sala 3`);
- código de ativo sequencial no formato `000-123` para etiquetas provisórias;
- leitura pela câmera fora da thread da interface, com limite de detecções, caixas suavizadas e tempo para a caixa sumir;
- fluxo de cadastro de item novo em quatro telas (local, fotos, revisão, confirmação), com verificação de duplicado por número de série;
- neutralização de fórmulas ao exportar CSV (CWE-1236).

Onde o Tombox é melhor que o Homebox Companion:
- funciona offline (o Companion depende de servidor e de IA na nuvem);
- lê o número impresso da plaqueta (OCR) e casa com a lista esperada, em vez de só ler QR;
- lê várias plaquetas por quadro;
- registra eventos imutáveis com hash, prontos para auditoria;
- IA roda no próprio celular, sem enviar fotos para fora.

## 8. Identidade visual

O protótipo usa o logo e as cores do TJPA, mas tudo de marca fica isolado em `app/assets/brand/` e `app/lib/brand/`. Trocar de marca precisa ser só substituir essa pasta e o arquivo `brand.json`. Nenhum texto ou cor da instituição pode ficar espalhado no resto do código.

## 9. Qualidade esperada

- Código organizado por funcionalidade, com responsabilidades pequenas e testáveis.
- Testes automatizados para a lógica que não pode falhar: normalização de números, casamento com a lista, importação de CSV, cadeia de hashes.
- Textos da interface em português do Brasil, linguagem simples.
- Acessibilidade: alvos de toque de no mínimo 48 dp, contraste AA, fonte escalável, feedback por vibração.
- Commits pequenos, com mensagem clara, ao fim de cada etapa.

## 10. Prazos

- 29/10/2026: vídeo de 3 minutos e deck da triagem. Precisa existir a leitura de plaquetas com casamento, funcionando no celular.
- 04 a 06/11/2026: evento presencial, demonstração ao vivo.

A especificação detalhada do app está em `docs/specs/app-mobile.md`.
