#!/bin/tcsh
setenv proj "P54048000"
setenv src "camtrunk_190912" ##"camtrunk_190219" ##"physgrid_190201" #"physgrid_190201" #"physgrid_180607"
setenv res "ne30_ne30_mg17"
setenv comp "FKESSLER"
setenv wall "00:10:00"
setenv pes "1800"
setenv caze ${src}_${comp}-steady_${res}_pe${pes}_`date '+%y%m%d'`

/glade/u/home/$USER/src/$src/cime/scripts/create_newcase --case /glade/scratch/$USER/$caze --compset $comp --res $res --walltime $wall --mach cheyenne --pecount $pes --compiler intel --queue premium -project $proj --run-unsupported
cd /glade/scratch/$USER/$caze

# no threading
./xmlchange NTHRDS=1
./xmlchange STOP_OPTION=ndays,STOP_N=15
./xmlchange DOUT_S=FALSE

# test tracers on
./xmlchange --append CAM_CONFIG_OPTS="-nadv_tt=6"

./xmlchange ATM_NCPL=48
echo "se_nsplit = 2">>user_nl_cam
echo "se_rsplit = 3">>user_nl_cam

## ne30 E15, ne60 E14, ne120 E13
cho "se_nu              =   0.4e15  ">> user_nl_cam
cho "se_nu_div          =   1.0e15  ">> user_nl_cam
cho "se_nu_p            =   1.0e15  ">> user_nl_cam

#./xmlchange --append CAM_CONFIG_OPTS="-analytic_ic"

# grids still need to be hacked
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne20np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne20np4.pg3_gx1v7.180605.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne20np4.pg3_gx1v7.180605.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne20np4.pg3_gx1v7.180605.nc"
#echo "ncdata = '/fs/cgd/csm/inputdata/atm/cam/inic/cam_vcoords_L30_c180105.nc'">> user_nl_cam

#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne80np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne80np4.pg3_gx1v7.180608.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne80np4.pg3_gx1v7.180608.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne80np4.pg3_gx1v7.180608.nc"
#echo "ncdata = '/fs/cgd/csm/inputdata/atm/cam/inic/cam_vcoords_L30_c180105.nc'">> user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/cam_vcoords_L30_c180105.nc'">> user_nl_cam

#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne40np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne40np4.pg3_gx1v7.180605.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne40np4.pg3_gx1v7.180605.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne40np4.pg3_gx1v7.180605.nc"

#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne30np4.pg4"
#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne30np4.pg4_gx1v7.170628.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne30np4.pg4_gx1v7.170628.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne30np4.pg4_gx1v7.170628.nc"

#echo "se_ftype=1">> user_nl_cam
#echo "se_qsize_condensate_loading = 1">> user_nl_cam

echo "inithist          = 'NONE'                                                 ">> user_nl_cam
echo "se_statediag_numtrac      = 99     ">>user_nl_cam
echo "se_statefreq              = 244    ">>user_nl_cam
echo "empty_htapes       = .true.                                                ">> user_nl_cam

