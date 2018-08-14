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

  VAR = "OMEGA"
  onemnth = False
  factor = 1.;;;secpday/100.

  scale = True
  sfactor = 1.;;;3./2.
  dtag = ""   ;;;"-scale32"

  nbins  = 200
  optpdf = True  ;;;If False, do pdfx w/ automatic bins
  xmin = -15.     ;;;x-axis range (override by binmin)
  ymin =  1.e-10 ;;;y-axis range

  writencdf = True
  loadncdf = False
  fname_out = fname(0)+".pdf-omg"+dtag+".nc"
  varnams = (/"pdfvar1","pdfvar2"/)
  fname_in  = fname_out

  xaxis = "~F33~w~F21~ (Pa/s)"

  pltNam = "temp_pdf-omg"
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
  res@trYMaxF                = 1.

  res@trXReverse            = True
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

  res@gsnXYBarChart            = True              ; Create bar plot
  res@gsnXYBarChartOutlineOnly = True
  res@xyMonoLineThickness = True
  res@xyLineThicknessF   = 3

  res@trYMinF                = ymin
  res@trXMinF                = xmin
  res@trXMaxF                = 0.05

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
   nstart = 1
   nfinish = 1
  else
   nstart = 0
   nfinish = nhist-1
  end if
  print("Loading Files(s)...")
  print(files(nstart:nfinish))
  f  = addfiles (files(nstart:nfinish),"r")
  ListSetType(f,"cat")
  delete(files)

  if (isfilevardim(f[0],"OMEGA","lon")) then
    print("*history fields must be on native se-grid*")
    print("exiting...")
    exit
  else
    dims = getfilevardimsizes(f[0],VAR)
    ncol = dims(2)
    delete(dims)

    dims = getfilevardimsizes(f[0],"OMEGA_gll")
    ncol_d = dims(2)
    delete(dims)
  end if

  var = f[:]->$VAR$
  var = var*factor

  if (scale) then
    var = var*sfactor
  end if

  ntime = dimsizes(f[:]->time)
  delete(f)
  print("minimum omg " + min(var))

  wcStrtPdf = systemfunc("date")
  wallClockElapseTime(wcStrtVar, "Loading Vars", 0)

  print("Starting pdf")

  var@_FillValue = default_fillvalue("float")
  var = where(var.lt.0.,var,var@_FillValue)
  if (optpdf) then
    print("do pdfx_lowmem with specified bins")

    ;;optpdf@bin_min  = -15.
    optpdf@bin_min  = get_binmin_omg(ncol,ncol_d)

    optpdf@bin_max  = 0.
    print("bin_min set to " + optpdf@bin_min)
    optpdf@bin_spacing = (optpdf@bin_max-optpdf@bin_min)/nbins
    pdfvar = pdfx_lowmem(var,3,nbins,optpdf)
  else
    print("do pdfx with automated bins")
    pdfvar = pdfx(var,nbins,optpdf)
    print("max bin " + pdfvar@bin_bound_max)
    print("min bin " + pdfvar@bin_bound_min)
  end if
  delete(var)

  if (scale) then
    pdfvar = pdfvar/sfactor
  end if  
 
;;;
delete(ncol)
;;;

   wallClockElapseTime(wcStrtPdf, "Compute PDF", 0)

else

   print("Loading pdfvars from " + fname_in)
   if (n.eq.0) then
     ncdf = addfile(fname_in , "r")
   end if
   pdfvar = ncdf->$varnams(n)$

end if

   print("Plotting...")
   res@trXMinF = xmin;;;optpdf@bin_min
   res@xyLineColors       = colors(n)
   pvals = ind(pdfvar.gt.0.d0)
   xvals = pdfvar@bin_bounds(0:nbins-1)
   if (n.eq.0) then
     res@tiYAxisString          = "Probability (fraction)"
     res@tiXAxisString          = xaxis
     plot  = gsn_csm_xy(wks,xvals(pvals),pdfvar(pvals)*1.e-2,res)
     delete(res@tiYAxisString)
   else 
     tmp = gsn_csm_xy(wks,xvals(pvals),pdfvar(pvals)*1.e-2,res)
     overlay(plot,tmp)
     delete(tmp)
   end if
   delete(pvals)
   delete(xvals)

   if (writencdf) then
     if (n.eq.0) then
       system("/bin/rm -f "+fname_out)
       ncdf = addfile(fname_out , "c")
     end if
     ncdf->$varnams(n)$ = pdfvar
   end if
   delete(pdfvar)

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

