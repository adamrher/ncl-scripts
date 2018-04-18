;**************************************
;zonal_hgt_isen.ncl
;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/esmf/ESMF_regridding.ncl"
load "/glade/p/work/aherring/se_func_lib.ncl"
;**************************************
begin

  rdir  = (/"/run/","/run/"/)
  fname = (/fname1,fname2/)
  fdate = (/".cam."+fincl1+"*",".cam."+fincl2+"*"/)
  nfiles = dimsizes(fname)

  ;;;Choose Variable to plot - RELHUM,U,OMEGA
  var = "RELHUM"

  labels = new( (/nfiles+1/), "string" ) 
  labels(0:nfiles-1) = fname
  labels(nfiles) = "Anomaly"

  onemnth = True
  nstart = 1

  writencdf = False
  fname_out = fname(0)+"."+fname(1)+".dzonal-hgt.nc"

  PSI   = (/  "PSI1",  "PSI2"/)
  ZRH   = (/  "ZRH1",  "ZRH2"/)
  PTROP = (/"PTROP1","PTROP2"/)

 ;;;tropopause colors
 colors = (/"gray28","dodgerblue3"/)

 ;;;psi contours
 psispace = (/5.e10,5.e10,1.e10 /)

 ;;;if-then-ism -ruth marcus
 if (var.eq."RELHUM") then
	 vmin = (/0.,0.,-20./)
	 vmax = (/100.,100.,20./)
	 vspace = (/5.,5.,1.5/)
	 var = "Q"
 else if (var.eq."U") then
	 vmin = (/-10.,-10.,-5./)
	 vmax = (/60.,60.,5./)
	 vspace = (/2.5,2.5,0.5/)
 else if (var.eq."OMEGA") then
         vmin = (/-80.,-60.,-20./)
         vmax = (/20.,30.,20./)
         vspace = (/5.,5.,2./)
 end if
 end if
 end if

 cp = 1004.64 ;J/kg/K
 Rd = 287.0423 ;J/kg/K
 g = 9.80616 ;m/s2
 re = 6.37122e6 ;m
 pi = 3.14159265358979
 p0 = 1.e5
 secpday = 60.*60.*24.

 pltnam = "temp_dhgt"

;*************************************************************
; Start graphics
;*************************************************************
  wks = gsn_open_wks("eps",pltnam)
  gsn_define_colormap(wks,"MPL_jet")
  gsn_reverse_colormap(wks)

  plot = new(3,graphic)                          ; create a plot array

;*************************************************************
; stream function contours
;*************************************************************
  res             = True
  res@gsnMaximize = False;True

  res@gsnDraw     = False      ; Will draw later, after overlaying
  res@gsnFrame    = False      ; all plots

  res@vpWidthF    = 0.95        ; Make plots wider
  res@vpHeightF   = 0.5
  res@vpXF                = 0.025
  res@vpYF                = 0.85

  res@cnLevelSelectionMode = "ManualLevels"    ; manually set the contour levels with the following 3 resources

  res@cnMonoLineThickness = True
  res@cnLineThicknessF   = 1.5
  res@gsnContourZeroLineThicknessF = 3.                 ; doubles thickness of zero contour
  res@gsnContourNegLineDashPattern = 1          ; sets negative contours to dash pattern 1
  res@cnLineLabelsOn    = False              ; turn off line labels
  res@cnInfoLabelOn     = True                ; turn off info label

  res@gsnXAxisIrregular2Linear = True
  res@gsnYAxisIrregular2Linear = True

  res@cnLineDrawOrder = "PostDraw" ;sets contours on top of everything

