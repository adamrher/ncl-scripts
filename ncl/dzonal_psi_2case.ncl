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

  plotgms = True

  writencdf = True
  loadncdf = False

  VAR1  = (/"PSI1","PSI2"/)
  VAR2  = (/"GMS3D1","GMS3D2"/)
  LAT   = (/"LAT1","LAT2"/)
  LATatt= (/"lat1","lat2"/)  

  cnsrv = 1 ;0 = bilinear remapping
	    ;1 = conservative remapping
  if (cnsrv.eq.0) then
    fname_out = fname(0)+"-2-"+fname(1)+".psi-bilin.nc"
  else if (cnsrv.eq.1) then
    fname_out = fname(0)+"-2-"+fname(1)+".psi-cnsrv.nc"
  end if
  end if
  fname_in  = fname_out

  secpday = 60.*60.*24;
  pi = 3.14159265358979
  p0 = 1.d5 ;Pa
  Re = 6.37122d6
  g = 9.80616 ;m/s2
  cpd = 1.00464d3
  Lv  = 2.501d6
  Lf  = 3.337d5

  colors = (/"magenta","darkorchid4","blue","green","deepskyblue1"/)

  factor = (/ 1.0/g, 1.0/g /)

;---Start the graphics
  wks = gsn_open_wks("pdf","temp_psi")
  plot = new((/2/),graphic)
  gsn_define_colormap(wks,"MPL_jet")
;---Plotting options for time series plot
  res             = True
  res@gsnMaximize = False
  res@gsnPaperOrientation = "landscape"

  res@gsnDraw     = False      ; Will draw later, after overlaying
  res@gsnFrame    = False      ; all plots
  res@vpWidthF    = 0.8        ; Make plots wider
  res@vpHeightF   = 0.5

  res@cnLevelSelectionMode = "ManualLevels"    ; manually set the contour levels with the following 3 resources

  res@cnMonoLineThickness = True
  res@cnLineThicknessF   = 1.5
  res@gsnContourZeroLineThicknessF = 3.                 ; doubles thickness of zero contour
  res@gsnContourNegLineDashPattern = 1          ; sets negative contours to dash pattern 1
  res@cnLineLabelsOn    = False              ; turn off line labels
  res@cnInfoLabelOn     = True                ; turn off info label

  res@gsnXAxisIrregular2Linear = True
  res@gsnYAxisIrregular2Linear = True

  res@tmBorderThicknessF = 4 ;axes thickness
  res@tmXBMajorOutwardLengthF = 0.
  res@tmYLMajorOutwardLengthF = 0.
  res@tmXBMinorOutwardLengthF = 0.
  res@tmYLMinorOutwardLengthF = 0.
  res@tmXTMajorOutwardLengthF = 0.
  res@tmYRMajorOutwardLengthF = 0.
  res@tmXTMinorOutwardLengthF = 0.
  res@tmYRMinorOutwardLengthF = 0.

  res@trYReverse            = True
  res@trYMinF            = 0.
  res@trYMaxF            = 1000.

  res@trXMinF     = -1.
  res@trXMaxF     = 1.
  res@tmXBMode        = "Explicit"
  xticks = new((/19/),float)
  do i = 0,19-1
    tmp = (i-9)*10.
    xticks(i) = sin(tmp*pi/180.)
  end do
  delete(tmp)
  res@tmXBValues      = xticks
  res@tmXBLabels      = (/"","-80","","-60","","-40","","-20","","0","","20","","40","","60","","80",""/)

;****************
;Begin Loop
;****************

do n = 0,nfiles-1
print("Begin case " +n)

if (.not.loadncdf) then

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

  if (isfilevardim(f[0],"PS","ncol")) then
    print("*history fields are on native grid")
    latlon = False
    dims = getfilevardimsizes(f[0],"PS")
    ncol = dims(1)
    wgtpath = get_wgt_path(ncol,cnsrv)
    print("wgtpath " + wgtpath)
  else
    print("*history fields are on lat-lon grid")
    latlon = True
    print("Lat-lon grid not supported. Exiting ...")
    exit

    dims = getfilevardimsizes(f[0],"PS")
    nlat = dims(1)
    nlon = dims(2)
  end if
  delete(dims)

  print("grabbing vars...")
  ;******************************************************
  ; ATM_BUDG = grad(F) + dE/dt
  ; Assume, dE/dt is zero and solve for F
  ;******************************************************

  V      = f[:]->V
  PS     = f[:]->PS

  VT	 = f[:]->VT
  VZ	 = f[:]->VZ
  VQ	 = f[:]->VQ

  VZ = VZ*factor(n)

  VMSE   = cpd*VT + g*VZ + Lv*VQ
  delete([/VT,VZ,VQ/])

  if (n.eq.0) then
        hyai = f[0]->hyai
        hybi = f[0]->hybi
        nlevs = dimsizes(f[0]->hyam)
        ilevs = dimsizes(hyai)

        ;;;compute dA and dB
        dA = hyai(1:ilevs-1) - hyai(0:ilevs-2)
        dB = hybi(1:ilevs-1) - hybi(0:ilevs-2)

        hyam = f[0]->hyam
        hybm = f[0]->hybm
        lev_p = p0*(hyam + hybm)
        lev_p!0         = "lev_p"
        lev_p&lev_p     =  lev_p
        lev_p@long_name = "Pressure (Pa)"
        lev_p@units     = "Pa"
        lev_p@positive  = "down"
  end if
  delete(f)

