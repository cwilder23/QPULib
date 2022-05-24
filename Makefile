# QPULib custom Makefile by cwilder

# Cwilder's custom functions
rwildcard = $(foreach d,$(wildcard $1*),$(call rwildcard,$d/,$2) $(filter $(subst *,%,$2),$d))
#usag: $(call rwildcard, Lib, *.h)

# Root directory of QPULib implementation
ROOT = Lib

# Compiler and default flags
CFLAGS = -O3
CXXFLAGS = 
ARCH=$(shell uname -m)
ifneq ($(arch), armv7l)
        CROSS_COMPILE = arm-linux-gnueabihf-
        CXX = arm-linux-gnueabihf-g++
        LD = arm-linux-gnueabihf-ld
        CC = arm-linux-gnueabihf-gcc
        CFLAGS += -march=armv7-a -mfpu=neon-vfpv4 -mtune=cortex-a53 -mfloat-abi=hard
else
        CXX = g++
endif
CFLAGS += -Wconversion -I $(ROOT)
CXXFLAGS += -std=c++0x $(CFLAGS)


# Test source directory
TESTS_DIR = Tests

# Dist directories
DIST_DIR = dist
DIST_QPULIB_DIR = $(DIST_DIR)/lib
DIST_INCLUDE_DIR = $(DIST_DIR)/include

# Object directory
OBJ_DIR = $(ROOT)/obj


# Debug mode
ifeq ($(DEBUG), 1)
  CXXFLAGS += -DDEBUG
  OBJ_DIR := $(OBJ_DIR)-debug
endif

# QPU or emulation mode
ifeq ($(QPU), 1)
  CXXFLAGS += -DQPU_MODE
  OBJ_DIR := $(OBJ_DIR)-qpu
else
  CXXFLAGS += -DEMULATION_MODE
endif

# Object files
OBJ =                         \
  Kernel.o                    \
  Source/Syntax.o             \
  Source/Int.o                \
  Source/Float.o              \
  Source/Stmt.o               \
  Source/Pretty.o             \
  Source/Translate.o          \
  Source/Interpreter.o        \
  Source/Gen.o                \
  Target/Syntax.o             \
  Target/SmallLiteral.o       \
  Target/Pretty.o             \
  Target/RemoveLabels.o       \
  Target/CFG.o                \
  Target/Liveness.o           \
  Target/RegAlloc.o           \
  Target/ReachingDefs.o       \
  Target/Subst.o              \
  Target/LiveRangeSplit.o     \
  Target/Satisfy.o            \
  Target/LoadStore.o          \
  Target/Emulator.o           \
  Target/Encode.o             \
  VideoCore/Mailbox.o         \
  VideoCore/Invoke.o          \
  VideoCore/VideoCore.o

# Top-level targets

.PHONY: top clean

top:
	@echo Please supply a target to build, e.g. \'make GCD\'
	@echo

clean:
	rm -rf $(addprefix $(ROOT)/,obj obj-debug obj-qpu obj-debug-qpu)
	rm -f $(addprefix $(TESTS_DIR)/,AutoTest GCD HeatMap HeatMapScalar Hello ID MultiTri OET Print ReqRecv Rot3D Sort Tri TriFloat) 
	rm -f $(TESTS_DIR)/*.o
	rm -f HeatMap
	rm -fr $(DIST_DIR)

LIB = $(patsubst %,$(OBJ_DIR)/%,$(OBJ))

#Build the distributable
dist: libQPU includesQPU

#Build all of the tests
tests: AutoTest GCD HeatMap HeatMapScalar Hello ID MultiTri OET Print ReqRecv Rot3D Sort Tri TriFloat


libQPU: $(LIB)
	@echo Building $@.so
	@mkdir -p $(DIST_QPULIB_DIR)
	@$(CXX) -fpic -shared $^ -o $(DIST_QPULIB_DIR)/$@.so

includesQPU: $(shell find $(ROOT) -name '*.h')
	@echo Collecting header files
	@rm -fr $(DIST_INCLUDE_DIR)
	@mkdir -p $(DIST_INCLUDE_DIR)
	@rsync -aR $^ $(DIST_INCLUDE_DIR)
	@mv $(DIST_INCLUDE_DIR)/Lib/* $(DIST_INCLUDE_DIR)
	@rm -fr $(DIST_INCLUDE_DIR)/Lib

Hello: $(TESTS_DIR)/Hello.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

ID: $(TESTS_DIR)/ID.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

Tri: $(TESTS_DIR)/Tri.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

Print: $(TESTS_DIR)/Print.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

GCD: $(TESTS_DIR)/GCD.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

AutoTest: $(TESTS_DIR)/AutoTest.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

MultiTri: $(TESTS_DIR)/MultiTri.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

OET: $(TESTS_DIR)/OET.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

ReqRecv: $(TESTS_DIR)/ReqRecv.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

Rot3D: $(TESTS_DIR)/Rot3D.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

HeatMap: $(TESTS_DIR)/HeatMap.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

HeatMapScalar: $(TESTS_DIR)/HeatMap.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

Sort: $(TESTS_DIR)/Sort.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

TriFloat: $(TESTS_DIR)/TriFloat.o $(LIB)
	@echo Linking...
	@$(CXX) $^ -o $(TESTS_DIR)/$@ $(CXXFLAGS)

# Intermediate targets

$(OBJ_DIR)/%.o: $(ROOT)/%.cpp $(OBJ_DIR)
	@echo Compiling $<
	@$(CXX) -c -o $@ $< $(CXXFLAGS)

%.o: %.cpp
	@echo Compiling $<
	@$(CXX) -c -o $@ $< $(CXXFLAGS)

$(OBJ_DIR):
	@mkdir -p $(OBJ_DIR)
	@mkdir -p $(OBJ_DIR)/Source
	@mkdir -p $(OBJ_DIR)/Target
	@mkdir -p $(OBJ_DIR)/VideoCore
