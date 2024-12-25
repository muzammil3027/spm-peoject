#include <iostream>
#include <cmath>
#include <cstring>
#include <mpi.h>

using namespace std;

// Matrix class to encapsulate matrix operations and computations
class Matrix {
public:
    // Constructor to initialize matrix size and allocate memory
    Matrix(uint64_t size) : size_(size) {
        // Allocate memory for the matrix
        matrix_ = new double[size_ * size_];
        // Initialize the matrix with diagonal elements
        initMatrix();
    }

    // Destructor to free dynamically allocated memory
    ~Matrix() {
        delete[] matrix_;
    }

    // Function to initialize the matrix with appropriate values
    void initMatrix() {
        for (uint64_t i = 0; i < size_; i++) {
            for (uint64_t j = 0; j < size_; j++) {
                if (j == i)  // Diagonal elements
                    matrix_[i * size_ + j] = (i + 1) / static_cast<double>(size_);
                else  // Off-diagonal elements
                    matrix_[i * size_ + j] = 0.0;
            }
        }
    }

    // Function to perform wavefront computation
    void computeWavefront(MPI_Comm comm, int myRank, int size) {
        for (uint64_t k = 1; k < size_; ++k) {
            // Divide work for each process based on the diagonal (k)
            int rowsPerProcess = (size_ - k) / size;
            int extraRows = (size_ - k) % size;
            int rowsToProcess = rowsPerProcess + (myRank < extraRows ? 1 : 0);

            // Buffer arrays to hold computed values for each process
            double* valuesToSend = new double[rowsToProcess];
            int* indices = new int[rowsToProcess];

            // Calculate start index for this process
            int startIndex = myRank * rowsPerProcess + std::min(myRank, extraRows);
            int counter = 0;

            // Perform dot product computation for each row assigned to the process
            for (int i = startIndex; i < startIndex + rowsToProcess; ++i) {
                double dotProduct = 0.0;
                // Compute the dot product for the current diagonal band
                for (uint64_t j = 1; j < k + 1; ++j) {
                    dotProduct += matrix_[i * size_ + (i + k - j)] * matrix_[(i + j) * size_ + (i + k)];
                }
                // Update the matrix value with the cube root of the dot product
                matrix_[i * size_ + (i + k)] = cbrt(dotProduct);

                // Store computed values to be gathered later
                valuesToSend[counter] = matrix_[i * size_ + (i + k)];
                indices[counter] = i;
                counter++;
            }

            // Gather computed values from all processes
            gatherResults(comm, valuesToSend, indices, rowsToProcess, k);
        }
    }

    // Function to gather results from all processes after computation
    void gatherResults(MPI_Comm comm, double* valuesToSend, int* indices, int numElements, uint64_t k) {
        int size;
        MPI_Comm_size(comm, &size);

        // Arrays to hold the number of elements from each process and displacements for gather
        int* recvCounts = new int[size];
        MPI_Allgather(&numElements, 1, MPI_INT, recvCounts, 1, MPI_INT, comm);

        int* displs = new int[size];
        int totalElements = 0;
        for (int i = 0; i < size; ++i) {
            displs[i] = totalElements;
            totalElements += recvCounts[i];
        }

        // Arrays to hold gathered values and indices
        double* gatheredValues = new double[totalElements];
        int* gatheredIndices = new int[totalElements];

        // Gather the results from all processes
        MPI_Allgatherv(valuesToSend, numElements, MPI_DOUBLE,
                        gatheredValues, recvCounts, displs, MPI_DOUBLE, comm);
        MPI_Allgatherv(indices, numElements, MPI_INT,
                        gatheredIndices, recvCounts, displs, MPI_INT, comm);

        // Update the matrix with the gathered values
        for (int i = 0; i < totalElements; ++i) {
            matrix_[gatheredIndices[i] * size_ + (gatheredIndices[i] + k)] = gatheredValues[i];
        }

        // Clean up memory allocations for gathering
        delete[] recvCounts;
        delete[] displs;
        delete[] gatheredValues;
        delete[] gatheredIndices;
    }

    // Function to retrieve a specific element from the matrix (for checking results)
    double getElement(uint64_t row, uint64_t col) const {
        return matrix_[row * size_ + col];
    }

private:
    uint64_t size_;       // Matrix size (NxN)
    double *matrix_;      // Pointer to the matrix data
};

// Main function that runs the program
int main(int argc, char *argv[]) {
    MPI_Init(&argc, &argv);  // Initialize MPI

    int myRank, size;
    MPI_Comm_rank(MPI_COMM_WORLD, &myRank);  // Get the rank of this process
    MPI_Comm_size(MPI_COMM_WORLD, &size);    // Get the number of processes

    uint64_t matrixSize = 512;    // Default size of the matrix (NxN)

    // Check if the correct number of arguments is passed
    if (argc != 1 && argc != 2 && argc != 3) {
        if (myRank == 0) {
            std::printf("Usage: %s N\n", argv[0]);
            std::printf("  N: Size of the square matrix\n");
        }
        MPI_Finalize();
        return -1;
    }

    if (argc > 1) {
        matrixSize = std::stol(argv[1]);
    }

    // Create a matrix object with the specified size
    Matrix matrix(matrixSize);

    // Start measuring time
    double startTime = MPI_Wtime();

    // Perform the wavefront computation using MPI
    matrix.computeWavefront(MPI_COMM_WORLD, myRank, size);

    // Stop measuring time
    double endTime = MPI_Wtime();

    // Print the results (only from the root process)
    if (myRank == 0) {
        std::cout << "# Elapsed time (wavefront): " << endTime - startTime << "s" << std::endl;
        std::cout << "Last element of the matrix: " << matrix.getElement(matrixSize - 1, matrixSize - 1) << std::endl;
    }

    // Finalize MPI and clean up
    MPI_Finalize();
    return 0;
}

