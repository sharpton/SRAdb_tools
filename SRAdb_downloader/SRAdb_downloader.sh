#!/bin/bash

# Arguments
DATA_DIR=$1
STUDY_ACCESSTION=$2
THREADS=$3
#DATA_DIR='/mnt/data/work/pollardlab/snayfach/metagenomes/Crohns'
#STUDY_ACCESSTION='SRP002423'
#THREADS=8

# 0. Create data directories
mkdir -p  ${DATA_DIR} ${DATA_DIR}/sra ${DATA_DIR}/fastq ${DATA_DIR}/log ${DATA_DIR}/src

# 1. Get run accessions from mysql
FTPS=`mysql -e "select ftp from SRAdb.sra where study_accession = '$STUDY_ACCESSTION'" | sed 1d`
if [ `echo $FTPS | wc -w` -eq 0 ]; then
    echo 'No run_accessions that correspond to study_accession:' $STUDY_ACCESSTION # check there's at least 1 run
    exit
fi

# 2. Download sra files in parallel
parallel -j $THREADS wget -q -P ${DATA_DIR}/sra -- $FTPS

# 3. Convert SRA files to FASTQ using fastq-dump on chef

#   check that at least one sra file downloaded
N_SRA=`ls -1 ${DATA_DIR}/sra/*.sra | wc -l`
if [ $N_SRA -eq 0 ]; then
    echo 'No sra files to convert!!'
    exit
fi
#   determine necessary scratch space (min 2G)
MAX_K=`du ${DATA_DIR}/sra/* | cut -f1 | sort -n | tail -1`
MAX_G=`expr $MAX_K / 1000000`
EXTRA_G=`expr $MAX_G / 3`
SCRATCH_SPACE=`expr $MAX_G + $EXTRA_G`
if [ $SCRATCH_SPACE -lt 2 ]; then SCRATCH_SPACE=2; fi

#   make and run chef array script
MY_SCRIPT=${DATA_DIR}/src/fastq_dump_array.sh                                 
MY_DIR=`echo $DATA_DIR | sed 's/\/mnt\/data\/work\/pollardlab/\/pollard\/shattuck0/'`
MY_ARRAY=`echo $MY_SCRIPT | sed 's/\/mnt\/data\/work\/pollardlab/\/pollard\/shattuck0/'`
${DATA_DIR}/src/make_qsub.sh $MY_DIR $N_SRA $SCRATCH_SPACE $MY_SCRIPT
ssh chef "
export SGE_CELL=qb3cell
export PATH=/usr/local/sge/bin/linux-x86
export SGE_QMASTER_PORT=6444
export SGE_EXECD_PORT=6445
export SGE_ROOT=/usr/local/sge
qsub $MY_ARRAY
"










