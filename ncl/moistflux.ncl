;**************************************
;compute figure 8 of O'Brien et al 2016
;save to netcdf file
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/p/work/aherring/se_func_lib.ncl"
;**************************************
begin
;****************************************
;****************************************
  Re = 6.37122e3 ;km
  secpday = 60.*60.*24
  pi = 3.14159265358979
  L = 2*pi*Re ;equatorial circumfrence
  g = 9.80616 ;m/s2
  p0   = 100000.
  rhow = 1000. ;;;<--from shr_const_mod.F90 in cime/src/share/utils/

  rdir = "/run/"
  fname = fname0
  fdate = ".cam."+fincl0+"*"
  nfiles = dimsizes(fname)

  onemnth = True

  writenetcdf = True
  nbins = 300
  bin_min  = 0.
  bin_max  = 300.

  factor = secpday*1000. ;;;<--m/s to mm/day

  fname_out = fname(0) + ".moistflux.nc"
  varnams = (/"bin_centers","medians","upperQ","lowerQ","nnorm","globav","globavup","pdfprect","pdfmflux"/)

  dopdfs = True
  optpdf = True
;******************************************************
; begin code
;******************************************************

do n = 0,nfiles-1

print("Begin case "+n)

  files = systemfunc ("ls " + dir + fname(n) + rdir(n) + fname(n) + fdate)
  nhist = dimsizes(files)

  if (onemnth) then
   nstart = 0
   nfinish = 0
  else
   nstart = 0
   nfinish = nhist-1
  end if
  print("Loading Files(s)...")
  print(files(nstart:nfinish))
  f  = addfiles (files(nstart:nfinish),"r")
  ListSetType(f,"cat")
  delete(files)

  if (isfilevardim(f[0],"PRECC","lat")) then
    print("*history fields must be on native se-grid*")
    print("exiting")
    exit
  end if

  tmp1 = f[:]->OMEGA850

    print("computing mean state...")
    area = f[0]->area
    lat1d = f[0]->lat
    lat2d = conform(tmp1,lat1d,1)

    omg = tmp1
    omg@_FillValue = default_fillvalue("float")
    omg = where(lat2d.gt.-10.0 .and. lat2d.lt.10.0,omg,omg@_FillValue)
    bart = dim_avg_0_lowmem(omg,2)
    globav = dim_sum(area*bart)/dim_sum(area*bart/bart)
    globav = globav*secpday/100.
    print("	mean OMG850 +/- 10 degress lat " + globav + " hPa/day")
    delete([/omg,bart/])

    omgup = tmp1
    omgup@_FillValue = default_fillvalue("float")
    omgup = where(tmp1.lt.0. .and. lat2d.gt.-10.0 .and. lat2d.lt.10.0,omgup,omgup@_FillValue)
    bart = dim_avg_0_lowmem(omgup,2)
    globavup = dim_sum(area*bart)/dim_sum(area*bart/bart)
    globavup = globavup*secpday/100.
    print("	mean upward OMG850 +/- 10 degress lat " + globavup + " hPa/day")
    delete([/omgup,bart,area,lat1d,lat2d/])

  tmp2 = f[:]->Q850
  mflux = -1.*factor*tmp1*tmp2/(g*rhow)
  delete([/tmp1,tmp2/])
  tmp1 = f[:]->PRECC
  tmp2 = f[:]->PRECL
  prect = (tmp1 + tmp2)*factor
  ;;;prect = tmp1*factor
  delete([/tmp1,tmp2/]) 
  ntime = dimsizes(f[:]->time)
  delete(f)

  opt = True
  opt@PrintStat = True
  statb = stat_dispersion(mflux, opt)
  nvals = statb(19)

print("Starting conditional statistics")

  mflux@_FillValue = default_fillvalue("float")
  prect@_FillValue = default_fillvalue("float")
  mflux = where(mflux.le.0.,mflux@_FillValue,mflux)
  prect = where(prect.le.0.,prect@_FillValue,prect)

  bin_spacing = (bin_max-bin_min)/nbins
  bins = fspan(bin_min,bin_max,nbins)
  bin_centers = bins(0:nbins-2)+bin_spacing/2.
  medians = new( (/nbins-1/),"float")
  upperQ = new( (/nbins-1/),"float")
  lowerQ = new( (/nbins-1/),"float")
  nnorm = new( (/nbins-1/),"float")

 do i = 0,nbins-2
   print("bin "+i+"/"+(nbins-1))
   prectmp = where(mflux.ge.bins(i) .and. mflux.lt.bins(i+1),prect,prect@_FillValue)
   statb = stat_dispersion(prectmp, False)
   medians(i) = statb(8)
   upperQ(i) = statb(10)
   lowerQ(i) = statb(6)
   nnorm(i) = statb(19)/nvals
   delete([/prectmp,statb/])
 end do

 if (dopdfs) then
     print("starting pdfs...")
     optpdf@bin_min  = bin_min
     optpdf@bin_max  = bin_max
     optpdf@bin_spacing = (optpdf@bin_max-optpdf@bin_min)/nbins
     pdfprect = pdfx_lowmem(prect,2,nbins,optpdf)
     pdfmflux = pdfx_lowmem(mflux,2,nbins,optpdf)
 end if

  if (writenetcdf) then
    system("/bin/rm -f "+fname_out(n))
    ncdf = addfile(fname_out(n) , "c")
    ncdf->$varnams(0)$ = bin_centers
    ncdf->$varnams(1)$ = medians
    ncdf->$varnams(2)$ = upperQ
    ncdf->$varnams(3)$ = lowerQ
    ncdf->$varnams(4)$ = nnorm
    ncdf->$varnams(5)$ = globav
    ncdf->$varnams(6)$ = globavup

    if (dopdfs) then
      ncdf->$varnams(7)$ = pdfprect  ;;;<<--these are backwards
      ncdf->$varnams(8)$ = pdfmflux  ;;;<<--keep this bug, will fix in plot routine
    end if
  end if

print("done with case " + n)

end do ;nfiles

end

