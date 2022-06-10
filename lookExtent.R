pathFut <- 'inputs/western_for'
pathPres <- 'inputs/pres_western'
dirsFut <- fs::dir_ls(pathFut, type = 'directory')
dirsPres <- fs::dir_ls(pathPres, type = 'directory')
#list the files within each directory 
filesFut <- list.files(dirsFut, full.names = TRUE)
filesPres <- list.files(dirsPres, full.names = TRUE)
##read the rasters 
filesFut <-  terra::rast(filesFut)
filesPres <- terra::rast(filesPres)

##get the extent for all rasters (creates an object class SpatExt)
rast_extPres<- lapply(filesPres, terra::ext)
rast_extFut<- lapply(filesFut, terra::ext)

##transform to a list of vectors 
find_extent<- function(raster){
  extList<- as.vector(terra::ext(raster))
}
##apply the function find_extent to each list of rasters 
futRast_ext <- lapply(X = rast_extFut, FUN = find_extent)
presRast_ext <- lapply(X= rast_extPres, FUN = find_extent)

##create a data frame with the extents and find if they are all equal
futRast_extDF<- bind_rows(lapply(futRast_ext, as.data.frame.list))
presRast_extDF<- bind_rows(lapply(presRast_ext, as.data.frame.list))

