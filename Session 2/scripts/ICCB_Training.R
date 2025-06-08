################################################################
################ Processing Climate Data with R ################
################################################################

## Install packages
#install.packages("terra")
#install.packages("dplyr")
#install.packages("sf")
#install.packages("ggplot2")
#install.packages("dismo")
#install.packages("rasterVis")
#install.packages("reshape")

## Import packages
library(terra)
library(dplyr)
library(sf)
library(ggplot2)
library(dismo)
library(rasterVis)
library(reshape)
library(RColorBrewer)

##########################################################################
# Part 1: Temperature Data (one model)

## Set working directory
setwd("C:/R Code/Training/ICCB/")
getwd()                   # get work directory
dir()                     # list folders in the work directory
dir("data/annual/")       # List files in subdirectory

# Retrieve file names in the directory
files=dir("data/annual/")
files[1]

# Load file and query data (working with one model)
tas = rast("data/annual/tas_GFDL-ESM4_ssp370_r1i1p1f1_CCAM10_aus-10i_10km_sem_1981-2100.nc")
tas 

#Check your lat and lon coords
xFromCol(tas)
yFromRow(tas)

# Adding missing year values to the data
dates = seq(as.Date("1981-01-01"), as.Date("2100-12-01"), by="year")
names(tas) = dates  # fixing the time data in the NetCDF
tas

# Sub-setting and plotting the data
tas[[1]]
plot(tas[[1]])
plot(tas[[1:4]])
plot(tas[[117:120]])

# Can also sub-set the data according to the date array
plot(tas[[dates >= as.Date("1981-01-01") & dates <= as.Date("1984-01-01")]])
plot(tas[[dates >= as.Date("2097-01-01") & dates <= as.Date("2100-01-01")]])

tas_base = mean(tas[[1:30]])      # Calculating climatology for baseline (1981-2010)
tas_fut = mean(tas[[91:120]])     # Calculating climatology for future (2071-2100)

# Q: Can you cut the historical data and future based on the dates?

plot(tas_base)
plot(tas_fut)

# Change in future temperature (future - base)
tas_dif = tas_fut - tas_base
plot(tas_dif)

# Q. Can you make this plot nicer? Add a title and change the colours
# Hint: You can set plot titles using 'main'
# Control the colours using col = brewer.pal(11, 'PaletteName') (see https://colorbrewer2.org/ for colour options)
# You can plot multiple figures in one plot using par (mfrow = c(nrows, ncols))
# Also check the instructions from Session 1!

# Extracting out point data (timeseries)
tas[50,50]                  # extracts data from the 50th lat and 50th lon position
cells <- cellFromRowCol(tas[[1]], 50, 50)
xyFromCell(tas,cells)

df = melt(tas[50,50])

# Basic plot
plot(df, xlab = "Year", ylab = "Temperature (degC)")

# Calculating spatial average of all data
spat_ave = global(tas, fun=mean, na.rm=TRUE)
spat_ave$date = dates

# ggplot
ggplot(data = spat_ave, aes(y=mean, x=date))+ 
  ylab('Temperature (degC)') + xlab('Year') +
  geom_point() +
  geom_line() +
  geom_smooth(method = "lm") +
  theme_bw()

# Q. Can you add another model to this plot and compare the two?
# Hint: You'll need to prepare a dataframe with data for all models in it. One of the columns will need to be the values, and the other the model name.


##########################################################################
# Part 2: Rainfall Data (multiple models)
# Working with multiple Models

pr_files <- list.files(path = "data/annual/", pattern = "pr", full.names = TRUE)            # Lists all files, including all scenarios
pr_files <- list.files(path = "data/annual/", pattern = "pr.*ssp370", full.names = TRUE)    # Lists files with only ssp370

pr_data = rast(pr_files)*365  # daily mean to annual total. CCAM has a 365 day calendar.
pr_data

# Repeating the year names multiple times to correspond with multiple models
years = seq(1981,2100)
years_rep = rep(years, times =3)
names(pr_data) = years_rep

# Calculating the model average
pr_modavg = tapp(pr_data, years, fun = mean)

# Calculating climatology for baseline (1981-2010)
pr_base = mean(pr_modavg[[1:30]])  # Converting from daily mean to annual mean

# Calculating climatology for future (2071-2100)
pr_fut = mean(pr_modavg[[91:120]])  # Converting from daily mean to annual mean

# Q: Can you select the data based on the years instead?


# Plot historic and future rainfall
levelplot(pr_base)
levelplot(pr_fut)

# Cutting data to Queensland
qld_shp = vect('data/shp/QLD_State_Mask.shp')
pr_dif = pr_fut - pr_base
pr_dif_masked <- crop(pr_dif, qld_shp, mask = TRUE)
levelplot(pr_dif_masked, margin = FALSE)

