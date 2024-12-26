# FastFlow root directory (ensure this path is correct)
ifndef FF_ROOT
FF_ROOT = ${HOME}/fastflow
endif

# Compiler and flags
CXX = g++ -std=c++20
MPI = mpicxx -std=c++20
OPTFLAGS = -O3 -DNDEBUG -ffast-math -g
CXXFLAGS += -Wall

# Include directories
INCLUDES = -I. -I include -I $(FF_ROOT)

# Libraries
LIBS = -pthread -fopenmp

# Source files
SOURCES = BroadMPIUTWavefront.cpp SequentialUTWavefront.cpp
TARGETS = BroadMPIUTWavefront SequentialUTWavefront

.PHONY: all clean cleanall clean-temp clean-slurm-logs clean-slurm-errs test

all: $(TARGETS)

BroadMPIUTWavefront: BroadMPIUTWavefront.cpp
	$(MPI) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

SequentialUTWavefront: SequentialUTWavefront.cpp
	$(CXX) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

# Test target to run both sequential and parallel tests
test: SequentialUTWavefront BroadMPIUTWavefront
	@echo "Running SequentialUTWavefront Test..."
	./SequentialUTWavefront 512 > temp_sequential_output.txt
	cat temp_sequential_output.txt
	@echo "\nRunning BroadMPIUTWavefront Test..."
	mpirun -np 8 ./BroadMPIUTWavefront 512 > temp_parallel_output.txt
	cat temp_parallel_output.txt

# Run the compiled program with the provided arguments
run_test:
	@if [ -z "$(FILE)" ] || [ -z "$(ARGS)" ]; then \
		echo "Error: FILE or ARGS not set"; \
		exit 1; \
	fi; \
	if echo "$(FILE)" | grep -q "MPI"; then \
		mpirun -np $$(echo $(ARGS) | awk '{print $$1}') ./$(FILE) $$(echo $(ARGS) | awk '{print $$2}'); \
	else \
		./$(FILE) $(ARGS); \
	fi

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

# Clean generated binaries
clean:
	-rm -f BroadMPIUTWavefront SequentialUTWavefront temp_elapsed_times.txt temp_parallel_output.txt temp_sequential_output.txt

# Clean only temporary files
clean-temp:
	-rm -f temp_elapsed_times.txt temp_parallel_output.txt temp_sequential_output.txt

# Clean only SLURM log files (*.log)
clean-slurm-logs:
	-rm -f *.log

# Clean only SLURM error files (*.err)
clean-slurm-errs:
	-rm -f *.err

# Clean everything, including targets
cleanall: clean clean-temp clean-slurm-logs clean-slurm-errs
	-rm -f $(TARGETS)

