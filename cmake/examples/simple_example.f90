! Simple example using glmnet_wrapper with plain real type
program simple_example
  use glmnet_wrapper
  implicit none
  
  ! Declare variables with plain real type
  real :: x(100, 5), y(100)
  real, allocatable :: yhat(:)
  type(glmnet_result) :: fit
  integer :: i, j
  
  ! Generate some random data
  call random_number(x)
  do i = 1, 100
    y(i) = 2.0 * x(i,1) - 3.0 * x(i,2) + 1.5 * x(i,3) + randn()
  end do
  
  ! Fit elastic net (alpha=0.5, automatic lambda sequence)
  fit = glmnet_fit(x, y, alpha=0.5)
  
  ! Check for errors
  if (fit%jerr /= 0) then
    print *, 'Error fitting model:', fit%jerr
    stop
  end if
  
  ! Print results
  print *, 'Successfully fitted model'
  print *, 'Number of lambda values:', fit%lmu
  print *, 'Optimal lambda:', fit%lambda(fit%lmu)
  print *, ''
  print *, 'Coefficients at optimal lambda:'
  do j = 1, 5
    if (abs(fit%beta(j, fit%lmu)) > 1.0e-6) then
      print '(A,I1,A,F10.6)', '  beta[', j, '] = ', fit%beta(j, fit%lmu)
    end if
  end do
  
  ! Make predictions
  yhat = glmnet_predict(fit, x)
  
  ! Compute R-squared manually
  print *, ''
  print *, 'R-squared:', 1.0 - sum((y - yhat)**2) / sum((y - sum(y)/100.0)**2)
  
  ! Clean up
  call fit%deallocate()
  
contains
  
  ! Simple normal random number generator
  real function randn()
    real :: u1, u2
    call random_number(u1)
    call random_number(u2)
    randn = sqrt(-2.0 * log(u1)) * cos(6.283185 * u2)
  end function randn
  
end program simple_example
