# 🏛️ Observatório de Emendas Parlamentares Individuais

> **Painel de Business Intelligence** para análise da execução orçamentária de emendas parlamentares individuais de deputados federais brasileiros — desenvolvido para a Faculdade de Ciências Econômicas da UFMG (FACE/UFMG).

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![R](https://img.shields.io/badge/R-276DC3?style=flat&logo=r&logoColor=white)
![Star Schema](https://img.shields.io/badge/Star%20Schema-Dimensional%20Model-blue)
![Status](https://img.shields.io/badge/Status-Concluído-brightgreen)

---

## 📋 Sumário executivo

Emendas parlamentares individuais são o principal mecanismo pelo qual deputados federais alocam recursos públicos diretamente em municípios e políticas específicas. Entre 2015 e 2026, foram executadas **mais de 657 mil transferências**, distribuindo bilhões de reais por todo o território nacional.

**O problema:** os dados estão disponíveis publicamente no SIGA Senado, mas em formato bruto e sem estrutura analítica — impossibilitando que gestores, pesquisadores e a sociedade respondam perguntas simples como *"quanto um deputado específico destinou ao seu próprio estado?"* ou *"quais funções orçamentárias concentram mais recursos?"*.

**A solução:** este projeto transforma esses dados brutos em um painel interativo que permite analisar **quem destina quanto, para onde e para quê** — com filtragem dinâmica por autor, partido, município, função orçamentária e período.

---

## 📊 Escopo dos dados

| Indicador | Valor |
|---|---|
| Registros de execução | 657.000+ |
| Deputados distintos | 1.435 |
| Municípios cobertos | 5.569 de 5.570 |
| Partidos (histórico) | 36 |
| Funções orçamentárias | 28 |
| Período | 2015 – 2026 |
| Fonte | SIGA Senado + IBGE DTB 2022 |

---

## 🗂️ Páginas do dashboard

| Página | Pergunta central respondida |
|---|---|
| **Apresentação** | Navegação central entre análises |
| **Autor** | Qual o perfil de distribuição de recursos de um deputado ao longo dos anos? |
| **Partido** | Como se compara o volume de emendas entre partidos e quem são os principais autores de cada legenda? |
| **Concentração** | Como os recursos se distribuem geograficamente e por função orçamentária? |
| **Rastreamento de Emenda** | Quais são todos os detalhes de execução de uma emenda específica? |
| **Territorialidade** | Como os recursos se distribuem espacialmente pelos municípios brasileiros? |
| **UO e Função** | Quais unidades orçamentárias e funções concentram mais recursos? |

---

## 🔧 Stack técnica

| Camada | Ferramenta | Detalhes |
|---|---|---|
| Coleta | SIGA Senado | Download mensal em .xlsx |
| Tratamento | R | tidyverse, janitor, lubridate, stringi, openxlsx |
| Modelagem | R | Star Schema com 1 fato + 8 dimensões |
| Visualização | Power BI | DAX, Power Query, relacionamentos |
| Geocodificação | IBGE DTB 2022 | Código de municípios como chave natural |

---

## 🗃️ Modelagem dimensional — Star Schema

O modelo segue o padrão Star Schema recomendado para Power BI, com `fato_execucao` no centro conectada a 8 dimensões:

```
fato_execucao (657k+ linhas)
    ├── dim_autor        (1.435 deputados — PK sintética)
    ├── dim_partido      (36 partidos — histórico preservado)
    ├── dim_municipio    (5.569 municípios — PK = código IBGE)
    ├── dim_funcao       (28 funções orçamentárias)
    ├── dim_subfuncao    (78 subfunções — dimensão independente)
    ├── dim_gnd          (3 grupos: Investimentos · Custeio · Inv. Financeiras)
    ├── dim_orgao        (337 órgãos — chave composta histórica)
    └── dim_calendario   (104 meses — granularidade mensal, 2015–2023)
```

---

## ⚙️ Decisões técnicas e desafios resolvidos

### Tratamento de autores — PK sintética
CPF ausente em 100% da base e `id_parlamentar` com **476 duplicatas**. Solução: PK sintética via `row_number()` após `distinct(autor)`, com normalização de nomes (remoção de prefixos "DEP." e "DEPUTADO", correção de 10 grafias divergentes ao longo dos anos).

### Histórico de partidos preservado
Partidos que mudaram de nome (PMDB→MDB, PTdoB→Avante, PFL→DEM, PPS→Cidadania, PR→PL, PRB→Republicanos, PRP) foram mantidos com seus **nomes históricos**, preservando o vínculo do deputado com o partido no momento da emenda.

### Geocodificação com o IBGE
Join com a tabela DTB 2022, com correção manual de **6 divergências de grafia** entre o SIGA e o IBGE — casos como `DONA EUSEBIA → DONA EUZEBIA` e `GRAO PARA → GRAO-PARA`.

### dim_subfuncao independente
40 das 78 subfunções aparecem em mais de uma função orçamentária. Incluí-las na mesma dimensão geraria duplicatas de PK — solução: dimensões separadas com FKs independentes na fato.

### dim_orgao com chave composta
Algumas Unidades Orçamentárias migraram de órgão superior ao longo dos anos (ex: INCRA vinculado a 3 ministérios distintos). A chave composta `uo_cod + orgao_superior_cod` preserva esse histórico, aplicando `slice_max(ano_execucao)` para manter o nome mais recente em casos de Tipo 1.

### dim_calendario parcial — limitação de dados
O campo `mes_execucao` do SIGA retorna `-` para 2024–2026, provavelmente por mudanças institucionais pós-STF e defasagem de atualização do SIAFI. A `dim_calendario` cobre apenas os meses disponíveis (104 linhas); `ano_execucao` foi mantido como atributo degenerado na fato para cobrir todos os anos.

---

## 📐 Medidas DAX implementadas

As medidas foram desenvolvidas e auditadas com o **AI Measure Killer**, garantindo que apenas medidas efetivamente utilizadas no dashboard sejam documentadas:

| Medida | Descrição |
|---|---|
| `Total Pago R$` | Soma do valor pago por favorecido |
| `Nº Emendas` | Contagem distinta de emendas |
| `Nº Autores` | Contagem distinta de deputados |
| `Nº Municípios` | Municípios distintos com execução |
| `Nº UFs` | UFs distintas com execução |
| `% do Total Pago R$` | Participação no total geral |
| `% do Total por Partido` | Participação no total por partido |
| `Ranking Autor` | Ranking por valor pago (RANKX denso) |
| `Ranking Partido` | Ranking de partidos por valor pago |
| `Média por Emenda R$` | Valor médio por emenda |
| `Média por Autor no Partido R$` | Média por deputado dentro do partido |
| `Total Pago Top Autor R$` | Valor do autor com maior execução |
| `Total Pago Top UO R$` | Valor da UO com maior execução |
| `Total Pago Partido R$` | Total por partido (ignora filtros externos) |
| `Rastreamento Municipio` | Detalha municípios de uma emenda específica |
| `Rastreamento Funcao` | Detalha funções de uma emenda específica |
| `Rastreamento Subfuncao` | Detalha subfunções de uma emenda específica |
| `Rastreamento UO` | Detalha UOs de uma emenda específica |
| `Rastreamento Orgao Superior` | Detalha órgãos superiores de uma emenda |
| `Rastreamento Programa` | Detalha programas de uma emenda |
| `Favorecido Rastreamento` | Lista favorecidos de uma emenda |
| `Cor da Bolha` | Classifica destino em estado do autor vs. outros |
| `Filtro_Seguranca_v2` | Garante integridade do filtro cruzado dim_funcao |

> Colunas calculadas: `chave_orgao` (fato e dim), `autor_fato`, `partido_fato`, `uf_fato`, `municipio_favorecido_fato` — criadas para viabilizar filtros cruzados via slicer sem TREATAS.

---

## 📁 Estrutura do repositório

```
observatorio-emendas-parlamentares/
├── README.md
├── emendas_individuais_relatorio.pbix     # Dashboard Power BI
├── scripts/
│   └── tratamento_emendas.R               # Script de tratamento e modelagem dimensional
└── docs/
    └── relatorio_tecnico.pdf              # Relatório técnico completo do projeto
```

---

## 🔗 Fonte dos dados

- **SIGA Senado** — [sigabrasil.senado.leg.br](https://www12.senado.leg.br/orcamento/sigabrasil)
  - Filtros aplicados: Deputado Federal + Emenda Individual
  - Período: 2015 a 2026 · Atualização: mensal
- **IBGE DTB 2022** — Tabela de Divisão Territorial Brasileira para geocodificação de municípios

---

## 👨‍💻 Autor

**Gabriel Henriques Fernandes**
Estudante de Ciências Sociais (7º período) — FAFICH/UFMG
Belo Horizonte, MG

[LinkedIn](https://www.linkedin.com/in/gabriel-henriques-fernandes/) · [GitHub](https://github.com/SEU_USERNAME)

---

*Projeto desenvolvido para a Faculdade de Ciências Econômicas — UFMG · Março de 2026*