if (.not.latlon) then

  print("computing stream function on native grid...")
  
  ;;;compute v*ps and v*p0
  ;;; *if V or PS are floats, need to change to doubles
  vps = V
  vps = 0.
  do k = 0,nlevs-1
    vps(:,k,:) = V(:,k,:)*PS
  end do
  vp0 = p0*V

  ;;;integrate from top-down
  psi_hat = V
  psi_hat = 0.
  tmp = PS
  tmp = 0.

  do k = 0,nlevs-1
        tmp = 0.
        do l = k,nlevs-1
                tmp = vp0(:,l,:)*dA(l) + vps(:,l,:)*dB(l) + tmp
        end do
        psi_hat(:,k,:) = tmp
  end do
  delete([/tmp,vps,vp0/])

  print("time average...")
  psi_bar = dim_avg_0_lowmem(psi_hat,3)
  delete(psi_hat)

  print("Computing MSE Flux...")

  ;;;compute v*mse*ps and v*mse*p0
  vmps = V
  vmps = 0.
  do k = 0,nlevs-1
    vmps(:,k,:) = VMSE(:,k,:)*PS
  end do
  vmp0 = VMSE*p0

  ;;;integrate from top-down
  fmse_eta = PS
  fmse_eta = 0.

  ktop = 0
  do k = ktop,nlevs-1
        fmse_eta = vmp0(:,k,:)*dA(k) + vmps(:,k,:)*dB(k) + fmse_eta
  end do
  fmse_eta = fmse_eta/g

  delete([/vmp0,vmps,V,PS,VMSE/])

  print("time average...")
  fmse_bar = dim_avg_0_lowmem(fmse_eta,2)
  delete(fmse_eta)

  print("regridding integrals...")
  psi_hat  = ESMF_regrid_with_weights(psi_bar,wgtpath,False)
  fmse_hat = ESMF_regrid_with_weights(fmse_bar,wgtpath,False)
  lat      = fmse_hat&lat
  nlat	   = dimsizes(lat)
  delete([/psi_bar,fmse_bar/])

end if

  print("zonal average...")
  psi_zon = dim_avg(psi_hat)
  fmse_zon = dim_avg(fmse_hat)
  delete([/psi_hat,fmse_hat/])

  ;;Convert W/m to W/degree (factor of Re*lat/lat)
  fmse_zon = Re*fmse_zon

  print("computing psi-max...")
  ;;multiply by cnst to get psi
  do k = 0,nlevs-1
    psi_zon(k,:) = 2*pi*Re*cos(lat*pi/180.)*psi_zon(k,:)/g
  end do

  gms3d = conform(psi_zon,abs(fmse_zon),1) ;;;/Re?
  gms3d@_FillValue = default_fillvalue("double")
  psi_zon@_FillValue = default_fillvalue("double")
  psitmp= where(psi_zon.eq.0,psi_zon@_FillValue,psi_zon)

  gms3d = gms3d/(abs(psitmp))
  gms3d = gms3d/cpd
  delete([/fmse_zon,psitmp/])

  psi_zon!0 = "levs"
  psi_zon&levs = lev_p/100.
  psi_zon&levs@long_name = "Pressure (hPa)"
  psi_zon!1 = "lat"
  psi_zon&lat = sin(lat*pi/180.)

  gms3d!0 = "levs"
  gms3d&levs = lev_p/100.
  gms3d&levs@long_name = "Pressure (hPa)"
  gms3d!1 = "lat"
  gms3d&lat = sin(lat*pi/180.)

else if (loadncdf)
   print("Loading vars from " + fname_in)
   if (n.eq.0) then
     ncdf = addfile(fname_in , "r")
   end if

   psi_zon = ncdf->$VAR1(n)$
   gms3d   = ncdf->$VAR2(n)$
   lat     = ncdf->$LAT(n)$
end if
end if

  print("max psi " + max(psi_zon))
  print("max gms3d " + max(gms3d))

  if (plotgms) then
    res@cnFillOn          = True
    res@cnLinesOn         = False

    ;;res@cnLevelSelectionMode = "AutomaticLevels"
    res@cnMinLevelValF  = 0.
    res@cnMaxLevelValF  = 200.
    res@cnLevelSpacingF = 10.
    plot(n) = gsn_csm_contour(wks,gms3d,res)
  else
    res@cnFillOn          = False
    res@cnLinesOn         = True

    res@cnMinLevelValF  =-2.e11
    res@cnMaxLevelValF  = 2.e11
    res@cnLevelSpacingF = 5.e10
    plot(n) = gsn_csm_contour(wks,psi_zon,res)
  end if


  if (writencdf) then
    if (n.eq.0) then
      system("/bin/rm -f "+fname_out)
      ncdf = addfile(fname_out,"c")
    end if
    psi_zon!1= LATatt(n)
    gms3d!1  = LATatt(n)
    lat!0    = LATatt(n)
    ncdf->$VAR1(n)$ = psi_zon
    ncdf->$VAR2(n)$ = gms3d
    ncdf->$LAT(n)$ = lat
  end if
  delete([/lat,psi_zon,gms3d/])

print("done with file " + n)

end do ;nfiles

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
