####################################################################################################
####################################################################################################
## DOWNLOAD ESA DATA IN SEPAL
## Contact remi.dannunzio@fao.org 
## 2018/07/17
####################################################################################################
####################################################################################################


###### IMPORTANT --> LICENSE FROM ESA
#   The present product is made available to the public by ESA and the consortium. 
#   You may use S2 prototype LC 20m map of Africa 2016 for educational and/or scientific purposes, without any fee on the condition that you credit the ESA Climate Change Initiative and in particular its Land Cover project as the source of the CCI-LC database:
#   Copyright notice:
#   © Contains modified Copernicus data (2015/2016)
# © ESA Climate Change Initiative - Land Cover project 2017

###### INSTRUCTIONS
###### Get an authorized download link here: http://2016africalandcover20m.esrin.esa.int/download.php
authorized_url <- "http://2016africalandcover20m.esrin.esa.int/download.php?token=fdf64398367159f24ad7fb800b19dee0"

## DOWNLOAD
download.file(authorized_url,
              paste0(esastore_dir,"esa_cci.zip"),
              method="auto")

## UNZIP
system(sprintf("unzip %s -d %s",
               paste0(esastore_dir,"esa_cci.zip"),
               esastore_dir
               ))

## DELETE ZIP
system(sprintf("rm %s",
               paste0(esastore_dir,"esa_cci.zip")
               ))

setwd(rootdir)