#!/bin/tcsh
setenv proj "P05010048" #"P03010039"
setenv src "camtrunk_190510" #"camtrunk_180305" #"physgrid_180606" #"cesm2_0_alpha10f"
setenv res "ne30pg2_ne30pg2_mg17"
setenv comp "FHS94"
setenv wall "06:00:00"
setenv pes "1800" # note that pes=192 crashes on hobart
setenv caze ${src}_${comp}topo_${res}_pe${pes}_`date '+%y%m%d'`_nu2E14_nup2E15_1200days

# Hobart - 48 proc/node, 32 nodes
/gpfs/u/home/$USER/$src/cime/scripts/create_newcase --case /glade/scratch/$USER/$caze --compset $comp --res $res --walltime $wall --mach cheyenne --compiler intel --queue regular --pecount $pes --run-unsupported
cd /glade/scratch/$USER/$caze

./xmlchange STOP_OPTION=ndays,STOP_N=1200
./xmlchange DOUT_S=FALSE
./xmlchange NTHRDS=1
./xmlchange CAM_CONFIG_OPTS="-phys held_suarez"

./xmlchange ATM_NCPL=48
echo "se_nu              =   0.2e15  ">> user_nl_cam
echo "se_nu_div          =   2.0e15  ">> user_nl_cam
echo "se_nu_p            =   2.0e15  ">> user_nl_cam
echo "use_topo_file      =  .true.   ">>user_nl_cam

echo "se_hypervis_subcycle = 5">> user_nl_cam

#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30np4_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw064_20170510.nc'">> user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30np4_nc3000_Co060_Fi001_PF_nullRR_Nsw042_20171020.nc'" >>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg3_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw065_20180204.nc'" >>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg3_nc3000_Co060_Fi001_PF_nullRR_Nsw042_20171014.nc'" >>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co060_Fi001_PF_nullRR_Nsw042_20171014.nc'">>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw065_20180606.nc'">>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co138_Fi001_MulG_PF_nullRR_NoAniso_20180608.nc'">>user_nl_cam
#echo "bnd_topo = '/gpfs/fs1/work/aherring/cesm_inputfiles/topo/ne30pg3_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw065_20180204.nc'" >>user_nl_cam

echo "bnd_topo = '/gpfs/fs1/work/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw065_20180606.nc'" >>user_nl_cam

#echo "bnd_topo = '/gpfs/fs1/work/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co138_Fi001_MulG_PF_nullRR_NoAniso_20180608.nc'" >>user_nl_cam

#echo "bnd_topo = '/gpfs/fs1/work/aherring/cesm_inputfiles/topo/ne30np4_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw064_20170510.nc'" >>user_nl_cam

#echo "ncdata = '/fs/cgd/csm/inputdata/atm/cam/inic/se/ape_topo_cam4_ne30np4_L30_c171020.nc'" >>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_topo_cam4_ne30np4_L30_c171020.nc'" >>user_nl_cam
#echo "ncdata = '/fs/cgd/csm/inputdata/atm/cam/inic/se/ape_topo_cam4_ne60np4_L30_c171020.nc'" >>user_nl_cam
#echo "ncdata = '/fs/cgd/csm/inputdata/atm/cam/inic/fv/cami-mam3_0000-01-01_0.9x1.25_L30_c100618.nc'" >>user_nl_cam

echo "ncdata = '/gpfs/fs1/work/aherring/cesm_inputfiles/ncdata/camtrunk_190509_FHS94topo_ne30pg3_ne30pg3_mg17_pe192_190509_1200days_10Xnudiv.cam.i.0004-04-01-00000.nc'" >>user_nl_cam

#echo "ncdata = '/gpfs/fs1/scratch/aherring/camtrunk_190510_FHS94topo_ne30pg3_ne30pg3_mg17_pe1800_190511_nu2E14_nup2E15_1200days/run/camtrunk_190510_FHS94topo_ne30pg3_ne30pg3_mg17_pe1800_190511_nu2E14_nup2E15_1200days.cam.i.0003-06-01-00000.nc'" >>user_nl_cam

#echo "ncdata = '/gpfs/fs1/scratch/aherring/camtrunk_190510_FHS94topo_ne30pg2_ne30pg2_mg17_pe1800_190511_nu2E14_nup2E15_nudiv1E16_1200days/run/camtrunk_190510_FHS94topo_ne30pg2_ne30pg2_mg17_pe1800_190511_nu2E14_nup2E15_nudiv1E16_1200days.cam.i.0003-04-01-00000.nc'" >>user_nl_cam

# grids still need to be hacked
#./xmlchange --append CAM_CONFIG_OPTS="-hgrid ne20np4.pg3"
#./xmlchange ATM_DOMAIN_FILE="domain.lnd.ne20np4.pg3_gx1v7.180605.nc"
#./xmlchange OCN_DOMAIN_FILE="domain.ocn.ne20np4.pg3_gx1v7.180605.nc"
#./xmlchange ICE_DOMAIN_FILE="domain.ocn.ne20np4.pg3_gx1v7.180605.nc"
#echo "ncdata = '/home/aherring/cesm_inputfiles/ncdata/physgrid_180606_FHS94topo_ne20pg3_ne20pg3_mg17_pe192_180607_test.cam.i.0001-01-07-00000.nc'" >>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne20pg3_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw065_20180606.nc'">>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne20pg3_nc3000_Co138_Fi001_MulG_PF_nullRR_NoAniso_20180608.nc'">>user_nl_cam
#echo "se_nu              =   0.6e15  ">> user_nl_cam
#echo "se_nu_div          =   7.6e15  ">> user_nl_cam
#echo "se_nu_p            =   3.8e15  ">> user_nl_cam

##history
echo "inithist          = 'MONTHLY'                                                 ">> user_nl_cam
echo "se_statefreq      = 144                                                    ">> user_nl_cam
echo "se_statediag_numtrac = 99							 ">> user_nl_cam
echo "empty_htapes      = .true.                                                 ">> user_nl_cam
echo "fincl1            = 'PS','T','Z3','U','V','OMEGA','OMEGA_gll','PHIS' ">> user_nl_cam
echo "fincl2            = 'PS','T','Z3','U','V','OMEGA','OMEGA_gll','PHIS' ">> user_nl_cam
echo "fincl3            = 'PS','T','Z3','U','V','OMEGA','OMEGA_gll','PHIS' ">> user_nl_cam
echo "avgflag_pertape(1) = 'A'"                                                   >> user_nl_cam
echo "avgflag_pertape(2) = 'A'"                                                   >> user_nl_cam
echo "avgflag_pertape(3) = 'I'"                                                   >> user_nl_cam
echo "nhtfrq             = 0,0,-6                                                ">> user_nl_cam
echo "mfilt              = 1,1,120                                         	 ">> user_nl_cam
## 0 = use GLL bassis, 1 = bi-linear
echo "interpolate_type = 1                                                       ">> user_nl_cam
echo "interpolate_output = .true.,.false.,.false."	                          >> user_nl_cam

#omega_gll
cp /gpfs/u/home/aherring/$src/components/cam/usr_src/omega_gll/stepon.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

#ifdefs
#cp /glade/u/home/aherring/$src/components/cam/usr_src/ifdefs/fvm_mapping.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

./case.setup
qcmd -- ./case.build
#./case.build # --skip-provenance-check
./case.submit