;*************************************************************
; relative humidity contours
;*************************************************************
   res1             = True
   res1@gsnMaximize = True
   res1@gsnPaperOrientation = "portrait"

   res1@gsnDraw     = False      ; Will draw later, after overlaying
   res1@gsnFrame    = False      ; all plots

   res1@vpWidthF    = res@vpWidthF        ; Make plots wider
   res1@vpHeightF   = res@vpHeightF
   res1@vpXF                = res@vpXF
   res1@vpYF                = res@vpYF

   res1@cnFillOn          = True               ; turn on color fill
   res1@cnLinesOn         = False
   res1@cnLineLabelsOn    = False
   res1@lbLabelBarOn        = True
   res1@lbOrientation =   "Vertical"          ; vertical label bar
   res1@cnInfoLabelOn     = False

   res1@cnMonoLineThickness = True
   res1@cnLineThicknessF  = 2.
   res1@cnLevelSelectionMode = "ManualLevels"     ; manually set the contour levels with the following 3 resources
   res1@gsnSpreadColors  = True               ; use full range of color map
   res1@lbLabelStride     = 2                  ; every other color

   res1@tmBorderThicknessF = 4 ;axes thickness
   res1@tmXBMajorOutwardLengthF = 0.
   res1@tmYLMajorOutwardLengthF = 0.
   res1@tmXBMinorOutwardLengthF = 0.
   res1@tmYLMinorOutwardLengthF = 0.
   res1@tmXTMajorOutwardLengthF = 0.
   res1@tmYRMajorOutwardLengthF = 0.
   res1@tmXTMinorOutwardLengthF = 0.
   res1@tmYRMinorOutwardLengthF = 0.
   res1@tmXTOn               = False
   res1@tmYROn               = False

   res1@gsnXAxisIrregular2Linear = True
   res1@gsnYAxisIrregular2Linear = True
   res1@trYReverse            = True
   res1@trYMinF            = 0.
   res1@trYMaxF            = 1000.
   res1@trXMinF     = -1.;0.
   res1@trXMaxF     = 1.
   res1@tmXBMode        = "Explicit"

   xticks = new((/19/),float)
   do i = 0,19-1
     tmp = (i-9)*10.
     xticks(i) = sin(tmp*pi/180.)
   end do
   delete(tmp)
   res1@tmXBValues      = xticks
   res1@tmXBLabels      = (/"","-80","","-60","","-40","","-20","","0","","20","","40","","60","","80",""/)

   lnres             = True

;****************************************
; Begin Loop
;************************************************
do n = 0,nfiles-1
  print("Begin Case " + n)

  files = systemfunc ("ls " + dir + fname(n) + rdir(n) + fname(n) + fdate(n))
  print(files)

  nf = dimsizes(files)
  if (onemnth) then
    nfinish = nstart
  else
    nfinish = nf-1
  end if
  in  = addfiles (files(nstart:nfinish),"r")
  ListSetType(in,"cat")
  delete(files)

  print("  grabbing vars...")
  if (n.eq.0) then
	hyam = in[0]->hyam
	hybm = in[0]->hybm
	hyai = in[0]->hyai
	hybi = in[0]->hybi
	nlevs = dimsizes(hyam)
	ilevs = dimsizes(hyai)

	;;;compute dA and dB
	dA = hyai(1:ilevs-1) - hyai(0:ilevs-2)
	dB = hybi(1:ilevs-1) - hybi(0:ilevs-2)

	linlog = 2
   	lev_p = (hyam + hybm)*p0
   	lev_p!0         = "lev_p"       
   	lev_p&lev_p     =  lev_p         
   	lev_p@long_name = "Pressure (Pa)"
   	lev_p@units     = "Pa"
   	lev_p@positive  = "down"
  end if

  time = in[:]->time

  ;;;are we on a lat-lon grid?
  if (isfilevardim(in[0],"OMEGA","ncol")) then
    print("  NETCDF on native grid")
    latlon = False
    dims = getfilevardimsizes(in[0],"OMEGA")
    ncol = dims(2)
    wgtpath = wgt_path(ncol)
    delete(dims)
  else
    print("  NETCDF on lat-lon grid")
    latlon = True
  end if 


  if (latlon) then
	lat = in[0]->lat
	lon = in[0]->lon

        ps = in[:]->PS
        T = in[:]->T
       	q = in[:]->$var$
        v = in[:]->V

        pm = pres_hybrid_ccm(ps,p0,hyam,hybm)
        copy_VarMeta(T,pm)

	if (var.eq."Q") then
        	rh = relhum(T,q/(1-q),pm)
	else
		rh = q
	end if
        delete(q)

  else 
	print("  regridding...")

	ps = in[:]->PS
	T = in[:]->T
	q = in[:]->$var$
	v = in[:]->V

        if (var.eq."Q") then
	        pm = se_pressure(ps,p0,hyam,hybm,0)
	        rh = relhum(T,q/(1-q),pm)
	        delete(pm)
        else
                rh = q
        end if
        delete(q)

	pstmp = ESMF_regrid_with_weights(ps,wgtpath,False)
	Ttmp = ESMF_regrid_with_weights(T,wgtpath,False)
	rhtmp = ESMF_regrid_with_weights(rh,wgtpath,False)
	vtmp = ESMF_regrid_with_weights(v,wgtpath,False)
	lat = Ttmp&lat
	lon = Ttmp&lon

	delete(ps)
	delete(T)
	delete(rh)
	delete(v)

	ps = pstmp
	T = Ttmp
	rh = rhtmp
	v = vtmp

	delete(pstmp)
        delete(Ttmp)
	delete(rhtmp)
        delete(vtmp)

        pm = pres_hybrid_ccm(ps,p0,hyam,hybm)
	copy_VarMeta(T,pm)
  end if
  delete(in)
  nlat = dimsizes(lat)
  nlon = dimsizes(lon)
  ntime = dimsizes(time)

  if (var.eq."OMEGA") then
	rh = rh*secpday/100.
  end if

