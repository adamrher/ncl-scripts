#!/bin/tcsh
setenv proj "P54048000"

setenv src "camtrunk_190912"
#setenv src "camtrunk_190510"

#setenv res "ne0GREENLANDne30x4_ne0GREENLANDne30x4_mt12"
#setenv alias "ne0GREENLANDne30x4_mt12"

#setenv res "ne0ARCTICne30x4_ne0ARCTICne30x4_mt12"
#setenv alias "ne0ARCTICne30x4_mt12"

setenv res "ne0EQUATOR-LOWne30x4_ne0EQUATOR-LOWne30x4_mt12"
setenv alias "ne0EQUATOR-LOWne30x4_mt12"

#setenv res "ne0EQUATOR-HIne30x4_ne0EQUATOR-HIne30x4_mt12"
#setenv alias "ne0EQUATOR-HIne30x4_mt12"

#setenv res "ne0ARCTIC-GrISne30x8_ne0ARCTIC-GrISne30x8_mt12"
#setenv alias "ne0ARCTIC-GrISne30x8_mt12"

setenv comp "QPC6"
setenv wall "00:30:00"
setenv pes "1800"
setenv caze ${src}_${comp}_${alias}_`date '+%y%m%d'`_tensor-spinup-c

/glade/u/home/$USER/src/$src/cime/scripts/create_newcase --case /glade/scratch/$USER/$caze --compset $comp --res $res --walltime $wall --pecount $pes --project $proj --compiler intel --queue premium --run-unsupported
cd /glade/scratch/$USER/$caze

./xmlchange STOP_OPTION=ndays,STOP_N=10
./xmlchange RESUBMIT=0
./xmlchange NTHRDS=2
./xmlchange DOUT_S=FALSE
#./xmlchange TIMER_LEVEL=10

#-----time stepping-----
./xmlchange ATM_NCPL=192
echo "se_nsplit=3               ">> user_nl_cam
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

./xmlchange ATM_GRID=ne0np4EQUATOR-LOW.ne30x4
./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne0np4EQUATOR-LOW.ne30x4"

#./xmlchange ATM_GRID=ne0np4EQUATOR-HI.ne30x4
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne0np4EQUATOR-HI.ne30x4"

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

./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne0np4EQUATOR-LOW_tx0.1v2.190919.nc"
./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne0np4EQUATOR-LOW_tx0.1v2.190919.nc"
./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne0np4EQUATOR-LOW_tx0.1v2.190919.nc"

#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne0np4EQUATOR-HI_tx0.1v2.190919.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne0np4EQUATOR-HI_tx0.1v2.190919.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne0np4EQUATOR-HI_tx0.1v2.190919.nc"

#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne0np4ARCTIC-GrIS_tx0.1v2.190919.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne0np4ARCTIC-GrIS_tx0.1v2.190919.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne0np4ARCTIC-GrIS_tx0.1v2.190919.nc"

#echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/VR_Greenland_111-55-28.g'">> user_nl_cam
#echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/arctic-lowerconn_ne30_4x_ne120.g'">> user_nl_cam
echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/equator-lowerconn_ne30_4x_ne120.g'">> user_nl_cam
#echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/equator-hiconn_ne30_4x_ne120.g'">> user_nl_cam
#echo "se_mesh_file = '/glade/work/aherring/grids/var-res/exodus_files/arctic-GrIS_ne30-8x-240.g'">> user_nl_cam

## set to a grid with more than enough grid ncols (Colin's hack)
echo "drydep_srf_file = '/glade/p/cesmdata/cseg/inputdata/atm/cam/chem/trop_mam/atmsrf_ne240np4_110920.nc'">> user_nl_cam

#------Initial Conditions and Topography-------
#------QPC6
#echo "ncdata = '/glade/work/aherring/grids/var-res/ncdata/inic_QPC6_ne0np4.GREENLAND.ne30-4x-120_interpic.nc'">>user_nl_cam
#echo "ncdata = '/glade/work/aherring/grids/var-res/ncdata/inic_QPC6_ne0np4.ARCTIC.ne30_4x_120_interpic.nc'">>user_nl_cam
#echo "ncdata = '/glade/work/aherring/grids/var-res/ncdata/inic_QPC6_ne0np4.EQUATOR-LOW.ne30_4x_120_interpic.nc'">>user_nl_cam

#echo "ncdata = '/glade/scratch/aherring/camtrunk_190912_QPC6_ne0EQUATOR-LOWne30x4_mt12_190921_spinup-c/run/camtrunk_190912_QPC6_ne0EQUATOR-LOWne30x4_mt12_190921_spinup-c.cam.i.0001-01-11-00000.nc'">>user_nl_cam

