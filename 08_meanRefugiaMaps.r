library(pacman)
pacman::p_load(ggplot2, glue, googledrive, qs, RColorBrewer,terra, sf, 
               tidyterra, tidyverse)

g <- gc(reset = TRUE)
rm(list = ls())

# Load data ----------------------------
path <- './outputs/meanRas'
#species <- basename(files)
# species <-  str_sub(species, start = 10, end = -32)
# species <- unique(species)
species<- c("ABIEB", "ACERR", "ACERS", "BETUA", "FAGUG","LARIL", "PICEE",
            "PICEG", "PICEM", "PICER",  "PINUB", "PINUR", "PINUS","POPUT",
            "THUJO")
ssp <- c('ssp126', 'ssp245', 'ssp370', 'ssp585')
labs <- c('ssp1-2.6','ssp2-4.5', 'ssp3-7.0', 'ssp5-8.5')
yrs <- c('2040', '2070', '2100')
limt <- terra::vect('./inputs/boundaries/AlaskaCA.shp')

makeMeanMap <- function(sp, type, baseline ){
 # sp <- species[1]
  files <- list.files(path, full.names = TRUE)
  message(crayon::blue('Creating table for species', sp,'\n'))
  fls <- grep(sp, files, value = TRUE)
  
  meanMap <- map(.x = 1:length(ssp), function(k){
    message(crayon::blue('Applying to', ssp[k] ,'\n'))
    sp_fls <- grep(ssp[k], fls, value = TRUE)
    sp_fls <- grep(baseline, sp_fls, value = TRUE)
   
    #read rasters 
    rst<- terra::rast(sp_fls)
    names(rst) <- yrs
    
    ##make ggplot
    meanSpMap<- ggplot() +
      geom_spatraster(data = rst) +
      geom_spatvector(data = limt, fill = NA) +
      facet_wrap(~lyr, ncol = 3) +
      scale_fill_gradientn(colours = brewer.pal(n = 5, name = 'Set2'), 
                           na.value = NA) +
      theme_bw() + 
      theme(legend.position = 'bottom',legend.key.width = unit(2, 'line'),
            plot.title = element_text(size = 16, face = 'bold', hjust = 0, vjust = 0.7),
            plot.subtitle = element_text(size = 14),
            axis.title = element_text(size = 14),
            axis.text.x = element_text(size = 12),
            axis.text.y = element_text(size = 12),
            legend.text = element_text(size = 11),
            legend.title = element_text(size = 12, face = 'bold'),
            panel.grid = element_blank(),
            strip.text = element_text(size = 14,face = 'bold')) +  
      labs(x = 'Longitude', y = 'Latitude', fill = 'Refugia',
           title = glue('Mean refugia index {sp}'),
           subtitle = labs[k]) +
      coord_sf(xlim = c(-4500000, 3500000), 
               ylim = c(-1500000, 5500000),
               expand = FALSE)  
    out <- glue('./maps/trees2/meanRefugia')
    ifelse(!file.exists(out), dir_create(out), print('Already exists'))
    
    ggsave(plot = meanSpMap, filename = glue('{out}/Meanrefugia_{sp}_{ssp[k]}_{baseline}.png'), 
           units = 'in', width = 7, height = 4, dpi = 300)
  })
  message(crayon::green('Done!'))
}

# Apply the function ------------------------------------------------------

dfrm <- map(.x = species, baseline = 'p1961', .f = makeMeanMap)


# Upload to Drive----------------------------------------------------------
outputFolder <- './maps/trees2/meanRefugia'
googleFolderID <- 'https://drive.google.com/drive/folders/11T9ljiwZ8uV1112XB4m4YAUMsGE11k5T' #meanRefugia

fl <- list.files(outputFolder, full.names = TRUE)
lapply(X = fl, FUN = drive_upload, path = as_id(googleFolderID))

