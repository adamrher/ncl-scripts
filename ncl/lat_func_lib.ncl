;**************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"   
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
;****************************************

;;; get maxlat of a field on lat-lon grid	
function get_maxlat(var,lat,lolat,hilat)
;;;

local var,lat,lolat,hilat,rank,indx,varreg,latreg,indphi,phi

begin

	indx = ind(lat.ge.lolat .and. lat.le.hilat)
	varreg = var(indx)
	latreg = lat(indx)
	indphi = maxind(varreg)	  
	phi = latreg(indphi)

	return(phi)
end

;;; get minlat of a field on lat-lon grid
function get_minlat(var,lat,lolat,hilat)
;;;

local var,lat,lolat,hilat,rank,indx,varreg,latreg,indphi,phi

begin

        indx = ind(lat.ge.lolat .and. lat.le.hilat)
        varreg = var(indx)
        latreg = lat(indx)
        indphi = minind(varreg)
        phi = latreg(indphi)

        return(phi)
end

;;; get lat of zero crossing on lat-lon grid
function get_zerocrossing(var,lat)
;;;

local var,lat,nlat,dvar,dlat,indphi,phi

begin
	nlat = dimsizes(lat)
	dvar = var(2:nlat-1) - var(0:nlat-3)
	dlat = lat(1:nlat-2)
	indphi = maxind(dvar)
	phi = dlat(indphi)

        return(phi)
end
