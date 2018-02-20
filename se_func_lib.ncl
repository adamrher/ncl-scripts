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
		p = new( (/ntime,nlevs,ncols/),"float")
		p@_FillValue = default_fillvalue("float")

		hya3d = tofloat(conform(p,hya,1))
		hyb3d = tofloat(conform(p,hyb,1))
		ps3d = p
		do k = 0,nlevs-1
			ps3d(:,k,:) = PS
		end do
	        p00 = tofloat(P0)
		p(:,:,:) = p00*hya3d + ps3d*hyb3d

	else if (topt.eq.1) then

		ncols = dims(0)
		p = new( (/nlevs,ncols/),"float")
		p@_FillValue = default_fillvalue("float")

		hya3d = tofloat(conform(p,hya,0))
		hyb3d = tofloat(conform(p,hyb,0))
		ps3d = p
		do k = 0,nlevs-1
			ps3d(k,:) = PS
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
  ntime = dims(0)
  nlevs = dims(1)
  nlat = dims(2)

  psi = new((/ntime,nlev,nlat/),double)
  do j = 0,nlat-1
    	const = 2*pi*re*cos(lat(j)*pi/180.)/g ;;;*(1.e-10)
    	do m = 0,nlev-1
     		dum = 0.d
     		do n = m,nlev-1
      			dum = vzon(:,n,j)*dp(:,n) + dum
     		end do
     		psi(:,m,j) = const*dum
    	end do
  end do

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
	pi,dimnames,dimsz,nelem,count,fcnt,j1,j2,n,i,j 

begin

  pi = 3.14159265358979
  res_p = True
  f = addfile("/home/aherring/grids/uniform_30.g.nc","r")
  ;;f = addfile("/home/aherring/grids/uniform_1.g.nc","r")
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

  res_p@gsLineThicknessF = 0.75
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



