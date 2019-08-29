;**************************************
;var_cam.ncl
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/gpfs/fs1/work/aherring/CESM2/arh-git-scripts/ncl/se_func_lib.ncl"
;**************************************
begin
;****************************************
  p0 = 1000.d2
  secpday = 60.*60.*24;
  pi = 3.14159265358979
  g = 9.80616
  Re = 6371.22
  cp = 1004.
  Rd = 287.
;****************************************

  dir   = dir
  fname = fname1
  fdate = ".cam."+fincl1+"*"
  nfiles= dimsizes(fname)

  VAR1 = VAR1
  factor = 1.

  ;;only use one history file
  onemnth = True
  nstart = 0

  ;;cell fill
  ;;*for non-standard se grids, set vpath to SCRIP grid file
  cellfill = False

  ;;regrid to lat-lon (for se grids only)
  ;;*for non-standard se grids, set wgtpath to the ESMF weight file
  regrid = False

  ;;number of contour levels
  cnlevs = 50.

  ;;set explicit contour levels
  explcn = False
  maxcn  = 10.
  mincn  = -10.

;************
;Main Loop
;************

do n = 0,nfiles-1

  print("begin case " + n)

  files = systemfunc ("ls " + dir + fname(n) + "/run/" + fname(n) + fdate)
  nf = dimsizes(files)
  if (onemnth) then
    nfinish = nstart
  else 
    nfinish = nf-1
  end if

  print("Loading Files")
  print(""+files(nstart:nfinish))
  f = addfiles(files(nstart:nfinish),"r")
  ListSetType(f,"cat")
  delete(files)

  print("Loading " + VAR1)
  VAR = f[:]->$VAR1$
  VAR = VAR*factor

  lat1d = f[0]->lat
  lon1d = f[0]->lon
  TIME  = f[:]->time

  if (isfilevardim(f[0],VAR1,"lat")) then
    print("NETCDF is on lat-lon grid")
    latlon = True
  else if (isfilevardim(f[0],VAR1,"ncol")) then
    print("NETCDF is on native se-grid")
    latlon = False
  else
    print("exiting: unrecognized grid")
    exit
  end if
  end if
  delete(f)

  if (.not.latlon .and. regrid) then
    print("regridding to latlon grid")
    ncol = dimsizes(VAR(0,:))
    wgtpath = get_wgt_path(ncol,ncol,0) 
    print("wgtpath " + wgtpath)
    tmp = ESMF_regrid_with_weights(VAR,wgtpath,False)
    delete([/VAR,lat1d,lon1d/])

    lat1d = tmp&lat
    lon1d = tmp&lon
    VAR = tmp
    delete(tmp)
    
    latlon = True
  end if

end do

print("max var: " + max(VAR))
print("min var: " + min(VAR))

if (.not.explcn) then
  maxcn = max(VAR)
  mincn = min(VAR)
end if
cnspc  = (maxcn-mincn)/cnlevs

if (.not.latlon .and. cellfill) then
  print("CellFill on")

  ncol = dimsizes(VAR(0,:))
  vpath = get_vertices(ncol,ncol)
  print("vpath:" + vpath)
  sf = addfile(vpath,"r")

  latvert = sf->grid_corner_lat
  lonvert = sf->grid_corner_lon
  delete(sf)
else if (latlon .and. cellfill) then
  print("CellFill on")
end if
end if

;**************
;time loop
;**************

wkstype = "png"
ntime = dimsizes(TIME)
do t0 = 0,ntime-1

    time = TIME(t0)
    print("t = " + t0 + "/" + (ntime-1))
    wks = gsn_open_wks(wkstype,sprinti("%0.3i", t0))
    gsn_define_colormap(wks,"BkBlAqGrYeOrReViWh200")
    plot = new( (/1/), graphic)
    gsn_reverse_colormap(wks)

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

    res@vpWidthF  = 1.0
    res@vpHeightF = 0.5

    res@mpOutlineOn          = False    ; turn off continental outline
    res@mpFillOn             = False
    res@mpGridAndLimbOn   = True           ; turn on lat/lon lines
    ;res@mpGridLatSpacingF = 10.
    ;res@mpGridLonSpacingF = 30.
    res@mpGridLineColor      = -1
    res@mpPerimOn         = False               ; turn off perimeter
    res@mpFillOn         = False
    res@mpOutlineBoundarySets     = "NoBoundaries"
    res@mpProjection = "CylindricalEquidistant"
    res@mpCenterLonF = 0.
 
;************************************************
; plotting
;************************************************

  if (.not.latlon .and. cellfill) then
    res@cnFillMode = "CellFill"
    res@sfXCellBounds = lonvert
    res@sfYCellBounds = latvert
  else if (latlon .and. cellfill) then
    res@cnFillMode = "RasterFill"
  else
    res@cnFillMode = "AreaFill"
  end if
  end if

  if (.not.latlon) then
    var = VAR(t0,:)
    res@sfXArray = lon1d
    res@sfYArray = lat1d
  else
    var = VAR(t0,:,:)
    var!0 = "lat"
    var!1 = "lon"
    var&lat = lat1d
    var&lon = lon1d
    var&lat@units = "degrees north"
    var&lon@units = "degrees east"
  end if

  if (regrid) then
    res@gsnAddCyclic = False
  end if

  res@cnLevelSelectionMode = "ManualLevels"
  res@cnMinLevelValF  = mincn
  res@cnMaxLevelValF  = maxcn
  res@cnLevelSpacingF = cnspc

  plot(0) = gsn_csm_contour_map(wks,var,res)

;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot

  resP@gsnMaximize = True

  resP@gsnPanelFigureStrings = (/"day " + sprintf("%0.2f", time)/)
  resP@gsnPanelFigureStringsFontHeightF = 0.015
  resP@gsnPanelFigureStringsPerimOn     = True
  resP@gsnPanelFigureStringsBackgroundFillColor = "white"
  resP@amJust           = "BottomRight"

  resP@gsnPanelLabelBar = True
  resP@lbBoxSeparatorLinesOn= False
  resP@gsnPanelBottom   = 0.1
  resP@lbTitleString              = VAR1
  resP@lbTitlePosition            = "Bottom"
  resP@lbTitleFontHeightF         = 0.02
  resP@lbLabelFontHeightF         = 0.01

  gsn_panel(wks,plot,(/1,1/),resP)      
  frame(wks)

  delete([/wks,plot,res,resP,var/])

end do

end



