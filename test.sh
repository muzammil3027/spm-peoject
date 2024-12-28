#!/bin/bash
#SBATCH -p normal                       # Partition name
#SBATCH -N 1                            # Number of nodes (default: 1)
#SBATCH --ntasks=32                     # Max tasks (logical CPUs) per node
#SBATCH -o ./%j-combined.log            # Standard output log
#SBATCH -e ./%j-combined.err            # Standard error log
#SBATCH -t 02:00:00                     # Time limit (2 hours)

# Parameters
matrix_sizes=(512 1024 2048 4096)       # Matrix sizes to test
workers=(1 2 4 8 16 32)                # Worker counts per node
iterations=10                          # Number of iterations

# Compile all programs
echo "Compiling programs..."
make all                                # Compile Sequential, FastFlow, and MPI implementations

# Function to run tests dynamically
run_tests() {
    implementation=$1
    executable=$2
    size=$3
    workers=$4
    test_type=$5  # e.g., "sequential", "fastflow", "mpi"

    log_file="results_${implementation}_${test_type}_${size}_${workers}.log"

    if [ "$implementation" = "MPI" ]; then
        echo "Running MPI: Matrix Size=$size, Processes=$workers"
        mpirun -np $workers $executable $size > $log_file
    elif [ "$implementation" = "FastFlow" ]; then
        echo "Running FastFlow: Matrix Size=$size, Workers=$workers"
        $executable $size $workers > $log_file
    elif [ "$implementation" = "Sequential" ]; then
        echo "Running Sequential: Matrix Size=$size"
        $executable $size > $log_file
    fi
}

# Sequential Tests
echo "Starting Sequential Tests..."
for size in "${matrix_sizes[@]}"; do
    run_tests "Sequential" ./SequentialUTWavefront $size 1 "sequential"
done

# FastFlow Tests
echo "Starting FastFlow Tests..."
for size in "${matrix_sizes[@]}"; do
    for worker in "${workers[@]}"; do
        run_tests "FastFlow" ./FFUTWavefront $size $worker "fastflow"
    done
done

# MPI Tests
echo "Starting MPI Tests..."
for size in "${matrix_sizes[@]}"; do
    for worker in "${workers[@]}"; do
        run_tests "MPI" ./BroadMPIUTWavefront $size $worker "mpi"
    done
done

echo "All tests completed!"

