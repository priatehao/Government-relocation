clear all
set seed 1234
graph set window fontface "Georgia"
set scheme s1color

do "../../0.DataCleaning/3.Code/projectpath.do"
cd "1.DataAnalysis/1.Input"

use CityBooks, clear
duplicates drop city_full_code year, force
save city, replace

import delimited "..\..\0.DataCleaning\2.Output\DF_city.csv", clear encoding(utf8)
rename 市代码 city_full_code
save DF_city, replace


import delimited "..\..\0.DataCleaning\1.Input\RelocationCities.csv", clear
destring 实际迁移时间,replace force

global esttab_option_rtf replace stats( fe1 fe2 jjj r2_a N, ///
                labels("Year FE" "Community FE" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes 

gen relocation = 1 
rename  code city_full_code
drop if  city_full_code == .
merge 1:m  city_full_code using DF_city
drop _merge
replace relocation =0 if relocation ==.
gen post = 0
replace post = 1 if 实际迁移时间<=year
gen treat_post = relocation*post
drop if 实际迁移时间<=2000
//gen llight = log(light_mean)

estimates clear
sdid light_mean city_full_code year treat_post, vce(bootstrap) seed(1213) graph g1_opt(xtitle("test1")) g2_opt(ylabel(0(50)150, axis(2)))
eststo e1
graph export "../2.Output/sdid.png", replace
esttab e* using "../2.Output/sdid1.tex", replace b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se
esttab e* using "../2.Output/sdid.rtf", $esttab_option_rtf keep(treat_post) rtf 
// estimates clear
// sdid llight city_full_code year treat_post, vce(bootstrap) seed(1213)
// eststo e1
// esttab e* using "../2.Output/sdid2.tex", replace b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se
// esttab e* using "../2.Output/sdid1.tex", append b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se








merge 1:1 year city_full_code using city
keep if _merge==3
drop _merge
duplicates drop city_full_code year, force

keep if year>=2000
drop if 实际迁移时间<=2000
bysort city_full_code: gen maxyears = _N
keep if maxyears== 20
foreach v of varlist finan secempr thirdempr2  sec_gdpr third_gdpr { //firstempr  first_gdpr 
	bys city_full_code: mipolate `v' year , gen(`v'_a) nearest
	sdid `v'_a city_full_code year treat_post, vce(bootstrap) seed(1213) graph g1_opt(xtitle("test1")) g2_opt(ylabel(0(50)150, axis(2)))
	eststo e`v'
	graph export "../2.Output/sdid`v'.png", replace
}
esttab e* using "../2.Output/sdid.rtf", $esttab_option_rtf keep(treat_post) rtf 
// gen lngdpm = ln(gdpm)
// sdid lngdpm city_full_code year treat_post, vce(bootstrap) seed(1213)


// reghdfe lngdpm treat_post,absorb(city_full_code year)

