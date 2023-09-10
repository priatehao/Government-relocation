clear all
do "../../0.DataCleaning/3.Code/projectpath.do"
cd "1.DataAnalysis/1.Input"
use Data1, clear
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

// sjlog using "../2.Output/bacon.tex", replace
estimates clear
xtset group year
forvalues i=2000(250)2000 {
	bacondecomp $yvar $xvar if ctrl_disx==`i', stub(Bacon_) robust
	eststo e`i'
	label drop Bacon_gp
	drop Bacon_*
	graph export "../2.Output/bacon`i'.pdf", replace 
	graph export "../2.Output/bacon`i'.png", replace 
}
esttab e* using "../2.Output/bacon.rtf", $esttab_option_rtf keep($xvar) rtf ///
// sjlog close, replace


// Main Results
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table e*, $table_option keep($xvar)
esttab e* using "../2.Output/main.tex", $esttab_option keep($xvar) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km") 
esttab e* using "../2.Output/main.rtf", $esttab_option_rtf keep($xvar) rtf ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")

// Drop overlapping comms
estimates clear
forvalues i=1000(250)3000 {
	_rmcoll light_mean treatment_post i.group i.year if ctrl_disx==`i', expand
	local all_variables `r(varlist)'
	local remove_variables light_mean
	local dependent_variables : list all_variables - remove_variables
	qui reg light_mean `dependent_variables' if ctrl_disx==`i', vce(robust)
	// reghdfe $yvar $xvar if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table e*, $table_option keep($xvar)
esttab e* using "../2.Output/drop_overlap.tex", $esttab_option keep($xvar) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
esttab e* using "../2.Output/drop_overlap.rtf", $esttab_option_rtf keep($xvar) rtf ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
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
esttab e* using "../2.Output/robustness1.rtf", $esttab_option_rtf keep($xvar) rtf ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")



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
esttab e* using "../2.Output/robustness2.rtf", $esttab_option_rtf keep($xvar) rtf ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")


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
esttab e* using "../2.Output/robustness3.rtf", $esttab_option_rtf keep($xvar) rtf ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")


* Event Study
estimates clear
forvalues i=1000(250)3000 {
	local disti = `i'/1000
	reghdfe $yvar es1 es2 es3 es4 o.es5 es6 es7 es8 es9  es10 if ctrl_disx==`i',  vce(robust) absorb(group year)
	eststo es`i'
	coefplot es`i', omitted baselevel keep( es2 es3 es4 es5 es6 es7 es8 es9 es10 ) vertical ///
	recast(connect) yline(0, lp(dash)) level(95) xline(4,lp(dash)) byopts(row(1)) order( es2 es3 es4 es5 es6 es7 es8 es9 es10) /// 
	coeflabels( es2="-4" es3="-3" es4="-2" es5="-1" es6="0" es7="1" es8="2" es9="3" es10="4" ) ///
	title(" ") xtitle(" " "Community Radius: `disti'km") name(g`i', replace) saving("../2.Output/es`i'.gph", replace)
	graph export "../2.Output/es`i'.pdf", replace
	graph export "../2.Output/es`i'.png", replace
}
estimates table es*, $table_option keep( es2 es3 es4  es6 es7 es8 es9 es10)
esttab es* using "../2.Output/event_study.tex", $esttab_option keep( es2 es3 es4  es6 es7 es8 es9 es10) tex f ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")
esttab es* using "../2.Output/event_study.rtf", $esttab_option_rtf keep( es2 es3 es4  es6 es7 es8 es9 es10) rtf ///
 mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")



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
esttab e* using "../2.Output/placebo.rtf", $esttab_option_rtf keep($xvar fake_treatment_post_1 fake_treatment_post_2) rtf ///
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
	graph export "../2.Output/sens`i'.png", replace
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
esttab *_inland using "../2.Output/byregion.rtf", $esttab_option_rtf  keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")  rtf

forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 内陆==0, vce(robust) absorb(group year)
	eststo e`i'_coastal
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_coastal, $table_option keep($xvar) 
esttab *_coastal using "../2.Output/byregion.tex", $esttab_option_hetero append nomtitles nonumbers keep($xvar) posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel B: Coastal}} \\ \addlinespace[.75ex]"') tex f
esttab *_coastal using "../2.Output/byregion2.tex", $esttab_option_hetero replace keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km") posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel A: Inland}} \\ \addlinespace[.75ex]"') tex f
esttab *_coastal using "../2.Output/byregion2.rtf", $esttab_option_rtf  keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")  rtf

**交互项系数显著性分析
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar i.内陆#c.$xvar if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'_neilujiaohu
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}

estimates table *_neilujiaohu, $table_option keep(i.内陆#c.$xvar)
esttab *_neilujiaohu using "../2.Output/byregion_neilujiaohu.tex", $esttab_option_hetero  mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")   tex f
esttab *_neilujiaohu using "../2.Output/byregion_neilujiaohu.rtf", $esttab_option_rtf  keep(i.内陆#c.$xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")  rtf








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
esttab *_Capital using "../2.Output/byadminstatus.rtf", $esttab_option_rtf  keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")  rtf

forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 省会==0, vce(robust) absorb(group year)
	eststo e`i'_non
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_non, $table_option keep($xvar) 
esttab *_non using "../2.Output/byadminstatus.tex", $esttab_option_hetero append nomtitles nonumbers keep($xvar) posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel B: Non-Capital}} \\ \addlinespace[.75ex]"') tex f
esttab *_non using "../2.Output/byadminstatus2.rtf", $esttab_option_rtf  keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")  rtf

