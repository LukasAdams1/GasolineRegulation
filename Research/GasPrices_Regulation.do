clear
cd "D:\OneDrive\GasRegulationResearch\Data"
use GBprices2016_1.dta

forvalues i = 1/12 {
	append using GBprices2016_`i'.dta
	append using GBprices2017_`i'.dta
	append using GBprices2018_`i'.dta
	append using GBprices2019_`i'.dta
}

	
/* CREATING MORE ROBUST STATION IDs  */
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


/***  Need to figure out how to eliminate multiple observations within a statidalt and Rcash_date, while preserving the correct values for other variables. ***/

rename Rcashp Rcashprice
rename Mcashp Mcashprice
rename Pcashp Pcashprice
rename Dcashp Dcashprice
rename Rcredp Rcredprice
rename Mcredp Mcredprice
rename Pcredp Pcredprice
rename Dcredp Dcredprice

format readdate %td

gen after2018=(readdate>td(1,1,2018))

merge m:m zip using ZIP-COUNTY-FIPS_2016.dta
drop if _merge==1
drop if _merge==2
drop _merge

rename stcountyfp fips
drop if fips>50000
drop if fips<41000

merge m:m fips using fips.dta

save GB_Regulation, replace

drop if treated==.

duplicates drop readdate statidalt, force

duplicates report readdate statidalt

gen aftertreated = after2018*treated

xtset statidalt readdate

xtreg Rcashprice after2018 treated aftertreated, cluster(statidalt)

margins after2018#treated
marginsplot, xdim(after2018)


/*
gen n=_n

gen Rcashtime=mdyhms(Rcash_month,Rcash_day,Rcash_year,Rcash_hour,Rcash_min,Rcash_sec)
gen Rcredtime=mdyhms(Rcred_month,Rcred_day,Rcred_year,Rcred_hour,Rcred_min,Rcred_sec)
gen Pcashtime=mdyhms(Pcash_month,Pcash_day,Pcash_year,Pcash_hour,Pcash_min,Pcash_sec)

gen premdiff_exact=Pcashp-Rcashp if Pcashtime==Rcashtime
gen Rcreddiff_exact=Rcredp-Rcashp if Rcredtime==Rcashtime
gen Pcreddiff_exact=Pcredp-Pcashp if Pcredtime==Pcashtime
gen Dcreddiff_exact=Dcredp-Dcashp if Dcredtime==Dcashtime


drop Rcashtime Rcredtime Pcashtime

reshape long @price @_fuelname @_year @_month @_day @_hour @_min @_sec , i(n) string
drop if price==.
gen time=mdyhms(_month,_day,_year,_hour,_min,_sec)


gen long date=mdy(_month,_day,_year)
replace date=date+1 if _hour>=16


/*Drop True Duplicate Observations*/
sort statidalt _j date time
drop if statidalt==statidalt[_n-1] & time==time[_n-1]


/* Drop all but one price observation per day, with a preference for keeping prices that were observed at the same time as other fuel prices at the same station */
egen ptimemode=mode(time),by(statidalt date) maxmode
gen mark=time==ptimemode
egen maxmark=max(mark), by(statidalt date _j)
drop if mark==0 & maxmark==1

egen ptimemode2=mode(time) if mark==0,by(statidalt date) maxmode
gen mark2=time==ptimemode2  if mark==0
egen maxmark2=max(mark2) if mark==0, by(statidalt date _j)
drop if mark2==0 & maxmark2==1


egen ptimemode3=mode(time) if mark==0 & mark2==0,by(statidalt date) maxmode
gen mark3=time==ptimemode3  if mark==0  & mark2==0
egen maxmark3=max(mark3) if mark==0  & mark2==0, by(statidalt date _j)
drop if mark3==0 & maxmark3==1

egen ptimemode4=mode(time) if mark==0 & mark2==0 & mark3==0,by(statidalt date) maxmode
gen mark4=time==ptimemode4  if mark==0  & mark2==0 & mark3==0
egen maxmark4=max(mark4) if mark==0  & mark2==0 & mark3==0, by(statidalt date _j)
drop if mark4==0 & maxmark4==1


egen pcounttemp=count(price),by(statidalt date  _j)
sum pcounttemp
if r(max)>1 asdf

drop ptimemode* mark* maxmark* pcounttemp


