##########################################################################################
################## Read, manipulate and write raster data
##########################################################################################

########################################################################################## 
# Contact: remi.dannunzio@fao.org
# Last update: 2018-08-24
##########################################################################################

time_start  <- Sys.time()

####################################################################################
####### GET COUNTRY BOUNDARIES
####################################################################################
aoi <- getData('GADM',path=gadm_dir, country= countrycode, level=1)

##  Add a numerical unique identifier and Export the SpatialPolygonDataFrame as a ESRI Shapefile
aoi$OBJECTID <- row(aoi)[,1]
writeOGR(aoi,
         paste0(gadm_dir,"gadm_",countrycode,"_l1.shp"),
         paste0("gadm_",countrycode,"_l1"),
         "ESRI Shapefile",
         overwrite_layer = T)


####################################################################################
####### DOWNLOAD THE ESA MAP FROM ESA-CCI WEBSITE
####################################################################################
if(!file.exists(paste0(esastore_dir,"ESACCI-LC-L4-LC10-Map-20m-P1Y-2016-v1.0.tif"))){
  source(paste0(scriptdir,"scripts_masks/download_ESA_CCI_map.R"),echo=T)
}


####################################################################################
####### CLIP ESA MAP TO COUNTRY BOUNDING BOX
####################################################################################
if(!file.exists(paste0(esa_dir,"esa_crop.tif")){
  
  bb <- extent(aoi)
  
  system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
                 floor(bb@xmin),
                 ceiling(bb@ymax),
                 ceiling(bb@xmax),
                 floor(bb@ymin),
                 paste0(esastore_dir,"ESACCI-LC-L4-LC10-Map-20m-P1Y-2016-v1.0.tif"),
                 paste0(esa_dir,"tmp_esa.tif")
  ))
}



#############################################################
### CROP TO COUNTRY BOUNDARIES
if(!file.exists(paste0(esa_dir,"esa_crop.tif"))){
  system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
                 paste0(scriptdir,"scripts_misc/"),
                 paste0(gadm_dir,"gadm_",countrycode,"_l1.shp"),
                 paste0(esa_dir,"tmp_esa.tif"),
                 paste0(esa_dir,"esa_crop.tif"),
                 "OBJECTID"
  ))
  
}

#############################################################
### CREATE A FOREST MASK FOR BFAST ANALYSIS
if(!file.exists(paste0(esa_dir,"esa_fnf.tif"))){
  
  system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
                 paste0(esa_dir,"esa_crop.tif"),
                 paste0(esa_dir,"esa_fnf.tif"),
                 paste0("(A==0)*0 + ((A==1)+(A==2))*1 + (A>2)*0")
  )
  )
}


####################################################################################
### CROP MASK TO CHARCOAL STUDY BOUNDARIES
####################################################################################

if(!file.exists(paste0(esa_dir,"esa_fnf_proscal_bb.tif"))){
  
  aoi <- readOGR(paste0(chcl_dir,"Proscal_Study_Area.shp"))
  bb  <- extent(aoi)
  
  system(sprintf("gdal_translate -ot Byte -projwin %s %s %s %s -co COMPRESS=LZW %s %s",
                 floor(bb@xmin),
                 ceiling(bb@ymax),
                 ceiling(bb@xmax),
                 floor(bb@ymin),
                 paste0(esa_dir,"esa_fnf.tif"),
                 paste0(esa_dir,"esa_fnf_proscal.tif")
  ))
}


system(sprintf("rm -f %s",
               paste0(esa_dir,"tmp_esa.tif")
               ))
# #############################################################
# ### CREATE A FOREST MASK FOR MSPA ANALYSIS
# system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(esa_dir,"esa_crop.tif"),
#                paste0(esa_dir,"esa_mspa.tif"),
#                paste0("(A==1)*2+((A==0)+(A==200))*0+((A>1)*(A<200))*1")
# ))
# 
# 
# #################### CREATE GFC TREE COVER MAP in 2000 AT THRESHOLD
# system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(gfc_dir,"gfc_treecover2000.tif"),
#                gfc_tc,
#                paste0("(A>",gfc_threshold,")*A")
# ))
# 
# #################### CREATE GFC TREE COVER LOSS MAP AT THRESHOLD
# system(sprintf("gdal_calc.py -A %s -B %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                paste0(gfc_dir,"gfc_treecover2000.tif"),
#                paste0(gfc_dir,"gfc_lossyear.tif"),
#                gfc_ly,
#                paste0("(A>",gfc_threshold,")*B")
# ))
# 
# #################### CREATE GFC FOREST MASK IN 2000 AT THRESHOLD (0 no forest, 1 forest)
# system(sprintf("gdal_calc.py -A %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                gfc_tc,
#                gfc_00,
#                "A>0"
# ))
# 
# #################### CREATE GFC FOREST MASK IN 2016 AT THRESHOLD (0 no forest, 1 forest)
# system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                gfc_tc,
#                gfc_ly,
#                gfc_gn,
#                gfc_16,
#                "(C==1)*1+(C==0)*((B==0)*(A>0)*1+(B==0)*(A==0)*0+(B>0)*0)"
# ))
# 
# #################### CREATE MAP 2000-2014 AT THRESHOLD (0 no data, 1 forest, 2 non-forest, 3 loss, 4 gain)
# system(sprintf("gdal_calc.py -A %s -B %s -C %s --co COMPRESS=LZW --outfile=%s --calc=\"%s\"",
#                gfc_tc,
#                gfc_ly,
#                gfc_gn,
#                gfc_mp,
#                "(C==1)*4+(C==0)*((B==0)*(A>0)*1+(B==0)*(A==0)*2+(B>0)*(B<15)*3+(B>=15)*1)"
# ))
# 
# #############################################################
# ### CROP TO COUNTRY BOUNDARIES
# system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
#                scriptdir,
#                paste0(gadm_dir,"gadm_",countrycode,"_l1.shp"),
#                gfc_mp,
#                gfc_mp_crop,
#                "OBJECTID"
# ))
# 
# #############################################################
# ### CROP TO ONE STATE BOUNDARIES
# system(sprintf("python %s/oft-cutline_crop.py -v %s -i %s -o %s -a %s",
#                scriptdir,
#                paste0(gadm_dir,"work_aoi_sub.shp"),
#                gfc_mp_crop,
#                gfc_mp_sub,
#                "OBJECTID"
# ))

time_products_global <- Sys.time() - time_start


