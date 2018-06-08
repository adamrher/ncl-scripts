;**************************************
;FHS94topo
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;;load "/glade/p/work/aherring/CESM2/arh-git-scripts/ncl/se_func_lib.ncl"
load "/home/aherring/arh-git-scripts/ncl/se_func_lib.ncl"
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
  titles = fname

  onemnth = False
  nstart = 0

  VAR = (/"OMEGA","OMEGA"/)
  varlev = (/22,19/) ;;23-1 And, 20-1 Him
  factor = secpday/100.
  LAT = (/"lat","lat"/)
  LON = (/"lon","lon"/)

  manlevs = True
  mag = 1.
  cmin = (/-150. /)*mag
  cmax = (/ 150. /)*mag
  cspc = (/   4. /)*mag

  cellfill = True

  labels = new( (/2*nfiles/), string)
  do i = 0,nfiles-1
    labels(i) = "784 hPa"
    labels(nfiles + i) = "524 hPa"
  end do

  varNam = (/"~F33~w~F21~ (hPa/day)"/)

  ;;;region
  lat1 = (/ -45., 15./) ;;And
  lon1 = (/ -100.,-40./) ;
  lat2 = (/   0., 60./) ;;Him 0.,55.
  lon2 = (/  50.,110./) ; 60.,120.

  writencdf = True
  fname_out = "fhstopo-contours.nc"
  andnams = (/"and1","and2"/)
  hindnams = (/"hind1","hind2"/)
  latnams = (/"lat1","lat2"/)
  lonnams = (/"lon1","lon2"/)

  pltNam = "temp_fhstopo"

;************** 
;graphics stuff
;**************
  wkstype = "pdf"
  wks = gsn_open_wks(wkstype,pltNam)
  gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200") ;;"3saw") ;;"BkBlAqGrYeOrReViWh200");;"gui_default");;"MPL_gist_rainbow")
  ;gsn_define_colormap(wks,"MPL_hsv")
  ;wkstype@wkBackgroundOpacityF    = 0.
  gsn_reverse_colormap(wks)
  setvalues NhlGetWorkspaceObjectId()
      "wsMaximumSize": 500000000
  end setvalues

  plot = new( (/2*nfiles/), graphic)
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

   if (cellfill) then
     res@cnFillMode = "CellFill"
   end if

   ;res@mpCenterLonF = 180.
   ;res@mpOutlineOn          = False    ; turn off continental outline
   res@mpGridAndLimbOn   = False           ; turn on lat/lon lines
   res@mpGridLatSpacingF = 5.
   res@mpGridLonSpacingF = 30.
   ;res@mpGridLineColor      = -1
   ;res@mpPerimOn         = False               ; turn off perimeter
   ;res@mpFillOn         = True
   ;;res@mpOutlineBoundarySets     = "NoBoundaries"
   ;;res@mpProjection = "Orthographic";;"Mollweide"

  ;;add titles
  txres = True
  txres@txFontHeightF = 0.010
  txres@txJust = "CenterCenter"
  yy = (/ 0.915,0.915 /)
  xx = (/ 0.325,0.705 /)

