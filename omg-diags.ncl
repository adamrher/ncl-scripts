;**************************************
;eof_cam.ncl
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/glade/p/work/aherring/se_func_lib.ncl"
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
  fname_out = fname+".omg-diags.nc"

  hilat = (/ 10.d, 90.d/)
  lolat = (/-10.d,-90.d/)

  OMG   = (/  "OMGtr",  "OMGgl"/)
  OMGU  = (/ "OMGUtr", "OMGUgl"/)
  OMGD  = (/ "OMGDtr", "OMGDgl"/)
  FRACU = (/"FRACUtr","FRACUgl"/)
  FRACD = (/"FRACDtr","FRACDgl"/)

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

 if (isfilevardim(f[0],"OMEGA","ncol")) then
   print("NETCDF on native grid")
   latlon = False
 else
   print("NETCDF on lat-lon grid")
   latlon = True
 end if

 print("Grab all vars...")
 VAR = f[:]->OMEGA
 VAR = VAR*secpday/100.
 PS  = f[:]->PS
 hyai= f[0]->hyai
 hybi= f[0]->hybi
 ilevs = dimsizes(hyai)
 lat = f[0]->lat

 if (latlon) then
   AREA = f[0]->w
 else
   AREA = f[0]->area
 end if
 delete(f)

 do n = 0,1
 print("Loading region " + lolat(n) + " to " + hilat(n))

   indx = ind(lat.le.hilat(n) .and. lat.ge.lolat(n))
   if (.not.latlon) then
      omg = VAR(:,:,indx)
      ps = PS(:,indx)

      print("  Computing pressure field...")
      pint = se_pressure(ps,p0,hyai,hybi,0)
      dp = pint(:,1:ilevs-1,:) - pint(:,0:ilevs-2,:)
      delete(pint)

   else
      omg = VAR(:,:,indx,:)
      ps = PS(:,indx,:)

      print("  Computing pressure field...")
      dp = dpres_hybrid_ccm(ps,p0,hyai,hybi)

   end if
   tmp = AREA(indx)
   wgt = conform(omg,tmp,2)
   delete(tmp)

   print("  Masking vars...")

   omgu = omg
   omgd = omg
   omgu@_FillValue = default_fillvalue("float")
   omgd@_FillValue = default_fillvalue("float")
   omgu = where(omgu.lt.0.,omgu,omgu@_FillValue)
   omgd = where(omgd.ge.0.,omgd,omgd@_FillValue)
   uvals = omgu/omgu
   dvals = omgd/omgd

   print("  Computing space-time wgts...")

   if (latlon) then
     garea = dim_sum(dim_sum(dim_sum(dim_sum(wgt*dp))))
     uarea = dim_sum(dim_sum(dim_sum(dim_sum(uvals*dp*wgt))))
     darea = dim_sum(dim_sum(dim_sum(dim_sum(dvals*dp*wgt))))
   else
     garea = dim_sum(dim_sum(dim_sum(wgt*dp)))
     uarea = dim_sum(dim_sum(dim_sum(uvals*dp*wgt)))
     darea = dim_sum(dim_sum(dim_sum(dvals*dp*wgt)))
   end if

   print("  Computing space-time means...")

   if (latlon) then
     gomg  = dim_sum(dim_sum(dim_sum(dim_sum(omg*dp*wgt))))
     gomg  = gomg/garea
     gomgu = dim_sum(dim_sum(dim_sum(dim_sum(omgu*dp*wgt))))
     gomgu = gomgu/uarea
     gomgd = dim_sum(dim_sum(dim_sum(dim_sum(omgd*dp*wgt))))
     gomgd = gomgd/darea
   else
     gomg  = dim_sum(dim_sum(dim_sum(omg*dp*wgt)))
     gomg  = gomg/garea
     gomgu = dim_sum(dim_sum(dim_sum(omgu*dp*wgt)))
     gomgu = gomgu/uarea
     gomgd = dim_sum(dim_sum(dim_sum(omgd*dp*wgt)))
     gomgd = gomgd/darea
   end if
   uarea = uarea/garea
   darea = darea/garea

   if (writencdf) then
     if (n.eq.0) then
       system("/bin/rm -f "+fname_out)
       ncdf = addfile(fname_out,"c")
     end if
     ncdf->$OMG(n)$ = gomg
     ncdf->$OMGU(n)$ = gomgu
     ncdf->$OMGD(n)$ = gomgd
     ncdf->$FRACU(n)$ = uarea
     ncdf->$FRACD(n)$ = darea
   end if

  dum = (uarea*gomgu) + (darea*gomgd)

  print("  ")
  print("Stats for region " + lolat(n) + " to " + hilat(n))
  print("------------------------------------------------------------------------")
  print("  Mean omega          " + gomg + " (hPa/day)")
  print("  Mean upward omega   " + gomgu + " (hPa/day)")
  print("  Mean downward omega " + gomgd + " (hPa/day)")
  print("  Space-time fraction of upward motion   " + uarea)
  print("  Space-time fraction of downward motion " + darea)
  print("  Check globav " + dum + " (hPa/day)")
  print("  ")
  delete([/omg,omgu,omgd,uvals,dvals,ps,dp,wgt,indx/])

end do 

end



