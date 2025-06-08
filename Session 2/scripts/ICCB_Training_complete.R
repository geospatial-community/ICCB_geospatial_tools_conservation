################################################################
################ Processing Climate Data with R ################
################################################################

## Install packages
install.packages("terra")
install.packages("dplyr")
install.packages("sf")
install.packages("ggplot2")
install.packages("dismo")
install.packages("rasterVis")
install.packages("reshape")

## Import packages
library(terra)
library(dplyr)
library(sf)
library(ggplot2)
library(dismo)
library(rasterVis)
library(reshape)
library(RColorBrewer)


# Part 1: Temperature Data (one model)

## Set working directory

getwd()                   # get work directory
dir()                     # list files in the work directory
dir("data/annual/")       # List files in subdirectory

# Retrieve file names in the directory
files=dir("data/annual/")
files[1]

# Load file and query data (working with one model)
tas = rast("data/annual/tas_GFDL-ESM4_ssp370_r1i1p1f1_CCAM10_aus-10i_10km_sem_1981-2100.nc")
tas 

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
tas_base = mean(tas[[dates >= as.Date("1981-01-01") & dates <= as.Date("2010-01-01")]])
tas_fut = mean(tas[[dates >= as.Date("2071-01-01") & dates <= as.Date("2100-01-01")]])

plot(tas_base)
plot(tas_fut)

# Change in future temperature (future - base)
tas_dif = tas_fut - tas_base
plot(tas_dif)

# Q. Can you make this plot nicer? Add a title and change the colours
# Hint: You can set plot titles using 'main'
# Control the colours using col = brewer.pal(11, 'PaletteName') (see https://colorbrewer2.org/ for colour options)
# You can plot multiple figures in one plot using par (mfrow = c(nrows, ncols))
qld_shp = vect('data/shp/QLD_State_Mask.shp') # this was going to be loaded later in the workshop, but loading now for plotting
par( mfrow= c(3,1) ) # Set up figure to have 3 rows and 1 column
plot(tas_base, col = brewer.pal(11,"YlOrRd"), main = "Historical", range = c(14, 30))
lines(qld_shp)
plot(tas_fut, col = brewer.pal(11,"YlOrRd"), main = "Future", range = c(14, 30))
lines(qld_shp)
plot(tas_dif, col = rev(brewer.pal(11,"RdBu")), main = "Change")
lines(qld_shp)

# Extracting out point data (timeseries)
tas[50,50]                  # extracts data from the 50th lat and 50th lon position
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
spat_ave$model <- "GFDL-ESM4" # add model name to your spatial average data
tas_ECEarth <- rast("data/annual/tas_EC-Earth3_ssp370_r1i1p1f1_CCAM10_aus-10i_10km_sem_1981-2100.nc") # load in a new model and prepare the datafarme
spat_ave_EC <- global(tas_ECEarth, fun = mean, na.rm = TRUE)
spat_ave_EC$date <- dates
spat_ave_EC$model <- 'EC-Earth3'
df <- rbind(spat_ave, spat_ave_EC) # make a new dataframe with data for both models in it

ggplot(data = df, aes(y=mean, x=date, group=model, color = model))+ 
  ylab('Temperature (degC)') + xlab('Year') +
  geom_point() +
  geom_line() +
  geom_smooth(method = "lm") +
  theme_bw() +
  theme(legend.position='bottom') +
  scale_color_manual(name = 'Model', values = c("#1b9e77", "#7570b3"))
  

# Part 2: Rainfall Data (multiple models)

# Working with multiple Models
pr_files <- list.files(path = "data/annual/", pattern = "pr", full.names = TRUE)            # Lists all files, including all scenarios
pr_files <- list.files(path = "data/annual/", pattern = "pr.*ssp370", full.names = TRUE)    # Lists files with only ssp370

pr_data = rast(pr_files)*365  # daily mean to annual total
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
pr_base = mean(pr_modavg[[years>=1981 & years<=2010]])  # Converting from daily mean to annual mean
pr_fut = mean(pr_modavg[[years>=2071 & years<=2100]])  # Converting from daily mean to annual mean

# Plot historic and future rainfall
levelplot(pr_base)
levelplot(pr_fut)

# Cutting data to Queensland
qld_shp = vect('data/shp/QLD_State_Mask.shp')
pr_dif = pr_fut - pr_base
pr_dif_masked <- crop(pr_dif, qld_shp, mask = TRUE)
levelplot(pr_dif_masked)

# Plotting the percent change 
pr_pdif = (pr_fut - pr_base ) / pr_base *100  #Percent difference
pr_pdif_masked <- crop(pr_pdif, qld_shp, mask = TRUE)
levelplot(pr_pdif_masked)

# Specifying plotting bins and colours
my.at <- seq(-20, 20, length.out = 10)
my.at = c(-Inf, my.at, Inf)
levelplot(pr_pdif_masked, at = my.at, cuts=11, pretty=T,
                col.regions=((brewer.pal(11,"RdBu"))))
  
# Q. Can you modify this plot to show more infomation? Can you add a title and change the colours?
# Would showing multiple models on this plot help?
# We've included levelplot here as it's a popular package that creates nicer base plots than the basic plotting function
# however it doesn't work that well with terra when it comes to shapefiles. To plot shapefiles over the raster you'll need to convert
# the data 
library(grid) # if we want to control multiple panels when plotting with levelplot, use the grid package
library(gridExtra) 

qld2 <- as(qld_shp, "Spatial") # convert terra shapefile into format compatible with sp.polygons

