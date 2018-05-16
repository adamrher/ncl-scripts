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

  secpday = 60.*60.*24;
  pi = 3.14159265358979
  g = 9.80616 ;m/s2
  p0 = 1.d5 ;Pa
  Re = 6.37122e6
  g = 9.80616 ;m/s2
  cpd = 1.00464e3
  Lv  = 2.501e6
  Lf  = 3.337e5

  colors = (/"magenta","darkorchid4","blue","green","deepskyblue1"/)

  yaxis = "GMS"

;---Start the graphics
  wks = gsn_open_wks("pdf","temp_dgms")
  plot = new((/1/),graphic)

;---Plotting options for time series plot
  res             = True
  ;res@gsnMaximize = True
  res@gsnPaperOrientation = "landscape"

  res@gsnDraw     = False      ; Will draw later, after overlaying
  res@gsnFrame    = False      ; all plots
  res@xyLineThicknesses = 5
  res@vpWidthF    = 0.8        ; Make plots wider
  res@vpHeightF   = 0.5

  res@tmBorderThicknessF = 4 ;axes thickness
  res@tmXBMajorOutwardLengthF = 0.
  res@tmYLMajorOutwardLengthF = 0.
  res@tmXBMinorOutwardLengthF = 0.
  res@tmYLMinorOutwardLengthF = 0.
  res@tmXTMajorOutwardLengthF = 0.
  res@tmYRMajorOutwardLengthF = 0.
  res@tmXTMinorOutwardLengthF = 0.
  res@tmYRMinorOutwardLengthF = 0.

  res@trXMinF     = -1.
  res@trXMaxF     = 1.
  res@tmXBMode        = "Explicit"
   xticks = new((/19/),float)
   do i = 0,19-1
     tmp = (i-9)*10.
     xticks(i) = sin(tmp*pi/180.)
   end do
  res@tmXBValues      = xticks
  res@tmXBLabels      = (/"","-80","","-60","","-40","","-20","","0","","20","","40","","60","","80",""/)

;****************
;Begin Loop
;****************

do n = 0,nfiles-1
print("Begin case " +n)

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

  if (isfilevardim(f[0],"PRECC","ncol")) then
    print("*history fields are on native grid")
    latlon = False
    dims = getfilevardimsizes(f[0],"PRECC")
    ncol = dims(1)
    wgtpath = get_wgt_path(ncol)
    delete(dims)
  else
    print("*history fields are on lat-lon grid")
    latlon = True
  end if

  print("grabbing vars...")
  T      = f[:]->T
  Z      = f[:]->Z3
  Q      = f[:]->Q
  CLDICE = f[:]->CLDICE

  V	 = f[:]->V
  PS	 = f[:]->PS

  lat = f[0]->lat

  if (n.eq.0) then
        hyai = in[0]->hyai
        hybi = in[0]->hybi
        nlevs = dimsizes(f{0]->hyam)
        ilevs = dimsizes(hyai)

        ;;;compute dA and dB
        dA = hyai(1:ilevs-1) - hyai(0:ilevs-2)
        dB = hybi(1:ilevs-1) - hybi(0:ilevs-2)
  end if
  delete(f)

  MSE = cpd*T + g*Z + Lv*Q + Lf*CLDICE
  delete([/T,Z,Q,CLDICE/])

  ;**********************************************************
  ;** Compute vertical integrals on native grid *************
  ;** psi(p,lat) = 2*pi*re*cos(lat)/g * int_0-p(v*p0)dA + int0-p(v*ps)dB **
  ;** fmse(lat)  = (int(m*v*p0)dA + int(m*v*ps)dB)/g 
  ;**********************************************************

