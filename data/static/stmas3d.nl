0                  ! WHETHER USE BACKGROUND OR NOT, 1 IS YES, 0 IS NOT.
1                  ! WHETHER USE BOUND OR NOT, 1 IS YES, 0 IS NOT.
1                  ! WHETHER USE PRESSURE COORDINATE, 1 IS FOR PRESSURE, 2 IS FOR HEIGHT, AND 0 IS FOR SIGMA COORDINATE.
5                  ! NUMBER OF STATE
1.0                ! DEFAULT SCALING
1.0                ! DEFAULT SCALING
1.0                ! DEFAULT SCALING
1.0                ! DEFAULT SCALING
1.0                ! DEFAULT SCALING
1.0                ! X DIRECTION PENALTY COEFFICENT.
1.0                ! Y DIRECTION PENALTY COEFFICENT.
2.0                ! Z DIRECTION PENALTY COEFFICENT.
0.0                ! T DIRECTION PENALTY COEFFICENT.
1.0                ! X DIRECTION PENALTY COEFFICENT.
1.0                ! Y DIRECTION PENALTY COEFFICENT.
2.0                ! Z DIRECTION PENALTY COEFFICENT.
0.0                ! T DIRECTION PENALTY COEFFICENT.
1.0                ! X DIRECTION PENALTY COEFFICENT.
1.0                ! Y DIRECTION PENALTY COEFFICENT.
2.0                ! Z DIRECTION PENALTY COEFFICENT.
0.0                ! T DIRECTION PENALTY COEFFICENT.
1.0                ! X DIRECTION PENALTY COEFFICENT.
1.0                ! Y DIRECTION PENALTY COEFFICENT.
2.0                ! Z DIRECTION PENALTY COEFFICENT.
0.0                ! T DIRECTION PENALTY COEFFICENT.
1.0                ! X DIRECTION PENALTY COEFFICENT.
1.0                ! Y DIRECTION PENALTY COEFFICENT.
2.0                ! Z DIRECTION PENALTY COEFFICENT.
0.0                ! T DIRECTION PENALTY COEFFICENT.
0.1                ! GEOSTROPHIC BALANCE PENALTY COEFFICENT FOR P AND U.
0.1                ! GEOSTROPHIC BALANCE PENALTY COEFFICENT FOR P AND V.
4                  ! NUMBER OF DIMENSION VALID
17                  ! INITIAL NUMBER OF GRID FOR DIMENSTION 1
17                  ! INITIAL NUMBER OF GRID FOR DIMENSTION 2 
6                  ! INITIAL NUMBER OF GRID FOR DIMENSTION 3
2                  ! INITIAL NUMBER OF GRID FOR DIMENSTION 4
3                  ! NUMBER OF LAPS TIME FRAMES FOR THE TIME DIMENSION
0.0                ! INITIAL GRID SPACING FOR DIMENSTION 4
0.0                ! ORIGINAL POSITION FOR DIMENSTION 1
0.0                ! ORIGINAL POSITION FOR DIMENSTION 2
0.0                ! ORIGINAL POSITION FOR DIMENSTION 3
0.0                ! ORIGINAL POSITION FOR DIMENSTION 4
129                ! MAXIMUM OF GRID NUMBER FOR DIMENSION 1
129                 ! MAXIMUM OF GRID NUMBER FOR DIMENSION 2
21                 ! MAXIMUM OF GRID NUMBER FOR DIMENSION 3
3                  ! MAXIMUM OF GRID NUMBER FOR DIMENSION 4
4                  ! THE FINEST GRID LEVEL
200000.0           ! AFFECT RANGE IN X DIRECTION
200000.0           ! AFFECT RANGE IN Y DIRECTION
50000.0            ! AFFECT RANGE IN Z DIRECTION
0.0                ! AFFECT RANGE IN T DIRECTION
200000.0           ! AFFECT RANGE IN X DIRECTION
200000.0           ! AFFECT RANGE IN Y DIRECTION
50000.0            ! AFFECT RANGE IN Z DIRECTION
0.0                ! AFFECT RANGE IN T DIRECTION
200000.0           ! AFFECT RANGE IN X DIRECTION
200000.0           ! AFFECT RANGE IN Y DIRECTION
50000.0            ! AFFECT RANGE IN Z DIRECTION
0.0                ! AFFECT RANGE IN T DIRECTION
200000.0           ! AFFECT RANGE IN X DIRECTION
200000.0           ! AFFECT RANGE IN Y DIRECTION
50000.0            ! AFFECT RANGE IN Z DIRECTION
0.0                ! AFFECT RANGE IN T DIRECTION
200000.0           ! AFFECT RANGE IN X DIRECTION
200000.0           ! AFFECT RANGE IN Y DIRECTION
50000.0            ! AFFECT RANGE IN Z DIRECTION
0.0                ! AFFECT RANGE IN T DIRECTION
1                  ! U COMPONENT
2                  ! V COMPONENT
0                  ! W COMPONENT
3                  ! PRESSURE
4                  ! TEMPERATURE
5                  ! SPECIFIC HUMIDITY ADDED BY YUANFU XIE JAN 2009
1                  ! X COORDINATE INDEX
2                  ! Y COORDINATE INDEX
3                  ! PRESSURE INDEX
4                  ! CORIOLIS FORCE INDEX
5                  ! DENSITY INDEX
10                 ! THE ITERATE STEPS BEFORE MIDDLE GRID LEVEL
6                  ! MIDDLE GRID LEVEL WHERE THE ITERATE STEP CHANGED
5                  ! THE ITERATE STEPS AFTER MIDDLE GRID LEVEL
1.                  !COEFFICIENT USED TO TRANSLATE THE X AND Y COORDINATE TO METERS 
1.                  !COEFFICIENT USED TO TRANSLATE THE Z COORDINATE TO METERS
0                  ! WHETHERE RUN FOR THE TEST CASE, SET 1 IS FOR THE TEST CASE.
0                  ! WHETHERE RUN THE MUTIGRID FRAME IN MONOTONOUS OR REPEATEDLY, 0 FOR MONOTONOUS, 1 FOR REPEATEDLY
3                  ! THE TIMES TO REPEAT
0.1                ! HYDROSTATIC CONDITION PENALTY COEFFICENT.
0.5                ! REDUCTION COEFFICENT OF HYDROSTATIC CONDITION PENALTY TERM
4                  ! THE GRID LEVEL AFTER WHICH THE HYDROSTATIC CONDITION PENALTY TERM IS OMMITTED.
4                  ! THE GRID LEVEL AFTER WHICH THE GEOSTROPHIC BALANCE PENALTY TERM IS OMMITTED.
10.                ! LIMIT_3, THE LIMITATION OF HEIGHT OR PRESSURE TO DECIDE IN WHICH RANGE THE OBSERVATION IS AVIABLE.
1.                 ! LIMIT_4, THE LIMITATION OF TIME TO DECIDE IN WHICH RANGE THE OBSERVATION IS AVIABLE. 
 