/*  Replace values of station characteristics with mode value for the day (in order to allow the data to be reshaped to wide format). */
drop n statid readdate
egen station_nm_mode= mode(station_nm) ,by(statidalt date) maxmode
replace station_nm=station_nm_mode
egen lat_mode= mode(lat) ,by(statidalt date) maxmode
replace lat=lat_mode
egen lng_mode= mode(lng) ,by(statidalt date) maxmode
replace lng=lng_mode
egen num_pumps_mode= mode(num_pumps) ,by(statidalt date) maxmode
replace num_pumps=num_pumps_mode
egen cash_credit_mode= mode(cash_credit) ,by(statidalt date) maxmode
replace cash_credit=cash_credit_mode
egen Rcreddiff_exact_mode= mode(Rcreddiff_exact) ,by(statidalt date) maxmode
replace Rcreddiff_exact=Rcreddiff_exact_mode
egen premdiff_exact_mode= mode(premdiff_exact) ,by(statidalt date) maxmode
replace premdiff_exact=premdiff_exact_mode
egen postal_code_mode= mode(postal_code) ,by(statidalt date) maxmode
replace postal_code=postal_code_mode
egen cross2_mode= mode(cross2) ,by(statidalt date) maxmode
replace cross2=cross2_mode
egen carwash_mode= mode(carwash) ,by(statidalt date) maxmode
replace carwash=carwash_mode
egen diesel_mode= mode(diesel) ,by(statidalt date) maxmode
replace diesel=diesel_mode
egen status_mode= mode(status) ,by(statidalt date) maxmode
replace status=status_mode
egen zip_mode= mode(zip) ,by(statidalt date) maxmode
replace zip=zip_mode
egen restaurant_mode= mode(restaurant) ,by(statidalt date) maxmode
replace restaurant=restaurant_mode
egen station_alias_mode= mode(station_alias) ,by(statidalt date) maxmode
replace station_alias=station_alias_mode
egen address_mode= mode(address) ,by(statidalt date) maxmode
replace address=address_mode
egen city_mode= mode(city) ,by(statidalt date) maxmode
replace city=city_mode
egen c_store_mode= mode(c_store) ,by(statidalt date) maxmode
replace c_store=c_store_mode
egen pay_at_pump_mode= mode(pay_at_pump) ,by(statidalt date) maxmode
replace pay_at_pump=pay_at_pump_mode
egen restrooms_mode= mode(restrooms) ,by(statidalt date) maxmode
replace restrooms=restrooms_mode
egen atm_mode= mode(atm) ,by(statidalt date) maxmode
replace atm=atm_mode
*egen Q_mode= mode(Q) ,by(statidalt date) maxmode
*replace Q=Q_mode


drop station_nm_mode lat_mode lng_mode num_pumps_mode cash_credit_mode Rcreddiff_exact_mode premdiff_exact_mode station_alias_mode address_mode city_mode c_store_mode pay_at_pump_mode restrooms_mode atm_mode

rename price p
rename time _time
reshape wide @p @_fuelname @_year @_month @_day @_hour @_min @_sec @_time , i(statidalt date) j(_j) string

tsset statid date


/* Use price differences as "exact" if observation times are different but price does not change over the relevant period.  */

replace premdiff_exact=Pcashp-Rcashp if premdiff_exact==. & (     (Rcash_time>Pcash_time & Pcashp==F.Pcashp)  |   (Rcash_time<Pcash_time & Rcashp==F.Rcashp)    )
replace Rcreddiff_exact=Rcredp-Rcashp if Rcreddiff_exact==. & (     (Rcred_time>Rcash_time & Rcashp==F.Rcashp)  |   (Rcred_time<Rcash_time & Rcredp==F.Rcredp)    )
replace Pcreddiff_exact=Pcredp-Pcashp if Pcreddiff_exact==. & (     (Pcred_time>Pcash_time & Pcashp==F.Pcashp)  |   (Pcred_time<Pcash_time & Pcredp==F.Pcredp)    )
replace Dcreddiff_exact=Dcredp-Dcashp if Dcreddiff_exact==. & (     (Dcred_time>Dcash_time & Dcashp==F.Dcashp)  |   (Dcred_time<Dcash_time & Dcredp==F.Dcredp)    )


replace Rcreddiff_exact=. if Rcreddiff_exact<0
replace Pcreddiff_exact=. if Pcreddiff_exact<0
replace Dcreddiff_exact=. if Dcreddiff_exact<0


