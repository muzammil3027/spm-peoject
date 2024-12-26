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
# IMPORTANT: we now point to $(FF_ROOT) so that #include <ff/pipeline.hpp> works.
INCLUDES = -I. -I include -I $(FF_ROOT)

# Libraries
LIBS = -pthread -fopenmp

# Source files and targets
SOURCES = BroadMPIUTWavefront.cpp SequentialUTWavefront.cpp FFUTWavefront.cpp
TARGETS = BroadMPIUTWavefront SequentialUTWavefront FFUTWavefront

.PHONY: all clean cleanall clean-temp clean-slurm-logs clean-slurm-errs test run_test run_multiple_tests

# Build all targets
all: $(TARGETS)

BroadMPIUTWavefront: BroadMPIUTWavefront.cpp
	$(MPI) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

SequentialUTWavefront: SequentialUTWavefront.cpp
	$(CXX) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

FFUTWavefront: FFUTWavefront.cpp
	$(CXX) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

# Test target to run all tests (sequential, MPI, and FastFlow) with default settings
test: SequentialUTWavefront BroadMPIUTWavefront FFUTWavefront
	@echo "Running SequentialUTWavefront Test (Matrix Size: 1024, Cores: 1)..."
	./SequentialUTWavefront 1024 > temp_sequential_output.txt
	cat temp_sequential_output.txt

	@echo "\nRunning BroadMPIUTWavefront Test (Matrix Size: 1024, Cores: 8)..."
	mpirun -np 8 ./BroadMPIUTWavefront 1024 > temp_parallel_output.txt
	cat temp_parallel_output.txt

	@echo "\nRunning FFUTWavefront Test (Matrix Size: 1024, Cores: 8)..."
	./FFUTWavefront 1024 8 > temp_fastflow_output.txt
	cat temp_fastflow_output.txt

# Run a single program (sequential, MPI, or FastFlow) with custom FILE and ARGS
# Usage example:
#    make run_test FILE=SequentialUTWavefront ARGS="1024"
#    make run_test FILE=BroadMPIUTWavefront   ARGS="8 1024"
#    make run_test FILE=FFUTWavefront        ARGS="1024 8"
run_test:
	@if [ -z "$(FILE)" ] || [ -z "$(ARGS)" ]; then \
		echo "Error: FILE or ARGS not set"; \
		exit 1; \
	fi; \
	if echo "$(FILE)" | grep -q "MPI"; then \
		# For MPI code, the first argument is # of processes, the second is matrix size
		mpirun -np $$(echo $(ARGS) | awk '{print $$1}') ./$(FILE) $$(echo $(ARGS) | awk '{print $$2}'); \
	else \
		# For sequential or FastFlow code, just pass $(ARGS)
		./$(FILE) $(ARGS); \
	fi

# Run multiple tests (10 times) to collect average elapsed time from the output
# (the code should print a line containing "# elapsed time" <time_in_seconds>)
run_multiple_tests:
	@if [ -z "$(FILE)" ] || [ -z "$(ARGS)" ]; then \
		echo "Error: FILE or ARGS not set"; \
		exit 1; \
	fi; \
	touch temp_elapsed_times.txt; \
	rm -f temp_elapsed_times.txt; \
	for i in $$(seq 1 10); do \
		./$(FILE) $(ARGS) | grep "# elapsed time" | awk '{print $$4}' >> temp_elapsed_times.txt; \
	done; \
	if [ -s temp_elapsed_times.txt ]; then \
		echo "Average elapsed times over 10 executions:"; \
		awk '{ total += $$1; count++ } END { if (count > 0) print total/count " seconds"; else print "No valid times collected"; }' temp_elapsed_times.txt; \
	else \
		echo "No valid times collected"; \
	fi; \
	rm -f temp_elapsed_times.txt;

# Clean generated binaries and temp files
clean:
	-rm -f BroadMPIUTWavefront SequentialUTWavefront FFUTWavefront \
	       temp_elapsed_times.txt \
	       temp_parallel_output.txt \
	       temp_sequential_output.txt \
	       temp_fastflow_output.txt

# Clean only temporary files
clean-temp:
	-rm -f temp_elapsed_times.txt \
	       temp_parallel_output.txt \
	       temp_sequential_output.txt \
	       temp_fastflow_output.txt

# Clean only SLURM log files (*.log)
clean-slurm-logs:
	-rm -f *.log

# Clean only SLURM error files (*.err)
clean-slurm-errs:
	-rm -f *.err

# Clean everything, including targets
cleanall: clean clean-temp clean-slurm-logs clean-slurm-errs
	-rm -f $(TARGETS)

