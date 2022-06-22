# Load libraries ----------------------------------------------------------
library(pacman)
pacman::p_load(dplyr, fs, fst, gdata, glue, googledrive, quantreg, rasterVis, reproducible,
               stringr,tidyverse, terra, yaImpute)
g <- gc(reset = TRUE)
rm(list = ls())

# Functions ---------------------------------------------------------------

source('./R/fatTail.R')
# Load data ---------------------------------------------------------------
pathFut <- 'inputs/rare_species/Vascular' # mammals
dirsFut <- fs::dir_ls(pathFut, type = 'directory')

# filesFut <- list.files('./inputs/rare_species/Reptiles', 
#                        pattern = '.*asc', full.names = TRUE)
filesPres <- list.files('./inputs/rare_species/pres_Vascular',
                        pattern = '*_thresholded.asc',
                        full.names = TRUE)
species <- basename(filesPres)
species <-  str_sub(species, end = -17)
# CRS for rare Species_Jessica 
CRS <- '+proj=laea +lat_0=45 +lon_0=-100 +x_0=0 +y_0=0 +ellps=WGS84 +units=m +no_defs ' 

# Velocity metric ---------------------------------------------------------
get_velocity <- function(sp){
  #sp <- species[25] # use for testing
  message(crayon::blue('Starting with:', sp, '\n'))
  flsPres <- grep(sp, filesPres, value = TRUE)
  yrs <- c('2050','2080')
  
  rsltdo <- map(.x = 1:length(yrs), function(k){
    message(crayon::blue('Applying to yr', k ,'\n'))
    flsFut <- grep(yrs[k], dirsFut, value = TRUE)
    flsPres <- grep('thresholded.asc', flsPres, value = TRUE)
    fleFut <- list.files(flsFut,pattern = glue('{sp}.*asc'), full.names = TRUE)
    rstPres <- terra::rast(flsPres)
    crs(rstPres) <- CRS
    rstFut <- terra::rast(fleFut)
    crs(rstFut) <- CRS
    emptyRas <- rstPres * 0 + 1 
    
    
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
    crs(sppref) <- crs(emptyRas)
    sppref <- crop(sppref, emptyRas)
    refstack <- sppref
    
    #rstFut <- crop(rstFut,emptyRas)
    futprevstack <- rstFut
    
    cat('Done ', flsFut, '\n')
    return(list(futprevstack, refstack))
  })
    
    # Getting the Future rasters
    ftr.stk <- map(1:length(rsltdo), function(h) rsltdo[[h]][[1]])
    ftr.stk <- map(1:length(ftr.stk), function(h) mean(ftr.stk[[h]]))
    
    ftr.stk <- rast(ftr.stk)
    names(ftr.stk) <- glue('y{yrs}')
    fut.stk <- ftr.stk * 100  ## multipy the values for 100 to reduce file size. 
  
    ## obtain mean for the reference stack
    ref.stk <- map(1:length(rsltdo), function(h) rsltdo[[h]][[2]])
    
    ## check that all rasters match
    message(crayon::green('Checking that extents match'))
    if(ext(ref.stk[[1]]) != ext(ref.stk[[2]])){
      warning(glue('ext of rasters do not match, need to resample'))
    
    #if(ext(ref.stk[[1]]) != ext(ref.stk[[2]]) || ext(ref.stk[[1]] != ref.stk[[3]])){
    ref.stk[[1]]<- resample(ref.stk[[1]], ref.stk[[2]], method = 'bilinear')
    ref.stk[[2]]<- resample(ref.stk[[2]], ref.stk[[1]], method = 'bilinear')
   }
    compareGeom(ref.stk[[1]], ref.stk[[2]])
    
    ref.stk <- rast(ref.stk)
    
    names(ref.stk) <- glue('y{yrs}')
    ref.stk <- ref.stk * 100
    
    
    # Write these rasters
    out <- glue('./outputs/velocity/rare_species/Vascular/')
    ifelse(!file.exists(out), dir_create(out), print('Already exists'))
    terra::writeRaster(ftr.stk, glue('{out}/{sp}_futprev_{names(ftr.stk)}.tif'),
                       filetype = 'GTiff', datatype = 'INTU2U',  overwrite = TRUE,
                       gdal = c('COMPRESS=ZIP'))
    
    terra::writeRaster(ref.stk, glue('{out}/{sp}_ refugia_{names(ref.stk)}.tif'), 
                       filetype = 'GTiff',datatype = 'INTU2U', overwrite = TRUE,
                       gdal = c('COMPRESS = ZIP'))
    
    
    cat('Finish!\n')
}

# Apply the function velocity ---------------------------------------------
map(species[363:397],get_velocity)


# Upload to Drive----------------------------------------------------------
outputFolder <- './outputs/velocity/rare_species/Vascular'
googleFolderID <- 'https://drive.google.com/drive/folders/1VIif-rfgyplbN-u3whlpnigbzhCteNFq' #Vascular
  #'https://drive.google.com/drive/folders/1a2l2d-FNP2Fh-IYDdtKgbptsgG7xcHKY' #Invertebrates
  #'https://drive.google.com/drive/folders/1_16pLDhAE129Hi3H-O-h3AVHyh0-V_j9' #Reptiles
  #'https://drive.google.com/drive/folders/1NQd-GxSVzwWUXQbvHes_eM9MYoZAOD3-' #mammals

fl <- list.files(outputFolder, full.names = TRUE)
lapply(X = fl, FUN = drive_upload, path = as_id(googleFolderID))
