# Tombox — Sistema de Inventário Patrimonial do TJPA

> **Tribunal de Justiça do Estado do Pará (TJPA)**  
> **Desafio 2 — Inventário Físico de Bens Móveis em Mutirão Offline**  
> *Arquitetura v2: Criptografia Ed25519, Sincronização Local P2P, Visão Computacional no Aparelho e Auditoria GS1 EPCIS 2.0.*

---

## 🏛️ Visão Geral

O **Tombox** é uma solução móvel e web desenvolvida sob medida para a realidade logística dos prédios e comarcas do Poder Judiciário do Estado do Pará. O sistema viabiliza mutirões de inventário físico com equipe distribuída operando em locais sem conectividade com a internet, garantindo integridade matemática em cada registro através de cadeias causais imutáveis de eventos assinados.

A interface foi concebida sobre o **Design System v2** (metáfora da *Plaqueta de Alumínio Estampada* e do *Livro de Tombo Tradicional*), abandonando elementos genéricos de aplicativos corporativos em prol de uma experiência institucional austera, legível e altamente eficiente.

---

## ⚡ Principais Capacidades da Arquitetura v2

### 1. Identidade Criptográfica e Cadeia Causal Imutável (Bloco B)
- **Assinatura Ed25519 por Dispositivo:** Cada smartphone ou tablet gera um par de chaves assimétricas em armazenamento seguro (`FlutterSecureStorage`). Cada conferente assina seus próprios registros com sua chave privada.
- **Estrutura de Event Sourcing Causal:** Cada evento (`LEITURA`, `ESTADO`, `DIVERGENCIA`, `TRANSFERENCIA`, `BEM_NOVO`, `FECHAMENTO_SALA`, `TERMO_ASSINADO`, `HOMOLOGACAO`) possui `hash` SHA-256 encadeado no evento anterior (`hash_anterior`), vetor de relógios causais (`conhecidos`) e assinatura digital irretratável.
- **Rastreabilidade por Campo (W3C PROV-O):** Cada atributo do bem (número de série, categoria, conservação, localização) carrega proveniência auditável detalhando método de coleta (`leitura_camera`, `leitor_externo_hid`, `ia_classificacao`, `ocr_etiqueta_fabricante`, `manual`), agente e nível de confiança.

### 2. Fotos Otimizadas e Armazenamento por Conteúdo (CAS) (Bloco C)
- **Isolamento em Background Thread:** Redimensionamento inteligente para até 1024 px de largura e compressão JPEG com alvo em menos de 120 KB executado fora da UI thread via `compute()`.
- **Content-Addressed Storage:** Nomes de arquivos indexados unicamente pelo SHA-256 do binário (`fotos/<hash>.jpg`), eliminando duplicação física no disco e garantindo verificação instantânea de integridade.

### 3. Sincronização Descentralizada em Rede Local e Pacote Offline (Bloco D & Revisão 08BCD)
- **Descoberta Dinâmica por mDNS (`_tombox._tcp`):** Localização automática de aparelhos parceiros na mesma rede Wi-Fi via `nsd`, sem endereços IP fixos.
- **Autenticação Mútua Desafio-Resposta:** Troca de desafios criptográficos (`nonce`) assinados com Ed25519 com verificação na comissão ativa de inventário antes de liberar sincronização.
- **Pacote Físico `.tombox`:** Arquivo ZIP com formato padronizado contendo `manifesto.json`, fotos em CAS e stream de eventos JSON Lines para transferência via pendrive USB, Bluetooth ou e-mail.

### 4. Papéis, Governança e Resolução de Divergências (Bloco E)
- **Controle de Acesso Baseado em Papéis (RBAC):**
  - **Conferente:** Registro de leituras, fotos, observações e bens novos provisórios.
  - **Gestor Patrimonial:** Autoridade exclusiva para emissão de convites, homologação de salas, descarte de divergências e fechamento de inventário. Eventos privilegiados emitidos por conferentes são rejeitados na validação da cadeia causal (`papelNaoAutorizado`).
- **Convites por QR Code de Uso Único:** Admissão de novos membros por QR Code com prazo de expiração e chave do emissor.
- **Fila de Divergências com Diagnóstico Inteligente:** Detecção e causa provável automática (troca de sala, tombamento duplicado, concorrência entre conferentes com comparação lado a lado).

### 5. Fechamento de Sala, Termo Assinado e Exportação Multiformato (Bloco F)
- **Fechamento e Termo em PDF:** Resumo estatístico consolidado com tabela completa de bens, declaração de fiel guarda, captura de assinatura manuscrita na tela sensível ao toque, carimbo da chave Ed25519 e hash do último evento no rodapé.
- **Exportação CSV com Proteção CWE-1236:** Sanitização automática contra injeção de fórmulas maliciosas em planilhas (`=`, `+`, `-`, `@`).
  - **Perfil Thema-GRP (TJPA):** Estrutura oficial esperada pelo sistema legado do tribunal.
  - **Perfil Genérico / Auditoria:** Dados completos com hashes, chaves públicas e status de assinatura.
- **GS1 EPCIS 2.0 JSON-LD:** Padronização internacional de rastreabilidade com vocabulário CBV (`ObjectEvent`, `TransactionEvent`), URNs SGTIN para bens e SGLN para dependências judiciárias.
- **Entrada por Leitor de Código de Barras / RFID Externo:** Captura de eventos HID via Bluetooth/USB sem foco obrigatório em caixa de texto.

