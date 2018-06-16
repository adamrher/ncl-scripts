#!/bin/tcsh

#1 year of ne30 takes about 1 hour
#1 year of ne60 takes about 4 hours
#1 year of ne120pg2 took under 5 hours 800 GB
#1 year of ne120 takes 12 hours?

if ( "$#argv" != 2) then
  echo "Wrong number of arguments specified:"
  echo "  -arg 1 case1 string"
  echo "  -arg 2 is fincl number (e.g. h0)"
  exit
endif
set n = 1
set case1 = "$argv[$n]"
set n = 2
set fincl1 = "$argv[$n]"
if (`hostname` == "hobart.cgd.ucar.edu") then
  set data_dir = "/scratch/cluster/$USER/"
  set ncl_dir = "/home/$USER/arh-git-scripts/ncl/"
  echo "You are on Hobart"
  echo "NCL directory is "$ncl_dir
else
  set data_dir = "/glade2/scratch2/$USER/"
  set ncl_dir = "/glade/p/work/$USER/CESM2/arh-git-scripts/ncl/"
  echo "You are on Glade"
  echo "NCL directory is "$ncl_dir
endif

ncl 'dir="'$data_dir'"' 'fname1="'$case1'"' 'fincl1="'$fincl1'"' $ncl_dir/omg-pdf-1case.ncl

