### MacroRefugia Indices for North American Avifauna
#Macrorefugia metricsde is an update from the code used in Stralberg et al. (2018)
#It generates the climate-change refugia indices for individual species based on 
#species distribution model predictions (for birds we use:
#2020 Audobon models https://www.audubon.org/climate/survivalbydegrees, documented
#in https://conbio.onlinelibrary.wiley.com/doi/full/10.1111/csp2.242)

The biotic velocity (Carroll et al. 2015) is calculated considering the 
nearest-analog velocity algorithm defined by Hamann et al.(2015), and then 
applies the distance-decay function to obtain an index ranging from 0 to 1. For
a fat-tailed distribution (c = 0.5, and alpha = 8333.33) results in a mean 
migration rate of 500 m/year (50km/century). Velocity values are averaged over 
four 3 GCMs (CCSM4, GFDLCM3, INMCM4)

The  values of the final product were multiply by 100 to make files smaller.

## Naming of raster Layers : 
Spp_refugia_X_ Y

where: 
* Spp = bird species 4 code letter
X = Representative Concentration Pathway (4.5 or 8.5)
Y = year (2025, 2055, 2085)

## Projection information 
Project Coordinate System: Albers_Conic_Equal_Area
Linear Unit: Meters
False Easting: 0.0
False Northing: 0.0
Central Meridian: -96.0
Standard parallel 1: 20.0
Standard parallel 2: 60.0
Latitude of origin:  40.0
Cell size: 1000

## References
Stralberg, D., Carroll, C., Pedlar, J., Wilsey, C., McKenney, D. and Nielsen, S.(2018). 
Macrorefugia for North American trees and songbirds: Climatic limiting factors and
multi-scale topographic influences. Global Ecology and Biogeography.27:6
 https://doi.org/10.1111/geb.12731