;************************************************
; compute tropopause
;************************************************
  print("  computing tropopause...")

  ;;;copy_VarCoords(T,pm)
  tmp = trop_wmo(pm(time|:,lat|:,lon|:,lev|:),T(time|:,lat|:,lon|:,lev|:),1,False)
  ptrop = dim_avg(dim_avg_n(tmp,0))
  delete(T)
  delete(tmp)

;************************************************
; compute meridional streamfunction
; will compute on native (eta) grid
; psi(t,k,lat,lon) 
; = 2*pi*re*cos(lat)/g * int(v*p0)dA + int(v*ps)dB
;************************************************
 print("  computing stream function...")

 ;;;compute v*ps and v*p0
 vps = v
 vps = 0.
 do k = 0,nlevs-1
  vps(:,k,:,:) = v(:,k,:,:)*ps
 end do
 vp0 = p0*v 
 delete(v)
 delete(ps)

 ;;;integrate from top-down
 ;;; note lat,lon,hyai,hybi are doubles by default
 int_eta = vps
 int_eta = 0. 
 tmp = new( (/ntime,nlat,nlon/),"double" )

 do k = 0,nlevs-1
	tmp = 0.
	do l = k,nlevs-1
		tmp = vp0(:,l,:,:)*dA(l) + vps(:,l,:,:)*dB(l) + tmp
	end do
	int_eta(:,k,:,:) = tofloat(tmp)
 end do
 delete(tmp)
 delete(vps)
 delete(vp0)

;************************************************
; set control vars &
; put anomaly vars on cntl grid
;************************************************
 
if (n.eq.0) then
	;;;save control vars
	pm0 = pm
	rh0 = rh
	int_eta0 = int_eta

	dint = int_eta0
	drh = rh0

	nlat0 = nlat
	lat0 = lat
 else
        wgtpath = wgt_res_path(nlat0,nlat)
	if (wgtpath.ne."none") then
		print("  regridding to CNTL")
		pmtmp = ESMF_regrid_with_weights(pm,wgtpath,False)
		int_etatmp = ESMF_regrid_with_weights(int_eta,wgtpath,False)
		rhtmp = ESMF_regrid_with_weights(rh,wgtpath,False)

		;;delete([/rh,pm,int_eta/])
		;;pm = pmtmp
		;;rh = rhtmp
		;;int_eta = int_etatmp
		;;delete([/pmtmp,rhtmp,int_etatmp/])
	end if

	;;; get vars on control grid
	;;; FOR ANOMALIES ONLY!!!
        rh_c = int2p_n(pmtmp,rhtmp,pm0,linlog,1)
	int_eta_c = int2p_n(pmtmp,int_etatmp,pm0,2,1)

	dint = int_eta0 - int_eta_c
	drh = rh0 - rh_c
	delete(int_eta_c)
	delete(rh_c)
 end if

