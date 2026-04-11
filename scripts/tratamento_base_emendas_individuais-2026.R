# Tratamento bases emendas parlemantares individuais 

rm(list = ls(all = TRUE))
options(scipen = 999L)

# Biblioteca
{
  library(tidyverse)
  library(openxlsx)
  library(janitor)
  library(lubridate)
  library(writexl)
  library(stringr)
  library(stringi)
}

# Definindo o diretório
dir_dados_trat <- "dados/dados_tratados"
dir_dados_brut <- "dados/dados_brutos"


# ---------- 1. Normalização ----------
normalize <- function(x) {
  x %>%
    str_squish() %>%
    str_to_upper() %>%
    stringi::stri_trans_general("Latin-ASCII")
}
# ----------------------- 1 Entrada --------------------------------------------

# obter a lista de 26 cidades com hífen nome

# Importa a base de codigos do IBGE
codigos_municipios <- readxl::read_xls(paste0(dir_dados_brut, "/DTB_2022/RELATORIO_DTB_BRASIL_MUNICIPIO.xls"), skip = 6)

# Aplica clean_names e select
codigos_municipios <- codigos_municipios %>% clean_names() %>%
  select(uf, codigo_municipio_completo, nome_municipio)

# Criar silga 
uf_codigo <- c(12, 27, 16, 13, 29, 23, 53, 32, 52, 21, 51, 50, 31,
               15, 25, 41, 26, 22, 24, 43, 33, 11, 14, 42, 35, 28, 17)

uf_sigla <- c("AC", "AL", "AP", "AM", "BA", "CE", "DF", "ES", "GO",
              "MA", "MT", "MS", "MG", "PA", "PB", "PR", "PE", "PI", 
              "RN", "RS", "RJ", "RO", "RR", "SC", "SP", "SE", "TO")

uf_sigla_codigo <- as.data.frame(cbind(uf_sigla, uf_codigo)) # Combinando código e sigla das ufs


# Final: Junta uf_sigla_codigo e codigo_do_municipio
codigos_municipios1 <- codigos_municipios %>%
  left_join(uf_sigla_codigo,
            by = c("uf" = "uf_codigo")) %>%
  mutate(mun_uf = paste0(nome_municipio, "-", uf_sigla))

# ---------- 2. NORMLIZO: Aplicar a função em uma coluna ----------
codigos_municipios2 <- codigos_municipios1 %>%
  mutate(
    mun_uf_norm = normalize(mun_uf),
    nome_mun_norm = normalize(nome_municipio)
  )

head(codigos_municipios2)

# Filtra apenas os municipios com hífens - só iremos tratar esses municípios a principio
mun_com_hifen_ibge <- codigos_municipios2 %>% 
  filter(str_detect(nome_mun_norm, "-"))

# Seleciona as colunas de interesse
list_26mun_semhifen <- 
  mun_com_hifen_ibge %>% select(uf_sigla, codigo_municipio_completo, nome_mun_norm, mun_uf_norm)

head(list_26mun_semhifen)

# 1 Dados do Painel de Emendas do SIGA -----------------------------------
# Importar - FIltros do SIGA: auto_tipo: Deputador Federal; autor_tipo: INDIVIDUAL
base_emendas <- read.xlsx(paste0(dir_dados_brut, "/emendas_individuais/dados_painel_emendas_siga_individuais-15-03-2026.xlsx")) # base com os dados das emendas

# Limpar nomes de colunas e normalizar texto da coluna de favorecidos
base_emendas <- base_emendas %>% clean_names()

base_emendas <- base_emendas %>%
  mutate(            # Normalizar as variáveis de texto com a função normalize
    favorecido_do_pagamento_municipio_uf_norm = normalize(favorecido_do_pagamento_municipio_uf)
  )
head(base_emendas)

