;**************************************
;transect.ncl
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
load "/home/aherring/ncl-scripts/se_func_lib.ncl"
;**************************************
begin
;****************************************
  secpday = 60.*60.*24;
  pi = 3.14159265358979
  g = 9.80616 ;m/s2
  p0 = 1.e5 ;Pa

  rdir  = (/"/run/","/run/","/run/"/)
  fname = (/fname1,fname2/)
  fdate = (/".cam."+fincl1+"*",".cam."+fincl2+"*"/)
  nfiles = dimsizes(fname)

  onemnth = False ;;if False, define nstart
  nstart = 1

  latlon = True
  wgt_path = "/home/aherring/regrid/"
  ;;wgt_file = (/"ne30_2_latlon.nc","ne30fvm_2_latlon.nc","ne30fvm_2_latlon.nc"/)
  wgt_file = (/"ne30_2_latlon.nc","ne30_2_latlon.nc","ne30_2_latlon.nc"/)

  VAR = (/"OMEGA","OMEGA","OMEGA"/)
  LAT = (/"lat","lat","lat"/)
  LON = (/"lon","lon","lon"/)
  factor = secpday/100.

  manlevs = True
  mag = 1.0 ;;1.0 for F2000; 3.5 for FHS94 (default nu_div)
  cmin = (/-250. /)*mag
  cmax = (/ 200. /)*mag
  cspc = (/   4.5/)*mag

  topolay = False ;;overlay topography
  noeq = True ;;off equator transect
  eq = (/128,128,128/)

  npts 	   = (/ 60, 60/)
  leftlat  = (/ -6.3, 10./)
  rightlat = (/ -6.3, 50./)
  leftlon  = (/-100., 89./)
  rightlon = (/ -60., 89./)

  labels = new( (/2*nfiles/), string)
  do i = 0,nfiles-1
    labels(2*i) = "Andes (E-W)"
    labels(2*i+ 1) = "Himalayas (S-N)"
  end do

;************** 
;graphics stuff
;**************
  wkstype = "pdf"
  wkstype@wkBackgroundOpacityF    = 0.
  wks = gsn_open_wks(wkstype,"temp_transect")
  gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
  gsn_reverse_colormap(wks)
  plot = new(2*nfiles,graphic)

   res             = True
   res@gsnMaximize = False
   res@gsnDraw     = False      ; Will draw later, after overlaying
   res@gsnFrame    = False      ; all plots

   res@vpXF      = 0.2
   res@vpYF      = 0.8
   res@vpWidthF  = 0.8
   res@vpHeightF = 0.2

   res@cnFillOn          = True               ; turn on color fill
   res@cnLinesOn         = False
   res@gsnSpreadColors  = True               ; use full range of color map
   res@lbLabelBarOn         = False
   res@lbLabelStride     = 2                  ; every other color
   res@cnLineLabelsOn       = False
   res@cnInfoLabelOn              = False 

   ;;;for titles to show up
   ;;;res@cnFillDrawOrder = "PreDraw"

   res@cnLevelSelectionMode = "ManualLevels"     ; manually set the contour levels with the following 3 resources
   res@cnMinLevelValF  = -800.;-150.                 ; set the minimum contour level
   res@cnMaxLevelValF  = 200.;150.                  ; set the maximum contour level
   res@cnLevelSpacingF = 50.;30                 ; set the interval between contours

   res@trYReverse            = True                 ; reverse y-axis
   res@gsnXAxisIrregular2Linear = True
   res@gsnYAxisIrregular2Linear = True
   res@tmBorderThicknessF = 2 ;axes thickness
   res@tmXBMajorOutwardLengthF = 0.
   res@tmYLMajorOutwardLengthF = 0.
   res@tmXBMinorOutwardLengthF = 0.
   res@tmYLMinorOutwardLengthF = 0.
   res@tmXTMajorOutwardLengthF = 0.
   res@tmYRMajorOutwardLengthF = 0.
   res@tmXTMinorOutwardLengthF = 0.
   res@tmYRMinorOutwardLengthF = 0.

   res@tiXAxisFontHeightF = 0.014
   res@tiYAxisFontHeightF = 0.014
   res@tmXBLabelFontHeightF = 0.014
   res@tmYLLabelFontHeightF = 0.014

;************
;Main Loop
;************
 do n = 0,nfiles-1

