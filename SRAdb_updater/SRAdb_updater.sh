#!/bin/bash

# This script with download and load SRAdb into MySQL
# Script should be run 2x each month to ensure up-to-date data
# To see the current cron jobs enter: crontab -l
# http://www.biomedcentral.com/1471-2105/14/19


# Download current dump of database
DATADIR='/mnt/data/work/pollardlab/snayfach/databases/SRAdb/data'
CURDIR=`date "+%m_%d_%y"`
cd $DATADIR
mkdir -p $CURDIR
cd $CURDIR
wget http://gbnci.abcc.ncifcrf.gov/backup/SRAdb.mysqldump.gz > wget.log 2>&1

# Load db into lighthouse (localhost)
mysql -e 'drop database if exists SRAdb; create database SRAdb' >> mysql.log 2>&1
zcat SRAdb.mysqldump.gz | mysql --database=SRAdb >> mysql.log 2>&1

# Update database
mysql --database=SRAdb -e "
alter table sra add ftp text, read_length int;
update sra set
   ftp = concat_ws('/','ftp://ftp-trace.ncbi.nlm.nih.gov/sra/sra-instant/reads/ByRun/sra',substring(run_accession, 1, 3),substring(run_accession, 1, 6),run_accession,concat(run_accession,'.sra','')),
   read_length = if(library_layout like 'PAIRED%', round(bases/spots/2), round(bases/spots))
;"
