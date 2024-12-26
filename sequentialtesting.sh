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

# Set ARGS to default if not provided
ARGS=${1:-512}

# Run the program directly to ensure timing is captured
./SequentialUTWavefront $ARGS > temp_sequential_output.txt

# Display output in the log
cat temp_sequential_output.txt

echo "done"

