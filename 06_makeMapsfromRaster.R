require(pacman)
pacman::p_load(glue, googledrive, qs, terra, sf, tidyterra, tidyverse)

g <- gc(reset = TRUE)
rm(list = ls())

# Load data ----------------------------
path <- './outputs/velocity/tree_spp2'
#species <- basename(files)
# species <-  str_sub(species, start = 10, end = -32)
# species <- unique(species)
species<- c("ABIEB", "ACERR", "ACERS", "BETUA", "FAGUG","LARIL", "PICEE",
            "PICEG", "PICEM", "PICER",  "PINUB", "PINUR", "PINUS","POPUT",
            "THUJO")
ssp <- c('ssp126', 'ssp245', 'ssp370', 'ssp585')
labs <- c('ssp1-2.6','ssp2-4.5', 'ssp3-7.0', 'ssp5-8.5')
yrs <- c('2040', '2070', '2100')
type <- 'backward'
limt <- terra::vect('./inputs/boundaries/AlaskaCA.shp')

makeMap <- function(sp, type, baseline ){
  #sp <- species[8]
  files <- list.files(path,pattern = type, full.names = TRUE)
  message(crayon::blue('Creating table for species', sp,'\n'))
  fls <- grep(sp, files, value = TRUE)
  
  spMap <- map(.x = 1:length(ssp), function(k){
    message(crayon::blue('Applying to', ssp[k] ,'\n'))
    sp_fls <- grep(ssp[k], fls, value = TRUE)
    sp_fls <- grep(baseline, sp_fls, value = TRUE)
    
    #read rasters 
    rst <- terra::rast(sp_fls)
    names(rst) <- yrs
    
    ##make ggplot
spMap<- ggplot() +
  geom_spatraster(data = rst) +
  geom_spatvector(data = limt, fill = NA) +
  facet_wrap(~lyr, ncol = 3) +
  scale_fill_gradientn(colours = brewer.pal(n = 5, name = 'BrBG'), na.value = NA) +
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
       title = glue('{str_to_title(type)} refugia index {sp}'),
       subtitle = labs[k]) +
  coord_sf(xlim = c(-4500000, 3500000), 
           ylim = c(-1500000, 5500000),
           expand = FALSE)  
out <- glue('./maps/trees2/')
ifelse(!file.exists(out), dir_create(out), print('Already exists'))

ggsave(plot = spMap, filename = glue('{out}/{type}_refugia_{sp}_{ssp[k]}_{baseline}.png'), 
       units = 'in', width = 10, height = 4, dpi = 300)
 })
  message(crayon::green('Done!'))
}

# Apply the function ------------------------------------------------------
dfrm <- map(.x = species, type = 'forward', baseline = 'p1991', .f = makeMap)


# Upload to Drive----------------------------------------------------------
outputFolder <- './maps/trees2/'
googleFolderID <- 'https://drive.google.com/drive/folders/1mxy2kcmRE72JO9FZ4bAKR24F2AmGHb4p' #Trees

fl <- list.files(outputFolder, full.names = TRUE)
lapply(X = fl, FUN = drive_upload, path = as_id(googleFolderID))

