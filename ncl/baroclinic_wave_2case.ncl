;**************************************
;FKESSLER contour plots
;requires data on native se-grid
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/home/aherring/arh-git-scripts/ncl/se_func_lib.ncl"
;**************************************
begin
;****************************************
  secpday = 60.*60.*24;
  pi = 3.14159265358979
  g = 9.80616 ;m/s2
  Re = 6371.22
  cp = 1004.
  Rd = 287.

  fname = (/fname1,fname2/)
  fdate = (/".cam."+fincl1+"*",".cam."+fincl2+"*"/)
  tname = fname
  nfiles = dimsizes(fname)

  cellfill = True
  doglobal = False
  onemnth = False

  t0 = 40 ;6-hourly indices: 36 = day9, 40 = day10, 60 = day15
  labels = (/"day10","day10","day10"/)

  VAR = (/plotvar,plotvar,plotvar/)
  LAT = (/"lat","lat","lat"/)
  LON = (/"lon","lon","lon"/)

  plotName = "temp"
  var3d = False
  manlevs = True
  if (VAR(0).eq."PS") then
    cmin = 920.
    cmax = 1020.
    cspc = 10.
    factor = 1.e-2
    varNam = (/"PS (hPa)"/)
  else if (VAR(0).eq."iCL") then
    doglobal = True
    cmin = 0.
    cmax = 4.e-6
    cspc = 0.25e-6
    factor = 1.
    varNam = (/"iCL (kg/kg)"/)
  else if (VAR(0).eq."iCL2") then
    doglobal = True
    cmin = 0.
    cmax = 2.e-6
    cspc = 0.1e-6
    factor = 1.
    varNam = (/"iCL2 (kg/kg)"/)
  else if (VAR(0).eq."iCLy") then
    doglobal = True
    cmin = 2.7e-6
    cmax = 4.8e-6
    cspc = 0.1e-6
    factor = 1.
    varNam = (/"iCLy (kg/kg)"/)
  else if (VAR(0).eq."PRECL") then
    cmin = 0.
    cmax = 60.
    cspc = 2.
    factor = secpday*1000.
    varNam = (/"PRECL (mm/day)"/)
  else if (VAR(0).eq."PTTEND") then
    var3d = True
    varlev = 23
    cmin = -50.
    cmax = 30.
    cspc = 4.
    factor = secpday
    varNam = (/"PTTEND(lev="+varlev+") (K/day)"/)
  else if (VAR(0).eq."CLDLIQ") then
    var3d = True
    varlev = 20
    cmin = 0.
    cmax = 0.00035
    cspc = 0.00001
    factor = 1.
    varNam = (/"CLDLIQ(lev="+varlev+") (kg/kg)"/)
  else if (VAR(0).eq."Q") then
    var3d = True
    varlev = 25
    cmin = 0.
    cmax = 0.015
    cspc = 0.0005
    factor = 1.
    varNam = (/"Q(lev="+varlev+") (kg/kg)"/)
  else if (VAR(0).eq."CL") then
    doglobal = True
    var3d = True
    varlev = 25
    cmin = 0.
    cmax = 4.e-6
    cspc = 0.25e-6
    factor = 1.
    varNam = (/"CL(lev="+varlev+") (kg/kg)"/)
  else if (VAR(0).eq."CL2") then
    doglobal = True
    var3d = True
    varlev = 25
    cmin = 0.
    cmax = 2.e-6
    cspc = 0.1e-6
    factor = 1.
    varNam = (/"CL2(lev="+varlev+") (kg/kg)"/)
  else
    manlevs = False
    factor = 1.
    varNam = VAR(0)
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if