# Plotting the percent change 
pr_pdif = (pr_fut - pr_base ) / pr_base *100  #Percent difference
pr_pdif_masked <- crop(pr_pdif, qld_shp, mask = TRUE)
levelplot(pr_pdif_masked, margin = FALSE)

# Specifying plotting bins and colours
my.at <- seq(-20, 20, length.out = 10)
my.at = c(-Inf, my.at, Inf)
levelplot(pr_pdif_masked, margin = FALSE, at = my.at, cuts=11, pretty=T,
                col.regions=((brewer.pal(11,"RdBu"))))
  
# Q. Can you modify this plot to show more infomation? Can you add a title and change the colours?
# Would showing multiple models on this plot help?

# Q. Can we compare the results from SSP370 to another Scenario?


##########################################################################
# Part 3: Validating your data Calculating BioClim Indices  

# now working with monthly data
dir("data/monthly/") # list files in the work directory
lga_shp = vect('data/shp/SunshineCoast.shp')

tmax = rast("data/monthly/tasmax_GFDL-ESM4_ssp370_r1i1p1f1_CCAM10_aus-10i_10km_mon_1981-2100.nc")
tmin = rast("data/monthly/tasmin_GFDL-ESM4_ssp370_r1i1p1f1_CCAM10_aus-10i_10km_mon_1981-2100.nc")
pr = rast("data/monthly/pr_GFDL-ESM4_ssp370_r1i1p1f1_CCAM10_aus-10i_10km_mon_1981-2100.nc" )

#interogate data
tmax

dates <- seq(as.Date("1981-01-01"), as.Date("2100-12-01"), by="month")
names(tmax) = dates
names(tmin) = dates
names(pr) = dates

# Plot the data
lga_shp2 <- as(lga_shp, "Spatial") # convert terra shapefile into format compatible with sp.polygons
qld2 <- as(qld_shp, "Spatial")
levelplot(mean(tmin[[0:360]]), margin = FALSE, par.settings = BuRdTheme, main = 'TMIN') +
  latticeExtra::layer(sp.polygons(lga_shp2, col = 'blue')) + # tell R we want to use layer from lattice, not from ggplot2
  latticeExtra::layer(sp.polygons(qld2))


# Validating the data against observations
dir("data/obs/") # list files in the obs dir

# Load in observation data
obs_tmax = rast(list.files(path = "data/obs/", pattern = "tmax", full.names = TRUE))
obs_tmin = rast(list.files(path = "data/obs/", pattern = "tmin", full.names = TRUE))
obs_pr = rast(list.files(path = "data/obs/", pattern = "precip", full.names = TRUE))

# Interogate the data (note the difference in resolution and time period)
# to compare data need to make them on the same spatial and temporal scales...
obs_tmax
tmax

# Resampling the data to the same spatial extent
obs_tmax_regridded <- resample(obs_tmax, tmax, method = "bilinear")
obs_tmin_regridded <- resample(obs_tmin, tmin, method = "bilinear")
obs_pr_regridded <- resample(obs_pr, pr, method = "bilinear")  # note typically we would use distance weighted interpolation outside of R

# retrieve model data over the same period as the observations
tmax_his = tmax[[dates >= as.Date("1981-01-01") & dates < as.Date("2021-01-01")]]
tmin_his = tmin[[dates >= as.Date("1981-01-01") & dates < as.Date("2021-01-01")]]
pr_his = pr[[dates >= as.Date("1981-01-01") & dates < as.Date("2021-01-01")]]

# compare data now
obs_pr_regridded
pr_his


# evaluate the bias of tmin
obs_tmin_regridded_mean = mean(obs_tmin_regridded)
tmin_his_mean = mean(tmin_his)
tmin_bias = (tmin_his_mean - obs_tmin_regridded_mean)
tmin_bias_masked <- crop(tmin_bias, qld_shp, mask = TRUE)

# Plot the bias
my.at <- seq(-3, 3, length.out = 10)
my.at = c(-Inf, my.at, Inf)
levelplot(tmin_bias_masked, at = my.at, margin = FALSE, cuts=11, pretty=T, main = 'Tmin bias (degC)',
          col.regions=rev((brewer.pal(11,"RdBu")))) +
  latticeExtra::layer(sp.polygons(lga_shp2, col = 'blue')) + # tell R we want to use layer from lattice, not from ggplot2
  latticeExtra::layer(sp.polygons(qld2))

# Quantify the bias using RMSE and MAPE
rmse = global((tmin_his_mean - obs_tmin_regridded_mean)^2, fun = "mean", na.rm = TRUE)[1]
print(paste("RMSE:", rmse))

mape = global((abs((tmin_his_mean - obs_tmin_regridded_mean) / obs_tmin_regridded_mean) * 100), fun = "mean", na.rm = TRUE)[1]
print(paste("MAPE:", mape))

# Q: Can you load in another model and compare the bias to this one?