# Trata a divergência de nomes do município de Grão-Pará e Olho-d’Água do Borges
base_emendas_tmp <- base_emendas %>%
  mutate(
    favorecido_do_pagamento_municipio_uf_norm = 
      str_replace_all(
        favorecido_do_pagamento_municipio_uf_norm,
        regex("\\bGRAO\\s+PARA\\b", ignore_case = TRUE),  # corrige "GRAO PARA"
        "GRAO PARA"
      ),
    favorecido_do_pagamento_municipio_uf_norm = 
      str_replace_all(
        favorecido_do_pagamento_municipio_uf_norm,
        regex("\\bOLHO\\s*-\\s*D['’]AGUA\\s+DO\\s+BORGES\\b", ignore_case = TRUE),  # pega "OLHO-D'AGUA DO BORGES"
        "OLHO D'AGUA DO BORGES"  # remove o hífen
      ),
    favorecido_do_pagamento_municipio_uf_norm = 
      str_replace_all(
        favorecido_do_pagamento_municipio_uf_norm,
        regex("\\bMOGI\\s*-\\s*MIRIM\\b", ignore_case = TRUE),  # pega "OLHO-D'AGUA DO BORGES"
        "MOGI MIRIM"  # remove o hífen
      ),
    favorecido_do_pagamento_municipio_uf_norm = 
      str_replace_all(
        favorecido_do_pagamento_municipio_uf_norm,
        regex("\\bBIRITIBA\\s*-\\s*MIRIM\\b", ignore_case = TRUE),  # pega "OLHO-D'AGUA DO BORGES"
        "BIRITIBA MIRIM"  # remove o hífen
      ),
    favorecido_do_pagamento_municipio_uf_norm = 
      str_replace_all(
        favorecido_do_pagamento_municipio_uf_norm,
        regex("\\bAMPARO\\s+DE\\s+SAO\\s+FRANCISCO\\b", ignore_case = TRUE),  # pega "OLHO-D'AGUA DO BORGES"
        "AMPARO DO SAO FRANCISCO"  # remove o hífen
      ),
    favorecido_do_pagamento_municipio_uf_norm = 
      str_replace_all(
        favorecido_do_pagamento_municipio_uf_norm,
        regex("\\bBOA\\s+SAUDE\\b", ignore_case = TRUE),  # pega "OLHO-D'AGUA DO BORGES"
        "JANUARIO CICCO"  # remove o hífen
      ),
    favorecido_do_pagamento_municipio_uf_norm = 
      str_replace_all(
        favorecido_do_pagamento_municipio_uf_norm,
        regex("\\bAUGUSTO\\s+SEVERO\\b", ignore_case = TRUE),  # pega "OLHO-D'AGUA DO BORGES"
        "CAMPO GRANDE"  # remove o hífen
      ),
    favorecido_do_pagamento_municipio_uf_norm = 
      str_replace_all(
        favorecido_do_pagamento_municipio_uf_norm,
        regex("\\bFORTALEZA\\s+DO\\s+TABOCAO\\b", ignore_case = TRUE),  # pega "OLHO-D'AGUA DO BORGES"
        "TABOCAO"  # remove o hífen
      )
    )


# Extrair o municipio_uf do favorecido
base_emendas_tmp <- base_emendas_tmp %>%
  mutate(
    B = sapply(favorecido_do_pagamento_municipio_uf_norm, function(Y) {          # Coluna auxiliar B: extrai X se estiver contido em favorecido_do_pagamento_municipio_uf
      match_X <- list_26mun_semhifen$mun_uf_norm[str_detect(Y, fixed(list_26mun_semhifen$mun_uf_norm))]
      if(length(match_X) > 0) match_X[1] else NA
    }),
    C = str_extract(favorecido_do_pagamento_municipio_uf_norm, "[^-]+-[^-]+$"),  # Coluna auxliar C: extrai Z (municipio_uf ao final da string)
    fav_mun_uf_norm = ifelse(!is.na(B), B, C),                        # Coluna municipio_uf: aplica a regra de retenção
    fav_mun_nm_norm = str_extract(fav_mun_uf_norm, ".*(?=-[A-Z]{2}$)"),     # Extrai o municipio de municipio_uf
    fav_uf_sg = str_extract(fav_mun_uf_norm, "[A-Z]{2}$"),                   # Extrai UF (as duas últimas letras maiúsculas)
    fav_uf_sg = if_else(str_detect(fav_uf_sg, "^[A-Z]{2}$"), fav_uf_sg, NA_character_), # Trata a UF: Substitui por NA se não forem duas letras maiúsculas
    
  )

View(base_emendas_tmp %>% select(favorecido_do_pagamento_municipio_uf_norm, B, C, fav_mun_uf_norm, fav_mun_nm_norm, fav_uf_sg) %>% 
       filter(is.na(fav_uf_sg)) %>% 
       distinct())

