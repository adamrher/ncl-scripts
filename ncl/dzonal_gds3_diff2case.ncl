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

  meanflow = False
  tropics = True

  writencdf = True
  loadncdf = False

  VAR1  = (/"VMSE1","VMSE2"/)
  VAR2  = (/"VDSE1","VDSE2"/)
  VAR3  = (/ "RAT1", "RAT2"/)
  LAT   = (/"LAT1","LAT2"/)
  LATatt= (/"lat1","lat2"/)  

  yaxis = (/"Meridional MSE Flux (PW deg~S~-1~N~)","Meridional DSE Flux (PW deg~S~-1~N~)", "VDSE/VMSE (unitless)"/)

  ;;ymin = (/-2.,-2.,-10./)
  ;;ymax = (/ 2., 2., 50./)
  ymin = (/-1.,-2.,-100./)
  ymax = (/ 1., 2., 100./)

  cnsrv = 1 ;0 = bilinear remapping
	    ;1 = conservative remapping
  if (cnsrv.eq.0) then
    fname_out = fname(0)+"-2-"+fname(1)+".eflx2-bilin.nc"
  else if (cnsrv.eq.1) then
    fname_out = fname(0)+"-2-"+fname(1)+".eflx2-cnsrv.nc"
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

  factor = (/ 1.0, 1.0 /)

;---Start the graphics
  wks = gsn_open_wks("pdf","temp_gds")
  plot = new((/3/),graphic)

;---Plotting options for time series plot
  res             = True
  ;res@gsnMaximize = True
  res@gsnPaperOrientation = "landscape"

  res@gsnDraw     = False      ; Will draw later, after overlaying
  res@gsnFrame    = False      ; all plots
  res@xyLineThicknesses = 5
  res@vpWidthF    = 0.8        ; Make plots wider
  res@vpHeightF   = 0.5

  res@tmBorderThicknessF = 3
  res@tmXBMajorOutwardLengthF = 0.
  res@tmYLMajorOutwardLengthF = 0.
  res@tmXBMinorOutwardLengthF = 0.
  res@tmYLMinorOutwardLengthF = 0.
  res@tmXTMajorOutwardLengthF = 0.
  res@tmYRMajorOutwardLengthF = 0.
  res@tmXTMinorOutwardLengthF = 0.
  res@tmYRMinorOutwardLengthF = 0.

  if (tropics) then
    res@trXMinF     = sin(-30.*pi/180.)
    res@trXMaxF     = sin(30.*pi/180.)
  else
    res@trXMinF     = -1.
    res@trXMaxF     =  1.
  end if

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
  end if
  delete(dims)

  print("grabbing vars...")
  ;******************************************************
  ; ATM_BUDG = grad(F) + dE/dt
  ; Assume, dE/dt is zero and solve for F
  ;******************************************************

  V      = f[:]->V
  PS     = f[:]->PS

if (.not.meanflow) then
  VT	 = f[:]->VT
  VZ	 = f[:]->VZ
  VQ	 = f[:]->VQ

  VZ = VZ*factor(n)

  VMSE = cpd*VT + g*VZ + Lv*VQ
  VDSE = cpd*VT + g*VZ
  delete([/VT,VZ,VQ/])
else
  T     = f[:]->VT
  Z     = f[:]->VZ
  Q     = f[:]->VQ

  ;;;Z = Z*factor(n)

  MSE = cpd*T + g*Z + Lv*Q
  DSE = cpd*T + g*Z
  VMSE = V*MSE
  VDSE = V*DSE
  delete([/T,Z,Q,MSE,DSE/])
end if

  if (n.eq.0) then
        hyai = f[0]->hyai
        hybi = f[0]->hybi
        nlevs = dimsizes(f[0]->hyam)
        ilevs = dimsizes(hyai)

        ;;;compute dA and dB
        dA = hyai(1:ilevs-1) - hyai(0:ilevs-2)
        dB = hybi(1:ilevs-1) - hybi(0:ilevs-2)
  end if
  delete(f)

if (.not.latlon) then

  print("Computing MSE Flux...")

  ;;;compute v*mse*ps and v*mse*p0
  vmps = V
  vmps = 0.
  vdps = vmps
  do k = 0,nlevs-1
    vmps(:,k,:) = VMSE(:,k,:)*PS
    vdps(:,k,:) = VDSE(:,k,:)*PS
  end do 
  vmp0 = VMSE*p0
  vdp0 = VDSE*p0
  delete([/VMSE,VDSE/])

  ;;;integrate from top-down
  fmse_eta = PS
  fmse_eta = 0.
  fdse_eta = fmse_eta

  ktop = 0
  do k = ktop,nlevs-1
        fmse_eta = vmp0(:,k,:)*dA(k) + vmps(:,k,:)*dB(k) + fmse_eta
        fdse_eta = vdp0(:,k,:)*dA(k) + vdps(:,k,:)*dB(k) + fdse_eta
  end do
  fmse_eta = fmse_eta/g
  fdse_eta = fdse_eta/g

  delete([/vmp0,vmps,vdp0,vdps,V,PS/])

  print("time average...")
  fmse_bar = dim_avg_0_lowmem(fmse_eta,2)
  fdse_bar = dim_avg_0_lowmem(fdse_eta,2)
  delete([/fmse_eta,fdse_eta/])

  print("regridding integrals...")
  fmse_hat = ESMF_regrid_with_weights(fmse_bar,wgtpath,False)
  fdse_hat = ESMF_regrid_with_weights(fdse_bar,wgtpath,False)
  lat      = fmse_hat&lat
  nlat	   = dimsizes(lat)
  delete([/fmse_bar,fdse_bar/])

