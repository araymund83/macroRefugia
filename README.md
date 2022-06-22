### macroRefugia
#This code is an update of the code use in Stralberg et al. (2018)
#It generates the climate-change refugia indices for individual species based on 
#species distribution model predictions (for birds we use:
#2020 Audobon models https://www.audubon.org/climate/survivalbydegrees, documented
#in https://conbio.onlinelibrary.wiley.com/doi/full/10.1111/csp2.242)

#The biotic velocity (Carroll et al. 2015) is calculated considering the 
#nearest-analog velocity algorithm defined by Hamann et al.(2015), and then 
#applies the distance-decay function to obtain an index ranging from 0 to 1. For
#a fat-tailed distribution (c = 0.5, and alpha = 8333.33) results in a mean 
#migration rate of 500 m/year (50km/century). Velocity values are averaged over 
#four 3 GCMs (CCSM4, GFDLCM3, INMCM4)

The  values of the final product were multiply by 100 to make files smaller.