### 6. IA no Aparelho e Plaquetas Provisórias (Bloco G)
- **Classificação Visual de Categoria:** Reconhecimento no aparelho via ML Kit (`google_mlkit_image_labeling`) mapeando itens visuais para o plano de contas patrimonial do TJPA (Informática, Mobiliário, Climatização, etc.).
- **OCR de Fabricante e Série com Antiduplicação:** Leitura automática de plaquetas e Service Tags (Dell, HP, etc.) com consulta em tempo real ao SQLite local para alertar duplicidade de patrimônio antes da gravação.
- **Cartela de QR Codes Provisórios em PDF A4:** Geração de folha padrão com 24 etiquetas adesivas recortáveis com identificação institucional e QR Codes de alta resolução para bens novos encontrados em campo.

---

## 🎨 Identidade Visual e Design System v2

O Tombox adota tokens formais rigorosos baseados na identidade do TJPA e no ambiente judiciário:
- **Tipografia:** Família **Barlow** (Barlow Condensed nos cabeçalhos e plaquetas, Barlow Semi Condensed nos rótulos de dados e Barlow regular no corpo do texto).
- **Cores Oficiais:**
  - `Tinta / Grafite:` `#1C2430` / `#222222` (alta legibilidade sobre fundo neutro).
  - `Papel / Fundo:` `#F7F8F9` (modo claro) / `#12161C` (modo escuro).
  - `Alumínio / Linhas:` `#D0D5DD` (bordas sólidas de 1 px sem sombras difusas).
  - `Status Funcionais:` Verde militar para Conferido (`#1E7E34`), Azul institucional para Outra Sala (`#0B5CAB`), Ocre para Pendente (`#B26A00`) e Carmim para Divergência (`#C92A2A`).

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- **Flutter SDK:** versão 3.24 ou superior (Canal Stable).
- **Android SDK:** API 24+ (Android 7.0 ou superior).
- **Java:** OpenJDK 17+.

### 1. Clonar o Repositório e Instalar Dependências
```bash
git clone https://github.com/cyberchristian92/Tombox.git
cd Tombox/app
flutter pub get
```

### 2. Executar a Suíte de Testes Automatizados
```bash
flutter test
```
*Garante a execução dos 87 testes unitários e de integração de criptografia, CAS, P2P, IA, EPCIS e interface.*

### 3. Análise de Código Estático (Linting)
```bash
flutter analyze
```
*Código validado com 0 avisos e 0 erros.*

### 4. Executar no Navegador (Modo Demonstração)
```bash
flutter run -d chrome
# ou
flutter run -d web-server --web-port 8085
```
*Na versão Web, o aplicativo oferece dados sintéticos da Comarca de Breves (300 bens), importação de CSVs locais e simulação explícita de IA/OCR.*

### 5. Compilar o APK de Produção / Depuração
```bash
flutter build apk --debug
# ou para release:
flutter build apk --release
```
O pacote compilado estará disponível em:  
`app/build/app/outputs/flutter-apk/app-debug.apk`

---

## 📁 Estrutura de Diretórios

```
processamento/Tombox/
├── app/
│   ├── lib/
│   │   ├── brand/                # Temas e cores dinâmicas
│   │   ├── core/                 # Design System v2: tokens, widgets e roteador
│   │   │   ├── theme/            # app_tokens.dart, brand_theme.dart
│   │   │   └── widgets/          # plaqueta, linha_bem, carimbo, etc.
│   │   ├── data/                 # SQLite (Drift), importação CSV e providers Riverpod
│   │   ├── domain/               # Lógica de negócio autônoma e auditável
│   │   │   ├── eventos/          # EventoV2, cadeia causal, relógios e assinaturas
│   │   │   ├── exportacao/       # Sanitização CWE-1236, Thema-GRP, EPCIS 2.0
│   │   │   ├── fechamento/       # Resumo da sala e Termo de Responsabilidade em PDF
│   │   │   ├── fotos/            # Compressão em background e Content-Addressed Storage
│   │   │   ├── ia/               # Mapeamento de categorias e OCR antiduplicação
│   │   │   ├── identidade/       # Geração de pares Ed25519 e Secure Storage
│   │   │   ├── membros/          # Papéis RBAC e convites por QR Code
│   │   │   ├── provisorio/       # Geração de cartela A4 com 24 QR Codes
│   │   │   └── sync/             # Descoberta mDNS, desafio-resposta e pacote .tombox
│   │   └── features/             # Telas e fluxos funcionais da aplicação
│   └── test/                     # Suíte com 87 testes automatizados
└── docs/
    ├── BIBLIOTECAS.md            # Catálogo auditado de bibliotecas e licenças
    ├── epcis.md                  # Especificação técnica do GS1 EPCIS 2.0 JSON-LD
    ├── prompts/                  # Diretrizes e blocos de implementação
    └── respostas/                # Relatórios técnicos dos Blocos A até G
```

---

## 📜 Licença e Conformidade

Desenvolvido para o **Tribunal de Justiça do Estado do Pará (TJPA)** sob as diretrizes de código aberto e licenças permissivas auditadas (MIT, Apache-2.0, BSD-3-Clause).  
Consulte o arquivo [`docs/BIBLIOTECAS.md`](docs/BIBLIOTECAS.md) para a lista exata e justificativa de cada dependência utilizada.
