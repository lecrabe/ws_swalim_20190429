####################################################################################################
####################################################################################################
## Tiling of an AOI (shapefile defined)
## Contact remi.dannunzio@fao.org 
## 2019/03/11
####################################################################################################
####################################################################################################

### GET COUNTRY BOUNDARIES FROM THE WWW.GADM.ORG DATASET
aoi   <- getData('GADM',
                 path=gadm_dir, 
                 country= countrycode, 
                 level=0)


### GET SENTINEL TILING SYSTEM FROM Military Grid Reference System (MGRS)
if(!file.exists(paste0(gadm_dir,"MGRS_100kmSQ_ID_38N.zip"))){
  system(sprintf("wget -O %s %s",
                 paste0(gadm_dir,"MGRS_100kmSQ_ID_38N.zip"),
                 "http://earth-info.nga.mil/GandG/coordsys/zip/MGRS/MGRS_100kmSQ_ID/MGRS_100kmSQ_ID_38N.zip"
  ))
  
  system(sprintf("unzip -o %s -d %s",
                 paste0(gadm_dir,"MGRS_100kmSQ_ID_38N.zip"),
                 gadm_dir
  ))
}

aoi <- readOGR(paste0(gadm_dir,"MGRS_100kmSQ_ID_38N.shp"))
aoi <- aoi[aoi$X100kmSQ_ID == "NJ",]
proj4string(aoi)
(bb    <- extent(aoi))

### What grid size do we need ? 
grid_size <- 20000          ## in meters

### GENERATE A GRID
sqr_df <- generate_grid(aoi,grid_size)

nrow(sqr_df)

### Select a vector from location of another vector
sqr_df_selected <- sqr_df[aoi,]
nrow(sqr_df_selected)

### Give the output a decent name, with unique ID
names(sqr_df_selected@data) <- "tileID" 
sqr_df_selected@data$tileID <- row(sqr_df_selected@data)[,1]

### Reproject in LAT LON
tiles   <- spTransform(sqr_df_selected,CRS("+init=epsg:4326"))
aoi_geo <- spTransform(aoi,CRS("+init=epsg:4326"))


### Plot the results
plot(tiles)
plot(aoi_geo,add=T,border="blue")


### Select and Export one Tile as KML 
one_tile <- tiles[15,]
plot(one_tile,col="green",add=T)
export_name <- paste0("one_tile")
writeOGR(obj=   one_tile,
         dsn=   paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)

##############################################################################
### CONVERT TO A FUSION TABLE
### For example:    
##############################################################################

### Export ALL TILES as KML
export_name <- paste0("tiling_system_38NNJ")

writeOGR(obj=tiles,
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)