;*************************************************************
; remap to common pressure level (for plotting)
; *remember when using vinth2p:
; lev_p->hPa / ps->Pa / p0->hPa
;*************************************************************

  ;;;don't be confused by the notation
  ;;;these are full fields, not anomalies

  drh_levp = int2p_n(pm,rh,lev_p,linlog,1)
  dint_levp = int2p_n(pm,int_eta,lev_p,linlog,1)
  delete(rh)
  delete(int_eta)

  ;;; zonal and time average
  zrh = dim_avg(dim_avg_n(drh_levp,0))
  psi = -1.*dim_avg(dim_avg_n(dint_levp,0))
 
  ;;; compute stream function
  do i = 0,nlat-1
	 psi(:,i) = tofloat(cos(lat(i)*pi/180.))*2*pi*re*psi(:,i)/g
  end do
  delete(drh_levp)
  delete(dint_levp)

  zrh!0 = "levs"
  zrh&levs = lev_p/100.
  zrh&levs@long_name = "Pressure (hPa)"
  zrh!1 = "lat"
  zrh&lat = sin(lat*pi/180.)

  psi!0 = "levs"
  psi&levs = lev_p/100.
  psi&levs@long_name = "Pressure (hPa)"
  psi!1 = "lat"
  psi&lat = sin(lat*pi/180.)

  ;;; anomaly for case n=1
  if (n.eq.1) then
	rh_levp = int2p_n(pmtmp,drh,lev_p,linlog,1)
        int_levp = int2p_n(pmtmp,dint,lev_p,linlog,1)
        delete(drh)
        delete(dint)

        ;;; compute stream function
	dzrh = dim_avg(dim_avg_n(rh_levp,0))
        ;;; compute stream function
	dpsi = -1.*dim_avg(dim_avg_n(int_levp,0))
	;;; compute stream function
	do i = 0,nlat0-1
	       dpsi(:,i) = tofloat(cos(lat0(i)*pi/180.))*2*pi*re*dpsi(:,i)/g
	end do
	delete(rh_levp)
	delete(int_levp)

	copy_VarMeta(zrh0,dzrh)
	copy_VarMeta(psi0,dpsi)
  end if
  delete(pm)

 print("  plotting...")

 ;;; Relative Humidity Contours
 res1@cnMinLevelValF  = vmin(n)
 res1@cnMaxLevelValF  = vmax(n)
 res1@cnLevelSpacingF = vspace(n)

 plot(n)  = gsn_csm_contour(wks,zrh,res1)
 ;;;stream function contours
 ;;res@cnMinLevelValF  = psimin(n)        
 ;;res@cnMaxLevelValF  = psimax(n)          
 res@cnLevelSpacingF = psispace(n)

 tmp = gsn_csm_contour(wks,psi,res)
 overlay(plot(n),tmp)
 delete(tmp)

 ;;; Tropopause Line
 copy_VarCoords(lat,ptrop)
 lnres@gsLineColor = colors(n)
 lnres@gsLineThicknessF = 5.
 lstr = unique_string("dum")
 plot@$lstr$ = gsn_add_polyline(wks,plot(n),sin(lat*pi/180.),ptrop/100.,lnres)

 ;;anomaly plot
 if (n.eq.0) then
	ptrop0 = ptrop
 else
        res1@tiXAxisString          = "Latitude"
	;;; Relative Humidity Contours
	res1@cnMinLevelValF  = vmin(2)
	res1@cnMaxLevelValF  = vmax(2)
	res1@cnLevelSpacingF = vspace(2)

	plot(2)  = gsn_csm_contour(wks,dzrh,res1)
	;;;stream function contours
	;;res@cnMinLevelValF  = psimin(2)
	;;res@cnMaxLevelValF  = psimax(2)
	res@cnLevelSpacingF = psispace(2)

	tmp = gsn_csm_contour(wks,dpsi,res)
	overlay(plot(2),tmp)
	delete(tmp)

	lnres@gsLineColor = colors(0)
	lstr = unique_string("dum")
	plot@$lstr$ = gsn_add_polyline(wks,plot(2),sin(lat*pi/180.),ptrop0/100.,lnres)
        lnres@gsLineColor = colors(1)
        lstr = unique_string("dum")
        plot@$lstr$ = gsn_add_polyline(wks,plot(2),sin(lat*pi/180.),ptrop/100.,lnres)
 end if

 if (writencdf) then
   if (n.eq.0) then
     system("/bin/rm -f "+fname_out)
     ncdf = addfile(fname_out,"c")
   end if

   ncdf->$PSI(n)$ = psi
   ncdf->$ZRH(n)$ = zrh
   ncdf->$PTROP(n)$ = ptrop

   if (n.eq.nfiles-1) then
     ncdf->DZRH = uarea
     ncdf->DPSI = dpsi
   end if
 end if
 
 if (n.eq.0) then
   psi0 = psi
   zrh0 = zrh
 end if

 delete(psi)
 delete(zrh)
 delete(ptrop)
 delete(time)
 delete(lat)
 delete(lon)

 print("Done with case " + n)

end do ;nfiles

;************************************************
; create panel
;************************************************
  resP                  = True                   ; modify the panel plot
  resP@gsnFrame         = False                  ; don't advance panel plot
  resP@gsnMaximize = False;True
  resP@gsnPaperOrientation = "portrait"
  ;resP@gsnPanelLabelBar = True                   ; add common colorbar
  resP@gsnPanelBottom   = 0.05

  ;;resP@gsnPanelFigureStrings = labels
  ;;resP@gsnPanelFigureStringsFontHeightF = 0.012
  ;;resP@gsnPanelFigureStringsPerimOn     = True
  ;;resP@gsnPanelFigureStringsBackgroundFillColor = "white"
  ;;resP@amJust           = "TopRight"

  gsn_panel(wks,plot,(/3,1/),resP)               ; now draw as one plot
  frame(wks)

end
