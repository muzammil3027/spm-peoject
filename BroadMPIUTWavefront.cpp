#include <iostream>
#include <cmath>
#include <cstring>
#include <mpi.h>
#include "hpc_helpers.hpp" // Include timing macros

using namespace std;

class Matrix {
public:
    Matrix(uint64_t size) : size_(size) {
        matrix_ = new double[size_ * size_];
        initMatrix();
    }

    ~Matrix() {
        delete[] matrix_;
    }

    void initMatrix() {
        for (uint64_t i = 0; i < size_; i++) {
            for (uint64_t j = 0; j < size_; j++) {
                if (j == i)
                    matrix_[i * size_ + j] = (i + 1) / static_cast<double>(size_);
                else
                    matrix_[i * size_ + j] = 0.0;
            }
        }
    }

    void computeWavefront(MPI_Comm comm, int myRank, int numProcs) {
        for (uint64_t k = 1; k < size_; ++k) {
            int rowsPerProcess = (size_ - k) / numProcs;
            int extraRows = (size_ - k) % numProcs;
            int rowsToProcess = rowsPerProcess + (myRank < extraRows ? 1 : 0);

            double* valuesToSend = new double[rowsToProcess];
            int* indices = new int[rowsToProcess];

            int startIndex = myRank * rowsPerProcess + min(myRank, extraRows);
            int counter = 0;

            for (int i = startIndex; i < startIndex + rowsToProcess; ++i) {
                double dotProduct = 0.0;
                for (uint64_t j = 1; j < k + 1; ++j) {
                    dotProduct += matrix_[i * size_ + (i + k - j)] * matrix_[(i + j) * size_ + (i + k)];
                }
                matrix_[i * size_ + (i + k)] = cbrt(dotProduct);
                valuesToSend[counter] = matrix_[i * size_ + (i + k)];
                indices[counter] = i;
                counter++;
            }

            gatherResults(comm, valuesToSend, indices, rowsToProcess, k);

            delete[] valuesToSend;
            delete[] indices;
        }
    }

    void gatherResults(MPI_Comm comm, double* valuesToSend, int* indices, int numElements, uint64_t k) {
        int numProcs;
        MPI_Comm_size(comm, &numProcs);

        int* recvCounts = new int[numProcs];
        MPI_Allgather(&numElements, 1, MPI_INT, recvCounts, 1, MPI_INT, comm);

        int* displs = new int[numProcs];
        int totalElements = 0;
        for (int i = 0; i < numProcs; ++i) {
            displs[i] = totalElements;
            totalElements += recvCounts[i];
        }

        double* gatheredValues = new double[totalElements];
        int* gatheredIndices = new int[totalElements];

        MPI_Allgatherv(valuesToSend, numElements, MPI_DOUBLE,
                       gatheredValues, recvCounts, displs, MPI_DOUBLE, comm);
        MPI_Allgatherv(indices, numElements, MPI_INT,
                       gatheredIndices, recvCounts, displs, MPI_INT, comm);

        for (int i = 0; i < totalElements; ++i) {
            matrix_[gatheredIndices[i] * size_ + (gatheredIndices[i] + k)] = gatheredValues[i];
        }

        delete[] recvCounts;
        delete[] displs;
        delete[] gatheredValues;
        delete[] gatheredIndices;
    }

    double getElement(uint64_t row, uint64_t col) const {
        return matrix_[row * size_ + col];
    }

private:
    uint64_t size_;
    double* matrix_;
};

int main(int argc, char* argv[]) {
    MPI_Init(&argc, &argv);

    int myRank, numProcs;
    MPI_Comm_rank(MPI_COMM_WORLD, &myRank);
    MPI_Comm_size(MPI_COMM_WORLD, &numProcs);

    uint64_t matrixSize = 512;

    if (argc > 1) {
        try {
            matrixSize = std::stol(argv[1]);
            if (matrixSize == 0) {
                throw invalid_argument("Matrix size must be positive.");
            }
        } catch (const exception& e) {
            if (myRank == 0) {
                cerr << "Invalid argument for matrix size. Usage: " << argv[0] << " [matrix_size]" << endl;
            }
            MPI_Finalize();
            return EXIT_FAILURE;
        }
    }

    MPI_Barrier(MPI_COMM_WORLD);
    double startTime = MPI_Wtime();

    Matrix matrix(matrixSize);
    matrix.computeWavefront(MPI_COMM_WORLD, myRank, numProcs);

    MPI_Barrier(MPI_COMM_WORLD);
    double endTime = MPI_Wtime();

    if (myRank == 0) {
        double elapsedTime = endTime - startTime;
        std::cout << "Running MPI Implementation..." << std::endl;
        std::cout << "Processes: " << numProcs << std::endl;
        std::cout << "Matrix Size: " << matrixSize << std::endl;
        std::cout << "# elapsed time (wavefront): " << elapsedTime << " seconds" << std::endl;
        std::cout << "Last element of the matrix: " << matrix.getElement(matrixSize - 1, matrixSize - 1) << std::endl;
    }

    MPI_Finalize();
    return 0;
}

