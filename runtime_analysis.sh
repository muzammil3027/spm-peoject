#!/bin/bash

# Output file for results
OUTPUT_FILE="runtime_results.csv"

# Write header to CSV file
echo "Matrix Size,Type,Configuration,Execution Time (s)" > $OUTPUT_FILE

# Matrix sizes to test
MATRIX_SIZES=(512)

# Sequential Execution
echo "Running Sequential Tests..."
for size in "${MATRIX_SIZES[@]}"; do
    # Run the sequential implementation and extract the execution time
    TIME=$(./SequentialUTWavefront $size | grep "Elapsed Time" | awk '{print $3}')
    echo "$size,Sequential,1 Core,$TIME" >> $OUTPUT_FILE
done

# FastFlow Execution
echo "Running FastFlow Tests..."
THREADS=(2 4 ) # Number of threads to test
for size in "${MATRIX_SIZES[@]}"; do
    for thread in "${THREADS[@]}"; do
        # Run the FastFlow implementation and extract the execution time
        TIME=$(./FFUTWavefront $size $thread | grep "Elapsed Time" | awk '{print $3}')
        echo "$size,FastFlow,$thread Threads,$TIME" >> $OUTPUT_FILE
    done
done

# MPI Execution
echo "Running MPI Tests..."
PROCESSES=(2 4 8 16 20 40) # Number of processes to test
for size in "${MATRIX_SIZES[@]}"; do
    for proc in "${PROCESSES[@]}"; do
        # Run the MPI implementation and extract the execution time
        TIME=$(mpirun -np $proc ./BroadMPIUTWavefront $size | grep "Elapsed Time" | awk '{print $3}')
        echo "$size,MPI,$proc Processes,$TIME" >> $OUTPUT_FILE
    done
done

echo "All tests completed. Results saved in $OUTPUT_FILE."

