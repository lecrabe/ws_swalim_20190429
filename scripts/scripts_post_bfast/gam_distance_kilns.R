# 
# #################### ALIGN
# mask   <- paste0(results_directory,base,"_amplitude_threshold.tif")
# proj   <- proj4string(raster(mask))
# extent <- extent(raster(mask))
# res    <- res(raster(mask))[1]
# 
# 
# #################### ALIGN
# input  <- paste0(esa_dir,"esa_crop.tif")
# ouput  <- paste0(esa_dir,"esa_crop_kilns.tif")
# 
# system(sprintf("gdalwarp -co COMPRESS=LZW -t_srs \"%s\" -te %s %s %s %s -tr %s %s %s %s -overwrite",
#                proj4string(raster(mask)),
#                extent(raster(mask))@xmin,
#                extent(raster(mask))@ymin,
#                extent(raster(mask))@xmax,
#                extent(raster(mask))@ymax,
#                res(raster(mask))[1],
#                res(raster(mask))[2],
#                input,
#                ouput
# ))
# 
# 
# ## MASK ESA
# system(sprintf("gdal_calc.py -A %s -B %s --co=COMPRESS=LZW --type=Byte --overwrite --outfile=%s --calc=\"%s\"",
#                paste0(results_directory,base,"_amplitude_threshold.tif"),
#                paste0(esa_dir,"esa_crop_kilns.tif"),
#                paste0(esa_dir,"esa_crop_kilns_masked.tif"),
#                "(A>0)*((B==0)*1 +(B>0)*(B+1))"
# ))
# 
# 
# kilns <- readOGR(paste0(chcl_dir,"Som_Proscal_Charcoalsites_Final_SWALIM_01FEB2018.shp"))
# kilns$id_unique <- row(kilns)[,1]
# 
# kilns$year <- 0
# kilns@data[!is.na(kilns@data$Y2016),]$year <- 16
# kilns@data[!is.na(kilns@data$Y2017),]$year <- 17
# 
# table(kilns$year)
# shp <- kilns[kilns$year >0 ,c("id_unique","Radius_m","year","Y2016","Y2017","category")]
# summary(shp$Radius_m)
# 
# center <- gCentroid(shp,byid = T)
# 
# pts <- SpatialPointsDataFrame(coords = center@coords,
#                               data = shp@data,
#                               proj4string = CRS('+init=epsg:4326')
#                                 )
# 
# writeOGR(pts,paste0(chcl_dir,"centroids_kilns_1617.shp"),"centroids_kilns_1617","ESRI Shapefile",overwrite_layer = T)
# 
# #############################################################
# ### AOI
# system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
#                paste0(scriptdir,"scripts_misc/"),
#                paste0(chcl_dir,"centroids_kilns_1617.shp"),
#                paste0(results_directory,base,"_amplitude_threshold.tif"),
#                paste0(chcl_dir,"centroids_kilns_1617.tif"),
#                "year"
# ))
# 
# ##################### CREATE A DISTANCE TO KILNS
# system(sprintf("gdal_proximity.py -co COMPRESS=LZW -ot Int16 -distunits PIXEL %s %s",
#                paste0(chcl_dir,"centroids_kilns_1617.tif"),
#                paste0(chcl_dir,"dist_kilns.tif")
# ))
# 
# 
# ## MASK DISTANCES
# system(sprintf("gdal_calc.py -A %s -B %s --co=COMPRESS=LZW --type=Int16 --overwrite --outfile=%s --calc=\"%s\"",
#                paste0(results_directory,base,"_amplitude_threshold.tif"),
#                paste0(chcl_dir,"dist_kilns.tif"),
#                paste0(chcl_dir,"dist_kilns_masked.tif"),
#                "(A>0)*((B==0)*1 +(B>0)*(B+1))"
# ))

##################### READ THE DIFFERENT LAYERS AND STORE AS ONE DATA TABLE
r1 <- raster(paste0(results_directory,base,"_amplitude_threshold.tif"))
r2 <- raster(paste0(esa_dir,"esa_crop_kilns_masked.tif"))
r3 <- raster(paste0(chcl_dir,"dist_kilns_masked.tif"))

c1 <- as.data.frame(rasterToPoints(r1,function(rast) {rast >0}))
c2 <- as.data.frame(rasterToPoints(r2,function(rast) {rast >0}))
c3 <- as.data.frame(rasterToPoints(r3,function(rast) {rast >0}))

df <- cbind(c1,
            c2[,3],
            c3[,3])
rm(c1)
rm(c2)
rm(c3)

names(df) <- c("x","y","bfast","esa","dist")

df$esa  <- df$esa - 1
df$dist <- df$dist - 1

##################### CHECK ESA CODES
#table(df$esa)

##################### SIMPLIFY TABLE HEADERS
df1 <- df

df1$loss <- 0
df1[(df1$bfast %in% 4:5) & (df1$esa %in% 1:2),]$loss <- 1

df1$forest <- 0
df1[(df1$esa %in% 1:2),]$forest <- 1

#table(df1$loss,df1$forest)

##################### CREATE THEME
papertheme <- theme_bw(base_size=12, base_family = 'Arial') +
  theme(legend.position='top')

d0 <- df1[,c("x","y","forest","loss","dist")]

##################### REMOVE NON FOREST PIXELS
dat <- d0[d0$forest==1,]
rm(d0)


#####################  CONVERT TO FACTOR
dat$loss <- as.factor(dat$loss)

##################### LOAD/INSTALL PACKAGES - FIRST RUN MAY TAKE TIME
packages(Hmisc)
packages(faraway)
packages(mgcv)
packages(sjPlot)
packages(sjmisc)



sel <- sample(1:nrow(dat),1000000)
dat$dist_m <- (dat$dist-1)*30

hist(dat[dat$loss ==0,]$dist_m,main="",xlab="Distance to kiln (m)")
hist(dat[dat$loss ==1,]$dist_m,add=T,col="red")

d0 <- dat[sel,]
#table(d0$loss)

##################### RUN THE MODEL
modbin <- gam(loss ~ s(dist_m,k=3) ,
              data = d0, method='REML', family = binomial())

##################### PLOT RESULTS
plot_model(modbin, type = "pred", 
           terms = c("dist_m"),
           axis.title = c("Distance to Kiln (m)","Loss probability"))

AIC(modbin)
summary(modbin)
