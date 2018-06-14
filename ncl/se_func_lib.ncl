;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;****************************************

;;; computes pressure field on native se grid	
function se_pressure(PS,P0,hya,hyb,topt)
;;;
;;; topt = 0,time dimension present
;;;      = 1,time dimension not present

local nlevs,dims,ntime,ncols,p,hya3d,hyb3d,ps3d,p00 

begin

	nlevs = dimsizes(hya)
	dims = dimsizes(PS)

	
	if (topt.eq.0) then
		ntime = dims(0)
		ncols = dims(1)  
		p = new( (/ntime,nlevs,ncols/),"double")
		p@_FillValue = default_fillvalue("double")

		hya3d = tofloat(conform(p,hya,1))
		hyb3d = tofloat(conform(p,hyb,1))
		ps3d = p
		do k = 0,nlevs-1
			ps3d(:,k,:) = todouble(PS)
		end do
	        p00 = todouble(P0)
		p(:,:,:) = p00*hya3d + ps3d*hyb3d

	else if (topt.eq.1) then

		ncols = dims(0)
		p = new( (/nlevs,ncols/),"double")
		p@_FillValue = default_fillvalue("double")

		hya3d = tofloat(conform(p,hya,0))
		hyb3d = tofloat(conform(p,hyb,0))
		ps3d = p
		do k = 0,nlevs-1
			ps3d(k,:) = todouble(PS)
		end do

                p00 = tofloat(P0)
		p(:,:) = p00*hya3d + ps3d*hyb3d

	end if
	end if

	return(p)

end

;;;computes psi
function psi_latlon(v,dp,lat,topt)
;;;
;;; mass stream function,
;;; psi = 2*pi*re*cos(lat)*v*dp/g
;;; topt = 0,time dimension present
;;;      = 1,time dimension not present

local dims,ntime,nlevs,nlat,const,dum,psi,g,re,pi

begin

  g = 9.80616 ;m/s2
  re = 6.37122e6 ;m
  pi = 3.14159265358979

  dims = dimsizes(v)
  if (topt.eq.0) then
    ntime = dims(0)
    nlevs = dims(1)
    nlat = dims(2)
  else
    nlevs = dims(0)
    nlat = dims(1)
  end if

 if (topt.eq.0) then

  psi = new((/ntime,nlevs,nlat/),double)
  do j = 0,nlat-1
    	const = 2*pi*re*cos(lat(j)*pi/180.)/g ;;;*(1.e-10)
    	do m = 0,nlevs-1
     		dum = 0.d
     		do n = m,nlevs-1
      			dum = v(:,n,j)*dp(:,n,j) + dum
     		end do
     		psi(:,m,j) = const*dum
    	end do
  end do

 else ;;topt

  psi = new((/nlevs,nlat/),double)
  do j = 0,nlat-1
        const = 2*pi*re*cos(lat(j)*pi/180.)/g ;;;*(1.e-10)
        do m = 0,nlevs-1
                dum = 0.d
                do n = m,nlevs-1
                        dum = v(n,j)*dp(n,j) + dum
                end do
                psi(m,j) = const*dum
        end do
  end do

 end if ;;topt

 return(tofloat(psi))

end

;;; low memory version of pdfx through loadvar
function pdfx_loadvar(files,var,rank,nbins,opt)
;;;
;;; files = list of netCDF files
;;; variable name in netCDF, as a string
;;; rank = number of dimensions of variable

local nfiles,n,in,ntime,t,tmp,pdfvar,nrecords

begin

  nfiles = dimsizes(files)

  do n = 0,nfiles-1

        in = addfile(files(n),"r")
        ntime = dimsizes(in->time)

        do t = 0,ntime-1

                if (rank.eq.2)
                        tmp = in->$var$(t,:)
                else if (rank.eq.3)
                        tmp = in->$var$(t,:,:)
                else if (rank.eq.4)
                        tmp = in->$var$(t,:,:,:)
                end if
                end if
                end if

                if (n.eq.0 .and. t.eq.0) then
  			pdfvar = pdfx(tmp,nbins,opt)
  			pdfvar = 0.
			nrecords = 0.
                end if

        	pdfvar = pdfvar + pdfx(tmp,nbins,opt)
	        print("t="+t)
	        nrecords = nrecords + 1

        end do
  end do

  pdfvar = pdfvar/nrecords
  return(pdfvar)

