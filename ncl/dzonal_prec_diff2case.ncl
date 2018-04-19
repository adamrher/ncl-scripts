;**************************************
;zonals.ncl
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/p/work/aherring/se_func_lib.ncl"
;**************************************
begin
;****************************************

  rdir  = (/"/run/","/run/"/)
  fname = (/fname1,fname2/)
  fdate = (/".cam."+fincl1+"*",".cam."+fincl2+"*"/)
  nfiles = dimsizes(fname)

  onemnth = False
  nstart = 1

  writencdf = True
  fname_out = fname(0)+"-2-"+fname(1)+".dzonal.nc"
  VAR   = (/"VAR1","VAR2","DZONAL"/)

  labels = new( (/nfiles+1/), "string")
  labels(0:nfiles-1) = fname
  labels(nfiles) = fname(1) + "~C~  *minus* ~C~" + fname(0)

  secpday = 60.*60.*24;
  pi = 3.14159265358979
  g = 9.80616 ;m/s2
  p0 = 1.e5 ;Pa

  colors = (/"magenta","darkorchid4","blue","green","deepskyblue1"/)

  yaxis = "Precipitation Rate (mm/day)"

;---Start the graphics
  wks = gsn_open_wks("pdf","temp_dzonal")
  plot = new((/2/),graphic)

;---Plotting options for time series plot
  res             = True
  ;res@gsnMaximize = True
  res@gsnPaperOrientation = "landscape"

  res@gsnDraw     = False      ; Will draw later, after overlaying
  res@gsnFrame    = False      ; all plots
  res@xyLineThicknesses = 5
  res@vpWidthF    = 0.8        ; Make plots wider
  res@vpHeightF   = 0.5

  res@tmBorderThicknessF = 4 ;axes thickness
  res@tmXBMajorOutwardLengthF = 0.
  res@tmYLMajorOutwardLengthF = 0.
  res@tmXBMinorOutwardLengthF = 0.
  res@tmYLMinorOutwardLengthF = 0.
  res@tmXTMajorOutwardLengthF = 0.
  res@tmYRMajorOutwardLengthF = 0.
  res@tmXTMinorOutwardLengthF = 0.
  res@tmYRMinorOutwardLengthF = 0.

  res@trXMinF     = -1.
  res@trXMaxF     = 1.
  res@tmXBMode        = "Explicit"
   xticks = new((/19/),float)
   do i = 0,19-1
     tmp = (i-9)*10.
     xticks(i) = sin(tmp*pi/180.)
   end do
  res@tmXBValues      = xticks
  res@tmXBLabels      = (/"","-80","","-60","","-40","","-20","","0","","20","","40","","60","","80",""/)

;****************
;Begin Loop
;****************

