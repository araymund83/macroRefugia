downloadRas <- function(folderUrl, 
                        birdsList,
                        group = NULL,
                        type = NULL,
                        rastersPath) {
  browser()
  
  ## drive_ls function is used to list all the files it finds using the folder url with the given pattern
  files <- googledrive::drive_ls(path = as_id(folderUrl),# it only needs the last bit of the https address. 
                                 pattern = group)
  files2 <- as_tibble(files)
  
  pattern <- c('.*range_masked', paste(birdList,collapse = '|'))

  rastersForBirdList <- files2 %>% filter(stringr::str_detect(name,pattern))

  if (length(rastersForBirdList) == 0){
    message(crayon::red(paste0("No prediction available for ", birdsList, 
                               "for group :", group)))
    return(NA)
  }
  # rastersPath <- glue 
  # do <- glue('{dout}/{spc}')
  # ifelse(!dir.exists(do), dircreate(do), print('Folder already exists'))
  
  ## for each item in turn from rastersForBirdlist the following function is applied:
  downloadedRasters <-
    lapply( X = rastersForBirdList, FUN = function(rasterFile) {
      browser()
      ## if the item in rastersForBirdList is not already present at rastersPath, googledrive package downloads it
      if (!file.exists(file.path(rastersPath, rasterFile))) {
        googledrive::drive_download(
          file = googledrive::as_id(rastersForBirdList[rastersForBirdList$name %in% rasterFile,]$id),
          path = file.path(rastersPath, rasterFile),
          overwrite = TRUE
        )
      }
      
      ## otherwise, if it is already present and downloaded, just get the name of the item
      return(raster(file.path(rastersPath, rasterFile), verbose = TRUE))
    }
    )
  names(downloadedRasters) <- birdList
  return(downloadedRasters)
}