if (.not.latlon) then 

  print("computing stream function...")

  ;;;compute v*ps and v*p0
  vps = V
  vps = 0.
  do k = 0,nlevs-1
    vps(:,k,:) = V(:,k,:)*PS
  end do
  vp0 = p0*V

  ;;;integrate from top-down
  psi_int = todouble(vps)
  psi_int = 0.
  tmp = new( (/ntime,ncol/),"double" )

  do k = 0,nlevs-1
        tmp = 0.
        do l = k,nlevs-1
                tmp = vp0(:,l,:)*dA(l) + vps(:,l,:)*dB(l) + tmp
        end do
        psi_int(:,k,:) = tmp
  end do
  delete/[(tmp,vps,vp0/])

  print("computing mse flux...")

  ;;;compute v*mse*ps and v*mse*p0
  vmps = V
  vmps = 0.
  do k = 0,nlevs-1
    vps(:,k,:) = V(:,k,:)*MSE(:,k,:)*PS
  end do
  vmp0 = V*MSE*p0

  ;;;integrate from top-down
  fmse_eta = PS
  fmse_eta = 0.

  do k = 0,nlevs-1
        fmse_eta = vmp0(:,l,:)*dA(l) + vmps(:,l,:)*dB(l) + fmse_eta
  end do
  delete([/vmp0,vmps/])
  fmse_eta = fmse_eta/g

  print("regridding integrals...")
  psi_hat  = ESMF_regrid_with_weights(psi_eta,wgtpath,False)
  fmse_hat = ESMF_regrid_with_weights(fmse_eta,wgtpath,False)
  delete(lat)
  lat	   = fmse_hat&lat
  delete([/psi_eta,fmse_eta,PS/])  

else

  print("NETCDF is on latlon grid")
  ;;print("exiting...")
  ;;exit

  print("computing stream function...")

  ;;;compute v*ps and v*p0
  vps = V
  vps = 0.
  do k = 0,nlevs-1
    vps(:,k,:,:) = V(:,k,:,:)*PS
  end do
  vp0 = p0*V

  ;;;integrate from top-down
  psi_int = todouble(vps)
  psi_int = 0.
  tmp = new( (/ntime,nlat,nlon/),"double" )

  do k = 0,nlevs-1
        tmp = 0.
        do l = k,nlevs-1
                tmp = vp0(:,l,:,:)*dA(l) + vps(:,l,:,:)*dB(l) + tmp
        end do
        psi_int(:,k,:,:) = tmp
  end do
  delete/[(tmp,vps,vp0/])

  print("computing mse flux...")

  ;;;compute v*mse*ps and v*mse*p0
  vmps = V
  vmps = 0.
  do k = 0,nlevs-1
    vps(:,k,:,:) = V(:,k,:,:)*MSE(:,k,:,:)*PS
  end do
  vmp0 = V*MSE*p0

  ;;;integrate from top-down
  fmse_eta = PS
  fmse_eta = 0.

  do k = 0,nlevs-1
        fmse_eta = vmp0(:,l,:,:)*dA(l) + vmps(:,l,:,:)*dB(l) + fmse_eta
  end do
  delete([/vmp0,vmps/])
  fmse_eta = fmse_eta/g

end if

  delete([/MSE,PS,V/])
  nlat = dimsizes(lat)

  print("time average...")
  psi_bar = dim_avg_0_lowmem(psi_hat,3)
  fmse_bar= dim_avg_0_lowmem(fmse_hat,2)
  delete([/psi_hat,fmse_hat/])

  print("zonal avg...")
  psi_zon = dim_avg(psi_bar)
  fmse    = dim_avg(fmse_bar)
  delete([psi_bar,fmse_bar/])

  ;;multiply by cnst to get psi
  do k = 0,nlevs-1
    psi_zon(k,:) = 2*pi*Re*cos(lat*pi/180.)*psi_zon(k,:)/g 
  end do
  psi_zon = abs(psi_zon)

  ;;find psi max
  psi_max = fmse
  psi_max = 0.
  do i = 0,nlat-1
     psimax(i) = max(psi_zon(:,i))    
  end do

  ;;compute GMS
  var_bar = abs(fmse)/psimax
  delete([/fmse,psimax,psi_zon/])

  res@xyLineColors           = colors(n)
  if (n.eq.0) then
    ;;;res@trYMinF     = 0.
    ;;;res@trYMaxF     = 18.
    res@tiYAxisString          = yaxis
    plot(0) = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
    delete(res@tiYAxisString)
  else
    dum = gsn_csm_xy(wks,sin(lat*pi/180.),var_bar,res)
    overlay(plot(0),dum)
    delete(dum)
  end if

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
  gsn_panel(wks,plot,(/1,1/),resP)               ; now draw as one plot

  frame(wks)

end
