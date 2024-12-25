#!/bin/sh
#SBATCH -p normal
#SBATCH -N 1
#SBATCH --ntasks=8                  # Number of MPI processes (distribute over 8 tasks)
#SBATCH --cpus-per-task=1           # Number of CPUs per task (1 CPU per process)
#SBATCH -o ./%j-mpi.log
#SBATCH -e ./%j-mpi.err
#SBATCH -t 02:00:00

echo "Test executed on: $SLURM_JOB_NODELIST with $SLURM_NTASKS"

# Compile the MPI program
make BroadMPIUTWavefront

# Run multiple tests with different thread count or matrix sizes
make run_multiple_tests FILE="BroadMPIUTWavefront.o" ARGS=$1

echo "done"

