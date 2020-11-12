!
! Copyright (C) 2003-2013 Quantum ESPRESSO and Wannier90 groups
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!
! Written by Riccardo De Gennaro, EPFL (Sept 2020).
!
!
!---------------------------------------------------------------------
MODULE cp_files
  !-------------------------------------------------------------------
  !
  !
  IMPLICIT NONE
  !
  PRIVATE
  !
  PUBLIC :: write_wannier_cp
  !
  CONTAINS
  !
  !-------------------------------------------------------------------
  SUBROUTINE write_wannier_cp( iun, nword, npwx, nwann, nrtot, ig_l2g )
    !-----------------------------------------------------------------
    !
    ! ...  This routine takes the Wannier functions in input and 
    ! ...  writes them into a file, readable by the CP-Koopmans code,
    ! ...  called 'evcw.dat'
    !
    USE kinds,               ONLY : DP
    USE io_global,           ONLY : ionode, ionode_id
    USE mp_bands,            ONLY : intra_bgrp_comm
    USE mp_wave,             ONLY : mergewf
    USE mp_world,            ONLY : mpime, nproc
    USE mp,                  ONLY : mp_sum
    USE noncollin_module,    ONLY : npol
    USE buffers,             ONLY : get_buffer
    !
    !
    IMPLICIT NONE
    !
    INTEGER, INTENT(IN) :: iun                   ! unit to the WFs buffer
    INTEGER, INTENT(IN) :: nword                 ! record length WF file
    INTEGER, INTENT(IN) :: npwx                  ! num PW evc
    INTEGER, INTENT(IN) :: nwann                 ! num of (primitive cell) WFs
    INTEGER, INTENT(IN) :: nrtot                 ! num of k-points
    INTEGER, INTENT(IN) :: ig_l2g(:)
    !
    INTEGER :: io_level = 1
    INTEGER :: cp_unit = 125
    INTEGER :: npw_g                             ! global number of PWs
    INTEGER :: ir, ibnd, ispin, ipw
    INTEGER :: nwannx
    COMPLEX(DP), ALLOCATABLE :: evc(:,:)
    COMPLEX(DP), ALLOCATABLE :: evc_g(:)
    !
    !
    ALLOCATE( evc(npwx*npol,nwann) )
    !
    nwannx = nwann * nrtot     ! number of bands in the supercell
    !
    !
    npw_g = npwx
    CALL mp_sum( npw_g, intra_bgrp_comm )
    ALLOCATE( evc_g(npw_g) )
    !
    IF ( ionode ) THEN
      OPEN( UNIT=cp_unit, FILE='evcw.dat', STATUS='unknown', FORM='unformatted' )
      WRITE( cp_unit ) npw_g, nwannx*2
    ENDIF
    !
    ! ... here we gather the wfc from all the processes
    ! ... and we write it to file (nspin=2 in CP-Koopmans)
    !
    DO ispin = 1, 2
      !
      DO ir = 1, nrtot
        !
        CALL get_buffer( evc, nword, iun, ir )
        !
        DO ibnd = 1, nwann
          !
          evc_g(:) = ( 0.D0, 0.D0 )
          CALL mergewf( evc(:,ibnd), evc_g, npwx, ig_l2g, mpime, &
                        nproc, ionode_id, intra_bgrp_comm )
  
          !
          IF ( ionode ) THEN
            !
            WRITE( cp_unit ) ( evc_g(ipw), ipw=1,npw_g )
            !
          ENDIF
          !
        ENDDO
        !
      ENDDO
      !
    ENDDO
    !
    IF ( ionode ) CLOSE( cp_unit )
    !
    !
  END SUBROUTINE write_wannier_cp
  !
  !
END MODULE cp_files