**交互项系数显著性分析
estimates clear
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar i.省会#c.$xvar if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'_shenghuijiaohu
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}

estimates table *_shenghuijiaohu, $table_option keep($xvar)
esttab *_shenghuijiaohu using "../2.Output/byregion_shenghuijiaohu.tex", $esttab_option_hetero  mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")   tex f
esttab *_shenghuijiaohu using "../2.Output/byregion_shenghuijiaohu.rtf", $esttab_option_rtf   mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")  rtf






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
esttab *_BeforeP using "../2.Output/bypolicycutoff.rtf", $esttab_option_rtf  keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km") rtf

forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar if ctrl_disx==`i' & 实际迁移时间>=2008, vce(robust) absorb(group year)
	eststo e`i'_AfterP
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}
estimates table *_AfterP, $table_option keep($xvar) 
esttab *_AfterP using "../2.Output/bypolicycutoff.tex", $esttab_option_hetero append nomtitles nonumbers keep($xvar) posthead(`"\midrule \addlinespace[.75ex] \multicolumn{10}{l}{\textbf{Panel B: Relocation After 2008}} \\ \addlinespace[.75ex]"') tex f
esttab *_AfterP using "../2.Output/bypolicycutoff2.rtf", $esttab_option_rtf  keep($xvar) mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km") rtf
**交互项系数显著性分析
estimates clear
gen 迁移时间 = 1
replace 迁移时间 = 0 if 实际迁移时间>=2008
forvalues i=1000(250)3000 {
	reghdfe $yvar $xvar i.迁移时间#c.$xvar if ctrl_disx==`i', vce(robust) absorb(group year)
	eststo e`i'_shijianjiaohu
	estadd local fe1 "Yes" , replace
    estadd local fe2 "Yes" , replace
}

estimates table *_shijianjiaohu, $table_option keep($xvar)
esttab *_shijianjiaohu using "../2.Output/byregion_shijianjiaohu.tex", $esttab_option_hetero  mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")   tex f
esttab *_shijianjiaohu using "../2.Output/byregion_shijianjiaohu.rtf", $esttab_option_rtf mtitles("1km" "1.25km" "1.50km" "1.75km" "2km" "2.25km" "2.50km" "2.75km" "3km")  rtf


* Summary
estimates clear
destring light_min light_max light_std, replace
estpost summarize light_mean light_min light_max light_std ctrl_disx
esttab . using "../2.Output/summary.rtf", cells("count mean(fmt(%5.3f))  sd(fmt(%5.3f))") label title(Descriptive Summary\label{table: summary}) ///
nomtitles nodepvars nonumbers replace rtf
