#!/bin/tcsh
setenv proj "P54048000"

setenv src "camtrunk_190912"
#setenv src "camtrunk_190510"

#setenv res "ne0GREENLANDne30x4_ne0GREENLANDne30x4_mt12"
#setenv alias "ne0GREENLANDne30x4_mt12"

#setenv res "ne0ARCTICne30x4_ne0ARCTICne30x4_mt12"
#setenv alias "ne0ARCTICne30x4_mt12"

#setenv res "ne0EQUATOR-LOWne30x4_ne0EQUATOR-LOWne30x4_mt12"
#setenv alias "ne0EQUATOR-LOWne30x4_mt12"

setenv res "ne0EQUATOR-HIne30x4_ne0EQUATOR-HIne30x4_mt12"
setenv alias "ne0EQUATOR-HIne30x4_mt12"

#setenv res "ne0ARCTIC-GrISne30x8_ne0ARCTIC-GrISne30x8_mt12"
#setenv alias "ne0ARCTIC-GrISne30x8_mt12"

setenv comp "FKESSLER"
setenv wall "00:40:00"
setenv pes "1800"
setenv caze ${src}_${comp}-steady_${alias}_`date '+%y%m%d'`

/glade/u/home/$USER/src/$src/cime/scripts/create_newcase --case /glade/scratch/$USER/$caze --compset $comp --res $res --walltime $wall --pecount $pes --project $proj --compiler intel --queue premium --run-unsupported
cd /glade/scratch/$USER/$caze

./xmlchange STOP_OPTION=ndays,STOP_N=30
./xmlchange RESUBMIT=0
./xmlchange NTHRDS=2
./xmlchange DOUT_S=FALSE
#./xmlchange TIMER_LEVEL=10

# test tracers on
./xmlchange --append CAM_CONFIG_OPTS="-nadv_tt=6"

#-----time stepping-----
./xmlchange ATM_NCPL=192
echo "se_nsplit=4               ">> user_nl_cam
echo "se_rsplit=3               ">> user_nl_cam
echo "se_qsplit=1		">> user_nl_cam
echo "se_hypervis_subcycle=4    ">> user_nl_cam
echo "se_ftype=0                ">> user_nl_cam

#-----Viscosity-----
#--Tensor Form
#echo "se_hypervis_scaling    =   3.3219     ">> user_nl_cam
#echo "se_nu_div              =   15.8e-8    ">> user_nl_cam
#echo "se_nu		     =   8.e-8      ">> user_nl_cam
#echo "se_nu_p 		     =   8.e-8      ">> user_nl_cam

#--Scalar Form
#echo "se_hypervis_power      =   3.3219     ">> user_nl_cam
#echo "se_nu_div              =   1.0e13     ">> user_nl_cam
#echo "se_nu                  =   0.4e13     ">> user_nl_cam
#echo "se_nu_p                =   1.0e13     ">> user_nl_cam
#echo "se_max_hypervis_courant=   1.9        ">> user_nl_cam
echo "se_fine_ne             =   120        ">> user_nl_cam

#------Grid Stuff-------
echo "se_refined_mesh        = .true.       ">> user_nl_cam

./xmlchange EPS_AAREA=1e-4

#./xmlchange ATM_GRID=ne0np4GREENLAND.ne30x4
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne0np4GREENLAND.ne30x4"

#./xmlchange ATM_GRID=ne0np4ARCTIC.ne30x4
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne0np4ARCTIC.ne30x4"

#./xmlchange ATM_GRID=ne0np4EQUATOR-LOW.ne30x4
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne0np4EQUATOR-LOW.ne30x4"

./xmlchange ATM_GRID=ne0np4EQUATOR-HI.ne30x4
./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne0np4EQUATOR-HI.ne30x4"

#./xmlchange ATM_GRID=ne0np4ARCTIC-GrIS.ne30x8
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne0np4ARCTIC-GrIS.ne30x8"

