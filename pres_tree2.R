# Load libraries ----------------------------------------------------------
library(pacman)
pacman::p_load(dplyr, fs, fst, gdata, glue, rasterVis, stringr,tidyverse, terra)
g <- gc(reset = TRUE)
rm(list = ls())

speciesList <- c('ABIEAMA', 'ACERRUB', 'ACERSAC', 'BETUALL', 'FAGUGRA', 'LARILAR', 
                 'PICEENE', 'PICEGLA', 'PICEMAR', 'PICERUB', 'PINUBAN', 'PINURES', 
                 'PINUSTR', 'POPUTRE', 'THUJOCC')
# Load data  --------------------------------------------------------------
root <- './inputs/tree_spp/tree_fut2'
dirs <- fs::dir_ls(root, type = 'directory') # reads directories 
dirs <- as.character(dirs)
species <- basename(dirs) # gets the species codes
#thr <- 0.3 #from Zhao et al 2023 https://doi.org/10.1016/j.ecolind.2023.110072
thrs <- read_csv('./inputs/tree_spp/treeCutoff.csv')

targetCRS <- '+proj=aea +lat_0=40 +lon_0=-96 +lat_1=20 +lat_2=60 +x_0=0 +y_0=0 +ellps=GRS80 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs'

reclass_Ras <- function(sp){
 #sp <- species[1]
  message(crayon::blue('Starting with:', sp, '\n'))
  
  dir <- grep(sp, dirs, value = TRUE)
  fls <- fs::dir_ls(dir, regexp = '.tif$')
  fls_fut <- grep('cons', fls, value = TRUE)
  thr <- filter(thrs, Code == sp) # filters the table to obtain the cutoff value for each spp.
  val <- unique(thr$CutOffZhao)
  rs <- terra ::rast(fls)
  rs <- terra::project(rs, targetCRS, method = 'near')
  rs[rs < val] <- 0
  rs[rs >= val] <- 1
 # Write the rasters
  out <- glue('./inputs/tree_spp/fut_thresholded2/')
  ifelse(!file.exists(out), dir_create(out), print('Already exists'))
  terra::writeRaster(rs, glue('{out}/{sp}_{names(rs)}_thresholded_proj.tif'),
                     filetype = 'GTiff',  overwrite = TRUE,
                     gdal = c('COMPRESS=ZIP'))
  cat('=====Done========! \n')
      
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

