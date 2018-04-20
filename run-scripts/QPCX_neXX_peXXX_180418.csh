#!/bin/tcsh
setenv proj "P93300642"
setenv src "camtrunk_180328" #"physgrid_180401"
setenv res "ne60_ne60_mg16"
setenv comp "QPC6"
setenv wall "04:30:00"
setenv pes "3840"
setenv caze ${src}_${comp}_ne60_`date '+%y%m%d'`_flux_max_iter2

## ne30 - pe1800 - QPC6 (1.09 hrs/sy)
## ne60pg3 - pe3840 - QPC6 (4.07 hrs/sy)
## ne120pg3 - pe7680 - QPC6 (14.12 hrs/sy)

/glade/u/home/$USER/$src/cime/scripts/create_newcase --case /glade/scratch/$USER/$caze --compset $comp --res $res --walltime $wall --pecount $pes --project $proj --compiler intel --queue regular --run-unsupported
cd /glade/scratch/$USER/$caze

./xmlchange STOP_OPTION=nyears,STOP_N=1
./xmlchange NTHRDS=1
./xmlchange DOUT_S=FALSE

#-----independent of resolution-----

echo "se_nsplit = 2">>user_nl_cam
echo "se_rsplit = 3">>user_nl_cam

echo "flux_max_iteration = 2">>user_nl_cam
#echo "zmconv_num_cin = 5">> user_nl_cam
#echo "cld_macmic_num_steps = 1">> user_nl_cam

#------dependent on resolution-------

## ne30=48, ne60=96, ne120=192
./xmlchange ATM_NCPL=96

## ne30 E15, ne60 E14, ne120 E13
#echo "se_nu              =   0.2e15  ">> user_nl_cam
#echo "se_nu_div          =   1.0e15  ">> user_nl_cam
#echo "se_nu_p            =   1.0e15  ">> user_nl_cam

#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne30np4_L32_c170509.nc'">>user_nl_cam
echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne60np4_L32_c170908.nc'">>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne120np4_L32_c170908.nc'">>user_nl_cam

#mental note - U850 causes a weird error (removed)
#--------------------------------------history----------------------------------------------
echo "inithist          = 'NONE'                                             ">> user_nl_cam
echo "se_statefreq      = 144                                                ">> user_nl_cam
echo "empty_htapes      = .true.                                             ">> user_nl_cam
echo "fincl1 =   'PS','T','Q','Z3','U','V','OMEGA','PRECL','PRECC','FREQZM', ">> user_nl_cam
echo "		 'FREQI','FREQL','CLDLIQ','CLDICE','CLOUD','CLDTOT','TMQ',   ">> user_nl_cam
echo "		 'FLNT','FLNS','FSNT','FSNS','LHFLX','SHFLX','RELHUM','TS',  ">> user_nl_cam
echo "           'SL','PBLH','PSDRY'					     ">> user_nl_cam
echo "fincl2 =   'PSDRY','PS','T','Q','Z3','U','V','OMEGA','PRECL','PRECC'   ">> user_nl_cam
echo "avgflag_pertape(1) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(2) = 'I'"                                               >> user_nl_cam
echo "nhtfrq             = 0,-6"                                              >> user_nl_cam
echo "mfilt              = 1,120"                                             >> user_nl_cam
echo "ndens              = 2,2"                                               >> user_nl_cam
echo "interpolate_output = .true.,.false."                                    >> user_nl_cam

./case.setup
qcmd -- ./case.build
./case.submit
