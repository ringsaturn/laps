#!/usr/local/perl5/bin/perl

package laps_tools;
use strict;
umask 002;

#
# routine get_nl_values returns value of namelist variable given
# LAPS_DATA_ROOT -> location of namelists (-d opt or environ var);
# namelist filename -> commaind line (-n) input;
# namelist variable name -> command line (-v) input;
# namelist to open is a template or not (template is defined or not)
#          in such case LAPS_DATA_ROOT = path to template files.
#
# returned namelist value is in an array.
#
# J. Smart 4-28-00

sub get_nl_value{

   my ($namelist_file, $namelist_var, $LAPS_DATA_ROOT, $template) = @_;

   if(!defined $LAPS_DATA_ROOT) {$LAPS_DATA_ROOT = $ENV{LAPS_DATA_ROOT};}
   if(!defined $LAPS_DATA_ROOT) {print "LAPS_DATA_ROOT not defined "; exit;}

   defined $namelist_file || die "namelist filename required input\n";
   defined $namelist_var || die "namelist variable required input\n";

   if(!defined $template){
      open(NLF,"$LAPS_DATA_ROOT/static/$namelist_file") or die "Can't open $LAPS_DATA_ROOT/$namelist_file";
   }else{
      open(NLF,"$LAPS_DATA_ROOT/$namelist_file") or die "Can't open $LAPS_DATA_ROOT/$namelist_file";
   }

   my @nlf=<NLF>;
   my $nlf=@nlf;
   my @nlcomps;
   my @nl_values;
   my $nlcomps;
   my $search_for_equal = 0;
   my $continue_adding_lines = 1; 
   my $pattern = 0;

   foreach (@nlf){

      if($continue_adding_lines == 1){

         if($search_for_equal == 1){
            $pattern = grep /=/, $_;
            if($pattern != 1){
               $pattern = grep /^\s*\/\s*$/, $_;
            }
         }
                        
         chomp; s/\s+$//; s/\,$//;
         if(/^\s+$namelist_var\s*/i) {
           @nlcomps = split('=',$_);
           @nl_values = split /\,/,$nlcomps[1];
           $search_for_equal = 1;
         }elsif($search_for_equal == 1 && $pattern == 0){

                @nlcomps = split /\,/,$_;
                $nlcomps = @nlcomps;
                push @nl_values, split(",",$nlcomps[0]);

         }elsif($search_for_equal == 1 && $pattern == 1){
              $continue_adding_lines = 0;
         }
      }
   }
# strip off quotes and leading white space.
   foreach (@nl_values){
      s/\'//g; s/\s*//;}

   return @nl_values;
}
1;
#
#================================================================================
#
sub update_nl{
    my($LAPS_DATA_ROOT,$nl_file,$nl_var,@new_values) = @_;

    print "LAPS_DATA_ROOT = $LAPS_DATA_ROOT\n";
    print "nl file = $nl_file\n";
    print "nl var = $nl_var \n";
    foreach (@new_values){
       print "new values = $_\n";}
    print "\n";
#
# open and compare nest7grid.parms and *.nl in $srcroot/static and $dataroot/static
# Add variables and files found in $srcroot/static but not $dataroot/static 
#
# ***   Correction for this code ... do not add files (like from srcroot/static)
#
# Retain the values of variables found in $dataroot/static for variables in both files
#
# some of this software was from "laps" etc/laps_localization.pl and is used
# here to replace namelist variables with new values.
#
#
# save the original copy of $nl_file unless it already exists
#
    unless (-e "$LAPS_DATA_ROOT/static/$nl_file.bak"){
      system("cp $LAPS_DATA_ROOT/static/$nl_file $LAPS_DATA_ROOT/static/$nl_file.bak");}

# save the existing namelist file for later merger operation with template 
# ------------------------------------------------------------------------
    if(!-e "$LAPS_DATA_ROOT/static/tmp"){
       print "make tmp directory and save $nl_file \n";
       mkdir "$LAPS_DATA_ROOT/static/tmp", 0777 or die "Can't make directory $LAPS_DATA_ROOT/static/tmp";
       system("mv $LAPS_DATA_ROOT/static/$nl_file  $LAPS_DATA_ROOT/static/tmp/."); 
    }else{
       system("mv $LAPS_DATA_ROOT/static/$nl_file  $LAPS_DATA_ROOT/static/tmp/.");
    }

# write a "template" namelist file in static with new variable info
# -----------------------------------------------------------------
    my $filename = "$LAPS_DATA_ROOT/static/$nl_file";
    my $nl_line;

    if($nl_file eq "nest7grid.parms"){
      $nl_line = "lapsparms_nl";
    }else{
       my @fname_part = split /\./, $nl_file;
       $nl_line = $fname_part[0]."_".$fname_part[1];
    }

    &write_namelist($filename,$nl_var,$nl_line,@new_values);

    my($var, $val, $line, $eon);
    my %nl_vals;
    my %comments;

# open the namelist file for which the variable is to be replaced with a new value. 

        print "First pass of namelist parser $nl_file\n";
        open(FILE,"$LAPS_DATA_ROOT/static/$nl_file");
        my @template = <FILE>;
        close(FILE);

        $var='';
        my $mark=0;
        foreach $line (@template){
            if($line =~ /^\s*\&/){
                $mark=1;
                next;
            }elsif($line =~ /^\s*\//){
                $mark=2;
                next;
            }elsif($line =~ /^[!cC]/){
                $comments{$nl_file} .= $line;
                $mark=3;
                next;
            }elsif($line =~ /^\s*(\S+)\s*=\s*(.*)$/){
                $var = $1;
                $var =~ tr/a-z/A-Z/;
                $nl_vals{$var} = $2;
                next;
            }elsif($line =~ /^(.*)$/){
                $nl_vals{$var} .= "\n$1";
                next;
            }
            if($mark>0){
                $var = '';
                $mark=0;
            }
        }

        open(INFILE,"$LAPS_DATA_ROOT/static/tmp/$nl_file");
        my @infile = <INFILE>;
        close(INFILE);

        
#--- here only open the saved (in tmp) file that represent the original and
#    merge the new "template" just written with the saved namelist file in tmp

        print "merging $LAPS_DATA_ROOT/static/tmp/$nl_file into $LAPS_DATA_ROOT/static/$nl_file\n";
        open(OUTFILE,">$LAPS_DATA_ROOT/static/$nl_file") or die "Could not open $LAPS_DATA_ROOT/static/$nl_file to write";

        my @comments = split("\n",$comments{$nl_file});

        foreach $line (@infile){
            next if($line eq "\n");
#           print ">$line< ".length($line)."\n";
            if($line =~ /^\s*\//){
                print "End of namelist found\n";
                $eon = 1;
                next;
            }
            
            if($line =~ /^\s*(\S+)\s*=\s*(.*)$/){
                $var = $1;
                
                $var =~ tr/a-z/A-Z/;
                $val = $2;
                if(exists $nl_vals{$var}){
#                   print "Found $var = $val\n";
                    $val = $nl_vals{$var};
                }
                $val =~ s/\n$//;
                print OUTFILE " $var = $val\n";
                next;
            }elsif($line =~ /^[!cC]/){
                chomp($line);
                my $tmpline = $line;
                $tmpline =~ s/[(\[\]\\\/\(\)\!\$\^)]/\$1/g;
                next if(grep(/$tmpline/,@comments)>0);
                push(@comments,$line);
                next;
#               print OUTFILE $line;            ;
            }elsif($line =~ /^\s*&/){
                print OUTFILE $line;
                next;
            }elsif(($line =~ /^(\s*[^&\/].*)$/) && exists $nl_vals{$var}){
                next;
            }
            print OUTFILE $line;

        }
        print OUTFILE " \/\n";
        foreach(@comments){
            print OUTFILE "$_\n";
        }
        close(OUTFILE);
#   }

}

#=========================================================================
#
sub laps_domain_name{
   my $LAPS_DATA_ROOT = shift(@_);
   my @components = split("/",$LAPS_DATA_ROOT); 
   my $i = 0; my $isave = 0;
   foreach (@components){
   if($_ eq "data"){
#print "location in list = $i\n";
      if($i != 1){$isave=$i-1;} }
      $i++;}
      $isave=$i-1 if($isave == 0);
   return my $DOMAIN_NAME = @components[$isave];
}
1;
#
# =========================================================================
sub laps_data_root{
   my $LAPS_DATA_ROOT = shift(@_);
   my $DATAROOT;
   my $DOMAIN_NAME = &laps_domain_name($LAPS_DATA_ROOT);
   my @components = split("/",$LAPS_DATA_ROOT);
   my $i = 0; my $isave=0;
   foreach (@components){
   if($_ eq "$DOMAIN_NAME"){
      if($i != 1){$isave=$i-1;} }
      $i++;}
   $isave=$i-1 if($isave == 0);
   $i=0;
   while ($i <= $isave) {
      $DATAROOT="$DATAROOT"."@components[$i]"."/";
      $i++;}
   return $DATAROOT;
}
1;

#===========================================================================
#
# laps_data_root is location of static, lapsprd, cdl, time,
# and log, and is where the data dirs are being created if
# they don't already exist.
# J. Smart 1-10-00:
#    "     1-18-00: product subdirectories added. Removed
#                   reference to lapssrcroot.

sub mkdatadirs{

  my $LAPS_DATA_ROOT = shift;
  $LAPS_DATA_ROOT = $ENV{LAPS_DATA_ROOT} if ! $LAPS_DATA_ROOT;

  my (@datadirs) = qw (cdl lapsprd log log/qc static time);
  my (@lapsprddirs) = qw (l1s lc3 lcb lco lcp lct lcv 
lf1 lga lh3 lh4 lhe lil liw lm1 lm2 lmd lmr lmt 
lpbl lps lq3 lrp lrs lso lsx lt1 lty 
lvd lvd/goes08 lvd/goes10 lvd/meteos lvd/gmssat lw3 lwc lwm 
msg pig pin prg pro sag vrc snd 
v01 v02 v03 v04 v05 v06 v07 v08 v09 v10 v11 v12 
v13 v14 v15 v16 v17 v18 v19 vdr 
d01 d02 d03 d04 d05 d06 d07 d08 d09 d10 d11 d12 
d13 d14 d15 d16 d17 d18 d19 d20 
ln3 lsr lsr/dmsp01 lsr/dmsp02 lsr/goes08 lsr/goes10 lsr/tros12 lsr/tros14 cdw rdr 
rdr/001 rdr/002 rdr/003 rdr/004 rdr/005 rdr/006 rdr/007 rdr/008 rdr/009 
rdr/001/raw rdr/001/vrc rdr/002/vrc rdr/003/vrc rdr/004/vrc 
rdr/005/vrc rdr/006/vrc rdr/007/vrc rdr/008/vrc rdr/009/vrc 
lgb ls2 dprep fsf fsf/mm5 fsf/ram fsf/eta fua fua/mm5 fua/ram fua/eta 
stats balance balance/lt1 balance/lw3 balance/lh3 
grid ram rsf lsq tmg lst pbl model model/varfiles model/output model/sfc);

  my $datadirs; my $lapsprddirs;

  foreach (@datadirs){
     mkdir "$LAPS_DATA_ROOT/$_",0777 if(! -e "$LAPS_DATA_ROOT/$_");}

# this perhaps can be used once (if) the lapsprd subdirectories are checked-in to CVS.
#    if( -e "$LAPSSRCROOT/data/lapsprd")    {
#        opendir(DATADIRS,"$LAPSSRCROOT/data/lapsprd");
#        @lapsprddirs = readdir DATADIRS;   }

  foreach (@lapsprddirs) {
     mkdir "$LAPS_DATA_ROOT/lapsprd/$_",0777;}

  return;
}
1;
#
# ---------------------------------------------------------------------
sub write_namelist {

    my ($filename,$nl_var,$nl_line,@nl_values)=@_;
    open(NLF,">$filename");
    my $first_time = 1;
    print NLF " &".$nl_line."\n";
    foreach (@nl_values){
       print "value = $_\n";
       if($first_time == 1){
          if(/^\d+/ || /^\s*\.\D+\./){
             print NLF " ".$nl_var."=".$_.",";      #this for digits and .true./.false.
             $first_time = 0;
          }elsif($first_time eq 1){
             print NLF " ".$nl_var."='".$_."',";    #this for character strings
             print NLF "\n" if(length($_)>25);      #separate long strings with line feed.
             $first_time = 0;
          }
       }elsif(/^\d+/ || /^\s*\.\D+\./){             #this for namelist arrays
          print NLF $_.",";
       }else{
          print NLF "'".$_."',";
          print NLF "\n" if(length($_)>25);         #separate long strings with line feed.
       }
    }

    print NLF "\n /\n";
    close NLF;
}
