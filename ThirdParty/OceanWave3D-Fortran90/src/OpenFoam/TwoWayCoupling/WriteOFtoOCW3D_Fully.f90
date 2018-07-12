SUBROUTINE WriteOFtoOCW3D_Fully
!
! Writes the free surface elevation and velocities calculated by OpenFOAM to the OCW3D solution
!
! By Jost Kemper
USE GlobalVariables, ONLY: WaveField, OfPoints, EOF, UxOF, UyOF, UzOF, alpha, beta, gamma, FineGrid,& 
						   GhostGridX, GhostGridY,GhostGridZ, dt, fileop, g, time, Phist,Ehist, k1_Phist, &
						    curvilinearONOFF
USE Precision
USE Constants
USE DataTypes

IMPLICIT NONE
  
INTEGER :: i, p
REAL(KIND=long) :: EOFtemp, EOCWtemp, UxOFtemp, UxOCWtemp, UyOFtemp, UyOCWtemp, UzOFtemp, UzOCWtemp, POFtemp, POCWtemp
REAL(KIND=long), DIMENSION(FineGrid%Nx+2*GhostGridX,FineGrid%Ny+2*GhostGridY) :: rhsE,rhsP, Ptemp, Eopen, Uxopen, Wopen
TYPE (Wavefield_FS) :: WavefieldCopy
!JK for writing
character(len=8) :: fmt ! format descriptor
character(len=20) :: strTime

fmt = '(I7.7)' ! an integer of width 5 with zeros at the left
write(strTime,*) INT(time*100) ! converting integer to string using a 'internal file'


Write(*,*) 'Writing OpenFOAM solution to OceanWave3D (fully coupled)'



!write OCW sloution
IF (.TRUE.)	THEN

