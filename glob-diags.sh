#!/bin/tcsh
# compute omega diagnostics

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
  set ncl_dir = "/home/$USER/2017-physres/ncl-scripts"
  echo "You are on Hobart"
  echo "NCL directory is "$ncl_dir
else
  set data_dir = "/glade2/scratch2/$USER/"
  set ncl_dir = "/glade/u/home/$USER/2017-physres/ncl-scripts"
  echo "You are on Glade"
  echo "NCL directory is "$ncl_dir
endif

ncl 'dir="'$data_dir'"' 'fname1="'$case1'"' 'fincl1="'$fincl1'"' $ncl_dir/all-diags.ncl

