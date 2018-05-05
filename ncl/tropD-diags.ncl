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
  rhow = 1000. ;kg/m3
  L = 2.501e6 ;J/kg

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
  PhiPE    = (/ "PhiPENH", "PhiPESH"/)
  PhiUSF   = (/"PhiUSFNH","PhiUSFSH"/)

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
 u     = f[:]->U
 v     = f[:]->V
 ps    = f[:]->PS
 prect = (f[:]->PRECC) + (f[:]->PRECL)
 prect = rhow*prect
 lhflx = f[:]->LHFLX
 lhflx = lhflx/L
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
   precttmp = dim_avg(prect)
   lhflxtmp = dim_avg(lhflx)
   delete([/u,v,prect,lhflx/])
 else
   print("Regridding vars...")
   ull = ESMF_regrid_with_weights(u,wgtpath,False)
   vll = ESMF_regrid_with_weights(v,wgtpath,False)
   prectll = ESMF_regrid_with_weights(prect,wgtpath,False)
   lhflxll = ESMF_regrid_with_weights(lhflx,wgtpath,False)
   utmp = dim_avg(ull)
   vtmp = dim_avg(vll)
   precttmp = dim_avg(prectll)
   lhflxtmp = dim_avg(lhflxll)
   delete([/u,v,ull,vll,prectll,lhflxll/])
 end if
 pstmp = dim_avg(ps)
 pmtmp = dim_avg(pm)
 dptmp = dim_avg(dp)
 delete([/ps,pm,dp/])

 print("Compute temporal avg...")
 uzon = dim_avg_0_lowmem(utmp,3)
 vzon = dim_avg_0_lowmem(vtmp,3) 
 prectzon = dim_avg_0_lowmem(precttmp,2)
 lhflxzon = dim_avg_0_lowmem(lhflxtmp,2)
 pszon = dim_avg_0_lowmem(pstmp,2)
 pmzon = dim_avg_0_lowmem(pmtmp,3)
 dpzon = dim_avg_0_lowmem(dptmp,3)
 delete([/utmp,vtmp,precttmp,lhflxtmp,pstmp,pmtmp,dptmp/])

 pezon = prectzon-lhflxzon
 delete([/prectzon,lhflxzon/])

 do n = 0,1
 print("Loading region " + lolat(n) + " to " + hilat(n))

   indx = ind(lat.le.hilat(n) .and. lat.ge.lolat(n))
   latreg = lat(indx)
   ureg = uzon(:,indx)
   vreg = uzon(:,indx)
   pereg = pezon(indx)
   psreg = pszon(indx)
   pmreg = pmzon(:,indx)
   dpreg = dpzon(:,indx)

;********************
;  Eddy Driven Jet
;********************
   linlog = 2
   u850tmp = int2p_n(pmreg,ureg,85000.d,linlog,0)
   u850 = u850tmp(0,:)
   delete(u850tmp)
   if (n.eq.0) then
     lolim = 15.d
     hilim = 60.d
   else
     lolim = -60.d
     hilim = -15.d
   end if
   phiedj = get_maxlat(u850,latreg,lolim,hilim)

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
   delete(indreg)

;***********************
;  P-E zero crossing (from neg-to-pos)
;***********************
  if (n.eq.0) then
    indmin = minind(pereg)
    lolim = latreg(indmin)
    hilim = 60.d
  else
    pereg = pereg(::-1)
    indmin = minind(pereg)
    lolim = -60.d
    hilim = latreg(indmin)
  end if
  indreg = ind(latreg.gt.lolim .and. latreg.lt.hilim)
  phipe = get_zerocrossing(pereg(indreg),latreg(indreg))
  delete(indreg)

;***********************
;  U850 zero-crossing (from neg-to-pos)
;***********************
  if (n.eq.0) then
    indmin = minind(u850)
    lolim = latreg(indmin)
    hilim = 60.d
  else
    u850 = u850(::-1)
    indmin = minind(u850)
    lolim = -60.d
    hilim = latreg(indmin)
  end if
  indreg = ind(latreg.gt.lolim .and. latreg.lt.hilim)
  phiusf = get_zerocrossing(u850(indreg),latreg(indreg))

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
     ncdf->$PhiPE(n)$  = phipe
     ncdf->$PhiUSF(n)$ = phiusf
   end if

  print("  ")
  print("Stats for region " + lolat(n) + " to " + hilat(n))
  print("------------------------------------------------------------------------")
  print("  Phi-EDJ          " + phiedj + " (degrees)")
  print("  Phi-PSL          " + phipsl + " (degrees)")
  print("  Phi-PSI          " + phipsi + " (degrees)")
  print("  Phi-PE           " + phipe  + " (degrees)")
  print("  Phi-USF          " + phiusf + " (degrees)")
  print("  ")
  delete([/u850,dpreg,pmreg,psreg,ureg,vreg,pereg,latreg,indx,indreg,psi500/])

end do 

end



