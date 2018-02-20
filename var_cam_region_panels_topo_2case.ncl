;**************************************
;eof_cam.ncl
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
  Re = 6371.22

  rdir  = (/"/run/","/run/"/)
  fname = (/fname1,fname2/)
  fdate = (/".cam."+fincl1+"*",".cam."+fincl2+"*"/)
  nfiles = dimsizes(fname)

  onemnth = False ;;if False, define nstart
  nstart = 1

  latlon = True

  VAR = (/"OMEGA","OMEGA"/)
  varlev = (/22,19/) ;;23-1 And, 20-1 Him
  LAT = (/"lat","lat"/)
  LON = (/"lon","lon"/)
  factor = secpday/100.

  manlevs = True
  mag = 1. ;;1.0 for F2000; 3.5 for FHS94 (default nu_div)
  cmin = (/-250. /)*mag
  cmax = (/ 200. /)*mag
  cspc = (/   4.5/)*mag

  topolay = False ;;overlay topography
	ktopo = (/29,29,29/)
  seover = False ;;overlay panel boundaries
  transect = True ;;overlay transect
  streams = False ;;overlay streamline contours

  plabels = False
  labels = new( (/2*nfiles/), string)
  do i = 0,nfiles-1
    labels(i) = "level 23"
    labels(nfiles + i) = "level 20"
  end do

  varNam = (/"~F33~w~F21~ (hPa/day)"/)

  leftlat  = (/  -6.3, 10./)
  rightlat = (/  -6.3, 70./)
  leftlon  = (/-100., 89./)
  rightlon = (/ -60., 89./)

  pltNam = "temp_contour"

;************** 
;graphics stuff
;**************
  wkstype = "pdf"
  wks = gsn_open_wks(wkstype,pltNam)
  gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200") ;;"3saw") ;;"BkBlAqGrYeOrReViWh200");;"gui_default");;"MPL_gist_rainbow")
  setvalues NhlGetWorkspaceObjectId()
      "wsMaximumSize": 500000000
  end setvalues

  plot = new( (/2*nfiles/), graphic)
  ;wkstype@wkBackgroundOpacityF    = 0.
  gsn_reverse_colormap(wks)
   res             = True
   res@gsnMaximize = False
   res@gsnDraw     = False      ; Will draw later, after overlaying
   res@gsnFrame    = False      ; all plots

;;stream overlay
   ress = True
   ress = res
   ress@stArrowLengthF = 0.004
   ress@stArrowStride = 5
   ress@stLengthCheckCount = 15
   ress@stLineStartStride = 1
   ress@stMinArrowSpacingF = 0.035
   ress@stStepSizeF = 0.001
   ress@stMinDistanceF = 0.01;;0.03
   ress@stMinLineSpacingF = 0.003;;0.007
   ress@stLineThicknessF = 0.17
;   ress@stLevelSelectionMode = "AutomaticLevels";;;"ManualLevels"
;   ress@stMinLevelValF = -100.
;   ress@stMaxLevelValF = 100.
   ress@stLevelSpacingF = 1.
   ress@stMaxLevelCount = 20
   ;;ress@stLevelSpacing = 10
   ress@stLineColor = "white"

;;back to res
   res@cnFillOn          = True               ; turn on color fill
   res@cnLinesOn         = False
   res@gsnSpreadColors   = True               ; use full range of color map
   res@cnLineLabelsOn       = False
   res@cnInfoLabelOn        = False
   res@lbLabelBarOn         = False

