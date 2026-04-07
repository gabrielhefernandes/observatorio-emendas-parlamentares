# Observatório de Emendas Parlamentares Individuais

> Painel interativo em Power BI para análise da execução de emendas parlamentares individuais de deputados federais brasileiros (2015–2026).

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![R](https://img.shields.io/badge/R-276DC3?style=for-the-badge&logo=r&logoColor=white)
![Excel](https://img.shields.io/badge/Excel-217346?style=for-the-badge&logo=microsoft-excel&logoColor=white)

---

## Sobre o projeto

Este projeto foi desenvolvido como iniciativa de análise de dados institucionais na **Universidade Federal de Minas Gerais**. O objetivo é transformar dados brutos do SIGA Senado em um painel navegável que permite à diretoria acompanhar, de forma visual e interativa, como os recursos de emendas parlamentares individuais são distribuídos no Brasil.

### Problema resolvido

Não existia ferramenta centralizada que permitisse responder perguntas como:
- Quais deputados mais destinaram recursos via emendas individuais?
- Quais partidos concentram mais recursos? Em quais municípios?
- A UFMG aparece como beneficiária? Em quais programas?
- Dado o número de uma emenda, quais são seus detalhes de execução?

---

## Principais números (série 2015–2026)

| Métrica | Valor |
|---|---|
| Total executado (R$) | R$ 122,98 bilhões |
| Total deflacionado (IPCA) | R$ 147,31 bilhões |
| Emendas individuais | 21.312 |
| Deputados autores | 1.432 |
| Municípios beneficiados | 5.569 (de 5.570) |
| Ticket médio por emenda | R$ 5,77 milhões |
| Autor com maior volume | Davi Alcolumbre — R$ 298 Mi |
| Partido líder | PL — 11,28% do total |

---

## Stack tecnológica

| Etapa | Tecnologia |
|---|---|
| Extração de dados | SIGA Senado (download manual .xlsx) |
| Tratamento e ETL | R (tidyverse, janitor, lubridate, stringi, openxlsx, geobr) |
| Modelagem dimensional | R — Star Schema com 1 fato e 8 dimensões |
| Visualização | Power BI Desktop + DAX |
| Armazenamento | Excel (.xlsx)  |
| Publicação | Power BI Service |

---

## Arquitetura do pipeline

```
SIGA Senado (.xlsx)
       │
       ▼
 Script R (ETL)
  ├── Normalização textual
  ├── Extração de município/UF via regex
  ├── Join com tabela IBGE (DTB 2022)
  ├── Correções de nomes de municípios e autores
  └── Modelagem dimensional (Star Schema)
       │
       ▼
 Excel com 9 abas
  ├── fato_execucao (657.000 linhas)
  ├── dim_autor, dim_partido, dim_municipio
  ├── dim_funcao, dim_subfuncao, dim_gnd
  ├── dim_orgao, dim_calendario
       │
       ▼
  Power BI (DAX + Visualizações)
       │
       ▼
  Power BI Service (acesso via navegador)
```

---

## Modelo dimensional

O modelo segue o padrão **Star Schema**, com a tabela `fato_execucao` no centro conectada a 8 dimensões. Todos os relacionamentos são do tipo muitos-para-um (`*:1`), com filtro unidirecional da dimensão para a fato.

| Tabela | Tipo | Chave primária | Linhas |
|---|---|---|---|
| fato_execucao | Fato | — | ~657.000 |
| dim_autor | Dimensão | id_autor (sintética) | 1.435 |
| dim_partido | Dimensão | id_partido (sintética) | 36 |
| dim_municipio | Dimensão | fav_mun_cod_ibge (IBGE) | 5.569 |
| dim_funcao | Dimensão | funcao_cod | 28 |
| dim_subfuncao | Dimensão | subfuncao_ajustada_cod | 78 |
| dim_gnd | Dimensão | gnd_cod | 3 |
| dim_orgao | Dimensão | uo_cod + orgao_superior_cod | 337 |
| dim_calendario | Dimensão | data_ref | 104 |

---

## Estrutura do dashboard

O painel é composto por 6 lâminas analíticas + 1 menu de navegação:

### Menu — Navegação principal
Capa com botões de navegação para todas as lâminas e descrição de cada uma.

### Lâmina 1 — Concentração de recursos
KPIs globais, ranking de autores, participação percentual por partido, concentração por município, mapa de bolhas e análise por função/subfunção orçamentária (matriz com drill down).

### Lâmina 2 — Perfil do autor
Análise individual de deputados: evolução do gasto por ano com linha de média por emenda, KPIs de municípios e UFs alcançados, tabela de partidos sensível ao filtro.

### Lâmina 3 — Análise por partido
Comparativo entre bancadas (número de autores, total pago, ranking, média por autor), evolução histórica por ano e ranking de autores dentro do partido selecionado.

### Lâmina 4 — Rastreamento de emenda
Busca granular por número de emenda com filtros encadeados (autor → partido → ano → número). Cartões com todos os atributos da emenda selecionada: município, favorecido, função, subfunção, GND, órgão superior e unidade orçamentária.

### Lâmina 5 — Territorialidade
Distribuição espacial dos recursos com mapa interativo, filtros por UF, função, partido e autor.

### Lâmina 6 — Unidade Orçamentária e Função
Ranking de UOs com segmentação por pesquisa de texto, matriz hierárquica de função/subfunção com drill down, mapa e KPIs de cobertura orçamentária.

---

## Medidas DAX (22 medidas)

Todas as medidas estão centralizadas na tabela `_medidas`. 

<details>
<summary>Ver todas as medidas e fórmulas</summary>

| Medida | Fórmula DAX |
|---|---|
| `Total Pago R$` | `SUM(fato_execucao[pago_rp_favorecido_lista_ob_r])` |
| `Total Pago IPCA` | `SUM(fato_execucao[pago_rp_favorecido_lista_ob_ipca])` |
| `Nº Emendas` | `DISTINCTCOUNT(fato_execucao[emenda_num])` |
| `Nº Autores` | `DISTINCTCOUNT(fato_execucao[id_autor])` |
| `Nº Municípios` | `CALCULATE(DISTINCTCOUNT(fato_execucao[fav_mun_cod_ibge]), NOT ISBLANK(fato_execucao[fav_mun_cod_ibge]))` |
| `Nº UFs` | `CALCULATE(DISTINCTCOUNT(dim_municipio[fav_uf_sg]), FILTER(dim_municipio, VALUE(dim_municipio[fav_mun_cod_ibge]) IN VALUES(fato_execucao[fav_mun_cod_ibge])))` |
| `Média por Emenda R$` | `DIVIDE([Total Pago R$], [Nº Emendas])` |
| `Média por Município R$` | `DIVIDE([Total Pago R$], [Nº Municípios])` |
| `Média por Autor no Partido R$` | `DIVIDE([Total Pago R$], [Nº Autores])` |
| `% do Total Pago R$` | `DIVIDE([Total Pago R$], CALCULATE([Total Pago R$], ALL(fato_execucao)))` |
| `% do Total por Partido` | `DIVIDE([Total Pago R$], CALCULATE([Total Pago R$], ALL(dim_partido)))` |
| `Ranking Autor` | `RANKX(ALL(dim_autor), [Total Pago R$], , DESC, DENSE)` |
| `Ranking Partido` | `RANKX(ALL(dim_partido), [Total Pago R$], , DESC, DENSE)` |
| `Total Pago Top Autor R$` | `MAXX(ALL(dim_autor[autor]), CALCULATE([Total Pago R$]))` |
| `Total Pago Top UO R$` | `MAXX(ALL(dim_orgao[uo_ajustada]), CALCULATE([Total Pago R$]))` |
| `Total Pago Partido R$` | `CALCULATE([Total Pago R$], ALLEXCEPT(dim_partido, dim_partido[autor_partido]))` |
| `Acumulado no Ano R$` | `CALCULATE([Total Pago R$], DATESYTD(dim_calendario[data_ref]))` |
| `Variação Anual R$` | `DIVIDE(ano_atual - ano_anterior, ano_anterior)` — restrita a 2017–2023 via `SELECTEDVALUE` |
| `Ano da Emenda` | `IF(HASONEVALUE(fato_execucao[emenda_ano]), MAX(fato_execucao[emenda_ano]), BLANK())` |
| `Partido do Autor` | `CALCULATE(FIRSTNONBLANK(dim_partido[autor_partido], 1), FILTER(fato_execucao, NOT ISBLANK(fato_execucao[id_partido])))` |
| `Média por Emenda por Ano R$` | `DIVIDE([Total Pago R$], DISTINCTCOUNT(fato_execucao[ano_execucao]))` |
| `Variação Anual por Ano` | Calcula variação entre o ano máximo disponível e o anterior |

</details>

---

## Principais decisões técnicas

**PK sintética em dim_autor**
O CPF estava 100% ausente na base do SIGA e o ID parlamentar tinha 476 duplicatas. Solução: `id_autor` gerado via `row_number()` após `distinct(autor)` com nomes normalizados.

**Chave composta em dim_orgao**
Algumas UOs migraram de órgão superior ao longo dos anos (ex: INCRA esteve vinculado a 3 ministérios). A chave `uo_cod + orgao_superior_cod` preserva o histórico institucional real.

**dim_subfuncao independente da dim_funcao**
40 das 78 subfunções aparecem em mais de uma função orçamentária. Incluir `funcao_cod` em `dim_subfuncao` geraria duplicatas na PK — as duas dimensões são independentes.

**Partidos históricos preservados**
PMDB, PTdoB, PFL, PPS, PR, PRB e PRP foram mantidos com seus nomes históricos, registrando o partido do deputado no momento da emenda.

**Granularidade mista no calendário**
O SIGA não disponibiliza `mes_execucao` para 2024–2026. A `dim_calendario` cobre apenas 2015–2023 (104 linhas mensais). O `ano_execucao` é mantido como atributo degenerado na fato para cobrir toda a série.

---

## Estrutura do repositório

```
observatorio-emendas-parlamentares/
│
├── README.md
│
├── dashboard/
│   └── emendas_individuais_relatorio.pbix
│
├── dados/
│   └── emendas_individuais_SAMPLE.xlsx   ← amostra com 500 linhas
│
├── scripts/
│   └── tratamento_base_emendas_individuais.R
│
├── docs/
│   └── relatorio_tecnico.pdf
│
└── imagens/
    ├── menu.png
    ├── lamina_concentracao.png
    ├── lamina_autor.png
    ├── lamina_partido.png
    ├── lamina_rastreamento.png
    ├── lamina_territorialidade.png
    └── lamina_uo_funcao.png
```

---

## Como reproduzir

### Pré-requisitos

- R 4.x com os pacotes: `tidyverse`, `openxlsx`, `writexl`, `janitor`, `lubridate`, `stringr`, `stringi`, `geobr`
- Power BI Desktop (versão gratuita disponível em powerbi.microsoft.com)
- Tabela DTB 2022 do IBGE disponível em: ibge.gov.br/geociencias/organizacao-do-territorio/divisao-territorial

### Passos

1. Clone este repositório
2. Baixe os dados brutos do SIGA Senado com os filtros: **Tipo de autor = Deputado Federal** e **Tipo de emenda = Individual**
3. Salve o arquivo em `dados/dados_brutos/emendas_individuais/`
4. Execute o script `scripts/tratamento_base_emendas_individuais.R`
5. O arquivo `modelo_dimensional_powerbi.xlsx` será gerado em `dados/dados_tratados/`
6. Abra o arquivo `.pbix` no Power BI Desktop e atualize a fonte de dados apontando para o Excel gerado

### Atualização mensal

Repita os passos 2 a 5 mensalmente. O Power BI Service atualiza automaticamente ao ler o novo arquivo Excel.

---

## Fonte dos dados

- **SIGA Senado** — Painel de Emendas Parlamentares: [senado.leg.br/orcamento/sigadownload](https://www12.senado.leg.br/orcamento/sigadownload)
- **IBGE DTB 2022** — Divisão Territorial Brasileira: [ibge.gov.br](https://www.ibge.gov.br/geociencias/organizacao-do-territorio/divisao-territorial)
- **Pacote geobr (R)** — Coordenadas geográficas dos municípios: [github.com/ipeaGIT/geobr](https://github.com/ipeaGIT/geobr)

---


## Autor

**Gabriel** — Graduando em Ciências Sociais · UFMG  
Transição para análise de dados com foco em BI, SQL e R.

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/gabriel-henriques-fernandes/)
[![GitHub](https://img.shields.io/badge/GitHub-181717?style=for-the-badge&logo=github&logoColor=white)](https://github.com/gabrielhefernandes)

---

*Projeto desenvolvido em março e abril de 2026 · UFMG — Faculdade de Ciências Humanas*
