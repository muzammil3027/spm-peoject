# FastFlow root directory (ensure this path is correct)
ifndef FF_ROOT
FF_ROOT = /home/m.muzammil/spm-peoject/fastflow
endif

# Compiler and flags
CXX       = g++
MPI       = mpicxx
OPTFLAGS  = -O3 -DNDEBUG -ffast-math -g
CXXFLAGS += -std=c++20 -Wall -Wno-unused-function -w

# Include directories
INCLUDES = -I. -I include -I $(FF_ROOT)
LIBS = -pthread -fopenmp

SOURCES = BroadMPIUTWavefront.cpp SequentialUTWavefront.cpp FFUTWavefront.cpp
TARGETS = BroadMPIUTWavefront SequentialUTWavefront FFUTWavefront

.PHONY: all clean cleanall run_multiple_tests

all: $(TARGETS)

BroadMPIUTWavefront: BroadMPIUTWavefront.cpp
	$(MPI) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

SequentialUTWavefront: SequentialUTWavefront.cpp
	$(CXX) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

FFUTWavefront: FFUTWavefront.cpp
	$(CXX) $(INCLUDES) $(CXXFLAGS) $(OPTFLAGS) -o $@ $< $(LIBS)

run_multiple_tests:
	@if [ -z "$(FILE)" ] || [ -z "$(ARGS)" ] || [ -z "$(ITERATIONS)" ]; then \
		echo "Usage: make run_multiple_tests FILE=<executable> ARGS=<arguments> ITERATIONS=<count>"; \
		exit 1; \
	fi; \
	echo "Running $(FILE) with ARGS='$(ARGS)' for $(ITERATIONS) iterations"; \
	TOTAL_TIME=0; \
	for i in $$(seq 1 $(ITERATIONS)); do \
		if [ "$(FILE)" = "FFUTWavefront" ]; then \
			ELAPSED=$$(./$(FILE) $(ARGS) 2>&1 | grep -m1 "# elapsed time:" | grep -Po "\d+\.\d+"); \
		elif [ "$(FILE)" = "BroadMPIUTWavefront" ]; then \
			ELAPSED=$$(mpirun -np $$(echo $(ARGS) | awk '{print $$2}') ./$(FILE) $$(echo $(ARGS) | awk '{print $$1}') 2>&1 | grep -m1 "# elapsed time (wavefront):" | grep -Po "\d+\.\d+"); \
		else \
			ELAPSED=$$(./$(FILE) $(ARGS) 2>&1 | grep -m1 "# elapsed time:" | grep -Po "\d+\.\d+"); \
		fi; \
		if [ -z "$$ELAPSED" ]; then \
			echo "Error: Could not capture elapsed time for Run $$i"; \
			exit 1; \
		fi; \
		echo "Run $$i: $$ELAPSED seconds"; \
		TOTAL_TIME=$$(echo "$$TOTAL_TIME + $$ELAPSED" | bc -l); \
	done; \
	AVG_TIME=$$(echo "$$TOTAL_TIME / $(ITERATIONS)" | bc -l); \
	echo "----------------------------------------"; \
	echo "Average Elapsed Time: $$AVG_TIME seconds";

clean:
	rm -f $(TARGETS)
	rm -f results_*.log
	rm -f *.o

cleanall: clean
	rm -f *_test_*.log

