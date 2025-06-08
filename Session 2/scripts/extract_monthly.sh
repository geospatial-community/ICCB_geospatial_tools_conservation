#!/bin/bash
 
#PBS -N ICCB_extract_monthly
#PBS -A qccceclim
#PBS -p 10
#PBS -j oe
#PBS -l walltime=24:00:00
#PBS -l mem=10gb
#PBS -q ccamamd2q

# Load Modules
module purge
module load modpathQCCCE
module load QCEstandard

# Activate virtual environment 
. /export/home/qclim/env-3.6.5/bin/activate

#cd ${PBS_O_WORKDIR}

# Arguments ------------------------------------------------------------------------------------ #

models=("ACCESS-CM2" "EC-Earth3" "GFDL-ESM4")
variants=("r2i1p1f1" "r1i1p1f1" "r1i1p1f1")
experiments=("CCAM10oc" "CCAM10" "CCAM10")

scen="ssp370"

outdir="/export/home/qclim/repositories/projects/collaborations/workshops/ICCB/data/monthly/"
base_dir="/scratch/qclimdata/CCAM/CORDEX-CMIP6/AUS-10i/post-processed/"

if [ ! -d ${outdir} ]; then
	 mkdir -p ${outdir}
fi

for m in {0..2}; do
	
	model=${models[${m}]}
	variant=${variants[${m}]}
	experiment=${experiments[${m}]}


	tmax_file="${base_dir}${model}_${experiment}/${scen}/${variant}/mon/tasmax_${model}_*.nc"
	tmin_file="${base_dir}${model}_${experiment}/${scen}/${variant}/mon/tasmin_${model}_*.nc"
	pr_file="${base_dir}${model}_${experiment}/${scen}/${variant}/mon/pr_${model}_*.nc"

	tmax_out="${outdir}tasmax_${model}_${scen}_${variant}_${experiment}_aus-10i_10km_mon_1981-2100.nc"
	tmin_out="${outdir}tasmin_${model}_${scen}_${variant}_${experiment}_aus-10i_10km_mon_1981-2100.nc"
	pr_out="${outdir}pr_${model}_${scen}_${variant}_${experiment}_aus-10i_10km_mon_1981-2100.nc"

	tmax_temp="${outdir}tasmax_${model}_${scen}_${variant}_${experiment}_temp.nc"
	tmin_temp="${outdir}tasmin_${model}_${scen}_${variant}_${experiment}_temp.nc"
	pr_temp="${outdir}pr_${model}_${scen}_${variant}_${experiment}_temp.nc"
	
	tmax_temp2="${outdir}tasmax_${model}_${scen}_${variant}_${experiment}_temp2.nc"
	tmin_temp2="${outdir}tasmin_${model}_${scen}_${variant}_${experiment}_temp2.nc"
	pr_temp2="${outdir}pr_${model}_${scen}_${variant}_${experiment}_temp2.nc"
	
	
	cdo -setattribute,tasmax@units=degC -addc,-273.15 -select,name='tasmax' -selyear,1981/2100 -sellonlatbox,151,155,-26,-29.5 ${tmax_file} ${tmax_temp}
	cdo -setattribute,tasmin@units=degC -addc,-273.15 -select,name='tasmin' -selyear,1981/2100 -sellonlatbox,151,155,-26,-29.5 ${tmin_file} ${tmin_temp}
	cdo -setattribute,pr@units=mm -mulc,86400 -select,name='pr' -selyear,1981/2100 -sellonlatbox,151,155,-26,-29.5 ${pr_file} ${pr_temp}
	
	rm -f ${tmax_out} ${tmin_out} ${pr_out}
	
	ncks -C -x -v lat_bnds,lon_bnds,time_bnds ${tmax_temp} ${tmax_temp2}
	ncks -C -x -v lat_bnds,lon_bnds,time_bnds ${tmin_temp} ${tmin_temp2}
	ncks -C -x -v lat_bnds,lon_bnds,time_bnds ${pr_temp} ${pr_temp2}
	
	ncpdq -a time,lat,lon ${tmax_temp2} ${tmax_out}
	ncpdq -a time,lat,lon ${tmin_temp2} ${tmin_out}
	ncpdq -a time,lat,lon ${pr_temp2} ${pr_out}
	
	rm -f ${tmax_temp} ${tmin_temp} ${pr_temp} ${tmax_temp2} ${tmin_temp2} ${pr_temp2}
done
