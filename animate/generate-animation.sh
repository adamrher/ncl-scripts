#!/bin/tcsh

set data_dir = "/glade/scratch/aherring/"
set case1    = "physgrid_180607_QPC6_ne30_ne30_mg17_180709"
set fincl1   = "h4"
set VAR1     = "TMQ"

ncl 'dir="'$data_dir'"' 'fname1="'$case1'"' 'fincl1="'$fincl1'"' 'VAR1="'$VAR1'"' var_cam.ncl

convert -quality 100 -set delay 5 -scale 100% *.png temp.gif

rm *.png