##history
#echo "fincl1 = 'Q','CLDLIQ','RAINQM','T','U','V','iCLy','iCL','iCL2','OMEGA',    ">>user_nl_cam
#echo "		'CL','CL2','PTTEND','PS','PRECL'				  ">>user_nl_cam
#echo "fincl2 = 'WV_pBF','WL_pBF','WI_pBF','SE_pBF','KE_pBF',    ">> user_nl_cam
#echo "          'WV_pBP','WL_pBP','WI_pBP','SE_pBP','KE_pBP',   ">> user_nl_cam
#echo "          'WV_pAP','WL_pAP','WI_pAP','SE_pAP','KE_pAP',   ">> user_nl_cam
#echo "          'WV_pAM','WL_pAM','WI_pAM','SE_pAM','KE_pAM',   ">> user_nl_cam
#echo "          'WV_dED','WL_dED','WI_dED','SE_dED','KE_dED',   ">> user_nl_cam
#echo "          'WV_dAF','WL_dAF','WI_dAF','SE_dAF','KE_dAF',   ">> user_nl_cam
#echo "          'WV_dBD','WL_dBD','WI_dBD','SE_dBD','KE_dBD',   ">> user_nl_cam
#echo "          'WV_dAD','WL_dAD','WI_dAD','SE_dAD','KE_dAD',   ">> user_nl_cam
#echo "          'WV_dAR','WL_dAR','WI_dAR','SE_dAR','KE_dAR',   ">> user_nl_cam
#echo "          'WV_dBF','WL_dBF','WI_dBF','SE_dBF','KE_dBF',   ">> user_nl_cam
#echo "          'WV_dBH','WL_dBH','WI_dBH','SE_dBH','KE_dBH',   ">> user_nl_cam
#echo "          'WV_dCH','WL_dCH','WI_dCH','SE_dCH','KE_dCH',   ">> user_nl_cam
#echo "          'WV_dAH','WL_dAH','WI_dAH','SE_dAH','KE_dAH'    ">> user_nl_cam
#echo "          'WV_PDC','WL_PDC','WI_PDC','TT_PDC','EFIX',     ">> user_nl_cam
#echo "          'WV_p2d','WL_p2d','WI_p2d','SE_p2d','KE_p2d'    ">> user_nl_cam
#echo "fincl3 = 'WV_pBF','WL_pBF','WI_pBF','SE_pBF','KE_pBF',    ">> user_nl_cam
#echo "          'WV_pBP','WL_pBP','WI_pBP','SE_pBP','KE_pBP',   ">> user_nl_cam
#echo "          'WV_pAP','WL_pAP','WI_pAP','SE_pAP','KE_pAP',   ">> user_nl_cam
#echo "          'WV_pAM','WL_pAM','WI_pAM','SE_pAM','KE_pAM',   ">> user_nl_cam
#echo "          'WV_dED','WL_dED','WI_dED','SE_dED','KE_dED',   ">> user_nl_cam
#echo "          'WV_dAF','WL_dAF','WI_dAF','SE_dAF','KE_dAF',   ">> user_nl_cam
#echo "          'WV_dBD','WL_dBD','WI_dBD','SE_dBD','KE_dBD',   ">> user_nl_cam
#echo "          'WV_dAD','WL_dAD','WI_dAD','SE_dAD','KE_dAD',   ">> user_nl_cam
#echo "          'WV_dAR','WL_dAR','WI_dAR','SE_dAR','KE_dAR',   ">> user_nl_cam
#echo "          'WV_dBF','WL_dBF','WI_dBF','SE_dBF','KE_dBF',   ">> user_nl_cam
#echo "          'WV_dBH','WL_dBH','WI_dBH','SE_dBH','KE_dBH',   ">> user_nl_cam
#echo "          'WV_dCH','WL_dCH','WI_dCH','SE_dCH','KE_dCH',   ">> user_nl_cam
#echo "          'WV_dAH','WL_dAH','WI_dAH','SE_dAH','KE_dAH'    ">> user_nl_cam
#echo "          'WV_PDC','WL_PDC','WI_PDC','TT_PDC','EFIX',     ">> user_nl_cam
#echo "          'WV_p2d','WL_p2d','WI_p2d','SE_p2d','KE_p2d'    ">> user_nl_cam
#echo "avgflag_pertape(1) = 'I'"                                                    >> user_nl_cam
#echo "avgflag_pertape(2) = 'I'"                                                    >> user_nl_cam
#echo "avgflag_pertape(3) = 'I'"                                                    >> user_nl_cam
#echo "nhtfrq             = -6,-6,-6                                               ">> user_nl_cam
#echo "mfilt              = 61,61,61                                               ">> user_nl_cam
#echo "ndens              = 2,1,2                                                  ">> user_nl_cam
#echo "interpolate_output = .false.,.false.,.true."                                 >> user_nl_cam

echo "fincl1 = 'Q','CLDLIQ','RAINQM','T','U','V','iCLy','iCL','iCL2','OMEGA',     ">> user_nl_cam
echo "          'CL','CL2','PTTEND','PS','PSDRY','PRECL','PSDRY_gll'              ">> user_nl_cam
echo "fincl2 = 'Q','CLDLIQ','RAINQM','T','U','V','iCLy','iCL','iCL2','OMEGA',     ">> user_nl_cam
echo "          'CL','CL2','PTTEND','PS','PSDRY','PRECL','PSDRY_gll'              ">> user_nl_cam
echo "fincl3 = 'TT_SLOT','TT_GBALL','TT_TANH','TT_EM8','TT_Y2_2','TT_Y32_16'	  ">> user_nl_cam
echo "fincl4 = 'TT_SLOT','TT_GBALL','TT_TANH','TT_EM8','TT_Y2_2','TT_Y32_16'      ">> user_nl_cam
echo "nhtfrq         = -6,-6,-6,-6                                                ">> user_nl_cam
echo "mfilt          = 121,121,121,121                                            ">> user_nl_cam
echo "avgflag_pertape(1) = 'I'"                                                    >> user_nl_cam
echo "avgflag_pertape(2) = 'I'"                                                    >> user_nl_cam
echo "avgflag_pertape(3) = 'I'"                                                    >> user_nl_cam
echo "avgflag_pertape(4) = 'I'"                                                    >> user_nl_cam
echo "interpolate_output = .true.,.false.,.true.,.false."       		   >> user_nl_cam

cp /glade/u/home/$USER/src/$src/components/cam/usr_src/steady-jet/ic_baroclinic.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/


./case.setup
qcmd -- ./case.build
./case.submit
