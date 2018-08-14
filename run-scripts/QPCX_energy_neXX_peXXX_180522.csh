#!/bin/tcsh
setenv proj "P93300642" #"P93300642"
setenv src "physgrid_180607" #"physgrid_180607" "cesm2_0_alpha10f"
setenv res "ne30_ne30_mg17"
setenv comp "QPC6"
setenv wall "02:00:00"
setenv pes "1800"
setenv caze ${src}_${comp}_${res}_`date '+%y%m%d'`

## ne30 - pe1800 - QPC6 (1.09 hrs/sy)
## ne60pg3 - pe3840 - QPC6 (4.07 hrs/sy)
## ne120pg3 - pe7680 - QPC6 (14.12 hrs/sy)

/glade/u/home/$USER/$src/cime/scripts/create_newcase --case /glade/scratch/$USER/$caze --compset $comp --res $res --walltime $wall --pecount $pes --project $proj --compiler intel --queue regular --run-unsupported
cd /glade/scratch/$USER/$caze

./xmlchange STOP_OPTION=nyears,STOP_N=1
./xmlchange NTHRDS=1
./xmlchange DOUT_S=FALSE
./xmlchange RESUBMIT=0

#--------timings----------
#./xmlchange TIMER_LEVEL=10

#-----independent of resolution-----

#echo "seasalt_emis_scale = 0">>user_nl_cam
#echo "micro_mg_nccons = .false.">>user_nl_cam
#echo "micro_mg_nicons = .false.">>user_nl_cam
#echo "flux_max_iteration = 2">>user_nl_cam
#echo "zmconv_num_cin = 1">> user_nl_cam
#echo "cld_macmic_num_steps = 1">> user_nl_cam
#echo "se_ftype=1">> user_nl_cam
#echo "se_qsize_condensate_loading = 1">> user_nl_cam

#------dependent on resolution-------

## ne30=48, ne60=96, ne120=192
./xmlchange ATM_NCPL=48

## for ne120 and ATM_NCPL = 384, set nsplit = 1
echo "se_nsplit = 2">>user_nl_cam
echo "se_rsplit = 3">>user_nl_cam

## ne30 E15, ne60 E14, ne120 E13
#echo "se_nu              =   1.5e15  ">> user_nl_cam
#echo "se_nu_div          =   3.8e15  ">> user_nl_cam
#echo "se_nu_p            =   3.8e15  ">> user_nl_cam

echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne30np4_L32_c170509.nc'">>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne60np4_L32_c170908.nc'">>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_cam6_ne120np4_L32_c170908.nc'">>user_nl_cam

#------non-standard grids-------
# grids need to be hacked

#echo "ncdata = '/glade/p/work/aherring/cesm_inputfiles/ncdata/ape_cam6_ne20np4_L32_c180606.nc'">>user_nl_cam
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne20np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne20np4.pg3_gx1v7.180605.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne20np4.pg3_gx1v7.180605.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne20np4.pg3_gx1v7.180605.nc"

#echo "ncdata = '/glade/p/work/aherring/cesm_inputfiles/ncdata/ape_cam6_ne40np4_L32_c180606.nc'">>user_nl_cam
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne40np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne40np4.pg3_gx1v7.180605.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne40np4.pg3_gx1v7.180605.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne40np4.pg3_gx1v7.180605.nc"

#echo "ncdata = '/glade/p/work/aherring/cesm_inputfiles/ncdata/ape_cam6_ne80np4_L32_c180612.nc'">>user_nl_cam
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne80np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne80np4.pg3_gx1v7.180608.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne80np4.pg3_gx1v7.180608.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne80np4.pg3_gx1v7.180608.nc"

# colin hack for non-standard grids
#echo "drydep_srf_file = '/glade/p/cesmdata/cseg/inputdata/atm/cam/chem/trop_mam/atmsrf_ne120np4_110920.nc'">> user_nl_cam

