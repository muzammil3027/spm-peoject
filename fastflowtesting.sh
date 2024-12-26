#!/bin/sh
#SBATCH -p normal
#SBATCH -N 1                          # 1 node
#SBATCH --ntasks=1                    # 1 task (FastFlow is not MPI-based)
#SBATCH --cpus-per-task=8             # How many CPU cores for this task
#SBATCH -o ./%j-ff.log                # Standard output goes here
#SBATCH -e ./%j-ff.err                # Standard error goes here
#SBATCH -t 02:00:00                   # 2 hours of runtime

# ------------------------------------------------------------------------------
# 1. The first argument is the matrix size; default = 512
# 2. The second argument is the number of threads; default = 8
#    Example usage: sbatch fastflowtesting.sh 1024 16
# ------------------------------------------------------------------------------
ARGS=${1:-512}
THREADS=${2:-8}

echo "Test executed on: $SLURM_JOB_NODELIST"
echo "Matrix size: $ARGS"
echo "Number of threads: $THREADS"

# Compile the FastFlow code (if needed)
make FFUTWavefront

# Run the FastFlow program
./FFUTWavefront "$ARGS" "$THREADS" > temp_fastflow_output.txt

# Print the output into the log
cat temp_fastflow_output.txt

echo "done"

