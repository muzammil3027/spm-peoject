# FastFlow root directory (ensure this path is correct)
ifndef FF_ROOT
FF_ROOT = /home/m.muzammil/spm-peoject/fastflow
endif

# Compiler and flags
CXX       = g++ -std=c++20
MPI       = mpicxx -std=c++20
OPTFLAGS  = -O3 -DNDEBUG -ffast-math -g
CXXFLAGS += -Wall -Wno-unused-function -w

# Include directories
INCLUDES = -I. -I include -I $(FF_ROOT)

# Libraries
LIBS = -pthread -fopenmp

# Source files and targets
SOURCES = BroadMPIUTWavefront.cpp SequentialUTWavefront.cpp FFUTWavefront.cpp
TARGETS = BroadMPIUTWavefront SequentialUTWavefront FFUTWavefront

.PHONY: all clean cleanall test run_test run_multiple_tests debug run_fastflow run_sequential run_mpi

# Build all targets
all: $(TARGETS)

BroadMPIUTWavefront: BroadMPIUTWavefront.cpp
	$(MPI) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

SequentialUTWavefront: SequentialUTWavefront.cpp
	$(CXX) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

FFUTWavefront: FFUTWavefront.cpp
	$(CXX) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

# Debug-specific target
debug: CXXFLAGS += -O0 -g
debug: all

# Test all implementations
test: SequentialUTWavefront BroadMPIUTWavefront FFUTWavefront
	@echo "Running SequentialUTWavefront Test (Matrix Size: 1024, 1 Thread)..."
	./SequentialUTWavefront 1024 > sequential_test_$(shell date +%F_%T).log

	@echo "\nRunning BroadMPIUTWavefront Test (Matrix Size: 1024, 8 Processes)..."
	mpirun -np 8 ./BroadMPIUTWavefront 1024 > mpi_test_$(shell date +%F_%T).log

	@echo "\nRunning FFUTWavefront Test (Matrix Size: 1024, 8 Threads)..."
	./FFUTWavefront 1024 8 > fastflow_test_$(shell date +%F_%T).log

# Run Multiple tests together
run_multiple_tests:
	@make run_sequential
	@make run_mpi
	@make run_fastflow

# Run FastFlow for multiple matrix sizes and threads
run_fastflow:
	@for size in 512 1024 2048 4096 8192; do \
		for threads in 2 4 8 16; do \
			echo "Testing FFUTWavefront: Matrix Size=$$size, Threads=$$threads"; \
			./FFUTWavefront $$size $$threads >> fastflow_results.log; \
			echo "Matrix Size=$$size, Threads=$$threads completed."; \
		done; \
	done

# Run Sequential for multiple matrix sizes
run_sequential:
	@for size in 512 1024 2048 4096 8192; do \
		echo "Testing SequentialUTWavefront: Matrix Size=$$size, 1 Thread"; \
		./SequentialUTWavefront $$size >> sequential_results.log; \
		echo "Matrix Size=$$size, 1 Thread completed."; \
	done

# Run MPI for multiple matrix sizes and processes
run_mpi:
	@for size in 512 1024 2048 4096 8192; do \
		for procs in 2 4 8 16; do \
			echo "Testing BroadMPIUTWavefront: Matrix Size=$$size, Processes=$$procs"; \
			mpirun -np $$procs ./BroadMPIUTWavefront $$size >> mpi_results.log; \
			echo "Matrix Size=$$size, Processes=$$procs completed."; \
		done; \
	done

# Clean generated binaries and logs
clean:
	-rm -f BroadMPIUTWavefront SequentialUTWavefront FFUTWavefront \
		   temp_elapsed_times.txt \
		   temp_parallel_output.txt \
		   temp_sequential_output.txt \
		   temp_fastflow_output.txt \
		   *_test_*.log sequential_results.log mpi_results.log fastflow_results.log fastflow_analysis.log mpi_analysis.log fastflow_weak_scalability.log mpi_weak_scalability.log

# Clean everything
cleanall: clean
	-rm -f $(TARGETS)

