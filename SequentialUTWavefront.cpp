#include <iostream>
#include <cmath>
#include <vector>
#include <stdexcept>
#include "hpc_helpers.hpp"  // Include the custom helper header file

using namespace std;

// Class to handle matrix operations
class Matrix {
public:
    explicit Matrix(uint64_t size, bool debug = false)
        : size_(size), debugMode_(debug) {
        if (size_ == 0) {
            throw invalid_argument("Matrix size must be greater than 0.");
        }
        matrix_.resize(size_ * size_, 0.0);
        initMatrix();
    }

    void initMatrix() {
        for (uint64_t row = 0; row < size_; ++row) {
            for (uint64_t col = 0; col < size_; ++col) {
                matrix_[row * size_ + col] = (row == col)
                    ? (row + 1) / static_cast<double>(size_)
                    : 0.0;
            }
        }
        if (debugMode_) {
            cout << "Matrix initialized." << endl;
            printMatrix();
        }
    }

    void printMatrix() const {
        if (!debugMode_) return;
        cout << "Matrix:" << endl;
        for (uint64_t row = 0; row < size_; ++row) {
            for (uint64_t col = 0; col < size_; ++col) {
                cout << matrix_[row * size_ + col] << " ";
            }
            cout << endl;
        }
    }

    void computeWavefront() {
        for (uint64_t k = 1; k < size_; ++k) {
            for (uint64_t row = 0; row < size_ - k; ++row) {
                double dotProduct = 0.0;
                for (uint64_t j = 1; j <= k; ++j) {
                    dotProduct += matrix_[row * size_ + (row + k - j)]
                                * matrix_[(row + j) * size_ + (row + k)];
                }
                matrix_[row * size_ + (row + k)] = cbrt(dotProduct);
            }
        }
    }

    double getElement(uint64_t row, uint64_t col) const {
        return matrix_[row * size_ + col];
    }

private:
    uint64_t size_;
    vector<double> matrix_;
    bool debugMode_;
};

int main(int argc, char* argv[]) {
    uint64_t matrixSize = 512;  // Default size
    bool debugMode = false;     // Debugging off by default

    if (argc > 1) {
        try {
            matrixSize = stoul(argv[1]);
            if (matrixSize == 0) {
                throw invalid_argument("Matrix size must be greater than 0.");
            }
        } catch (const exception& e) {
            cerr << "Invalid matrix size: " << argv[1] << ". Exiting." << endl;
            return EXIT_FAILURE;
        }
    }

    try {
        cout << "Running Sequential Implementation..." << endl;
        cout << "Matrix Size: " << matrixSize << endl;

        Matrix matrix(matrixSize, debugMode);

        // Timing the wavefront computation
        TIMERSTART(wavefront_time);
        matrix.computeWavefront();
        TIMERSTOP(wavefront_time);

        // Print results
        cout << "Workers: 1" << endl;
        cout << "Matrix Size: " << matrixSize << endl;
        cout << "Last element of the matrix: "
             << matrix.getElement(matrixSize - 1, matrixSize - 1) << endl;

    } catch (const exception& e) {
        cerr << "Error: " << e.what() << endl;
        return EXIT_FAILURE;
    }

    return EXIT_SUCCESS;
}

