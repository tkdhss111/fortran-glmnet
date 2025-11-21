# Makefile for glmnet_wrapper
#
# Usage:
#   make              - Build the wrapper library
#   make test         - Build and run tests
#   make clean        - Clean build files
#   make install      - Install to system (requires sudo)

# Compiler settings
FC = gfortran
FFLAGS = -O2 -Wall
FFLAGS_LEGACY = -O2 -std=legacy
INSTALL_DIR = /usr/local

# Files
GLMNET_SRC = glmnet.f
WRAPPER_SRC = glmnet_wrapper.f90
TEST_SRC = test_glmnet_wrapper.f90

GLMNET_OBJ = glmnet.o
WRAPPER_OBJ = glmnet_wrapper.o
WRAPPER_MOD = glmnet_wrapper.mod

LIB_NAME = libglmnet_wrapper.a
TEST_EXE = test_glmnet_wrapper

# Targets
.PHONY: all test clean install uninstall help

all: $(LIB_NAME)

# Compile glmnet.f (legacy Fortran)
$(GLMNET_OBJ): $(GLMNET_SRC)
	$(FC) $(FFLAGS_LEGACY) -c $(GLMNET_SRC) -o $(GLMNET_OBJ)

# Compile wrapper module
$(WRAPPER_OBJ): $(WRAPPER_SRC)
	$(FC) $(FFLAGS) -c $(WRAPPER_SRC)

# Create static library
$(LIB_NAME): $(GLMNET_OBJ) $(WRAPPER_OBJ)
	ar rcs $(LIB_NAME) $(GLMNET_OBJ) $(WRAPPER_OBJ)
	@echo ""
	@echo "Library $(LIB_NAME) created successfully!"
	@echo "Link with: gfortran your_program.f90 $(LIB_NAME)"

# Build and run tests
test: $(TEST_EXE)
	@echo ""
	@echo "Running tests..."
	@echo "================"
	./$(TEST_EXE)

$(TEST_EXE): $(TEST_SRC) $(LIB_NAME)
	$(FC) $(FFLAGS) $(TEST_SRC) $(LIB_NAME) -o $(TEST_EXE)

# Install to system
install: $(LIB_NAME)
	@echo "Installing to $(INSTALL_DIR)..."
	install -d $(INSTALL_DIR)/lib
	install -d $(INSTALL_DIR)/include
	install -m 644 $(LIB_NAME) $(INSTALL_DIR)/lib/
	install -m 644 $(WRAPPER_MOD) $(INSTALL_DIR)/include/
	@echo "Installation complete!"
	@echo "Use: gfortran -I$(INSTALL_DIR)/include your_program.f90 -L$(INSTALL_DIR)/lib -lglmnet_wrapper"

# Uninstall from system
uninstall:
	rm -f $(INSTALL_DIR)/lib/$(LIB_NAME)
	rm -f $(INSTALL_DIR)/include/$(WRAPPER_MOD)
	@echo "Uninstallation complete!"

# Clean build files
clean:
	rm -f *.o *.mod *.a $(TEST_EXE)
	@echo "Clean complete!"

# Help message
help:
	@echo "glmnet_wrapper Makefile"
	@echo "======================="
	@echo ""
	@echo "Targets:"
	@echo "  make          - Build the wrapper library"
	@echo "  make test     - Build and run tests"
	@echo "  make clean    - Remove build files"
	@echo "  make install  - Install to $(INSTALL_DIR) (requires sudo)"
	@echo "  make uninstall- Remove from $(INSTALL_DIR) (requires sudo)"
	@echo "  make help     - Show this help message"
	@echo ""
	@echo "Examples:"
	@echo "  make && make test                    # Build and test"
	@echo "  sudo make install                    # Install system-wide"
	@echo "  gfortran my_prog.f90 libglmnet_wrapper.a  # Link with library"
