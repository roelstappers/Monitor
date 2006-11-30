SUBROUTINE do_stat(p1,p2)

 USE data
 USE timing

 IMPLICIT NONE

 ! Input
 INTEGER :: p1(maxstn),p2(maxstn)

 ! Local
 INTEGER :: i,j,k,o,current_month,pp1,pp2,      &
            wrk(mparver),nlev,nmax
 INTEGER :: vertime(ntimver),timing_id,par_active(nparver)

 TYPE (statistics) :: onestat(nexp)
 TYPE (statistics), ALLOCATABLE  :: statall(:,:,:)

 CHARACTER(LEN=4 ) :: ttype = 'TIME'
 CHARACTER(LEN=38) :: text  = '   BIAS    RMSE     STDV      N      R'
!---------------------------------

 timing_id = 0
 IF (ltiming) CALL acc_timing(timing_id,'do_stat')

 IF(lprint_do_stat) WRITE(6,*)'--DO_STAT--',p1,p2

102 format(2A5,5(A38))
103 format(5(A38))


 ! Recheck active stations
 par_active = 0
 DO i=1,maxstn
    DO j=1,nparver
       par_active(j) = par_active(j) + stat(i)%par_active(j)
    ENDDO
 ENDDO

 !
 ! Allocate and init
 !

 IF (lallstat) THEN
    ALLOCATE(statall(nexp,nparver,ntimver))
    statall   = statistics(0.,0.,0.,0,0,0.)
 ENDIF

 DO i=1,ntimver 
   vertime(i)=(i-1)*timdiff + time_shift
 ENDDO

 IF (lfcver) vertime = fclen(1:ntimver)
 IF (lfcver) ttype='  LL'

 !
 ! Loop over all stations
 !

 DO i = 1,maxstn

    ! Check if we should plot this station

    IF (MAXVAL(stnlist_plot) == -1 ) THEN
       leach_station = .FALSE.
    ELSEIF (MAXVAL(stnlist_plot) == 0 ) THEN
       leach_station = .TRUE.
    ELSE
       leach_station = .FALSE.
       DO j=1,maxstn
          IF (hir(i)%stnr == stnlist_plot(j)) THEN
             leach_station = .TRUE.
             EXIT
          ENDIF
       ENDDO
    ENDIF
    
    csi = i

    IF(lprint_do_stat) WRITE(6,*)'DO station', i,maxstn,stat(i)%active

    IF (.NOT.stat(i)%active) CYCLE

    IF(leach_station) THEN
       WRITE(lunstat,*)
       WRITE(lunstat,*)'Station',stat(i)%stnr,p1(i),p2(i)
       IF (nexp.GT.1) WRITE(lunstat,103)expname(1:nexp)
       WRITE(lunstat,102)'TYPE ',ttype,(text,o=1,nexp)
    ENDIF

    DO j=1,nparver

       onestat = statistics(0.,0.,0.,0,0,0.)

       DO k=1,ntimver

          IF (leach_station) &
          CALL write_stat(obstype(j),vertime(k),stat(i)%s(:,j,k),nexp)
          DO o=1,nexp
             CALL   acc_stat(onestat(o),stat(i)%s(o,j,k),1,1,1)
          ENDDO

       ENDDO

       IF(leach_station) CALL write_stat(obstype(j),999,onestat,nexp)

    ENDDO

    !
    ! Plot statistics against hour or forecast time
    !

    IF(leach_station.AND.( lplot_stat .AND. .NOT. doing_monthvise  .OR.   &
                           lplot_stat_month .AND. doing_monthvise)      ) &
      CALL plot_stat2(lunout,nexp,nparver,ntimver,                        &
      stat(i)%s,stat(i)%stnr,p1(i),p2(i),par_active)

    !
    ! Plot statistics against level for specific
    ! hour or forecast time
    !

    IF ( ltemp .AND. leach_station  .AND.               &
       ( lplot_vert .AND. .NOT. doing_monthvise  .OR.   &
         lplot_vert_month .AND. doing_monthvise)      )  THEN
      wrk = 0
      WHERE ( lev_lst > 0 ) wrk = 1 
      nlev = SUM(wrk)
      CALL plot_vert(lunout,nexp,nlev,nparver,ntimver,                        &
      stat(i)%s,stat(i)%stnr,p1(i),p2(i),par_active)
    ENDIF

    IF (lallstat) CALL acc_stat(statall,stat(i)%s,nexp,nparver,ntimver)

 ENDDO

 IF ( plot_bias_map ) CALL plot_map(0,minval(p1),maxval(p2),0,map_type)
 IF ( plot_bias_map ) CALL plot_map(0,minval(p1),maxval(p2),1,map_type)
 IF ( plot_obs_map  ) CALL plot_map(0,minval(p1),maxval(p2),2,map_type)

 csi = 1

 IF (doing_monthvise) THEN
    current_month = minval(p1)
 ELSE
    current_month = 0
 ENDIF

 ALLSTAT : IF (lallstat.AND.(count(stat%active).GT.0)) THEN

    WRITE(lunstat,*)
    WRITE(lunstat,'(A4,I4,A10,2I12)')'All ',    &
    count(stat%active),' stations',minval(p1),maxval(p2)

    IF (nexp.GT.1) WRITE(lunstat,103)expname(1:nexp)
    WRITE(lunstat,102)'TYPE ',ttype,(text,o=1,nexp)

    LOOP_NPARVER : DO j=1,nparver

       onestat = statistics(0.,0.,0.,0,0,0.)

       DO k=1,ntimver

          CALL write_stat(obstype(j),vertime(k),statall(1:nexp,j,k),nexp)

          DO o=1,nexp
             CALL acc_stat(onestat(o),statall(o,j,k),1,1,1)
          ENDDO

       ENDDO

       CALL write_stat(obstype(j),999,onestat,nexp)

    ENDDO LOOP_NPARVER

    !
    ! Plot statistics against hour or forecast time
    !

    IF( lplot_stat .AND. .NOT. doing_monthvise  .OR.   &
        lplot_stat_month .AND. doing_monthvise       ) &
    THEN
      IF (lprint_do_stat) WRITE(6,*)'Call plot_stat'
      CALL plot_stat2(lunout,nexp,nparver,ntimver,     &
      statall,0,minval(p1),maxval(p2),par_active)
    ENDIF

    !
    ! Plot statistics against level for specific
    ! hour or forecast time
    !
    IF ( ltemp .AND.                                    &
       ( lplot_vert .AND. .NOT. doing_monthvise  .OR.   &
         lplot_vert_month .AND. doing_monthvise)      )  THEN

       wrk = 0
       WHERE ( lev_lst > 0 ) wrk = 1 
       nlev = SUM(wrk)
       CALL plot_vert(lunout,nexp,nlev,nparver,ntimver, &
                      statall,0,MINVAL(p1),MAXVAL(p2),  &
                      par_active)

    ENDIF

    DEALLOCATE(statall)

 ENDIF ALLSTAT

 IF (ltiming) CALL acc_timing(timing_id,'do_stat')

 RETURN