;************
;Main Loop
;************
 do n = 0,nfiles-1
 
 print("begin case "+n)

 ;load all files
 files = systemfunc ("ls " + dir + fname(n) + rdir(n) + fname(n) + fdate(n))
 nf = dimsizes(files)
 if (onemnth) then
   nfinish = nstart
 else
   nfinish = 10;;;nf-1
 end if

 print("load files...")
 print(files(nstart:nfinish))

 f  = addfiles (files(nstart:nfinish),"r")
 ListSetType(f,"cat")
 delete(files)

 if (isfilevardim(f[0],"OMEGA","lon")) then
   print("*history fields must be on native se-grid*")
   print("exiting...")
   exit
 end if

 print("Grab var...")
 ntime = dimsizes(f[:]->time)

 lat1d = f[0]->$LAT(n)$
 lon1d = f[0]->$LON(n)$
 ncol = dimsizes(lat1d)

 if (isfilevardim(f[0],"OMEGA_gll","ncol_d")) then
   dims = getfilevardimsizes(f[0],"OMEGA_gll") 
   ncol_d = dims(2)
   delete(dims)
 else
   ncol_d = ncol
 end if
 print("ncol_d " + ncol_d)

 var1 = f[:]->$VAR(n)$(:,varlev(0),:)
 var2 = f[:]->$VAR(n)$(:,varlev(1),:)
 var1 = factor*var1
 var2 = factor*var2
 delete(f)

 print("dim_avg_0...")
 bar1 = dim_avg_0_lowmem(var1,2) 
 bar2 = dim_avg_0_lowmem(var2,2)
 delete(var1)
 delete(var2)

 print("plotting...")
 
 res@sfXArray = lon1d
 res@sfYArray = lat1d

 if (cellfill) then
   print("CellFill on")
   vpath = get_vertices(ncol,ncol_d)
   sf = addfile(vpath,"r")
   latvert = sf->grid_corner_lat 
   lonvert = sf->grid_corner_lon 
   res@sfXCellBounds = lonvert
   res@sfYCellBounds = latvert
   delete([/sf,latvert,lonvert,vpath/])
 end if

 if (manlevs) then
   res@cnLevelSelectionMode = "ManualLevels"
   res@cnMinLevelValF  = cmin(0)
   res@cnMaxLevelValF  = cmax(0)
   res@cnLevelSpacingF = cspc(0)
 end if

 andind = n
 himind = nfiles + n

 res@mpMinLonF = lon1(0)
 res@mpMaxLonF = lon1(1)
 res@mpMinLatF = lat1(0)
 res@mpMaxLatF = lat1(1)

 plot(andind) = gsn_csm_contour_map(wks,bar1,res)

 res@mpMinLonF = lon2(0)
 res@mpMaxLonF = lon2(1)
 res@mpMinLatF = lat2(0)
 res@mpMaxLatF = lat2(1)

 plot(himind) = gsn_csm_contour_map(wks,bar2,res) 

 if (writencdf) then
   if (n.eq.0) then
     system("/bin/rm -f "+fname_out)
     ncdf = addfile(fname_out , "c")
   end if
   ncdf->$andnams(n)$ = bar1
   ncdf->$hindnams(n)$ = bar2
   if (n.eq.nfiles-1) then
     ;;attribute name ncol conflicts with other cases
     lat1d!0 = "ncl6"
     lon1d!0 = "ncl6"
   end if
   ncdf->$latnams(n)$ = lat1d(:)
   ncdf->$lonnams(n)$ = lon1d(:)
 end if

 delete(bar1)
 delete(bar2)
 delete(lat1d)
 delete(lon1d)
 delete(res@sfXArray)
 delete(res@sfYArray)
 delete([/res@sfXCellBounds,res@sfYCellBounds/])

 gsn_text_ndc(wks,titles(n),xx(n),yy(n),txres)

end do ;nfiles

;;;drawNDCGrid(wks)
;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot

  resP@gsnPanelFigureStrings = labels
  resP@gsnPanelFigureStringsFontHeightF = 0.010
  resP@gsnPanelFigureStringsPerimOn     = True
  resP@gsnPanelFigureStringsBackgroundFillColor = "white"
  resP@amJust           = "TopRight"

  resP@gsnPanelLabelBar = True
  resP@lbTitleString              = varNam
  resP@lbTitlePosition            = "Bottom"
  resP@lbTitleFontHeightF         = 0.015
  resP@lbLabelFontHeightF         = 0.008
  resP@lbBoxSeparatorLinesOn = False

  resP@pmLabelBarOrthogonalPosF = -0.01
  resP@pmLabelBarParallelPosF = 0.

  resP@gsnPanelTop        = 0.9
  resP@gsnPanelBottom     = 0.1
  ;resP@gsnPanelRight     = 0.9007;
  ;resP@gsnPanelLeft     = 0.40        ; position of left most plot
  gsn_panel(wks,plot,(/2,nfiles/),resP)      

frame(wks)

end



