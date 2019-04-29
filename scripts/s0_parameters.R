####################################################################################################
####################################################################################################
## Set environment variables
## Contact remi.dannunzio@fao.org 
## 2018/09/07
####################################################################################################
####################################################################################################

####################################################################################################

### Read all external files with TEXT as TEXT
options(stringsAsFactors = FALSE)

### Create a function that checks if a package is installed and installs it otherwise
packages <- function(x){
  x <- as.character(match.call()[[2]])
  if (!require(x,character.only=TRUE)){
    install.packages(pkgs=x,repos="http://cran.r-project.org")
    require(x,character.only=TRUE)
  }
}

### Install (if necessary) two missing packages in your local SEPAL environment
packages(Hmisc)
packages(RCurl)
packages(hexbin)
packages(parallel)
#packages(gfcanalysis)

### Load necessary packages
packages(raster)
packages(rgeos)
packages(ggplot2)
packages(rgdal)
packages(plyr)
packages(dplyr)
packages(foreign)
packages(reshape2)
packages(survey)
packages(stringr)
packages(tidyr)

## Set the working directory
rootdir       <- "~/ws_swalim_20190429/"

## Set two downloads directories
gfcstore_dir  <- "~/downloads/gfc/2018/"
esastore_dir  <- "~/downloads/ESA_2016/"

## Set the country code
countrycode <- "SOM"

## Go to the root directory
setwd(rootdir)
rootdir  <- paste0(getwd(),"/")
username <- unlist(strsplit(rootdir,"/"))[3]

scriptdir<- paste0(rootdir,"scripts/")
data_dir <- paste0(rootdir,"data/")
gadm_dir <- paste0(rootdir,"data/gadm/")
bfst_dir <- paste0(rootdir,"data/bfast/")
tile_dir <- paste0(rootdir,"data/tiling/")
chcl_dir <- paste0(rootdir,"data/charcoal_kilns/")

dir.create(gfcstore_dir,showWarnings = F)
dir.create(esastore_dir,showWarnings = F)

dir.create(data_dir,showWarnings = F)
dir.create(gadm_dir,showWarnings = F)
dir.create(tile_dir,showWarnings = F)
dir.create(bfst_dir,showWarnings = F)
  

############ CREATE A FUNCTION TO GENERATE REGULAR GRIDS
generate_grid <- function(aoi,size){
  ### Create a set of regular SpatialPoints on the extent of the created polygons  
  sqr <- SpatialPoints(makegrid(aoi,offset=c(0,0),cellsize = size))
  
  ### Convert points to a square grid
  grid <- points2grid(sqr)
  
  ### Convert the grid to SpatialPolygonDataFrame
  SpP_grd <- as.SpatialPolygons.GridTopology(grid)
  
  sqr_df <- SpatialPolygonsDataFrame(Sr=SpP_grd,
                                     data=data.frame(rep(1,length(SpP_grd))),
                                     match.ID=F)
  ### Assign the right projection
  proj4string(sqr_df) <- proj4string(aoi)
  sqr_df
}

print(paste0("you are : ",username))
print(paste0("you use ",detectCores()," cores for this session"))

      