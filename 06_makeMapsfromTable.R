require(pacman)
pacman::p_load(glue, qs, terra, sf, tidyverse, RColorBrewer, ggspatial)

g <- gc(reset = TRUE)
rm(list = ls())

# Load data ----------------------------
path <- './outputs/tables/treeRefugia'
files <- list.files(path,pattern = 'backward_', full.names = TRUE)
# species <- basename(files)
# species <-  str_sub(species, start = 9, end = -18)
# species <- unique(species)
species<- c("ABIEB", "ACERR", "ACERS", "BETUA", "FAGUG","LARIL", "PICEE",
            "PICEG", "PICEM", "PICER",  "PINUB", "PINUR", "PINUS","POPUT",
            "THUJO")
ssp <- c('_ssp126_', '_ssp245_', '_ssp370_', '_ssp585_')
yrs <- c('2040', '2070', '2100')
baseline <- 'p1961'

makeMap <- function(sp, baseline, yr){
  sp <- species[8]
  message(crayon::blue('Creating map for species', sp,'\n'))
  fls <- grep(sp, files, value = TRUE)
  fl <- grep(baseline, fls, value = TRUE)
  tbl <- qs::qread(file = fl)
  df <- tbl %>% pivot_longer(cols = 3:5 ,
                             names_to = 'yr', values_to = "value") %>% 
    mutate(yr = as.numeric(gsub('y_','', yr))) %>% 
    rename('lon' = x, 'lat' = y)
  
  makeMaps <- map(.x = 1:length(ssp), function(k){
    message(crayon::blue('Making map for:', ssp[k] ,'\n'))
    
    df <- df %>% filter(ssp == ssp[k])
 
  gavg <- ggplot() + 
    geom_tile(data = df, aes(x = lon, y = lat, fill = value)) + 
    #scale_fill_gradientn(colors = RColorBrewer::brewer.pal(n = 8, name = 'BuPu')) + 
    scale_fill_gradientn(colours = brewer.pal(n = 10, name = 'BrBG')) +
    theme_bw() + 
    ggtitle(label = glue('Refugia index {sp}'),
            subtitle = gsub('_', '', ssp[k])) +
    theme(legend.position = 'bottom',legend.key.width = unit(2, 'line'),
          plot.title = element_text(size = 16, face = 'bold', hjust = 0, vjust = 0.7),
          plot.subtitle = element_text(size = 14),
          axis.title = element_text(size = 14),
          axis.text.x = element_text(size = 12),
          axis.text.y = element_text(size = 12),
          legend.text = element_text(size = 11),
          legend.title = element_text(size = 12, face = 'bold'),
          strip.text = element_text(size = 14)) +  
    labs(x = 'Longitude', y = 'Latitude', fill = 'Refugia') +
    coord_sf() + 
    facet_wrap(.~ yr, nrow = 1, ncol = 3) 
  out <- glue('./maps/trees/')
  ifelse(!file.exists(out), dir_create(out), print('Already exists'))
  
  ggsave(plot = gavg, filename = glue('{out}/backward_refugia_{sp}_{ssp[k]}_{baseline}.png'), 
         units = 'in', width = 14, height = 5, dpi = 300)
    
  })
}

# Apply the function ------------------------------------------------------
dfrm <- map(.x = species, baseline = 'p1991', .f = makeMap)
