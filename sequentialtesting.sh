#!/bin/sh
#SBATCH -p normal
#SBATCH -N 1
#SBATCH --ntasks=1                  # Only one task (sequential)
#SBATCH --cpus-per-task=1           # Number of CPUs per task (1 CPU per process)
#SBATCH -o ./%j-seq.log
#SBATCH -e ./%j-seq.err
#SBATCH -t 02:00:00

echo "Test executed on: $SLURM_JOB_NODELIST"

# Compile the sequential program
make SequentialUTWavefront

# Run multiple tests with different thread count or matrix sizes
make run_multiple_tests FILE="SequentialUTWavefront.o" ARGS=$1

echo "done"

