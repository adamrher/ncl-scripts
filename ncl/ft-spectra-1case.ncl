;**************************************
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/p/work/aherring/CESM2/arh-git-scripts/ncl/se_func_lib.ncl"
;**************************************
begin
;****************************************
;****************************************
wcStrt     = systemfunc("date")

  Re = 6.37122e3 ;km
  secpday = 60.*60.*24
  pi = 3.14159265358979
  g = 9.80616 ;m/s2
  p0   = 100000.d

  rdir = (/"/run/"/)
  fname = (/fname1/)
  fdate = (/".cam."+fincl1+"*"/)
  label = fname
  nfiles = dimsizes(fname)

  onemnth = True
  nstart = 0

  VAR = "PTTEND"
  factor = 1.

  plotnlat = 165
  klev = 18  ;;;19-1:379hPa 23-1:691hPa

  writencdf = True
  loadncdf = False
  fname_out = fname(0)+".spectra-ft.nc"
  fname_in  = fname_out
  varnams1 = (/"specbar1","specbar2"/)
  varnams2 = (/"xbar1","xbar2"/)

  xaxis = "Spherical Wavenumber"
  yaxis = "PTTEND (physgrid) spectral density (K~S~2~N~/s~S~2~N~), level " + (klev+1)

  pltNam = "temp_spectra"
  colors = (/"darkorchid4","magenta"/)

;******************************************************
; plot options
;******************************************************
;---Start the graphics
  wks = gsn_open_wks("pdf",pltNam)

  res                      = True         ; plot modifications desired
  res@gsnDraw              = False        ; don't draw plot
  res@gsnFrame             = False        ; don't advance frame
  ;res@gsnMaximize = True
  ;res@gsnPaperOrientation = "portrait"
  ;res@vpWidthF = 0.7
  ;res@vpHeightF = 0.35
  res@xyYStyle ="Log"
  res@xyXStyle ="Log"

  res@tmBorderThicknessF = 3 ;axes thickness
  res@tmXBMajorOutwardLengthF = 0.
  res@tmYLMajorOutwardLengthF = 0.
  res@tmXBMinorOutwardLengthF = 0.
  res@tmYLMinorOutwardLengthF = 0.
  res@tmXTMajorOutwardLengthF = 0.
  res@tmYRMajorOutwardLengthF = 0.
  res@tmXTMinorOutwardLengthF = 0.
  res@tmYRMinorOutwardLengthF = 0.

  res@pmLegendDisplayMode    = "NoCreate"                      ; turn on legend
  res@pmLegendSide           = "Bottom"                      ; Change location of
  res@pmLegendParallelPosF   = .7                           ; move units right
  res@pmLegendOrthogonalPosF = -1.15                          ; move units down
  res@pmLegendWidthF         = 0.14                          ; Change width and
  res@pmLegendHeightF        = 0.11                           ; height of legend.
  res@lgPerimOn              = False                         ; turn off box around
  res@lgLabelFontHeightF     = .02                          ; label font height

  res@xyMonoLineThickness = True
  res@xyLineThicknessF   = 3

  res@trYMinF     = 1.e-13
  res@trYMaxF     = 6.e-10
  res@trXMinF                = 1
  res@trXMaxF                = 200;;;plotnlat

  ;;add legend
  txres = True
  txres@txFontHeightF = 0.020
  txres@txJust = "CenterLeft"

  plres  = True                  ; polyline mods desired
  plres@gsLineDashPattern  = 0                    ; solid line
  plres@gsLineThicknessF  = 5.                   ; line thicker

  yy = (/ 0.90,0.87 /)
  xx = (/ 0.20,0.24 /)

do n = 0,nfiles-1

wcStrtVar = systemfunc("date")

print("Begin case "+n)

