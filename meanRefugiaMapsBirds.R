library(pacman)
pacman::p_load(ggplot2, glue, googledrive, qs, RColorBrewer,terra, sf, 
               tidyterra, tidyverse)

g <- gc(reset = TRUE)
rm(list = ls())


# Load data ----------------------------
group <- 'waterbirds' #'aridlands','arctic', 'boreal' 'coastal', 'eastern', 'generalist', 'grasslands', 'marshlands', 'subtropical'
#'urban', 'waterbirds','western'
path <-  glue('./outputs/velocity/{group}')
files <- list.files(path, pattern = '.tif')
species <- basename(files)
species <-  str_sub(species,  start = 1, end = 4)
species <- unique(species)
#species<- c("BRSP", "ABTO")
rcp <- c('45', '85')
labs <- c('RCP-4.5', 'RCP-8.5')
yrs <- c('2025', '2055', '2085')
#limt <- terra::vect('./inputs/boundaries/AlaskaCA.shp')
limt <- terra::vect('./inputs/boundaries/usCanada/us_canada.shp')


makeMeanMap <- function(sp, rcp){
  #sp <- species[1]
  files <- list.files(path, full.names = TRUE)
  message(crayon::blue('Creating table for species', sp,'\n'))
  fls <- grep(sp, files, value = TRUE)
  
  meanMap <- map(.x = 1:length(rcp), function(k){

    message(crayon::blue('Applying to', rcp[k] ,'\n'))
    sp_fls <- grep(rcp[k], fls, value = TRUE)
  #  sp_fls <- grep(baseline, sp_fls, value = TRUE)
    
    #read rasters 
    rst1 <- rast(sp_fls[1])
    rst2 <- rast(sp_fls[2])
    rst3 <- rast(sp_fls[3])
    #browser()
    
    #Resample rst2 and rst3 to match the extent and resolution of the first raster.
    # Resample rst2 and rst3 to match the extent and resolution of rst1
    rst2_resampled <- resample(rst2, rst1)
    rst3_resampled <- resample(rst3, rst1)
    
    rst_stack <- c(rst1, rst2_resampled, rst3_resampled)
 
    #Convert the raster stack to integer format
    rst_stack_int <- clamp(round(rst_stack), 0, 100)
    # Reproject the shapefile to match the CRS of the raster stack
    limt_proj <- terra::project(limt, crs(rst_stack_int))
    
    # Use the reprojected shapefile in the mask function
    rst_stack <- terra::mask(rst_stack_int, limt_proj)
   
     # Determine the min and max values of the raster stack
    rst_min <- min(values(rst_stack_int), na.rm = TRUE)
    rst_max <- max(values(rst_stack_int), na.rm = TRUE)
    
    # Get the extent of the raster stack
    extent_vals <- terra::ext(rst_stack_int)
    xlim_vals <- c(extent_vals$xmin, extent_vals$xmax)
    ylim_vals <- c(extent_vals$ymin, extent_vals$ymax)
    
    colors <- c('#f5f5f5', '#ffffa6', '#a1dab4', '#41b6c4','#2c7fb8','#253494')
    
    names(rst_stack) <- yrs
  
    ##make ggplot
    meanSpMap<- ggplot() +
      geom_spatraster(data = rst_stack) +
      facet_wrap(~lyr, ncol = 3) +
      # scale_fill_gradientn(colours = brewer.pal(n = 5, name = 'Set2'), 
      #                      limits = c(rst_min, rst_max),
      #                      na.value = NA) +
      scale_fill_gradientn(colours = colors, 
                           limits = c(rst_min, rst_max),
                           na.value = NA) +
      geom_spatvector(data = limt, fill = '#E6E6E6', color = 'black', alpha = 0.5) +
       theme_bw() + 
      theme(legend.position = 'bottom',legend.key.width = unit(2, 'line'),
            plot.title = element_text(size = 12, face = 'bold', hjust = 0, vjust = 0.7),
            plot.subtitle = element_text(size = 11),
            axis.title = element_text(size = 10),
            axis.text.x = element_text(size = 10),
            axis.text.y = element_text(size = 10),
            legend.text = element_text(size = 10),
            legend.title = element_text(size = 10, face = 'bold'),
            panel.grid = element_blank(),
            strip.text = element_text(size = 12,face = 'bold')) +
       labs(x = 'Longitude', y = 'Latitude', fill = 'Refugia',
           title = glue('Mean refugia index {sp}'),
            subtitle = labs[k]) 

 #browser()
  #  meanSpMap <- meanSpMap +  coord_sf(xlim = c(-2500000, 1500000), 
   #                                    ylim = c(-800000, 2200000),
    #                                   expand = FALSE)  
    meanSpMap <- meanSpMap +  coord_sf(xlim = xlim_vals,
                                       ylim = ylim_vals,
                                       expand = FALSE)  
    
    out <- glue('./maps/birds/{group}')
    ifelse(!file.exists(out), dir.create(out), print('Already exists'))
    
    ggsave(plot = meanSpMap, filename = glue('{out}/Meanrefugia_{sp}_{rcp[k]}.png'), 
           units = 'in', width = 14, height = 5, dpi = 300)
  })
  message(crayon::green('Done!'))
}

# Apply the function ------------------------------------------------------

dfrm <- map(.x = species[7:46], rcp = rcp, .f = makeMeanMap)


# Upload to Drive----------------------------------------------------------
outputFolder <- './maps/trees2/meanRefugia'
googleFolderID <- 'https://drive.google.com/drive/folders/11T9ljiwZ8uV1112XB4m4YAUMsGE11k5T' #meanRefugia

fl <- list.files(outputFolder, full.names = TRUE)
lapply(X = fl, FUN = drive_upload, path = as_id(googleFolderID))

