require(pacman)
pacman::p_load('glue', 'googledrive', 'purrr', 'reproducible', 'tidyverse')


#download boreal bird species
birdList <- c('COMI', 'YFGU')
birdList <- c('COMI', 'YFGU', 'COGD', 'LBWO', 'BANO', 'WWDO',
              'EUCD', 'HOSP', 'INDO', 'WTDO', 'ROPI', 'VERD',
              'CACW', 'CONI', 'NOCA', 'CARW', 'GTGR', 'MAFR',
              'GBAN', 'GRRO', 'BCTI')

birdList <- c("ALFL", "AMRE", "ATTW", "BBWA", "BBWO", "BCCH", "BLBW", "BLPW",
             "BOCH", "BOOW", "BOWA", "CAJA", "CAWA", "CMWA", "CONW", "EVGR", 
             "FOSP", "GCKI", "GCSP", "GCTH", "GGOW", "HASP", "LEFL", "LISP", 
             "MAWA", "MOWA", "NHOW", "NOGO", "NOWA", "NSHR", "NSWO", "OSFL", 
             "PAWA", "PHVI", "PIGR", "PUFI", "RBNU", "RECR", "RUBL", "RUGR",
             "SPGR", "SWTH", "TEWA", "WTSP", "WWCR", "YBFL", "YEWA", "YRWA")




##download audobon models for boreal forest birds
folderUrl = 'https://drive.google.com/drive/folders/11dEkSmKs1oIpdbChR_2bUYFIE0gyaixX'



folderID  <- drive_get(as_id(folderUrl))


ras <- downloadRasters (folderUrl = folderUrl,
                        rastersPath = paths$inputPath,
                        group = 'boreal_forest', # options are:artic,aridlands, coastal etc...
                        type = '_breeding_', #options are: breeding, resident, two-season
                        birdsList = birdList)


currentUrl <-'https://drive.google.com/drive/folders/1ETLVsiQtn0NZK0ppVKGV8Vlwu2gVkfx1'