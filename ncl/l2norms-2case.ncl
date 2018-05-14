;**************************************
;compute l2norms
;
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl" 
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
;**************************************
begin
;****************************************
  fname = (/fname1,fname2/)
  fdate = (/".cam."+fincl1+"*",".cam."+fincl2+"*"/)
  nfiles = dimsizes(fname)

  yaxis = "l~B~2~N~( p~B~s~N~ ) (hPa)"
  ymax = 2.e2
  ymin = 1.e-3

  onemnth = False
  nstart = 0

  writencdf = False
  fname_out = "l2norms-2-case.nc"

  rcolors = (/"magenta3","black"/) 
  rlabel =(/"  l~B~2~N~(Case2 - Case1)", \
            "  l~B~2~N~(CAM-SE ne120 - CAM-FV 0.25~F135~G~F21~)"/)

  titles = fname
  titles(0) = "Case1: " + fname(0)
  titles(1) = "Case2: " + fname(1)

  Re = 6.37122e3 ;km
  secpday = 60.*60.*24
  pi = 3.14159265358979
  L = 2*pi*Re ;equatorial circumfrence
  g = 9.80616 ;m/s2
  p0   = 100000.
;******************************************************
; plot options
;******************************************************
;---Start the graphics
  wks = gsn_open_wks("pdf","temp_l2")

  res                      = True         ; plot modifications desired
  res@gsnDraw              = False        ; don't draw plot
  res@gsnFrame             = False        ; don't advance frame
  ;res@gsnMaximize = True
  res@vpWidthF = 0.5
  res@vpHeightF = 0.5
  ;res@trYMaxF                = ymax
  ;res@trYMinF                = ymin
  ;res@trXMinF                = -5.e3
  ;res@trXMaxF                = 0.

  res@trXReverse            = False
  res@tmBorderThicknessF = 4 ;axes thickness
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
  res@xyLineThicknessF   = 3.0

  ;;;titles
  txres = True
  txres@txFontHeightF = 0.016
  txres@txJust = "CenterLeft"
  ytitle = (/0.955,0.93/)

do n = 0,nfiles-1

print("Begin case n = " + n)

  files = systemfunc ("ls " + dir + fname(n) + "/run/" + fname(n) + fdate(n))
  nhist = dimsizes(files)

  if (onemnth) then
   nfinish = nstart
  else 
   nfinish = nhist-1
  end if
  f  = addfiles (files(nstart:nfinish),"r") 
  ListSetType(f,"cat")
  delete(files)

  if (isfilevardim(f[0],"PS","lat")) then
    print("NETCDF is on lat-lon grid")
    latlon = True
  else
    print("NETCDF is on native se-grid")
    latlon = False
  end if

print("grabbing vars...")

  if (latlon) then
    wgt = f[0]->w ;;gw in fv?
  else
    wgt = f[0]->area
  end if
  time = f[:]->time
  ntime = dimsizes(time)

  ps = f[:]->PS
  delete(f)

  if (n.eq.0) then
    ps0 = ps
  else
    print("computing l2norm...")
    prsqr = (ps - ps0)^2.
    if (latlon) then
      globav = wgt_areaave(prsqr,wgt,1.0,1)
    else    
      globav = dim_avg_wgt(prsqr,wgt,0)
    end if 
    l2norm = sqrt(globav)/100.
    delete([/globav,prsqr,ps0/])

    res@xyLineColors       = rcolors(0)
    res@tiYAxisString          = yaxis
    res@tiXAxisString	       = "Time (days)"
    res@trYMaxF                = ymax
    res@trYMinF                = ymin
    res@xyYStyle ="Log"

    vals = ind(l2norm.ne.0.)
    if (all(ismissing(vals))) then
      print("NO NON-ZERO L2 VALS")
      print("exiting...")
      exit
    end if

    plot  = gsn_csm_xy(wks,time(vals),l2norm(vals),res)
    delete([/vals,l2norm/])
  end if

  delete([/ps,time/])

  ;;add titles
  gsn_text_ndc(wks,titles(n),0.015,ytitle(n),txres)

  print("done with case " + n)

end do
;;;drawNDCGrid(wks)

  ncdfin = addfile(ncldir+"/l2_paper.nc","r")
  time = ncdfin->time
  l2ref = ncdfin->l2norms(2,:)
  NTIME = dimsizes(time)

  res@xyCurveDrawOrder = "PreDraw"
  res@xyLineColors       = rcolors(1)
  vals = ind(l2ref.ne.0.)
  tmp = gsn_csm_xy(wks,time(vals),l2ref(vals),res)
  overlay(plot,tmp)
  delete([/tmp,vals/])

;--
;Add transparent polygon at l2ref
;--
  xp = new((/NTIME+3/),double)
  yp = new((/NTIME+3/),double)
 
  xp(0) = time(0)
  xp(1:NTIME) = time(0:NTIME-1)
  xp(NTIME+1) = time(NTIME-1)    
  xp(NTIME+2) = time(0)

  yp(0) = ymin
  yp(1:NTIME) = l2ref(0:NTIME-1)
  yp(NTIME+1) = ymin
  yp(NTIME+2) = ymin

  gsres                = True
  gsres@gsFillColor    = "yellow"
  gsres@gsFillOpacityF = 0.2
  gsres@tfPolyDrawOrder = "PreDraw"

  box = gsn_add_polygon(wks,plot,xp,yp,gsres)
;--
;*****************************************************
; Manually create and attach legend
;*****************************************************
  res_text                    = True                  ; text mods desired
  res_text@txFontHeightF      = 0.014                 ; change text size
  res_text@txJust             = "CenterLeft"          ; text justification

  res_lines                   = True                  ; polyline mods desired
  res_lines@gsLineDashPattern = 0                    ; solid line
  res_lines@gsLineThicknessF  = 3.                   ; line thicker

  xx = (/1.,2.5/)
  yy = (/1.e2,6.e1/)
  do n = 0,1
    res_lines@gsLineColor       = rcolors(n)
    lstr = unique_string("num")
    tstr = unique_string("fum")
    plot@$lstr$ = gsn_add_polyline(wks,plot,xx,(/yy(n),yy(n)/),res_lines)
    plot@$tstr$ = gsn_add_text(wks,plot,rlabel(n),xx(1),yy(n),res_text)
  end do

;*****************************************************
; Panel Plot
;*****************************************************
  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  resP@gsnPaperOrientation = "portrait"
  resP@gsnPanelFigureStringsFontHeightF = 0.02
  ;resP@txString = plotTitle
  ;resP@gsnPanelFigureStrings = (/ "a","b"/)
  resP@gsnPanelFigureStringsPerimOn     = False
  resP@amJust           = "TopRight"
  resP@gsnPanelTop   = 0.90
  ;;resP@gsnPanelBottom   = 0.05
  ;;resP@gsnPanelYWhiteSpacePercent = 5.
  gsn_panel(wks,plot,(/1,1/),resP)               ; now draw as one plot

  frame(wks)
end

