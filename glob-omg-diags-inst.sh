#!/bin/tcsh
# compute omega diagnostics
# ne30 is about 20-30 min using 200 GB
# ne60 is about 1.5 hrs at 500 GB (can use 350GB)
# ne120 only works for the tropics before getting killed (at 800GB) 

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
  set ncl_dir = "/home/$USER/arh-git-scripts/ncl-scripts"
  echo "You are on Hobart"
  echo "NCL directory is "$ncl_dir
else
  #set data_dir = "/glade2/scratch2/$USER/"
  set data_dir = "/glade/scratch_new/$USER/"
  #set ncl_dir = "/glade/p/work/$USER/CESM2/arh-git-scripts/ncl/"
  set ncl_dir = "/glade/work/aherring/CESM2/temp/"
  echo "You are on Glade"
  echo "NCL directory is "$ncl_dir
endif

ncl 'dir="'$data_dir'"' 'fname1="'$case1'"' 'fincl1="'$fincl1'"' $ncl_dir/omg-diags.ncl

