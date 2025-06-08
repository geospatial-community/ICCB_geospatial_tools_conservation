#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Wed May 14 08:25:51 2025

@author: qclim
"""
import glob
import xarray as xr
import argparse
import numpy as np

folder = '/export/home/qclim/repositories/projects/collaborations/workshops/ICCB/data/monthly/'

def standardise_latlon(ds, digits=2):
    """
    This function rounds the latitude / longitude coordinates to the 4th digit, because some dataset
    seem to have strange digits (e.g. 50.00000001 instead of 50.0), which prevents merging of data.
    """
    ds = ds.assign_coords({"lat": np.round(ds.lat, digits).astype('float64')})
    ds = ds.assign_coords({"lon": np.round(ds.lon, digits).astype('float64')})
    return(ds)

def preprocess_ds(ds):
    # set errant time values to datetime (no-leap models will have conflicting time values otherwise)
    if ds.time.dtype == "O":
        ds = ds.assign_coords(time = ds.indexes['time'].to_datetimeindex()) 
    
    ds = standardise_latlon(ds)
    ds = ds.drop_vars([item for item in ('height', 'lat_bnds', 'lon_bnds', 'time_bnds') if item in ds.variables or item in ds.dims])

    # round all time values to midday for consistency
    # may not be necessary for univariate methods, depending on the mdl and ref data
    ds = ds.assign_coords(time = ds.time.dt.floor("D") + np.timedelta64(12, 'h')) 
    
    return ds

Vars = ['pr', 'tasmax', 'tasmin']



for k in range(len(Vars)):
    input_file = glob.glob(folder + Vars[k] + '*.nc')
    file=input_file[0]
    
    ds= xr.open_mfdataset(file, preprocess = preprocess_ds)
    
    ds = standardise_latlon(ds)
    ds = ds.drop_vars([item for item in ('height', 'lat_bnds', 'lon_bnds', 'time_bnds') if item in ds.variables or item in ds.dims])

    # round all time values to midday for consistency
    # may not be necessary for univariate methods, depending on the mdl and ref data
    ds = ds.assign_coords(time = ds.time.dt.floor("D") + np.timedelta64(12, 'h')) 
    
    da = ds[Vars[k]]
    da = da.chunk(chunks=None)
    da.load()
    
    fname = str.split(file, '.nc')[0] + '_fixed.nc'
    print(fname)
    da.to_netcdf(path=fname, mode='w', format = "NETCDF4")
    


