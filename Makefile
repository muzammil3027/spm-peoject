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
INCLUDES = -I. -I ../include -I $(FF_ROOT)

# Libraries
LIBS = -pthread -fopenmp

# List of all .cpp source files
SOURCES = $(wildcard *.cpp)

# Define targets from source files (remove the .cpp extension)
TARGET = $(SOURCES:.cpp=)

# Default target (build all executables)
.PHONY: all clean cleanall run_test run_multiple_tests

# General compilation rule for all .cpp files
%: %.cpp
	@if echo "$<" | grep -q "MPI"; then \
		$(MPI) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@.o $< $(LIBS); \
	else \
		$(CXX) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@.o $< $(LIBS); \
	fi

# Build all targets
all: $(TARGET)

# Run the compiled program with the provided arguments
run_test: 
	./$(FILE) $(ARGS)

# Run multiple tests and compute the average execution time over 10 runs
run_multiple_tests:
	@ ARG2=$(shell echo $(ARGS) | awk '{print $$2}'); \
	for i in $$(seq 1 10); do \
		if echo "$(FILE)" | grep -q "MPI"; then \
			mpirun ./$(FILE) $(ARGS) | grep "# elapsed time" | awk '{print "Time: " $$5}' >> temp_elapsed_times_$$ARG2.txt; \
		else \
			./$(FILE) $(ARGS) | grep "# elapsed time" | awk '{print "Time: " $$5}' >> temp_elapsed_times_$$ARG2.txt; \
		fi \
	done; \
	echo "Average elapsed times over 10 executions:"; \
	echo "$$(grep "Time: " temp_elapsed_times_$$ARG2.txt | awk '{ total += $$2; count++ } END { print total/count "s" }')"; \
	rm -f temp_elapsed_times_$$ARG2.txt;

# Clean up object files and other generated files
clean: 
	-rm -fr *.o *~

# Clean everything, including targets
cleanall: clean
	-rm -fr $(TARGET)

