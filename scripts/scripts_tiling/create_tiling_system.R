####################################################################################################
####################################################################################################
## Tiling of an AOI (shapefile defined)
## Contact remi.dannunzio@fao.org 
## 2019/03/11
####################################################################################################
####################################################################################################

### READ PROSCAL BOUNDARIES
aoi   <- readOGR(paste0(chcl_dir,"Proscal_Study_Area.shp"))


proj4string(aoi)
(bb    <- extent(aoi))

### What grid size do we need ? 
grid_size <- 20000          ## in meters

### GENERATE A GRID
sqr_df <- generate_grid(aoi,grid_size/111320)

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



### Export ALL TILES as KML
export_name <- paste0("tiling_system_charcoal_kilns")

writeOGR(obj=tiles,
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)

### Read the list of usernames
users     <- read.csv(paste0(data_dir,"workshop_list_20190429.csv"))


### Assign each tile with a username
df        <- data.frame(cbind(tiles@data[,"tileID"],users$username))
names(df) <- c("tileID","username")
#df$username <- sort(df$username)
df$tileID <- as.numeric(df$tileID)
table(df$username)

### Create a final subset corresponding to your username
tiles@data <- df 

my_tiles <- tiles[tiles$tileID %in% df[df$username == username,"tileID"],]

plot(my_tiles,add=T,col="green")
length(my_tiles)

### Export the final subset
export_name <- paste0("charcoal_kilns_",length(my_tiles),"_tiles_",username)

writeOGR(obj=my_tiles,
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)

### Export the ONE TILE IN THE subset
export_name <- paste0("charcoal_kilns_one_tile_",username)

writeOGR(obj=my_tiles[1,],
         dsn=paste(tile_dir,export_name,".kml",sep=""),
         layer= export_name,
         driver = "KML",
         overwrite_layer = T)
