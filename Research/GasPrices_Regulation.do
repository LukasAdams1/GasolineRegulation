*-------------------------------------------------------------------------------
* The Effect of Self-Service Bans in the Retail Gasoline Market on Gasoline Prices
*             - Vitor Melo and Lukas Adams
* ------------------------------------------------------------------------------
 
clear
global GB_Directory "D:\OneDrive\GasRegulationResearch\Data"
cd $GB_Directory

*-------------------------------------------------------------------------------
* Loading and appending Gasoline Prices Data
* ------------------------------------------------------------------------------

use GBprices2016_1.dta
forvalues i = 1/12 {
	append using GBprices2016_`i'.dta
	append using GBprices2017_`i'.dta
	append using GBprices2018_`i'.dta
	append using GBprices2019_`i'.dta
}

*-------------------------------------------------------------------------------
* Creating robust station IDs and data clean up
* ------------------------------------------------------------------------------

gen long zip=real(substr(postal_code,1,5))
gen latround=round(lat,.002)
gen lnground=round(lng,.002)
gen long streetnumber=real(substr(address,1,index(address," ")-1))

egen long id1=group(streetnumber latround lnground station_nm)
gen long statidalt=statid
gsort + id1 - readdate
replace statidalt=statidalt[_n-1] if id1==id1[_n-1] & id1~=.

egen long id2=group(address zip latround lnground)
gsort + id2 - readdate
replace statidalt=statidalt[_n-1] if id2==id2[_n-1] & id2~=.
gsort + id1 - readdate
replace statidalt=statidalt[_n-1] if id1==id1[_n-1] & id1~=.

egen long id3=group(lat lng)
gsort + id3 - readdate
replace statidalt=statidalt[_n-1] if id3==id3[_n-1] & id3~=.
gsort + id2 - readdate
replace statidalt=statidalt[_n-1] if id2==id2[_n-1] & id2~=.
gsort + id1 - readdate
replace statidalt=statidalt[_n-1] if id1==id1[_n-1] & id1~=.

drop streetnumber latround lnground id1 id2 id3

rename Rcashp Rcashprice
rename Mcashp Mcashprice
rename Pcashp Pcashprice
rename Dcashp Dcashprice
rename Rcredp Rcredprice
rename Mcredp Mcredprice
rename Pcredp Pcredprice
rename Dcredp Dcredprice

* Formating data on dates
format readdate %td

* Dropping a small amount of duplicates
duplicates drop readdate statidalt, force
duplicates report readdate statidalt

xtset statidalt readdate

tsfill, full

