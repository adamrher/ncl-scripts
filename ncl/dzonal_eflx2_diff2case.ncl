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

  tropics = True
  psivert = True
  meanflow = False

  writencdf = True
  loadncdf = False

  VAR1  = (/"FLX1","FLX2"/)
  VAR2  = (/"PSI1","PSI2"/)
  VAR3  = (/"GMS1","GMS2"/)
  LAT   = (/"LAT1","LAT2"/)
  LATatt= (/"lat1","lat2"/)  

  yaxis = (/"Meridional Energy Flux (PW deg~S~-1~N~)","PSI MAX (kg/s)", "GMS (Kelvin)"/)

  if (meanflow) then
    ymin = (/-0.8,0.    ,-2./)
    ymax = (/ 0.8,1.5e11,20./)
    mtag = "MSE"
    print("We will compute V_bar * MSE_bar")
  else if (psivert) then
    ymin = (/-2.,0.    , -2./)
    ymax = (/ 2.,1.5e11, 60./)
    mtag = "VMSE"
    print("We will compute V * MSE, which includes eddy terms")
  else
    ymin = (/-2.,0.    , -2./)
    ymax = (/ 2.,1.5e11, 80./)
    mtag = "VMSE"
    print("We will compute V * MSE, which includes eddy terms")
  end if
  end if

  cnsrv = 1 ;0 = bilinear remapping
	    ;1 = conservative remapping
  if (cnsrv.eq.0) then
    fname_out = fname(0)+"-2-"+fname(1)+".eflx2-bilin-"+mtag+".nc"
  else if (cnsrv.eq.1) then
    fname_out = fname(0)+"-2-"+fname(1)+".eflx2-cnsrv-"+mtag+".nc"
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
  ;;factor = (/ 1.0, 1.0 /)

;---Start the graphics
  wks = gsn_open_wks("pdf","temp_eflx")
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
    res@trXMinF     = sin(-30.*pi/180)
    res@trXMaxF     = sin(30.*pi/180) 

    if (meanflow) then
      ymin = (/-0.8,0.    ,-2./)
      ymax = (/ 0.8,1.5e11,20./)
      mtag = "MSE"
      print("We will compute V_bar * MSE_bar")
    else if (psivert) then
      ymin = (/-1.,0.    , -2./)
      ymax = (/ 1.,1.5e11, 30./)
      mtag = "VMSE"
      print("We will compute V * MSE, which includes eddy terms")
    else
      ymin = (/-1.,0.    , -2./)
      ymax = (/ 1.,1.5e11, 30./)
      mtag = "VMSE"
      print("We will compute V * MSE, which includes eddy terms")
    end if
    end if

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

  if (meanflow) then
    T      = f[:]->T
    Z      = f[:]->Z3
    Q      = f[:]->Q
    Q	 = Q/(1-Q) ;;;specific humiidty -> mixing ratio
    ;;CLDICE = f[:]->CLDICE
    CLDICE = 0.

    MSE    = cpd*T + g*Z + Lv*Q
    ;;;MSE    = f[:]->SL
    delete([/T,Z,Q,CLDICE/])
  else
    VT	   = f[:]->VT
    VZ	   = f[:]->VZ
    VQ	   = f[:]->VQ

    VZ = VZ*factor(n)

    VMSE   = cpd*VT + g*VZ + Lv*VQ
    delete([/VT,VZ,VQ/])
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
    if (meanflow) then
      vmps(:,k,:) = V(:,k,:)*MSE(:,k,:)*PS
    else
      vmps(:,k,:) = VMSE(:,k,:)*PS
    end if
  end do
  
  if (meanflow) then
    vmp0 = V*MSE*p0
  else
    vmp0 = VMSE*p0
  end if

  ;;;integrate from top-down
  fmse_eta = PS
  fmse_eta = 0.

  ktop = 0
  do k = ktop,nlevs-1
        fmse_eta = vmp0(:,k,:)*dA(k) + vmps(:,k,:)*dB(k) + fmse_eta
  end do
  fmse_eta = fmse_eta/g

  if (meanflow) then
    delete([/vmp0,vmps,V,MSE/])
  else
    delete([/vmp0,vmps,V,VMSE/])
  end if

  print("time average...")
  fmse_bar = dim_avg_0_lowmem(fmse_eta,2)
  delete(fmse_eta)

  print("regridding integrals...")
  psi_hat  = ESMF_regrid_with_weights(psi_bar,wgtpath,False)
  fmse_hat = ESMF_regrid_with_weights(fmse_bar,wgtpath,False)
  PS_rgrid  = ESMF_regrid_with_weights(PS,wgtpath,False)
  lat      = fmse_hat&lat
  nlat	   = dimsizes(lat)
  delete([/psi_bar,fmse_bar,PS/])

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
  psi_zon = abs(psi_zon)

  if (.not.psivert) then
    psi_max = fmse_zon
    psi_max = 0.
    do i = 0,nlat-1
       psi_max(i) = max(psi_zon(:,i))
    end do

  else
    ;;;try something new
    abspsi = abs(psi_zon)
    pszon = dim_avg(PS_rgrid)
    psbar = dim_avg_0_lowmem(pszon,2)

    psiv = psbar
    psiv = 0.
    do k = 0,nlevs-1
      psiv(:) = abspsi(k,:)*p0*dA(k) + abspsi(k,:)*psbar*dB(k) + psiv
    end do
    psi_max = psiv/psbar
    delete([/abspsi,PS_rgrid,pszon,psbar,psiv/])
  end if
  delete(psi_zon)

  var_bar = abs(fmse_zon)/psi_max
  var_bar = var_bar/cpd

