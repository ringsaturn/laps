#!/bin/sh 

#umask 000

echo "start lapsplot_gifs.sh"

uname -a

proc=$1
WINDOW=$2
LAPS_GIFS=$3
delay=$4
EXE_DIR=$5
export LAPS_DATA_ROOT=$6
export NCARG_ROOT=$7

# Choices are "yes", "no", or the number of images if a montage is desired
animate=$8

RESOLUTION=$9

SCRATCH_DIR=$LAPS_GIFS/scratch
LAPSPLOT_IN=$SCRATCH_DIR/lapsplot.in_$proc

uscore="_"
MACHINE=`uname -s`
NODE=`uname -n`

#export NCARG_ROOT=/usr/local/apps/ncarg-4.2.2-pgi
SUPMAP_DATA_DIR=/home/elvis/mcdonald/data/supmap/
#alias ctrans '/usr/local/apps/ncarg-4.0.1/bin/ctrans  -verbose'

echo "proc ="$proc
echo "WINDOW ="$WINDOW
echo "LAPS_GIFS = "$LAPS_GIFS
echo "SCRATCH_DIR =  $SCRATCH_DIR"
echo "EXE_DIR =  $EXE_DIR"
echo "NCARG_ROOT ="$NCARG_ROOT
echo "LAPS_DATA_ROOT ="$LAPS_DATA_ROOT
echo "latest ="$latest
echo "RESOLUTION ="$RESOLUTION
echo "LAPSPLOT_IN ="$LAPSPLOT_IN
echo "animate ="$animate
echo "delay ="$delay

echo " "
echo "setting ulimit"
ulimit -t 1000
ulimit -t

#mkdir -p /scratch/lapb/www
mkdir -p $SCRATCH_DIR/$proc
cd $SCRATCH_DIR/$proc

#EXE_DIR=/usr/nfs/lapb/parallel/laps/bin

date -u
echo "Running $EXE_DIR/lapsplot.exe < $LAPSPLOT_IN on $MACHINE $NODE"
#$EXE_DIR/lapsplot.exe                                          < $LAPS_GIFS/lapsplot.in
$EXE_DIR/lapsplot.exe                                           < $LAPSPLOT_IN

pwd
ls -l $SCRATCH_DIR/$proc/gmeta

if test "$MACHINE" = "AIX"; then

#   Combination for IBM
    ext1=avs
    ext2=x
    ext3=gif
    netpbm=no

#   CTRANS=/usr/local/apps/ncarg-4.0.1/bin/ctrans

else

    netpbm=yes

#   Best combination for LINUX
    ext1=avs
    ext2=avs
    ext3=gif

#   The ones below will run but produce fewer colors in color images for LINUX

#   ext1=sun
#   ext2=sun

#   ext1=xwd
#   ext2=xwd

#   Note that sgi will not work in LINUX since we are using gmeta files with WINDOW/RESOLUTION set
#   ext1=sgi
#   ext2=sgi

#   ext1=sun
#   ext2=gif

#   CTRANS=/usr/local/apps/ncarg-4.2.2-pgi/bin/ctrans

fi

CTRANS=$NCARG_ROOT/bin/ctrans


#/usr/local/apps/ncarg-4.0.1/bin/ctrans -verbose -d avs -window $WINDOW -resolution $RESOLUTION gmeta > $SCRATCH_DIR/gmeta_$proc.x
#ctrans -d avs -window 0.0:0.08:1.0:0.92 -resolution 610x512 gmeta > $SCRATCH_DIR/gmeta_$proc.x
#/usr/local/apps/ncarg-4.0.1/bin/ctrans -verbose -d $ext1 -window $WINDOW -resolution $RESOLUTION gmeta > $SCRATCH_DIR/gmeta_temp_$proc.$ext2
#$NCARG_ROOT/bin/ctrans -verbose -d $ext1 -window $WINDOW -resolution $RESOLUTION $SCRATCH_DIR/gmeta > $SCRATCH_DIR/gmeta_temp_$proc.$ext2

