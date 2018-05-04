;**************************************
;load ne30pg3_omg_locations.nc
;generate sepearate plot for vanilla
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
  title = "ATM_NCPL = 48,96 for ne30,ne60"

  fname_in = (/fname1+".moistflux.nc",fname2+".moistflux.nc"/)
  nfiles = dimsizes(fname_in)
  varnams = (/"bin_centers","medians","upperQ","lowerQ","nnorm","globav","globavup","pdfprect","pdfmflux"/)

  xaxis = "-~F33~w~F21~*q/(g*rhow) at 850 hPa (mm/day)"
  yaxis = "PRECT (mm/day)"

  pltNam = "temp_mflux"

  label = (/fname1,fname2/)

  dopdfs = True
  donnorm = False
  dopdfo = False
  nplots = 2

  colors = (/"green","magenta"/)
  colors4 = (/"green4","magenta4"/)

  ymax = 300.
  xmax = 300.
  xlim = (/300.,300./)

;******************************************************
; plot options
;******************************************************
;---Start the graphics
  wks = gsn_open_wks("pdf",pltNam)
  plot = new( (/nplots/),"graphic")
  c = 0

  res                      = True         ; plot modifications desired
  res@gsnDraw              = False        ; don't draw plot
  res@gsnFrame             = False        ; don't advance frame
  ;res@gsnMaximize = True
  ;res@gsnPaperOrientation = "portrait"
  ;res@vpWidthF = 0.7
  ;res@vpHeightF = 0.35

  res@tmBorderThicknessF = 2 ;axes thickness
  res@tmXBMajorOutwardLengthF = 0.
  res@tmYLMajorOutwardLengthF = 0.
  res@tmXBMinorOutwardLengthF = 0.
  res@tmYLMinorOutwardLengthF = 0.
  res@tmXTMajorOutwardLengthF = 0.
  res@tmYRMajorOutwardLengthF = 0.
  res@tmXTMinorOutwardLengthF = 0.
  res@tmYRMinorOutwardLengthF = 0.

  res@xyMonoLineThickness = True
  res@xyLineThicknessF   = 2.

  respdf = True
  respdf = res
  respdf@gsnXYBarChart            = True              ; Create bar plot
  respdf@gsnXYBarChartOutlineOnly = True
  respdf@xyYStyle ="Log"
  respdf@xyLineThicknessF   = 2.

  resline = True
  resline@gsLineThicknessF = 2.
  resline@gsLineDashPattern = 1.

  gsres                = True
  gsres@gsFillOpacityF = 0.2;;;0.15
  gsres@tfPolyDrawOrder = "PreDraw"

  txres = True

  res_lines                   = True                  ; polyline mods desired
  res_lines@gsLineDashPattern = 0                    ; solid line
  res_lines@gsLineThicknessF  = 2.                   ; line thicker

do n = 0,nfiles-1

print("Begin case "+n)

   ncdf = addfile(fname_in(n) , "r")
   bin_centers = ncdf->$varnams(0)$
   medians = ncdf->$varnams(1)$
   upperQ = ncdf->$varnams(2)$
   lowerQ = ncdf->$varnams(3)$

   if (donnorm) then
     nnorm = ncdf->$varnams(4)$
   end if

   if (dopdfs) then
     ;;pdfmflux = ncdf->$varnams(7)$
     ;;pdfprect = ncdf->$varnams(8)$
     pdfprect = ncdf->$varnams(7)$ ;;bug fix
     pdfmflux = ncdf->$varnams(8)$ ;; 
     globav = ncdf->$varnams(5)$
     globavup = ncdf->$varnams(6)$
   end if
   delete(ncdf)

   pvals = ind(bin_centers.le.xlim(n))
   nvals = dimsizes(pvals);;;(medians)
   res@trYMinF                = 0.
   res@trYMaxF                = ymax
   res@trXMinF                = 0.
   res@trXMaxF                = xmax

   res@xyLineColors       = colors(n)
   if (n.eq.0) then
     res@tiYAxisString          = yaxis
     res@tiXAxisString          = xaxis
     plot(0)  = gsn_csm_xy(wks,bin_centers(pvals),medians(pvals),res)
     delete(res@tiYAxisString)
     delete(res@tiXAxisString)
     ;;; 1:1 line
     refline = gsn_add_polyline(wks,plot(0),(/res@trXMinF,res@trXMaxF/),(/res@trYMinF,res@trYMaxF/),resline)
   else 
     tmp = gsn_csm_xy(wks,bin_centers(pvals),medians(pvals),res)
     overlay(plot(0),tmp)
     delete(tmp)
   end if
   delete(pvals)

   ;;; transparent polygons
   np = 2*nvals+1
   xp = new((/np/),float)
   yp = new((/np/),float)

   xp(0) = bin_centers(0)
   xp(1:nvals) = bin_centers(0:nvals-1)
   xp(nvals+1:np-1) = bin_centers(nvals-1:0)

   yp(0) = upperQ(0)
   yp(1:nvals) = upperQ(0:nvals-1)
   yp(nvals+1:np-1) = lowerQ(nvals-1:0)

   gsres@gsFillColor    = colors4(n)
   polystr = unique_string("hum")
   plot@$polystr$ = gsn_add_polygon(wks,plot(0),xp,yp,gsres)
   delete([/medians,upperQ,lowerQ,xp,yp/])

   if (donnorm) then
     respdf@trYMinF                = 1.e-7
     respdf@trYMaxF                = 1.e0
     respdf@trXMinF                = 0.
     respdf@trXMaxF                = xmax
     respdf@xyLineColors       = colors(n)
     pvals = ind(nnorm.gt.0. .and. bin_c)
     if (n.eq.0) then
       c = c + 1
       c1 = c
       respdf@tiYAxisString          = "Normalized sample size per bin"
       respdf@tiXAxisString          = xaxis
       plot(c)  = gsn_csm_xy(wks,bin_centers(pvals),nnorm(pvals),respdf)
       delete(respdf@tiYAxisString)
       delete(respdf@tiXAxisString)
     else
       tmp  = gsn_csm_xy(wks,bin_centers(pvals),nnorm(pvals),respdf)
       overlay(plot(1),tmp)
       delete(tmp)
     end if
     delete([/nnorm,pvals/])

   end if
   
   if (dopdfs) then
     respdf@trYMinF                = 1.e-7
     respdf@trYMaxF                = 1.e0
     respdf@trXMinF                = 0.
     respdf@trXMaxF                = xmax
     respdf@xyLineColors       = colors(n)
     nbins = pdfprect@nbins
     xvals = pdfprect@bin_bounds(0:nbins-1)
