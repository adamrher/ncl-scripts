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
  g = 9.80616 ;m/s2
  Re = 6371.22
  p0 = 1.d5

  rdir  = "/run/"
  fname = fname1
  fdate = ".cam."+fincl1+"*"

  onemnth = True 
  nstart = 1

  writencdf = True
  fname_out = fname+".globdiags.nc"

  hilat = (/90.d,10.d/)
  lolat = (/-90.d,-10.d/)

  OMG = (/"OMGgl","OMGtr"/)
  OMGU = (/"OMGUgl","OMGUtr"/)
  OMGD = (/"OMGDgl","OMGDtr"/)
  FRACU = (/"FRACUgl","FRACUtr"/)
  FRACD = (/"FRACDgl","FRACDr"/)

;************
;main
;************
 
 ;load all files
 files = systemfunc ("ls " + dir + fname + rdir + fname + fdate)
 nf = dimsizes(files)
 if (onemnth) then
   nfinish = nstart+1
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

 hyai= f[0]->hyai
 hybi= f[0]->hybi
 lat = f[0]->lat
 lon = f[0]->lon
 ilevs = dimsizes(hyai)

 if (latlon) then
   AREA = f[0]->w
   rank = 3
 else
   AREA = f[0]->area
   rank = 2
 end if

 do n = 0,1
 print("Loading region " + lolat(n) + " to " + hilat(n))
 nrecords = 0
 gomg = 0.d
 gomgu = 0.d
 gomgd = 0.d
 uarea = 0.d
 darea = 0.d

  indx = ind(lat.le.hilat(n) .and. lat.ge.lolat(n))
  do h = 0,(nfinish-nstart)
   print("h = " + h + "/" + nfinish)
   ntime = dimsizes(f[h]->time)  
   do t = 0,ntime-1
     print("  t = " + t + "/" + (ntime-1))
     if (.not.latlon) then
        omg = f[h]->OMEGA(t,:,indx)
        ps = f[h]->PS(t,indx)
        pint = se_pressure(ps,p0,hyai,hybi,1)
        dp = pint(1:ilevs-1,:) - pint(0:ilevs-2,:)
        delete(pint)
     else
        omg = f[h]->OMEGA(t,:,indx,:)
        ps = f[h]->PS(t,indx,:)
        dp = dpres_hybrid_ccm(ps,p0,hyai,hybi)
     end if

     if (h.eq.0 .and. t.eq.0.)
       tmp = AREA(indx)
       wgt = conform(omg,tmp,1)
       delete(tmp)
     end if

     omgu = omg
     omgd = omg
     omgu@_FillValue = default_fillvalue("float")
     omgd@_FillValue = default_fillvalue("float")
     omgu = where(omgu.lt.0.,omgu,omgu@_FillValue)
     omgd = where(omgd.gt.0.,omgd,omgd@_FillValue)
     uvals = omgu/omgu
     dvals = omgd/omgd

     if (latlon) then
       garea = dim_sum(dim_sum(dim_sum(wgt*dp)))
       uareat = dim_sum(dim_sum(dim_sum(uvals*dp*wgt)))
       uareat = uareat/garea   
       dareat = dim_sum(dim_sum(dim_sum(dvals*dp*wgt)))
       dareat = dareat/garea
     else
       garea = dim_sum(dim_sum(wgt*dp))
       uareat = dim_sum(dim_sum(uvals*dp*wgt))
       uareat = uareat/garea
       dareat = dim_sum(dim_sum(dvals*dp*wgt))
       dareat = dareat/garea
     end if

     vomg = dim_sum_n(omg*dp,0)/dim_sum_n(dp,0)
     vomgu = dim_sum_n(omgu*dp,0)/dim_sum_n(uvals*dp,0)
     vomgd = dim_sum_n(omgd*dp,0)/dim_sum_n(dvals*dp,0)

     delete(garea)
     if (latlon) then
       garea = dim_sum(dim_sum(wgt(0,:,:)))
       tomg = dim_sum(dim_sum(wgt(0,:,:)*vomg))
       tomg = tomg/garea
       tomgu = dim_sum(dim_sum(wgt(0,:,:)*vomgu))
       tomgu = tomgu/garea
       tomgd = dim_sum(dim_sum(wgt(0,:,:)*vomgd))
       tomgd = tomgd/garea
     else
       garea = dim_sum(wgt(0,:))
       tomg = dim_sum(wgt(0,:)*vomg)
       tomg = gomg/garea
       tomgu = dim_sum(wgt(0,:)*vomgu)
       tomgu = tomgu/garea
       tomgd = dim_sum(wgt(0,:)*vomgd)
       tomgd = tomgd/garea
     end if

     gomg = gomg + tomg
     gomgu = gomgu + tomgu
     gomgd = gomgd + tomgd
     uarea = uarea + uareat
     darea = darea + dareat
     nrecords = nrecords + 1

  end do;ntime
 end do;nhist

;;;time average here

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

  stag = 1. - darea - uarea
  print("  ")
  print("Stats for region " + lolat(n) + " to " + hilat(n))
  print("------------------------------------------------------------------------")
  print("  Mean omega          " + gomg + " (hPa/day)")
  print("  Mean upward omega   " + gomgu + " (hPa/day)")
  print("  Mean downward omega " + gomgd + " (hPa/day)")
  print("  Space-time fraction of upward motion   " + uarea)
  print("  Space-time fraction of downward motion " + darea)
  print("  Space-time fraction of stagnant motion " + stag)
dum = (uarea*gomgu) + (darea*gomgd)
  print("  Check on globav " + dum)
  print("  ")
  delete([/omg,omgu,omgd,vomg,vomgu,vomgd,omg,omgu,omgd,uvals,dvals,ps,dp,wgt,indx/])

end do 
delete(f)
end



