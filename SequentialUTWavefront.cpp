#include <iostream>
#include <cmath>
#include <vector>
#include <stdexcept>
#include <hpc_helpers.hpp>  // Include the custom helper header file

using namespace std;

// Class to handle matrix operations
class Matrix {
public:
    // Constructor to initialize matrix size and allocate memory
    explicit Matrix(uint64_t size, bool debug = false) : size_(size), debugMode_(debug) {
        if (size_ == 0) {
            throw invalid_argument("Matrix size must be greater than 0.");
        }
        matrix_.resize(size_ * size_, 0.0);
        initMatrix();
    }

    // Function to initialize the matrix with appropriate values
    void initMatrix() {
        for (uint64_t row = 0; row < size_; ++row) {
            for (uint64_t col = 0; col < size_; ++col) {
                matrix_[row * size_ + col] = (row == col) ? (row + 1) / static_cast<double>(size_) : 0.0;
            }
        }
        if (debugMode_) {
            cout << "Matrix initialized." << endl;
            printMatrix();
        }
    }

    // Function to print the matrix (for debugging)
    void printMatrix() const {
        cout << "Resulting Matrix:" << endl;
        for (uint64_t row = 0; row < size_; ++row) {
            for (uint64_t col = 0; col < size_; ++col) {
                cout << matrix_[row * size_ + col] << " ";
            }
            cout << endl;
        }
    }

    // Perform wavefront computation
    void computeWavefront() {
        for (uint64_t k = 1; k < size_; ++k) {
            for (uint64_t row = 0; row < size_ - k; ++row) {
                double dotProduct = 0.0;
                for (uint64_t j = 1; j < k + 1; ++j) {
                    dotProduct += matrix_[row * size_ + (row + k - j)] * matrix_[(row + j) * size_ + (row + k)];
                }
                matrix_[row * size_ + (row + k)] = cbrt(dotProduct);

                if (debugMode_) {
                    cout << "Updated Matrix[" << row << "][" << (row + k) << "] = "
                         << matrix_[row * size_ + (row + k)] << endl;
                }
            }
        }
    }

    // Retrieve specific matrix element (for result verification)
    double getElement(uint64_t row, uint64_t col) const {
        return matrix_[row * size_ + col];
    }

private:
    uint64_t size_;            // Matrix size
    vector<double> matrix_;    // Flattened matrix storage
    bool debugMode_;           // Debugging flag
};

// Command-line argument parsing
bool parseArgs(int argc, char* argv[], uint64_t& matrixSize, bool& debugMode) {
    matrixSize = 512;  // Default size
    debugMode = false;

    for (int i = 1; i < argc; ++i) {
        string arg = argv[i];
        if (arg == "--debug" || arg == "-d") {
            debugMode = true;
        } else {
            try {
                matrixSize = stoul(argv[i]);
                if (matrixSize == 0) {
                    throw invalid_argument("Matrix size must be positive.");
                }
            } catch (const exception& e) {
                cerr << "Invalid argument: " << argv[i] << endl;
                return false;
            }
        }
    }
    return true;
}

// Main function
int main(int argc, char* argv[]) {
    uint64_t matrixSize;
    bool debugMode;

    if (!parseArgs(argc, argv, matrixSize, debugMode)) {
        cerr << "Usage: " << argv[0] << " [matrix_size] [--debug/-d]" << endl;
        return EXIT_FAILURE;
    }

    try {
        Matrix matrix(matrixSize, debugMode);

        TIMERSTART(wavefront);
        matrix.computeWavefront();
        TIMERSTOP(wavefront);

        cout << "Last element of the matrix: "
             << matrix.getElement(matrixSize - 1, matrixSize - 1) << endl;

    } catch (const exception& e) {
        cerr << "Error: " << e.what() << endl;
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}