end

;;; low memory version of pdfx
function pdfx_lowmem(var,rank,nbins,opt)
;;;
;;; files = list of netCDF files
;;; variable name in netCDF, as a string
;;; rank = number of dimensions of variable

local dims,ntime,t,tmp,pdfvar,nrecords

begin

  dims = dimsizes(var)
  ntime = dims(0)

  do t = 0,ntime-1

                if (rank.eq.2)
                        tmp = var(t,:)
                else if (rank.eq.3)
                        tmp = var(t,:,:)
                else if (rank.eq.4)
                        tmp = var(t,:,:,:)
                end if
                end if
                end if

                if (t.eq.0) then
                        pdfvar = pdfx(tmp,nbins,opt)
                        pdfvar = 0.
                        nrecords = 0.
                end if

                pdfvar = pdfvar + pdfx(tmp,nbins,opt)
                print("t="+t)
                nrecords = nrecords + 1

  end do

  pdfvar = pdfvar/nrecords
  return(pdfvar)

end


;;; low memory version of dim_avg
function dim_avg_0_loadvar(files,var,rank)
;;; 
;;; note that it average over the first dimension (should be time)
;;; var must be 2,3 or 4 dimensional
;;; input arguments:
;;; files = list of netCDF files
;;; variable name in netCDF, as a string
;;; rank = number of dimensions of variable
;;; 

local nfiles,n,in,ntime,t,tmp,dims,sums,sumsN,var_avg,prec

begin

  prec = "double"
  nfiles = dimsizes(files)

  do n = 0,nfiles-1

  	in = addfile(files(n),"r")             
  	ntime = dimsizes(in->time)

  	do t = 0,ntime-1

		if (rank.eq.2)
			tmp = todouble(in->$var$(t,:))
		else if (rank.eq.3)
			tmp = todouble(in->$var$(t,:,:))
		else if (rank.eq.4)
			tmp = todouble(in->$var$(t,:,:,:))
		end if
		end if
		end if

	        if (n.eq.0 .and. t.eq.0) then
                	dims = dimsizes(tmp)
                	sums = new(dims,prec,default_fillvalue(prec))
                	sumsN = new(dims,prec,default_fillvalue(prec))
                	sums = 0.
                	sumsN = 0.
        	end if

	        sums = sums + where(.not.ismissing(tmp),tmp,0.0)
        	sumsN = sumsN + where(.not.ismissing(tmp),1.0,0.0)

	end do
  end do

  sumsN = where(sumsN.lt.1.0,sumsN@_FillValue,sumsN)
  var_avg = sums/sumsN
  return(var_avg)

end

;;; low memory version of dim_avg for an array
function dim_avg_0_lowmem(var,rank)
;;;
;;; note that it average over the first dimension (should be time)
;;; var must be 2,3 or 4 dimensional
;;; input arguments:
;;; variable name
;;; rank = number of dimensions of variable
;;;

local prec,dims,ntime,t,tmp,sums,sumsN,var_avg

begin

	prec = "double"
        dims = dimsizes(var)
	ntime = dims(0)
	delete(dims)

        do t = 0,ntime-1

                if (rank.eq.2)
                        tmp = todouble(var(t,:))
                else if (rank.eq.3)
                        tmp = todouble(var(t,:,:))
                else if (rank.eq.4)
                        tmp = todouble(var(t,:,:,:))
                end if
                end if
                end if

                if (t.eq.0) then
                        dims = dimsizes(tmp)
                        sums = new(dims,prec,default_fillvalue(prec))
                        sumsN = new(dims,prec,default_fillvalue(prec))
                        sums = 0.
                        sumsN = 0.
                end if

                sums = sums + where(.not.ismissing(tmp),tmp,0.0)
                sumsN = sumsN + where(.not.ismissing(tmp),1.0,0.0)

        end do

  sumsN = where(sumsN.lt.1.0,sumsN@_FillValue,sumsN)
  var_avg = sums/sumsN
  return(var_avg)

