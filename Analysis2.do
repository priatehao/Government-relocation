clear all
do "../../0.DataCleaning/3.Code/projectpath.do"
cd "1.DataAnalysis/1.Input"
use Data2, clear
set seed 1234
graph set window fontface "Georgia"
set scheme s1color

global xvar treatment_post
global yvar light_mean
// global control_vars 降水量 平均气温 light均值
global table_option varlabel  b star(0.1 0.05 0.01) stats(r2_a N) varwidth(24) modelwidth(24)
global esttab_option replace stats( fe1 fe2 jjj r2_a N, ///
                labels("Year FE" "Community FE" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes posthead(`"\hline \addlinespace[.75ex]"') 
global esttab_option_rtf replace stats( fe1 fe2 jjj r2_a N, ///
                labels("Year FE" "Community FE" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes 
// Main Results
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table e*, $table_option keep($xvar)
esttab e* using "../2.Output/main2.tex", $esttab_option keep($xvar) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
esttab e* using "../2.Output/alternative_con_group.rtf", $esttab_option_rtf keep($xvar) rtf ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
// esttab e* using "../2.Output/main2.rtf", $esttab_option keep($xvar) rtf
/*
// estimates clear
// forvalues i=1000(250)3000 {
// 	reghdfe $yvar $xvar if ctrl_disx==`i', vce(cluster group year) absorb(group year)
// 	eststo e`i'
// 	estadd local fe1 "Yes" , replace
//     estadd local fe2 "Yes" , replace
// }
// estimates table e*, $table_option keep($xvar)
// esttab e* using "../2.Output/robustenss1.tex", $esttab_option keep($xvar) tex f ///
//  mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
// // esttab e* using "../2.Output/main.rtf", $esttab_option keep($xvar) rtf

estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i', vce(cluster group ) absorb(group year)
	eststo e`i'
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table e*, $table_option keep($xvar)
esttab e* using "../2.Output/robustness1.tex", $esttab_option keep($xvar) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
// esttab e* using "../2.Output/main.rtf", $esttab_option keep($xvar) rtf

estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar  if ctrl_disx==`i', vce(cluster group) absorb(group year i.group#c.year)
	eststo e`i'
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
    estadd local fe3 "Yes" , replace
}
estimates table e*, $table_option keep($xvar)
esttab e* using "../2.Output/robustness2.tex", replace stats( fe1 fe2 fe3 jjj r2_a N, ///
                labels("Year FE" "Community FE" "Community Year Linear Trend" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes posthead(`"\hline \addlinespace[.75ex]"')  keep($xvar) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
// esttab e* using "../2.Output/main.rtf", $esttab_option keep($xvar) rtf

estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar  if ctrl_disx==`i', vce(cluster group) absorb(group year i.group#c.year i.group#c.year2)
	eststo e`i'
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
    estadd local fe3 "Yes" , replace
    estadd local fe4 "Yes" , replace
}
estimates table e*, $table_option keep($xvar)
esttab e* using "../2.Output/robustness3.tex", replace stats( fe1 fe2 fe3 fe4 jjj r2_a N, ///
                labels("Year FE" "Community FE" "Community Year Linear Trend" "Community Year Quadratic Trend" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes posthead(`"\hline \addlinespace[.75ex]"')  keep($xvar) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
// esttab e* using "../2.Output/main.rtf", $esttab_option keep($xvar) rtf

// estimates clear
// forvalues i=1000(250)3000 {
// 	// _rmcoll light_mean treatment_post i.group i.year, expand
// 	// local all_variables `r(varlist)'
// 	// local remove_variables light_mean
// 	// local dependent_variables : list all_variables - remove_variables
// 	// qui reg light_mean `dependent_variables', vce(robust)
// 	// eststo e1  
// 	// reghdfe light_mean treatment_post if ctrl_disx==`i' & valid== "1", vce(robust) absorb(group year)
// }

* Event Study
estimates clear
forvalues i=1000(250)3000 {
	local disti = `i'/1000
	reghdfe $yvar es1 es2 es3 es4 o.es5 es6 es7 es8 es9  if ctrl_disx==`i',  vce(robust) absorb(group year)
	eststo es`i'
	coefplot es`i', omitted baselevel keep( es2 es3 es4 es5 es6 es7 es8 ) vertical ///
	recast(connect) yline(0, lp(dash)) level(95) xline(4,lp(dash)) byopts(row(1)) order( es2 es3 es4 es5 es6 es7 es8 ) /// 
	coeflabels( es2="-4" es3="-3" es4="-2" es5="-1" es6="0" es7="1" es8="2" ) ///
	title(" ") xtitle(" " "Community Radius: `disti'km") name(g`i', replace) saving("../2.Output/es`i'.gph", replace)
	graph export "../2.Output/es`i'.pdf", replace
}

* Placebo Test
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar treatment_post fake_treatment_post_1 fake_treatment_post_2 if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table e*, $table_option keep($xvar fake_treatment_post_1 fake_treatment_post_2)
esttab e* using "../2.Output/placebo.tex", $esttab_option keep($xvar fake_treatment_post_1 fake_treatment_post_2) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")


* Sensitivity
tab 市代码, gen(市代码)
estimates clear
forvalues i=1000(250)3000 {
	local disti = `i'/1000
	matrix A=J(25,2,0)
	forvalues p = 1(1)25 {
		reghdfe $yvar $xvar   ///
		if ctrl_disx==`i' & 市代码`p' ==0 , vce(robust) absorb(group year)
		estimates store e`p'_`i'
		matrix a`p'=e(b)
		matrix b`p'=e(V)
		scalar A`p'1=a`p'[1,1]
		scalar A`p'2=sqrt(b`p'[1,1])
		matrix A[`p',1]=A`p'1
		matrix A[`p',2]=A`p'2
	}

	preserve
	mat2txt, matrix(A) saving (matrixa) replace
	insheet using matrixa.txt,clear
	rename c1 coff
	rename c2 se
	gen low=coff-1.96*se
	gen high=coff+1.96*se
	egen v2=group(v1)
	graph twoway (rcap low high v2  ,lcolor(cranberry) mcolor(midred) msymbol(O) mlabcolor(black))|| ///
	 (scatter coff v2, mcolor(midblue) msymbol(O) mlabcolor(black)) ,yline(0, lpattern(dash) lcolor(black))  ///
	 legend(off) xtitle(" " "Community Radius: `disti'km") xlabel(none) scheme(s1color) //xlabel(0(10)60)
	graph export "../2.Output/sens`i'.pdf", replace 
	restore
}

global esttab_option_hetero stats( fe1 fe2 jjj r2_a N, ///
                labels("Year FE" "Community FE" "\addlinespace[.25ex]" "Adjusted R2" "Observations")) ///
                 b  star(* 0.1 ** 0.05 *** 0.01)  label depvars se nonotes ///
                  ///
 

* Heterogeneity Analysis
** Inland/Coastal
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 内陆==1, vce(robust) absorb(group year)
	eststo e`i'_inland
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_inland, $table_option keep($xvar)
esttab *_inland using "../2.Output/byregion.tex", $esttab_option_hetero replace keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km") posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel A: Inland}} \\ \addlinespace[.75ex]"') tex f

forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 内陆==0, vce(robust) absorb(group year)
	eststo e`i'_coastal
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_coastal, $table_option keep($xvar) 
esttab *_coastal using "../2.Output/byregion.tex", $esttab_option_hetero append nomtitles nonumbers keep($xvar) posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel B: Coastal}} \\ \addlinespace[.75ex]"') tex f

** Capital/NonCapital
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 省会==1, vce(robust) absorb(group year)
	eststo e`i'_Capital
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_Capital, $table_option keep($xvar)
esttab *_Capital using "../2.Output/byadminstatus.tex", $esttab_option_hetero replace keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km") posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel A: Captal}} \\ \addlinespace[.75ex]"') tex f

forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 省会==0, vce(robust) absorb(group year)
	eststo e`i'_non
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_non, $table_option keep($xvar) 
esttab *_non using "../2.Output/byadminstatus.tex", $esttab_option_hetero append nomtitles nonumbers keep($xvar) posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel B: Non-Capital}} \\ \addlinespace[.75ex]"') tex f

** Policy cutoff 2008
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 实际迁移时间<2008, vce(robust) absorb(group year)
	eststo e`i'_BeforeP
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_BeforeP, $table_option keep($xvar)
esttab *_BeforeP using "../2.Output/bypolicycutoff.tex", $esttab_option_hetero replace keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km") posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel A: Relocation Before 2008}} \\ \addlinespace[.75ex]"') tex f

forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 实际迁移时间>=2008, vce(robust) absorb(group year)
	eststo e`i'_AfterP
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_AfterP, $table_option keep($xvar) 
esttab *_AfterP using "../2.Output/bypolicycutoff.tex", $esttab_option_hetero append nomtitles nonumbers keep($xvar) posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel B: Relocation After 2008}} \\ \addlinespace[.75ex]"') tex f