# Extrair o favorecido do pagamento
base_emendas_tmp1 <- base_emendas_tmp %>%
  mutate(
    favorecido_norm = ifelse(
      !is.na(fav_mun_uf_norm),
      favorecido_do_pagamento_municipio_uf_norm %>%
        str_remove(paste0("[-\\s]*", fixed(fav_mun_uf_norm), "$")) %>%  # remove o hífen e espaços antes de D, no final da string
        str_squish(),                                    # limpa sobras de espaço
      NA
    )
  )

View(base_emendas_tmp1 %>% select(favorecido_do_pagamento_municipio_uf_norm, favorecido_norm, fav_mun_uf_norm, fav_uf_sg) %>% distinct())

# Extrai numero da emenda e cria dummy marcando a emenda que não tem id do local 
base_emendas_tmp2 <- base_emendas_tmp1 %>%
  mutate(
    emenda_num = str_sub(string = emenda_numero_ano,  # Número da emenda
                         start = 1, end = str_length(emenda_numero_ano)-5),
    emenda_sem_mun = ifelse(is.na(fav_uf_sg),
                            yes = 1, no = 0)          # 1 se não tiver uf
    ) %>%
  rename(autor_sg_uf = "autor_uf")

# 1.4 Compatibilizar com os nomes na base do IBGE
base_emendas_tmp3 <- base_emendas_tmp2 %>%
  mutate(
    fav_mun_nm_norm = case_when(
      fav_mun_nm_norm == "AMPARO DA SERRA" ~ "AMPARO DO SERRA",
      fav_mun_nm_norm == "DONA EUSEBIA" ~ "DONA EUZEBIA",
      fav_mun_nm_norm == "VINTE" ~ "PASSA VINTE",
      fav_mun_nm_norm == "SAO THOME DAS LETRAS" ~ "SAO TOME DAS LETRAS",
      fav_mun_nm_norm == "SANTO ANTONIO DO LEVERGER" ~ "SANTO ANTONIO DE LEVERGER",
      fav_mun_nm_norm == "GRAO PARA" ~ "GRAO-PARA",
      TRUE ~ fav_mun_nm_norm
    )
  )


# Combina dados de municipios do IBGE e df de UFs criado acima
codigos_municipios3 <- codigos_municipios2 %>%
  rename(fav_mun_cod_ibge = "codigo_municipio_completo",
         fav_mun_nm_ibge = "nome_municipio",
         fav_mun_nm_ibge_norm = "nome_mun_norm",
         fav_uf_cod_ibge = "uf",
         fav_uf_sg_ibge = "uf_sigla",
         fav_mun_uf_ibge = "mun_uf",
         fav_mun_uf_ibge_norm = "mun_uf_norm") %>% 
  select(fav_mun_cod_ibge, fav_mun_nm_ibge, fav_mun_nm_ibge_norm, fav_mun_uf_ibge_norm, fav_uf_cod_ibge, fav_uf_sg_ibge)

# 3 Combina as bases de emendas e codigos de municípios --------
base_emendas_tmp4 <- base_emendas_tmp3 %>%
  left_join(codigos_municipios3,
            by = c("fav_mun_nm_norm" = "fav_mun_nm_ibge_norm",
                   "fav_uf_sg" = "fav_uf_sg_ibge"))
# checando NAs
base_emendas_tmp4 %>%
  filter(is.na(fav_mun_cod_ibge) & funcional_localidade_tipo == "MUNICÍPIO" &
           !favorecido_do_pagamento_municipio_uf_norm %in% c("NAO APLICAVEL-",
                                                             "IMPOSTO/CONTRIBUICAO-",
                                                             "NAO IDENTIFICADO-",
                                                             "CODIGO INEXISTENTE NO SIAFI-",
                                                             "NAO INFORMADO-")
         ) %>%
  distinct(funcao, favorecido_do_pagamento_municipio_uf_norm)

# Limpando o ambiente de trabalho
rm(list = setdiff(ls(), c("base_emendas_tmp4", "dir_dados_brut", "dir_dados_trat")))


# ----------------------- 2 Manipulação --------------------------------------------