forvalues i = 1/700 {
replace zip = zip[_n-`i'] if missing(zip) & readdate>=td(1,1,2018)
replace zip = zip[_n+`i'] if missing(zip) & readdate<=td(1,1,2018)
}

forvalues i = 1/200 {
replace zip = zip[_n-`i'] if missing(zip) & readdate>=td(1,1,2018)
replace zip = zip[_n+`i'] if missing(zip) & readdate<=td(1,1,2018)
}

forvalues i = 200/730 {
replace zip = zip[_n-`i'] if missing(zip) & readdate>=td(1,1,2018)
replace zip = zip[_n+`i'] if missing(zip) & readdate<=td(1,1,2018)
}

forvalues i = 1/200 {
replace zip = zip[_n-`i'] if missing(zip) & readdate>=td(1,1,2018)
replace zip = zip[_n+`i'] if missing(zip) & readdate<=td(1,1,2018)
}

drop if statidalt==102266
drop if statidalt==193757

count if missing(zip)

save GB_Regulation_Inital, replace

* Generating time of treatment variable
gen after2018=(readdate>=td(1,1,2018))
replace after2018 = after2018[_n-1] if missing(after2018)

* Merging with County fips codes
merge m:m zip using ZIP-COUNTY-FIPS_2016.dta
drop if _merge==1
drop if _merge==2
drop _merge

rename stcountyfp fips
drop if fips>50000
drop if fips<41000

* Merging with data on counties that were treated 
merge m:m fips using fips.dta

save GB_Regulation, replace

*-------------------------------------------------------------------------------
* Creating Teatment Variables and deliting duplicates
* ------------------------------------------------------------------------------
clear
use GB_Regulation.dta 

* Droping counties that were allowed to have half serlf-service gas stations
drop if treated==.

* Dropping a small amount of duplicates
duplicates drop readdate statidalt, force
duplicates report readdate statidalt

* Creating interation term between time of treatment and treatment status
gen aftertreated = after2018*treated

save GB_Regulation1, replace

*-------------------------------------------------------------------------------
* Diff-in-Diff analysis
* ------------------------------------------------------------------------------
clear
use GB_Regulation1.dta 

*----------------------------------
* county level aggregation + Trends test
* ---------------------------------

*Collapsing data
collapse (mean) Rcashprice, by(readdate fips)
sort fips
by fips: count if missing(Rcashprice)
sort readdate

* Generating Monthly data
gen monthly_date = mofd(readdate)
format monthly_date %tm

* Adjusting for prices
merge m:m monthly_date using cpi_monthly_cleaned.dta

gen prices = .
replace prices = Rcashprice/cpi*108.6475

drop Rcashprice
rename prices Rcashprice
drop _merge
drop cpi

*Merging with data on treatment
merge m:m fips using fips.dta
*Dropping counties that were allowed to have self-service from 6am-6pm
drop if _merge==2
drop _merge

*Generating after var and interection term
gen after2018=(monthly_date>=tm(2017m12))
gen aftertreated = after2018 * treated

* Generating Year variable
gen year = .
replace year=2016 if (monthly_date<tm(2017m1))
replace year=2019 if (monthly_date>tm(2018m12))
replace year=2017 if (monthly_date>tm(2016m12) & monthly_date<tm(2018m1))
replace year=2018 if (monthly_date>tm(2017m12) & monthly_date<tm(2019m1))

* Merging with population data
rename fips area_fips

merge m:m area_fips year using population_updated.dta

drop if _merge==1
drop if _merge==2
drop _merge

rename area_fips fips

* Merging with Poverty/income

merge m:m fips year using poverty_data.dta
drop if _merge==2
drop _merge

* Merging with Unemployment - Monthly 

merge m:m fips monthly_date using unemployment_monthly_clean.dta
drop if _merge==2
drop _merge

*Encoding county id 
encode county, gen(id)

*Dropping counties with no observations
drop if fips == 41069
drop if fips == 41021

keep Rcashprice after2018 treated aftertreated monthly_date fips county id unemprate year popestimate percentageinpoverty medianhouseholdincome readdate

* DiD analysis 
xtset id readdate
xtreg Rcashprice after2018 treated aftertreated unemprate popestimate percentageinpoverty medianhouseholdincome, cluster(fips)
xtdidregress (Rcashprice) (aftertreated), group(id) time(monthly_date) wildbootstrap(rseed(111))
xtdidregress (Rcashprice unemprate) (aftertreated), group(id) time(monthly_date) 
                                 * The results above are identical
help xtdidregress			
			 
*DiD graphs and parallel trends test (pre-treatment)
estat trendplots
estat ptrends

* Manual Graphs of means
collapse (mean) Rcashprice, by(monthly_date treated)
reshape wide Rcashprice, i(monthly_date) j(treated)
graph twoway line Rcashprice* monthly_date

*----------------------------------
* Analysis without any aggregation 
* ---------------------------------
clear
use GB_Regulation1.dta 

























* Old models:

xtset statidalt readdate

diff 

xtreg Rcashprice after2018 treated aftertreated, cluster(statidalt)


collapse (mean) Rcashprice, by(readdate treated)

reshape wide Rcashprice, i(readdate) j(treated)
graph twoway line Rcashprice* readdate

*xtdidregress (Rcashprice) (aftertreated), group(statidalt) time(readdate) nogteffects aggregate(standard) 


collapse (mean) Rcashprice, by(readdate fips)

sort fips

by fips: count if missing(Rcashprice)

sort readdate

merge m:m fips using fips.dta
drop if _merge==2
drop _merge

gen after2018=(readdate>=td(1,1,2018))
gen aftertreated = after2018*treated

save collapsed_means, replace

use collapsed_means

gen ln_price = ln(Rcashprice)
*drop if readdate>=td(1,7,2019)

xtset fips readdate

drop if fips == 41069
drop if fips == 41021

xtdidregress (Rcashprice) (aftertreated), group(fips) time(readdate) nogteffects

estat trendplots

sort readdate


xtreg price after2018 treated aftertreated, cluster(fips)

reshape wide ln_price, i(readdate) j(treated)
graph twoway line ln_price* readdate