do n = 0,nfiles-1
print("Begin case " +n)

  files = systemfunc ("ls /glade/scratch/aherring/"+fname(n) + rdir(n) + fname(n) + fdate(n))
  nhist = dimsizes(files)

  if (onemnth) then
    nfinish = nstart
  else
    nfinish = nhist-1
  end if
  print(files(nstart:nfinish))
  f  = addfiles (files(nstart:nfinish),"r")
  ListSetType(f,"cat")
  delete(files)

  if (isfilevardim(f[0],"PRECC","ncol")) then
    print("*history fields are on native grid")
    latlon = False
    dims = getfilevardimsizes(f[0],"PRECC")
    ncol = dims(1)
    wgtpath = get_wgt_path(ncol)
    delete(dims)
  else
    print("*history fields are on lat-lon grid")
    latlon = True
  end if

  print("grabbing var...")
  var = (f[:]->PRECC) + (f[:]->PRECL)
  lat = f[0]->lat
  ntime = dimsizes(f[:]->time)
  delete(f)

  ;convert mm/day
  var = var*secpday*1000.

  if (.not.latlon) then
    print("regridding...")
    vartmp = var
    delete([/lat,var/])
    var = ESMF_regrid_with_weights(vartmp,wgtpath,False) 
    lat = var&lat
    delete(vartmp)
  end if

  print("zonal avg...")
  ;;; zonal average
  var_zon = dim_avg(var)

  print("variance...")
  ;;; variance
  var_var = dim_variance_n(var_zon,0)
  print("max variance = " + max(var_var))

  print("time average...")
  ;;; time average
  var_bar = dim_avg_n(var_zon,0)
  delete(var_zon)

  res@xyLineColors           = colors(n)

  if (n.eq.0) then
    res@trYMinF     = 0.
    res@trYMaxF     = 18.
    res@tiYAxisString          = yaxis
    plot(0) = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
    delete(res@tiYAxisString)
  else
    dum = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
    overlay(plot(0),dum)
    delete(dum)
  end if

 if (writencdf) then
   if (n.eq.0) then
     system("/bin/rm -f "+fname_out)
     ncdf = addfile(fname_out,"c")
   end if
   
   if (n.eq.nfiles-1) then
     var_bar!0 = "lat1"
   end if
   ncdf->$VAR(n)$ = var_bar
 end if
  ;;;***************************************
  ;;; Compute the difference between 2 cases
  ;;; and test for significance
  ;;;***************************************

  if (n.eq.0) then
    ;;;save a copy
    var_bar0 = var_bar
    var_var0 = var_var
    lat0 = lat
    nlat0 = dimsizes(lat)
  else if (n.eq.1) then
    nlat = dimsizes(lat)
    wgtpath = get_wgt_path_res(nlat0,nlat)
    if (wgtpath.ne."none") then
	    print("regridding to CNTL...")
	    var_bar2d = conform(var(0,:,:),var_bar,0)
            var_var2d = conform(var(0,:,:),var_var,0)
            delete([/var_bar,var_var/])
            var_bartmp = ESMF_regrid_with_weights(var_bar2d,wgtpath,False)
            var_vartmp = ESMF_regrid_with_weights(var_var2d,wgtpath,False)
	    delete([/var_bar2d,var_var2d/])
	    var_bar = var_bartmp(:,0)
	    var_var = var_vartmp(:,0)
            delete([/var_bartmp,var_vartmp/])
    end if    
    dzonal = var_bar - var_bar0

    print("ttest...")
    welsh = False
    P = ttest(var_bar0,var_var0,ntime,var_bar,var_var,ntime,welsh,False)

    res@gsnYRefLine            = 0
    res@gsnYRefLineThicknessF  = 2
    res@trYMinF     = -5.
    res@trYMaxF     = 5.
    res@xyLineColors           = colors(2)
    res@tiYAxisString          = "Anomalous " + yaxis 
    res@tiXAxisString          = "Latitude"
    plot(1) = gsn_csm_xy(wks,sin(lat0*pi/180.),dzonal,res)
  end if
  end if

  if (writencdf .and. n.eq.nfiles-1) then
    dzonal!0 = "lat"
    ncdf->$VAR(nfiles)$ = dzonal
  end if

delete([/var,lat,var_bar,var_var/])

print("done with file " + n)
end do ;nfiles

;--
;Add transparent polygon
;--

 alpha = 0.05
 thick = 0.70
 dzonal@_FillValue = default_fillvalue("float")
 dzonal = where(P.le.alpha,dzonal,dzonal@_FillValue)

 res@xyCurveDrawOrder = "PreDraw"
 res@xyLineColors           = colors(3)
 res@xyLineThicknesses = 20
 topbot = gsn_csm_xy(wks,sin(lat0*pi/180.),dzonal,res)
 overlay(plot(1),topbot)

;*****************************************************
; Manually create and attach legend - plot0
;*****************************************************
  res_text                    = True                  ; text mods desired
  res_text@txFontHeightF      = 0.018                 ; change text size
  res_text@txJust             = "CenterLeft"          ; text justification

  res_lines                   = True                  ; polyline mods desired
  res_lines@gsLineDashPattern = 0                    ; solid line
  res_lines@gsLineThicknessF  = 5.                   ; line thicker

  xx = (/sin(-65.*pi/180.),sin(-50.*pi/180.)/)
  yy = (/16.8,15.8/)
  do n = 0,nfiles-1
    res_lines@gsLineColor       = colors(n)
    lstr = unique_string("num")
    tstr = unique_string("fum")
    plot@$lstr$ = gsn_add_polyline(wks,plot(0),xx,(/yy(n),yy(n)/),res_lines)
    plot@$tstr$ = gsn_add_text(wks,plot(0),labels(n),xx(1),yy(n),res_text)
  end do

  delete(yy)
  yy = (/3.8/)
  res_lines@gsLineColor       = colors(2)
  lstr = unique_string("num")
  tstr = unique_string("fum")
  plot@$lstr$ = gsn_add_polyline(wks,plot(1),xx,(/yy(0),yy(0)/),res_lines)
  plot@$tstr$ = gsn_add_text(wks,plot(1),labels(2),xx(1),yy(0),res_text)

;*****************************************************
; Plot panel
;*****************************************************

  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  ;resP@gsnPaperOrientation = "portrait"
  resP@gsnPanelBottom   = 0.05
  ;resP@gsnPanelFigureStrings = (/ "a","b","c","d" /)
  ;resP@gsnPanelFigureStringsPerimOn     = True
  ;resP@gsnPanelFigureStringsBackgroundFillColor = "white"
  ;resP@amJust           = "TopRight"
  ;resP@txString = pltTitle
  gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot

  frame(wks)

end
