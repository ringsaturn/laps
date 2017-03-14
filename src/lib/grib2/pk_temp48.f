      SUBROUTINE PK_TEMP48(KFILDO,IPACK,ND5,IS4,NS4,L3264B,
     1                     LOCN,IPOS,IER,*)
C
C        MARCH   2000   LAWRENCE   GSC/TDL   ORIGINAL CODING
C        JANUARY 2001   GLAHN      COMMENTS; ADDED TEST FOR IS4( ) 
C                                  SIZE; IER = 403 CHANGED TO 402
C
C        PURPOSE
C            PACKS TEMPLATE 4.8 INTO PRODUCT DEFINITION SECTION 
C            OF A GRIB2 MESSAGE.  TEMPLATE 4.8 IS FOR 
C            AVERAGE, ACCUMULATION, AND/OR EXTREME VALUES
C            AT A HORIZONTAL LEVEL OR IN A HORIZONTAL LAYER
C            IN A CONTINUOUS OR NON-CONTINUOUS TIME INTERVAL.
C            IT IS THE RESPONSIBILITY OF THE CALLING ROUTINE
C            TO PACK THE FIRST 9 OCTETS IN SECTION 4.
C
C        DATA SET USE
C           KFILDO - UNIT NUMBER FOR OUTPUT (PRINT) FILE. (OUTPUT)
C
C        VARIABLES
C              KFILDO = UNIT NUMBER FOR OUTPUT (PRINT) FILE. (INPUT)
C            IPACK(J) = THE ARRAY THAT HOLDS THE ACTUAL PACKED MESSAGE
C                       (J=1,ND5). (INPUT/OUTPUT)
C                 ND5 = THE SIZE OF THE ARRAY IPACK( ). (INPUT)
C              IS4(J) = CONTAINS THE PRODUCT DEFINITION INFORMATION 
C                       FOR TEMPLATE 4.8 (IN ELEMENTS 10 THROUGH 42
C                       OR MORE) THAT WILL BE PACKED INTO IPACK( )
C                       (J=1,NS4).  (INPUT)
C                 NS4 = SIZE OF IS4( ). (INPUT) 
C              L3264B = THE INTEGER WORD LENGTH IN BITS OF THE MACHINE
C                       BEING USED. VALUES OF 32 AND 64 ARE
C                       ACCOMMODATED. (INPUT)
C                LOCN = THE WORD POSITION TO PLACE THE NEXT VALUE.
C                       (INPUT/OUTPUT)
C                IPOS = THE BIT POSITION IN LOCN TO START PLACING
C                       THE NEXT VALUE. (INPUT/OUTPUT)
C                 IER = RETURN STATUS CODE. (OUTPUT)
C                        0 = GOOD RETURN.
C                      1-4 = ERROR CODES GENERATED BY PKBG. SEE THE 
C                            DOCUMENTATION IN THE PKBG ROUTINE.
C                      402 = IS4 HAS NOT BEEN DIMENSIONED LARGE
C                            ENOUGH TO CONTAIN THE ENTIRE TEMPLATE. 
C                   * = ALTERNATE RETURN WHEN IER NE 0. 
C
C             LOCAL VARIABLES
C             MINSIZE = THE SMALLEST ALLOWABLE DIMENSION FOR IS4( ).
C                   N = L3264B = THE INTEGER WORD LENGTH IN BITS OF
C                       THE MACHINE BEING USED. VALUES OF 32 AND
C                       64 ARE ACCOMMODATED.
C
C        NON SYSTEM SUBROUTINES CALLED
C           PKBG
C
      PARAMETER(MINSIZE=43)
C
      DIMENSION IPACK(ND5),IS4(NS4)
C
      N=L3264B
      IER=0
C
C        CHECK THE DIMENSIONS OF IS4( ).
      IF(NS4.LT.MINSIZE)THEN
