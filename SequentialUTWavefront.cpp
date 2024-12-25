#include <iostream>
#include <cmath>
#include <vector>
#include <hpc_helpers.hpp>  // Include the custom helper header file

using namespace std;

// Class to handle matrix operations (initialization, computation, etc.)
class Matrix {
public:
    // Constructor to initialize matrix size and allocate memory
    Matrix(uint64_t size) : size_(size) {
        matrix_ = new double[size_ * size_];
        initMatrix();
    }

    // Destructor to free dynamically allocated memory
    ~Matrix() {
        delete[] matrix_;
    }

    // Function to initialize the matrix with appropriate values
    void initMatrix() {
        for (uint64_t row = 0; row < size_; row++) {
            for (uint64_t col = 0; col < size_; col++) {
                // Set diagonal elements and zero out non-diagonal elements
                if (row == col) {
                    matrix_[row * size_ + col] = (row + 1) / static_cast<double>(size_);
                } else {
                    matrix_[row * size_ + col] = 0.0;
                }
            }
        }
    }

    // Function to print the matrix (for debugging)
    void printMatrix() const {
        printf("Resulting Matrix:\n");
        for (uint64_t row = 0; row < size_; ++row) {
            for (uint64_t col = 0; col < size_; ++col) {
                printf("%f ", matrix_[row * size_ + col]);
            }
            printf("\n");
        }
    }

    // Function to perform wavefront computation
    void computeWavefront(bool debugMode) {
        for (uint64_t k = 1; k < size_; ++k) {
            for (uint64_t row = 0; row < size_ - k; ++row) {
                double dotProduct = 0.0;
                // Compute the dot product for the current diagonal band
                for (uint64_t j = 1; j < k + 1; ++j) {
                    dotProduct += matrix_[row * size_ + (row + k - j)] * matrix_[(row + j) * size_ + (row + k)];
                }

                if (debugMode) {
                    // Debugging: print the values before the update
                    std::cout << "Dot product for k = " << k << ", row = " << row 
                              << ": " << dotProduct << std::endl;
                }
                
                // Update the matrix with the cube root of the dot product
                matrix_[row * size_ + (row + k)] = cbrt(dotProduct);

                if (debugMode) {
                    // Debugging: print the matrix element after the update
                    std::cout << "Matrix element at [" << row << ", " << (row + k) 
                              << "] updated to: " << matrix_[row * size_ + (row + k)] << std::endl;
                }
            }
        }
    }

    // Function to retrieve a specific element from the matrix (for checking results)
    double getElement(uint64_t row, uint64_t col) const {
        return matrix_[row * size_ + col];
    }

private:
    uint64_t size_;       // Matrix size (NxN)
    double *matrix_;      // Pointer to the matrix
};

// Function to parse command line arguments
bool parseArgs(int argc, char* argv[], uint64_t& matrixSize, bool& debugMode) {
    // Default values
    matrixSize = 512;  // Default size of the matrix
    debugMode = false; // Default to no debug mode

    for (int i = 1; i < argc; ++i) {
        if (string(argv[i]) == "--debug" || string(argv[i]) == "-d") {
            debugMode = true;
        } else {
            try {
                matrixSize = std::stol(argv[i]);
            } catch (const std::invalid_argument&) {
                std::cerr << "Invalid argument: " << argv[i] << std::endl;
                return false;
            }
        }
    }
    return true;
}

// Main function that runs the program
int main(int argc, char *argv[]) {
    uint64_t matrixSize;  // Matrix size (NxN)
    bool debugMode;       // Flag to enable debug mode

    // Parse command line arguments
    if (!parseArgs(argc, argv, matrixSize, debugMode)) {
        std::cout << "Usage: " << argv[0] << " [matrix_size] [--debug/-d]" << std::endl;
        return -1;
    }

    // Create a matrix object with the specified size
    Matrix matrix(matrixSize);

    // Start the timer for the wavefront computation
    TIMERSTART(wavefront);

    // Perform the wavefront computation (with or without debug mode)
    matrix.computeWavefront(debugMode);

    // Stop the timer and print the elapsed time
    TIMERSTOP(wavefront);

    // Optionally, print the entire matrix (disabled for large matrices)
    // matrix.printMatrix();

    // Print the last element of the matrix to check the result of the computation
    std::cout << "Last element of the matrix: " 
              << matrix.getElement(matrixSize - 1, matrixSize - 1) << std::endl;

    return 0;
}

