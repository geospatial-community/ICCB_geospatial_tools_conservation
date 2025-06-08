#!/bin/bash
 
#PBS -N ICCB_extract_annual
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

models=("ACCESS-ESM1-5" "EC-Earth3" "GFDL-ESM4")
variants=("r6i1p1f1" "r1i1p1f1" "r1i1p1f1")
experiments=("CCAM10" "CCAM10" "CCAM10")

scen="ssp126"

outdir="/export/home/qclim/repositories/projects/collaborations/workshops/ICCB/data/annual/"
base_dir="/scratch/qclimdata/CCAM/CORDEX-CMIP6/AUS-10i/post-processed/"

if [ ! -d ${outdir} ]; then
	 mkdir -p ${outdir}
fi

for m in {0..2}; do
	
    model=${models[${m}]}
    variant=${variants[${m}]}
    experiment=${experiments[${m}]}
    
 
    tas_file="${base_dir}${model}_${experiment}/${scen}/${variant}/sem/tas_${model}_*.nc"
    pr_file="${base_dir}${model}_${experiment}/${scen}/${variant}/sem/pr_${model}_*.nc"
    
    tas_out="${outdir}tas_${model}_${scen}_${variant}_${experiment}_aus-10i_10km_sem_1981-2100.nc"
    pr_out="${outdir}pr_${model}_${scen}_${variant}_${experiment}_aus-10i_10km_sem_1981-2100.nc"
    
    #cdo -selyear,1981/2100 -sellonlatbox,137.5,155,-9,-29.5 ${tas_file} ${tas_out}
    #cdo -selyear,1981/2100 -sellonlatbox,137.5,155,-9,-29.5 ${pr_file} ${pr_out}
    
    cdo -setattribute,tas_annual@units=degC -addc,-273.15 -select,name='tas_annual' -selyear,1981/2100 -sellonlatbox,137.5,155,-9,-29.5 ${tas_file} ${tas_out}
    cdo -setattribute,pr_annual@units=mm -mulc,86400 -select,name='pr_annual' -selyear,1981/2100 -sellonlatbox,137.5,155,-9,-29.5 ${pr_file} ${pr_out}
done
