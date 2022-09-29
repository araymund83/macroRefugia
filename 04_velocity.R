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
species <- basename(dirsFut)
ext <- c(-5546387, 5722613, -2914819, 5915181) 


# Velocity metric ---------------------------------------------------------
get_velocity <- function(sp){
# sp <- species[1] # use for testing
  message(crayon::blue('Starting with:', sp, '\n'))
  flsFut <- grep(sp, dirsFut, value = TRUE)
  dirPres <- grep(sp, dirsPres, value = TRUE)
  flsFut <- dir_ls(flsFut)
  rcp <- c('_45_', '_85_')
  gcms <- c('CCSM4', 'GFDLCM3', 'INMCM4')
  yrs <- c('2025','2055', '2085')
 
  rsltdo <- map(.x = 1:length(rcp), function(k){
    message(crayon::blue('Applying to rcp', rcp[k] ,'\n'))
    flsFut <- grep(rcp[k], flsFut, value = TRUE)
  
    rs <- map(.x = 1:length(yrs), .f = function(i){
      message(crayon::blue('Applying to year',yrs[i], '\n'))
      flsPres <- dir_ls(dirPres)
      
      cat(flsPres, '\n')
      flsPres <- grep('range_masked.tif', flsPres, value = TRUE)
      flesFut <- grep(yrs[i], flsFut, value = TRUE)
      flesFut <- grep(rcp[k], flesFut, value = TRUE)
     
       vel <- map(.x = 1:length(gcms), .f = function(j){
        message(crayon::blue('Applying to gcm',gcms[j], '\n'))
        fleFut <- grep(gcms[j], flesFut, value = TRUE)
        rstPres <- terra::rast(flsPres)
        rstFut <- terra::rast(fleFut)
        emptyRas <- rstPres * 0 + 1
        ext <- c(-5546387, 5722613, -2914819, 5915181)
        terra::ext(emptyRas) <- ext
        
        tblPres <- terra::as.data.frame(rstPres, xy = TRUE)
        colnames(tblPres)[3] <- 'prev'
        tblFut <- terra::as.data.frame(rstFut, xy = TRUE)
        colnames(tblFut)[3] <-  'prev'
        
        p.xy <- mutate(tblPres, pixelID = 1:nrow(tblPres)) %>%
          dplyr::select(pixelID, x, y, prev)
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
        d1b <- mutate(d1b, fat = fattail(bvel, 8333.3335, 0.5))
        sppref <- rast(d1b[, c(2, 3, 6)])
        sppref[is.na(sppref)] <- 0
        crs(sppref) <- crs(emptyRas)
        refstack <- sppref
        # rstFut <- crop(rstFut,emptyRas)
        futprevstack <- rstFut 
       return(list(refstack, futprevstack))
      })
  # Getting the Refugia rasters
    ftr.stk <- map(1:length(vel), function(h) vel[[h]][[1]])
    names (ftr.stk) <- gcms
    ftr.stk <- rast(ftr.stk)
  # average among GCMs
    ftr.mean <- app(ftr.stk, fun=mean, na.rm=TRUE)
    ftr.mean <- ftr.mean * 100  ## multiply the values for 100 to reduce file size.
    names(ftr.mean) <- glue('y{yrs[i]}')
    #ext(ftr.mean) <- ext
   
  ## obtain mean for the reference stack
    # ref.stk <- map(1:length(vel), function(h) vel[[h]][[2]])
    # ref.stk <- rast(ref.stk)
    # ref.mean <- app(ref.stk, fun = mean, na.rm = TRUE)
    # Write these rasters
    out <- glue('./outputs/velocity/subtropical')
    ifelse(!file.exists(out), dir_create(out), print('Already exists'))
    terra::writeRaster(ftr.mean, glue('{out}/{sp}_refugia{rcp[k]}{yrs[i]}.tif'),
                       filetype = 'GTiff', datatype = 'INT4U',  overwrite = TRUE)
    
     cat('Finish!\n')  
  
  cat('Done ', flsFut[i], '\n')
  
cat('Finish!\n')  
  })
    })
}
   
  
# Apply the function velocity ---------------------------------------------
map(species,get_velocity)
map(species[1:12],get_velocity)
map(species[14:15],get_velocity)
map(species[17:35],get_velocity)

# plot 3 graphs on the same window
par(mfrow = c(1, 2))
par(mfrow = c(1, 1))


