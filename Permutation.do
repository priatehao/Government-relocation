clear all
graph drop _all
macro drop _all
set seed 1234
do "../../0.DataCleaning/3.Code/projectpath.do"
cd "1.DataAnalysis/1.Input"
use Data, clear

graph set window fontface "Georgia"
set scheme s1color


tab 市代码, gen(市代码)
by 市代码, sort: gen nvals = _n == 1 
count if nvals 
replace nvals = sum(nvals)
local lastn = nvals[_N]

set matsize 5000
local reps = 100
global xvar treatment_post
global yvar light_mean
// global control_vars 降水量 平均气温 light均值
global table_option varlabel  b star(0.1 0.05 0.01) stats(r2_a N) varwidth(24) modelwidth(24)
global esttab_option replace stats( fe1 fe2 jjj r2_a N, ///
                labels("Year FE" "Community FE" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes posthead(`"\hline \addlinespace[.75ex]"') 

// Main Results
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'
	local b`i' = _b[treatment_post]
	local u`i' = abs(`b`i'')
	local l`i' = -abs(`b`i'')
}

//-------------------------------------------
estimates clear
forvalues i=1000(250)3000 {
    mat B`i' = J(`reps',1,.)
}

gen simulate_year = .
forvalues k = 1(1)`reps'{
	preserve
	foreach p of varlist 市代码1-市代码`lastn' {
	    qui replace simulate_year=2000+round(20*runiform()) if `p'==1  
	}

	gen simulate_Post = (year>=simulate_year)
	gen simulate_treatment_post = treatment*simulate_Post

	forvalues i=1000(250)3000 {
	qui reghdfe $yvar simulate_treatment_post if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'
	mat B`i'[`k',1] = _b[simulate_treatment_post]
        }
	dis `k'
	restore
}

forvalues i=1000(250)3000 {
	local disti = `i'/1000
	svmat B`i', names(b`i')
	sum b`i'
	global mean`i'=r(mean)
	global lower`i'=r(mean)-2*r(sd)
	macro list  lower`i'
	global upper`i'=r(mean)+2*r(sd)
	macro list  upper`i'
	local l`i' = `l`i''*1.2
	local u`i' = `u`i''*1.2
	if ${lower`i'} < `l`i'' local l`i' = ${lower`i'}*1.2
	if ${upper`i'} > `u`i'' local u`i' = ${upper`i'}*1.2
	if `i'==1 local stage = "Exposed to the reform in 7th-9th grade"
	twoway kdensity b`i', xline(${lower`i'} ${upper`i'}, lstyle(foreground) lpattern(dash)) xline(`b`i'') ///
	ylabel() ytitle("Density", height(5)) xtitle("Treatment effect", size(small)) range(`l`i'' `u`i'') xlabel(#10, labsize(vsmall)) ///
	legend(label(1 "Distribution of placebo estimates") label(2 "Random") on) title("Community Radius: `disti'km")  name(g`i', replace) //range(${lower`i'_`v'} ${upper`i'_`v'})
	graph export "../2.Output/permutation`i'.pdf", replace

}
