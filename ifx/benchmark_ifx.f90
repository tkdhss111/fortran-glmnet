! Performance Benchmark for glmnet_wrapper with Intel ifx
! Compares different optimization levels and flags
!
! Compile with different flags and compare:
!   ifx -O2 glmnet.f glmnet_wrapper.f90 benchmark_ifx.f90 -o bench_O2
!   ifx -O3 -xHost glmnet.f glmnet_wrapper.f90 benchmark_ifx.f90 -o bench_O3
!   ifx -O3 -xHost -ipo glmnet.f glmnet_wrapper.f90 benchmark_ifx.f90 -o bench_ipo

program benchmark_glmnet_ifx
  use glmnet_wrapper
  use, intrinsic :: iso_fortran_env, only: real64
  implicit none
  
  ! Timing
  real(real64) :: start_time, end_time, elapsed
  
  ! Problem sizes
  integer, parameter :: n_small = 100, p_small = 10
  integer, parameter :: n_medium = 500, p_medium = 50
  integer, parameter :: n_large = 1000, p_large = 100
  
  ! Data
  real, allocatable :: x(:,:), y(:)
  real, allocatable :: yhat(:)
  type(glmnet_result) :: fit
  
  ! Results
  integer :: i, iter
  
  print '(A)', '================================================'
  print '(A)', '  glmnet_wrapper Performance Benchmark'
  print '(A)', '  Intel Fortran Compiler (ifx)'
  print '(A)', '================================================'
  print *
  
  ! Get compiler info
  print '(A)', 'Compiler flags used to build this executable:'
  print '(A)', '  Check with: ifx --version'
  print *
  
  ! ======================================================================
  ! Benchmark 1: Small problem (n=100, p=10)
  ! ======================================================================
  print '(A)', 'Benchmark 1: Small problem (n=100, p=10)'
  print '(A)', '----------------------------------------'
  
  allocate(x(n_small, p_small), y(n_small))
  call random_seed()
  call random_number(x)
  
  ! Generate response
  y = 2.0 * x(:,1) - 1.5 * x(:,2) + 0.8 * x(:,3)
  do i = 1, n_small
    y(i) = y(i) + randn() * 0.5
  end do
  
  ! Time single fit
  call cpu_time(start_time)
  do iter = 1, 100
    fit = glmnet_fit(x, y, alpha=0.5)
    call fit%deallocate()
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 100.0
  
  print '(A,F10.6,A)', '  Single fit (averaged): ', elapsed * 1000, ' ms'
  
  ! Time predictions
  fit = glmnet_fit(x, y, alpha=0.5, nlambda=20)
  call cpu_time(start_time)
  do iter = 1, 1000
    yhat = glmnet_predict(fit, x)
    deallocate(yhat)
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 1000.0
  
  print '(A,F10.6,A)', '  Prediction (averaged): ', elapsed * 1000, ' ms'
  call fit%deallocate()
  
  deallocate(x, y)
  print *
  
  ! ======================================================================
  ! Benchmark 2: Medium problem (n=500, p=50)
  ! ======================================================================
  print '(A)', 'Benchmark 2: Medium problem (n=500, p=50)'
  print '(A)', '----------------------------------------'
  
  allocate(x(n_medium, p_medium), y(n_medium))
  call random_number(x)
  
  y = 0.0
  do i = 1, 10  ! Only first 10 variables matter
    y = y + (11.0 - real(i)) * x(:,i) / 10.0
  end do
  do i = 1, n_medium
    y(i) = y(i) + randn() * 0.5
  end do
  
  ! Time single fit
  call cpu_time(start_time)
  do iter = 1, 20
    fit = glmnet_fit(x, y, alpha=0.5)
    call fit%deallocate()
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 20.0
  
  print '(A,F10.3,A)', '  Single fit (averaged): ', elapsed * 1000, ' ms'
  
  ! Time lambda path
  call cpu_time(start_time)
  do iter = 1, 10
    fit = glmnet_fit(x, y, alpha=0.5, nlambda=50)
    call fit%deallocate()
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 10.0
  
  print '(A,F10.3,A)', '  Lambda path (50) (avg): ', elapsed * 1000, ' ms'
  
  ! Time cross-validation
  call cpu_time(start_time)
  fit = glmnet_cv(x, y, alpha=0.5, nfolds=5)
  call cpu_time(end_time)
  elapsed = end_time - start_time
  
  print '(A,F10.3,A)', '  5-fold CV: ', elapsed * 1000, ' ms'
  call fit%deallocate()
  
  deallocate(x, y)
  print *
  
  ! ======================================================================
  ! Benchmark 3: Large problem (n=1000, p=100)
  ! ======================================================================
  print '(A)', 'Benchmark 3: Large problem (n=1000, p=100)'
  print '(A)', '----------------------------------------'
  
  allocate(x(n_large, p_large), y(n_large))
  call random_number(x)
  
  y = 0.0
  do i = 1, 20  ! Only first 20 variables matter
    y = y + (21.0 - real(i)) * x(:,i) / 20.0
  end do
  do i = 1, n_large
    y(i) = y(i) + randn() * 0.5
  end do
  
  ! Time single fit
  call cpu_time(start_time)
  do iter = 1, 10
    fit = glmnet_fit(x, y, alpha=0.5)
    call fit%deallocate()
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 10.0
  
  print '(A,F10.3,A)', '  Single fit (averaged): ', elapsed * 1000, ' ms'
  
  ! Time lambda path
  call cpu_time(start_time)
  do iter = 1, 5
    fit = glmnet_fit(x, y, alpha=0.5, nlambda=100)
    call fit%deallocate()
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 5.0
  
  print '(A,F10.3,A)', '  Lambda path (100) (avg): ', elapsed * 1000, ' ms'
  
  ! Time cross-validation
  call cpu_time(start_time)
  fit = glmnet_cv(x, y, alpha=0.5, nfolds=10)
  call cpu_time(end_time)
  elapsed = end_time - start_time
  
  print '(A,F10.3,A)', '  10-fold CV: ', elapsed * 1000, ' ms'
  call fit%deallocate()
  
  deallocate(x, y)
  print *
  
  ! ======================================================================
  ! Benchmark 4: Different alpha values (n=500, p=50)
  ! ======================================================================
  print '(A)', 'Benchmark 4: Different alpha values (n=500, p=50)'
  print '(A)', '----------------------------------------'
  
  allocate(x(n_medium, p_medium), y(n_medium))
  call random_number(x)
  y = 0.0
  do i = 1, 10
    y = y + (11.0 - real(i)) * x(:,i) / 10.0
  end do
  do i = 1, n_medium
    y(i) = y(i) + randn() * 0.5
  end do
  
  ! Ridge (alpha=0)
  call cpu_time(start_time)
  do iter = 1, 10
    fit = glmnet_fit(x, y, alpha=0.0)
    call fit%deallocate()
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 10.0
  print '(A,F10.3,A)', '  Ridge (alpha=0.0): ', elapsed * 1000, ' ms'
  
  ! Elastic Net (alpha=0.5)
  call cpu_time(start_time)
  do iter = 1, 10
    fit = glmnet_fit(x, y, alpha=0.5)
    call fit%deallocate()
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 10.0
  print '(A,F10.3,A)', '  Elastic Net (alpha=0.5): ', elapsed * 1000, ' ms'
  
  ! Lasso (alpha=1)
  call cpu_time(start_time)
  do iter = 1, 10
    fit = glmnet_fit(x, y, alpha=1.0)
    call fit%deallocate()
  end do
  call cpu_time(end_time)
  elapsed = (end_time - start_time) / 10.0
  print '(A,F10.3,A)', '  Lasso (alpha=1.0): ', elapsed * 1000, ' ms'
  
  deallocate(x, y)
  print *
  
  ! ======================================================================
  ! Summary
  ! ======================================================================
  print '(A)', '================================================'
  print '(A)', '  Benchmark Complete'
  print '(A)', '================================================'
  print *
  print '(A)', 'To compare different optimization levels:'
  print '(A)', '  1. Compile with -O2:'
  print '(A)', '     ifx -O2 glmnet.f glmnet_wrapper.f90 benchmark_ifx.f90 -o bench_O2'
  print '(A)', '  2. Compile with -O3 -xHost:'
  print '(A)', '     ifx -O3 -xHost glmnet.f glmnet_wrapper.f90 benchmark_ifx.f90 -o bench_O3'
  print '(A)', '  3. Compile with -O3 -xHost -ipo:'
  print '(A)', '     ifx -O3 -xHost -ipo glmnet.f glmnet_wrapper.f90 benchmark_ifx.f90 -o bench_ipo'
  print '(A)', '  4. Run each and compare times'
  print *
  
contains
  
  ! Simple normal random number generator
  real function randn() result(r)
    real :: u1, u2
    call random_number(u1)
    call random_number(u2)
    r = sqrt(-2.0 * log(u1)) * cos(6.283185 * u2)
  end function randn
  
end program benchmark_glmnet_ifx
