# Load libraries ----------------------------------------------------------
library(pacman)
pacman::p_load(dplyr, fs, fst, gdata, glue, quantreg, rasterVis, reproducible,
               stringr,tidyverse, terra )


# Load data ---------------------------------------------------------------

pathPred <- 'inputs/pr'
dirs <- fs::dir_ls(path, type = 'directory')
species <- basename(dirs)

# Velocity metric ---------------------------------------------------------
get_velocity <- function(sp){
  sp <- species[1]
  fls <- fs::dir_ls(sp)
  yrs <- parse_number(basename(fls))
  yrs <- unique(yrs)
  yrs <- na.omit(yrs)
  gcm <- str_sub(basename(fls), start = 45, end = nchar(basename(fls)) - 17)
  gcm <- unique(gcm)
  
  
  present <- terra::rast(fl)
  
  
}

