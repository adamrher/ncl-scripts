#!/bin/tcsh
setenv proj "P93300642"
setenv src "cesm2_0_alpha10f" #"physgrid_180515" "cesm2_alpha10c"
setenv res "ne30pg3_ne30pg3_mg17"
setenv comp "QPC6"
setenv wall "01:00:00"
setenv pes "1800"
setenv caze ${src}_${comp}_${res}_`date '+%y%m%d'`_pttend

## ne30 - pe1800 - QPC6 (1.09 hrs/sy)
## ne60pg3 - pe3840 - QPC6 (4.07 hrs/sy)
## ne120pg3 - pe7680 - QPC6 (14.12 hrs/sy)

/glade/u/home/$USER/$src/cime/scripts/create_newcase --case /glade/scratch/$USER/$caze --compset $comp --res $res --walltime $wall --pecount $pes --project $proj --compiler intel --queue regular --run-unsupported
cd /glade/scratch/$USER/$caze

./xmlchange STOP_OPTION=nmonths,STOP_N=6
./xmlchange NTHRDS=1
./xmlchange DOUT_S=FALSE

#-----independent of resolution-----

echo "se_nsplit = 2">>user_nl_cam
echo "se_rsplit = 3">>user_nl_cam

#echo "flux_max_iteration = 2">>user_nl_cam
#echo "zmconv_num_cin = 5">> user_nl_cam
#echo "cld_macmic_num_steps = 1">> user_nl_cam

#------dependent on resolution-------

## ne30=48, ne60=96, ne120=192
./xmlchange ATM_NCPL=48

## ne30 E15, ne60 E14, ne120 E13
#echo "se_nu              =   0.2e15  ">> user_nl_cam
#echo "se_nu_div          =   1.0e15  ">> user_nl_cam
#echo "se_nu_p            =   1.0e15  ">> user_nl_cam

echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne30np4_L32_c170509.nc'">>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne60np4_L32_c170908.nc'">>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne120np4_L32_c170908.nc'">>user_nl_cam

#mental note - U850 causes a weird error (removed)
#--------------------------------------history----------------------------------------------
echo "inithist          = 'NONE'                                             ">> user_nl_cam
echo "se_statefreq      = 144                                                ">> user_nl_cam
echo "empty_htapes      = .true.                                             ">> user_nl_cam
echo "fincl1 =   'PS','T','Q','Z3','U','V','OMEGA','PRECL','PRECC','FREQZM', ">> user_nl_cam
echo "		 'FREQI','FREQL','CLDLIQ','CLDICE','CLOUD','CLDTOT','TMQ',   ">> user_nl_cam
echo "		 'FLNT','FLNS','FSNT','FSNS','LHFLX','SHFLX','RELHUM','TS',  ">> user_nl_cam
echo "           'SL','PBLH','PSDRY','PSDRY_gll','PRECSC','PRECSL',	     ">> user_nl_cam
echo "           'PTTEND','EFIX'                                             ">> user_nl_cam
echo "fincl2 =   'PS','T','Q','Z3','U','V','OMEGA','PRECL','PRECC','FREQZM', ">> user_nl_cam
echo "           'FREQI','FREQL','CLDLIQ','CLDICE','CLOUD','CLDTOT','TMQ',   ">> user_nl_cam
echo "           'FLNT','FLNS','FSNT','FSNS','LHFLX','SHFLX','RELHUM','TS',  ">> user_nl_cam
echo "           'SL','PBLH','PSDRY','PSDRY_gll','PRECSC','PRECSL',          ">> user_nl_cam
echo "		 'PTTEND','EFIX'					     ">> user_nl_cam
echo "fincl3 =   'PSDRY','PS','T','Q','Z3','U','V','OMEGA','OMEGA_gll',      ">> user_nl_cam
echo "	  	 'CLDLIQ','CLDICE'				             ">> user_nl_cam
echo "fincl4 =   'PRECL','PRECC','Q850','OMEGA850','TMQ','FLNT'		     ">> user_nl_cam
echo "avgflag_pertape(1) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(2) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(3) = 'I'"                                               >> user_nl_cam
echo "avgflag_pertape(4) = 'I'"                                               >> user_nl_cam
echo "nhtfrq             = 0,0,-6,-6"                                         >> user_nl_cam
echo "mfilt              = 1,1,120,120"                                       >> user_nl_cam
echo "ndens              = 2,2,2,2"                                           >> user_nl_cam
echo "interpolate_output = .true.,.false.,.false.,.false."                    >> user_nl_cam

#omega_gll
cp /glade/u/home/aherring/$src/components/cam/usr_src/omega_gll/stepon.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

./case.setup
qcmd -- ./case.build --skip-provenance-check
./case.submit