gen twoprice=cash_credit=="true"
gen twoprice_Rcurrent=Rcreddiff_exact>0 if Rcreddiff_exact~=.
gen twoprice_Pcurrent=Pcreddiff_exact>0 if Pcreddiff_exact~=.
gen twoprice_Dcurrent=Dcreddiff_exact>0 if Dcreddiff_exact~=.
egen Rcreddiffshr=mean(twoprice_Rcurrent), by(statidalt)
replace twoprice=0 if Rcreddiffshr<.25
 */



































drop *secfrac

	
/* CREATING MORE ROBUST STATION IDs  */
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


/***  Need to figure out how to eliminate multiple observations within a statidalt and Rcash_date, while preserving the correct values for other variables. ***/

rename Rcashp Rcashprice
rename Mcashp Mcashprice
rename Pcashp Pcashprice
rename Dcashp Dcashprice
rename Rcredp Rcredprice
rename Mcredp Mcredprice
rename Pcredp Pcredprice
rename Dcredp Dcredprice

gen n=_n

gen Rcashtime=mdyhms(Rcash_month,Rcash_day,Rcash_year,Rcash_hour,Rcash_min,Rcash_sec)
gen Rcredtime=mdyhms(Rcred_month,Rcred_day,Rcred_year,Rcred_hour,Rcred_min,Rcred_sec)
gen Pcashtime=mdyhms(Pcash_month,Pcash_day,Pcash_year,Pcash_hour,Pcash_min,Pcash_sec)

gen premdiff_exact=Pcashp-Rcashp if Pcashtime==Rcashtime
gen Rcreddiff_exact=Rcredp-Rcashp if Rcredtime==Rcashtime
gen Pcreddiff_exact=Pcredp-Pcashp if Pcredtime==Pcashtime
gen Dcreddiff_exact=Dcredp-Dcashp if Dcredtime==Dcashtime


drop Rcashtime Rcredtime Pcashtime

reshape long @price @_fuelname @_year @_month @_day @_hour @_min @_sec , i(n) string
drop if price==.
gen time=mdyhms(_month,_day,_year,_hour,_min,_sec)


gen long date=mdy(_month,_day,_year)
replace date=date+1 if _hour>=16


/*Drop True Duplicate Observations*/
sort statidalt _j date time
drop if statidalt==statidalt[_n-1] & time==time[_n-1]


/* Drop all but one price observation per day, with a preference for keeping prices that were observed at the same time as other fuel prices at the same station */
egen ptimemode=mode(time),by(statidalt date) maxmode
gen mark=time==ptimemode
egen maxmark=max(mark), by(statidalt date _j)
drop if mark==0 & maxmark==1

egen ptimemode2=mode(time) if mark==0,by(statidalt date) maxmode
gen mark2=time==ptimemode2  if mark==0
egen maxmark2=max(mark2) if mark==0, by(statidalt date _j)
drop if mark2==0 & maxmark2==1


egen ptimemode3=mode(time) if mark==0 & mark2==0,by(statidalt date) maxmode
gen mark3=time==ptimemode3  if mark==0  & mark2==0
egen maxmark3=max(mark3) if mark==0  & mark2==0, by(statidalt date _j)
drop if mark3==0 & maxmark3==1

egen ptimemode4=mode(time) if mark==0 & mark2==0 & mark3==0,by(statidalt date) maxmode
gen mark4=time==ptimemode4  if mark==0  & mark2==0 & mark3==0
egen maxmark4=max(mark4) if mark==0  & mark2==0 & mark3==0, by(statidalt date _j)
drop if mark4==0 & maxmark4==1


egen pcounttemp=count(price),by(statidalt date  _j)
sum pcounttemp
if r(max)>1 asdf

drop ptimemode* mark* maxmark* pcounttemp


