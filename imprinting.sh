#!/bin/tcsh
# plots omega in orthographic and dist-pressure transect
# default assumes data is on lat-lon grid

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
  set ncl_dir = "/home/$USER/ncl-scripts"
  echo "You are on Hobart"
  echo "NCL directory is"$ncl_dir
else
  ##for now, lets just stick to hobart
  ##set data_dir = "/glade/scratch/$USER/"
  ##setenv ncl_dir "/glade/p/work/$USER/CESM2"
endif

ncl 'dir="'$data_dir'"' 'fname1="'$case1'"' 'fname2="'$case2'"' 'fincl1="'$fincl1'"' 'fincl2="'$fincl2'"' $ncl_dir/contour/var_cam_region_panels_topo_2case.ncl

ncl 'dir="'$data_dir'"' 'fname1="'$case1'"' 'fname2="'$case2'"' 'fincl1="'$fincl1'"' 'fincl2="'$fincl2'"' $ncl_dir/transect/transect_2case.ncl