end

;;; low memory version of dim_variance for an array
function dim_variance_0_lowmem(var,rank,bar)
;;;
;;; note that it average over the first dimension (should be time)
;;; var must be 2,3 or 4 dimensional
;;; input arguments:
;;; variable name
;;; rank = number of dimensions of variable
;;;

local prec,dims,ntime,t,tmp,sums,sumsN,var_avg

begin

        prec = "double"
        dims = dimsizes(var)
        ntime = dims(0)
	delete(dims)

        do t = 0,ntime-1

                if (rank.eq.2)
                        tmp = todouble(var(t,:))
			tmp = (tmp-bar)^2.
                else if (rank.eq.3)
                        tmp = todouble(var(t,:,:))
                else if (rank.eq.4)
                        tmp = todouble(var(t,:,:,:))
                end if
                end if
                end if

                if (t.eq.0) then
                        dims = dimsizes(tmp)
                        sums = new(dims,prec,default_fillvalue(prec))
                        sumsN = new(dims,prec,default_fillvalue(prec))
                        sums = 0.
                        sumsN = 0.
                end if

                sums = sums + where(.not.ismissing(tmp),tmp,0.0)
                sumsN = sumsN + where(.not.ismissing(tmp),1.0,0.0)

        end do

  sumsN = where(sumsN.lt.1.0,sumsN@_FillValue,sumsN)
  var_avg = sums/sumsN
  return(var_avg)

end


;;; overlays panel boundaries of cubed sphere on contour plot
procedure overlay_se_grid(wks,plot)
;;;

local coordx,coordy,coordz,xlon,xlat,lat,lon,map,f,fvars,fdims,num_el_blk, \ 
	pi,dimnames,dimsz,nelem,count,fcnt,j1,j2,n,i,j,host 

begin

  pi = 3.14159265358979
  res_p = True

  host = getenv("HOST")
  if (host.eq."hobart.cgd.ucar.edu") then
    dirn = "/home/aherring/grids/"
  else
    dirn = "/glade/p/work/aherring/grids/grid_files/"
  end if

  f = addfile(dirn+"uniform_30.g.nc","r")
  ;;f = addfile(dirn+"uniform_1.g.nc","r")

  fvars = getvardims(f)
  fdims = getfiledimsizes(f)
  num_el_blk = fdims(ind(fvars.eq."num_el_blk"))

  ; cartesian coords:
  coordx = f->coord(0,:)
  coordy = f->coord(1,:)
  coordz = f->coord(2,:)

  lat = asin(coordz)
  lon = atan2(coordy,coordx)

  lat = lat*180.d/pi
  lon = lon*180.d/pi

  dimnames = getvardims(f)
  dimsz = getfiledimsizes(f)
  do i=0,dimsizes(dimnames)-1
    if ( dimnames(i).eq."num_elem")
      nelem=dimsz(i)
    end if
  end do

  map = new ( (/nelem,4/), "integer", -99 )

  count=0
  fcnt = dimsizes(f->connect1)
  n=fcnt(0)
  map(count:(n-1),:) = (/ f->connect1 /)
  count=count+n

  nelem=count

  j1 = ispan(0,3,1)
  j2 = (j1+1)%4

  xlon = new ( (/5/), "double")
  xlat = new ( (/5/), "double")

  res_p@gsLineThicknessF = 1.;2.
  res_p@gsLineColor   = "grey43"

  do i=0,nelem-1
    if ( mod(i,500).eq.0) then
      ;print ("i = "+i+"/"+(nelem-1))
    end if
    xlon(0:3) = lon(map(i,:)-1)
    xlat(0:3) = lat(map(i,:)-1)

    do j=0,2
      if ( abs(xlon(j+1)-xlon(j)) .gt. 180.0) then
        if (xlon(j+1) .gt. xlon(j) ) then
          xlon(j)=xlon(j)+360.
        else
          xlon(j+1)=xlon(j+1)+360.
        end if
      end if
    end do

    xlon(4)=xlon(0)
    xlat(4)=xlat(0)
    str = unique_string("polyline")
    plot@$str$ = gsn_add_polyline(wks, plot, xlon,xlat,res_p)
  end do

