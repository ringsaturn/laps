 &surface_analysis
 use_lso_qc = 0,
 skip_internal_qc = 0,
 itheta=5, 
 /
c
c..... This is the namelist for the LAPS surface analysis
c..... process (LSX).  Switches and similar things can go
c..... here, and are read at runtime (rather than requiring
c..... a recompile.
c
c..... Current switches and their default values:
c
c..... use_lso_qc = 0, (a "1" tells LSX to use the quality-
c.....                  controlled version of LSO (lso_qc),
c.....                  a "0" uses the normal LSO file. Note
c.....                  that setting this to one--using the
c.....                  QC'd LSO file--turns off the internal
c.....                  LSX QC). 
c.....                  
c
c..... skip_internal_qc = 0, (a "1" tells LSX to skip it's
c.....                        internal QC routine; a "0" uses
c.....                        it.  Note that this is only used
c.....                        if "use_lso_qc" is set to zero.)
c.....
c
c.......... itheta=5
c
c.......... Surface Theta check:  Check to see that the surface potential
c..........     temperatures are not greater than the potential temperature
c..........     at an upper level.  Set this variable equal to the desired
c..........     upper level:
c
c..........      	0 = No sfc theta check done
c..........      	7 = Use 700 mb level
c..........       	5 = Use 500 mb level
c
c..........     Recommended:  Use 700 mb most places, 500 mb over higher
c..........                   terrain areas (like Colorado).

