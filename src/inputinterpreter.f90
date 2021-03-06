!----------------------------------------------------------------------
! Module inputinterp contains subprograms responsible for reading and 
! interpreting the input file.     
!
! Authors: 
!   Dallas Moser <dmoser4@vols.utk.edu> 
!   Ondrej Chvala <ochvala@utk.edu>
! 
! License: GNU/GPL
!----------------------------------------------------------------------
! Initializes ... 
! TODO comments
!
module inputinterp
use iso_fortran_env
implicit none
!
integer, parameter                   :: fDebug = 3     ! debugging level
real(real64), protected, allocatable :: inputdata(:,:) ! input data array
             ! inputdata(:,1) - time steps
             ! inputdata(:,2) - externally imposed reactivity rho(t) in absolute values
             ! inputdata(:,3) - external source S(t) neutrons in neutrons/second             
integer, protected                   :: nRecords = -1  ! length of input array
logical, protected                   :: isThermal      ! reactor type
!
contains
  !------------------- init_input_data(filename) -------------------
  ! Initializes the input file by taking the input file name and   |
  ! reading the information from file to be used for calculations. |
  ! It will first read the logical isThermal to determine if the   |
  ! core is thermal. It then cycles through the input file to      |
  ! determine the number of given values stored as nRecords. This  |
  ! is used to allocate memory to store the data as the variable   |
  ! inputdata. The data is then stored by reading from the file    |
  ! through a linebuffer.                                          |
  !----------------------------------------------------------------- 
  subroutine init_input_data(filename)
  ! Reads in the input data file
    character(*), intent(in) :: filename    ! name of input file
    character(256)           :: linebuffer  ! buffer to read in data
    integer                  :: i, ioerr
    real(real64)             :: tmp1, tmp2  ! temporary vars for input validation
    if (fDebug>1) print *, "[DEBUG] Reading input from file: ", filename
    open(unit=10, file=filename, status="old", action="read", iostat=ioerr)
    if (ioerr/=0) stop "Input data file does not exist, bailing out!"
    read(10, *,iostat=ioerr) isThermal      ! first record: is the core thermal?
    if (ioerr/=0) stop "Input data file reading error, bailing out!"
    if (fDebug>1) print *, "[DEBUG] Thermal spectrum problem? ", isThermal
    ! Figure out the number of records
    nRecords = 0
    do
     read(10, *, iostat=ioerr) tmp1, tmp2
     if (ioerr>0) stop "Input data file reading error, bailing out!"
     if (ioerr<0) exit                      ! reached EOF
     nRecords = nRecords + 1
    end do
    if (fDebug>1) print *, "[DEBUG] There appears to be ",nRecords," state points in the input file ", filename
    if (nRecords<2) stop "Not enough input data, bailing out!"
    ! Now  read in the records
    rewind(10)
    read(10,*)                              ! skip the first line
    allocate(inputdata(nRecords,3))
    inputdata = 0.0                         ! make sure all is initialized
    if (fDebug>5) print *, "[DEBUG] Will read ", nRecords, " records from ", filename
    do i = 1, nRecords
      read(10, "(A)", iostat=ioerr) linebuffer
      if (ioerr.ne.0) stop "Input data file reading error, bailing out!"
      read(linebuffer, *,iostat=ioerr) inputdata(i,1), inputdata(i,2), inputdata(i,3)
      if (fDebug>5) print *, "[DEBUG] input data: ", i, inputdata(i,1), inputdata(i,2), inputdata(i,3)