;;hack
;;     pdfmflux = (pdfmflux - pdfprect)
;;
     pvals1 = ind(pdfmflux.gt.0. .and. xvals.le.xlim(n)) 
     pvals2 = ind(pdfprect.gt.0. .and. xvals.le.xlim(n))

     if (n.eq.0) then
       c = c + 1
       c2 = c
       respdf@tiYAxisString          = "Probability (fraction)"
       respdf@tiXAxisString          = "-~F33~w~F21~*q/(g*rhow) (solid) & PRECT (dashed) (mm/day)"
;;hack
;;       respdf@tiXAxisString          = "residuals (mm/day)"
;;
       plot(c2)  = gsn_csm_xy(wks,xvals(pvals1),pdfmflux(pvals1)/100.,respdf)
       delete(respdf@tiYAxisString)
       delete(respdf@tiXAxisString)
       respdf@xyDashPattern  = 16
       tmp  = gsn_csm_xy(wks,xvals(pvals2),pdfprect(pvals2)/100.,respdf)
       overlay(plot(c2),tmp)
       delete([/tmp,respdf@xyDashPattern/])
     else
       tmp  = gsn_csm_xy(wks,xvals(pvals1),pdfmflux(pvals1)/100.,respdf)
       overlay(plot(c2),tmp)
       delete(tmp)
       respdf@xyDashPattern  = 16
       tmp  = gsn_csm_xy(wks,xvals(pvals2),pdfprect(pvals2)/100.,respdf)
       overlay(plot(c2),tmp)
       delete([/tmp,respdf@xyDashPattern/])
     end if
     delete([/pvals1,pvals2,xvals,pdfprect,pdfmflux/])

     res_lines@gsLineColor       = colors(n)
     lstr = unique_string("hum")
     ylog = (/4.e-1,1.e-1,3.e-2,8.e-3/)
     plot@$lstr$ = gsn_add_polyline(wks,plot(c2),(/15.,25./),(/ylog(n),ylog(n)/),res_lines)

     txres@txFontHeightF = 0.0125
     txres@txJust             = "CenterLeft"
     tstr = unique_string("hum")
     txstats = (/"  Mean OMG850 +/- 10 degrees " + globav + " hPa/day"/)
     plot@$tstr$ = gsn_add_text(wks,plot(c2),txstats,25.,ylog(n),txres)

     tstr = unique_string("hum")
     ylog = (/2.e-1,6.e-2,1.5e-2,4.e-3/)
     txstats = (/"  Mean OMG850up +/- 10 degrees " + globavup + " hPa/day"/)
     plot@$tstr$ = gsn_add_text(wks,plot(c2),txstats,25.,ylog(n),txres)

   end if

delete(bin_centers)
print("done with case " + n)

end do ;nfiles

  ;;add title
  ;;txres@txFontHeightF = 0.025
  ;;txres@txJust             = "CenterCenter"
  ;;gsn_text_ndc(wks,title,0.50,0.98,txres)

;*****************************************************
; Manually create and attach legend
;*****************************************************
  res_text                    = True                  ; text mods desired
  res_text@txFontHeightF      = 0.018                 ; change text size
  res_text@txJust             = "CenterLeft"          ; text justification

  xx = (/3.,13./)
  yy = (/290.,280.,270.,260./)
  do n = 0,nfiles-1
    res_lines@gsLineColor       = colors(n)
    lstr = unique_string("rum")
    tstr = unique_string("hum")
    plot@$lstr$ = gsn_add_polyline(wks,plot(0),xx,(/yy(n),yy(n)/),res_lines)
    plot@$tstr$ = gsn_add_text(wks,plot(0),label(n),xx(1),yy(n),res_text)
  end do

;*****************************************************
; Panel Plot
;*****************************************************

  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  resP@gsnPaperOrientation = "portrait"
  resP@gsnPanelFigureStringsFontHeightF = 0.02
  ;resP@gsnPanelFigureStrings = (/ "a","b"/)
  resP@gsnPanelFigureStringsPerimOn     = False
  resP@amJust           = "TopRight"
  resP@gsnPanelYWhiteSpacePercent = 5.
  if (nplots.lt.4) then
    gsn_panel(wks,plot,(/1,nplots/),resP)               ; now draw as one plot
  else
    gsn_panel(wks,plot,(/2,2/),resP)
  end if
  ;;;drawNDCGrid(wks)
  frame(wks)

end

