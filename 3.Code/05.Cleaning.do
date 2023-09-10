clear all
do "../../0.DataCleaning/3.Code/projectpath.do"
cd "0.DataCleaning\2.Output"
forvalues i=1(1)3 {
import delimited "DF`i'.csv", clear
// drop if valid=="0"
// rename ctrl_dis ctrl_disx
destring 实际迁移时间 国务院批示时间 year light_mean ctrl_disx, replace force
foreach v of varlist year light_mean ctrl_disx {
	drop if `v' == .
} 
// replace 实际迁移时间=国务院批示时间 if 实际迁移时间==.
keep if year>=2000
drop if 实际迁移时间==.
drop if label == "old"
gen treatment = 1 if label=="new"
replace treatment = 0 if label=="control"
gen Post = (year>=实际迁移时间)
gen treatment_post = treatment*Post
gen year2 = year^2
// gen llight = log(light_mean+0.1)
gen llight2 = log(light_mean)
label var treatment_post "Relocation\#After"
label var llight2 "Log of Average Night Light"

gen fake_实际迁移时间_2 = 实际迁移时间 - 2
gen fake_Post_2 = (year>=fake_实际迁移时间_2)
gen fake_treatment_post_2 = treatment*fake_Post_2

gen fake_实际迁移时间_1 = 实际迁移时间 - 1
gen fake_Post_1 = (year>=fake_实际迁移时间_1)
gen fake_treatment_post_1 = treatment*fake_Post_1


gen es = -5 if year <= 实际迁移时间-5
replace es = -4 if year == 实际迁移时间-4
replace es = -3 if year == 实际迁移时间-3
replace es=-2 if year == 实际迁移时间-2
replace es=-1 if year == 实际迁移时间-1
replace es=0 if year == 实际迁移时间
replace es=1 if year == 实际迁移时间+1
replace es=2 if year == 实际迁移时间+2
replace es = 3 if year >= 实际迁移时间+3
// replace es=3 if year >= 实际迁移时间+3
tab es, gen(es)

save ../2.Output/Data`i', replace
save ../../1.DataAnalysis/1.Input/Data`i', replace
}