# Reordenar colunas por blocos temáticos
base_emendas_tmp5 <- base_emendas_tmp4 %>%
  select(
    
    # Identificação da emenda
    emenda_ano, emenda_num, emenda_sem_mun,
    autor, autor_partido, autor_sg_uf,
    
    # Dados do favorecido e sua localidade
    favorecido_do_pagamento_municipio_uf, favorecido_do_pagamento_municipio_uf_norm, 
    favorecido_norm,
    fav_mun_cod_ibge,
    fav_mun_nm_norm,
    fav_uf_cod_ibge,
    fav_uf_sg,
    favorecido_do_pagamento_natureza_subgrupo,
    favorecido_do_pagamento_tipo,
    
    # Informações orçamentárias / Classificação funcional e programática 
    funcional,
    funcao, funcao_cod,
    subfuncao_ajustada, subfuncao_ajustada_cod,
    programa, programa_cod,
    acao_ajustada, acao_cod,
    subtitulo, subtitulo_cod,
    funcional_localidade, funcional_localidade_regiao,
    funcional_localidade_tipo,
    
    # Códigos estruturais e de execução orçamentária
    gnd_desc, gnd_cod,
    modalidade_aplicacao, modalidade_aplicacao_cod,
    orgao_superior, orgao_superior_cod,
    uo_ajustada, uo_cod,
    
    # Execução financeira
    ano_execucao,
    mes_execucao,
    pago_rp_favorecido_lista_ob_r,
    pago_rp_favorecido_lista_ob_ipca
    
    # Colunas auxiliares
    #b, c
  )

names(base_emendas_tmp5)

# Salvando
write_xlsx(base_emendas_tmp5, "emendas_individuais_13-03-2026-dados_para_o_powerbi.xlsx")



soma_pago_ipca <- sum(base_emendas_tmp5$pago_rp_favorecido_lista_ob_ipca)
soma_pago_reais <- sum(base_emendas_tmp5$pago_rp_favorecido_lista_ob_r)


# ══════════════════════════════════════════════════════════════════════════════
# SEÇÃO 3 — Modelagem dimensional para Power BI
# ══════════════════════════════════════════════════════════════════════════════

#tratamento dim_partido
base_emendas_tmp5 <- base_emendas_tmp5 %>%
  mutate(
    autor_partido = case_when(
      is.na(autor_partido) | autor_partido == "" ~ "NÃO INFORMADO",
      autor_partido == "S/PARTIDO" ~ "SEM PARTIDO",
      autor_partido == "NÃO INFORMADO" ~ "NÃO INFORMADO",
      autor_partido == "PCdoB" ~ "PCDOB",
      autor_partido == "Pros" ~ "PROS",
      autor_partido == "SOLIDARIED" ~ "SD",
      TRUE ~ autor_partido
    )
  )


#DIM_PARTIDO ══════════════════════════════════════════════════════════════════════════════
dim_partido <- base_emendas_tmp5 %>%
  distinct(autor_partido) %>%
  filter(!is.na(autor_partido)) %>%
  arrange(autor_partido) %>%
  mutate(id_partido = row_number())



#tratamento dim_autor ══════════════════════════════════════════════════════════════════════════════
dim_autor <- base_emendas_tmp5 %>%
  filter(!is.na(autor)) %>%
  mutate(
    autor = autor %>% 
      str_to_upper() %>%                   # Normaliza para MAIÚSCULAS
      str_replace_all("^DEP\\.?\\s+", "") %>% # Remove "DEP." ou "DEP " no início
      str_replace_all("^DEPUTADO\\s+", "") %>% # Remove "DEPUTADO " no início
      str_squish(),                        # Remove espaços duplos e nas pontas
     #REMOÇÃO DE ACENTUAÇÃO
      autor = iconv(autor, from = "UTF-8", to = "ASCII//TRANSLIT"),
      autor = str_replace_all(autor, "[^[:alnum:][:space:]]", ""), # Remove resquícios de acentos
     # LIMPEZA DA UF DO AUTOR (Onde estava o erro)
      autor_sg_uf = autor_sg_uf %>% 
      str_trim() %>% 
      str_to_upper() %>%
      str_extract("[A-Z]{2}") # Garante que fiquem apenas as 2 letras da UF
  ) %>%
  mutate(
    autor = case_when(
      autor == "PAULO FOLLETTO" ~ "PAULO FOLETTO",
      autor == "ALENCAR SANTANA" ~ "ALENCAR SANTANA BRAGA",
      autor == "ADRIAN"          ~ "ADRIAN MUSSI RAMOS",
      autor == "ANGELIM"    ~ "RAIMUNDO ANGELIM",
      autor == "IRAJA"    ~ "IRAJA ABREU",
      autor == "LUIZ DO CARMO"  ~ "LUIZ CARLOS DO CARMO",
      autor == "WEVERTON"    ~ "WEVERTON ROCHA",
      autor == "DR ISMAEL ALEXANDRINO" ~ "ISMAEL ALEXANDRINO",
      autor == "HAROLDO CATHEDRAL" ~ "ZE HAROLDO CATHEDRAL",
      autor == "PROFESSORA DORINHA SEABRA" ~ "PROFESSORA DORINHA SEABRA REZENDE",
      TRUE ~ autor
    )
  ) %>%
  distinct(autor, autor_sg_uf, .keep_all = TRUE) %>%
  select(autor, autor_sg_uf) %>% 
  arrange(autor) %>%
  mutate(id_autor = row_number())





