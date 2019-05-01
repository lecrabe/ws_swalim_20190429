results_directory <- "/media/dannunzio/OSDisk/Users/dannunzio/Documents/countries/somalia/data/results_day2/"
base   <- "results_kilns"

aoi    <- paste0(chcl_dir,"Proscal_Study_Area.shp")


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