echo "ncdata = '/glade/scratch/aherring/camtrunk_190912_QPC6_ne0EQUATOR-LOWne30x4_mt12_190921_tensor-spinup-b/run/camtrunk_190912_QPC6_ne0EQUATOR-LOWne30x4_mt12_190921_tensor-spinup-b.cam.i.0001-01-11-00000.nc'">>user_nl_cam

#echo "ncdata = '/glade/scratch/aherring/camtrunk_190510_QPC6_ne0EQUATOR-LOWne30x4_mt12_190921_spinup-d/run/camtrunk_190510_QPC6_ne0EQUATOR-LOWne30x4_mt12_190921_spinup-d.cam.i.0001-01-11-00000.nc'">>user_nl_cam

#echo "ncdata = '/glade/scratch/aherring/camtrunk_190510_QPC6_ne0EQUATOR-HIne30x4_mt12_190922_spinup-c/run/camtrunk_190510_QPC6_ne0EQUATOR-HIne30x4_mt12_190922_spinup-c.cam.i.0001-01-11-00000.nc'">>user_nl_cam

#echo "ncdata = '/glade/work/aherring/grids/var-res/ncdata/inic_QPC6_ne0np4.ARCTIC-GrIS.ne30_8x_240_interpic.nc'">>user_nl_cam

#------QPC5
#echo "ncdata = '/glade/work/aherring/grids/var-res/ncdata/inic_QPC5_ne0np4.EQUATOR-LOW.ne30_4x_120_interpic.nc'">>user_nl_cam

#--------------------------------------history----------------------------------------------
echo "inithist          = 'DAILY'                                            ">> user_nl_cam
echo "se_statefreq      = 144                                                ">> user_nl_cam
echo "empty_htapes      = .true.                                             ">> user_nl_cam
#echo "fincl1 =   'PS','T','Q','Z3','U','V','OMEGA','PRECL','PRECC','FREQZM', ">> user_nl_cam
#echo "		 'FREQI','FREQL','CLDLIQ','CLDICE','CLOUD','CLDTOT','TMQ',   ">> user_nl_cam
#echo "		 'FLNT','FLNS','FSNT','FSNS','LHFLX','SHFLX','RELHUM','TS',  ">> user_nl_cam
#echo "           'SL','PBLH','PSDRY','PSDRY_gll','PRECSC','PRECSL',	     ">> user_nl_cam
#echo "           'PTTEND','EFIX'                                             ">> user_nl_cam
#echo "fincl2 =   'PS','T','Q','Z3','U','V','OMEGA','PRECL','PRECC','FREQZM', ">> user_nl_cam
#echo "           'FREQI','FREQL','CLDLIQ','CLDICE','CLOUD','CLDTOT','TMQ',   ">> user_nl_cam
#echo "           'FLNT','FLNS','FSNT','FSNS','LHFLX','SHFLX','RELHUM','TS',  ">> user_nl_cam
#echo "           'SL','PBLH','PSDRY','PSDRY_gll','PRECSC','PRECSL',          ">> user_nl_cam
#echo "		 'PTTEND','EFIX'					     ">> user_nl_cam
echo "fincl3 =   'PSDRY','PS','T','Q','Z3','U','V','OMEGA'	             ">> user_nl_cam
echo "fincl4 =   'PRECL','PRECC','Q850','OMEGA850','TMQ','FLNT','FREQZM'     ">> user_nl_cam
echo "fincl5 =   'PSDRY','PS','T','Q','Z3','U','V','OMEGA'                   ">> user_nl_cam
#echo "fincl5 =   'ZMDT','MPDT','STEND_CLUBB','PTTEND','FT','CMFMCDZM'	     ">> user_nl_cam	
#echo "avgflag_pertape(1) = 'A'"                                               >> user_nl_cam
#echo "avgflag_pertape(2) = 'A'"                                               >> user_nl_cam
echo "avgflag_pertape(3) = 'I'"                                               >> user_nl_cam
echo "avgflag_pertape(4) = 'I'"                                               >> user_nl_cam
echo "avgflag_pertape(5) = 'I'"                                               >> user_nl_cam
echo "nhtfrq             = 0,0,-6,-6,-6"                                      >> user_nl_cam
echo "mfilt              = 1,1,120,120,120"                                   >> user_nl_cam
echo "ndens              = 2,2,2,2,2"                                         >> user_nl_cam
#echo "interpolate_output = .true.,.false.,.false.,.false.,.false."            >> user_nl_cam
echo "interpolate_output = .true.,.false.,.false.,.false.,.true."             >> user_nl_cam

#-------integrate clubb over entire time-step prior to MG2 call-------
#--------(blow-up runs tend to occur earlier w/ this set to 1)-------
#echo "cld_macmic_num_steps = 1">> user_nl_cam

#-------allow for unsupported clubb timestep----
cp /glade/u/home/$USER/src/$src/components/cam/usr_src/clubb/clubb_intr.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

./case.setup
qcmd -- ./case.build
./case.submit
