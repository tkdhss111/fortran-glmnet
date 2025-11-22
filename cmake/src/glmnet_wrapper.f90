! =======================================================================
! Modern Fortran Wrapper for glmnet.f
! Provides clean interface to the original glmnet elastic net implementation
! =======================================================================
module glmnet_wrapper
  use, intrinsic :: iso_fortran_env, only: int32, error_unit
  implicit none
  private
  
  public :: glmnet_fit, glmnet_predict, glmnet_cv
  
  ! Result type for glmnet fits
  type, public :: glmnet_result
    integer(int32) :: lmu = 0          ! number of lambda values
    integer(int32) :: jerr = 0         ! error flag
    integer(int32) :: nobs = 0         ! number of observations
    integer(int32) :: nvars = 0        ! number of predictors
    integer(int32) :: nlp = 0          ! number of passes over data
    integer(int32), allocatable :: ia(:)      ! active variable indices
    integer(int32), allocatable :: nin(:)     ! number of nonzero coefs per lambda
    real, allocatable :: a0(:)            ! intercepts
    real, allocatable :: beta(:,:)        ! coefficients (nvars x lmu)
    real, allocatable :: lambda(:)        ! lambda values
    real, allocatable :: rsq(:)           ! R-squared values
    real, allocatable :: dev_ratio(:)     ! deviance ratio
    ! For cross-validation
    real, allocatable :: cvm(:)           ! mean CV error
    real, allocatable :: cvsd(:)          ! CV error standard deviation
    integer(int32) :: lambda_min_idx = 0      ! index of min CV error
    integer(int32) :: lambda_1se_idx = 0      ! index of 1-SE rule
  contains
    procedure :: deallocate => result_deallocate
    final :: result_finalize
  end type glmnet_result
  
contains

