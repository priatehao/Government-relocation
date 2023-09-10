clear all
do "../../0.DataCleaning/3.Code/projectpath.do"
cd "0.DataCleaning/1.Input"
local flist fin_inst ins_inst enterprise realestate realestateprice realestatehh
foreach f of local flist {
import delimited "`f'.csv", clear
// keep if year>=2000
drop if year>2013 & "`f'"=="enterprise"
drop if year>2018 & "`f'"=="realestate"
drop if year>2018 & "`f'"=="realestateprice"
drop if year>2018 & "`f'"=="realestatehh"
drop if label == "old"
gen treatment = 1 if label == "new"
replace treatment = 0 if label == "control"
drop if 实际迁移时间 ==.
gen post = 1 if year >= 实际迁移时间
replace post = 0 if year < 实际迁移时间
gen treatment_post = treatment*post
save "../../1.DataAnalysis/1.Input/`f'.dta", replace
}

do "../../0.DataCleaning/3.Code/projectpath.do"
cd "1.DataAnalysis/1.Input"
set seed 1234
graph set window fontface "Georgia"
set scheme s1color
global xvar treatment_post 

// global control_vars 降水量 平均气温 light均值
global table_option varlabel  b star(0.1 0.05 0.01) stats(r2_a N) varwidth(24) modelwidth(24)
global esttab_option replace stats( fe1 fe2 jjj r2_a N, ///
                labels("Year FE" "Community FE" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes posthead(`"\hline \addlinespace[.75ex]"') 
global esttab_option_rtf replace stats( fe1 fe2 jjj r2_a N, ///
                labels("Year FE" "Community FE" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes 



local flist fin_inst ins_inst enterprise realestate realestateprice realestatehh
foreach f of local flist {
global yvar `f'_count
if "`f'"=="realestateprice" {
global yvar realestate_avgprice //log_realestate_avgprice //
}
if "`f'"=="realestatehh" {
global yvar realestate_totalhh //log_realestate_avgprice //
}

use `f', clear
// Mechanism
estimates clear
forvalues i=1000(250)3000 {
	qui reghdfe $yvar $xvar if ctrl_dis==`i', vce(robust) absorb(group year)
	eststo e`i'
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table e*, $table_option keep($xvar)
esttab e* using "../2.Output/mechanism`f'.tex", $esttab_option keep($xvar) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
 esttab e* using "../2.Output/mechanism`f'.rtf", $esttab_option keep($xvar) rtf ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
 
}