;************** 
;graphics stuff
;**************
  wkstype = "pdf"
  wks = gsn_open_wks(wkstype,plotName)
  gsn_define_colormap(wks,"gui_default");;"gui_default");;"MPL_gist_rainbow")
  plot = new( (/nfiles/), graphic)
  ;wkstype@wkBackgroundOpacityF    = 0.
  ;gsn_reverse_colormap(wks)

   res             = True
   res@gsnMaximize = False
   res@gsnDraw     = False      ; Will draw later, after overlaying
   res@gsnFrame    = False      ; all plots

   res@cnFillOn          = True               ; turn on color fill
   res@cnLinesOn         = False
   res@gsnSpreadColors   = True               ; use full range of color map
   res@cnLineLabelsOn       = False
   res@cnInfoLabelOn        = False

   res@lbLabelBarOn         = False

   res@mpCenterLonF = 180.
   res@mpOutlineOn          = False    ; turn off continental outline
   res@mpFillOn             = False
   res@mpGridAndLimbOn   = False           ; turn on lat/lon lines
   ;res@mpGridLatSpacingF = 10.
   ;res@mpGridLonSpacingF = 30.
   ;res@mpGridLineColor      = -1
   res@mpPerimOn         = False               ; turn off perimeter
   res@mpFillOn         = False
   res@mpOutlineBoundarySets     = "NoBoundaries"

   if (cellfill) then
     res@cnFillMode = "CellFill"
   end if

   if (.not.doglobal) then
     res@mpMaxLatF = 70.
     res@mpMinLatF = 20.
     res@mpMaxLonF = 210.
     res@mpMinLonF = 30.
   end if

;Set Position and Sizes

   ;res@vpXF             = 0.12
   ;res@vpYF             = 0.94   
   ;res@vpWidthF         = 0.50
   ;res@vpHeightF        = 0.40
   ;res@trYMinF          = 0.                   
   ;res@trYMaxF          = 950.         

;************
;Main Loop
;************
 do n = 0,nfiles-1
 
 print("begin case "+n)

 ;load all files
 files = systemfunc ("ls " + dir + fname(n) + "/run/" + fname(n) + fdate(n))
 nf = dimsizes(files)
 if (onemnth) then
   nstart = nf-2
   nfinish = nf-2
 else
   nstart = 0
   nfinish = nf-1
 end if

 print("load files...")

 f  = addfiles (files(nstart:nfinish),"r")
 ListSetType(f,"cat")
 delete(files)

 print("Grab var...")

 if (var3d) then
   var = f[:]->$VAR(n)$(t0,varlev,:)
   if (n.eq.0) then
     hyam = f[0]->hyam
     hybm = f[0]->hybm
   end if
 else
   var = f[:]->$VAR(n)$(t0,:)
 end if

 var = factor*var

 lat1d = f[0]->$LAT(n)$
 lon1d = f[0]->$LON(n)$
 delete(f)

 print("Plotting...")

 if (cellfill) then
   print("CellFill on")
   ncol = dimsizes(lat1d)
   vpath = get_vertices(ncol)
   sf = addfile(vpath,"r")
   latvert = sf->grid_corner_lat
   lonvert = sf->grid_corner_lon
   res@sfXCellBounds = lonvert
   res@sfYCellBounds = latvert
   delete([/sf,latvert,lonvert/])
 end if

 delete(var@units)
 var@long_name = tname(n)
 res@sfXArray = lon1d
 res@sfYArray = lat1d

 if (manlevs) then
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF  = cmin
   res@cnMaxLevelValF  = cmax
   res@cnLevelSpacingF = cspc
 else
   print("manual levels set to False")
   print("max var " + max(var))
   print("min var " + min(var))
   mxmmn = max(var)-min(var)
   print("max - min " + mxmmn)
 end if

 plot(n) = gsn_csm_contour_map(wks,var,res)

delete(var)
delete(lat1d)
delete(lon1d)
delete(res@sfXArray)
delete(res@sfYArray)

if (cellfill) then
   delete([/res@sfXCellBounds,res@sfYCellBounds/])
end if

end do ;nfiles


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
  resP@gsnPanelBottom   = 0.1
  resP@lbTitleString              = varNam
  resP@lbTitlePosition            = "Top"
  resP@lbTitleFontHeightF         = 0.0084
  resP@lbLabelFontHeightF         = 0.008

  resP@pmLabelBarOrthogonalPosF = -0.01
  resP@pmLabelBarParallelPosF = 0.

  ;resP@gsnPanelTop        = 0.97
  resP@gsnPanelBottom     = 0.1
  ;resP@gsnPanelRight     = 0.9007;
  ;resP@gsnPanelLeft     = 0.40        ; position of left most plot
  gsn_panel(wks,plot,(/nfiles,1/),resP)      

frame(wks)

end



