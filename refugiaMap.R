# Load data ---------------------------------------------------------------
root <- './outputs/velocity'
dirs <- fs::dir_ls(root, type = 'directory')
spcs <- basename(dirs)

# Function to use ---------------------------------------------------------
make_stack <- function(spc){
  
  spc <- spcs[2] # Run and erase
  
  cat('Start ', spc, '\n')
  dir <- grep(spc, dirs, value = TRUE)
  fls <- fs::dir_ls(dir, directory = '.tif$')
  fls <- grep('velocity', fls, value = TRUE)
  
  cat('To get the name of each rcp\n')
  rcp <- parse_number(basename(fls))
  rcp <- unique(rcp)

  cat('To apply to each rcp\n')
  rsl <- map(.x = 1:length(rcp), function(i){
    
   cat(rcp[i], '\n')
      rs <- terra::rast(fls)
      df <- terra::as.data.frame(x = rs, xy= TRUE)
      df <- as_tibble(df)
      colnames(df) <- c('lon', 'lat', 'ref45', 'ref85')
      dfLong <- df %>% pivot_longer(! c(lon, lat),names_to = 'rcp', values_to = 'val' )
      
      ref_map <- ggplot() +
        geom_tile(data = dfLong, aes (x = lon, y = lat, fill = val)) +
        facet_wrap(.~rcp) +
        #ggtitle(label = spc) +
        #theme_ipsum_es() +
        theme_bw() +
        theme(legend.position = 'bottom',
              legend.key.width = unit(2, 'line'),## aumenta la longitud de la leyenda
              axis.text.y = element_text(angle = 90, vjust = 0.5)) +
        labs(x = 'Longitude', y = 'Latitude')
      
      ggsave(plot = ref_map,filename = glue('./outputs/figs/refugia{spc}.png'),
             units = 'in', width = 12, height = 9, dpi = 700)
  

      
          