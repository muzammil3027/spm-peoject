#ifndef HPC_HELPERS_HPP
#define HPC_HELPERS_HPP

#include <iostream>
#include <cstdint>

#ifndef __CUDACC__
    #include <chrono>
#endif

// Define consistent macros for timer usage
#ifndef __CUDACC__
    // Start the timer
    #define TIMERSTART(label)                                                  \
        std::chrono::time_point<std::chrono::system_clock> a##label, b##label; \
        a##label = std::chrono::system_clock::now();

    // Stop the timer and output a consistent format
    #define TIMERSTOP(label)                                                   \
        b##label = std::chrono::system_clock::now();                           \
        std::chrono::duration<double> delta##label = b##label - a##label;      \
        std::cout << "# elapsed time: " << delta##label.count() << " seconds"  \
                  << std::endl;

#else
    // CUDA version of the timer macros
    #define TIMERSTART(label)                                                  \
        cudaEvent_t start##label, stop##label;                                 \
        float time##label;                                                     \
        cudaEventCreate(&start##label);                                        \
        cudaEventCreate(&stop##label);                                         \
        cudaEventRecord(start##label, 0);

    #define TIMERSTOP(label)                                                   \
        cudaEventRecord(stop##label, 0);                                       \
        cudaEventSynchronize(stop##label);                                     \
        cudaEventElapsedTime(&time##label, start##label, stop##label);         \
        std::cout << "# elapsed time: " << time##label / 1000.0 << " seconds"  \
                  << std::endl;
#endif


#ifdef __CUDACC__
    #define CUERR {                                                            \
        cudaError_t err;                                                       \
        if ((err = cudaGetLastError()) != cudaSuccess) {                       \
            std::cout << "CUDA error: " << cudaGetErrorString(err) << " : "    \
                      << __FILE__ << ", line " << __LINE__ << std::endl;       \
            exit(1);                                                           \
        }                                                                      \
    }

    // Transfer constants
    #define H2D (cudaMemcpyHostToDevice)
    #define D2H (cudaMemcpyDeviceToHost)
    #define H2H (cudaMemcpyHostToHost)
    #define D2D (cudaMemcpyDeviceToDevice)
#endif

// Safe division macro
#define SDIV(x,y) (((x) + (y) - 1) / (y))

// Define no_init_t wrapper for numeric types
#include <type_traits>

template<class T>
class no_init_t {
public:
    static_assert(std::is_fundamental<T>::value &&
                  std::is_arithmetic<T>::value,
                  "wrapped type must be a fundamental, numeric type");

    // Default constructor does nothing
    constexpr no_init_t() noexcept {}

    // Convertible from a T
    constexpr no_init_t(T value) noexcept : v_(value) {}

    // Acts as a T in all conversion contexts
    constexpr operator T () const noexcept { return v_; }

    // Negation operators
    constexpr no_init_t& operator - () noexcept { v_ = -v_; return *this; }
    constexpr no_init_t& operator ~ () noexcept { v_ = ~v_; return *this; }

    // Prefix increment/decrement
    constexpr no_init_t& operator ++ () noexcept { v_++; return *this; }
    constexpr no_init_t& operator -- () noexcept { v_--; return *this; }

    // Postfix increment/decrement
    constexpr no_init_t operator ++ (int) noexcept {
       auto old(*this);
       v_++;
       return old;
    }
    constexpr no_init_t operator -- (int) noexcept {
       auto old(*this);
       v_--;
       return old;
    }

    // Assignment operators
    constexpr no_init_t& operator  += (T v) noexcept { v_  += v; return *this; }
    constexpr no_init_t& operator  -= (T v) noexcept { v_  -= v; return *this; }
    constexpr no_init_t& operator  *= (T v) noexcept { v_  *= v; return *this; }
    constexpr no_init_t& operator  /= (T v) noexcept { v_  /= v; return *this; }

    // Bitwise operators
    constexpr no_init_t& operator  &= (T v) noexcept { v_  &= v; return *this; }
    constexpr no_init_t& operator  |= (T v) noexcept { v_  |= v; return *this; }
    constexpr no_init_t& operator  ^= (T v) noexcept { v_  ^= v; return *this; }
    constexpr no_init_t& operator >>= (T v) noexcept { v_ >>= v; return *this; }
    constexpr no_init_t& operator <<= (T v) noexcept { v_ <<= v; return *this; }

private:
    T v_; // Underlying value
};

#endif

