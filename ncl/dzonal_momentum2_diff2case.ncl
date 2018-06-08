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
  dtag = ""

  plotvar = 3 ; 0 = psie
	      ; 1 = psit
	      ; 2 = Ro
	      ; 3 = psim
	      ; 4 = Ro = vort/f
	      ; 5 = EMFC

  plotang = True
  skip = (/8,16/)

  zeromiss = False ;zero missing values?

  writencdf = True
  writediag = True
  loadncdf = False

  VAR1  = (/"PSIE1","PSIE2"/)
  VAR2  = (/"PSIT1","PSIT2"/)
  VAR3  = (/"RO1","RO2"/)
  VAR4  = (/"PSIM1","PSIM2"/)
  VAR5  = (/"ROV1","ROV2"/)
  VAR6  = (/"ANG1","ANG2"/)
  VAR7  = (/"EMFC1","EMFC2"/)
  LATatt= (/"lat1","lat2"/)  

  cnsrv = 1 ;0 = bilinear remapping
	    ;1 = conservative remapping
  if (cnsrv.eq.0) then
    fname_out = fname(0)+"-2-"+fname(1)+".momentum-bilin-"+dtag+".nc"
  else if (cnsrv.eq.1) then
    fname_out = fname(1)+"-2-"+fname(1)+".momentum-cnsrv-"+dtag+".nc"
  end if
  end if
  fname_in  = fname_out

  if (writediag) then
    fname1_dout = fname(0)+".momementum-cnsrv"+dtag+".diags.nc"
    fname2_dout = fname(1)+".momementum-cnsrv"+dtag+".diags.nc"
    fname_dout = (/fname1_dout,fname2_dout/)

    PSIMAX   = (/"PSIMAXNH","PSIMAXSH"/)
    PSIEMAX   = (/"PSIEMAXNH","PSIEMAXSH"/)
    PSIMMAX   = (/"PSIMMAXNH","PSIMMAXSH"/)
    ROVMAX   = (/"ROVMAXNH","ROVMAXSH"/)
    ROBMAX   = (/"ROBMAXNH","ROBMAXSH"/)
    EMFC     = (/  "EMFCNH",  "EMFCSH"/)
  end if

  secpday = 86400. 
  Ssecpday = 86164.
  pi = 3.14159265358979
  omg_cnst = 2*pi/Ssecpday
  p0 = 1.d5 ;Pa
  Re = 6.37122d6
  g = 9.80616 ;m/s2
  cpd = 1.00464d3
  Lv  = 2.501d6
  Lf  = 3.337d5

;---Start the graphics
  wks = gsn_open_wks("pdf","temp_mom")
  plot = new((/2/),graphic)
  gsn_define_colormap(wks,"MPL_jet")