C        WRITE(KFILDO,10)NS4,MINSIZE
C10      FORMAT(/' IS4( ) IS CURRENTLY DIMENSIONED TO CONTAIN'/
C    1           ' NS4=',I4,' ELEMENTS. THIS ARRAY MUST BE'/
C    2           ' DIMENSIONED TO AT LEAST ',I4,' ELEMENTS'/
C    3           ' TO CONTAIN ALL OF THE DATA IN PRODUCT'/
C    4           ' DEFINITION TEMPLATE 4.1.'/)
         IER=402
      ELSE
C
C           SINCE THIS TEMPLATE SHARES THE SAME INFORMATION
C           AS TEMPLATE 4.0, CALL THE PK_TEMP40 ROUTINE
         CALL PK_TEMP40(KFILDO,IPACK,ND5,IS4,NS4,L3264B,LOCN,IPOS,
     1                  IER,*900)
C
C           PACK THE YEAR
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(35),16,N,IER,*900)
C
C           PACK THE MONTH 
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(37),8,N,IER,*900)
C
C           PACK THE DAY
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(38),8,N,IER,*900)
C
C           PACK THE HOUR
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(39),8,N,IER,*900)
C
C           PACK THE MINUTE
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(40),8,N,IER,*900)
C
C           PACK THE SECOND
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(41),8,N,IER,*900)
C
C           PACK THE NUMBER OF TIME RANGE SPECIFICATIONS DESCRIBING
C           THE TIME INTERVALS USED TO CALCULATE THE STATISTICALLY
C           PROCESSED FIELD.
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(42),8,N,IER,*900)
C
C           PACK THE TOTAL NUMBER OF DATA VALUES MISSING IN 
C           STATISTICAL PROCESS.
         CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(43),32,N,IER,*900)
C
C           IS IS4( ) LARGE ENOUGH TO HOLD WHAT IS4(42) SAYS IT
C           SHOULD?
C     
         IF(NS4.LT.MINSIZE+12*IS4(42))THEN
C              ABOVE IS EQUIVALENT TO:
C              MINSIZE+3+12*(IS4(42)-3.  THE LAST VALUE IN IS4( )
C              FILLS 4 BYTES, BUT IS4( ) DOESN'T REALLY HAVE TO
C              BE THAT LARGE.  THE +3 IS TO ACCOMMODATE A 4-BYTE
C              VALUE IN IS4(43).
            IER=402
            GO TO 900
         ENDIF
C
         DO 20 I=1,IS4(42)
            IC=12*(I-1)
C
C              PACK THE STATISTICAL PROCESS USED TO CALCULATE THE 
C              PROCESSED FIELD FROM THE FIELD AT EACH TIME INCREMENT
C              DURING THE TIME RANGE.
            CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(47+IC),8,N,
     1                IER,*900)
C
C              PACK THE TYPE OF TIME INCREMENT BETWEEN SUCCESSIVE
C              FIELDS USED IN THE STATISTICAL PROCESS.
            CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(48+IC),8,N,
     1                IER,*900)
C
C              PACK THE INDICATOR OF UNIT OF TIME FOR TIME RANGE OVER
C              WHICH STATISTICAL PROCESSING IS DONE.
            CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(49+IC),8,N,
     1                IER,*900)
C
C              PACK THE LENGTH OF THE TIME RANGE OVER WHICH STATISTICAL
C              PROCESSING IS DONE, IN UNITS DEFINED BY THE PREVIOUS 
C              OCTET.
            CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(50+IC),32,N,
     1                IER,*900)
C
C              PACK THE INDICATOR OF UNIT OF TIME FOR THE INCREMENT
C              BETWEEN THE SUCCESSIVE FIELDS USED.
            CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(54+IC),8,N,
     1                IER,*900)
C
C              PACK THE TIME INCREMENT BETWEEN SUCCESSIVE FIELDS,
C              IN UNITS DEFINED BY THE PREVIOUS OCTET.
            CALL PKBG(KFILDO,IPACK,ND5,LOCN,IPOS,IS4(55+IC),32,N,
     1                IER,*900)
C
 20      ENDDO
C
      ENDIF
C
C       ERROR RETURN SECTION
 900  IF(IER.NE.0)RETURN 1
C
      RETURN
      END
