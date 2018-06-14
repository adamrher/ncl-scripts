#!/bin/tcsh
#setenv proj "P93300642"
setenv src "physgrid_180606" #"cesm2_0_alpha10f"
setenv res "ne30pg3_ne30pg3_mg17"
setenv comp "FHS94"
setenv wall "12:00:00"
setenv pes "192" # note that pes=192 crashes on hobart
setenv caze ${src}_${comp}topo_${res}_pe${pes}_`date '+%y%m%d'`_se-nu-default

# Hobart - 48 proc/node, 32 nodes
/home/$USER/src/$src/cime/scripts/create_newcase --case /scratch/cluster/$USER/$caze --compset $comp --res $res --walltime $wall --mach hobart --compiler nag --queue monster --pecount $pes --run-unsupported
cd /scratch/cluster/$USER/$caze

./xmlchange STOP_OPTION=nyears,STOP_N=1
./xmlchange DOUT_S=FALSE
./xmlchange NTHRDS=1
./xmlchange CAM_CONFIG_OPTS="-phys held_suarez"

./xmlchange ATM_NCPL=48
#echo "se_nu              =   0.4e15  ">> user_nl_cam
echo "se_nu_div          =   2.0e15  ">> user_nl_cam
#echo "se_nu_p            =   1.0e15  ">> user_nl_cam
echo "use_topo_file      =  .true.   ">>user_nl_cam

#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30np4_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw064_20170510.nc'">> user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30np4_nc3000_Co060_Fi001_PF_nullRR_Nsw042_20171020.nc'" >>user_nl_cam
echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg3_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw065_20180204.nc'" >>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg3_nc3000_Co060_Fi001_PF_nullRR_Nsw042_20171014.nc'" >>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co060_Fi001_PF_nullRR_Nsw042_20171014.nc'">>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co092_Fi001_MulG_PF_nullRR_Nsw065_20180606.nc'">>user_nl_cam
#echo "bnd_topo = '/home/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co138_Fi001_MulG_PF_nullRR_NoAniso_20180608.nc'">>user_nl_cam
#echo "bnd_topo  = '/glade/p/work/aherring/cesm_inputfiles/topo/ne30pg2_nc3000_Co060_Fi001_PF_nullRR_Nsw042_20171014.nc'">>user_nl_cam
#echo "bnd_topo = '/fs/cgd/csm/inputdata/atm/cam/topo/fv_0.9x1.25_nc3000_Nsw042_Nrs008_Co060_Fi001_ZR_sgh30_24km_GRNL_c170103.nc'" >>user_nl_cam

echo "ncdata = '/fs/cgd/csm/inputdata/atm/cam/inic/se/ape_topo_cam4_ne30np4_L30_c171020.nc'" >>user_nl_cam
#echo "ncdata = '/glade/p/cesmdata/cseg/inputdata/atm/cam/inic/se/ape_topo_cam4_ne30np4_L30_c171020.nc'" >>user_nl_cam
#echo "ncdata = '/fs/cgd/csm/inputdata/atm/cam/inic/se/ape_topo_cam4_ne60np4_L30_c171020.nc'" >>user_nl_cam
#echo "ncdata = '/fs/cgd/csm/inputdata/atm/cam/inic/fv/cami-mam3_0000-01-01_0.9x1.25_L30_c100618.nc'" >>user_nl_cam

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
echo "inithist          = 'NONE'                                                 ">> user_nl_cam
echo "se_statefreq      = 144                                                    ">> user_nl_cam
echo "se_statediag_numtrac = 99							 ">> user_nl_cam
echo "empty_htapes      = .true.                                                 ">> user_nl_cam
echo "fincl1            = 'PS','PSDRY_fvm','PSDRY_gll','T','Z3','U','V','OMEGA','OMEGA_gll','PHIS' ">> user_nl_cam
echo "fincl2            = 'PS','PSDRY_fvm','PSDRY_gll','T','Z3','U','V','OMEGA','OMEGA_gll','PHIS' ">> user_nl_cam
echo "fincl3            = 'PS','PSDRY_fvm','PSDRY_gll','T','Z3','U','V','OMEGA','OMEGA_gll','PHIS' ">> user_nl_cam
echo "avgflag_pertape(1) = 'A'"                                                   >> user_nl_cam
echo "avgflag_pertape(2) = 'A'"                                                   >> user_nl_cam
echo "avgflag_pertape(3) = 'I'"                                                   >> user_nl_cam
echo "nhtfrq             = 0,0,-6                                                ">> user_nl_cam
echo "mfilt              = 1,1,120                                         	 ">> user_nl_cam
## 0 = use GLL bassis, 1 = bi-linear
echo "interpolate_type = 1                                                       ">> user_nl_cam
echo "interpolate_output = .true.,.false.,.false."	                          >> user_nl_cam

#omega_gll
#cp /home/aherring/src/$src/components/cam/usr_src/omega_gll/stepon.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/
cp /home/aherring/src/$src/components/cam/usr_src/omega_gll/stepon.F90 /scratch/cluster/$USER/$caze/SourceMods/src.cam/

#ifdefs
#cp /glade/u/home/aherring/$src/components/cam/usr_src/ifdefs/fvm_mapping.F90 /glade/scratch/$USER/$caze/SourceMods/src.cam/

./case.setup
#qcmd -- ./case.build --skip-provenance-check
./case.build # --skip-provenance-check
./case.submit