if (.not.loadncdf) then

  files = systemfunc ("ls " + dir + fname(n) + rdir(n) + fname(n) + fdate(n))
  nhist = dimsizes(files)

  if (onemnth) then
   nfinish = nstart
  else
   nfinish = nhist-1
  end if
  print("Loading Files(s)...")
  print(files(nstart:nfinish))
  f  = addfiles (files(nstart:nfinish),"r")
  ListSetType(f,"cat")
  delete(files)

  if (isfilevardim(f[0],"PTTEND","lon")) then
    print("*history fields must be on native se-grid*")
    print("exiting...")
    exit
  else
    dims = getfilevardimsizes(f[0],"PTTEND")
    ncol = dims(2)
    delete(dims)

    dims = getfilevardimsizes(f[0],"FT")
    ncol_d = dims(2)
    delete(dims)

    wgtpath = get_wgt_path(ncol,ncol_d,0)
    print("wgt path " + wgtpath)
  end if

  var = f[:]->$VAR$
  var = var*factor

  ntime = dimsizes(f[:]->time)
  delete(f)

  wcStrtPdf = systemfunc("date")
  wallClockElapseTime(wcStrtVar, "Loading Vars", 0)

  print("Starting spectra")

  ;;;create arrays
  tmp = ESMF_regrid_with_weights(var(0,:,:),wgtpath,False)
  nlat = dimsizes(tmp&lat)
  delete(tmp)

  spectra = new ( (/ntime,nlat/), "double", 1d-99 )
  xbar    = new ( (/nlat/), "double", 1d-99 )

  do m=1,nlat-1
     xbar(m) = m
  end do

  do t=0,ntime-1

    print("t = " + t + "/" + (ntime-1) )
    var_regrid = ESMF_regrid_with_weights(var(t,:,:),wgtpath,False)

    varlev = var_regrid(klev-1,:,:)
    delete(var_regrid)

    ab_var = shaeC(varlev)
    delete(varlev)

    spectra(t,0:nlat-1) = dim_sum( ab_var(0,:,:)^2 + ab_var(1,:,:)^2 )*0.5
    delete(ab_var)

  end do

  specbar = dim_avg_0_lowmem(spectra,2)

  wallClockElapseTime(wcStrtPdf, "Compute Spectra", 0)

else

   print("Loading vars from " + fname_in)
   if (n.eq.0) then
     ncdf = addfile(fname_in , "r")
   end if
   specbar = ncdf->$varnams1(n)$
   xbar    = ncdf->$varnams2(n)$

end if

   print("Plotting...")
   res@xyLineColors       = colors(n)
   if (n.eq.0) then
     res@tiYAxisString          = yaxis
     res@tiXAxisString          = xaxis
     plot  = gsn_csm_xy(wks,xbar(1:plotnlat),specbar(1:plotnlat),res)
     delete(res@tiYAxisString)
   else 
     tmp = gsn_csm_xy(wks,xbar(1:plotnlat),specbar(1:plotnlat),res)
     overlay(plot,tmp)
     delete(tmp)
   end if

   if (writencdf) then
     if (n.eq.0) then
       system("/bin/rm -f "+fname_out)
       ncdf = addfile(fname_out , "c")
     end if
     ncdf->$varnams1(n)$ = specbar
     ncdf->$varnams2(n)$ = xbar
   end if
   delete([/specbar,xbar/])

   plres@gsLineColor       = colors(n)
   gsn_polyline_ndc(wks,xx,(/yy(n),yy(n)/),plres)   
   gsn_text_ndc(wks,label(n),xx(1),yy(n),txres)

print("done with case " + n)

end do ;nfiles

;;drawNDCGrid(wks)

;*****************************************************
; Panel Plot
;*****************************************************

  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  resP@gsnPaperOrientation = "portrait"
  resP@gsnPanelFigureStringsFontHeightF = 0.02
  resP@gsnPanelFigureStringsPerimOn     = False
  resP@amJust           = "TopRight"
  resP@gsnPanelYWhiteSpacePercent = 5.
  gsn_panel(wks,plot,(/1,1/),resP)               ; now draw as one plot
  frame(wks)

wallClockElapseTime(wcStrt, "Script time", 0)

end