# ── dim_municipio ─────────────────────────────────────────────────────────────
dim_municipio <- base_emendas_tmp5 %>%
  distinct(fav_mun_cod_ibge, fav_mun_nm_norm, fav_uf_sg,
           fav_uf_cod_ibge) %>%
  filter(!is.na(fav_mun_cod_ibge)) %>%
  mutate(
    # Garante que a UF do município esteja no exato mesmo formato da UF do autor
    fav_uf_sg = fav_uf_sg %>% 
      str_trim() %>% 
      str_to_upper() %>%
      str_extract("[A-Z]{2}")
  ) %>%
  arrange(fav_mun_nm_norm)



# ── dim_funcao ────────────────────────────────────────────────────────────────
dim_funcao <- base_emendas_tmp5 %>%
  distinct(funcao_cod, funcao) %>%
  filter(!is.na(funcao_cod)) %>%
  arrange(funcao_cod)




#dim_subfuncao

#tratamento dim_subfuncao

base_emendas_tmp5 <- base_emendas_tmp5 %>%
  mutate(
    subfuncao_ajustada = case_when(
      subfuncao_ajustada_cod == 241 & subfuncao_ajustada == "ASSISTÊNCIA À PESSOA IDOSA" 
      ~ "ASSISTÊNCIA AO IDOSO",
      TRUE ~ subfuncao_ajustada
    )
  )



#dim_subfuncao
dim_subfuncao <- base_emendas_tmp5 %>%
  distinct(subfuncao_ajustada_cod, subfuncao_ajustada) %>%
  filter(!is.na(subfuncao_ajustada_cod)) %>%
  arrange(subfuncao_ajustada_cod)






#dim_gnd

dim_gnd <- base_emendas_tmp5 %>%
  distinct(gnd_cod, gnd_desc) %>%
  filter(!is.na(gnd_cod)) %>%
  arrange(gnd_cod)




# ── dim_orgao ─────────────────────────────────────────────────────────────────
dim_orgao <- base_emendas_tmp5 %>%
  distinct(uo_cod, uo_ajustada, orgao_superior_cod, orgao_superior, ano_execucao) %>%
  group_by(uo_cod, orgao_superior_cod) %>%
  slice_max(ano_execucao, n = 1, with_ties = FALSE) %>%
  ungroup() %>%
  select(uo_cod, uo_ajustada, orgao_superior_cod, orgao_superior) %>%
  filter(!is.na(uo_cod)) %>%
  arrange(orgao_superior_cod, uo_cod)



#dim_calendario


#NAO SE TEM CONTAGEM DE MêS DISPONIVEL PARA 2024,2025 E 2026!!!
base_emendas_tmp5 %>%
  filter(mes_execucao == "-") %>%
  count(ano_execucao, funcional_localidade_tipo)

contagem_mes <- base_emendas_tmp5 %>%
  count(ano_execucao, mes_execucao)

view(contagem_mes)
#NAO SE TEM CONTAGEM DE MÊS DISPONÍVEIS PARA 2024,2025 E 2026!!!


#DIM_CALENDARIO




# ── dim_calendario ────────────────────────────────────────────────────────────

# Limpar o "-" da coluna mes_execucao
base_emendas_tmp5 <- base_emendas_tmp5 %>%
  mutate(
    mes_execucao = if_else(mes_execucao == "-", NA_character_, mes_execucao),
    ano_execucao = as.integer(ano_execucao)
  )

