;**************************************
;tropD metrics
;translated from Kevin Griese MATLAB scripts
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/p/work/aherring/CESM2/arh-git-scripts/ncl/se_func_lib.ncl"
load "/glade/p/work/aherring/CESM2/arh-git-scripts/ncl/lat_func_lib.ncl"
;**************************************
begin
;****************************************
  secpday = 60.*60.*24;
  pi = 3.14159265358979
  g = 9.80616  ;m/s2
  Re = 6371.22 ;km
  p0 = 1.d5    ;Pa

  rdir  = "/run/"
  fname = fname1
  fdate = ".cam."+fincl1+"*"

  onemnth = False
  nstart = 1

  writencdf = True
  fname_out = fname+".tropD-diags.nc"

  hilat = (/ 90.d,  0.d/)
  lolat = (/  0.d,-90.d/)

  PhiEDJ   = (/"PhiEDJNH","PhiEDJSH"/)
  PhiPSL   = (/"PhiPSLNH","PhiPSLSH"/)
  PhiPSI   = (/"PhiPSINH","PhiPSISH"/)

;************
;main
;************
 
 files = systemfunc ("ls " + dir + fname + rdir + fname + fdate)
 nf = dimsizes(files)
 if (onemnth) then
   nfinish = nstart
 else
   nfinish = nf-1
 end if

 print("loading...")
 print(files(nstart:nfinish))

 f  = addfiles (files(nstart:nfinish),"r")
 ListSetType(f,"cat")
 delete(files)

 if (isfilevardim(f[0],"U","ncol")) then
   print("NETCDF on native grid")
   latlon = False
   dims = getfilevardimsizes(f[0],"U")
   ncol = dims(2)
   wgtpath = get_wgt_path(ncol)
   delete(dims)
 else
   print("NETCDF on lat-lon grid")
   latlon = True
 end if

 print("Grab all vars...")
 u = f[:]->U
 v = f[:]->V
 ps  = f[:]->PS
 hyam= f[0]->hyam
 hybm= f[0]->hybm
 hyai= f[0]->hyai
 hybi= f[0]->hybi
 lat = f[0]->lat
 delete(f)

 print("Compute pressure")
 if (.not.latlon) then
   print("Regridding surface pressure...")
   psll = ESMF_regrid_with_weights(ps,wgtpath,False)
   delete(ps)
   ps = psll
   delete([/psll,lat/])
   lat = ps&lat
 end if
 pm = pres_hybrid_ccm(ps,p0,hyam,hybm)
 dp = dpres_hybrid_ccm(ps,p0,hyai,hybi)

 print("Compute zonal avg...")
 if (latlon) then
   utmp = dim_avg(u)
   vtmp = dim_avg(v)
   delete([/u,v/])
 else
   print("Regridding vars...")
   ull = ESMF_regrid_with_weights(u,wgtpath,False)
   vll = ESMF_regrid_with_weights(v,wgtpath,False)
   utmp = dim_avg(ull)
   vtmp = dim_avg(vll)
   delete([/u,v,ull,vll/])
 end if
 pstmp = dim_avg(ps)
 pmtmp = dim_avg(pm)
 dptmp = dim_avg(dp)
 delete([/ps,pm,dp/])

 print("Compute temporal avg...")
 uzon = dim_avg_0_lowmem(utmp,3)
 vzon = dim_avg_0_lowmem(vtmp,3) 
 pszon = dim_avg_0_lowmem(pstmp,2)
 pmzon = dim_avg_0_lowmem(pmtmp,3)
 dpzon = dim_avg_0_lowmem(dptmp,3)
 delete([/utmp,vtmp,pstmp,pmtmp,dptmp/])

 do n = 0,1
 print("Loading region " + lolat(n) + " to " + hilat(n))

   indx = ind(lat.le.hilat(n) .and. lat.ge.lolat(n))
   latreg = lat(indx)
   ureg = uzon(:,indx)
   vreg = uzon(:,indx)
   psreg = pszon(indx)
   pmreg = pmzon(:,indx)
   dpreg = dpzon(:,indx)

;********************
;  Eddy Driven Jet
;********************
   linlog = 2
   u850 = int2p_n(pmreg,ureg,85000.d,linlog,0)
   if (n.eq.0) then
     lolim = 15.d
     hilim = 60.d
   else
     lolim = -60.d
     hilim = -15.d
   end if
   phiedj = get_maxlat(u850(0,:),latreg,lolim,hilim)

;********************
;  Maximum PSL
;********************
   phipsl = get_maxlat(psreg,latreg,lolim,hilim)

;***********************
;  Psi500 zero crossing
;***********************
   psi = psi_latlon(vreg,dpreg,latreg,1)
   psitmp = int2p_n(pmreg,psi,50000.d,linlog,0)
   psi500 = psitmp(0,:)
   delete([/psi,psitmp/])
   ;
   if (n.eq.0) then
     lolim = 0.d
     hilim = 30.d
     psi500 = -1.*psi500 ;;;flip sign for NH
   else
     lolim = -30.d
     hilim = 0.d
     psi500 = -1.*psi500 ;;;this is confusing me, how does this fix the problem?
   end if
   maxlat = get_maxlat(psi500,latreg,lolim,hilim)
   ;
   if (n.eq.0) then
     lolim = maxlat
     hilim = 60.d
   else
     lolim = -60.d
     hilim = maxlat
   end if
   minlat = get_minlat(psi500,latreg,lolim,hilim)
   ;
   if (n.eq.0) then
     indreg = ind(latreg.gt.maxlat .and. latreg.lt.minlat)
   else
     ;;;flip indices to NH convention
     latreg = latreg(::-1)
     psi500 = psi500(::-1)
     indreg = ind(latreg.gt.minlat .and. latreg.lt.maxlat)
   end if
   phipsi = get_zerocrossing(psi500(indreg),latreg(indreg))

;********************
; Write netcdf
;********************
   if (writencdf) then
     if (n.eq.0) then
       system("/bin/rm -f "+fname_out)
       ncdf = addfile(fname_out,"c")
     end if
     ncdf->$PhiEDJ(n)$ = phiedj
     ncdf->$PhiPSL(n)$ = phipsl
     ncdf->$PhiPSI(n)$ = phipsi
   end if

  print("  ")
  print("Stats for region " + lolat(n) + " to " + hilat(n))
  print("------------------------------------------------------------------------")
  print("  Phi-EDJ          " + phiedj + " (degrees)")
  print("  Phi-PSL          " + phipsl + " (degrees)")
  print("  Phi-PSI          " + phipsi + " (degrees)")
  print("  ")
  delete([/u850,dpreg,pmreg,psreg,ureg,vreg,latreg,indx,indreg,psi500/])

end do 

end



