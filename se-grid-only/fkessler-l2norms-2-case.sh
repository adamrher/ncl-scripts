#!/bin/tcsh

if ( "$#argv" != 4) then
  echo "Wrong number of arguments specified:"
  echo "  -arg 1 case1 string"
  echo "  -arg 2 is fincl number (e.g. h0)"
  echo "  -arg 3 case2 string"
  echo "  -arg 4 is fincl number (e.g. h0)"
  exit
endif
set n = 1
set case1 = "$argv[$n]"
set n = 2
set fincl1 = "$argv[$n]"
set n = 3
set case2 = "$argv[$n]"
set n = 4
set fincl2 = "$argv[$n]"
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

ncl 'dir="'$data_dir'"' 'ncldir="'$ncl_dir'"' 'fname1="'$case1'"' 'fname2="'$case2'"' 'fincl1="'$fincl1'"' 'fincl2="'$fincl2'"' $ncl_dir/l2norms2-2case.ncl