# Mapa de conversão de meses
meses_map <- c(
  "JANEIRO" = 1, "FEVEREIRO" = 2, "MARÇO" = 3,
  "ABRIL" = 4, "MAIO" = 5, "JUNHO" = 6,
  "JULHO" = 7, "AGOSTO" = 8, "SETEMBRO" = 9,
  "OUTUBRO" = 10, "NOVEMBRO" = 11, "DEZEMBRO" = 12
)

# Criar mes_execucao_num e data_ref na base
base_emendas_tmp5 <- base_emendas_tmp5 %>%
  mutate(
    mes_execucao_num = recode(mes_execucao, !!!meses_map, .default = NA_real_),
    data_ref = as.Date(ifelse(
      !is.na(mes_execucao_num),
      paste(ano_execucao, sprintf("%02d", as.integer(mes_execucao_num)), "01", sep = "-"),
      NA_character_
    ))
  )

# Construir dim_calendario
dim_calendario <- base_emendas_tmp5 %>%
  filter(!is.na(data_ref)) %>%
  distinct(data_ref, ano_execucao, mes_execucao_num) %>%
  mutate(
    mes_nome        = format(data_ref, "%B") %>% str_to_upper(),
    mes_abrev       = format(data_ref, "%b") %>% str_to_upper(),
    trimestre       = paste0(ano_execucao, " T", ceiling(mes_execucao_num / 3)),
    semestre        = paste0(ano_execucao, " S", ceiling(mes_execucao_num / 6)),
    ano_mes         = as.integer(format(data_ref, "%Y%m")),
    ano_legislativo = if_else(mes_execucao_num >= 2, ano_execucao, ano_execucao - 1),
    legislatura     = case_when(
      ano_legislativo <= 2003 ~ "51ª Legislatura (1999-2003)",
      ano_legislativo <= 2007 ~ "52ª Legislatura (2003-2007)",
      ano_legislativo <= 2011 ~ "53ª Legislatura (2007-2011)",
      ano_legislativo <= 2015 ~ "54ª Legislatura (2011-2015)",
      ano_legislativo <= 2019 ~ "55ª Legislatura (2015-2019)",
      ano_legislativo <= 2022 ~ "56ª Legislatura (2019-2023)",
      TRUE                    ~ "57ª Legislatura (2023-2027)"
    ),
    ano_eleitoral   = ano_execucao %% 4 == 2,
    rotulo          = format(data_ref, "%b/%Y") %>% str_to_upper()
  ) %>%
  select(-mes_execucao_num) %>%
  arrange(data_ref)





#TABELA FATO

# ── fato_execucao ─────────────────────────────────────────────────────────────

# Passo 1: padronizar autor na base antes do join com dim_autor
base_emendas_tmp5 <- base_emendas_tmp5 %>%
  mutate(
    autor = autor %>%
      str_to_upper() %>%
      str_replace_all("^DEP\\.?\\s+", "") %>%
      str_replace_all("^DEPUTADO\\s+", "") %>%
      str_squish(),
    autor = iconv(autor, from = "UTF-8", to = "ASCII//TRANSLIT"),
    autor = str_replace_all(autor, "[^[:alnum:][:space:]]", ""),
    autor = case_when(
      autor == "PAULO FOLLETTO"          ~ "PAULO FOLETTO",
      autor == "ALENCAR SANTANA"         ~ "ALENCAR SANTANA BRAGA",
      autor == "ADRIAN"                  ~ "ADRIAN MUSSI RAMOS",
      autor == "ANGELIM"                 ~ "RAIMUNDO ANGELIM",
      autor == "IRAJA"                   ~ "IRAJA ABREU",
      autor == "LUIZ DO CARMO"           ~ "LUIZ CARLOS DO CARMO",
      autor == "WEVERTON"                ~ "WEVERTON ROCHA",
      autor == "DR ISMAEL ALEXANDRINO"   ~ "ISMAEL ALEXANDRINO",
      autor == "HAROLDO CATHEDRAL"       ~ "ZE HAROLDO CATHEDRAL",
      autor == "PROFESSORA DORINHA SEABRA" ~ "PROFESSORA DORINHA SEABRA REZENDE",
      TRUE ~ autor
    )
  )

