### LIBRARY's ----
library(tidyverse)
library(ggthemes)
library(gganimate)
library(av)
library(gifski)
library(readxl)
library(ggrepel)
library(directlabels)
library(ggpubr)
library(hrbrthemes)
library(extrafont)
loadfonts(quiet = TRUE)


### INPUTS ----
dir_base <- "~/dev_Py/juros_futuros_susep"
arquivo <- "historico_curvas.xlsx"
n_row <- 50

setwd(dir_base)


### IMPORTAÇÃO ----

hist_pre <- arquivo %>% 
    # Extrai os dados históricos de cada aba do arquivo .xlsx
    read_excel(sheet = "curvas_pre", n_max = n_row) %>%
    # Cria a variável curva com o cupom correspondente
    mutate(curva = "PREFIXADO") %>% 
    # retira dados com dias úteis menores que 126du
    tail(44) %>%
    # transforma os dados em formato 'long'
    gather(key = "anomes", value = "taxa", -c(nseq, dias, curva))

hist_ipca <- arquivo %>% 
    read_excel(sheet = "curvas_ipca", n_max = n_row) %>%
    mutate(curva = "IPCA") %>% 
    tail(44) %>% 
    gather(key = "anomes", value = "taxa", -c(nseq, dias, curva))

hist_igpm <- arquivo %>% 
    read_excel(sheet = "curvas_igpm", n_max = n_row) %>%
    mutate(curva = "IGPM") %>% 
    tail(44) %>% 
    gather(key = "anomes", value = "taxa", -c(nseq, dias, curva))

hist_tr <- arquivo %>% 
    read_excel(sheet = "curvas_tr", n_max = n_row) %>%
    mutate(curva = "TR") %>% 
    tail(44) %>%
    gather(key = "anomes", value = "taxa", -c(nseq, dias, curva))



### LIMPEZA ----

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


### facet_plot .GIF ---- 
facet_plot <- hist_curvas %>% 
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
facet_plot <- facet_plot + transition_time(data)+ 
    ease_aes(y = 'cubic-in-out') +
    labs(title = "Interpolação e Extrapolação das Curvas de Juros (201512 - 2020202)", 
         subtitle = 'Modelo: Nelson Siegel Svensson\nPeríodo: {format(frame_time,"%Y%m")}')

# Gera a animação em .gif no diretório base
gganimate::animate(facet_plot, 
                   start_pause = 3,
                   end_pause = 3,
                   renderer = gifski_renderer("curvas_201512_202002_facet.gif"))


### color_plot .GIF ----
p <- hist_curvas %>% 
    mutate(taxa1 = taxa*100) %>% 
    select(-taxa) %>% 
    rename(taxa = taxa1) %>%
    # filter(anomes == "201912") %>%
    mutate(label = if_else(dias == max(dias), as.character(curva), NA_character_)) %>%
    
    ggplot(aes(x = dias, y = taxa, color = curva)) +
    geom_line(size = 2, linejoin = "bevel") +
    geom_label_repel(aes(label = label),
                     nudge_x = 1,
                     na.rm = TRUE,
                     inherit.aes = TRUE) +
    ylab("Juros % a.a") +
    xlab(NULL) +
    labs(title = 'Interpolação e Extrapolação das Curvas de Juros - {format(frame_time,"%Y%m")}', 
         subtitle = 'Modelo: Nelson Siegel Svensson',
         color = NULL, 
         caption = "Elaboração: @AugustoCL") +
    # scale_y_continuous(breaks = scales::pretty_breaks(7)) +
    scale_x_continuous(breaks = scales::pretty_breaks(6),
                       labels = scales::dollar_format(prefix = NULL, suffix = " du")) +
    scale_color_brewer(palette = "Set1") +
    theme_minimal(base_family = "Trebuchet MS") +
    theme(strip.text.x = element_text(size = 12, color = "black", face = "bold"),
          legend.position = "none",
          axis.title.x = element_text(hjust = 0.5),
          axis.title.y = element_text(hjust = 0.5),
          text = element_text(family = "Trebuchet MS")) 

p <- p + transition_time(data)+ 
    ease_aes(y = 'linear') # 'cubic-in-out'

gganimate::animate(p1, start_pause = 3,
                   end_pause = 3,
                   renderer = gifski_renderer("curvas_201512_202002.gif"))



### dark_plot.GIF ----
p_dark <- hist_curvas %>% 
    mutate(taxa1 = taxa*100) %>% 
    select(-taxa) %>% 
    rename(taxa = taxa1) %>%
    # filter(anomes == "201912") %>%
    mutate(label = if_else(dias == max(dias), as.character(curva), NA_character_)) %>%
    
    ggplot(aes(x = dias, y = taxa, color = curva)) +
    geom_line(size = 2, linejoin = "bevel") +
    geom_label_repel(aes(label = label),
                     nudge_x = 1,
                     na.rm = TRUE,
                     inherit.aes = TRUE) +
    ylab("Juros % a.a") +
    xlab(NULL) +
    labs(title = 'Interpolação das Curvas de Juros - {format(frame_time,"%Y%m")}', 
         subtitle = 'Modelo: Nelson Siegel Svensson',
         color = NULL, 
         caption = "Elaboração: @AugustoCL") +
    # scale_y_continuous(breaks = scales::pretty_breaks(7)) +
    scale_x_continuous(breaks = scales::pretty_breaks(6),
                       labels = scales::dollar_format(prefix = NULL, suffix = " du")) +
    scale_color_brewer(palette = "Set1") +
    hrbrthemes::theme_modern_rc(base_family = "Trebuchet MS") +
    theme(strip.text.x = element_text(size = 10,
                                      face = "bold"),
          legend.position = "none",
          axis.text = element_text(size = 2),
          axis.title.x = element_text(hjust = 0.5),
          axis.title.y = element_text(),
          title = element_text(family = "Trebuchet MS"),
          text = element_text(family = "Trebuchet MS")) 

p_dark <- p_dark + 
    transition_time(data) +
    ease_aes(y = 'linear') # 'cubic-in-out'

gganimate::animate(p_dark, start_pause = 3,
                   end_pause = 3,
                   # height = 600, width = 800,
                   renderer = gifski_renderer("curvas_201512_202002_dark.gif"))