./xmlchange ATM_DOMAIN_PATH="/glade/work/aherring/grids/var-res/domain_files/"
./xmlchange OCN_DOMAIN_PATH="/glade/work/aherring/grids/var-res/domain_files/"
./xmlchange ICE_DOMAIN_PATH="/glade/work/aherring/grids/var-res/domain_files/"

#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne0np4GREENLAND_tx0.1v2.190919.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne0np4GREENLAND_tx0.1v2.190919.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne0np4GREENLAND_tx0.1v2.190919.nc"

#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne0np4ARCTIC_tx0.1v2.190919.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne0np4ARCTIC_tx0.1v2.190919.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne0np4ARCTIC_tx0.1v2.190919.nc"

#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne0np4EQUATOR-LOW_tx0.1v2.190919.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne0np4EQUATOR-LOW_tx0.1v2.190919.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne0np4EQUATOR-LOW_tx0.1v2.190919.nc"

./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne0np4EQUATOR-HI_tx0.1v2.190919.nc"
./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne0np4EQUATOR-HI_tx0.1v2.190919.nc"
./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne0np4EQUATOR-HI_tx0.1v2.190919.nc"

#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne0np4ARCTIC-GrIS_tx0.1v2.190919.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne0np4ARCTIC-GrIS_tx0.1v2.190919.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne0np4ARCTIC-GrIS_tx0.1v2.190919.nc"

#echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/VR_Greenland_111-55-28.g'">> user_nl_cam
#echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/arctic-lowerconn_ne30_4x_ne120.g'">> user_nl_cam
#echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/equator-lowerconn_ne30_4x_ne120.g'">> user_nl_cam
echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/equator-hiconn_ne30_4x_ne120.g'">> user_nl_cam
#echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/arctic-GrIS_ne30-8x-240.g'">> user_nl_cam

echo "inithist          = 'NONE'                                                 ">> user_nl_cam
echo "se_statediag_numtrac      = 99     ">>user_nl_cam
echo "se_statefreq              = 244    ">>user_nl_cam
echo "empty_htapes       = .true.                                                ">> user_nl_cam

echo "fincl1 = 'Q','CLDLIQ','RAINQM','T','U','V','iCLy','iCL','iCL2','OMEGA',     ">> user_nl_cam
echo "          'CL','CL2','PTTEND','PS','PSDRY','PRECL','PSDRY_gll'              ">> user_nl_cam
echo "fincl2 = 'Q','CLDLIQ','RAINQM','T','U','V','iCLy','iCL','iCL2','OMEGA',     ">> user_nl_cam
echo "          'CL','CL2','PTTEND','PS','PSDRY','PRECL','PSDRY_gll'              ">> user_nl_cam
echo "fincl3 = 'TT_SLOT','TT_GBALL','TT_TANH','TT_EM8','TT_Y2_2','TT_Y32_16'      ">> user_nl_cam
echo "fincl4 = 'TT_SLOT','TT_GBALL','TT_TANH','TT_EM8','TT_Y2_2','TT_Y32_16'      ">> user_nl_cam
echo "nhtfrq         = -6,-6,-6,-6                                                ">> user_nl_cam
echo "mfilt          = 121,121,121,121                                            ">> user_nl_cam
echo "avgflag_pertape(1) = 'I'"                                                    >> user_nl_cam
echo "avgflag_pertape(2) = 'I'"                                                    >> user_nl_cam
echo "avgflag_pertape(3) = 'I'"                                                    >> user_nl_cam
echo "avgflag_pertape(4) = 'I'"                                                    >> user_nl_cam
echo "interpolate_output = .true.,.false.,.true.,.false."                          >> user_nl_cam

cp /glade/u/home/$USER/src/$src/components/cam/usr_src/steady-jet/ic_baroclinic.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

./case.setup
qcmd -- ./case.build
./case.submit