#mental note - U850 causes a weird error (removed)
#--------------------------------------history----------------------------------------------
echo "inithist          = 'NONE'                                             ">> user_nl_cam
echo "se_statefreq      = 144                                                ">> user_nl_cam
echo "empty_htapes      = .true.                                             ">> user_nl_cam
echo "fincl1 =   'PS','T','Q','Z3','U','V','OMEGA','PRECL','PRECC','FREQZM', ">> user_nl_cam
echo "		 'FREQI','FREQL','CLDLIQ','CLDICE','CLOUD','CLDTOT','TMQ',   ">> user_nl_cam
echo "		 'FLNT','FLNS','FSNT','FSNS','LHFLX','SHFLX','RELHUM','TS',  ">> user_nl_cam
echo "           'SL','PBLH','PSDRY','PSDRY_gll','PRECSC','PRECSL','PTTEND'  ">> user_nl_cam
echo "           'VZ','VT','VU','VQ','OMEGAV','OMEGAU','ZZ'	    	     ">> user_nl_cam
echo "fincl2 =   'PS','T','Q','Z3','U','V','OMEGA','PRECL','PRECC','FREQZM', ">> user_nl_cam
echo "           'FREQI','FREQL','CLDLIQ','CLDICE','CLOUD','CLDTOT','TMQ',   ">> user_nl_cam
echo "           'FLNT','FLNS','FSNT','FSNS','LHFLX','SHFLX','RELHUM','TS',  ">> user_nl_cam
echo "           'SL','PBLH','PSDRY','PSDRY_gll','PRECSC','PRECSL','PTTEND'  ">> user_nl_cam
echo "           'VZ','VT','VU','VQ','OMEGAV','OMEGAU','ZZ'	             ">> user_nl_cam
echo "fincl3 =  'WV_pBF','WL_pBF','WI_pBF','SE_pBF','KE_pBF',    	     ">> user_nl_cam
echo "          'WV_pBP','WL_pBP','WI_pBP','SE_pBP','KE_pBP',   	     ">> user_nl_cam
echo "          'WV_pAP','WL_pAP','WI_pAP','SE_pAP','KE_pAP',   	     ">> user_nl_cam
echo "          'WV_pAM','WL_pAM','WI_pAM','SE_pAM','KE_pAM',  		     ">> user_nl_cam
echo "          'WV_dED','WL_dED','WI_dED','SE_dED','KE_dED',   	     ">> user_nl_cam
echo "          'WV_dAF','WL_dAF','WI_dAF','SE_dAF','KE_dAF',   	     ">> user_nl_cam
echo "          'WV_dBD','WL_dBD','WI_dBD','SE_dBD','KE_dBD',  		     ">> user_nl_cam
echo "          'WV_dAD','WL_dAD','WI_dAD','SE_dAD','KE_dAD',  		     ">> user_nl_cam
echo "          'WV_dAR','WL_dAR','WI_dAR','SE_dAR','KE_dAR', 		     ">> user_nl_cam
echo "          'WV_dBF','WL_dBF','WI_dBF','SE_dBF','KE_dBF',  		     ">> user_nl_cam
echo "          'WV_dBH','WL_dBH','WI_dBH','SE_dBH','KE_dBH',  		     ">> user_nl_cam
echo "          'WV_dCH','WL_dCH','WI_dCH','SE_dCH','KE_dCH',  		     ">> user_nl_cam
echo "          'WV_dAH','WL_dAH','WI_dAH','SE_dAH','KE_dAH',  		     ">> user_nl_cam
echo "          'WV_PDC','WL_PDC','WI_PDC','TT_PDC','EFIX',      	     ">> user_nl_cam
echo "          'WV_p2d','WL_p2d','WI_p2d','SE_p2d','KE_p2d',		     ">> user_nl_cam
echo "          'U','V','PS'						     ">> user_nl_cam
echo "fincl4 =   'PSDRY','PS','T','Q','Z3','U','V','OMEGA','OMEGA_gll'       ">> user_nl_cam
#echo "fincl4 =   'PSDRY','PS','T','Q','Z3','U','V','OMEGA','OMEGA_gll',      ">> user_nl_cam
#echo "	  	 'CLDLIQ','CLDICE'				             ">> user_nl_cam
echo "fincl5 =   'PRECL','PRECC','Q850','OMEGA850','TMQ','FLNT'	     ">> user_nl_cam
echo "           'PTTEND','FT','PTEQ'                                ">> user_nl_cam
#echo "		 'PTTEND','FT','PTEQ','FQ_fvm'				     ">> user_nl_cam
echo "avgflag_pertape(1) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(2) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(3) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(4) = 'I'"                                               >> user_nl_cam
echo "avgflag_pertape(5) = 'I'"                                               >> user_nl_cam
echo "nhtfrq             = 0,0,0,-6,-6"                                       >> user_nl_cam
echo "mfilt              = 1,1,1,120,120"                                     >> user_nl_cam
echo "ndens              = 2,1,1,2,2"                                         >> user_nl_cam
echo "interpolate_output = .true.,.false.,.false.,.false.,.false."            >> user_nl_cam

#omega_gll
cp /glade/u/home/aherring/$src/components/cam/usr_src/omega_gll/stepon.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

#no zm-momtran
#cp /glade/u/home/aherring/$src/components/cam/usr_src/momtran/zm_conv_intr.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

#cpdry
#cp /glade/u/home/aherring/$src/components/cam/usr_src/lcpmoist/dyn_comp.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

#iwidth,PCoM
#cp /glade/u/home/aherring/$src/components/cam/usr_src/bilin/fvm_mapping.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

./case.setup
qcmd -- ./case.build # --skip-provenance-check
./case.build # --skip-provenance-check
./case.submit