Open(fileop(17),file='OCW_'//trim(adjustl(strTime))//'.chk',status='unknown')

DO p=1, SIZE(FineGrid%x) 

			!write(fileop(15),*)  FineGrid%x(p,1), Wavefield%Px(p,1), Wavefield%W(p,1)
			write(fileop(17),*)  FineGrid%x(p,1),  Wavefield%Px(p,1), Wavefield%W(p,1), Wavefield%E(p,1), Wavefield%Ex(p,1), Wavefield%Exx(p,1), Wavefield%P(p,1)
			!x ux uz Eta Etax Etaxx P
END DO

Close(fileop(17))

!STOP!!!

ENDIF
!copy wavefield
call ALLOCATE_Wavefield_Type(wavefieldCopy, FineGrid%Nx, FineGrid%Ny, FineGrid%Nz, GhostGridX, GhostGridy, GhostGridZ, 0)
wavefieldCopy%E = Wavefield%E
wavefieldCopy%Ex = Wavefield%Ex
wavefieldCopy%Exx = Wavefield%Exx
wavefieldCopy%P = Wavefield%P
wavefieldCopy%Px = Wavefield%Px
wavefieldCopy%W = Wavefield%W
WavefieldCopy%SourceEx = Wavefield%SourceEx
WaveFieldCopy%WHist = WaveField%WHist
WaveFieldCopy%EtatHist = WaveField%EtatHist

!initialize TWC
Eopen =0.0
Uxopen = 0.0
Wopen = 0.0



DO i=1, SIZE(OfPoints)
	! write surface elevation to wavefield
	EOCWtemp = WaveField%E(OfPoints(i)%xInd, OfPoints(i)%yInd)*(one - OfPoints(i)%relax)
	EOFtemp = EOF(i)*OfPoints(i)%relax
	WaveField%E(OfPoints(i)%xInd, OfPoints(i)%yInd) = EOFtemp + EOCWtemp
	Eopen(OfPoints(i)%xInd, OfPoints(i)%yInd) = EOF(i)
	
	! write Ux to Px
	IF (FineGrid%Nx>1) THEN
		UxOCWtemp = WaveField%Px(OfPoints(i)%xInd, OfPoints(i)%yInd)*(one - OfPoints(i)%relax)
		UxOFtemp = UxOF(i)*OfPoints(i)%relax
		WaveField%Px(OfPoints(i)%xInd, OfPoints(i)%yInd) = UxOFtemp + UxOCWtemp
		Uxopen(OfPoints(i)%xInd, OfPoints(i)%yInd) = UxOF(i)
	END IF
	
	! write Uy to Py
	IF (FineGrid%Ny>1) THEN
	UyOCWtemp = WaveField%Py(OfPoints(i)%xInd, OfPoints(i)%yInd)*(one - OfPoints(i)%relax)
	UyOFtemp = UyOF(i)*OfPoints(i)%relax
	WaveField%Py(OfPoints(i)%xInd, OfPoints(i)%yInd) = UyOFtemp + UyOCWtemp
	END IF
	
	! write Uz to W
	UzOCWtemp = WaveField%W(OfPoints(i)%xInd, OfPoints(i)%yInd)*(one - OfPoints(i)%relax)
	UzOFtemp = UzOF(i)*OfPoints(i)%relax
	WaveField%W(OfPoints(i)%xInd, OfPoints(i)%yInd) = UzOFtemp + UzOCWtemp
	Wopen(OfPoints(i)%xInd, OfPoints(i)%yInd) = UzOF(i)
	
END DO

!smooth Eta, Px and Py
CALL OFsmoothing(wavefield%E, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)
IF (FineGrid%Nx>1) THEN
	CALL OFsmoothing(wavefield%Px, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)
END IF
IF (FineGrid%Ny>1) THEN
	CALL OFsmoothing(wavefield%Py, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)
END IF
CALL OFsmoothing(wavefield%W, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)

!Update derivates of Eta and smooth in between
IF (curvilinearONOFF==0) THEN
    ! Differentiation in the Free Surface plane
	IF (FineGrid%Nx>1) THEN
	   CALL UpdateGhostLayerX(Wavefield%E,Wavefield%SourceEx,FineGrid%Nx+2*GhostGridX,FineGrid%Ny+2*GhostGridY,&
       		FineGrid%DiffStencils,alpha,GhostGridX,GhostGridY)
       CALL DiffXEven(Wavefield%E,Wavefield%Ex, 1,FineGrid%Nx+2*GhostGridX,FineGrid%Ny+2*GhostGridY,1,FineGrid%DiffStencils,alpha)
       !smooth Ex
       CALL OFsmoothing(wavefield%Ex, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)
       CALL DiffXEven(Wavefield%E,Wavefield%Exx,2,FineGrid%Nx+2*GhostGridX,FineGrid%Ny+2*GhostGridY,1,FineGrid%DiffStencils,alpha)
	   !smooth Exx
       CALL OFsmoothing(wavefield%Exx, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)
	END IF

	IF (FineGrid%Ny>1) THEN
	   CALL UpdateGhostLayerY(Wavefield%E,Wavefield%SourceEy,FineGrid%Nx+2*GhostGridX,FineGrid%Ny+2*GhostGridY,&
       		FineGrid%DiffStencils,beta,GhostGridX,GhostGridY)
       CALL DiffYEven(Wavefield%E,Wavefield%Ey, 1,FineGrid%Nx+2*GhostGridX,FineGrid%Ny+2*GhostGridY,1,FineGrid%DiffStencils,beta)
       !smooth Ey
       CALL OFsmoothing(wavefield%Ey, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)
       CALL DiffYEven(Wavefield%E,Wavefield%Eyy,2,FineGrid%Nx+2*GhostGridX,FineGrid%Ny+2*GhostGridY,1,FineGrid%DiffStencils,beta)
	   !smooth Eyy
       CALL OFsmoothing(wavefield%Eyy, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)
	END IF
ELSE
	Write(*,*) 'Error in WriteOFtoOCW3D: curvilinear not implemented'
END IF


! Get new Phi by timeintegration with newly obtained OF results
CALL rhsFreeSurface3D(time,Wavefield,g,rhsE,rhsP,FineGrid%Nx+2*GhostGridX,FineGrid%Ny+2*GhostGridY)
Ptemp = Phist + half * dt * (rhsP + k1_Phist) 

! write Ptemp to P (only inside the OpenFOAM domain)
DO i=1, SIZE(OfPoints)
	POCWtemp = WaveField%P(OfPoints(i)%xInd, OfPoints(i)%yInd)*(one - OfPoints(i)%relax)
	POFtemp = Ptemp(OfPoints(i)%xInd, OfPoints(i)%yInd)*OfPoints(i)%relax
	WaveField%P(OfPoints(i)%xInd, OfPoints(i)%yInd) = POFtemp + POCWtemp
END DO

! smooth Phi
CALL OFsmoothing(wavefield%P, FineGrid%Nx+2*GhostGridX, FineGrid%Ny+2*GhostGridY)

!Update EtatHist and WHist
WaveField%WHist(:,:,1) = WaveField%W(:,:)
WaveField%EtatHist(:,:,1) = (WaveField%E(:,:) - Ehist(:,:))/dt



!write OF sloution
IF (.TRUE.)	THEN

Open(fileop(18),file='OF_'//trim(adjustl(strTime))//'.chk',status='unknown')

DO p=1, SIZE(FineGrid%x) 

			!write(fileop(15),*)  FineGrid%x(p,1), Wavefield%Px(p,1), Wavefield%W(p,1)
			write(fileop(18),*)  FineGrid%x(p,1),  Uxopen(p,1), Wopen(p,1), Eopen(p,1)
			!x ux uz Eta
END DO

Close(fileop(18))

!STOP!!!

ENDIF

!write TWC sloution
IF (.TRUE.)	THEN

Open(fileop(19),file='TWC_'//trim(adjustl(strTime))//'.chk',status='unknown')

DO p=1, SIZE(FineGrid%x) 

			!write(fileop(15),*)  FineGrid%x(p,1), Wavefield%Px(p,1), Wavefield%W(p,1)
			write(fileop(19),*)  FineGrid%x(p,1),  Wavefield%Px(p,1), Wavefield%W(p,1), Wavefield%E(p,1), Wavefield%Ex(p,1), Wavefield%Exx(p,1), Wavefield%P(p,1)
			!x ux uz Eta Etax Etaxx P
END DO

Close(fileop(19))

!STOP!!!

ENDIF



!undo Coupling
!~ wavefield%E = WavefieldCopy%E
!~ wavefield%Ex = WavefieldCopy%Ex
!~ wavefield%Exx = WavefieldCopy%Exx
!~ wavefield%P = WavefieldCopy%P
!~ wavefield%Px = WavefieldCopy%Px
!~ wavefield%W = WavefieldCopy%W
!~ Wavefield%SourceEx=WavefieldCopy%SourceEx
!~ WaveField%WHist = WaveFieldCopy%WHist
!~ WaveField%EtatHist = WaveFieldCopy%EtatHist

END SUBROUTINE WriteOFtoOCW3D_Fully