! =======================================================================
! Main fitting function - wraps elnet from glmnet.f
! =======================================================================
function glmnet_fit(x, y, alpha, lambda, nlambda, lambda_min_ratio, &
                    standardize, fit_intercept, weights, thresh, maxit, &
                    penalty_factor, lower_limits, upper_limits) result(fit)
  ! Inputs
  real, intent(in) :: x(:,:)                    ! predictors (nobs x nvars)
  real, intent(in) :: y(:)                      ! response (nobs)
  real, intent(in), optional :: alpha           ! elastic net parameter (default 1.0)
  real, intent(in), optional :: lambda(:)       ! user-supplied lambda sequence
  integer, intent(in), optional :: nlambda          ! number of lambdas (default 100)
  real, intent(in), optional :: lambda_min_ratio ! min lambda ratio (default auto)
  logical, intent(in), optional :: standardize      ! standardize predictors (default true)
  logical, intent(in), optional :: fit_intercept    ! include intercept (default true)
  real, intent(in), optional :: weights(:)      ! observation weights (default 1.0)
  real, intent(in), optional :: thresh          ! convergence threshold (default 1e-7)
  integer, intent(in), optional :: maxit            ! max iterations (default 100000)
  real, intent(in), optional :: penalty_factor(:) ! variable penalties (default 1.0)
  real, intent(in), optional :: lower_limits(:)   ! lower bounds on coefs (default -inf)
  real, intent(in), optional :: upper_limits(:)   ! upper bounds on coefs (default +inf)
  
  type(glmnet_result) :: fit
  
  ! Local variables
  integer :: nobs, nvars, ka, isd, intr, nlam, ne, nx, maxit_loc
  real :: parm, flmin, thr
  real, allocatable :: x_copy(:,:), y_copy(:), w(:), vp(:), ulam(:)
  real, allocatable :: cl(:,:), a0(:), ca(:,:), rsq(:), alm(:)
  integer, allocatable :: jd(:), ia(:), nin(:)
  
  ! Get dimensions
  nobs = size(x, 1)
  nvars = size(x, 2)
  fit%nobs = nobs
  fit%nvars = nvars
  
  ! Set parameters
  ka = 1  ! use covariance updating algorithm (ka=2 for naive)
  
  if (present(alpha)) then
    parm = alpha
  else
    parm = 1.0
  end if
  
  if (present(standardize)) then
    if (standardize) then
      isd = 1
    else
      isd = 0
    end if
  else
    isd = 1  ! default is true
  end if
  
  if (present(fit_intercept)) then
    if (fit_intercept) then
      intr = 1
    else
      intr = 0
    end if
  else
    intr = 1  ! default is true
  end if
  
  if (present(thresh)) then
    thr = thresh
  else
    thr = 1.0e-7
  end if
  
  if (present(nlambda)) then
    nlam = nlambda
  else
    nlam = 100
  end if
  
  if (present(maxit)) then
    maxit_loc = maxit
  else
    maxit_loc = 100000
  end if
  
  ne = nvars
  nx = nvars
  
  ! Allocate and initialize arrays
  allocate(x_copy(nobs, nvars), y_copy(nobs), w(nobs))
  allocate(vp(nvars), cl(2, nvars), jd(1))
  allocate(ulam(nlam), a0(nlam), ca(nx, nlam))
  allocate(ia(nx), nin(nlam), rsq(nlam), alm(nlam))
  
  ! Copy data (glmnet modifies arrays in-place)
  x_copy = x
  y_copy = y
  
  ! Set weights
  if (present(weights)) then
    w = weights
  else
    w = 1.0
  end if
  
  ! Set penalty factors
  if (present(penalty_factor)) then
    vp = penalty_factor
  else
    vp = 1.0
  end if
  
  ! Set bounds
  if (present(lower_limits) .and. present(upper_limits)) then
    cl(1, :) = lower_limits
    cl(2, :) = upper_limits
  else if (present(lower_limits)) then
    cl(1, :) = lower_limits
    cl(2, :) = 9.9e35
  else if (present(upper_limits)) then
    cl(1, :) = -9.9e35
    cl(2, :) = upper_limits
  else
    cl(1, :) = -9.9e35
    cl(2, :) = 9.9e35
  end if
  
  ! Set lambda sequence
  jd(1) = 0  ! use all variables
  
  if (present(lambda)) then
    ! User-supplied lambda sequence
    nlam = size(lambda)
    deallocate(ulam, a0, ca, rsq, alm)
    allocate(ulam(nlam), a0(nlam), ca(nx, nlam), rsq(nlam), alm(nlam))
    ulam = lambda
    flmin = 1.0  ! signals to use supplied lambda
  else
    ! Auto-generate lambda sequence
    if (present(lambda_min_ratio)) then
      flmin = lambda_min_ratio
    else
      ! Default: 0.0001 if nobs >= nvars, else 0.01
      flmin = merge(0.0001, 0.01, nobs >= nvars)
    end if
    ulam = 0.0  ! will be computed internally
  end if
  
  ! Call glmnet
  call elnet(ka, parm, nobs, nvars, x_copy, y_copy, w, jd, vp, cl, &
             ne, nx, nlam, flmin, ulam, thr, isd, intr, maxit_loc, &
             fit%lmu, a0, ca, ia, nin, rsq, alm, fit%nlp, fit%jerr)
  
  ! Check for errors
  if (fit%jerr /= 0) then
    if (fit%jerr > 0) then
      write(error_unit, '(A,I0)') 'glmnet error: jerr = ', fit%jerr
      if (fit%jerr < 7777) then
        write(error_unit, '(A)') '  Memory allocation error'
      else if (fit%jerr == 7777) then
        write(error_unit, '(A)') '  All predictors have zero variance'
      else if (fit%jerr == 10000) then
        write(error_unit, '(A)') '  All penalty factors are <= 0'
      end if
      return
    else
      ! Non-fatal error (convergence issues)
      write(error_unit, '(A,I0)') 'glmnet warning: jerr = ', fit%jerr
      write(error_unit, '(A)') '  Partial output returned'
    end if
  end if
  
  ! Extract results
  if (fit%lmu > 0) then
    allocate(fit%a0(fit%lmu))
    allocate(fit%beta(nvars, fit%lmu))
    allocate(fit%lambda(fit%lmu))
    allocate(fit%rsq(fit%lmu))
    allocate(fit%nin(fit%lmu))
    allocate(fit%ia(nx))
    
    fit%a0 = a0(1:fit%lmu)
    fit%lambda = alm(1:fit%lmu)
    fit%rsq = rsq(1:fit%lmu)
    fit%nin = nin(1:fit%lmu)
    fit%ia = ia
    
    ! Uncompress coefficients
    call uncompress_coefs(ca(:, 1:fit%lmu), ia, nin(1:fit%lmu), nvars, fit%lmu, fit%beta)
  end if
  
  ! Cleanup
  deallocate(x_copy, y_copy, w, vp, cl, jd, ulam, a0, ca, ia, nin, rsq, alm)
  