end

;;; find wgt_path from ncol
function get_wgt_path(ncol,ncol_d,opt)
;;;

local ncol,ncol_d,wgtpath,root,host,opt

begin

  host = getenv("HOST")
  if (host.eq."hobart.cgd.ucar.edu") then
    root = "/home/aherring/grids/"
  else
    root = "/glade/p/work/aherring/grids/grid_files/"
  end if

if (opt.eq.0) then

  if (ncol.eq.13826 .and. ncol_d.eq.13826) then
    wgtpath = root + "ne16_2_latlon.nc"
  else if (ncol.eq.21600 .and. ncol_d.eq.21602) then
    wgtpath = root + "bilin/ne20pg3_2_09375deg-bilin.nc"
  else if (ncol.eq.48602 .and. ncol_d.eq.48602) then
    wgtpath = root + "bilin/ne30np4_2_0703125deg-bilin.nc"
  else if (ncol.eq.21600 .and. ncol_d.eq.48602) then
    wgtpath = root + "bilin/ne30pg2_2_0703125deg-bilin.nc"
  else if (ncol.eq.48600 .and. ncol_d.eq.48602) then
    wgtpath = root + "bilin/ne30pg3_2_0703125deg-bilin.nc"
  else if (ncol.eq.86400 .and. ncol_d.eq.86402) then
    wgtpath = root + "bilin/ne40pg3_2_046875deg-bilin.nc"
  else if (ncol.eq.194402 .and. ncol_d.eq.194402) then
    wgtpath = root + "bilin/ne60np4_2_03515625deg-bilin.nc"
  else if (ncol.eq.86400 .and. ncol_d.eq.194402) then
    wgtpath = root + "bilin/ne60pg2_2_03515625deg-bilin.nc"
  else if (ncol.eq.194400 .and. ncol_d.eq.194402) then
    wgtpath = root + "bilin/ne60pg3_2_03515625deg-bilin.nc"
  else if (ncol.eq.194400 .and. ncol_d.eq.194402) then
    wgtpath = root + "bilin/ne80pg3_2_0234375deg-bilin.nc"
  else if (ncol.eq.777602 .and. ncol_d.eq.777602) then
    wgtpath = root + "ne120_2_latlon.nc"
  else if (ncol.eq.345600 .and. ncol_d.eq.777602) then
    wgtpath = root + "bilin/ne120pg2_2_017578125deg-bilin.nc"
  else if (ncol.eq.777600 .and. ncol_d.eq.777602) then
    wgtpath = root + "bilin/ne120pg3_2_017578125deg-bilin.nc"
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
  end if
  end if
  end if

else if (opt.eq.1) then

  if (ncol.eq.21600 .and. ncol_d.eq.21602) then
    wgtpath = root + "cnsrv/ne20pg3_2_09375deg-cnsrv.nc"
  else if (ncol.eq.48602 .and. ncol_d.eq.48602) then
    wgtpath = root + "cnsrv/ne30np4_2_0703125deg_cnsrv.nc"
  else if (ncol.eq.21600 .and. ncol_d.eq.48602) then
    wgtpath = root + "cnsrv/ne30pg2_2_0703125deg_cnsrv.nc"
  else if (ncol.eq.48600 .and. ncol_d.eq.48602) then
    wgtpath = root + "cnsrv/ne30pg3_2_0703125deg_cnsrv.nc"
  else if (ncol.eq.86400 .and. ncol_d.eq.86402) then
    wgtpath = root + "cnsrv/ne40pg3_2_046875deg-cnsrv.nc"
  else if (ncol.eq.194402 .and. ncol_d.eq.194402) then
    wgtpath = root + "cnsrv/ne60np4_2_03515625deg_cnsrv.nc"
  else if (ncol.eq.86400 .and. ncol_d.eq.194402) then
    wgtpath = root + "cnsrv/ne60pg2_2_03515625deg_cnsrv.nc"
  else if (ncol.eq.194400 .and. ncol_d.eq.194402) then
    wgtpath = root + "cnsrv/ne60pg3_2_03515625deg_cnsrv.nc"
  else if (ncol.eq.194400 .and. ncol_d.eq.194402) then
    wgtpath = root + "cnsrv/ne80pg3_2_0234375deg-cnsrv.nc"
  else if (ncol.eq.345600 .and. ncol_d.eq.777602) then
    wgtpath = root + "cnsrv/ne120pg2_2_017578125deg_cnsrv.nc"
  else if (ncol.eq.777600 .and. ncol_d.eq.777602) then
    wgtpath = root + "cnsrv/ne120pg3_2_017578125deg_cnsrv.nc"
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
  end if

