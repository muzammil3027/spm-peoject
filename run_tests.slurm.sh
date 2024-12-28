#!/bin/bash
#SBATCH --job-name=wavefront_tests      # Job name
#SBATCH --output=results_%j.out         # Standard output log
#SBATCH --error=results_%j.err          # Standard error log
#SBATCH --ntasks=1                      # Number of tasks (1 for sequential/fastflow)
#SBATCH --cpus-per-task=16              # Number of CPUs for the task
#SBATCH --time=02:00:00                 # Time limit (hh:mm:ss)
#SBATCH --partition=normal              # Partition name

# Load required modules (if applicable)
module load mpi/openmpi

# Set parameters
iterations=120
matrix_sizes=(512 1024 2048 4096)
max_workers=16  # Based on cpus-per-task

# Executables
mpi_executable=./BroadMPIUTWavefront
fastflow_executable=./FFUTWavefront
sequential_executable=./SequentialUTWavefront

# Run Sequential Tests
for size in "${matrix_sizes[@]}"; do
    if [ "$size" -lt 4096 ]; then
        echo "Running Sequential Implementation for Matrix Size $size"
        ./SequentialUTWavefront $size
    else
        echo "Skipping Sequential Implementation for Matrix Size $size"
    fi
done

# Run FastFlow Tests
for size in "${matrix_sizes[@]}"; do
    for workers in 1 2 4 8 $max_workers; do
        echo "Running FastFlow Implementation: Matrix Size=$size, Workers=$workers"
        ./FFUTWavefront $size $workers
    done
done

# Run MPI Tests
for size in "${matrix_sizes[@]}"; do
    for workers in 1 2 4 8 $max_workers; do
        echo "Running MPI Implementation: Matrix Size=$size, Processes=$workers"
        mpirun -np $workers ./BroadMPIUTWavefront $size
    done
done

