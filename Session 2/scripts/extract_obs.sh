#!/bin/bash
 
#PBS -N ICCB_extract_AGCD
#PBS -A qccceclim
#PBS -p 10
#PBS -j oe
#PBS -l walltime=24:00:00
#PBS -l mem=40gb
#PBS -q ccamamd2q

# Load Modules
module purge
module load modpathQCCCE
module load QCEstandard

# Activate virtual environment 
. /export/home/qclim/env-3.6.5/bin/activate

#cd ${PBS_O_WORKDIR}

# Arguments ------------------------------------------------------------------------------------ #

vars=("precip" "tmax" "tmin")

outdir="/export/home/qclim/repositories/projects/collaborations/workshops/ICCB/data/obs/"
base_dir="/scratch/qclimprod/Obs/AGCD/2024/v1-0-2/"

if [ ! -d ${outdir} ]; then
	 mkdir -p ${outdir}
fi

for v in {1..2}; do
	
	var=${vars[${v}]}
	
	infile="${base_dir}${var}/*/r005/01day/concat/agcd_v1_${var}_*_r005_daily_1911_2023.nc"
	
	outfile="${outdir}agcd_v1_${var}_r005_daily_1981_2020.nc"
	
	cdo -monmean -selyear,1981/2020 -sellonlatbox,151,155,-26,-29.5 ${infile} ${outfile}
	
done