print(n)

 files = systemfunc ("ls " + dir + fname(n) + rdir(n) + fname(n) + fdate(n))
 nf = dimsizes(files)
 if (onemnth) then
   nstart = nf-3
   nfinish = nf-2
 else
   nfinish = nf-1
 end if

 print("load files...")
 print(files(nstart:nfinish))

 f  = addfiles (files(nstart:nfinish),"r")
 ListSetType(f,"cat")
 delete(files)

 print("Grab var...")

 if (n.eq.0) then
   hyam = f[0]->hyam
   hybm = f[0]->hybm
 end if

 var1 = f[:]->$VAR(n)$
 var1 = factor*var1
 ps = f[:]->PS

 if (latlon) then
   lat = f[0]->lat
   lon = f[0]->lon
 else
 end if
 delete(f)

 print("dim_avg_0...")
 if (latlon) then
   rank = 4
 else
   ;;;unstructured
   rank = 3
 end if
 bar1 = dim_avg_0_lowmem(var1,rank)
 psbar = dim_avg_0_lowmem(ps,rank-1)
 delete(var1)
 delete(ps)

 if (.not.latlon) then
   ;regrid
   bar_regrid = ESMF_regrid_with_weights(bar1,wgt_path+wgt_file(n),False)
   ps_regrid  = ESMF_regrid_with_weights(psbar,wgt_path+wgt_file(n),False)
   delete(bar1)
   delete(psbar)
   lat = bar_regrid&lat
   lon = bar_regrid&lon
 else
   bar_regrid = bar1
   ps_regrid = psbar
 end if
 delete(bar1)
 delete(psbar)

 pm = pres_hybrid_ccm(ps_regrid,p0,hyam,hybm)

  if (n.eq.0) then
   lev_p = (hyam + hybm)*p0
   lev_p!0         = "lev_p"                  ; variable/dim name
   lev_p&lev_p     =  lev_p                   ; create coordinate variable
   lev_p@long_name = "Pressure (hPa)"               ; attach some attributes
   lev_p@units     = "Pa"
   lev_p@positive  = "down"
   linlog = 2
  end if

do regind = 0,1 ;;And and Him

 if (.not.noeq) then
    barx = bar_regrid(:,eq(n),:)
    pmx = pm(:,eq(n),:)
 else
    ;************************************
    ; calculate great circle along transect
    ;************************************
    dum    = gc_latlon(leftlat(regind),leftlon(regind),rightlat(regind),rightlon(regind),npts(regind),4)
    dist   = fspan(0.,1.,npts(regind))*dum
    ;********************************
    ; interpolate data to great circle
    ;********************************
    barx  = linint2_points(lon,lat,bar_regrid,True,dum@gclon,dum@gclat,2)
    pmx   = linint2_points(lon,lat,pm,True,dum@gclon,dum@gclat,2)
    delete(dum)

    ;;res@trXMinF     = 0.
    ;;res@trXMaxF     = R*180.*pi/180.
    ;;res@tmXBMode = "Manual"
    ;;res@tmXBDataRightF = 20000.
    ;;res@tmXBTickStartF = 0.
    ;;res@tmXBTickEndF = 20000.
    ;;res@tmXBMinorPerMajor = 5
    ;;res@tmXBTickSpacingF = 10000.
  end if
  pmx!0 = "levs"
  pmx!1 = "dist"

  copy_VarAtts(bar_regrid,barx)
  copy_VarAtts(ps_regrid,pmx)

;*************************************************************
; remap to common pressure level
; *remember when using vinth2p:
; lev_p->hPa / ps->Pa / p0->hPa
;*************************************************************

  var = int2p_n(pmx(levs|:,dist|:),barx,lev_p,linlog,0)
  var!0 = "levs"
  var&levs = lev_p/100.
  var&levs@long_name = "Pressure (hPa)"
  var!1 = "dist"
  var&dist = dist
  delete(pmx)
  delete(barx)
  delete(dist)

  if (n.eq.nfiles-1) then  
   res@tiXAxisString          = "Distance (km)"
  end if

  if (manlevs) then
    res@cnLevelSelectionMode = "ManualLevels"
    res@cnMinLevelValF  = cmin(0)
    res@cnMaxLevelValF  = cmax(0)
    res@cnLevelSpacingF = cspc(0)
  end if

  plot( 2*n + regind )  = gsn_csm_contour(wks,var,res)

  delete(var)

end do;regind

  delete(bar_regrid)
  delete(ps_regrid)
  delete(pm)
  delete(lat)
  delete(lon)

end do

;;;drawNDCGrid(wks)
;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  resP@gsnMaximize      = True
  resP@gsnPaperOrientation = "portrait"
  resP@gsnPanelLabelBar = True                   ; add common colorbar

  resP@gsnPanelFigureStrings = labels

  resP@gsnPanelFigureStringsFontHeightF = 0.008
  resP@gsnPanelFigureStringsPerimOn     = True
  resP@gsnPanelFigureStringsBackgroundFillColor = "white"
  resP@amJust           = "TopRight"

  resP@gsnPanelBottom   = 0.1
  resP@lbTitleString              = "~F33~w~F21~ (hPa/day)"
  resP@lbTitlePosition            = "Bottom"
  resP@lbBoxSeparatorLinesOn = False

  resP@vpHeightF                  = 0.1     ; Height of labelbar
  resP@vpWidthF                   = 0.60      ; Width of labelbar
  resP@lbLabelFontHeightF         = 0.010
  resP@lbLabelStride              = 1
  resP@lbTitleFontHeightF         = 20
  ;resP@lbTitleFont                = 22
  resP@lbTopMarginF               = 0.11

  gsn_panel(wks,plot,(/nfiles,2/),resP)               ; now draw as one plot

;;
  ;;add titles
  txres = True
  txres@txFontHeightF = 0.008
  txres@txJust = "CenterLeft"
  yy = (/ 0.68,0.55 /)
  xx = (/ 0.06,0.06 /)
  do n = 0,nfiles-1
    gsn_text_ndc(wks,fname(n),xx(n),yy(n),txres)
  end do

frame(wks)

end



