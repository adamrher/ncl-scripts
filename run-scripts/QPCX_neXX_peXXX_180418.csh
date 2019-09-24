#!/bin/tcsh
setenv proj "P54048000" ##"P03010039" ##"UNSB0017"
setenv src "camtrunk_190912" ##"physgrid_190201" ##"physgrid_180607"  
setenv res "ne30_ne30_mg17"
setenv comp "QPC6"
setenv wall "00:30:00"
setenv pes "1800"
setenv caze ${src}_${comp}_${res}_`date '+%y%m%d'`

## ne30 - pe1800 - QPC6 (1.09 hrs/sy)
## ne60pg3 - pe3840 - QPC6 (4.07 hrs/sy)
## ne120pg3 - pe7680 - QPC6 (14.12 hrs/sy)

/glade/u/home/$USER/src/$src/cime/scripts/create_newcase --case /glade/scratch/$USER/$caze --compset $comp --res $res --walltime $wall --pecount $pes --project $proj --compiler intel --queue regular --run-unsupported
cd /glade/scratch/$USER/$caze

./xmlchange STOP_OPTION=nmonths,STOP_N=1
./xmlchange RESUBMIT=0
./xmlchange NTHRDS=2
./xmlchange DOUT_S=FALSE
./xmlchange TIMER_LEVEL=10

#-----independent of resolution-----

#echo "se_nsplit = 1">>user_nl_cam
#echo "se_rsplit = 1">>user_nl_cam

#echo "flux_max_iteration = 2">>user_nl_cam
#echo "zmconv_num_cin = 5">> user_nl_cam
#echo "cld_macmic_num_steps = 1">> user_nl_cam

#------dependent on resolution-------

## ne30=48, ne60=96, ne120=192
./xmlchange ATM_NCPL=48

## ne30 E15, ne60 E14, ne120 E13
echo "se_nu              =   0.4e15  ">> user_nl_cam
echo "se_nu_div          =   1.0e15  ">> user_nl_cam
echo "se_nu_p            =   1.0e15  ">> user_nl_cam

#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne30np4_L32_c170509.nc'">>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne60np4_L32_c170908.nc'">>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne120np4_L32_c170908.nc'">>user_nl_cam

#------non-standard grids-------
# grids need to be hacked

#echo "ncdata = '/glade/work/aherring/cesm_inputfiles/ncdata/ape_cam6_ne20np4_L32_c180606.nc'">>user_nl_cam
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne20np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.lnd.ne20np4.pg3_gx1v7.180605.nc"
#./xmlchange OCN_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.ocn.ne20np4.pg3_gx1v7.180605.nc"
#./xmlchange ICE_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.ocn.ne20np4.pg3_gx1v7.180605.nc"

#echo "ncdata = '/glade/work/aherring/cesm_inputfiles/ncdata/ape_cam6_ne40np4_L32_c180606.nc'">>user_nl_cam
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne40np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.lnd.ne40np4.pg3_gx1v7.180605.nc"
#./xmlchange OCN_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.ocn.ne40np4.pg3_gx1v7.180605.nc"
#./xmlchange ICE_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.ocn.ne40np4.pg3_gx1v7.180605.nc"

#echo "ncdata = '/glade/work/aherring/cesm_inputfiles/ncdata/ape_cam6_ne80np4_L32_c180612.nc'">>user_nl_cam
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne80np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.lnd.ne80np4.pg3_gx1v7.180608.nc"
#./xmlchange OCN_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.ocn.ne80np4.pg3_gx1v7.180608.nc"
#./xmlchange ICE_DOMAIN_FILE="/glade/work/aherring/grids/physgrids/domain_files/domain.ocn.ne80np4.pg3_gx1v7.180608.nc"

## colin hack for non-standard grids
#echo "drydep_srf_file = '/glade/p/cesmdata/cseg/inputdata/atm/cam/chem/trop_mam/atmsrf_ne120np4_110920.nc'">> user_nl_cam

#mental note - U850 causes a weird error (removed)
#--------------------------------------history----------------------------------------------
echo "inithist          = 'MONTHLY'                                          ">> user_nl_cam
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
echo "fincl3 =   'PSDRY','PS','T','Q','Z3','U','V','OMEGA'                   ">> user_nl_cam
echo "fincl4 =   'PRECL','PRECC','Q850','OMEGA850','TMQ','FLNT','FREQZM'     ">> user_nl_cam
echo "fincl5 =   'ZMDT','MPDT','STEND_CLUBB','PTTEND','FT','CMFMCDZM'	     ">> user_nl_cam	
echo "avgflag_pertape(1) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(2) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(3) = 'I'"                                               >> user_nl_cam
echo "avgflag_pertape(4) = 'I'"                                               >> user_nl_cam
echo "avgflag_pertape(5) = 'I'"                                               >> user_nl_cam
echo "nhtfrq             = 0,0,-6,-6,-6"                                      >> user_nl_cam
echo "mfilt              = 1,1,120,120,120"                                   >> user_nl_cam
echo "ndens              = 2,2,2,2,2"                                         >> user_nl_cam
echo "interpolate_output = .true.,.false.,.false.,.false.,.false."            >> user_nl_cam

#omega_gll
#cp /glade/u/home/aherring/src/$src/components/cam/usr_src/omega_gll/stepon.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

./case.setup
qcmd -- ./case.build #--skip-provenance-check
./case.submit
