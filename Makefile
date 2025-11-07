# nymph-balancer makefile

NIM           = nim
NIMFLAGS      = --threads:on --mm:arc
RELEASE_FLAGS = -d:release --opt:speed
DEBUG_FLAGS   = -d:debug --debugger:native

SRC_DIR   = src
BIN_DIR   = bin
TEST_DIR  = tests
TOOLS_DIR = tools

# main targets
BALANCER       = $(BIN_DIR)/balancer.exe
SIMPLE_BACKEND = $(BIN_DIR)/simple_backend.exe
LOAD_TEST      = $(BIN_DIR)/load_test.exe
TEST_BACKEND   = $(BIN_DIR)/test_backend_direct.exe

# source files
BALANCER_SRC       = $(SRC_DIR)/balancer.nim
SIMPLE_BACKEND_SRC = $(TOOLS_DIR)/simple_backend.nim
LOAD_TEST_SRC      = $(TOOLS_DIR)/load_test.nim
TEST_BACKEND_SRC   = $(TOOLS_DIR)/test_backend_direct.nim

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

tools: dirs $(SIMPLE_BACKEND) $(LOAD_TEST) $(TEST_BACKEND)

$(SIMPLE_BACKEND): $(SIMPLE_BACKEND_SRC)
	$(NIM) c $(RELEASE_FLAGS) -o:$(SIMPLE_BACKEND) $(SIMPLE_BACKEND_SRC)

$(LOAD_TEST): $(LOAD_TEST_SRC)
	$(NIM) c $(RELEASE_FLAGS) -o:$(LOAD_TEST) $(LOAD_TEST_SRC)

$(TEST_BACKEND): $(TEST_BACKEND_SRC)
	$(NIM) c $(RELEASE_FLAGS) -o:$(TEST_BACKEND) $(TEST_BACKEND_SRC)

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
	@echo   make tools    - build test tools (backend, load test)
	@echo   make test     - run test suite
	@echo   make clean    - remove build artifacts
	@echo   make dirs     - create directory structure
	@echo   make help     - show this message
