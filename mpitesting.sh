#!/bin/sh
#SBATCH -p normal
#SBATCH -N 1                     # Number of nodes
#SBATCH --cpus-per-task=1        # CPUs per task
#SBATCH -o ./%j-mpi.log
#SBATCH -e ./%j-mpi.err
#SBATCH -t 02:00:00

# Set number of tasks and matrix size from input arguments or use defaults
SLURM_NTASKS=${1:-8}  # Default to 8 tasks if not provided
ARGS=${2:-512}         # Default to matrix size 512 if not provided

echo "Test executed on: $SLURM_JOB_NODELIST with $SLURM_NTASKS tasks"

# Compile the MPI program
make BroadMPIUTWavefront

# Run the program and capture output
mpirun -np $SLURM_NTASKS ./BroadMPIUTWavefront $ARGS > temp_parallel_output.txt

# Display output in the log
cat temp_parallel_output.txt

echo "done"

