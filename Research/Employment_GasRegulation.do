cd "C:\Users\vitor\OneDrive\Research_Resources\GasRegulation_Resources\Data\Employment_Establsh_Data"

********************************************************************************
* Coverting data to dta format and keep Oregon data


clear
insheet using "2016.total_gas_stations.csv"

gen first_two_digits = substr(area_fips, 1, 2)
drop if substr(area_fips,1,1) =="C"
drop if substr(area_fips,1,1) =="U"
destring area_fips, replace
destring first_two_digits, replace
keep if first_two_digits == 41
keep if own_code == 5

keep area_fips area_title industry_code year qtr disclosure_code qtrly_estabs_count month1_emplvl month2_emplvl month3_emplvl avg_wkly_wage total_qtrly_wages avg_wkly_wage taxable_qtrly_wages

save 2010.no_convstores_cleaned, replace 



forvalues i = 2010/2020 {
    clear
	insheet using "`i'.no_convstores.csv"

gen first_two_digits = substr(area_fips, 1, 2)
drop if substr(area_fips,1,1) =="C"
drop if substr(area_fips,1,1) =="U"
destring area_fips, replace
destring first_two_digits, replace
keep if first_two_digits == 41
keep if own_code == 5

keep area_fips area_title industry_code year qtr disclosure_code qtrly_estabs_count month1_emplvl month2_emplvl month3_emplvl avg_wkly_wage total_qtrly_wages avg_wkly_wage taxable_qtrly_wages

save `i'.no_convstores_cleaned, replace 
	
} 

forvalues i = 2010/2020 {
    clear
	insheet using "`i'.with_convstores.csv"

gen first_two_digits = substr(area_fips, 1, 2)
drop if substr(area_fips,1,1) =="C"
drop if substr(area_fips,1,1) =="U"
destring area_fips, replace
destring first_two_digits, replace
keep if first_two_digits == 41
keep if own_code == 5

keep area_fips area_title industry_code year qtr disclosure_code qtrly_estabs_count month1_emplvl month2_emplvl month3_emplvl avg_wkly_wage total_qtrly_wages avg_wkly_wage taxable_qtrly_wages

save `i'.with_convstores_cleaned, replace 
	
} 

forvalues i = 2010/2020 {
    clear
	insheet using "`i'.total_gas_stations.csv"

gen first_two_digits = substr(area_fips, 1, 2)
drop if substr(area_fips,1,1) =="C"
drop if substr(area_fips,1,1) =="U"
destring area_fips, replace
destring first_two_digits, replace
keep if first_two_digits == 41
keep if own_code == 5

keep area_fips area_title industry_code year qtr disclosure_code qtrly_estabs_count month1_emplvl month2_emplvl month3_emplvl avg_wkly_wage total_qtrly_wages avg_wkly_wage taxable_qtrly_wages

save `i'.total_gas_stations_cleaned, replace 
	
} 


clear 



********************************************************************************
*appending data for each industry aggregation


clear
use 2010.total_gas_stations_cleaned
forvalues i = 2011/2020 {
    append using `i'.total_gas_stations_cleaned
	
}

save complete_total, replace

clear
use 2010.no_convstores_cleaned
forvalues i = 2011/2020 {
    append using `i'.no_convstores_cleaned
	
}

save complete_no_convstores, replace


clear
use 2010.with_convstores_cleaned
forvalues i = 2011/2020 {
    append using `i'.with_convstores_cleaned
}

save complete_with_convstores, replace

*******************************************************************************
*Merging with population data
clear 
insheet using "Population_Counties.csv"

rename popestimate2000 population
save population.dta, replace

clear 
use complete_with_convstores.dta 
rename area_fips fips
merge m:1 fips using population.dta
save complete_with_convstores.dta, replace

clear 
use complete_no_convstores.dta 
rename area_fips fips
merge m:1 fips using population.dta
save complete_no_convstores.dta, replace

clear 
use complete_total.dta 
rename area_fips fips
merge m:1 fips using population.dta
save complete_total.dta, replace






*******************************************************************************
* Analysis for stations without convenience store


clear 
use complete_no_convstores.dta

gen qdate = yq(year, qtr)
format qdate %tq

drop _merge
merge m:1 fips using treatment_code.dta, force
keep if _merge==3
drop _merge
gen after = 1 if qdate>231
replace after = 0 if after==.
gen interaction = after*treated

xtset fips qdate
xtreg qtrly_estabs_count interaction i.qdate, fe vce(cluster fips)
xtreg qtrly_estabs_count interaction after treated, vce(cluster fips)

*drop if disclosure_code == "N"
*drop if fips == 41069
xtreg month1_emplvl interaction i.qdate, fe vce(cluster fips)
xtreg month1_emplvl interaction after treated, vce(cluster fips)


* employment per capita*100000
gen emp_pcpt = month1_emplvl/population*100000
xtreg emp_pcpt interaction i.qdate, fe vce(cluster fips)

* average_wages 
xtreg avg_wkly_wage interaction i.qdate, fe vce(cluster fips)
xtreg total_qtrly_wages interaction i.qdate, fe vce(cluster fips)

**********************************************************
* Analysis for stations with convenience store

clear 
use complete_with_convstores.dta

gen qdate = yq(year, qtr)
format qdate %tq

