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

;;; get lat of zero crossing on array of increasing lat
function get_zerocrossing(var,lat)
;;;

local var,lat,sign,nlat,i,phi

begin
	;;;the procedure is to scan for the first sign change
	sign = var/abs(var)
        nlat = dimsizes(lat)
	i = 0
	do while (sign(i).eq.sign(i+1))
	  i = i + 1
	end do
        phi = (lat(i-1) + lat(i))/2
        return(phi)
end

