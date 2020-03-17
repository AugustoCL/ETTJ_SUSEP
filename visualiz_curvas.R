library(tidyverse)
library(ggthemes)
library(gganimate)
library(av)
library(gifski)
library(readxl)

# Inputs
dir_base <- "~/dev_Py/Py/ETTJ_SUSEP/historico_curvas"
arquivo <- "historico_curvas.xlsx"
n_row <- 50

setwd(dir_base)

hist_pre <- arquivo %>% 
    # Extrai os dados históricos de cada aba do arquivo .xlsx
    read_excel(sheet = "curvas_pre", n_max = n_row) %>%
    # Cria a variável curva com o cupom correspondente
    mutate(curva = "PREFIXADO") %>% 
    # transforma os dados em formato 'long'
    gather(key = "anomes", value = "taxa", -c(nseq, dias, curva))

hist_ipca <- arquivo %>% 
    read_excel(sheet = "curvas_ipca", n_max = n_row) %>%
    mutate(curva = "IPCA") %>% 
    gather(key = "anomes", value = "taxa", -c(nseq, dias, curva))

hist_igpm <- arquivo %>% 
    read_excel(sheet = "curvas_igpm", n_max = n_row) %>%
    mutate(curva = "IGPM") %>% 
    gather(key = "anomes", value = "taxa", -c(nseq, dias, curva))

hist_tr <- arquivo %>% 
    read_excel(sheet = "curvas_tr", n_max = n_row) %>%
    mutate(curva = "TR") %>% 
    gather(key = "anomes", value = "taxa", -c(nseq, dias, curva))

# Une as 4 tibbles em uma única tibble
hist_curvas <- rbind(hist_pre, hist_ipca, hist_igpm, hist_tr)

# Cria a variável data a partir da variável anomes
hist_curvas$data <- as.Date(paste0(as.character(hist_curvas$anomes), '01'), format='%Y%m%d')

# Transforma a variável curva em fator
hist_curvas$curva <- factor(hist_curvas$curva)
                             
# cria nível nos fatores para ajustar a ordem da visualizacao
neworder <- c("PREFIXADO", "TR", "IPCA", "IGPM")
hist_curvas <- arrange(transform(hist_curvas,curva=factor(curva,levels=neworder)),curva)  
hist_curvas <- hist_curvas %>% as_tibble()


p <- hist_curvas %>% 
    mutate(taxa1 = taxa*100) %>% 
    select(-taxa) %>% 
    rename(taxa = taxa1) %>% 
    ggplot(aes(x = dias, y = taxa)) +
    ylab("Juros % a.a") +
    xlab("Dias") +
    geom_line(size = 1.5,
              show.legend = FALSE) +
    facet_wrap(~curva,
               scales = "free") + 
    theme_bw() +
    theme(strip.text.x = element_text(size = 12, color = "black", face = "bold")) +
    labs(caption = "Elaborado por: @AugustoCL\n Fonte: Coeficientes SUSEP")

# Adiciona as funções de animação da visualizacao
p <- p + transition_time(data)+ 
    ease_aes(y = 'cubic-in-out') +
    labs(title = "Interpolação e Extrapolação das Curvas de Juros (201512 - 2020202)", 
         subtitle = 'Modelo: Nelson Siegel Svensson\nPeríodo: {format(frame_time,"%Y%m")}')

# Gera a animação em .gif no diretório base
gganimate::animate(p, start_pause = 3,
                         end_pause = 3,
                         renderer = gifski_renderer("curvas_201512_202002.gif"))


