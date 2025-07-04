# ICCB2025 Geospatial Workshop Session 2: Using downscaled climate projections in R

This repository has all of the scripts and data for the ICCB 2025 workshop 'Using downscaled climate projections in R'. The powerpoint slides include instructions for running through the scripts and pictures of what the output should look like.

## Models and climate change scenarios
We have provided data for three downscaled climate models. These models were downscaled from the CMIP6 GCMs (Global Climate Models) using the CCAM model to a 10km resolution over Australia. The model name refers to the CMIP6 GCM which acted as the host model and provided input to CCAM. Further information on the downscaling technique is available in Chapman et al. (2023) and information on the climate change impacts shown in these models is available in Chapman et al. (2024).    

We have selected three models which represent the span from the full ensemble (set of all downscaled climate models): 
- ACCESS-ESM1-5 r6i1p1f1 - dry model
- EC-Earth3 r1i1p1f1 - wet model
- GFDL-ESM4 r1i1p1f1 - this model is close to the ensemble average for both temperature and precipitation changes at the end of the century

We have provided data for three climate change scenarios:
- SSP126 - a low emission pathway, with on average 2°C of global warming at the end of century compared to pre-industrial times.
- SSP245 - a medium emission pathway, with on average 3°C of warming.
- SSP370 - a high emission pathway, with on average 4°C of warming.

Note that there can be a great deal of variation within a model ensemble, and for each scenario there will be models that are warmer or cooler than the ensemble average.  

## Data
- `annual`: annual average precipitation (mm/day) and temperature (celsius) for 1981 - 2100 for Queensland.  
- `monthly`: monthly pr (mm/day), tasmax and tasmin (celsius) for 1981 - 2100 for South-East Queensland.  
- `obs`: observational data from the Australian Gridded Climate Dataset (AGCD). Variables include daily maximum and minimum temperature and precipitation for 1981 - 2020 at a 5km resolution. See Jones et al (2009) for further details.  
- `shp`: Shapefiles for Queensland and the Sunshine Coast.  

## Scripts
- `ICCB_Training.R`: the training script. This is what will be used in the workshop.  
- `ICCB_Training_complete.R`: the training script with additional examples. Try not to look at these until you've had a go yourself!

The remaining scripts in this folder were used to prepare the workshop data and are included for interest only.

## References
Further information on the models and datasets used here can be found in the following papers:
- Chapman, S., Syktus, J., Trancoso, R., Thatcher, M., Toombs, N., Wong, K. K.-H., & Takbash, A. (2023). Evaluation of Dynamically Downscaled CMIP6-CCAM Models Over Australia. Earth’s Future, 11(11), e2023EF003548. https://doi.org/10.1029/2023EF003548
- Chapman, S., Syktus, J., Trancoso, R., Toombs, N., & Eccles, R. (2024). Projected changes in mean climate and extremes from downscaled high-resolution CMIP6 simulations in Australia. Weather and Climate Extremes, 46, 100733. https://doi.org/10.1016/j.wace.2024.10073
- Jones, D. A., Wang, W., & Fawcett, R. (2009). High-quality spatial climate data-sets for Australia. Australian Meteorlogical and Oceangraphic Journal, 58, 233–248.