;;topo overlay
   rest = True
   rest = res
   rest@cnFillOn = False
   rest@cnLinesOn = True
   rest@cnMaxLevelCount = 5
   rest@cnLevelSelectionMode = "ExplicitLevels"     ; manually set the contour levels with the following 3 resources
   rest@cnLevels = (/1000.,2000.,3000.,4000.,5000./)
   rest@cnLineThicknessF   = 0.75
   rest@cnLineColor = "white";;"grey43"
   rest@cnLineDrawOrder = "PostDraw"

   ;res@mpCenterLonF = 180.
   ;res@mpOutlineOn          = True    ; turn off continental outline
   res@mpGridAndLimbOn   = False           ; turn on lat/lon lines
   res@mpGridLatSpacingF = 10.
   res@mpGridLonSpacingF = 30.
   ;res@mpGridLineColor      = -1
   res@mpPerimOn         = False               ; turn off perimeter
   ;res@mpFillOn         = True
   ;;res@mpOutlineBoundarySets     = "NoBoundaries"
   res@mpProjection = "Orthographic";;"Mollweide"

;;transect overlay
  mkres               = True
  mkres@gsMarkerIndex = 16     ; Filled circle
  mkres@gsMarkerSizeF = 0.0001
  mkres@gsMarkerColor  = "black"

;;add titles

   ;must have on for exodus grid overlay
   res@mpGreatCircleLinesOn=True
   res@cnMaxLevelCount = 50

;************
;Main Loop
;************
 do n = 0,nfiles-1
 
 print("begin case "+n)

 if (n.eq.2) then
   ;;;flag for FV
   ;;;latlon = True
   ;;;varlev(0) = varlev(0) - 2
   ;;;varlev(1) = varlev(1) - 2
 else if (n.eq.1) then
   ;;;varlev(0) = varlev(0) + 2
   ;;;varlev(1) = varlev(1) + 2
 end if
 end if


 ;load all files
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
 ntime = dimsizes(f[:]->time)

 lat1d = f[0]->$LAT(n)$
 lon1d = f[0]->$LON(n)$

 if (latlon) then
   var1 = f[:]->$VAR(n)$(:,varlev(0),:,:)
   var2 = f[:]->$VAR(n)$(:,varlev(1),:,:)
   var1 = factor*var1
   var2 = factor*var2

   if (topolay) then
     topo = f[0]->Z3(0,ktopo(n),:,:)
   else if (streams) then
     u1 = f[:]->U(:,varlev(0),:,:)
     v1 = f[:]->V(:,varlev(0),:,:)
     u2 = f[:]->U(:,varlev(1),:,:)
     v2 = f[:]->V(:,varlev(1),:,:)
   end if
   end if
 else
   var1 = f[:]->$VAR(n)$(:,varlev(0),:)
   var2 = f[:]->$VAR(n)$(:,varlev(1),:)
   var1 = factor*var1
   var2 = factor*var2

   res@sfXArray = lon1d
   res@sfYArray = lat1d

   if (topolay) then
     topo = f[0]->Z3(0,ktopo(n),:)
     ;;lat = f[0]->lat
     ;;lon = f[0]->lon
     rest@sfXArray = lon1d
     rest@sfYArray = lat1d
   else if (streams) then
     u1 = f[:]->U(:,varlev(0),:)
     v1 = f[:]->V(:,varlev(0),:)
     u2 = f[:]->U(:,varlev(1),:)
     v2 = f[:]->V(:,varlev(1),:)
   end if
   end if
 end if

 delete(f)

 print("dim_avg_0...")
 if (latlon) then
   rank = 3
 else
   ;;;unstructured
   rank = 2
 end if
 bar1 = dim_avg_0_lowmem(var1,rank) 
 bar2 = dim_avg_0_lowmem(var2,rank)

 if (streams) then
  u1bar = dim_avg_0_lowmem(u1,rank)
  v1bar = dim_avg_0_lowmem(v1,rank)
  u2bar = dim_avg_0_lowmem(u2,rank)
  v2bar = dim_avg_0_lowmem(v2,rank)
  delete(u1)
  delete(u2)
  delete(v1)
  delete(v2)
 end if

 print("plotting...")

 if (latlon) then
  attr = var1(0,:,:)
  delete(attr@long_name)
  delete(attr@units)
  copy_VarMeta(attr,bar1)
  copy_VarMeta(attr,bar2)
  if (streams) then
    copy_VarMeta(attr,u1bar)
    copy_VarMeta(attr,v1bar)
    copy_VarMeta(attr,u2bar)
    copy_VarMeta(attr,v2bar)
  end if
  delete(attr)
 end if
 delete(var1)
 delete(var2)

 if (manlevs) then
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF  = cmin(0)
   res@cnMaxLevelValF  = cmax(0)
   res@cnLevelSpacingF = cspc(0)
 end if

 andind = n
 himind = nfiles + n

 res@mpCenterLonF = -80.;-70.
 res@mpCenterLatF = 0.;-20.
 plot(andind) = gsn_csm_contour_map(wks,bar1,res)
 res@mpCenterLonF = 60.;80.
 res@mpCenterLatF = 30.
 plot(himind) = gsn_csm_contour_map(wks,bar2,res) 

 if (seover) then
  overlay_se_grid(wks,plot(andind))
  overlay_se_grid(wks,plot(himind))
 end if

 if (topolay) then
   delete(topo@long_name)
   delete(topo@units)
   tmp1 = gsn_csm_contour(wks,topo,rest)
   tmp2 = gsn_csm_contour(wks,topo,rest)
   overlay(plot(andind),tmp1)
   overlay(plot(himind),tmp2)
   delete(tmp1)
   delete(tmp2)
   delete(topo) 
 end if

 if (streams) then
   tmp1 = gsn_csm_streamline(wks,u1bar,v1bar,ress)
   tmp2 = gsn_csm_streamline(wks,u1bar,v1bar,ress)
   overlay(plot(andind),tmp1)
   overlay(plot(himind),tmp2)
   delete(u1bar)
   delete(u2bar)
   delete(v1bar)
   delete(v2bar)
   delete(tmp1)
   delete(tmp2)
 end if

 if (transect) then
  npts = 300
  dum    = gc_latlon(leftlat,leftlon,rightlat,rightlon,npts,4)
  tstr1 = unique_string("dum")
  tstr2 = unique_string("dum")
  plot@$tstr1$ = gsn_add_polymarker(wks,plot(andind),dum@gclon ,dum@gclat ,mkres)
  plot@$tstr2$ = gsn_add_polymarker(wks,plot(himind),dum@gclon ,dum@gclat ,mkres)
  delete(dum)
 end if