# Masking data to Sunshine Coast
pr_masked <- crop(pr, lga_shp, mask = TRUE)
tmin_masked <- crop(tmin, lga_shp, mask = TRUE)
tmax_masked <- crop(tmax, lga_shp, mask = TRUE)

# Spatial average
pr_ave_coarse = global(pr_masked, fun=mean, na.rm=TRUE)
tmin_ave_coarse = global(tmin_masked, fun=mean, na.rm=TRUE)
tmax_ave_coarse = global(tmax_masked, fun=mean, na.rm=TRUE)

# Plot the masked data
lga_shp2 <- as(lga_shp, "Spatial") # convert terra shapefile into format compatible with sp.polygons
levelplot(mean(tmin_masked[[0:360]]), margin = FALSE, par.settings = BuRdTheme, main = 'TMIN') +
  latticeExtra::layer(sp.polygons(lga_shp2, col = 'blue'))  # tell R we want to use layer from lattice, not from ggplot2

# Weighted spatial average
pr_ave = as.data.frame(t(terra::extract(pr, lga_shp, weights=TRUE, fun=mean, na.rm=TRUE, ID=FALSE)))
tmin_ave = as.data.frame(t(terra::extract(tmin, lga_shp, weights=TRUE, fun=mean, na.rm=TRUE, ID=FALSE)))
tmax_ave = as.data.frame(t(terra::extract(tmax, lga_shp, weights=TRUE, fun=mean, na.rm=TRUE, ID=FALSE)))

# Comparison of average vs spatial average
par( mfrow= c(1,1) )
plot(pr_ave_coarse$mean, pr_ave$V1, xlab = "Average", ylab = "Spatial Average")


# Rename header from mean to variable for merging
colnames(pr_ave)[1] <- "pr"
colnames(tmin_ave)[1] <- "tmin"
colnames(tmax_ave)[1] <- "tmax"

# Adding date column for merging
pr_ave$date <- rownames(pr_ave)
tmin_ave$date <- rownames(tmin_ave)
tmax_ave$date <- rownames(tmax_ave)

# Merge data into a dataframe
df <- merge(pr_ave, tmin_ave, by = "date", all = TRUE)
df <- merge(df, tmax_ave, by = "date", all = TRUE)


# Select the baseline (1981-2010)
df$date <- as.Date(df$date)
df$year <- as.numeric(format(df$date, "%Y"))
df_base = subset(df, year >= 1981 & year <= 2010)
df_fut = subset(df, year >= 2071 & year <= 2100)


# Using dismo package to calculate the biovars
bio_base = biovars(df_base$pr, df_base$tmin, df_base$tmax)
bio_fut = biovars(df_fut$pr, df_fut$tmin, df_fut$tmax)

print(bio_base[, c("bio5", "bio6", "bio12", "bio15")])
print(bio_fut[, c("bio5", "bio6", "bio12", "bio15")])


# How can we repeat this process for every single grid cell across SEQ???
# Can loop through every single lat and lon and calculate and save the outputs...
# Or can use customised functions with terra applied to all cells 

tmax_base = tmax[[dates >= as.Date("1981-01-01") & dates < as.Date("2011-01-01")]]
tmin_base = tmin[[dates >= as.Date("1981-01-01") & dates < as.Date("2011-01-01")]]
pr_base = pr[[dates >= as.Date("1981-01-01") & dates < as.Date("2011-01-01")]]

tmax_fut = tmax[[dates >= as.Date("2071-01-01") & dates < as.Date("2101-01-01")]]
tmin_fut = tmin[[dates >= as.Date("2071-01-01") & dates < as.Date("2101-01-01")]]
pr_fut = pr[[dates >= as.Date("2071-01-01") & dates < as.Date("2101-01-01")]]

# Stack the inputs
bioclim_input_base =c(pr_base, tmin_base, tmax_base)
bioclim_input_fut =c(pr_fut, tmin_fut, tmax_fut)

# Function to calculate the bioclimatic indices customised for stacked terra inputs
fun_bio_calc <- function(x) {
  # Split the input into pr, tmin, and tmax
  n <- length(x) / 3
  pr <- x[1:n]
  tmin <- x[(n + 1):(2 * n)]
  tmax <- x[(2 * n + 1):(3 * n)]
  
  # Calculate bioclimatic variables for the time series
  bio <- biovars(pr, tmin, tmax)
  
  # Return the bioclimatic variables as a vector
  return(bio)
}


# Apply the function using terra::app
bio_base <- app(bioclim_input_base, fun = fun_bio_calc)
bio_fut <- app(bioclim_input_fut, fun = fun_bio_calc)
plot(bio_base[[12]])
plot(bio_fut[[12]])

# Q: can you plot the bioclimatic indices in the past and present and compare the changes?



# Q: What does the bioclimatic indicators look like for a lower emissions scenario?


