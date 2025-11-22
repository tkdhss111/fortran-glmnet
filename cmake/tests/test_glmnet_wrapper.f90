program test_glmnet_wrapper
  use glmnet_wrapper
  implicit none
  
  integer :: n, p, i
  real, allocatable :: x(:,:), y(:), w(:), newx(:,:), yhat(:)
  type(glmnet_result) :: fit, cv_fit
  
  ! Test data
  n = 4
  p = 3
  allocate(x(n, p), y(n), w(n), newx(n, p))
  
  ! Same test data as before
  y = [7.1, 12.4, 21.5, 36.0]
  w = [1.0, 2.0, 3.0, 4.0]
  
  x(1, :) = [1.0, 2.0, 4.0]
  x(2, :) = [1.0, 3.0, 9.0]
  x(3, :) = [1.0, 4.0, 16.0]
  x(4, :) = [1.0, 5.0, 25.0]
  
  newx(1, :) = [2.0, 3.0, 7.0]
  newx(2, :) = [1.0, 3.0, 9.0]
  newx(3, :) = [1.0, 4.0, 16.0]
  newx(4, :) = [1.0, 5.0, 25.0]
  
  print *, '======================================='
  print *, 'Testing Modern glmnet Wrapper Module'
  print *, '======================================='
  print *, ''
  
  ! Test 1: Single lambda with elastic net
  print *, 'Test 1: lambda=0.1, alpha=0.5 (Elastic Net)'
  print *, '--------------------------------------------'
  fit = glmnet_fit(x, y, alpha=0.5, lambda=[0.1], weights=w, &
                   standardize=.true., fit_intercept=.true.)
  
  if (fit%jerr == 0 .and. fit%lmu > 0) then
    print '(A,I3)', ' Number of lambda values fitted: ', fit%lmu
    print '(A,F16.10)', ' Intercept: ', fit%a0(1)
    print *, ' Coefficients:'
    do i = 1, p
      print '(A,I1,A,E20.12)', '   beta[', i, '] = ', fit%beta(i, 1)
    end do
    print '(A,F16.10)', ' R-squared: ', fit%rsq(1)
    
    ! Make predictions
    yhat = glmnet_predict(fit, newx, s=1)
    print *, ' Predictions:'
    do i = 1, n
      print '(A,I1,A,F16.10)', '   yhat[', i, '] = ', yhat(i)
    end do
  else
    print *, ' Error: jerr = ', fit%jerr
  end if
  print *, ''
  call fit%deallocate()
  
  ! Test 2: Lambda sequence with lasso
  print *, 'Test 2: lambda=1.0, alpha=1.0 (Lasso)'
  print *, '--------------------------------------'
  fit = glmnet_fit(x, y, alpha=1.0, lambda=[1.0], weights=w)
  
  if (fit%jerr == 0 .and. fit%lmu > 0) then
    print '(A,F16.10)', ' Intercept: ', fit%a0(1)
    print *, ' Coefficients:'
    do i = 1, p
      print '(A,I1,A,E20.12)', '   beta[', i, '] = ', fit%beta(i, 1)
    end do
    print '(A,F16.10)', ' R-squared: ', fit%rsq(1)
    print '(A,I3)', ' Number of non-zero coefficients: ', fit%nin(1)
  else
    print *, ' Error: jerr = ', fit%jerr
  end if
  print *, ''
  call fit%deallocate()
  
  ! Test 3: Ridge regression
  print *, 'Test 3: lambda=0.1, alpha=0.0 (Ridge)'
  print *, '--------------------------------------'
  fit = glmnet_fit(x, y, alpha=0.0, lambda=[0.1], weights=w)
  
  if (fit%jerr == 0 .and. fit%lmu > 0) then
    print '(A,F16.10)', ' Intercept: ', fit%a0(1)
    print *, ' Coefficients:'
    do i = 1, p
      print '(A,I1,A,E20.12)', '   beta[', i, '] = ', fit%beta(i, 1)
    end do
    print '(A,F16.10)', ' R-squared: ', fit%rsq(1)
  else
    print *, ' Error: jerr = ', fit%jerr
  end if
  print *, ''
  call fit%deallocate()
  
  ! Test 4: Automatic lambda sequence
  print *, 'Test 4: Automatic lambda sequence (alpha=0.5)'
  print *, '----------------------------------------------'
  fit = glmnet_fit(x, y, alpha=0.5, nlambda=10, weights=w)
  
  if (fit%jerr == 0 .and. fit%lmu > 0) then
    print '(A,I3)', ' Number of lambda values: ', fit%lmu
    print *, ' Lambda sequence:'
    do i = 1, min(5, fit%lmu)
      print '(A,I2,A,E12.4,A,I2,A,F8.4)', '   lambda[', i, '] = ', fit%lambda(i), &
            ', nin = ', fit%nin(i), ', R² = ', fit%rsq(i)
    end do
    if (fit%lmu > 5) print *, '   ...'
  else
    print *, ' Error: jerr = ', fit%jerr
  end if
  print *, ''
  call fit%deallocate()
  
  ! Test 5: Cross-validation
  print *, 'Test 5: Cross-validation (3-fold)'
  print *, '----------------------------------'
  cv_fit = glmnet_cv(x, y, alpha=0.5, nfolds=3, weights=w)
  
  if (cv_fit%jerr == 0 .and. cv_fit%lmu > 0) then
    print '(A,I3)', ' Number of lambda values: ', cv_fit%lmu
    print '(A,I3)', ' Lambda min index: ', cv_fit%lambda_min_idx
    print '(A,I3)', ' Lambda 1-SE index: ', cv_fit%lambda_1se_idx
    if (cv_fit%lambda_min_idx > 0) then
      print '(A,E12.4)', ' Best lambda (min CV): ', cv_fit%lambda(cv_fit%lambda_min_idx)
      print '(A,F12.6)', ' CV error at min: ', cv_fit%cvm(cv_fit%lambda_min_idx)
      print *, ' Coefficients at lambda.min:'
      do i = 1, p
        print '(A,I1,A,E20.12)', '   beta[', i, '] = ', &
              cv_fit%beta(i, cv_fit%lambda_min_idx)
      end do
    end if
    
    ! Predict using CV-selected model
    yhat = glmnet_predict(cv_fit, newx)
    print *, ' Predictions (using lambda.min):'
    do i = 1, n
      print '(A,I1,A,F10.4,A,F10.4)', '   obs[', i, ']: y=', y(i), ', yhat=', yhat(i)
    end do
  else
    print *, ' Error: jerr = ', cv_fit%jerr
  end if
  print *, ''
  call cv_fit%deallocate()
  
  print *, '======================================='
  print *, 'All tests completed!'
  print *, '======================================='
  
  deallocate(x, y, w, newx)
  if (allocated(yhat)) deallocate(yhat)
  
end program test_glmnet_wrapper
