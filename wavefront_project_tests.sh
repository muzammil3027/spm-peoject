#!/bin/bash

# Parameters
iterations=120
matrix_sizes=(512 1024 2048 4096)
max_slots=$(nproc)  # Determine the number of available logical CPUs dynamically
workers=(1 2 4 8 16 32 $max_slots)  # Respect system limits

# Executables
mpi_executable=./BroadMPIUTWavefront
fastflow_executable=./FFUTWavefront
sequential_executable=./SequentialUTWavefront

# Function to run tests
run_tests() {
    implementation=$1
    executable=$2
    size=$3
    iterations=$4
    workers=$5

    if [ "$implementation" = "MPI" ]; then
        if [ $workers -le $max_slots ]; then
            echo "Running MPI Implementation with $workers processes"
            mpirun -np $workers $executable $size > results_${implementation}_${size}_${workers}.log
        else
            echo "Skipping MPI Implementation for $workers processes: exceeds available slots ($max_slots)"
        fi
    elif [ "$implementation" = "FastFlow" ]; then
        echo "Running FastFlow Implementation with $workers workers"
        $executable $size $workers > results_${implementation}_${size}_${workers}.log
    elif [ "$implementation" = "Sequential" ]; then
        echo "Running Sequential Implementation"
        $executable $size > results_${implementation}_${size}.log
    fi
}

# Testing by Matrix Sizes
echo "Testing by Matrix Sizes"
for size in "${matrix_sizes[@]}"; do
    echo "Matrix Size: $size"

    # Sequential
    if [ "$size" -lt 4096 ]; then
        run_tests "Sequential" $sequential_executable $size $iterations 1
    else
        echo "Skipping Sequential Implementation for Matrix Size $size"
    fi

    # FastFlow
    for w in "${workers[@]}"; do
        run_tests "FastFlow" $fastflow_executable $size $iterations $w
    done

    # MPI
    for w in "${workers[@]}"; do
        run_tests "MPI" $mpi_executable $size $iterations $w
    done
done

# Testing by Number of Iterations
echo "Testing by Iterations"
iterations_set=(10 20 40 60 80 100 120)
size=1024  # Fixed size for iteration tests

for i in "${iterations_set[@]}"; do
    echo "Iterations: $i"

    # Sequential
    run_tests "Sequential" $sequential_executable $size $i 1

    # FastFlow
    for w in "${workers[@]}"; do
        run_tests "FastFlow" $fastflow_executable $size $i $w
    done

    # MPI
    for w in "${workers[@]}"; do
        run_tests "MPI" $mpi_executable $size $i $w
    done
done

# Testing by Workers
echo "Testing by Workers"
size=2048  # Fixed size for worker tests

for w in "${workers[@]}"; do
    echo "Workers: $w"

    # FastFlow
    run_tests "FastFlow" $fastflow_executable $size $iterations $w

    # MPI
    if [ $w -le $max_slots ]; then
        run_tests "MPI" $mpi_executable $size $iterations $w
    else
        echo "Skipping MPI Implementation for $w processes: exceeds available slots ($max_slots)"
    fi
done

