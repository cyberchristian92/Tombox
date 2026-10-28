# Mapeamento de Eventos Tombox para GS1 EPCIS 2.0 JSON-LD

O Tombox adota a especificação global **GS1 EPCIS 2.0 (Electronic Product Code Information Services)** em formato **JSON-LD** para exportação e interoperabilidade de rastreabilidade patrimonial com sistemas corporativos, órgãos de controle e tribunais superiores (CNJ).

---

## 1. Identificadores Padronizados (EPC e SGLN)

Para garantir unicidade internacional sem ambiguidades:
- **Bens Patrimoniais (EPC):** Utiliza URNs baseadas no esquema **SGTIN** (Serialized Global Trade Item Number):
  `urn:epc:id:sgtin:tjpa.patrimonio.<tombamento>`
  Exemplo: `urn:epc:id:sgtin:tjpa.patrimonio.045123`
- **Locais e Salas (ReadPoint / SGLN):** Utiliza URNs baseadas no esquema **SGLN** (Global Location Number):
  `urn:epc:id:sgln:tjpa.<unidadeId>.<salaId>`
  Exemplo: `urn:epc:id:sgln:tjpa.predio_sede.sala_101`
- **Termos de Responsabilidade e Fechamento:**
  `urn:epc:id:sgln:tjpa.termo.<pdfHashSha256>`

---

## 2. Vocabulário de Negócio CBV (Core Business Vocabulary)

| Evento Tombox | Tipo EPCIS 2.0 | Ação (`action`) | Etapa de Negócio (`bizStep`) | Disposição (`disposition`) |
|---|---|---|---|---|
| **LEITURA / CONFIRMACAO** | `ObjectEvent` | `OBSERVE` | `urn:epcglobal:cbv:bizstep:inspecting` | `urn:epcglobal:cbv:disp:active` |
| **FOTO** | `ObjectEvent` | `OBSERVE` | `urn:epcglobal:cbv:bizstep:inspecting` | `urn:epcglobal:cbv:disp:active` |
| **MOVIMENTACAO** | `ObjectEvent` | `OBSERVE` | `urn:epcglobal:cbv:bizstep:relocating` | `urn:epcglobal:cbv:disp:in_transit` |
| **FECHAMENTO_SALA / TERMO** | `TransactionEvent` | `ADD` | `urn:epcglobal:cbv:bizstep:closing` | `urn:epcglobal:cbv:disp:conformed` |

---

## 3. Extensões TJPA (Auditoria e Criptografia)

No namespace `tjpa: "https://tjpa.jus.br/epcis/v1/"`:
- `tjpa:eventoId`: UUID v4 do evento original no SQLite local do aparelho.
- `tjpa:seq`: Sequência do autor no relógio vetorial.
- `tjpa:autor`: Chave pública Ed25519 do conferente que assinou o evento.
- `tjpa:hashEvento`: SHA-256 canônico encadeado na cadeia causal.
- `tjpa:assinatura`: Assinatura digital Ed25519 em formato hexadecimal.
- `tjpa:fotoHashSha256`: Hash do arquivo de imagem comprimido no formato WebP 60 sem metadados.
- `tjpa:pdfHashSha256`: Hash do documento PDF do termo de responsabilidade com assinatura biométrica.

---

## 4. Exemplo Completo de Payload EPCIS 2.0 JSON-LD

```json
{
  "@context": [
    "https://ref.gs1.org/standards/epcis/2.0.0/epcis-context.jsonld",
    {
      "tjpa": "https://tjpa.jus.br/epcis/v1/"
    }
  ],
  "type": "EPCISDocument",
  "schemaVersion": "2.0",
  "creationDate": "2026-10-28T14:30:00Z",
  "epcisBody": {
    "eventList": [
      {
        "type": "ObjectEvent",
        "action": "OBSERVE",
        "bizStep": "urn:epcglobal:cbv:bizstep:inspecting",
        "disposition": "urn:epcglobal:cbv:disp:active",
        "eventTime": "2026-10-28T14:20:00Z",
        "eventTimeZoneOffset": "-03:00",
        "epcList": [
          "urn:epc:id:sgtin:tjpa.patrimonio.045123"
        ],
        "readPoint": {
          "id": "urn:epc:id:sgln:tjpa.unidade_01.sala_101"
        },
        "tjpa:eventoId": "8b9e6f33-6c7b-4d44-938d-192a831e5f1b",
        "tjpa:seq": 14,
        "tjpa:autor": "9a12c8b7440e11893112c3f...",
        "tjpa:hashEvento": "3ab8d7c1e592f6b3e8a4d7c1e592f6b3...",
        "tjpa:assinatura": "b2f6c8d7e1a3b5...",
        "tjpa:tipoEvento": "CONFIRMACAO"
      },
      {
        "type": "TransactionEvent",
        "action": "ADD",
        "bizStep": "urn:epcglobal:cbv:bizstep:closing",
        "disposition": "urn:epcglobal:cbv:disp:conformed",
        "eventTime": "2026-10-28T14:28:00Z",
        "eventTimeZoneOffset": "-03:00",
        "readPoint": {
          "id": "urn:epc:id:sgln:tjpa.unidade_01.sala_101"
        },
        "bizTransactionList": [
          {
            "type": "urn:epcglobal:cbv:btt:inv",
            "bizTransaction": "urn:epc:id:sgln:tjpa.termo.c8a2b5e9f1d4..."
          }
        ],
        "tjpa:signatarioNome": "Dra. Maria Helena Silva",
        "tjpa:signatarioMatricula": "TJPA-8841",
        "tjpa:pdfHashSha256": "c8a2b5e9f1d4a7b3c2e1f8d4...",
        "tjpa:eventoId": "9c11a2f4-7e8d-4a11-b32e-5f8a192b4c3e"
      }
    ]
  }
}
```