end if 
end if

  return(wgtpath)

end

;;; find wgt_path from one nlat to nlat0
function get_wgt_path_res(nlat0,nlat)
;;;

local nlat0,nlat,wgtpath,root,host

begin

  host = getenv("HOST")
  if (host.eq."hobart.cgd.ucar.edu") then
    root = "/home/aherring/grids/"
  else
    root = "/glade/p/work/aherring/grids/grid_files/"
  end if

  if (nlat.eq.257 .and. nlat0.eq.128) then
    wgtpath = root + "ne30latlon_2_ne16latlon_cnsrv.nc"
  else if (nlat.eq.513 .and. nlat0.eq.128) then
    wgtpath = root + "ne60latlon_2_ne16latlon_cnsrv.nc"
  else if (nlat.eq.1026 .and. nlat0.eq.128) then
    wgtpath = root + "ne120latlon_2_ne16latlon_cnsrv.nc"
  else if (nlat.eq.2052 .and. nlat0.eq.128) then
    wgtpath = root + "ne240latlon_2_ne16latlon_cnsrv.nc"
  else if (nlat.eq.257 .and. nlat0.eq.193) then
    wgtpath = root + "cnsrv/0703125deg_2_09375deg-cnsrv.nc"
  else if (nlat.eq.513 .and. nlat0.eq.385) then
    wgtpath = root + "cnsrv/03515625deg_2_046875deg-cnsrv.nc"
  else if (nlat.eq.513 .and. nlat0.eq.257) then
    wgtpath = root + "cnsrv/03515625deg_2_0703125deg_cnsrv.nc"
  else if (nlat.eq.1025 .and. nlat0.eq.257) then
    wgtpath = root + "cnsrv/017578125deg_2_0703125deg_cnsrv.nc"
  else if (nlat.eq.1025 .and. nlat0.eq.513) then
    wgtpath = root + "cnsrv/017578125deg_2_03515625deg_cnsrv.nc"
  else if (nlat.eq.1025 .and. nlat0.eq.769) then
    wgtpath = root + "cnsrv/017578125deg_2_0234375deg-cnsrv.nc"
  else if (nlat.eq.1026 .and. nlat0.eq.513) then
    wgtpath = root + "ne120latlon_2_ne60latlon_cnsrv.nc"
  else if (nlat.eq.2052 .and. nlat0.eq.1026) then
    wgtpath = root + "ne240latlon_2_ne120latlon_cnsrv.nc"
  else
    wgtpath = "none"
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
  end if
  end if

  return(wgtpath)

end

;;; find vertex file
function get_vertices(ncol,ncol_d)
;;;

local ncol,root,vpath,host