/*  Replace values of station characteristics with mode value for the day (in order to allow the data to be reshaped to wide format). */
drop n statid readdate
egen station_nm_mode= mode(station_nm) ,by(statidalt date) maxmode
replace station_nm=station_nm_mode
egen lat_mode= mode(lat) ,by(statidalt date) maxmode
replace lat=lat_mode
egen lng_mode= mode(lng) ,by(statidalt date) maxmode
replace lng=lng_mode
egen num_pumps_mode= mode(num_pumps) ,by(statidalt date) maxmode
replace num_pumps=num_pumps_mode
egen cash_credit_mode= mode(cash_credit) ,by(statidalt date) maxmode
replace cash_credit=cash_credit_mode
egen Rcreddiff_exact_mode= mode(Rcreddiff_exact) ,by(statidalt date) maxmode
replace Rcreddiff_exact=Rcreddiff_exact_mode
egen premdiff_exact_mode= mode(premdiff_exact) ,by(statidalt date) maxmode
replace premdiff_exact=premdiff_exact_mode
egen postal_code_mode= mode(postal_code) ,by(statidalt date) maxmode
replace postal_code=postal_code_mode
egen cross2_mode= mode(cross2) ,by(statidalt date) maxmode
replace cross2=cross2_mode
egen carwash_mode= mode(carwash) ,by(statidalt date) maxmode
replace carwash=carwash_mode
egen diesel_mode= mode(diesel) ,by(statidalt date) maxmode
replace diesel=diesel_mode
egen status_mode= mode(status) ,by(statidalt date) maxmode
replace status=status_mode
egen zip_mode= mode(zip) ,by(statidalt date) maxmode
replace zip=zip_mode
egen restaurant_mode= mode(restaurant) ,by(statidalt date) maxmode
replace restaurant=restaurant_mode
egen station_alias_mode= mode(station_alias) ,by(statidalt date) maxmode
replace station_alias=station_alias_mode
egen address_mode= mode(address) ,by(statidalt date) maxmode
replace address=address_mode
egen city_mode= mode(city) ,by(statidalt date) maxmode
replace city=city_mode
egen c_store_mode= mode(c_store) ,by(statidalt date) maxmode
replace c_store=c_store_mode
egen pay_at_pump_mode= mode(pay_at_pump) ,by(statidalt date) maxmode
replace pay_at_pump=pay_at_pump_mode
egen restrooms_mode= mode(restrooms) ,by(statidalt date) maxmode
replace restrooms=restrooms_mode
egen atm_mode= mode(atm) ,by(statidalt date) maxmode
replace atm=atm_mode
*egen Q_mode= mode(Q) ,by(statidalt date) maxmode
*replace Q=Q_mode


drop station_nm_mode lat_mode lng_mode num_pumps_mode cash_credit_mode Rcreddiff_exact_mode premdiff_exact_mode station_alias_mode address_mode city_mode c_store_mode pay_at_pump_mode restrooms_mode atm_mode

rename price p
rename time _time
reshape wide @p @_fuelname @_year @_month @_day @_hour @_min @_sec @_time , i(statidalt date) j(_j) string

tsset statid date


/* Use price differences as "exact" if observation times are different but price does not change over the relevant period.  */

replace premdiff_exact=Pcashp-Rcashp if premdiff_exact==. & (     (Rcash_time>Pcash_time & Pcashp==F.Pcashp)  |   (Rcash_time<Pcash_time & Rcashp==F.Rcashp)    )
replace Rcreddiff_exact=Rcredp-Rcashp if Rcreddiff_exact==. & (     (Rcred_time>Rcash_time & Rcashp==F.Rcashp)  |   (Rcred_time<Rcash_time & Rcredp==F.Rcredp)    )
replace Pcreddiff_exact=Pcredp-Pcashp if Pcreddiff_exact==. & (     (Pcred_time>Pcash_time & Pcashp==F.Pcashp)  |   (Pcred_time<Pcash_time & Pcredp==F.Pcredp)    )
replace Dcreddiff_exact=Dcredp-Dcashp if Dcreddiff_exact==. & (     (Dcred_time>Dcash_time & Dcashp==F.Dcashp)  |   (Dcred_time<Dcash_time & Dcredp==F.Dcredp)    )


replace Rcreddiff_exact=. if Rcreddiff_exact<0
replace Pcreddiff_exact=. if Pcreddiff_exact<0
replace Dcreddiff_exact=. if Dcreddiff_exact<0


gen twoprice=cash_credit=="true"
gen twoprice_Rcurrent=Rcreddiff_exact>0 if Rcreddiff_exact~=.
gen twoprice_Pcurrent=Pcreddiff_exact>0 if Pcreddiff_exact~=.
gen twoprice_Dcurrent=Dcreddiff_exact>0 if Dcreddiff_exact~=.
egen Rcreddiffshr=mean(twoprice_Rcurrent), by(statidalt)
replace twoprice=0 if Rcreddiffshr<.25