end function glmnet_fit

! =======================================================================
! Prediction function
! =======================================================================
function glmnet_predict(fit, newx, s) result(yhat)
  type(glmnet_result), intent(in) :: fit
  real, intent(in) :: newx(:,:)     ! new predictors (n_new x nvars)
  integer(int32), intent(in), optional :: s  ! which lambda (default: lambda_min or last)
  real, allocatable :: yhat(:)
  
  integer :: idx, n_new
  
  if (fit%lmu == 0 .or. .not. allocated(fit%beta)) then
    write(error_unit, '(A)') 'Error: glmnet model not fitted'
    allocate(yhat(0))
    return
  end if
  
  ! Determine which lambda to use
  if (present(s)) then
    idx = s
  else if (fit%lambda_min_idx > 0) then
    idx = fit%lambda_min_idx
  else
    idx = fit%lmu  ! use last lambda
  end if
  
  if (idx < 1 .or. idx > fit%lmu) then
    write(error_unit, '(A,I0,A,I0)') 'Error: lambda index ', idx, &
                                      ' out of range [1, ', fit%lmu, ']'
    allocate(yhat(0))
    return
  end if
  
  ! Compute predictions
  n_new = size(newx, 1)
  allocate(yhat(n_new))
  yhat = matmul(newx, fit%beta(:, idx)) + fit%a0(idx)
  
end function glmnet_predict

! =======================================================================
! Cross-validation
! =======================================================================
function glmnet_cv(x, y, alpha, lambda, nfolds, weights, standardize, &
                   fit_intercept, thresh, maxit, penalty_factor, &
                   type_measure) result(fit)
  ! Inputs
  real, intent(in) :: x(:,:)
  real, intent(in) :: y(:)
  real, intent(in), optional :: alpha
  real, intent(in), optional :: lambda(:)
  integer, intent(in), optional :: nfolds
  real, intent(in), optional :: weights(:)
  logical, intent(in), optional :: standardize
  logical, intent(in), optional :: fit_intercept
  real, intent(in), optional :: thresh
  integer, intent(in), optional :: maxit
  real, intent(in), optional :: penalty_factor(:)
  character(len=*), intent(in), optional :: type_measure  ! 'mse', 'mae', 'deviance'
  
  type(glmnet_result) :: fit
  
  ! Local variables
  integer :: nobs, nfolds_loc, fold, nlam
  integer, allocatable :: fold_ids(:)
  real, allocatable :: cv_errors(:,:)
  type(glmnet_result) :: fit_full
  character(len=20) :: measure
  
  nobs = size(x, 1)
  nfolds_loc = merge(nfolds, min(10, nobs), present(nfolds))
  measure = merge(type_measure, 'mse', present(type_measure))
  
  ! Fit on full data to get lambda sequence
  fit_full = glmnet_fit(x, y, alpha=alpha, lambda=lambda, weights=weights, &
                        standardize=standardize, fit_intercept=fit_intercept, &
                        thresh=thresh, maxit=maxit, penalty_factor=penalty_factor)
  
  if (fit_full%jerr /= 0 .or. fit_full%lmu == 0) then
    fit = fit_full
    return
  end if
  
  nlam = fit_full%lmu
  
  ! Create CV folds
  allocate(fold_ids(nobs))
  allocate(cv_errors(nlam, nfolds_loc))
  call create_folds(nobs, nfolds_loc, fold_ids)
  
  ! Perform cross-validation
  do fold = 1, nfolds_loc
    call process_cv_fold(fold, x, y, fit_full%lambda(1:nlam), fold_ids, &
                         cv_errors(:, fold), alpha, weights, standardize, &
                         fit_intercept, thresh, maxit, penalty_factor, measure)
  end do
  
  ! Copy full fit results
  fit = fit_full
  
  ! Compute CV statistics
  allocate(fit%cvm(nlam), fit%cvsd(nlam))
  call compute_cv_stats(cv_errors, nfolds_loc, fit%cvm, fit%cvsd)
  
  ! Find optimal lambdas
  call find_optimal_lambdas(fit%cvm, fit%cvsd, fit%lambda_min_idx, fit%lambda_1se_idx)
  
  deallocate(fold_ids, cv_errors)
  