delete(bar1)
delete(bar2)
delete(lat1d)
delete(lon1d)

 if (.not.latlon) then
   delete(res@sfXArray)
   delete(res@sfYArray)
   if (topolay) then
     delete(rest@sfXArray)
     delete(rest@sfYArray)
   end if
 end if

  ;;add titles
  txres = True
  txres@txFontHeightF = 0.010
  yy = (/ 0.99,0.99 /)
  xx = (/ 0.3,0.7 /)
  gsn_text_ndc(wks,fname(n),xx(n),yy(n),txres)

end do ;nfiles

;drawNDCGrid(wks)
;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot

  ;;if (plabels) then
    resP@gsnPanelFigureStrings = labels
    resP@gsnPanelFigureStringsFontHeightF = 0.010
    resP@gsnPanelFigureStringsPerimOn     = True
    resP@gsnPanelFigureStringsBackgroundFillColor = "white"
    resP@amJust           = "TopRight"
  ;;end if

  resP@gsnPanelLabelBar = True
  resP@lbTitleString              = varNam
  resP@lbTitlePosition            = "Bottom"
  resP@lbTitleFontHeightF         = 0.015
  resP@lbLabelFontHeightF         = 0.008
  resP@lbBoxSeparatorLinesOn = False

  resP@pmLabelBarOrthogonalPosF = -0.01
  resP@pmLabelBarParallelPosF = 0.

  resP@gsnPanelTop        = 0.97
  ;resP@gsnPanelBottom     = 0.1
  ;resP@gsnPanelRight     = 0.9007;
  ;resP@gsnPanelLeft     = 0.40        ; position of left most plot
  gsn_panel(wks,plot,(/2,nfiles/),resP)      

frame(wks)

end



