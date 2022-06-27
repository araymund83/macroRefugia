# Load libraries ----------------------------------------------------------
library(pacman)
pacman::p_load(dplyr, fs, fst, gdata, glue, googledrive, quantreg, rasterVis, reproducible,
               stringr,tidyverse, terra, yaImpute)
g <- gc(reset = TRUE)
rm(list = ls())

# Functions ---------------------------------------------------------------
source('./R/fatTail.R')

# Load data ---------------------------------------------------------------
filesFut <- list.files('./inputs/tree_spp/future_thresholded', 
                      pattern = '.tif', full.names = TRUE)

filesPres <- list.files('./inputs/tree_spp/pres_thresholded',
                        full.names = TRUE)
species <- basename(filesPres)
species <-  str_sub(species, end = -31)

# Velocity metric ---------------------------------------------------------
get_velocity <- function(sp){
  #sp <- species[1] # use for testing
  message(crayon::blue('Starting with:', sp, '\n'))
  flsPres <- grep(sp, filesPres, value = TRUE)
  flsFut <- grep(sp, filesFut, value = TRUE)
  rcp <- c('_rcp45_', '_rcp85_')
  yrs <- c('2025', '2055', '2085')
  
  rsltdo <- map(.x = 1:length(rcp), function(k){
    message(crayon::blue('Applying to rcp', rcp[k] ,'\n'))
    flsFut <- grep(rcp[k], flsFut, value = TRUE)
    
    rs <- map(.x = 1:length(yrs), function(i){
      message(crayon::blue('Applying to year',yrs[i], '\n'))
      flePres <- grep('baseline', flsPres, value = TRUE)
      fleFut <- grep(yrs[i], flsFut, value = TRUE)
      
      rstPres <- terra::rast(flePres)
      rstFut <- terra::rast(fleFut)
      emptyRas <- rstPres * 0 +1
      
     
    tblPres <- terra::as.data.frame(rstPres, xy = TRUE)
    colnames(tblPres)[3] <- 'prev'
    tblFut <- terra::as.data.frame(rstFut, xy = TRUE)
    colnames(tblFut)[3] <- 'prev'
    
    p.xy <-
      mutate(tblPres, pixelID = 1:nrow(tblPres)) %>% dplyr::select(pixelID, x, y, prev)
    f.xy <-
      mutate(tblFut, pixelID = 1:nrow(tblFut)) %>% dplyr::select(pixelID, x, y, prev)
    
    p.xy2 <-
      filter(p.xy, prev > 0.1) %>% dplyr::select(1:3) %>% as.matrix()
    f.xy2 <-
      filter(f.xy, prev > 0.1) %>% dplyr::select(1:3) %>% as.matrix()
    
    if (nrow(f.xy) > 0) {
      d.ann <- as.data.frame(ann(
        as.matrix(p.xy2[, -1, drop = FALSE]),
        as.matrix(f.xy2[, -1, drop = FALSE]),
        k = 1,
        verbose = F
      )$knnIndexDist)
      d1b <- as.data.frame(cbind(f.xy2, round(sqrt(d.ann[, 2]))))
      names(d1b) <- c("ID", "X", "Y", "bvel")
    } else {
      print(spec[i])
    }
    f.xy <- as.data.frame(f.xy)
    colnames(f.xy) <- c('ID', 'X', 'Y', 'Pres')
    f.xy <- as_tibble(f.xy)
    d1b <- left_join(f.xy, d1b, by = c('ID', 'X', 'Y'))
    d1b <- mutate(d1b, fat = fattail(bvel, 8333.3335, 0.5))
    sppref <- rast(d1b[, c(2, 3, 6)])
    sppref[is.na(sppref)] <- 0
    crs(sppref)<- crs(rstPres)
    ext(sppref)<- ext(rstPres)
    sppref <- crop(sppref, emptyRas)
    refstack <- sppref
    
    #rstFut <- crop(rstFut,emptyRas)
    futprevstack <- rstFut
    
    message(crayon::yellow('Done ', flsFut, '\n'))
    return(list(futprevstack, refstack))
   })
    
    # Getting the Future rasters
    ftr.stk <- map(1:length(rs), function(h) rs[[h]][[2]])
    ftr.stk <- rast(ftr.stk)
    ftr.stk <- ftr.stk * 100  ## multiply the values for 100 to reduce file size. 
    names(ftr.stk) <- glue('{sp}_refugia_{rcp[k]}{yrs}')
    
    # Write these rasters
    out <- glue('./outputs/velocity/tree_spp/')
    ifelse(!file.exists(out), dir_create(out), print('Already exists'))
    terra::writeRaster(ftr.stk, glue('{out}/{names(ftr.stk)}.tif'),
                       filetype = 'GTiff', datatype = 'INTU2U',  overwrite = TRUE,
                       gdal = c('COMPRESS=ZIP'))
    
    message(crayon::magenta('Finish!\n'))
})
}

# Apply the function velocity ---------------------------------------------
map(species,get_velocity)


# Upload to Drive----------------------------------------------------------
outputFolder <- './outputs/velocity/tree_spp/'
googleFolderID <- 'https://drive.google.com/drive/folders/1eYew9QYEZp6IRf7EYeMByQfP-pQsx7w_' #Trees

fl <- list.files(outputFolder, full.names = TRUE)
lapply(X = fl, FUN = drive_upload, path = as_id(googleFolderID))