keep if _merge==3
drop _merge 
merge m:1 fips using treatment_code.dta, force
keep if _merge==3
drop _merge
gen after = 1 if qdate>231
replace after = 0 if after==.
gen interaction = after*treated

xtset fips qdate
xtreg qtrly_estabs_count interaction i.qdate, fe vce(cluster fips)
xtreg qtrly_estabs_count interaction after treated, vce(cluster fips)

*drop if disclosure_code == "N"
*drop if fips == 41069
xtreg month1_emplvl interaction i.qdate, fe vce(cluster fips)
xtreg month1_emplvl interaction after treated, vce(cluster fips)

* average_wages 
xtreg avg_wkly_wage interaction i.qdate, fe vce(cluster fips)
xtreg total_qtrly_wages interaction i.qdate, fe vce(cluster fips)
*******************************************************************************
*******************************************************************************
*******************************************************************************
* Analysis for total amount of stores

clear 
use complete_total.dta

gen qdate = yq(year, qtr)
format qdate %tq


keep if _merge==3
drop _merge 
merge m:1 fips using treatment_code.dta, force
keep if _merge==3
drop _merge
gen after = 1 if qdate>231
replace after = 0 if after==.
gen interaction = after*treated

xtset fips qdate
xtreg qtrly_estabs_count interaction i.qdate, fe vce(cluster fips)
xtreg qtrly_estabs_count interaction after treated, vce(cluster fips)


* Deleting surprassed observations
drop if fips == 41021 | fips == 41037 | fips == 41049 | fips == 41055 | fips == 41069

* Replacing 4 mising obervations by the observation right before it.
replace month1_emplvl = month1_emplvl[_n-1] if disclosure_code == "N"
replace avg_wkly_wage = avg_wkly_wage[_n-1] if disclosure_code == "N"
replace total_qtrly_wages = total_qtrly_wages[_n-1] if disclosure_code == "N"

* Employment 
xtreg month1_emplvl interaction i.qdate, fe vce(cluster fips)

* average_wages 
xtreg avg_wkly_wage interaction i.qdate, fe vce(cluster fips)
xtreg total_qtrly_wages interaction i.qdate, fe vce(cluster fips)

* Generating employment per gas stations
gen emp_per_station = month1_emplvl/qtrly_estabs_count
xtreg emp_per_station interaction i.qdate, fe vce(cluster fips)

* Creating means graphs for average wages
collapse (mean) avg_wkly_wage , by(qdate treated)

drop if treated == .
reshape wide avg_wkly_wage, i(qdate) j(treated)
graph twoway line avg_wkly_wage* qdate


* Creating means graphs for total wages
collapse (mean) total_qtrly_wages, by(qdate treated)

drop if treated == .
reshape wide total_qtrly_wages, i(qdate) j(treated)
graph twoway line total_qtrly_wages* qdate








******************************************************************************
*Creating total establishment data to get ratio later
clear 
use complete_total.dta

gen qdate = yq(year, qtr)
format qdate %tq

rename area_fips fips
merge m:1 fips using treatment_code.dta
keep if _merge==3
drop _merge
gen after = 1 if qdate>231
replace after = 0 if after==.
gen interaction = after*treated


gen total_establish = qtrly_estabs_count
keep fips total_establish qdate
save total_estb, replace


**********************************************************
* Analysis for ratios of store with convenience vs without
clear 
use complete_with_convstores.dta

gen qdate = yq(year, qtr)
format qdate %tq

keep if _merge==3
drop _merge 
merge m:1 fips using treatment_code.dta, force
keep if _merge==3
drop _merge
gen after = 1 if qdate>231
replace after = 0 if after==.
gen interaction = after*treated

xtset fips qdate
xtreg qtrly_estabs_count interaction i.qdate, fe vce(cluster fips)
xtreg qtrly_estabs_count interaction after treated, vce(cluster fips)

merge 1:1 fips qdate using total_estb.dta
gen conv_ratio = qtrly_estabs_count/total_establish

xtset fips qdate
xtreg conv_ratio interaction i.qdate, fe vce(cluster fips)
xtreg conv_ratio interaction after treated, vce(cluster fips)

******************************************************************************
* Analysis for total stores - Employment diff-in-diff 
clear 
use complete_total.dta

gen qdate = yq(year, qtr)
format qdate %tq

rename area_fips fips
merge m:1 fips using treatment_code.dta
keep if _merge==3
drop _merge
gen after = 1 if qdate>231
replace after = 0 if after==.
gen interaction = after*treated

xtset fips qdate
xtreg qtrly_estabs_count interaction i.qdate, fe vce(cluster fips)
xtreg qtrly_estabs_count interaction after treated, vce(cluster fips)

drop if disclosure_code == "N"
drop if fips == 41069
xtreg month1_emplvl interaction i.qdate, fe vce(cluster fips)
xtreg month1_emplvl interaction after treated, vce(cluster fips)

gen emp_per_station = month1_emplvl/qtrly_estabs_count 
xtreg emp_per_station interaction i.qdate, fe vce(cluster fips)
xtreg emp_per_station interaction after treated, vce(cluster fips)

* Creating graph of means 
collapse (mean) month1_emplvl , by(qdate treated)

drop if treated == .
reshape wide month1_emplvl, i(qdate) j(treated)
graph twoway line month1_emplvl* qdate
