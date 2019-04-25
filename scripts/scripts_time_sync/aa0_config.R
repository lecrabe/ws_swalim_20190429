####################################################################################################
####################################################################################################
## Configure the AA scripts
## Contact remi.dannunzio@fao.org
## 2018/08/31
####################################################################################################
####################################################################################################

the_map    <- paste0(dd_dir,"dd_map_0414_gt",gfc_threshold,"_utm_pl1.tif")
sae_dir    <- paste0(dirname(the_map),"/","sae_design_",substr(basename(the_map),1,nchar(basename(the_map))-4),"/")
point_file <- list.files(sae_dir,glob2rx("pts_*.csv"))

####################################################################################################
options(stringsAsFactors=FALSE)

library(Hmisc)
library(sp)
library(rgdal)
library(raster)
library(plyr)
library(foreign)
library(dplyr)
library(rgeos)