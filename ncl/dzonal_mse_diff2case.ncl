;**************************************
;zonals.ncl
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/p/work/aherring/CESM2/arh-git-scripts/ncl/se_func_lib.ncl"
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
  fname_out = fname(0)+"-2-"+fname(1)+".dmse.nc"
  VAR   = (/"VAR1","VAR2","DZONAL"/)

  labels = new( (/nfiles+1/), "string")
  labels(0:nfiles-1) = fname
  labels(nfiles) = fname(1) + "~C~  *minus* ~C~" + fname(0)

  secpday = 60.*60.*24;
  pi = 3.14159265358979
  p0 = 1.d5 ;Pa
  ; from: "src/cime/src/share/util/shr_const_mod.F90"
  Li = 3.337e5
  Lv = 2.501e6
  cpd= 1.00464e3
  g  = 9.80616

  colors = (/"magenta","darkorchid4","blue","green","deepskyblue1"/)

  yaxis = "Column Frozen MSE (J/m2)"

;---Start the graphics
  wks = gsn_open_wks("pdf","temp_dmse")
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

  files = systemfunc ("ls " + dir + fname(n) + rdir(n) + fname(n) + fdate(n))
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

  if (isfilevardim(f[0],"SE_pAP","ncol")) then
    print("*history fields are on native grid")
    latlon = False
    dims = getfilevardimsizes(f[0],"SE_pAP")
    ncol = dims(1)
    wgtpath = get_wgt_path(ncol)
    delete(dims)
  else
    print("*history fields are on lat-lon grid")
    latlon = True
  end if

  print("grabbing var...")
  V   = f[:]->V
  PS  = f[:]->PS

  T   = f[:]->T
  Z   = f[:]->Z3
  Q   = f[:]->Q
  ;CLDICE = f[:]->CLDICE

  hyam= f[0]->hyam
  hybm= f[0]->hybm
  hyai= f[0]->hyai
  hybi= f[0]->hybi

  lat = f[0]->lat
  ntime = dimsizes(f[:]->time)
  delete(f)

  MSE = cpd*T + g*Z + Lv*Q
  delete([/T,Z,Q/])

  if (.not.latlon) then
    print("regridding...")
    msetmp = MSE
    vtmp   = V
    pstmp  = PS
    delete([/lat,MSE,V,PS/])
    MSE = ESMF_regrid_with_weights(msetmp,wgtpath,False) 
    lat = MSE&lat
    V   = ESMF_regrid_with_weights(vtmp,wgtpath,False)
    PS  = ESMF_regrid_with_weights(pstmp,wgtpath,False)
    delete([/msetmp,vtmp,pstmp/])
  end if

  print("zonal avg...")
  ;;; zonal average
  mse_zon = dim_avg(MSE)
  v_zon   = dim_avg(V)
  ps_zon  = dim_avg(PS)
  delete([/MSE,V,PS/])

  print("time average...")
  ;;; time average
  mse_bar = dim_avg_n(mse_zon,0)
  v_bar   = dim_avg_n(v_zon,0)
  ps_bar  = todouble(dim_avg_n(ps_zon,0))
  delete([/mse_zon,v_zon,ps_zon/])

  print("interpolate to fixed pressure grid")
  if (n.eq.0) then
   lev_p = (hyam + hybm)*p0
   lev_p!0         = "lev_p"                  ; variable/dim name
   lev_p&lev_p     =  lev_p                   ; create coordinate variable
   lev_p@long_name = "Pressure (hPa)"               ; attach some attributes
   lev_p@units     = "Pa"
   lev_p@positive  = "down"
   nlevs 	   = dimsizes(hyam)
   linlog	   = 2

   lev_i 	   = (hyai+hybi)*p0
   dp		   = lev_i(1:nlevs) - lev_i(0:nlevs-1)
   delete(lev_i)
  end if
  ;;compute pressure
  ps2d	   = conform(mse_bar,ps_bar,1)
  hyam2d   = conform(mse_bar,hyam,0)
  hybm2d   = conform(mse_bar,hybm,0)
  p02d     = ps2d
  p02d(:,:)= p0
  pm	   = p02d*hyam2d + ps2d*hybm2d
  delete([/ps2d,p02d,hyam2d,hybm2d/])

  mse_lev = int2p_n(pm,mse_bar,lev_p,linlog,0)
  v_lev	  = int2p_n(pm,v_bar,lev_p,linlog,0)
  delete([/mse_bar,v_bar,ps_bar,pm/])

  print("computing mse transport")
  nlat = dimsizes(lat)
  var_bar = new((/nlat/),double)
  do j = 0,nlat-1
        dum = 0.d
        do m = 0,nlevs-1
        	dum = v_lev(m,j)*mse_lev(m,j)*dp(m) + dum
        end do
        var_bar(j) = dum/g
  end do

  kmid = 20 ;;20 (500 hPa) or 21 (600 hPa)
  low_bar = new((/nlat/),double)