begin

  host = getenv("HOST")
  if (host.eq."hobart.cgd.ucar.edu") then
    root = "/home/aherring/grids/"
  else
    root = "/glade/p/work/aherring/grids/physgrids/SCRIP_files/"
  end if

  if (ncol.eq.21600 .and. ncol_d.eq.21602) then
    vpath = root + "ne20pg3_scrip_180605.nc"
  else if (ncol.eq.21602 .and. ncol_d.eq.21602) then
    vpath = root + "ne20_scrip_180606.nc"
  else if (ncol.eq.21600 .and. ncol_d.eq.48602) then
    vpath = root + "ne30pg2_scrip_170608.nc"
  else if (ncol.eq.48600 .and. ncol_d.eq.48602) then
    vpath = root + "ne30pg3_scrip_170611.nc"
  else if (ncol.eq.86400 .and. ncol_d.eq.48602) then  
    vpath = root + "ne30pg4_scrip_170609.nc" 
  else if (ncol.eq.48602 .and. ncol_d.eq.48602) then
    vpath = root + "ne30np4_091226_pentagons.nc"
  else if (ncol.eq.86400 .and. ncol_d.eq.86402) then
    vpath = root + "ne40pg3_scrip_180605.nc"
  else if (ncol.eq.86400 .and. ncol_d.eq.194402) then
    vpath = root + "ne60pg2_scrip_170612.nc"
  else if (ncol.eq.194400 .and. ncol_d.eq.194402) then
    vpath = root + "ne60pg3_scrip_170611.nc"
  else if (ncol.eq.345600 .and. ncol_d.eq.194402) then
    vpath = root + "ne60pg4_scrip_170611.nc"
  else if (ncol.eq.194402 .and. ncol_d.eq.194402) then
    vpath = root + "ne60np4_pentagons_100408.nc"
  else if (ncol.eq.345600 .and. ncol_d.eq.345602) then
    vpath = root + "ne80pg3_scrip_180608.nc"
  else if (ncol.eq.777602 .and. ncol_d.eq.777602) then
    vpath = root + "ne120_scrip_180608.nc"
  else if (ncol.eq.345600 .and. ncol_d.eq.777602) then
    vpath = root + "ne120pg2_scrip_170629.nc"
  else if (ncol.eq.777600 .and. ncol_d.eq.777602) then
    vpath = root + "ne120pg3_scrip_170628.nc"
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
  end if
  end if
  end if
  end if
  end if

  return(vpath)

end

;;; find omega bin-bounds for pdfx_lowmem
function get_binmin_omg(ncol)
;;;
;;; binmin in Pa/s

local ncol,binmin

begin

  if (ncol.eq.13826) then
    ;;ne16np4
    binmin = -2.
  else if (ncol.eq.48602) then
    ;;ne30np4
    binmin = -5.
  else if (ncol.eq.194402) then
    ;;ne60np4
    binmin = -10.
  else if (ncol.eq.777602) then
    ;;ne120np4??
    binmin = -15.
  else if (ncol.eq.21600) then
    ;;ne30pg2
    binmin = -5.
  else if (ncol.eq.48600) then
    ;;ne30pg3
    binmin = -5.
  else if (ncol.eq.86400) then
    ;;ne30pg4/ne60pg2, not unique!
    binmin = -10.
  else if (ncol.eq.194400) then
    ;;ne60pg3
    binmin = -10.
  else if (ncol.eq.777600) then
    ;;ne120pg3
    binmin = -15. ;;-20
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if

  return(binmin)

end

;;; find prect bin-bounds for pdfx_lowmem
function get_binmax_prect(ncol)
;;;
;;; binmax in mm/day

local ncol,binmax

begin

  if (ncol.eq.13826) then
    ;;ne16np4
    binmax = 200.
  else if (ncol.eq.48602) then
    ;;ne30np4
    binmax = 400.
  else if (ncol.eq.194402) then
    ;;ne60np4
    binmax = 800.
  else if (ncol.eq.777602) then
    ;;ne120np4??
    binmax = 1500.
  else if (ncol.eq.21600) then
    ;;ne30pg2
    binmax = 400.
  else if (ncol.eq.48600) then
    ;;ne30pg3
    binmax = 404.
  else if (ncol.eq.86400) then
    ;;ne30pg4/ne60pg2, not unique!
    binmax = 800.
  else if (ncol.eq.194400) then
    ;;ne60pg3
    binmax = 800.
  end if
  end if
  end if
  end if
  end if
  end if
  end if
  end if

  return(binmax)

end



