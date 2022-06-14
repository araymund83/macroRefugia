# Load libraries ----------------------------------------------------------
library(pacman)
pacman::p_load(dplyr, fs, fst, gdata, glue, quantreg, rasterVis, reproducible,
               stringr,tidyverse, terra, yaImpute)
g <- gc(reset = TRUE)
rm(list = ls())

# Functions ---------------------------------------------------------------
source('./R/fatTail.R')
# Load data ---------------------------------------------------------------
pathFut <- 'inputs/subtropical_fut'
pathPres <- 'inputs/pres_subtropical'
dirsFut <- fs::dir_ls(pathFut, type = 'directory')
dirsPres <- fs::dir_ls(pathPres, type = 'directory')
gcms <- c('CCSM4', 'GFDLCM3', 'INMCM4')
species <- basename(dirsFut)
ext <- c(-5546387, 5722613, -2914819, 5915181) 

# Velocity metric ---------------------------------------------------------
get_velocity <- function(sp){
 #sp <- species[8] # use for testing
  message(crayon::blue('Starting with:', sp, '\n'))
  flsFut <- grep(sp, dirsFut, value = TRUE)
  dirPres <- grep(sp, dirsPres, value = TRUE)
  flsFut <- dir_ls(flsFut)
  rcp <- c('_45_', '_85_')
  #gcm <- str_sub(basename(flsFut),start = 46, end = nchar(basename(flsFut)) -17) # this will change if the file_name structure changes
  #gcm <- unique(gcm)
  #yrs <- parse_number(basename(flsFut))
  #yrs <- unique(yrs)
  yrs <- c('2025','2055', '2085')
 
  rsltdo <- map(.x = 1:length(rcp), function(k){
    message(crayon::blue('Applying to rcp', k ,'\n'))
    flsFut <- grep(rcp[k], flsFut, value = TRUE)
  
    rs <- map(.x = 1:length(yrs), .f = function(i){
      message(crayon::blue('Applying to year',i, '\n'))
      flsPres <- dir_ls(dirPres)
      
      cat(flsPres, '\n')
      flsPres <- grep('range_masked.tif', flsPres, value = TRUE)
      fleFut <- grep(yrs[i], flsFut, value = TRUE)
      fleFut <- grep(rcp[k], fleFut, value = TRUE)
      
      rstPres <- terra::rast(flsPres)
      rstFut <- terra::rast(fleFut)
      emptyRas <- rstPres * 0 + 1 
      terra::ext(emptyRas) <- ext
    
      tblPres <- terra::as.data.frame(rstPres, xy = TRUE)
      colnames(tblPres)[3] <- 'prev'
      tblFut <- terra::as.data.frame(rstFut, xy = TRUE)
      colnames(tblFut)[3] <- 'prev'
      
      p.xy <- mutate(tblPres, pixelID = 1:nrow(tblPres)) %>% dplyr::select(pixelID, x, y, prev) 
      f.xy <- mutate(tblFut, pixelID = 1:nrow(tblFut)) %>% dplyr::select(pixelID, x, y, prev) 
      
      p.xy2 <-filter(p.xy, prev > 0.1) %>% dplyr::select(1:3) %>% as.matrix()
      f.xy2 <-filter(f.xy, prev > 0.1) %>% dplyr::select(1:3) %>% as.matrix()
      
      if(nrow(f.xy) > 0){
        d.ann <- as.data.frame(ann(
          as.matrix(p.xy2[,-1, drop = FALSE]),
          as.matrix(f.xy2[,-1, drop = FALSE]),
          k = 1, verbose = F)$knnIndexDist)
        d1b <- as.data.frame(cbind(f.xy2, round(sqrt(d.ann[,2]))))
        names(d1b) <- c("ID","X","Y","bvel")
      } else {
        print(spec[i])
      }
      f.xy <- as.data.frame(f.xy)
      colnames(f.xy) <- c('ID', 'X', 'Y', 'Pres')
      f.xy <- as_tibble(f.xy)
      d1b <- left_join(f.xy, d1b, by = c('ID', 'X', 'Y'))
      d1b <- mutate(d1b, fat = fattail(bvel, 8333.3335, 0.5))
      sppref <- rast(d1b[,c(2,3,6)])
      sppref[is.na(sppref)] <- 0
      crs(sppref) <- crs(emptyRas)
      sppref <- crop(sppref, emptyRas)
      refstack <- sppref
      
      #rstFut <- crop(rstFut,emptyRas)
      futprevstack <- rstFut
      
     cat('Done ', flsFut[i], '\n')
      return(list(futprevstack, refstack))
    })

    # Getting the Future rasters
    ftr.stk <- map(1:length(rs), function(h) rs[[h]][[1]])
    ftr.stk <- map(1:length(ftr.stk), function(h) mean(ftr.stk[[h]]))
    
    ftr.stk <- rast(ftr.stk)
    names(ftr.stk) <- glue('y{yrs}')
    fut.stk <- ftr.stk * 100  ## multipy the values for 100 to reduce file size. 
    #TODO: write the metadata 
   
    ## obtain mean for the reference stack
    ref.stk <- map(1:length(rs), function(h) rs[[h]][[2]])
    
    ## check that all rasters match
    message(crayon::green('Checking that extents match'))
   if(ext(ref.stk[[1]]) != ext(ref.stk[[2]]) || ext(ref.stk[[1]])!= ext(ref.stk[[3]])){
   warning(glue('ext of rasters do not match, need to resample'))}
    
    #if(ext(ref.stk[[1]]) != ext(ref.stk[[2]]) || ext(ref.stk[[1]] != ref.stk[[3]])){
     ref.stk[[1]]<- resample(ref.stk[[1]], ref.stk[[2]], method = 'bilinear')
     ref.stk[[3]]<- resample(ref.stk[[3]], ref.stk[[1]], method = 'bilinear')
     ref.stk[[2]] <- resample(ref.stk[[2]], ref.stk[[1]], method = 'bilinear')
     
    compareGeom(ref.stk[[1]], ref.stk[[2]],ref.stk[[3]])
   # }
   # if(!compareGeom(ref.stk[[1]], ref.stk[[3]], crs = TRUE, ext = TRUE,
   #                  rowcol = TRUE)){
   #    #warning(glue('ext of rasters do not match, need to resample'))
   #   ref.stk[[1]]<- resample(ref.stk[[1]], ref.stk[[3]], method = 'bilinear')
   #   }
   # if (!compareGeom(ref.stk[[2]], ref.stk[[3]], crs = TRUE, ext = TRUE,
   #                  rowcol = TRUE)){
   #   # warning(glue('ext of rasters do not match, need to resample'))
   #   ref.stk[[2]] <- resample(ref.stk[[2]], ref.stk[[3]], method = 'bilinear')
   #   }
   #  if(!compareGeom(ref.stk[[3]], ref.stk[[2]], crs = TRUE, ext = TRUE,
   #                  rowcol = TRUE)){
   #    #warning(glue('ext of rasters do not match, need to resample'))
   #    ref.stk[[3]] <- resample(ref.stk[[3]], ref.stk[[2]], method = 'bilinear')
   #    }
   #  if(!compareGeom(ref.stk[[3]], ref.stk[[1]], crs = TRUE, ext = TRUE,
   #                  rowcol = TRUE)){
   #   # warning(glue('ext of rasters do not match, need to resample'))
   #    ref.stk[[3]] <- resample(ref.stk[[3]], ref.stk[[1]], method = 'bilinear')
   #  }
   #  if(!compareGeom(ref.stk[[2]], ref.stk[[3]], crs = TRUE, ext = TRUE,
   #                  rowcol = TRUE)){
   #    #warning(glue('ext of rasters do not match, need to resample'))
   #  ref.stk[[2]] <- resample(ref.stk[[2]], ref.stk[[3]], method = 'bilinear')
   #  }
   
   ## the only way I could solve the extention and dimension problems was by resampling

   # ref.stk <- map(1:length(rs), function(h) crop(ref.stk[[h]], ext(emptyRas))) # is tis not croping to the same extent
    ref.stk <- rast(ref.stk)
  
    names(ref.stk) <- glue('y{yrs}')
    ref.stk <- ref.stk * 100
    ref.stk_mean <- terra::app(ref.stk, fun = 'mean')
    
    # Write these rasters
    out <- glue('./outputs/velocity/subtropical/{sp}')
    ifelse(!file.exists(out), dir_create(out), print('Already exists'))
    terra::writeRaster(ftr.stk, glue('{out}/{sp}_futprev_{rcp[k]}.tif'),
                       filetype = 'GTiff', datatype = 'INTU2U',  overwrite = TRUE,
                       gdal = c('COMPRESS=ZIP'))
    
    terra::writeRaster(ref.stk, glue('{out}/{sp}_ refugia_{rcp[k]}_{names(ref.stk)}.tif'), 
                        filetype = 'GTiff',datatype = 'INTU2U', overwrite = TRUE,
                       gdal = c('COMPRESS = ZIP'))
    
    terra::writeRaster(ref.stk_mean, glue('{out}/{sp}_refugiaMean_{rcp[k]}.tif'),
                       filetype = 'GTiff', datatype = 'INTU2U',overwrite = TRUE,
                       gdal = c('COMPRESS = ZIP'))
    cat('Finish!\n')
    })
     }
   
  
# Apply the function velocity ---------------------------------------------
map(species,get_velocity)
map(species[6:7],get_velocity)
map(species[62],get_velocity)
map(species[81],get_velocity)




# plot 3 graphs on the same window
#par(mfrow = c(1, 3))