else if (loadncdf)
   print("Loading vars from " + fname_in)
   if (n.eq.0) then
     ncdf = addfile(fname_in , "r")
   end if

   fmse_zon= ncdf->$VAR1(n)$
   psi_max = ncdf->$VAR2(n)$
   var_bar = ncdf->$VAR3(n)$
   lat     = ncdf->$LAT(n)$
end if
end if

  print("max psi_max " + max(psi_max))
  print("max fmse_zon " + (max(fmse_zon)/1.e15))
  print("max GMS " + max(var_bar))

  res@xyLineColors           = colors(n)
  if (n.eq.0) then
    res@trYMinF     = ymin(0);;;-0.8e15 ;;-6.e15
    res@trYMaxF     = ymax(0);;; 0.8e15 ;;6.e15
    res@tiYAxisString          = yaxis(0)
    res@gsnYRefLine            = 0
    res@gsnYRefLineThicknessF  = 2
    plot(0) = gsn_csm_xy(wks,sin(lat*pi/180.),fmse_zon/(1.e15),res)
    delete(res@gsnYRefLine)
    res@trYMinF     = ymin(1)
    res@trYMaxF     = ymax(1)
    res@tiYAxisString          = yaxis(1)
    plot(1) = gsn_csm_xy(wks,sin(lat*pi/180.),psi_max,res)
    delete(res@gsnYRefLine)
    res@trYMinF     = ymin(2)
    res@trYMaxF     = ymax(2)
    res@tiYAxisString          = yaxis(2)
    res@gsnYRefLine            = 0
    plot(2) = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
  else
    rum = gsn_csm_xy(wks,sin(lat*pi/180.),fmse_zon/(1.e15),res)
    overlay(plot(0),rum)
    yum = gsn_csm_xy(wks,sin(lat*pi/180.),psi_max,res)
    overlay(plot(1),yum)
    dum = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
    overlay(plot(2),dum)
    delete([/rum,yum,dum/])
  end if

  if (writencdf) then
    if (n.eq.0) then
      system("/bin/rm -f "+fname_out)
      ncdf = addfile(fname_out,"c")
    end if
    var_bar!0 = LATatt(n)
    fmse_zon!0= LATatt(n)
    psi_max!0 = LATatt(n)
    lat!0     = LATatt(n)
    ncdf->$VAR1(n)$ = fmse_zon
    ncdf->$VAR2(n)$ = psi_max
    ncdf->$VAR3(n)$ = var_bar
    ncdf->$LAT(n)$ = lat
  end if
  delete([/lat,var_bar,fmse_zon,psi_max/])

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
