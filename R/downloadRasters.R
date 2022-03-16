downloadRasters <- function(folderUrl, 
                        birdsList,
                        group = NULL,
                        type = NULL,
                        rastersPath) {
  
  
  ## drive_ls function is used to list all the files it finds using the folder url with the given pattern
  files <- googledrive::drive_ls(path = as_id(folderUrl),# it only needs the last bit of the https address. 
                                 pattern = group)
  
  files2 <- as_tibble(files)
  filesToDownload <- files2[grep('_breeding_', files2$name, value = FALSE),]
  filesToDownload <- filesToDownload[grep('range_masked.tif$', 
                                          filesToDownload$name, value = FALSE),]
  filesToDownload <- filesToDownload[grep(paste0(birdList, collapse = '|'),
                                          filesToDownload$name, value = FALSE),]
  
  tst <- filesToDownload %>% 
              separate(data = ., col = name, 
                       into = c('type', 'frst', 'spc', 'v1', 'v2', 'yr', 'y2', 'gcm', 'rng', 'msk'),
                       sep = '_')
  browser()
  downloadRas <- function(sp){
    #sp <- birdList[2]
    subdir <- glue('{path}/{sp}')
    ifelse(!dir.exists(subdir), fs::dir_create(subdir), print('Folder already exists'))
    tst2 <-tst %>% filter(., spc == sp)
    tst2 <- tst2 %>% 
      mutate(name = glue('{type}_{frst}_{spc}_{v1}_{v2}_{yr}_{y2}_{gcm}_{rng}_{msk}'), 
             name = as.character(name))
    message(crayon::blue(glue('Downloading rasters for {sp}')))
    tst2 %>% 
      split(tst2$id) %>% 
      walk(~drive_download(.$id, path = file.path(subdir, .$name), overwrite = TRUE))
    message(crayon::blue('Done!'))
  }
  map(.x = birdList, .f = downloadRas)
}


