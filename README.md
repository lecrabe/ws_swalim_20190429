### SEPAL Workshop SWALIM, May 2019
The material on this repository has been developed to run inside SEPAL (https://sepal.io) and Google Earth Engine (https://code.earthengine.google.com)

It was directed at staff from FAO-SWALIM, FAO-KENYA and RCMRD for a workshop in Nairobi 29 April - 3 May 2019

The GEE scripts for S1 SAR data processing are adapted from A.Vollrath and available here upon request: https://earthengine.googlesource.com/users/remidannunzio/swalim

#### Time series analysis of optical imagery

Time series analysis of optical imagery to monitor vegetation degradation in relation with charcoal kilns. The BFAST algorithm developed by Wageningen university was applied for the period 2013-2019 on Landsat 8 data, in the PROSCAL area.

![Alt text](/docs/images/bfast.jpeg?raw=true)

Over 230,000 kilns were identified in the area (``Bolognesi & Leonardi, Analysis of very high-resolution satellite images to generate, information on the charcoal production and its dynamics in South Somalia from 2011 to 2017. Technical Project Report. FAO-SWALIM, Nairobi, Kenya. 2018 ``). 

The BFAST analysis enabled to look at the relationship between distance to kiln and probability of vegetation damage through a generalized additive model  (GAM)

![Alt text](/docs/images/GAM2.png?raw=true)

#### Time series analysis of radar imagery

Timescans of Sentinel 1 backscatter data for the first semester of 2018 were used to map a flood event that occured in May 2018. Supervised classification of the Timescan was produced directly in GEE. 

![Alt text](/docs/images/floods_2.png?raw=true)

#### Mosaic creation and LCLU classification (Sentinel-2/Landsat)

![Alt text](/docs/images/supervised_classification.jpeg?raw=true)


####  Temporal profile calculation and plotting

![Alt text](/docs/images/ndvi_profile.jpeg?raw=true)