END SUBROUTINE do_stat
!---------------------------
!---------------------------
!---------------------------
SUBROUTINE acc_stat(s,p,i,j,k)

 USE types

 IMPLICIT NONE

 INTEGER :: i,j,k
 TYPE (statistics) :: s(i,j,k),p(i,j,k)

   s%r    = s%r    + p%r
   s%n    = s%n    + p%n
   s%bias = s%bias + p%bias
   s%rmse = s%rmse + p%rmse
   s%obs  = s%obs  + p%obs
   s%mabe = s%mabe + p%mabe

 RETURN
END SUBROUTINE acc_stat
!---------------------------
!---------------------------
!---------------------------
SUBROUTINE write_stat(p,t,s,n)

 USE types
 USE data, ONLY : len_lab,lunstat,lfcver

 IMPLICIT NONE

 INTEGER :: t,n
 CHARACTER(LEN=len_lab) :: p
 CHARACTER(LEN=3      ) :: cc='Day'
 TYPE (statistics) :: s(n)

! Local

 INTEGER :: o
 REAL    :: rn(n)
 CHARACTER(LEN=30) :: form1='(2A6,x(3f8.3,2I7))'
 CHARACTER(LEN=30) :: form2='(A6,I5,x(3f8.3,2I7))'
 
!------------------------------------------

 WRITE(form1(6:6),'(I1)')n
 WRITE(form2(8:8),'(I1)')n

 rn = 1.
 WHERE (s%n > 0 ) rn = FLOAT(s%n)
 !
 ! STD^2 = RMSE^2 - BIAS^2
 !

 IF (t.eq.999) THEN

       IF (lfcver) THEN
         cc='All'
       ELSE
         cc='Day'
       ENDIF

       WRITE(lunstat,form1)p,cc,              &
           (      s(o)%bias/rn(o),            &
!                 s(o)%mabe/rn(o),            &
             sqrt(s(o)%rmse/rn(o)),           &
             sqrt(ABS(s(o)%rmse/rn(o)         &
                    -(s(o)%bias/rn(o))**2)),  &
                  s(o)%n,s(o)%r,o=1,n)
       WRITE(lunstat,*)
 ELSE
       WRITE(lunstat,form2)p,t,               &
           (      s(o)%bias/rn(o),            &
!                 s(o)%mabe/rn(o),            &
             sqrt(s(o)%rmse/rn(o)),           &
             sqrt(ABS(s(o)%rmse/rn(o)         &
                    -(s(o)%bias/rn(o))**2)),  &
                  s(o)%n,s(o)%r,o=1,n)
 ENDIF

 RETURN
END SUBROUTINE write_stat