# Passo 2: construir a fato
fato_execucao <- base_emendas_tmp5 %>%
  
  # ── FKs para dimensões ──────────────────────────────────────────────────────
  
  # FK dim_autor
  left_join(dim_autor %>% select(autor, id_autor),
            by = "autor") %>%
  
  # FK dim_partido
  left_join(dim_partido %>% select(autor_partido, id_partido),
            by = "autor_partido") %>%
  
  # ── Selecionar colunas finais ───────────────────────────────────────────────
  select(
    
    # Chaves estrangeiras
    id_autor,
    id_partido,
    fav_mun_cod_ibge,
    funcao_cod,
    subfuncao_ajustada_cod,
    gnd_cod,
    uo_cod,
    orgao_superior_cod,
    data_ref,
    
    # Atributos degenerados — identificação da emenda
    emenda_num,
    emenda_ano,
    emenda_sem_mun,
    ano_execucao,
    
    # Atributos degenerados — favorecido
    favorecido_norm,
    favorecido_do_pagamento_tipo,
    favorecido_do_pagamento_natureza_subgrupo,
    
    # Atributos degenerados — orçamentários
    modalidade_aplicacao,
    programa,
    acao_ajustada,
    
    # Atributos degenerados — localidade programática
    funcional_localidade,
    funcional_localidade_tipo,
    funcional_localidade_regiao,
    
    # Medidas
    pago_rp_favorecido_lista_ob_r,
    pago_rp_favorecido_lista_ob_ipca
  ) %>% 

  # Conversões de tipo
  mutate(
    fav_mun_cod_ibge       = as.integer(fav_mun_cod_ibge),
    funcao_cod             = as.integer(funcao_cod),
    subfuncao_ajustada_cod = as.integer(subfuncao_ajustada_cod),
    gnd_cod                = as.integer(gnd_cod),
    uo_cod                 = as.integer(uo_cod),
    orgao_superior_cod     = as.integer(orgao_superior_cod),
    emenda_ano             = as.integer(emenda_ano)
  )
  

# ── Exportação para Power BI ──────────────────────────────────────────────────
write_xlsx(list(
  fato_execucao  = fato_execucao,
  dim_autor      = dim_autor,
  dim_partido    = dim_partido,
  dim_municipio  = dim_municipio,
  dim_funcao     = dim_funcao,
  dim_subfuncao  = dim_subfuncao,
  dim_gnd        = dim_gnd,
  dim_orgao      = dim_orgao,
  dim_calendario = dim_calendario
), paste0(dir_dados_trat, "/emendas_individuais/modelo_dimensional_powerbi.xlsx"))


#IMPORTAR LAT E LONG SERÁ IMPORTANTE PARA O MAPA DO POWERBI FUNCIONAR


# Instalar pacote com coordenadas dos municípios brasileiros
install.packages("geobr")
library(geobr)

# Baixar centroides dos municípios
municipios_geo <- read_municipality(year = 2022) %>%
  mutate(
    lat = sf::st_coordinates(sf::st_centroid(geom))[,2],
    lon = sf::st_coordinates(sf::st_centroid(geom))[,1],
    fav_mun_cod_ibge = as.integer(code_muni)
  ) %>%
  as.data.frame() %>%
  select(fav_mun_cod_ibge, lat, lon)

municipios_geo <- municipios_geo %>%
  mutate(
    lat = case_when(fav_mun_cod_ibge == 3205309 ~ -20.3155, TRUE ~ lat),
    lon = case_when(fav_mun_cod_ibge == 3205309 ~ -40.3128, TRUE ~ lon)
  )

dim_municipio <- dim_municipio %>%
  mutate(fav_mun_cod_ibge = as.integer(fav_mun_cod_ibge)) %>%
  left_join(municipios_geo, by = "fav_mun_cod_ibge")





# ── Reexportação para Power BI ────────────────────────────────────────────────
write_xlsx(list(
  fato_execucao  = fato_execucao,
  dim_autor      = dim_autor,
  dim_partido    = dim_partido,
  dim_municipio  = dim_municipio,
  dim_funcao     = dim_funcao,
  dim_subfuncao  = dim_subfuncao,
  dim_gnd        = dim_gnd,
  dim_orgao      = dim_orgao,
  dim_calendario = dim_calendario
), paste0(dir_dados_trat, "/emendas_individuais/modelo_dimensional_powerbi.xlsx"))