;  do j = 0,nlat-1
;        dum = 0.d
;        do m = kmid-1,nlevs-1
;                dum = v_lev(m,j)*dp(m) + dum
;        end do
;        low_bar(j) = dum
;  end do
;  var_bar = var_bar/low_bar
  delete([/mse_lev,v_lev,low_bar/])


  res@xyLineColors           = colors(n)
  if (n.eq.0) then
    ;;res@trYMinF     = 0.
    ;;res@trYMaxF     = 18.
    res@tiYAxisString          = yaxis
    plot(0) = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
    delete(res@tiYAxisString)
  else
    yum = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
    overlay(plot(0),yum)
    delete(yum)
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
;  ;;;***************************************
;  ;;; Compute the difference between 2 cases
;  ;;; and test for significance
;  ;;;***************************************
;
;  if (n.eq.0) then
;    ;;;save a copy
;    var_bar0 = var_bar
;    var_var0 = var_var
;    lat0 = lat
;    nlat0 = dimsizes(lat)
;  else if (n.eq.1) then
;    nlat = dimsizes(lat)
;    wgtpath = get_wgt_path_res(nlat0,nlat)
;    if (wgtpath.ne."none") then
;	    print("regridding to CNTL...")
;	    var_bar2d = conform(MSE(0,:,:),var_bar,0)
;            var_var2d = conform(MSE(0,:,:),var_var,0)
;            delete([/var_bar,var_var/])
;            var_bartmp = ESMF_regrid_with_weights(var_bar2d,wgtpath,False)
;            var_vartmp = ESMF_regrid_with_weights(var_var2d,wgtpath,False)
;	    delete([/var_bar2d,var_var2d/])
;	    var_bar = var_bartmp(:,0)
;	    var_var = var_vartmp(:,0)
;            delete([/var_bartmp,var_vartmp/])
;    end if    
;    dzonal = var_bar - var_bar0
;
;    print("ttest...")
;    welsh = False
;    P = ttest(var_bar0,var_var0,ntime,var_bar,var_var,ntime,welsh,False)
;
;    res@gsnYRefLine            = 0
;    res@gsnYRefLineThicknessF  = 2
;    ;res@trYMinF     = -5.
;    ;res@trYMaxF     = 5.
;    res@xyLineColors           = colors(2)
;    res@tiYAxisString          = "Anomalous " + yaxis 
;    res@tiXAxisString          = "Latitude"
;    plot(1) = gsn_csm_xy(wks,sin(lat0*pi/180.),dzonal,res)
;  end if
;  end if
;
;  if (writencdf .and. n.eq.nfiles-1) then
;    dzonal!0 = "lat"
;    ncdf->$VAR(nfiles)$ = dzonal
;  end if

delete([/lat,var_bar/])

print("done with file " + n)
end do ;nfiles

;--
;Add transparent polygon
;--

; alpha = 0.05
; thick = 0.70
; dzonal@_FillValue = default_fillvalue("float")
; dzonal = where(P.le.alpha,dzonal,dzonal@_FillValue)
;
; res@xyCurveDrawOrder = "PreDraw"
; res@xyLineColors           = colors(3)
; res@xyLineThicknesses = 20
; topbot = gsn_csm_xy(wks,sin(lat0*pi/180.),dzonal,res)
; overlay(plot(1),topbot)

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

;  delete(yy)
;  yy = (/3.8/)
;  res_lines@gsLineColor       = colors(2)
;  lstr = unique_string("num")
;  tstr = unique_string("fum")
;  plot@$lstr$ = gsn_add_polyline(wks,plot(1),xx,(/yy(0),yy(0)/),res_lines)
;  plot@$tstr$ = gsn_add_text(wks,plot(1),labels(2),xx(1),yy(0),res_text)

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
