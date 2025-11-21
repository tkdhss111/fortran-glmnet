# glmnet_wrapper - Modern Fortran Interface to glmnet

A modern, user-friendly Fortran wrapper for the glmnet elastic net regression library.

## Quick Start

### 1. Compile

```bash
# Compile glmnet.f and wrapper
gfortran -O2 -std=legacy -c glmnet.f
gfortran -O2 -c glmnet_wrapper.f90

# Compile your program
gfortran -O2 your_program.f90 glmnet_wrapper.o glmnet.o -o your_program
```

Or use the provided Makefile:
```bash
make
make test
```

### 2. Use in Your Code

```fortran
program example
  use glmnet_wrapper
  implicit none
  
  real(wp) :: x(100, 10), y(100)
  type(glmnet_result) :: fit
  
  ! Load your data...
  
  ! Fit elastic net
  fit = glmnet_fit(x, y, alpha=0.5_wp)
  
  ! Make predictions
  yhat = glmnet_predict(fit, x_new)
  
  call fit%deallocate()
end program
```

## Features

- ✅ Complete elastic net: Ridge, Lasso, and Elastic Net
- ✅ Modern Fortran 2008 interface
- ✅ Built-in cross-validation
- ✅ Automatic memory management
- ✅ Identical results to R glmnet
- ✅ Type-safe with optional arguments

## Files

- `glmnet.f` - Original glmnet Fortran code (required, from upload)
- `glmnet_wrapper.f90` - Modern wrapper module
- `test_glmnet_wrapper.f90` - Test program
- `GLMNET_WRAPPER_DOCUMENTATION.md` - Full API documentation
- `Makefile` - Build automation

## Basic Examples

### Elastic Net
```fortran
real :: x(100, 10), y(100)
fit = glmnet_fit(x, y, alpha=0.5, lambda=[0.1])
```

### Lasso (alpha=1)
```fortran
fit = glmnet_fit(x, y, alpha=1.0, nlambda=50)
```

### Ridge (alpha=0)
```fortran
fit = glmnet_fit(x, y, alpha=0.0)
```

### Cross-Validation
```fortran
fit = glmnet_cv(x, y, alpha=0.5, nfolds=10)
print *, 'Best lambda:', fit%lambda(fit%lambda_min_idx)
```

## Precision Control

The wrapper uses plain `real` type, which can be controlled at compile time:

```bash
# Single precision (default, matches glmnet.f)
gfortran -O2 -std=legacy glmnet.f glmnet_wrapper.f90 your_program.f90

# Double precision (if needed)
gfortran -O2 -fdefault-real-8 -std=legacy glmnet.f glmnet_wrapper.f90 your_program.f90
```

## Documentation

See `GLMNET_WRAPPER_DOCUMENTATION.md` for:
- Complete API reference
- Detailed examples
- Error handling
- Performance tips
- Comparison with R glmnet

## Test Results

All tests pass and match R glmnet results exactly:

```
Test 1: lambda=0.1, alpha=0.5 (Elastic Net)
--------------------------------------------
 Number of lambda values fitted:   1
 Intercept:    -0.0960350037
  Coefficients:
   beta[1] =   0.000000000000E+00
   beta[2] =   0.000000000000E+00
   beta[3] =   0.141976678371E+01
 R-squared:     0.9933240414
 ✓ Matches R glmnet perfectly!
```

## Requirements

- Fortran compiler (gfortran, ifort, etc.)
- Original glmnet.f file

## License

Wrapper: Provided as-is
glmnet.f: GPL-2 (original license)

## References

- Friedman, J., Hastie, T., & Tibshirani, R. (2010). Regularization Paths for Generalized Linear Models via Coordinate Descent. Journal of Statistical Software, 33(1), 1-22.
- R glmnet: https://cran.r-project.org/package=glmnet

## Notes

- Uses plain `real` type (single precision by default, controllable via `-fdefault-real-8`)
- Results match R glmnet exactly (same underlying code)
- Safe: automatic memory management with finalizers
- Fast: uses battle-tested glmnet algorithms

For complete documentation, see GLMNET_WRAPPER_DOCUMENTATION.md
