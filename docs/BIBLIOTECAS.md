# Bibliotecas e Licenças de Terceiros - Tombox

Este documento registra todas as dependências externas utilizadas no projeto Tombox, suas versões e licenças correspondentes, em conformidade com as regras do edital do Hackathon TJPA 2026.

Todas as bibliotecas adotadas possuem licenças de código aberto permissivas (MIT, BSD-3-Clause, Apache-2.0), sendo totalmente compatíveis com a licença Apache-2.0 do Tombox. Nenhuma biblioteca sob licenças virais (GPL / AGPL) foi ou será incluída no código-fonte.

---

## 1. Bibliotecas Utilizadas (Etapas 0, 1 e 2)

| Pacote | Versão | Licença | Finalidade |
|---|---|---|---|
| **Flutter SDK** | 3.47.8 | BSD-3-Clause | Framework multiplataforma base da aplicação móvel. |
| **Dart SDK** | 3.13.7 | BSD-3-Clause | Linguagem de programação tipada e compilada AOT. |
| **flutter_riverpod** | 3.4.3 | MIT | Gerenciamento de estado declarativo, reativo e desacoplado. |
| **go_router** | 18.1.1 | BSD-3-Clause | Roteamento declarativo baseado em URLs e deep links com parâmetros de rota. |
| **drift** / **drift_flutter** | 2.35.3 / 0.3.1 | MIT | Banco relacional SQLite local, tipado, com migrations e streams reativos. |
| **sqlite3_flutter_libs** | 0.6.0 | MIT | Binários nativos do SQLite para Android, iOS e desktop. |
| **file_picker** | 13.3.0 | MIT | Seleção segura de arquivos de entrada (CSV da unidade). |
| **csv** | 8.0.0 | MIT | Leitura e escrita de CSV com suporte a delimitadores flexíveis e neutralização. |
| **camera** | 0.12.1 | BSD-3-Clause | Feed e stream de quadros da câmera em tempo real para o pipeline de IA. |
| **google_mlkit_text_recognition** | 0.17.1 | Apache-2.0 | OCR offline no aparelho para leitura de plaquetas metálicas. |
| **google_mlkit_barcode_scanning** | 0.16.1 | Apache-2.0 | Leitura de códigos de barra e QR codes nos mesmos quadros do pipeline de câmera. |
| **intl** | 0.20.3 | BSD-3-Clause | Internacionalização, formatação de datas e números no padrão pt_BR. |
| **uuid** | 4.6.0 | MIT | Geração de identificadores únicos (UUID v4) para eventos imutáveis e aparelho. |
| **crypto** | 3.0.8 | BSD-3-Clause | Algoritmos criptográficos de hash (SHA-256) para a cadeia de eventos de auditoria. |
| **cryptography** | 2.9.0 | Apache-2.0 | Implementação criptográfica de chaves Ed25519 e assinaturas digitais não-repúdio. |
| **flutter_secure_storage** | 11.2.0 | BSD-3-Clause | Armazenamento seguro de chave privada Ed25519 em Keystore/Keychain. |
| **image** | 4.12.0 | Apache-2.0 | Processamento, redimensionamento (1024px/160px), remoção de EXIF e compressão WebP/JPEG pura em Dart. |
| **archive** | 4.5.2 | Apache-2.0 | Compactação e descompactação de arquivos .tombox (formato ZIP puro em Dart). |
| **shelf** | 1.4.3 | BSD-3-Clause | Servidor HTTP leve embutido no app para sincronização ponto-a-ponto entre celulares. |
| **cupertino_icons** | 1.0.9 | MIT | Ícones adicionais no estilo visual iOS quando necessário. |
| **flutter_lints** | 6.0.0 | BSD-3-Clause | Conjunto oficial de boas práticas e análise estática recomendada para Flutter. |
| **build_runner** / **drift_dev** | 2.17.1 / 2.35.2 | BSD-3-Clause / MIT | Geradores de código estático para o Drift (apenas em desenvolvimento). |

---

## 2. Bibliotecas Planejadas para as Próximas Etapas

| Pacote | Licença | Finalidade / Etapa |
|---|---|---|
| **share_plus** | BSD-3-Clause | Compartilhamento nativo de relatórios consolidados (CSV e pacotes JSON) (Etapa 3). |

---

## 3. Conformidade com as Regras de Licenciamento

* O núcleo da aplicação foi desenvolvido do zero a partir de 21/10/2026.
* Os projetos de referência estudados (`processamento/homebox` com AGPL-3.0 e `processamento/homebox-companion` com GPL-3.0) serviram exclusivamente para levantamento de requisitos conceituais.
* Nenhuma linha de código foi copiada de tais referências, preservando a autonomia da licença Apache-2.0 do Tombox.
