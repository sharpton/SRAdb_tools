MY_DIR=$1
NTASKS=$2
SCRATCH_SPACE=$3
MY_SCRIPT=$4

cat '/dev/null' > $MY_SCRIPT

echo "\
#!/bin/bash
#$ -l arch=linux-x64
#$ -r y
#$ -cwd
#$ -l h_rt=24:00:00
#$ -l mem_free=0.2G
#$ -l scratch=${SCRATCH_SPACE}G
#$ -o ${MY_DIR}/log
#$ -e ${MY_DIR}/log
#$ -t 1-${NTASKS}
" >> $MY_SCRIPT

echo "\
# arguments
N_CONCURRENT_READS=5
CONCURRENCY='/netapp/home/snayfach/concurrency'
FASTQ_DUMP='/pollard/shattuck0/snayfach/packages/sratoolkit.2.3.3-4-ubuntu64/bin/fastq-dump'
D_SRA='${MY_DIR}/sra'
D_FASTQ='${MY_DIR}/fastq'
P_SRA=\`ls \${D_SRA}/*.sra | sed -n \${SGE_TASK_ID}p\`
SRA=\`basename \$P_SRA\`
RUN=\`echo \$SRA | sed 's/.sra//'\`

# create tempdir on scratch
TMPDIR=/scratch
SCRATCH_DIR=\`mktemp -d\`
cd \$SCRATCH_DIR

# ***** control shattuck I/O
# *****
while [ \`ls -1 \$CONCURRENCY | wc -l\` -gt \$N_CONCURRENT_READS ]; do
    sleep 15
done
# copy SRA file
touch \${CONCURRENCY}/\${SGE_TASK_ID}
cp -r \$P_SRA ./
rm \${CONCURRENCY}/\${SGE_TASK_ID}
# *****
# ***** control shattuck I/O

# fastq-dump
\$FASTQ_DUMP --split-3 --gzip \$SRA >> \${RUN}.log 2>&1
rm \$SRA

# ***** control shattuck I/O
# *****
while [ \`ls -1 \$CONCURRENCY | wc -l\` -gt \$N_CONCURRENT_READS ]; do
    sleep 15
done
# copy SRA file
touch \${CONCURRENCY}/\${SGE_TASK_ID}
cp * \$D_FASTQ
rm \${CONCURRENCY}/\${SGE_TASK_ID}
# *****
# ***** control shattuck I/O

#cleanup scratch
rm -r \$SCRATCH_DIR

" >> $MY_SCRIPT