end function glmnet_cv

! =======================================================================
! Helper subroutines
! =======================================================================

subroutine uncompress_coefs(ca, ia, nin, nvars, nlam, beta)
  real, intent(in) :: ca(:,:)
  integer(int32), intent(in) :: ia(:), nin(:)
  integer, intent(in) :: nvars, nlam
  real, intent(out) :: beta(nvars, nlam)
  integer :: k, j
  
  beta = 0.0
  do k = 1, nlam
    do j = 1, nin(k)
      if (ia(j) > 0 .and. ia(j) <= nvars) then
        beta(ia(j), k) = ca(j, k)
      end if
    end do
  end do
end subroutine uncompress_coefs

subroutine create_folds(n, nfolds, fold_ids)
  integer, intent(in) :: n, nfolds
  integer(int32), intent(out) :: fold_ids(n)
  integer :: i, swap_idx, temp
  integer, allocatable :: perm(:)
  real :: rand_val
  
  allocate(perm(n))
  do i = 1, n
    perm(i) = i
  end do
  
  ! Shuffle
  do i = n, 2, -1
    call random_number(rand_val)
    swap_idx = int(rand_val * real(i)) + 1
    temp = perm(i)
    perm(i) = perm(swap_idx)
    perm(swap_idx) = temp
  end do
  
  ! Assign folds
  do i = 1, n
    fold_ids(perm(i)) = mod(i - 1, nfolds) + 1
  end do
  
  deallocate(perm)
end subroutine create_folds

