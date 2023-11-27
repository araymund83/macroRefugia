# Load libraries ----------------------------------------------------------
library(pacman)
pacman::p_load(dplyr, fs, fst, gdata, glue, rasterVis, stringr,tidyverse, terra)
g <- gc(reset = TRUE)
rm(list = ls())

speciesList <- c('ABIEAMA', 'ABIEGRA', 'ABIELAS', 'ACERRUB', 'ACERSAC', 'ALNURUB',
                 'BETUALL', 'FAGUGRA', 'LARILAR', 'PICEENG', 'PICEGLA', 'PICEMAR',
                 'PICERUB', 'PICESIT', 'PINUBAN', 'PINUCON', 'PINURES', 'PINUSTR',
                 'POPUBAL', 'POPUTRE', 'PSEUMEN', 'THUJOCC', 'THUJPLI', 'TSUGHET')
# Load data  --------------------------------------------------------------
pathPres <- './inputs/tree_spp/pres_trees'
pathFut <- './inputs/tree_spp/tree_fut'
thrs <- read_csv('./inputs/tree_spp/treeCutoff.csv')
filesPres <- list.files(pathPres, pattern = '.tif$', full.names = TRUE)
filesFut <- list.files(pathFut, pattern = '.tif$', full.names = TRUE)

species <- speciesList

reclass_Ras <- function(sp){
  #sp <- species[1]
  message(crayon::blue('Starting with:', sp, '\n'))
  rcp <- c('_rcp45_', '_rcp85_')
  yrs <- c('2025', '2055', '2085')
  targetCRS <- '+proj=aea +lat_0=40 +lon_0=-96 +lat_1=20 +lat_2=60 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'
  
  reclass <- map(.x = 1:length(rcp), function(k){
    message(crayon::blue('Starting with:', rcp[k], '\n'))
    flsFut<- grep(sp, filesFut, value = TRUE)
    flsFut <- grep(rcp[k], flsFut, value = TRUE)
    flsPres <- grep(sp, filesPres, value = TRUE)
    
    year <- map(.x = 1:length(yrs), .f = function(i){
      message(crayon::blue('Applying to year', yrs[i], '\n'))
      fl <- grep(yrs[i], flsFut, value = TRUE)
      thr <- filter(thrs, Code == sp)
      val <- unique(thr$CutOff)
      rs <- terra ::rast(fl)
      rs <- terra::project(rs, targetCRS, method = 'near')
      rs[rs < val] <- 0
      rs[rs >= val] <- 1
      # Write the rasters
      out <- glue('./inputs/tree_spp/future_thresholded/')
      ifelse(!file.exists(out), dir_create(out), print('Already exists'))
      terra::writeRaster(rs, glue('{out}/{sp}_{rcp[k]}_{yrs[i]}_tresholded_proj.tif'),
                         filetype = 'GTiff', datatype = 'INTU2U',  overwrite = TRUE,
                         gdal = c('COMPRESS=ZIP'))
      cat('=====Done========! \n')
      
    })
  })
}

# Apply the function ------------------------------------------------------
reclass<- map(.x = species, reclass_Ras)



# filesPres<-lapply(filesPres, raster::raster)
# filesPresTerra<-lapply(filesPres, terra::rast)
# stack <- c(filesPresTerra)
# meanTest <- lapply(c(filesPresTerra), globals())
# 
# meanPresTerra <- global(filesPresTerra[[1]], fun = 'mean', na.rm = TRUE)
# #calculates the mean of a list of spatRasters 
# meanPresTerra <- sapply(filesPresTerra, function(x){
#   terra::global(x= x, fun = 'mean', na.rm = TRUE)
# })
#  s <- sapp(filesPresTerra, fun = function(x, ...){global(x, fun = 'mean', na.rm = TRUE)})
# 
#  
 
 

