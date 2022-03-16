require(pacman)
pacman::p_load('glue', 'googledrive', 'purrr', 'reproducible', 'tidyverse')


#download boreal bird species
# birdList <- c("ALFL", "AMRE", "ATTW", "BBWA", "BBWO", "BCCH", "BLBW", "BLPW",
#              "BOCH", "BOOW", "BOWA", "CAJA", "CAWA", "CMWA", "CONW", "EVGR", 
#              "FOSP", "GCKI", "GCSP", "GCTH", "GGOW", "HASP", "LEFL", "LISP", 
#              "MAWA", "MOWA", "NHOW", "NOGO", "NOWA", "NSHR", "NSWO", "OSFL", 
#              "PAWA", "PHVI", "PIGR", "PUFI", "RBNU", "RECR", "RUBL", "RUGR",
#              "SPGR", "SWTH", "TEWA", "WTSP", "WWCR", "YBFL", "YEWA", "YRWA")

##download western forest species 
birdList <- c("ACWO", "AMDI", "BHGR", "BLSW", "BRCR", "BTAH", "BTPI", "BTYW",
              "BUOR", "BUSH", "CAFI", "CAHU", "CASJ","CAVI", "CBCH", "CLNU",
              "COFL", "DCFL", "DEJU", "DUFL", "DUGR", "GRHA", "GRWA", "HAFL",
              "HETA", "HETH", "HEWA", "HOOR", "HUVI", "JUTI", "LAZB", "LEGO",
              "MGWA", "MOBL", "MOCH", "MOUQ", "NOPO", "NUWO", "OATI", "OCWA",
              "PAWR", "PIJA", "PISI", "PLVI", "PSFL", "PYNU", "RBSA", "RCKI", 
              "RNSA", "RUHU", "SPOW", "SPTO", "SSHA", "STJA", "TOSO", "TOWA", 
              "VASW", "VATH", "VGSW", "VIWA", "WEBL", "WESO", "WETA", "WEWP", 
              "WHWO", "WIFL", "WISA", "WIWA", "WOSJ", "YBMA", "ZTHA")


##download audobon models for boreal forest birds
folderUrl = 'https://drive.google.com/drive/folders/11dEkSmKs1oIpdbChR_2bUYFIE0gyaixX'
##Audobon_2010 folder
presentUrl = 'https://drive.google.com/drive/folders/18Rxl419A94oJqlRaDC7m0-z4MDjG2k7c' 

folderID  <- drive_get(as_id(folderUrl))
folderID  <- drive_get(as_id(presentUrl))
rastersPath <- './inputs/pres_western'

ras <- downloadRasters (folderUrl = presentUrl,
                        rastersPath = rastersPath,
                        group = 'western_forests', # options are:artic,aridlands, coastal etc...
                        type = '_breeding_', #options are: breeding, resident, two-season
                        birdsList = birdList)


currentUrl <-'https://drive.google.com/drive/folders/1ETLVsiQtn0NZK0ppVKGV8Vlwu2gVkfx1'