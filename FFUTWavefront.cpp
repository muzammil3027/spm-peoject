#include <iostream>
#include <cmath>
#include <vector>
#include <stdexcept>       // for std::invalid_argument
#include <ff/parallel_for.hpp>
#include "hpc_helpers.hpp" // <-- ensure this has TIMERSTART/TIMERSTOP macros

#define MAX_THREADS 32

using namespace ff;

// A class to encapsulate the NxN matrix and wavefront logic
class Matrix {
public:
    // Constructor: allocate and initialize the matrix
    Matrix(uint64_t size, int threads, bool debug = false)
        : size_(size), numThreads_(threads), debugMode_(debug) {
        if (size_ == 0) {
            throw std::invalid_argument("Matrix size must be greater than 0.");
        }
        matrix_.resize(size_ * size_, 0.0);
        initMatrix();
    }

    // Initialize the diagonal to (row+1)/size, rest to 0
    void initMatrix() {
        for (uint64_t row = 0; row < size_; ++row) {
            for (uint64_t col = 0; col < size_; ++col) {
                matrix_[row * size_ + col] = (row == col)
                    ? (row + 1) / static_cast<double>(size_)
                    : 0.0;
            }
        }
        if (debugMode_) {
            std::cout << "Matrix initialized." << std::endl;
            printMatrix();
        }
    }

    // Optional: Print the matrix contents (for debug)
    void printMatrix() const {
        std::cout << "Resulting Matrix:" << std::endl;
        for (uint64_t row = 0; row < size_; ++row) {
            for (uint64_t col = 0; col < size_; ++col) {
                std::cout << matrix_[row * size_ + col] << " ";
            }
            std::cout << std::endl;
        }
    }

    // Perform the wavefront computation using FastFlow ParallelFor
    void computeWavefront() {
        ParallelFor pf(numThreads_, /*spin waiting*/ true, /*reduce only*/ true);

        for (uint64_t k = 1; k < size_; ++k) {
            // Adjust the number of threads dynamically based on diagonal size
            if ((uint64_t)numThreads_ > (size_ - k) && numThreads_ > 1) {
                --numThreads_;
            }

            // For each diagonal iteration, run parallel_for over rows [0..(size_-k-1)]
            pf.parallel_for(0, size_ - k, 1, [&, k](uint64_t row) {
                double dotProduct = 0.0;
                // Summation from j=1..k (this was your original approach)
                // If you want j=0..k, replace with j=0; j <= k
                for (uint64_t j = 1; j < k + 1; ++j) {
                    dotProduct += matrix_[row * size_ + (row + k - j)]
                                * matrix_[(row + j) * size_ + (row + k)];
                }
                matrix_[row * size_ + (row + k)] = cbrt(dotProduct);

                if (debugMode_) {
                    std::cout << "Updated M[" << row << "][" << (row + k)
                              << "] = " << matrix_[row * size_ + (row + k)]
                              << std::endl;
                }
            }, numThreads_);
        }
    }

    // Get the value at a specific (row, col)
    double getElement(uint64_t row, uint64_t col) const {
        return matrix_[row * size_ + col];
    }

private:
    uint64_t size_;              // Dimension (N)
    std::vector<double> matrix_; // Matrix storage: size_ x size_
    int numThreads_;             // Current number of threads
    bool debugMode_;             // Verbose debugging
};

// Command-line argument parsing
bool parseArgs(int argc, char* argv[], uint64_t& matrixSize, int& numThreads, bool& debugMode) {
    matrixSize = 512;       // Default size
    numThreads = MAX_THREADS; 
    debugMode = false;

    for (int i = 1; i < argc; ++i) {
        std::string arg = argv[i];
        if (arg == "--debug" || arg == "-d") {
            debugMode = true;
        } else {
            try {
                if (matrixSize == 512) {
                    matrixSize = std::stoul(arg);  // parse matrix size
                } else {
                    numThreads = std::stoi(arg);   // parse number of threads
                }
            } catch (const std::exception& e) {
                std::cerr << "Invalid argument: " << argv[i] << std::endl;
                return false;
            }
        }
    }
    return true;
}

int main(int argc, char* argv[]) {
    uint64_t matrixSize;
    int numThreads;
    bool debugMode;

    if (!parseArgs(argc, argv, matrixSize, numThreads, debugMode)) {
        std::cerr << "Usage: " << argv[0] << " [matrix_size] [num_threads] [--debug/-d]"
                  << std::endl;
        return EXIT_FAILURE;
    }

    try {
        Matrix matrix(matrixSize, numThreads, debugMode);

        // Start timing (macro from your hpc_helpers.hpp)
        TIMERSTART(wavefront);

        // Wavefront computation
        matrix.computeWavefront();

        // Stop timing (macro prints elapsed time automatically or you can change it)
        TIMERSTOP(wavefront);

        // Print a result: the bottom-right corner (row=N-1, col=N-1)
        std::cout << "Last element of the matrix: "
                  << matrix.getElement(matrixSize - 1, matrixSize - 1)
                  << std::endl;

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}