subroutine process_cv_fold(fold, x, y, lambda, fold_ids, cv_error, &
                           alpha, weights, standardize, fit_intercept, &
                           thresh, maxit, penalty_factor, measure)
  integer, intent(in) :: fold
  real, intent(in) :: x(:,:), y(:), lambda(:)
  integer(int32), intent(in) :: fold_ids(:)
  real, intent(out) :: cv_error(:)
  real, intent(in), optional :: alpha, weights(:), thresh, penalty_factor(:)
  logical, intent(in), optional :: standardize, fit_intercept
  integer, intent(in), optional :: maxit
  character(len=*), intent(in) :: measure
  
  integer :: n, nvars, n_train, n_test, i, train_idx, test_idx, nlam
  real, allocatable :: x_train(:,:), y_train(:), w_train(:)
  real, allocatable :: x_test(:,:), y_test(:), yhat(:), resid(:)
  type(glmnet_result) :: fit
  logical, allocatable :: test_mask(:)
  
  n = size(x, 1)
  nvars = size(x, 2)
  nlam = size(lambda)
  
  ! Create train/test split
  allocate(test_mask(n))
  test_mask = (fold_ids == fold)
  n_test = count(test_mask)
  n_train = n - n_test
  
  allocate(x_train(n_train, nvars), y_train(n_train))
  allocate(x_test(n_test, nvars), y_test(n_test))
  allocate(w_train(n_train))
  
  train_idx = 0
  test_idx = 0
  do i = 1, n
    if (test_mask(i)) then
      test_idx = test_idx + 1
      x_test(test_idx, :) = x(i, :)
      y_test(test_idx) = y(i)
    else
      train_idx = train_idx + 1
      x_train(train_idx, :) = x(i, :)
      y_train(train_idx) = y(i)
      if (present(weights)) then
        w_train(train_idx) = weights(i)
      else
        w_train(train_idx) = 1.0
      end if
    end if
  end do
  
  ! Fit on training data
  fit = glmnet_fit(x_train, y_train, alpha=alpha, lambda=lambda, &
                   weights=w_train, standardize=standardize, &
                   fit_intercept=fit_intercept, thresh=thresh, &
                   maxit=maxit, penalty_factor=penalty_factor)
  
  ! Compute test error
  cv_error = huge(1.0)
  if (fit%jerr == 0 .and. fit%lmu > 0) then
    do i = 1, min(fit%lmu, nlam)
      yhat = glmnet_predict(fit, x_test, s=i)
      resid = y_test - yhat
      
      select case(trim(measure))
      case('mse', 'deviance')
        cv_error(i) = sum(resid**2) / real(n_test)
      case('mae')
        cv_error(i) = sum(abs(resid)) / real(n_test)
      case default
        cv_error(i) = sum(resid**2) / real(n_test)
      end select
    end do
  end if
  
  deallocate(x_train, y_train, w_train, x_test, y_test, test_mask)
  call fit%deallocate()
  
end subroutine process_cv_fold

subroutine compute_cv_stats(cv_errors, nfolds, cvm, cvsd)
  real, intent(in) :: cv_errors(:,:)
  integer, intent(in) :: nfolds
  real, intent(out) :: cvm(:), cvsd(:)
  integer :: i, nlam
  real, allocatable :: deviations(:)
  
  nlam = size(cv_errors, 1)
  allocate(deviations(nfolds))
  
  do i = 1, nlam
    cvm(i) = sum(cv_errors(i, :)) / real(nfolds)
    deviations = cv_errors(i, :) - cvm(i)
    cvsd(i) = sqrt(sum(deviations**2) / max(1, nfolds - 1))
  end do
  
  deallocate(deviations)
end subroutine compute_cv_stats

subroutine find_optimal_lambdas(cvm, cvsd, idx_min, idx_1se)
  real, intent(in) :: cvm(:), cvsd(:)
  integer(int32), intent(out) :: idx_min, idx_1se
  integer :: i, nlam
  real :: min_cvm, threshold
  
  nlam = size(cvm)
  
  ! Find minimum
  idx_min = 1
  min_cvm = cvm(1)
  do i = 2, nlam
    if (cvm(i) < min_cvm) then
      min_cvm = cvm(i)
      idx_min = i
    end if
  end do
  
  ! Find 1-SE rule
  threshold = min_cvm + cvsd(idx_min)
  idx_1se = idx_min
  do i = 1, nlam
    if (cvm(i) <= threshold) then
      idx_1se = i
      exit
    end if
  end do
  
end subroutine find_optimal_lambdas

subroutine result_deallocate(this)
  class(glmnet_result), intent(inout) :: this
  if (allocated(this%ia)) deallocate(this%ia)
  if (allocated(this%nin)) deallocate(this%nin)
  if (allocated(this%a0)) deallocate(this%a0)
  if (allocated(this%beta)) deallocate(this%beta)
  if (allocated(this%lambda)) deallocate(this%lambda)
  if (allocated(this%rsq)) deallocate(this%rsq)
  if (allocated(this%dev_ratio)) deallocate(this%dev_ratio)
  if (allocated(this%cvm)) deallocate(this%cvm)
  if (allocated(this%cvsd)) deallocate(this%cvsd)
end subroutine result_deallocate

subroutine result_finalize(this)
  type(glmnet_result), intent(inout) :: this
  call this%deallocate()
end subroutine result_finalize

end module glmnet_wrapper
