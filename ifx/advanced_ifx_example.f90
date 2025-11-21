! Advanced Example: Using glmnet_wrapper with Intel ifx, MKL, and OpenMP
!
! This example demonstrates:
!   1. OpenMP parallel processing
!   2. Intel MKL for fast linear algebra (if linked)
!   3. Advanced optimization features
!   4. Performance monitoring
!
! Compile with:
!   ifx -O3 -xHost -qopenmp -qmkl glmnet.f glmnet_wrapper.f90 advanced_ifx_example.f90 -o advanced
!
! Run with:
!   export OMP_NUM_THREADS=4
!   ./advanced

program advanced_ifx_example
  use glmnet_wrapper
  use omp_lib
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  
  ! Problem parameters
  integer, parameter :: n_obs = 1000
  integer, parameter :: n_vars = 200
  integer, parameter :: n_simulations = 100
  
  ! Data arrays
  real, allocatable :: x(:,:), y(:), x_test(:,:), y_test(:)
  type(glmnet_result) :: fit
  real, allocatable :: predictions(:)
  
  ! Results storage
  real :: mse_results(n_simulations)
  real :: best_lambda(n_simulations)
  integer :: selected_vars(n_simulations)
  
  ! Timing
  real(real64) :: start_time, end_time, total_time
  
  ! Other
  integer :: i, sim, true_vars(20)
  real :: mse
  
  print '(A)', '================================================'
  print '(A)', '  Advanced Intel ifx Example'
  print '(A)', '  glmnet_wrapper with OpenMP and MKL'
  print '(A)', '================================================'
  print *
  
  ! Show OpenMP info
  !$OMP PARALLEL
  !$OMP MASTER
  print '(A,I0)', 'OpenMP threads available: ', omp_get_num_threads()
  print '(A,I0)', 'Max threads: ', omp_get_max_threads()
  !$OMP END MASTER
  !$OMP END PARALLEL
  print *
  
  ! Generate true variable indices (first 20 variables are important)
  do i = 1, 20
    true_vars(i) = i
  end do
  
  print '(A)', 'Problem specification:'
  print '(A,I0)', '  Observations: ', n_obs
  print '(A,I0)', '  Variables: ', n_vars
  print '(A,I0)', '  True model: 20 variables with signal'
  print '(A,I0)', '  Simulations: ', n_simulations
  print *
  
  ! Allocate arrays
  allocate(x(n_obs, n_vars), y(n_obs))
  allocate(x_test(n_obs, n_vars), y_test(n_obs))
  
  ! =================================================================
  ! Parallel Simulation using OpenMP
  ! =================================================================
  print '(A)', 'Running parallel simulations...'
  print '(A)', '----------------------------------------'
  
  call cpu_time(start_time)
  
  !$OMP PARALLEL DO PRIVATE(x, y, x_test, y_test, fit, predictions, i, mse) &
  !$OMP SHARED(mse_results, best_lambda, selected_vars, true_vars) &
  !$OMP SCHEDULE(dynamic)
  do sim = 1, n_simulations
    
    ! Generate training data
    call random_seed()
    call random_number(x)
    
    ! True model: y = sum of first 20 variables
    y = 0.0
    do i = 1, 20
      y = y + real(21 - i) * x(:, i) / 20.0
    end do
    
    ! Add noise
    do i = 1, n_obs
      y(i) = y(i) + randn() * 2.0
    end do
    
    ! Generate test data
    call random_number(x_test)
    y_test = 0.0
    do i = 1, 20
      y_test = y_test + real(21 - i) * x_test(:, i) / 20.0
    end do
    do i = 1, n_obs
      y_test(i) = y_test(i) + randn() * 2.0
    end do
    
    ! Fit model with cross-validation
    fit = glmnet_cv(x, y, alpha=0.5, nfolds=5)
    
    ! Store best lambda
    best_lambda(sim) = fit%lambda(fit%lambda_min_idx)
    
    ! Count selected variables (non-zero coefficients)
    selected_vars(sim) = count(abs(fit%beta(:, fit%lambda_min_idx)) > 1.0e-6)
    
    ! Predict on test set
    predictions = glmnet_predict(fit, x_test, s=fit%lambda_min_idx)
    
    ! Compute test MSE
    mse = sum((y_test - predictions)**2) / real(n_obs)
    mse_results(sim) = mse
    
    ! Clean up
    deallocate(predictions)
    call fit%deallocate()
    
  end do
  !$OMP END PARALLEL DO
  
  call cpu_time(end_time)
  total_time = end_time - start_time
  
  print '(A)', '✓ Simulations complete'
  print '(A,F8.2,A)', '  Total time: ', total_time, ' seconds'
  print '(A,F8.2,A)', '  Time per simulation: ', total_time / n_simulations, ' seconds'
  print *
  
  ! =================================================================
  ! Analyze Results
  ! =================================================================
  print '(A)', 'Simulation Results:'
  print '(A)', '----------------------------------------'
  
  ! MSE statistics
  print '(A,F10.4)', '  Mean test MSE: ', sum(mse_results) / n_simulations
  print '(A,F10.4)', '  Min test MSE: ', minval(mse_results)
  print '(A,F10.4)', '  Max test MSE: ', maxval(mse_results)
  print '(A,F10.4)', '  Std dev MSE: ', sqrt(variance(mse_results))
  print *
  
  ! Lambda statistics
  print '(A,F10.6)', '  Mean optimal lambda: ', sum(best_lambda) / n_simulations
  print '(A,F10.6)', '  Min lambda: ', minval(best_lambda)
  print '(A,F10.6)', '  Max lambda: ', maxval(best_lambda)
  print *
  
  ! Variable selection
  print '(A,F6.2)', '  Mean selected variables: ', &
        sum(real(selected_vars)) / n_simulations
  print '(A,I0)', '  Min selected: ', minval(selected_vars)
  print '(A,I0)', '  Max selected: ', maxval(selected_vars)
  print '(A,I0)', '  True model size: 20'
  print *
  
  ! =================================================================
  ! Single Detailed Example
  ! =================================================================
  print '(A)', 'Detailed Example (single fit):'
  print '(A)', '----------------------------------------'
  
  ! Generate one more dataset
  call random_number(x)
  y = 0.0
  do i = 1, 20
    y = y + real(21 - i) * x(:, i) / 20.0
  end do
  do i = 1, n_obs
    y(i) = y(i) + randn() * 2.0
  end do
  
  ! Fit with CV
  fit = glmnet_cv(x, y, alpha=0.5, nfolds=10)
  
  print '(A,I0)', '  Number of lambda values: ', fit%lmu
  print '(A,I0)', '  Lambda min index: ', fit%lambda_min_idx
  print '(A,F10.6)', '  Optimal lambda: ', fit%lambda(fit%lambda_min_idx)
  print '(A,F10.4)', '  CV error at min: ', fit%cvm(fit%lambda_min_idx)
  print *
  
  ! Show selected variables
  print '(A)', '  Selected variables (|coef| > 1e-6):'
  do i = 1, n_vars
    if (abs(fit%beta(i, fit%lambda_min_idx)) > 1.0e-6) then
      print '(A,I4,A,F10.6)', '    Variable ', i, ': ', &
            fit%beta(i, fit%lambda_min_idx)
    end if
  end do
  print *
  
  call fit%deallocate()
  deallocate(x, y, x_test, y_test)
  
  ! =================================================================
  ! Performance Summary
  ! =================================================================
  print '(A)', '================================================'
  print '(A)', '  Performance Summary'
  print '(A)', '================================================'
  print *
  
  !$OMP PARALLEL
  !$OMP MASTER
  print '(A,I0)', 'Used ', omp_get_num_threads(), ' OpenMP threads'
  !$OMP END MASTER
  !$OMP END PARALLEL
  
  print '(A,I0,A)', 'Completed ', n_simulations, ' simulations'
  print '(A,F8.2,A)', 'Total time: ', total_time, ' seconds'
  print '(A,F8.4,A)', 'Throughput: ', n_simulations / total_time, ' simulations/sec'
  print *
  
  print '(A)', 'Intel ifx optimizations enabled:'
  print '(A)', '  ✓ -O3 (aggressive optimization)'
  print '(A)', '  ✓ -xHost (CPU-specific instructions)'
  print '(A)', '  ✓ -qopenmp (parallel processing)'
  print '(A)', '  ✓ -qmkl (Intel Math Kernel Library, if linked)'
  print *
  
  print '(A)', '================================================'
  print '(A)', '  Example Complete'
  print '(A)', '================================================'
  
contains
  
  ! Variance calculation
  real function variance(arr) result(var)
    real, intent(in) :: arr(:)
    real :: mean_val, n
    integer :: i
    
    n = real(size(arr))
    mean_val = sum(arr) / n
    var = sum((arr - mean_val)**2) / (n - 1.0)
  end function variance
  
  ! Simple normal random number generator
  real function randn() result(r)
    real :: u1, u2
    call random_number(u1)
    call random_number(u2)
    r = sqrt(-2.0 * log(u1)) * cos(6.283185 * u2)
  end function randn
  
end program advanced_ifx_example
