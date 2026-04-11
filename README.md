# 🏛️ Observatório de Emendas Parlamentares Individuais

> **Painel de Business Intelligence** para análise da execução orçamentária de emendas parlamentares individuais de deputados federais brasileiros — desenvolvido para Universidade Federal de Minas Gerais (UFMG).

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=flat&logo=powerbi&logoColor=black)
![R](https://img.shields.io/badge/R-276DC3?style=flat&logo=r&logoColor=white)
![Star Schema](https://img.shields.io/badge/Star%20Schema-Dimensional%20Model-blue)
![Status](https://img.shields.io/badge/Status-Concluído-brightgreen)
[![Dados Validados](https://img.shields.io/badge/Dados-23%20testes%20%7C%20100%25%20aprovados-brightgreen)](docs/laudo_validacao.pdf)

---

## 📋 Sumário executivo

Emendas parlamentares individuais são o principal mecanismo pelo qual deputados federais alocam recursos públicos diretamente em municípios e em pessoas físicas e jurídicas. Entre 2015 e 2026, foram executadas **21.312 emendas parlamentares individuais distintas**, gerando mais de **657 mil registros de pagamento** e distribuindo **R$ 123,259 bilhões** por todo o território nacional.

**O problema de negócio:** a Diretoria de Cooperação Institucional da UFMG precisa identificar quais deputados federais destinam recursos para municípios e áreas de interesse da universidade — como Educação Superior e Ciência e Tecnologia em Minas Gerais. Sem uma ferramenta analítica, essa informação está dispersa em bases brutas de difícil interpretação, como o SIGA Senado, tornando inviável o mapeamento sistemático de potenciais parceiros institucionais.

**A solução**: este projeto transforma esses dados em um painel interativo que permite identificar, com poucos cliques, **quem destina quanto, para onde e para quê** — viabilizando que a diretoria priorize contatos e estabeleça parcerias com deputados alinhados às demandas da universidade.

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
│
├── dashboard/
│   └── emendas_individuais_relatorio.pbix                      # Arquivo fonte (`.pbix`) do painel interativo desenvolvido no Power BI
│
├── scripts/
│   └── scripts/tratamento_base_emendas_individuais-2026.R      # Script feito em R para tratamento e modelagem dimensional
└── docs/
    ├── laudo_validacao.pdf                                     # Procedimentos de certificação da integridade e qualidade dos dados
    └── relatorio_tecnico.pdf                                   # Metodologia, escopo e análise dos resultados do projeto
│
├── dados/
│   └── emendas_individuais_SAMPLE.xlsx                         # Amostra de 500 registros dos dados tratados
│
└── imagens/                                                    # Capturas de tela do dashboard para rápida referência
    ├── lamina_apresentacao.png                                          
    ├── lamina_autor.png
    ├── lamina_partido.png
    ├── lamina_distribuicao_regional.png

```

---

## ⚙️ Como reproduzir

### Pré-requisitos
- R 4.x com os pacotes: `tidyverse`, `openxlsx`, `writexl`, `janitor`, `lubridate`, `stringr`, `stringi`, `geobr`
- Power BI Desktop (gratuito em powerbi.microsoft.com)
- Tabela DTB 2022 do IBGE (ibge.gov.br → Geociências → Organização do território → Estrutura Territorial → Divisão territorial Brasileira)

### Passos
1. Clone este repositório
2. Baixe os dados brutos do SIGA Senado com os filtros: **Tipo de autor = Deputado Federal** e **Tipo de emenda = Individual**
3. Salve o arquivo em `dados/dados_brutos/emendas_individuais/`
4. Ajuste o nome do arquivo na linha indicada em ``scripts/tratamento_base_emendas_individuais-2026.R``
5. Execute o script completo no RStudio 
6. O arquivo `modelo_dimensional_powerbi.xlsx` será gerado em `dados/dados_tratados/`
7. Abra o `.pbix` no Power BI Desktop e atualize a fonte de dados apontando para o Excel gerado

### Atualização mensal
Repita os passos 2 a 6 mensalmente. O Power BI Service atualiza automaticamente ao ler o novo arquivo.

> **Nota:** o arquivo `.pbix` no repositório exibirá erro de fonte de dados ao ser aberto sem executar o pipeline acima, pois os dados completos (67 MB) não estão versionados por limitação de tamanho. A pasta `dados/` contém apenas uma amostra de 500 linhas para referência estrutural.

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
