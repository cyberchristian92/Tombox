# Bibliotecas e Licenças de Terceiros - Tombox

Este documento registra todas as dependências externas utilizadas no projeto Tombox, suas versões e licenças correspondentes, em conformidade com as regras do edital do Hackathon TJPA 2026.

Todas as bibliotecas adotadas possuem licenças de código aberto permissivas (MIT, BSD-3-Clause, Apache-2.0), sendo totalmente compatíveis com a licença Apache-2.0 do Tombox. Nenhuma biblioteca sob licenças virais (GPL / AGPL) foi ou será incluída no código-fonte.

---

## 1. Bibliotecas Utilizadas na Etapa 0

| Pacote | Versão | Licença | Finalidade |
|---|---|---|---|
| **Flutter SDK** | 3.47.8 | BSD-3-Clause | Framework multiplataforma base da aplicação móvel. |
| **Dart SDK** | 3.13.7 | BSD-3-Clause | Linguagem de programação tipada e compilada AOT. |
| **flutter_riverpod** | ^3.4.3 | MIT | Gerenciamento de estado declarativo, reativo e desacoplado. |
| **go_router** | ^18.1.1 | BSD-3-Clause | Roteamento declarativo baseado em URLs e deep links com parâmetros de rota. |
| **intl** | ^0.20.3 | BSD-3-Clause | Internacionalização, formatação de datas e números no padrão pt_BR. |
| **uuid** | ^4.6.0 | MIT | Geração de identificadores únicos (UUID v4) para eventos imutáveis e aparelho. |
| **crypto** | ^3.0.8 | BSD-3-Clause | Algoritmos criptográficos de hash (SHA-256) para a cadeia de eventos de auditoria. |
| **cupertino_icons** | ^1.0.9 | MIT | Ícones adicionais no estilo visual iOS quando necessário. |
| **flutter_lints** | ^6.0.0 | BSD-3-Clause | Conjunto oficial de boas práticas e análise estática recomendada para Flutter. |

---

## 2. Bibliotecas Planejadas para as Próximas Etapas

| Pacote | Licença | Finalidade / Etapa |
|---|---|---|
| **drift** / **sqlite3_flutter_libs** | MIT / Apache-2.0 | Banco de dados relacional SQLite local, tipado e com migrations seguras (Etapa 1). |
| **file_picker** | MIT | Seleção segura de arquivos de entrada (CSV) da unidade (Etapa 1). |
| **csv** | MIT | Leitura e escrita de arquivos CSV com suporte a delimitadores flexíveis e neutralização (Etapa 1 e 3). |
| **camera** | BSD-3-Clause | Acesso ao feed da câmera em tempo real para o pipeline de visão computacional (Etapa 2). |
| **google_mlkit_text_recognition** | Apache-2.0 | OCR offline executado diretamente no aparelho para leitura de plaquetas metálicas (Etapa 2). |
| **google_mlkit_barcode_scanning** | Apache-2.0 | Leitura de códigos de barra e QR codes nos mesmos quadros do pipeline de câmera (Etapa 2). |
| **share_plus** | BSD-3-Clause | Compartilhamento nativo de relatórios consolidados (CSV e pacotes JSON) (Etapa 3). |

---

## 3. Conformidade com as Regras de Licenciamento

* O núcleo da aplicação foi desenvolvido do zero a partir de 21/10/2026.
* Os projetos de referência estudados (`processamento/homebox` com AGPL-3.0 e `processamento/homebox-companion` com GPL-3.0) serviram exclusivamente para levantamento de requisitos conceituais.
* Nenhuma linha de código foi copiada de tais referências, preservando a autonomia da licença Apache-2.0 do Tombox.
