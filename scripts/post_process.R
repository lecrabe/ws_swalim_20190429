results_directory <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/somalia/data/results_day2/"

aoi    <- paste0(chcl_dir,"Proscal_Study_Area.shp")
base   <- "results_kilns"

result <- paste0(results_directory,"tmp_",base,".tif")

system(sprintf("gdal_merge.py -o %s -co COMPRESS=LZW -v  %s",
               result,
               paste0(results_directory,"*/*2019.tif")
               ))

#############################################################
### AOI
system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               paste0(scriptdir,"scripts_misc/"),
               aoi,
               result,
               paste0(results_directory,"aoi.tif"),
               "OBJECTID"
))


#############################################################
### CROP AMPLITUDE TO AOI
system(sprintf("gdal_calc.py -A %s --A_band=2 -B %s --co=COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               result,
               paste0(results_directory,"aoi.tif"),
               paste0(results_directory,"tmp",base,"_amplitude_crop.tif"),
               "(B>0)*A"
))

#############################################################
### CROP DATE TO AOI
system(sprintf("gdal_calc.py -A %s --A_band=1 -B %s --co=COMPRESS=LZW --overwrite --outfile=%s --calc=\"%s\"",
               result,
               paste0(results_directory,"aoi.tif"),
               paste0(results_directory,"tmp",base,"_date_crop.tif"),
               "(B>0)*A"
))

#############################################################
### COMPUTE THRESHOLDS
ampli      <- paste0(results_directory,"tmp",base,"_amplitude_crop.tif")

means_b2   <- cellStats( raster(ampli) , "mean") 
mins_b2    <- cellStats( raster(ampli) , "min")
maxs_b2    <- cellStats( raster(ampli) , "max")
stdevs_b2  <- cellStats( raster(ampli) , "sd")

system(sprintf("gdal_calc.py -A %s -B %s --co=COMPRESS=LZW --type=Byte --overwrite --outfile=%s --calc=\"%s\"",
               ampli,
               paste0(results_directory,"aoi.tif"),
               paste0(results_directory,"tmp_bfast_threshold.tif"),
               paste0("(B>0)*(",
                      '(A<=',(maxs_b2),")*",
                      '(A>' ,(means_b2+(stdevs_b2*4)),")*9+",
                      '(A<=',(means_b2+(stdevs_b2*4)),")*",
                      '(A>' ,(means_b2+(stdevs_b2*3)),")*8+",
                      '(A<=',(means_b2+(stdevs_b2*3)),")*",
                      '(A>' ,(means_b2+(stdevs_b2*2)),")*7+",
                      '(A<=',(means_b2+(stdevs_b2*2)),")*",
                      '(A>' ,(means_b2+(stdevs_b2)),")*6+",
                      '(A<=',(means_b2+(stdevs_b2)),")*",
                      '(A>' ,(means_b2-(stdevs_b2)),")*1+",
                      '(A>=',(mins_b2),")*",
                      '(A<' ,(means_b2-(stdevs_b2*4)),")*5+",
                      '(A>=',(means_b2-(stdevs_b2*4)),")*",
                      '(A<' ,(means_b2-(stdevs_b2*3)),")*4+",
                      '(A>=',(means_b2-(stdevs_b2*3)),")*",
                      '(A<' ,(means_b2-(stdevs_b2*2)),")*3+",
                      '(A>=',(means_b2-(stdevs_b2*2)),")*",
                      '(A<' ,(means_b2-(stdevs_b2)),")*2)")
))



####################  CREATE A PSEUDO COLOR TABLE
cols <- col2rgb(c("black","beige","yellow","orange","red","darkred","palegreen","green2","forestgreen",'darkgreen'))
pct <- data.frame(cbind(c(0:9),
                        cols[1,],
                        cols[2,],
                        cols[3,]
))

write.table(pct,paste0(results_directory,"color_table.txt"),row.names = F,col.names = F,quote = F)


################################################################################
## Add pseudo color table to result
system(sprintf("(echo %s) | oft-addpct.py %s %s",
               paste0(results_directory,"color_table.txt"),
               paste0(results_directory,"tmp_bfast_threshold.tif"),
               paste0(results_directory,"tmp_colortable.tif")
))

## Compress final result
system(sprintf("gdal_translate -ot byte -co COMPRESS=LZW %s %s",
               paste0(results_directory,"tmp_colortable.tif"),
               paste0(results_directory,base,"_amplitude_threshold.tif")
))

