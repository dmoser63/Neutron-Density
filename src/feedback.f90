module feedback
! Functions here simulate thermal reactivity feedback
! 
use iso_fortran_env
implicit none
!
real(real64), parameter :: temp_equil    = 300.0     ! 300K of equilibrium temperature
real(real64)            :: reactor_temp = temp_equil ! Reactor temperature, starts at equilibirum

contains
function get_feedback(flux, dt)
! Returns reactivity feedback based on reactor flux and time step size
! This really should use its own time step...
!
! Constants are made up ... fixme units
real(real64)            :: get_feedback          ! reactivity feedback
real(real64)            :: flux                  ! neutron flux (nt)
real(real64)            :: dt                    ! time step [s]
real(real64), parameter :: alpha_temp    = -5E-5 ! Temperature coefficient of reactivity [K-1], note pcm = 1E-5
real(real64), parameter :: heat_per_nt_s = 10.0  ! Heat generation per neutron per second
real(real64), parameter :: heat_capacity = 4.2E3 ! Heat capacity [J kg-1 K-1]
real(real64), parameter :: ht_coeff      = 2.0   ! Heat conductivity
real(real64), parameter :: sb            = 5.670367E-8 ! Stefan–Boltzmann constant [W m−2 K−4]
real(real64), parameter :: emisivity     = 0.91  ! Concrete ..
real(real64)            :: fission_heating       ! Heating by fission
real(real64)            :: ht_conduction         ! Conduction heat loss
real(real64)            :: ht_radiation          ! Radiation heat loss
real(real64)            :: delta_reactor_temp    ! Reactor temperature change

! Heating up by neutrons 
fission_heating = flux*heat_per_nt_s  

! Heat loss by conduction
ht_conduction = ht_coeff*(reactor_temp - temp_equil) 

! Heat loss by radiation
ht_radiation = emisivity*sb*(reactor_temp**4 - temp_equil**4)

! Calculate new reactor temperature
delta_reactor_temp = dt*(fission_heating - ht_conduction - ht_radiation)/heat_capacity
reactor_temp = reactor_temp + delta_reactor_temp

! Feedback
get_feedback = delta_reactor_temp * alpha_temp

end function get_feedback

end module feedback