#$CTRANS -verbose -d $ext1 -window $WINDOW -resolution $RESOLUTION $SCRATCH_DIR/$proc/gmeta > $SCRATCH_DIR/gmeta_temp_$proc.$ext2

#ls -l $SCRATCH_DIR/gmeta_temp_$proc.$ext2

date -u

echo "lapsplot_gifs.sh: netpbm = $netpbm"

#numimages=`ls -1 *.gif | wc -l`
#echo "numimages = $numimages"

#We assume we are running this script in LINUX and convert will not properly do AVS X on LINUX
if test "$netpbm" = "yes" && test "$animate" = "no"; then 
    date
#   echo "Running $NCARG_ROOT/bin/ctrans | netpbm to make gmeta_$proc.gif file"
    echo "Running $NCARG_ROOT/bin/ctrans -verbose -d sun -window $WINDOW -resolution $RESOLUTION gmeta | rasttopnm | ppmtogif > $SCRATCH_DIR/gmeta_$proc.gif"
    $NCARG_ROOT/bin/ctrans -verbose -d sun -window $WINDOW -resolution $RESOLUTION gmeta | rasttopnm | ppmtogif > $SCRATCH_DIR/gmeta_$proc.gif

    date -u

#   Cleanup
    echo "Cleanup"
    mv gmeta $SCRATCH_DIR/gmeta_$proc.gm;  cd ..; rmdir $SCRATCH_DIR/$proc &

elif test "$netpbm" = "yes" && test "$animate" != "no"; then 
    date
    echo "Running $NCARG_ROOT/bin/ctrans -verbose -d sun -window $WINDOW -resolution $RESOLUTION gmeta > $SCRATCH_DIR/$proc/gmeta_$proc.sun"
    $NCARG_ROOT/bin/ctrans -verbose -d sun -window $WINDOW -resolution $RESOLUTION gmeta > $SCRATCH_DIR/$proc/gmeta_$proc.sun

#   Convert multiframe raster image to animated gif
    $NCARG_ROOT/bin/rassplit gmeta_$proc.sun

#   Convert sun to gif images so convert works better on new server
    for file in `ls gmeta_$proc.*.sun`; do
        ls $file
        rasttopnm $file | ppmtogif > $file.gif
    done

    ls -l gmeta_$proc.*.sun.gif

    numimages=`ls -1 *.gif | wc -l`
    echo "numimages = $numimages"

    echo " "
    echo "Listing of $SCRATCH_DIR/$proc animation images"
    ls -1r gmeta*.gif | tee files.txt

    if test "$animate" = "yes"; then
        echo "convert -delay $delay -loop 0 *.gif $SCRATCH_DIR/gmeta_$proc.gif"
        convert -delay $delay -loop 0 *.gif $file.gif     $SCRATCH_DIR/gmeta_$proc.gif

    else # make montage instead of animation, $animate is the number of images
#       numimages=`ls -1 *.gif | wc -l`
#       echo "numimages = $numimages"

        nmontage=$animate

        echo "nmontage = $nmontage"

        montage_file=$SCRATCH_DIR/montage_$proc.sh

        if test -r "$montage_file"; then

          echo "running montage file: $montage_file"
          cat $montage_file
          /bin/sh $montage_file
          rm -f $montage_file

          echo " "
          echo "Listing of $SCRATCH_DIR/$proc animation images"
          ls -1r gmeta_*_*.gif | tee files.txt
          rm -f *sun*.gif

        else

          x20=x20
          x=x

          if test "$numimages" == "3"; then # single row
            echo "making single row"
            echo "montage *.gif -mode Concatenate -tile $nmontage$x20 $SCRATCH_DIR/gmeta_$proc.gif"
                  montage *.gif -mode Concatenate -tile $nmontage$x20 $SCRATCH_DIR/gmeta_$proc.gif
          elif test "$numimages" == "4"; then # double row
            echo "making double row"
            echo "montage *.gif -mode Concatenate -tile 2x2           $SCRATCH_DIR/gmeta_$proc.gif"
                  montage *.gif -mode Concatenate -tile 2x2           $SCRATCH_DIR/gmeta_$proc.gif
          else                              # automatic settings
            echo "making $nmontage (nmontage) columns"
            echo "montage *.gif -mode Concatenate -tile $nmontage$x     $SCRATCH_DIR/gmeta_$proc.gif"
                  montage *.gif -mode Concatenate -tile $nmontage$x     $SCRATCH_DIR/gmeta_$proc.gif
          fi    

        fi

    fi