## Year of disturbance
system(sprintf("gdal_translate -ot UInt16 -co COMPRESS=LZW %s %s",
               paste0(results_directory,"tmp",base,"_date_crop.tif"),
               paste0(results_directory,base,"_year.tif")
))

## Day of disturbance
system(sprintf("gdal_calc.py -A %s --co=COMPRESS=LZW --type=UInt16 --overwrite --outfile=%s --calc=\"%s\"",
               paste0(results_directory,"tmp",base,"_date_crop.tif"),
               paste0(results_directory,base,"_day.tif"),
               "(A-floor(A))*365"
))


#################### ALIGN GLAD WITH GFC
mask   <- paste0(results_directory,base,"_amplitude_threshold.tif")
proj   <- proj4string(raster(mask))
extent <- extent(raster(mask))
res    <- res(raster(mask))[1]


#################### ALIGN GFC TREE COVER WITH SEGMENTS
input  <- paste0(esa_dir,"esa_crop.tif")
ouput  <- paste0(esa_dir,"esa_crop_kilns.tif")

system(sprintf("gdalwarp -co COMPRESS=LZW -t_srs \"%s\" -te %s %s %s %s -tr %s %s %s %s -overwrite",
               proj4string(raster(mask)),
               extent(raster(mask))@xmin,
               extent(raster(mask))@ymin,
               extent(raster(mask))@xmax,
               extent(raster(mask))@ymax,
               res(raster(mask))[1],
               res(raster(mask))[2],
               input,
               ouput
))

#############################################################
### AOI
system(sprintf("python %s/oft-rasterize_attr.py -v %s -i %s -o %s -a %s",
               paste0(scriptdir,"scripts_misc/"),
               paste0(chcl_dir,"kilns_2016_2017.shp"),
               paste0(results_directory,base,"_amplitude_threshold.tif"),
               paste0(chcl_dir,"kilns_2016_2017.tif"),
               "Radius_m"
))

##################### CREATE A DISTANCE TO KILNS
system(sprintf("gdal_proximity.py -co COMPRESS=LZW -ot Int16 -distunits PIXEL %s %s",
               paste0(chcl_dir,"kilns_2016_2017.tif"),
               paste0(chcl_dir,"dist_kilns.tif")
))


##################### READ THE DIFFERENT LAYERS AND STORE AS ONE DATA TABLE
r1 <- raster(paste0(results_directory,base,"_amplitude_threshold.tif"))
r2 <- raster(paste0(esa_dir,"esa_crop_kilns.tif"))
r3 <- raster(paste0(chcl_dir,"dist_kilns.tif"))

c1 <- rasterToPoints(r1)
c2 <- rasterToPoints(r2)
c3 <- rasterToPoints(r3)

c10 <- c1 != 0

d1 <- data.frame(c1)
d2 <- data.frame(c2)
d3 <- data.frame(c3)

df <- cbind(d1,
            d2$esa_crop_kilns,
            d3$dist_kilns)

names(df) <- c("x","y","bfast","esa","dist_to_kilns")

##################### SELECT IN LAND DATA ONLY AND EXPORT
summary(df)
df1 <- df[df$data_mask == 1,]
hist(df1$tree_cover)
write.csv(df1,paste0(resdir,"resultats_20190212.csv"),row.names = F)

##################### SIMPLIFY TABLE HEADERS
df1 <- read.csv(paste0(resdir,"resultats_20190212.csv"))
df1$loss <- 0
df1[df1$loss_year > 0 & df1$tree_cover > 30,]$loss <- 1

df1$pa <- 0 
df1[df1$dist_to_forets == 0,]$pa <- 1

df1$forest <- 0
df1[df1$tree_cover > 30,]$forest <- 1


##################### CREATE THEME
papertheme <- theme_bw(base_size=12, base_family = 'Arial') +
  theme(legend.position='top')

dat <- df1[,c("x","y","forest","pa","loss","dist_to_roads","dist_to_forets")]
names(dat) <- c("x","y","forest","pa","loss","dist_to_roads","dist_to_pa")

##################### REMOVE NON FOREST PIXELS
dat <- dat[-which(dat$forest==0),]

#####################  CONVERT TO FACTOR
dat$pa   <- as.factor(dat$pa)
dat$loss <- as.factor(dat$loss)

##################### RUN THE MODEL
modbin <- gam(loss ~ s(dist_to_roads, by=pa, k=3) + pa,
              data = dat, method='REML', family = binomial())

##################### PLOT RESULTS
plot_model(modbin, type = "pred", terms = c("dist_to_roads","pa"))

AIC(modbin)
summary(modbin)