# Create new bins for base plot
my.at_base <- seq(0, 1000, length.out = 10)
my.at_base = c(my.at_base, Inf)

pr_base_mask <-  crop(pr_base, qld_shp, mask = TRUE)

p1 <- levelplot(pr_base_mask, at = my.at_base, cuts=11, pretty=T,
          col.regions=rev((brewer.pal(11,"PRGn"))), margin = FALSE,
          main = list(label = 'Historical', cex = 1), # cex controls font size
          colorkey = list(title = "mm/year")) +
      latticeExtra::layer(sp.polygons(qld2)) # tell R we want to use layer from lattice, not from ggplot2
p2 <- levelplot(pr_pdif_masked, at = my.at, cuts=11, pretty=T,
                col.regions=rev((brewer.pal(11,"PRGn"))), margin = FALSE,
                main = list(label = 'Precipitation Change', cex = 1),
                colorkey = list(title = "%")) +
      latticeExtra::layer(sp.polygons(qld2))

grid.arrange(p1, p2, nrow = 1, ncol = 2, top = textGrob('Ensemble Average', gp=gpar(fontsize=15)))


# Plotting against another emissions scenario
pr_files_245 <- list.files(path = "data/annual/", pattern = "pr.*ssp245", full.names = TRUE)    # Lists files with only ssp370
pr_data_245 = rast(pr_files_245)*365  # daily mean to annual total. CCAM has a 365 day calendar.
names(pr_data_245) = years_rep
pr_modavg_245 = tapp(pr_data_245, years, fun = mean)
pr_base_245 = mean(pr_modavg_245[[years>=1981 & years<=2010]])  # Converting from daily mean to annual mean
pr_fut_245 = mean(pr_modavg_245[[years>=2071 & years<=2100]])  # Converting from daily mean to annual mean
pr_pdif_245 = (pr_fut_245 - pr_base_245 ) / pr_base_245 *100  #Percent difference
pr_pdif_245_masked <- crop(pr_pdif_245, qld_shp, mask = TRUE)

p1 <- levelplot(pr_pdif_masked, at = my.at, cuts=11, pretty=T,
                col.regions=(brewer.pal(11,"PRGn")), margin = FALSE,
                main = list(label = 'Precipitation Change: SSP370', cex = 1),
                colorkey = list(title = "%")) +
  latticeExtra::layer(sp.polygons(qld2))
p2 <- levelplot(pr_pdif_245_masked, at = my.at, cuts=11, pretty=T,
                col.regions=(brewer.pal(11,"PRGn")), margin = FALSE,
                main = list(label = 'Precipitation Change: SSP245', cex = 1),
                colorkey = list(title = "%")) +
  latticeExtra::layer(sp.polygons(qld2))

grid.arrange(p1, p2, nrow = 1, ncol=2, top = textGrob('Ensemble Average', gp=gpar(fontsize=15)))


# Part 3: Validating your data and Calculating BioClim Indices 

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

#plot one bioclimatic index
levelplot(bio_base[[1]], margin = FALSE, main = "BIO 1: Annual Mean Temperature", col.regions=((brewer.pal(9,"YlOrRd"))),
          at = seq(16, 22, length.out = 10))


# Plot all temp indices together together
my.at <- seq(0, 50, length.out = 8)
my.at = c(my.at, Inf)
levelplot(bio_base[[1:11]], margin = FALSE, main = "BIOCLIMATIC INDICATORS", col.regions=((brewer.pal(9,"YlOrRd"))),
          at = my.at, names =  c("BIO1", "BIO2", "BIO3", "BIO4", "BIO5", "BIO6", "BIO7", "BIO8", "BIO9", "BIO10", "BIO11"))

#Plot all precip indices together
my.at <- seq(0, 50, length.out = 8)
my.at = c(my.at, Inf)
levelplot(bio_base[[12:19]], margin = FALSE, main = "BIOCLIMATIC INDICATORS", col.regions=((brewer.pal(9,"GnBu"))),
          at = my.at, names =  c("BIO12", "BIO13", "BIO14", "BIO15", "BIO16", "BIO17", "BIO18", "BIO19"))

# Compare changes
bio_dif = bio_fut - bio_base
bio_sdm <- c(bio_dif[[5:6]], bio_dif[[12]], bio_dif[[15]]) # Let's just get the layers used for the species modelling tomorrow

levelplot(bio_dif[[5]], margin = FALSE, main = "BIO 5: Max Temperature of Warmest Month", col.regions=((brewer.pal(9,"YlOrRd"))),
          at = seq(3, 6, length.out = 10))

# Plot temp indicators
levelplot(bio_sdm[[1:2]], margin = FALSE, main = "CHANGE IN BIOCLIMATIC INDICATORS", names = c("BIO5: Max Temp Warmest Month", "BIO6: Min Temp Coldest Month"),
          col.regions=((brewer.pal(9,"YlOrRd"))),
          at = seq(3, 6, length.out = 10))

# Plot rainfall indicators
my.at <- seq(-150, 150, length.out = 10)
my.at = c(-Inf, my.at, Inf)
levelplot(bio_sdm[[3:4]], margin = FALSE, main = "CHANGE IN BIOCLIMATIC INDICATORS", names = c("BIO12: Annual Precipitation", "BIO15: Precipitation Seasonality"),
          col.regions=((brewer.pal(9,"PRGn"))),
          at = my.at)
# Q: What does the bioclimatic indicators look like for a lower emissions scenario?


