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
  fname_out = fname+".all-diags.nc"

  hilat = (/ 10.d, 90.d/)
  lolat = (/-10.d,-90.d/)

  gPRECC = (/ "PRECCtr", "PRECCgl"/)
  gPRECL = (/ "PRECLtr", "PRECLgl"/)
  gFREQZM= (/"FREQZMtr","FREQZMgl"/)
  gPBLH  = (/  "PBLHtr",  "PBLHgl"/)
  gTMQ   = (/  "TMQtr",   "TMQHgl"/)
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
 PRECC = f[:]->PRECC
 PRECC = PRECC*secpday*1000.
 PRECL = f[:]->PRECL
 PRECL = PRECL*secpday*1000.
 ;;;FREQZM = f[:]->FREQZM
 PBLH  = f[:]->PBLH
 TMQ   = f[:]->TMQ
 lat   = f[0]->lat

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
      precc = PRECC(:,indx)
      precl = PRECL(:,indx)
      pblh  = PBLH(:,indx)
      tmq   = TMQ(:,indx)
   else
      precc = PRECC(:,indx,:)
      precl = PRECL(:,indx,:)
      pblh  = PBLH(:,indx,:)
      tmq   = TMQ(:,indx,:)
   end if
   tmp = AREA(indx)
   wgt = conform(precc,tmp,1)
   delete(tmp)

   print("  Computing space-time wgts...")

   if (latlon) then
     garea = dim_sum(dim_sum(dim_sum(wgt)))
   else
     garea = dim_sum(dim_sum(wgt))
   end if

   print("  Computing space-time means...")

   if (latlon) then
     gprecc  = dim_sum(dim_sum(dim_sum(precc*wgt)))
     gprecc  = gprecc/garea
     gprecl  = dim_sum(dim_sum(dim_sum(precl*wgt)))
     gprecl  = gprecl/garea
     gpblh  = dim_sum(dim_sum(dim_sum(pblh*wgt)))
     gpblh  = gpblh/garea
     gtmq  = dim_sum(dim_sum(dim_sum(tmq*wgt)))
     gtmq  = gtmq/garea
   else
     gprecc  = dim_sum(dim_sum(precc*wgt))
     gprecc  = gprecc/garea
     gprecl  = dim_sum(dim_sum(precl*wgt))
     gprecl  = gprecl/garea
     gpblh  = dim_sum(dim_sum(pblh*wgt))
     gpblh  = gpblh/garea
     gtmq  = dim_sum(dim_sum(tmq*wgt))
     gtmq  = gtmq/garea
   end if

   if (writencdf) then
     if (n.eq.0) then
       system("/bin/rm -f "+fname_out)
       ncdf = addfile(fname_out,"c")
     end if
     ncdf->$gPRECC(n)$  = gprecc
     ncdf->$gPRECL(n)$  = gprecl
     ;;;ncdf->$gFREQZM(n)$ = gfrqzm
     ncdf->$gPBLH(n)$   = gpblh
     ncdf->$gTMQ(n)$    = gtmq
   end if

  gprect = gprecc + gprecl
  print("  ")
  print("Stats for region " + lolat(n) + " to " + hilat(n))
  print("------------------------------------------------------------------------")
  print("  Mean PRECC          " + gprecc + " (mm/day)")
  print("  Mean PRECL          " + gprecl + " (mm/day)")
  print("  Mean PRECT          " + gprect + " (mm/day)")
  print("  PRECL/PRECC         " + gprecl/gprecc + " (fraction)")
  ;;;print("  Mean FREQZM         " + gfrqzm + " (fraction)")
  print("  Mean PBLH	       " + gpblh  + " (m)")
  print("  Mean TMQ            " + gtmq  + " (mm water)")
  print("  ")
  delete([/precc,precl,pblh,tmq,wgt,indx/])

end do 

end