end if

  print("zonal average...")
  fmse_zon = dim_avg(fmse_hat)
  fdse_zon = dim_avg(fdse_hat)

  ;;Convert W/m to W/degree (factor of Re*lat/lat)
  fmse_zon = Re*fmse_zon
  fdse_zon = Re*fdse_zon

  var_bar = abs(fdse_zon)/abs(fmse_zon)

  if (n.eq.1) then
    wgtpath = get_wgt_path_res(nlat0,nlat)
    print("wgt path is " + wgtpath)
    if (wgtpath.eq."none") then
      var_bar_rgrid = var_bar
    else
      fmse_tmp = ESMF_regrid_with_weights(fmse_hat,wgtpath,False)
      fdse_tmp = ESMF_regrid_with_weights(fdse_hat,wgtpath,False)
      fmse_zon_rgrid = dim_avg(fmse_tmp)
      fdse_zon_rgrid = dim_avg(fdse_tmp)
      var_bar_rgrid = abs(fdse_zon_rgrid)/abs(fmse_zon_rgrid)
      delete([/fmse_tmp,fdse_tmp,fmse_zon_rgrid,fdse_zon_rgrid/])
    end if
  end if
  delete([/fdse_hat,fmse_hat/])

  if (n.eq.0) then
    var_bar0 = var_bar
    lat0   = lat
    nlat0  = nlat
  else if (n.eq.1) then
    dvar = var_bar_rgrid - var_bar0
    delete([/var_bar0,var_bar_rgrid/])
  end if
  end if


else if (loadncdf)
   print("Loading vars from " + fname_in)
   if (n.eq.0) then
     ncdf = addfile(fname_in , "r")
   end if

   fmse_zon= ncdf->$VAR1(n)$
   fdse_zon= ncdf->$VAR2(n)$
   var_bar = ncdf->$VAR3(n)$
   lat     = ncdf->$LAT(n)$

end if
end if

  print("max fmse_zon " + (max(fmse_zon)/1.e15))
  print("max fdse_zon " + (max(fdse_zon)/1.e15))
  print("max GMS " + max(var_bar))

  res@xyLineColors           = colors(n)
  if (n.eq.0) then
    res@trYMinF     = ymin(0)
    res@trYMaxF     = ymax(0)
    res@tiYAxisString          = yaxis(0)
    res@gsnYRefLine            = 0
    res@gsnYRefLineThicknessF  = 2
    plot(0) = gsn_csm_xy(wks,sin(lat*pi/180.),fmse_zon/(1.e15),res)
    delete(res@gsnYRefLine)
    res@trYMinF     = ymin(1)
    res@trYMaxF     = ymax(1)
    res@tiYAxisString          = yaxis(1)
    plot(1) = gsn_csm_xy(wks,sin(lat*pi/180.),fdse_zon/(1.e15),res)
    delete(res@gsnYRefLine)
    res@trYMinF     = ymin(2)
    res@trYMaxF     = ymax(2)
    res@tiYAxisString          = yaxis(2)
    res@gsnYRefLine            = 0
    plot(2) = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
  else
    rum = gsn_csm_xy(wks,sin(lat*pi/180.),fmse_zon/(1.e15),res)
    overlay(plot(0),rum)
    yum = gsn_csm_xy(wks,sin(lat*pi/180.),fdse_zon/(1.e15),res)
    overlay(plot(1),yum)
    dum = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
    overlay(plot(2),dum)
    delete([/rum,yum,dum/])

    res@xyLineColors = "black"
    ;;mum = gsn_csm_xy(wks,sin(lat0*pi/180.),dvar,res)
    ;;overlay(plot(2),mum)
    ;;delete(mum)
  end if

  if (writencdf) then
    if (n.eq.0) then
      system("/bin/rm -f "+fname_out)
      ncdf = addfile(fname_out,"c")
    end if
    fmse_zon!0= LATatt(n)
    fdse_zon!0 = LATatt(n)
    var_bar!0 = LATatt(n)
    lat!0     = LATatt(n)
    ncdf->$VAR1(n)$ = fmse_zon
    ncdf->$VAR2(n)$ = fdse_zon
    ncdf->$VAR3(n)$ = var_bar
    ncdf->$LAT(n)$ = lat
  end if
  delete([/lat,var_bar,fmse_zon,fdse_zon/])

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
  gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot

  frame(wks)

end