;---Plotting options for time series plot
  res             = True
  ;res@gsnMaximize = True
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

  if (plotvar.eq.2 .or. plotvar.eq.4 .or. plotvar.eq.5) then
   res@lbLabelBarOn        = True
   res@lbOrientation =   "Vertical"          ; vertical label bar
   res@cnInfoLabelOn     = False
  end if

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
    dims = getfilevardimsizes(f[0],"PS")
    ncol = dims(1)
    wgtpath = get_wgt_path(ncol,cnsrv)
    print("wgtpath " + wgtpath)
  else
    print("*history fields are on lat-lon grid")
    print("Lat-lon grid not supported. Exiting ...")
    exit
  end if
  delete(dims)

  print("grabbing vars...")
  ;******************************************************
  ;Computing equations 5, 6 and 7 in Merlis et al. (2013)
  ; (5) psi_eddy = -2*pi*a*cos(lat)/f * int S*dp/g
  ;	f = 2*omg*sin(lat)
  ;	S = SY + SP
  ;	SY = 1/(a*cos^2(lat)) * d(u'v'_bar*cos^2(lat))/dlat 
  ;     SP = d(u'omg'_bar)/dp
  ;
  ; (6) psi_mean = -2*pi*a*cos(lat)/f * int M*dp/g
  ;	M = MY + MP
  ;     MY = 1/(a*cos^2(lat)) * v_bar * d(u_bar*cos^2(lat))/dlat
  ;	MP = omg_bar * d(U_bar)/dp
  ;******************************************************

  PS     = f[:]->PS
  U	 = f[:]->U
  V      = f[:]->V
  VU	 = f[:]->VU
  OMEGAU = f[:]->OMEGAU
  OMEGA = f[:]->OMEGA

  lat1d  = f[0]->lat

  if (n.eq.0) then
        hyai = f[0]->hyai
        hybi = f[0]->hybi
        ilevs = dimsizes(hyai)

        hyam = f[0]->hyam
        hybm = f[0]->hybm
        nlevs = dimsizes(f[0]->hyam)

        ;;;compute dA and dB
        dA = hyai(1:ilevs-1) - hyai(0:ilevs-2)
        dB = hybi(1:ilevs-1) - hybi(0:ilevs-2)

        lev_p = p0*(hyam + hybm)
        lev_p!0         = "lev_p"
        lev_p&lev_p     =  lev_p
        lev_p@long_name = "Pressure (Pa)"
        lev_p@units     = "Pa"
        lev_p@positive  = "down"
  end if
  delete(f)

  UpVp   = VU - (U*V)
  delete(VU)

  UpWp   = OMEGAU - (U*OMEGA)
  delete([/OMEGAU,OMEGA/])

  print("  compute vertical derivatives on native grid...")
  pm = se_pressure(PS,p0,hyam,hybm,0)
  dUWdp =  center_finite_diff_n(UpWp,pm,False,0,1)
  delete(UpWp)

  print("  Regridding...")
  U_rgrid     = ESMF_regrid_with_weights(U,wgtpath,False)
  V_rgrid     = ESMF_regrid_with_weights(V,wgtpath,False)
  PS_rgrid    = ESMF_regrid_with_weights(PS,wgtpath,False)
  UpVp_rgrid  = ESMF_regrid_with_weights(UpVp,wgtpath,False)
  dUWdp_rgrid = ESMF_regrid_with_weights(dUWdp,wgtpath,False)
  PM_rgrid    = ESMF_regrid_with_weights(pm,wgtpath,False)

  lat = V_rgrid&lat
  lon = V_rgrid&lon
  delete([/U,V,UpVp,dUWdp,lat1d,PS,pm/])

  print("  Computing momentum flux terms on lat-lon grid")

  latrad = lat*pi/180.

  ;;multiple by cnst
  lat3d  = conform(V_rgrid,latrad,2)
  UpVp_rgrid = (cos(lat3d)^2) * UpVp_rgrid

  ;;compute dUpVpdlat
  dUVdy = UpVp_rgrid
  dUVdy = 0.
  dVUdy = dUVdy

  ;;centered difference
  dUVdy =  center_finite_diff_n(UpVp_rgrid,latrad,True,0,2)

  ;;multiply by cnst
  Ycnst = 1/(Re*(cos(lat3d))^2)
  SY = Ycnst * dUVdy

  print("  max SY " + max(SY))

  ;;need the correct vars!
  SP = dUWdp_rgrid
  delete(dUWdp_rgrid)

  S = SY + SP
  delete([/UpVp_rgrid,Ycnst,dUVdy,dVUdy,SY,SP/])

  print("  Computing stream functions")

  ;;;compute S*ps and S*p0
  sps = S
  sps = 0.
  vps = sps
  do k = 0,nlevs-1
    sps(:,k,:,:) = S(:,k,:,:)*PS_rgrid
    vps(:,k,:,:) = V_rgrid(:,k,:,:)*PS_rgrid
  end do
  sp0 = p0*S
  vp0 = p0*V_rgrid

  ;;;integrate from top-down
  psi_hate = sps
  psi_hate = 0.
  psi_hatt = psi_hate
  tmpe = PS_rgrid
  tmpe = 0.
  tmpt = tmpe
  delete(PS_rgrid)

  do k = 0,nlevs-1
        tmpe = 0.
        tmpt = 0.
        do l = k,nlevs-1
                tmpe = sp0(:,l,:,:)*dA(l) + sps(:,l,:,:)*dB(l) + tmpe
                tmpt = vp0(:,l,:,:)*dA(l) + vps(:,l,:,:)*dB(l) + tmpt
        end do
        psi_hate(:,k,:,:) = tmpe
        psi_hatt(:,k,:,:) = tmpt
  end do
  delete([/tmpe,tmpt,sps,sp0,vps,vp0/])

  print("  computing vorticity")
  lonrad = lon*pi/180.
  U_rgrid = cos(lat3d) * U_rgrid

  ;;centered differences
  dVdx = center_finite_diff_n(V_rgrid,lonrad,True,0,3)
  dUdy = center_finite_diff_n(U_rgrid,latrad,True,0,2)

  vort = dVdx - dUdy
  vort = 1/(Re*cos(lat3d)) * vort
  delete([/lon,lonrad,V_rgrid,lat3d,dUdy,dVdx/])

  print("zonal average...")
  psi_zone = dim_avg(psi_hate)
  psi_zont = dim_avg(psi_hatt) 
  vor_zon = dim_avg(vort)
  u_zon = dim_avg(U_rgrid)
  s_zon = dim_avg(S)
  pmzon = dim_avg(PM_rgrid)
  delete([/psi_hatt,psi_hate,vort,U_rgrid,S,PM_rgrid/])

  print("time average...")
  psie = dim_avg_0_lowmem(psi_zone,3)
  psit = dim_avg_0_lowmem(psi_zont,3)
  vor = dim_avg_0_lowmem(vor_zon,3)
  ubar = dim_avg_0_lowmem(u_zon,3)
  emfc = dim_avg_0_lowmem(s_zon,3)
  pmbar = dim_avg_0_lowmem(pmzon,3)
  delete([/psi_zone,psi_zont,vor_zon,u_zon,s_zon,pmzon/])

  f  = 2.*omg_cnst*sin(latrad)
  indx = ind(f.eq.0.) 
  f@_FillValue = default_fillvalue("double")
  f(indx) = f@_FillValue
  delete(indx)

  ;;multiply by cnst to get psi
  psie@_FillValue = default_fillvalue("double")
  psit@_FillValue = default_fillvalue("double")
  do k = 0,nlevs-1
    psie(k,:) = 2*pi*Re*cos(latrad)*psie(k,:)/(g*f)
    psit(k,:) = 2*pi*Re*cos(latrad)*psit(k,:)/g
  end do

  ;compute Rovort
  Rovort = vor
  Rovort = 0.
  do k = 0,nlevs-1
    Rovort(k,:) = vor(k,:)/f
  end do
  Rovort = -1.*Rovort 
  Rovort = abs(Rovort)
  delete([/f,vor/])

  ;compute angular momentum
  angmom = ubar
  angmom = 0.
  do k = 0,nlevs-1
    angmom(k,:) = ( omg_cnst*Re*cos(latrad) + ubar(k,:) ) * Re*cos(latrad)
  end do
  delete([/latrad,ubar/])

  ;compute bulk rossby number
  Ro = (psit - psie)/psit
  Ro = abs(Ro)

  psim = psit - psie

  if (zeromiss) then
    delete([/psie@_FillValue,psim@_FillValue,Ro@_FillValue/])
    missval = 9.969209968386869e+36
    psie = where(psie.eq.missval,0.,psie)
    psim = where(psim.eq.missval,0.,psim)
    Ro   = where(Ro.eq.missval,0.,Ro)
  end if

  print("max psie " + max(psie))
  print("max psim " + max(psim))
  print("max psit " + max(psit))

  print("psie num ismissing + " + num(ismissing(psie)) )
  print("psim num ismissing + " + num(ismissing(psim)) )
  print("Ro num ismissing + " + num(ismissing(Ro)) )

  psie!0 = "levs"
  psie&levs = lev_p/100.
  psie&levs@long_name = "Pressure (hPa)"
  psie!1 = "lat"
  psie&lat = sin(lat*pi/180.)

  psit!0 = "levs"
  psit&levs = lev_p/100.
  psit&levs@long_name = "Pressure (hPa)"
  psit!1 = "lat"
  psit&lat = sin(lat*pi/180.)

  Ro!0 = "levs"
  Ro&levs = lev_p/100.
  Ro&levs@long_name = "Pressure (hPa)"
  Ro!1 = "lat"
  Ro&lat = sin(lat*pi/180.)

  psim!0 = "levs"
  psim&levs = lev_p/100.
  psim&levs@long_name = "Pressure (hPa)"
  psim!1 = "lat"
  psim&lat = sin(lat*pi/180.)

  Rovort!0 = "levs"
  Rovort&levs = lev_p/100.
  Rovort&levs@long_name = "Pressure (hPa)"
  Rovort!1 = "lat"
  Rovort&lat = sin(lat*pi/180.)

  angmom!0 = "levs"
  angmom&levs = lev_p/100.
  angmom&levs@long_name = "Pressure (hPa)"
  angmom!1 = "lat"
  angmom&lat = sin(lat*pi/180.)

  emfc = emfc*secpday
  emfc!0 = "levs"
  emfc&levs = lev_p/100.
  emfc&levs@long_name = "Pressure (hPa)"
  emfc!1 = "lat"
  emfc&lat = sin(lat*pi/180.)

