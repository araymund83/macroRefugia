# Load libraries ----------------------------------------------------------
library(pacman)
pacman::p_load(dplyr, fs, fst, glue, googledrive, stringr,tidyverse, terra, 
               yaImpute)
g <- gc(reset = TRUE)
rm(list = ls())

# Functions ---------------------------------------------------------------
source('./R/fatTail.R')

# Load data ---------------------------------------------------------------
filesFut <- list.files('./inputs/tree_spp/fut_thresholded2', 
                      pattern = '.tif', full.names = TRUE)

filesPres <- list.files('./inputs/tree_spp/pres_thresholded2',
                        full.names = TRUE)
species <- basename(filesPres)
species <-  str_sub(species, end = -35)
species <- unique(species)

# Backwards Velocity metric ---------------------------------------------------------
get_backward_velocity <- function(sp, baseline){
 sp <- species[1] # use for testing
  message(crayon::blue('Starting with:', sp, '\n'))
  flsPres <- grep(sp, filesPres, value = TRUE)
  flsFut <- grep(sp, filesFut, value = TRUE)
  ssp <- c('_ssp126_', '_ssp245_', '_ssp370_', '_ssp585_')
  yrs <- c('2040', '2070', '2100')
  baseline <- baseline
  
  rsltdo <- map(.x = 1:length(ssp), function(k){
    message(crayon::blue('Applying to', ssp[k] ,'\n'))
    flsFut <- grep(ssp[k], flsFut, value = TRUE)
    
    rs <- map(.x = 1:length(yrs), function(i){
      message(crayon::blue('Applying to year',yrs[i], '\n'))
      flePres <- grep(baseline, flsPres, value = TRUE) #p 1961 for the first baseline, p1991 for the second baseline
      fleFut <- grep(yrs[i], flsFut, value = TRUE)
      #read rasters 
      rstPres <- terra::rast(flePres)
      rstFut <- terra::rast(fleFut)
      emptyRas <- rstPres * 0 + 1
    
    tblPres <- terra::as.data.frame(rstPres, xy = TRUE)
    colnames(tblPres)[3] <- 'prev'
    tblFut <- terra::as.data.frame(rstFut, xy = TRUE)
    colnames(tblFut)[3] <- 'prev'
    
    p.xy <- mutate(tblPres, pixelID = 1:nrow(tblPres)) %>% 
      dplyr::select(pixelID, x, y, prev)
    f.xy <- mutate(tblFut, pixelID = 1:nrow(tblFut)) %>% 
      dplyr::select(pixelID, x, y, prev)
    #Calculate backward biotic velocity
    p.xy2 <- filter(p.xy, prev > 0.1) %>% dplyr::select(1:3) %>% as.matrix()
    f.xy2 <- filter(f.xy, prev > 0.1) %>% dplyr::select(1:3) %>% as.matrix()
    
    if (nrow(f.xy) > 0) {
      d.ann <- as.data.frame(yaImpute::ann(
        as.matrix(p.xy2[, -1, drop = FALSE]), 
        as.matrix(f.xy2[, -1, drop = FALSE]), 
        k = 1,
        verbose = F)$knnIndexDist)
      d1b <- as.data.frame(cbind(f.xy2, round(sqrt(d.ann[, 2]))))
      names(d1b) <- c("ID", "X", "Y", "bvel")
    } else {
      print(spec[i])
    }
    f.xy <- as.data.frame(f.xy)
    colnames(f.xy) <- c('ID', 'X', 'Y', 'Pres')
    f.xy <- as_tibble(f.xy)
    d1b <- left_join(f.xy, d1b, by = c('ID', 'X', 'Y'))
    #create a raster
    velRas <- rast(d1b[, c(2,3,5)]) 
    #assign extend and projection
    velref <-  extend(velRas, rstPres, snap = 'near')
    crs(velref)<- crs(rstPres)
    #save the backward velocity calculation into a raster
    out <- glue('./outputs/velocity/treeVelRas/')
    ifelse(!file.exists(out), dir_create(out), print('Already exists'))
    terra::writeRaster(velref, glue('{out}/{sp}_{baseline}_backwardVel{ssp[k]}{yrs[i]}.tif'),
                       filetype = 'GTiff', datatype = 'INT4U',  
                       overwrite = TRUE)
    # Creates refugia index 
    d1b <- mutate(d1b, fat = fattail(bvel, 8333.3335, 0.5)) 
    sppref <- rast(d1b[, c(2, 3, 6)])
    #sppref[is.na(sppref)] <- 0
    sppref <-  extend(sppref, rstPres, snap = 'near')
    crs(sppref)<- crs(rstPres)
    refstack <- sppref
    futprevstack <- rstFut
    
    message(crayon::yellow('Done ', flsFut, '\n'))
    return(list(futprevstack, refstack))
   })
    
    # Getting the Future rasters
    ftr.stk <- map(1:length(rs), function(h) rs[[h]][[2]])
    ftr.stk <- rast(ftr.stk)
    ftr.stk <- ftr.stk * 100  ## multiply the values for 100 to reduce file size. 
    names(ftr.stk) <- glue('{sp}_refugia_{baseline}_{ssp[k]}{yrs}')
    
    # Write these rasters
    out <- glue('./outputs/velocity/tree_spp2/')
    ifelse(!file.exists(out), dir_create(out), print('Already exists'))
    terra::writeRaster(ftr.stk, glue('{out}/backward_{names(ftr.stk)}.tif'),
                       filetype = 'GTiff', datatype = 'INT4U',  
                       overwrite = TRUE)
    
    message(crayon::magenta('Finish!\n'))
})
}

# Apply the function velocity ---------------------------------------------
map(species,baseline = 'p1991', get_backward_velocity)


# Upload to Drive----------------------------------------------------------
outputFolder <- './outputs/velocity/tree_spp2/'
googleFolderID <- 'https://drive.google.com/drive/folders/1ajNkZ49wZVqSc80OBi1oiKQs3JtTq-BD' #Trees

fl <- list.files(outputFolder, full.names = TRUE)
lapply(X = fl, FUN = drive_upload, path = as_id(googleFolderID))
