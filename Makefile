# nymph-balancer makefile

NIM = nim
NIMFLAGS = --threads:on --mm:arc
RELEASE_FLAGS = -d:release --opt:speed
DEBUG_FLAGS = -d:debug --debugger:native

SRC_DIR = src
BIN_DIR = bin
TEST_DIR = tests
TOOLS_DIR = tools

# main targets
BALANCER = $(BIN_DIR)/nymph_balancer.exe
TRAFFIC_SIM = $(BIN_DIR)/traffic_simulator.exe
BENCHMARK = $(BIN_DIR)/benchmark.exe

# source files
BALANCER_SRC = $(SRC_DIR)/core/balancer.nim
TRAFFIC_SIM_SRC = $(TOOLS_DIR)/traffic_simulator.nim
BENCHMARK_SRC = $(TOOLS_DIR)/benchmark.nim

.PHONY: all build clean test help dirs dev

all: dirs build

dirs:
	@if not exist $(BIN_DIR) mkdir $(BIN_DIR)
	@if not exist logs mkdir logs

build: dirs $(BALANCER)

dev: dirs
	$(NIM) c $(NIMFLAGS) $(DEBUG_FLAGS) -o:$(BALANCER) $(BALANCER_SRC)

$(BALANCER): $(BALANCER_SRC)
	$(NIM) c $(NIMFLAGS) $(RELEASE_FLAGS) -o:$(BALANCER) $(BALANCER_SRC)

tools: dirs $(TRAFFIC_SIM) $(BENCHMARK)

$(TRAFFIC_SIM): $(TRAFFIC_SIM_SRC)
	$(NIM) c $(NIMFLAGS) $(RELEASE_FLAGS) -o:$(TRAFFIC_SIM) $(TRAFFIC_SIM_SRC)

$(BENCHMARK): $(BENCHMARK_SRC)
	$(NIM) c $(NIMFLAGS) $(RELEASE_FLAGS) -o:$(BENCHMARK) $(BENCHMARK_SRC)

test: dirs
	@echo running tests...
	@if exist $(TEST_DIR)\*.nim ($(NIM) c -r $(NIMFLAGS) $(TEST_DIR)\test_all.nim) else (echo no tests found)

clean:
	@if exist $(BIN_DIR)\*.exe del /q $(BIN_DIR)\*.exe
	@if exist $(SRC_DIR)\*.exe del /q $(SRC_DIR)\*.exe
	@if exist $(TOOLS_DIR)\*.exe del /q $(TOOLS_DIR)\*.exe
	@if exist $(TEST_DIR)\*.exe del /q $(TEST_DIR)\*.exe
	@echo cleaned build artifacts

help:
	@echo nymph-balancer build system
	@echo.
	@echo targets:
	@echo   make all      - build everything (default)
	@echo   make build    - build balancer only
	@echo   make dev      - build with debug symbols
	@echo   make tools    - build traffic simulator and benchmark
	@echo   make test     - run test suite
	@echo   make clean    - remove build artifacts
	@echo   make dirs     - create directory structure
	@echo   make help     - show this message