!      inputdata(i,3) = inputdata(i,3)*1E25 ! source strength scaling for development purposes
    end do
  end subroutine init_input_data


  !---------------- get_reactivity(t) ----------------
  ! Returns the reactivity value at a given time (t) |
  !---------------------------------------------------
  function get_reactivity(t)
  ! Returns reactivity at time t
    real(real64), intent(in) :: t              ! desired time
    real(real64)             :: get_reactivity ! reactivity at desired time
    integer                  :: i              ! counting variable
    do i = 1, nRecords-1
      if (t >= inputdata(i,1) .and. t < inputdata(i+1,1)) then
        get_reactivity = inputdata(i,2)
        exit
      else if (t > inputdata(nRecords,1)) then
        get_reactivity = inputdata(nRecords,2)
      else
        cycle
      end if
    end do 
  end function get_reactivity


  !------------- get_reactivity_slope(t) -------------
  ! Returns the slope of the reactivity data at a    |
  ! given time (t), also known as d\rho/dt.          |
  !---------------------------------------------------
  function get_reactivity_slope(t)
  ! Returns d\rho/dt (t)
  ! This will not work well for large time steps in the input file
  ! TODO: Improve the code for larger time steps.
    real(real64), intent(in) :: t                    ! desired time
    real(real64)             :: get_reactivity_slope ! d\rho/dt at desired time
    integer                  :: i                    ! counting variable

    do i = 1, nRecords-1
      if (t >= inputdata(i,1) .and. t < inputdata(i+1,1)) then
        if (i==1) then      ! 1st time step, use forward method
          get_reactivity_slope = (inputdata(i+1,2)-inputdata(i,2)) / (inputdata(i+1,1)-inputdata(i,1))
          exit
        else                ! use centered method
          get_reactivity_slope = (inputdata(i+1,2)-inputdata(i-1,2)) / (inputdata(i+1,1)-inputdata(i-1,1))
          exit
        end if
      else if (t > inputdata(nRecords,1)) then ! backward
        get_reactivity_slope = (inputdata(i,2)-inputdata(i-1,2)) / (inputdata(i,1)-inputdata(i-1,1))
      else
        cycle
      end if
    end do 
  end function get_reactivity_slope



  !--------------- get_source(t) ---------------
  ! Returns source value at a given time (t).  |
  !---------------------------------------------
  function get_source(t)
    real(real64), intent(in) :: t          ! desired time
    real(real64)             :: get_source ! S(t) [n/sec]
    integer                  :: i          ! counting variable
    do i = 1, nRecords-1
      if (t >= inputdata(i,1) .and. t < inputdata(i+1,1)) then
        get_source = inputdata(i,3)
        exit
      else if (t > inputdata(nRecords,1)) then
        get_source = inputdata(nRecords,3)
      else
        cycle
      end if
    end do 
  end function get_source

  !--------------- get_source_slope(t) ---------------
  ! Returns the slope of the source data at a        |
  ! given time (t), also known as d\S/dt.            |
  !---------------------------------------------------
  function get_source_slope(t)
    real(real64), intent(in) :: t                    ! desired time
    real(real64)             :: get_source_slope     ! d\S/dt at desired time
    integer                  :: i                    ! counting variable

    do i = 1, nRecords-1
      if (t >= inputdata(i,1) .and. t < inputdata(i+1,1)) then
        if (i==1) then      ! 1st time step, use forward method
          get_source_slope = (inputdata(i+1,3)-inputdata(i,3)) / (inputdata(i+1,1)-inputdata(i,1))
          exit
        else                ! use centered method
          get_source_slope = (inputdata(i+1,3)-inputdata(i-1,3)) / (inputdata(i+1,1)-inputdata(i-1,1))
          exit
        end if
      else if (t > inputdata(nRecords,1)) then ! backward
        get_source_slope = (inputdata(i,3)-inputdata(i-1,3)) / (inputdata(i,1)-inputdata(i-1,1))
      else
        cycle
      end if
    end do 
  end function get_source_slope
  
  !--------------- nearest_time_step(t) ----------------
  ! Returns distance from a given time (t) to the next |
  ! time step specified in the input file              |
  !-----------------------------------------------------
  function nearest_time_step(t)
    real(real64), intent(in) :: t                 ! current time
    real(real64)             :: nearest_time_step ! distance to the next time step
    integer                  :: i                 ! counting variable
    do i = 1, nRecords-1
       if (t >= inputdata(i,1) .and. t < inputdata(i+1,1)) then
          nearest_time_step = inputdata(i+1,1) - t
          exit
       endif
    end do
  end function nearest_time_step

  !---------- get_start_time() ----------
  ! Returns the starting time specified |
  ! in the input file                   |
  !--------------------------------------
  function get_start_time()
    real(real64) ::  get_start_time ! starting time 
    get_start_time = inputdata(1,1)
  end function get_start_time

  !----------- get_end_time() -----------
  ! Returns the end time specified in   |
  ! the input file                      |
  !--------------------------------------
  function get_end_time()
    real(real64) :: get_end_time  ! ending time
    get_end_time = inputdata(nRecords,1)
  end function get_end_time

end module inputinterp

