require(pacman)
pacman::p_load(glue, qs, terra, sf, tidyverse, RColorBrewer, ggspatial)

g <- gc(reset = TRUE)
rm(list = ls())

# Load data ----------------------------
path <- './outputs/velocity/tree_spp2'
files <- list.files(path, full.names = TRUE)
# species <- basename(files)
# species <-  str_sub(species, start = 9, end = -18)
# species <- unique(species)
species<- c("ABIEB", "ACERR", "ACERS", "BETUA", "FAGUG","LARIL", "PICEE",
            "PICEG", "PICEM", "PICER",  "PINUB", "PINUR", "PINUS","POPUT",
            "THUJO")
ssp <- c('ssp126', 'ssp245', 'ssp370', 'ssp585')
labs <- c('ssp1-2.6','ssp2-4.5', 'ssp3-7.0', 'ssp5-8.5')
yrs <- c('2040', '2070', '2100')
limt <- terra::vect('./inputs/boundaries/AlaskaCA.shp')

get_meanRas <- function(sp, baseline){
# sp <- species[1]
  message(crayon::blue('Creating table for species', sp,'\n'))
  fls <- grep(sp, files, value = TRUE)
  
  spMap <- map(.x = 1:length(ssp), function(k){
    message(crayon::blue('Applying to', ssp[k] ,'\n'))
    sp_fls <- grep(ssp[k], fls, value = TRUE)
    sp_fls <- grep(baseline, sp_fls, value = TRUE)
 
    spAvg <- map(.x = 1:length(yrs), function(i){
      message(crayon::blue('Calculating average for year', yrs[i] ,'\n'))
      yr_fls <- grep(yrs[i], sp_fls, value = TRUE)
      bck_fl <- grep('backward', yr_fls, value = TRUE)
      fwd_fl <- grep('forward', yr_fls, value = TRUE)
      #read rasters 
      bck_ras <- terra::rast(bck_fl)
      fwd_ras <- terra::rast(fwd_fl)
    
      #stack both rasters   
      stk <- c(bck_ras,fwd_ras)
      #get the mean of the stk and rm NA values 
      mean_ras <- mean(stk, na.rm = TRUE)
      # # Create a mask of NA values in the original rasters
      # bck_msk <- is.na(bck_ras)
      # fwd_msk <- is.na(fwd_ras)
      # 
      # mean_ras_msk <- mask(mean_ras, bck_msk|fwd_msk, maskvalue = -99)
      out <- glue('./outputs/meanRas/')
      #create a directory to save the raster 
      ifelse(!file.exists(out), dir_create(out), print('Already exists'))
      #save the spatRaster 
      terra::writeRaster(mean_ras, glue('{out}/meanRefugia_{sp}_{baseline}_{ssp[k]}_{yrs[i]}.tif'),
                         filetype = 'GTiff', datatype = 'INT4U',  
                         overwrite = TRUE)
     
    })
  })
  message(crayon::green('Done!'))
}

# Apply the function ------------------------------------------------------
meanRas <- map(.x = species, baseline = 'p1991', .f = get_meanRas)
  
