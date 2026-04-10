# 🏛️ Observatório de Emendas Parlamentares Individuais

> **Painel de Business Intelligence** para análise da execução orçamentária de emendas parlamentares individuais de deputados federais brasileiros — desenvolvido para Universidade Federal de Minas Gerais (UFMG).

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![R](https://img.shields.io/badge/R-276DC3?style=flat&logo=r&logoColor=white)
![Star Schema](https://img.shields.io/badge/Star%20Schema-Dimensional%20Model-blue)
![Status](https://img.shields.io/badge/Status-Concluído-brightgreen)

---

## 📋 Sumário executivo

Emendas parlamentares individuais são o principal mecanismo pelo qual deputados federais alocam recursos públicos diretamente em municípios e em pessoas físicas e jurídicas, fazendo uso de políticas específicas. Entre 2015 e 2026, foram executadas **mais de 657 mil transferências**, distribuindo bilhões de reais por todo o território nacional.

**O problema de negócio:** a diretoria de Cooperação Institucional da Universidade Federal de Minas Gerais deseja uma ferramenta que possibilite, de **forma fácil e acessível*, conseguir responder perguntas simples como *"quais deputados específicos colocam mais dinheiro em determinados municípios?"* ou *"quais deputados tipicamente destinam recursos para a educação de nível superior em Minas Gerais?*. A intenção é que a diretoria possa fazer uso dessa ferramenta para que possa contatar esses deputados e estabeelcer projetos e parcerias, sem ter que analisar os dados em formato bruto e sem estrutura analítica fornecidos publicamente em bases de dados como o SIGA Senado.

**A solução:** este projeto transforma esses dados brutos em um painel interativo que permite analisar **quem destina quanto, para onde e para quê** — com filtragem dinâmica por autor, partido, município, função orçamentária, subfunção orçamentária, órgão superior e suas hierarquias e período de tempo.

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
| **Distribuição Regional** | Como os deputados distribuem seus recursos espacialmente pelos municípios brasileiros? |

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

As medidas foram desenvolvidas e auditadas, garantindo que apenas medidas efetivamente utilizadas no dashboard sejam documentadas:

| Medida | Descrição |
|---|---|
| `Total Pago R$` | Soma do valor pago por favorecido |
| `Nº Emendas` | Contagem distinta de emendas |
| `Nº Autores` | Contagem distinta de deputados |
| `Nº Municípios` | Municípios distintos com execução |
| `Nº UFs` | UFs distintas com execução |
| `Ranking Autor` | Ranking por valor pago (RANKX denso) |
| `Média por Emenda R$` | Valor médio por emenda |
| `Total Pago Partido R$` | Total por partido (ignora filtros externos) |

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

[LinkedIn](https://www.linkedin.com/in/gabriel-henriques-fernandes/) · [GitHub](https://github.com/gabrielhefernandes)

---

*Projeto desenvolvido para a Universidade Federal de Minas Gerais — UFMG · Março e Abril de 2026*