#   This option may be more direct though it isn't working on the new server
#   echo "convert -delay $delay -loop 0 gmeta_$proc.*.sun $SCRATCH_DIR/gmeta_$proc.gif"
#   convert -delay $delay -loop 0 gmeta_$proc.*.sun $SCRATCH_DIR/gmeta_$proc.gif

    ln -s -f /w3/lapb/looper/files.cgi files.cgi

    date -u

#   Cleanup
    echo "Cleanup"
#   mv gmeta $SCRATCH_DIR/gmeta_$proc.gm;  cd ..; rm -f $SCRATCH_DIR/$proc/gmeta*; rmdir $SCRATCH_DIR/$proc &
    mv gmeta $SCRATCH_DIR/gmeta_$proc.gm;  cd ..; rm -f gmeta; rm -f $SCRATCH_DIR/$proc/*.sun & 

#   echo " "
#   echo "Cleaned up listing of $SCRATCH_DIR/$proc"
#   ls -l $SCRATCH_DIR/$proc

elif test "$ext2" = "x"; then
    date -u
    echo "Converting $SCRATCH_DIR/$proc/gmeta file with $CTRANS to $SCRATCH_DIR/gmeta_temp_$proc.$ext2"
    $CTRANS -verbose -d $ext1 -window $WINDOW -resolution $RESOLUTION $SCRATCH_DIR/$proc/gmeta > $SCRATCH_DIR/gmeta_temp_$proc.$ext2

    ls -l $SCRATCH_DIR/gmeta_temp_$proc.$ext2

    date -u

#   echo "Running imconv.ibm.exe on ren via rsh"
#   rsh ren /usr/nfs/avs_fsl/bin/imconv.ibm.exe $SCRATCH_DIR/gmeta_temp_$proc.$ext2 $SCRATCH_DIR/gmeta_$proc.gif

#   Note that 'convert' is available on Linux but it appears to be slow for GIFs
#   echo "Running convert $SCRATCH_DIR/gmeta_temp_$proc.$ext2 $SCRATCH_DIR/gmeta_$proc.$ext3 on $MACHINE"
#   convert $SCRATCH_DIR/gmeta_temp_$proc.$ext2 $SCRATCH_DIR/gmeta_$proc.$ext3

    echo "Running imconv.ibm.exe on $MACHINE $NODE"
    /usr/nfs/avs_fsl/bin/imconv.ibm.exe $SCRATCH_DIR/gmeta_temp_$proc.$ext2 $SCRATCH_DIR/gmeta_$proc.gif

    date -u

#   Cleanup
    echo "Cleanup"
!   rm -f $SCRATCH_DIR/gmeta_temp_$proc.$ext2; mv gmeta $SCRATCH_DIR/gmeta_$proc.gm;  cd ..; rmdir $SCRATCH_DIR/$proc &
    rm -f $SCRATCH_DIR/gmeta_temp_$proc.$ext2; mv gmeta $SCRATCH_DIR/gmeta_$proc.gm;  cd ..                           &

fi

chmod 666 $SCRATCH_DIR/gmeta_$proc.$ext3


echo " "
date -u
echo " "