else if (loadncdf)
   print("Loading vars from " + fname_in)
   if (n.eq.0) then
     ncdf = addfile(fname_in , "r")
   end if

   psie = ncdf->$VAR1(n)$
   psit = ncdf->$VAR2(n)$
   Ro   = ncdf->$VAR3(n)$
   psim = ncdf->$VAR4(n)$
   Rovort = ncdf->$VAR5(n)$
   angmom = ncdf->$VAR6(n)$
   emfc = ncdf->$VAR7(n)$

   lat = ncdf->$LATatt(n)$

end if
end if

  if (plotvar.eq.0) then
    var = psie
    varNam = "psi-e"
  else if (plotvar.eq.1) then
    var = psit
    varNam = "psi-tot"
  else if (plotvar.eq.2) then
    var = Ro
    varNam = "Ro"
  else if (plotvar.eq.3) then
    var = psim
    varNam = "psim"
  else if (plotvar.eq.4) then
    var = Rovort
    varNam = "Rovort"
  else if (plotvar.eq.5) then
    var = emfc
    varNam = "emfc"
  end if
  end if
  end if
  end if
  end if
  end if

  print("max " + varNam + " " + max(var))
  print("min " + varNam + " " + min(var))

  if (plotvar.eq.2 .or. plotvar.eq.4) then
    res@cnFillOn          = True 
    res@cnLinesOn         = False
    res@cnMinLevelValF  = 0.
    res@cnMaxLevelValF  = 1.;;;10.
    res@cnLevelSpacingF = 0.05;;;0.5
  else if (plotvar.eq.5) then
    res@cnFillOn          = True
    res@cnLinesOn         = False
    res@cnMinLevelValF  = -5.
    res@cnMaxLevelValF  =  5.
    res@cnLevelSpacingF = 0.5
  else
    res@cnFillOn          = False
    res@cnLinesOn         = True
    res@cnMinLevelValF  =-2.e11
    res@cnMaxLevelValF  = 2.e11
    res@cnLevelSpacingF = 5.e10
  end if
  end if

  plot(n) = gsn_csm_contour(wks,var,res)

  if (plotvar.eq.2 .or. plotvar.eq.4)
    res@cnFillOn          = False
    res@cnLinesOn         = True

    res@cnMinLevelValF  =-2.e11
    res@cnMaxLevelValF  = 2.e11
    res@cnLevelSpacingF = 5.e10

    tmp = gsn_csm_contour(wks,psit,res)
    overlay(plot(n),tmp)
    delete(tmp)
  end if

  if (plotang) then
    res@cnFillOn          = False
    res@cnLinesOn         = True

    res@cnInfoLabelOn     = False
    res@cnLineColor = "red"
    res@cnLevelSelectionMode = "ExplicitLevels"
    nlat = dimsizes(lat)
    ;;;;skip = (/8,8/) ;;; (/8,16/) ;;;;ne30pg3/ne60pg3
    ncn = nlat/(2*skip(n))
    cnlevs = new( (/ncn+1/), "float")   

    kbot = 31
    do i = 0,ncn
      idx = i*skip(n)
      cnlevs(i) = tofloat(angmom(kbot,idx))
    end do
    res@cnLevels = cnlevs
    delete(cnlevs)

    ;;mfact = omg_cnst*Re^2./15
    res@cnLineColor = "red"

    tmp = gsn_csm_contour(wks,angmom,res)
    overlay(plot(n),tmp)
    delete(tmp)

    res@cnLineColor = "black"
    res@cnLevelSelectionMode = "ManualLevels"
    res@cnInfoLabelOn     = True
  end if

  if (writencdf) then
    if (n.eq.0) then
      system("/bin/rm -f "+fname_out)
      ncdf = addfile(fname_out,"c")
    end if
    psie!1= LATatt(n)
    psit!1= LATatt(n)
    Ro!1  = LATatt(n)
    psim!1= LATatt(n)
    Rovort!1= LATatt(n)
    angmom!1= LATatt(n)
    emfc!1= LATatt(n)

    ncdf->$VAR1(n)$ = psie
    ncdf->$VAR2(n)$ = psit
    ncdf->$VAR3(n)$ = Ro
    ncdf->$VAR4(n)$ = psim
    ncdf->$VAR5(n)$ = Rovort
    ncdf->$VAR6(n)$ = angmom
    ncdf->$VAR7(n)$ = emfc
  end if

  if (writediag) then
    hilat = (/ 90.d,  0.d/)
    lolat = (/  0.d,-90.d/)

    do m = 0,1
       indx = ind(lat.le.hilat(m) .and. lat.ge.lolat(m))
       latreg = lat(indx)

       ;;;psie max
       psiereg = psie(:,indx)
       if (m.eq.0) then
         maxlat = 30.
         minlat = 10.
       else
         maxlat = -10.
         minlat = -30.
         psiereg = -1.*psiereg
       end if
       indxx = ind(latreg.gt.minlat .and. latreg.lt.maxlat)
       psiexx = psiereg(:,indxx)
       psiemax = max(psiexx)
       delete([/psiereg,indxx,psiexx/])

       ;;;psie max
       psim = -1.*psim
       psimreg = psim(:,indx)
       if (m.eq.0) then
         maxlat = 20.
         minlat = 5.
       else
         maxlat =  -5.
         minlat = -20.
       end if
       indxx = ind(latreg.gt.minlat .and. latreg.lt.maxlat)
       psimxx = psimreg(:,indxx)
       psimmax = max(psimxx)
       delete([/psimreg,indxx,psimxx/])

       ;;;psi max
       psit = -1.*psit
       psireg = psit(:,indx)
       psi1d = ndtooned(psireg)
       inds = ind_resolve(maxind(psi1d),dimsizes(psireg))

       psimax = psireg(inds(0,0),inds(0,1))
       delete([/psireg,psi1d/])

       ;;;Ro at psi-max
       Rovreg = Ro(:,indx)
       Rovmax = Rovreg(inds(0,0),inds(0,1))
       delete([/inds,Rovreg/])

       ;;;max Robulk (between 175 hPa and 325 hPa)
       ;;;first reduce domain in vertical
       lev_d = (/175.d2,225.d2,275.d2,325.d2/)
       linlog = 1
       Roblev = int2p_n(pmbar(:,indx),Rovort(:,indx),lev_d,linlog,0)
       if (m.eq.0) then
         maxlat = 15.
         minlat = 0.
       else
         maxlat = 0.
	 minlat = -15.
       end if
       indxx = ind(latreg.gt.minlat .and. latreg.lt.maxlat)
       Robreg = Roblev(:,indxx)
       Roblat = latreg(indxx)
       Rob1d = ndtooned(Robreg)
       inds = ind_resolve(maxind(Rob1d),dimsizes(Robreg))

       Robmax = Robreg(inds(0,0),inds(0,1))
       delete([/Roblev,Robreg,Roblat,Rob1d,inds,indxx/])

       ;;;mean EMFC between 10 and 25 deg
       dp   = (/ 50.d2, 50.d2, 50.d2, 50.d2/)
       emfclev =int2p_n(pmbar(:,indx),emfc(:,indx),lev_d,linlog,0)
       if (m.eq.0) then
         maxlat = 25.
         minlat = 10.
       else
         maxlat = -10.
         minlat = -25.
       end if
       indxx = ind(latreg.gt.minlat .and. latreg.lt.maxlat)
       emfcreg = emfclev(:,indxx)
       emfclat = latreg(indxx)
       emfcvert = ( emfcreg(1,:)*dp(1) + emfcreg(2,:)*dp(2) ) / ( dp(1) + dp(2) )

       ;emfc_bar = dim_avg(emfcvert)
       nlate = dimsizes(emfcvert)
       dlat = ( lat(1) - lat(0) )  * pi/180.
       emfc_bar = 0.
       denom = 0.
       do j = 0,nlate-1
         emfc_bar = tofloat( emfcvert(j)*dlat*cos(emfclat(j)*pi/180.) ) + emfc_bar	 
         denom = tofloat( dlat*cos(emfclat(j)*pi/180.) ) + denom
       end do
       emfc_bar = emfc_bar/denom
       delete([/emfclev,indxx,emfcreg,emfclat,emfcvert,indx,latreg/])

       if (m.eq.1) then
	 delete(pmbar)
       end if

       if (m.eq.0) then
         system("/bin/rm -f "+fname_dout(n))
         dncdf = addfile(fname_dout(n),"c")
       end if
       dncdf->$PSIMAX(m)$ = psimax
       dncdf->$PSIEMAX(m)$ = psiemax
       dncdf->$PSIMMAX(m)$ = psimmax
       dncdf->$ROVMAX(m)$ = Rovmax
       dncdf->$ROBMAX(m)$ = Robmax
       dncdf->$EMFC(m)$  = emfc_bar

       print("  ")
       print("Stats for region " + lolat(n) + " to " + hilat(n))
       print("------------------------------------------------------------------------")
       print("  PSIMAX           " + psimax + " (kg/s)")
       print("  PSIEMAX          " + psiemax + " (kg/s)")
       print("  PSIMMAX          " + psimmax + " (kg/s)")
       print("  ROVMAX           " + Rovmax + " (unitless)")
       print("  ROBMAX           " + Robmax + " (unitless)")
       print("  EMFC             " + emfc_bar  + " (m/s/d)")
       print("  ")

     end do
     delete(dncdf)
   end if

delete([/psie,psit,Ro,psim,Rovort,var,angmom,emfc,lat/])

print("done with file " + n)

end do ;nfiles

;*****************************************************
; Plot panel
;*****************************************************

  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  ;resP@gsnPaperOrientation = "portrait"
  resP@gsnPanelBottom   = 0.05
  ;resP@gsnPanelFigureStrings = (/varNam,varNam/)
  resP@gsnPanelFigureStringsPerimOn     = True
  resP@gsnPanelFigureStringsBackgroundFillColor = "white"
  resP@amJust           = "TopRight"
  ;resP@txString = pltTitle
  gsn_panel(wks,plot,(/2,1/),resP)               ; now draw as one plot

  frame(wks)

end
