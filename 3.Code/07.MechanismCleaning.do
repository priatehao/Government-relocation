clear all
do "projectpath.do"
cd "0.DataCleaning\1.Input"

import delimited "RelocationCities.csv", clear
gen str 城市=subinstr(city, "市", "", .)
replace 城市=subinstr(城市, "藏族自治州", "", .)
rename code 市代码
drop if 市代码==.
save RelocationCities, replace


use "金融机构网点数据（2022年4月5日更新，含经纬度和所处省市区县）.dta", clear
merge m:1 市代码 using RelocationCities
keep if _merge==3
drop _merge
gen year = year(批准成立日期)
keep 经度 纬度 year
export delimited using "FinancialInstitution.csv", replace


use "保险许可证持有机构数据（含经纬度及所在省市区县，截止2023-01-30）.dta", clear
merge m:1 市代码 using RelocationCities
keep if _merge==3
drop _merge
gen year = year(批准日期)
keep 经度 纬度 year
export delimited using "InsuranceInstitution.csv", replace

import delimited "fang_esf.csv", clear
keep 城市 竣工时间 开盘时间 交房时间 经度 纬度 价格 当期户数 总户数
merge m:1 城市 using RelocationCities
keep if _merge==3
drop _merge
export delimited using "RealEstateInfo.csv", replace

clear
forvalues i = 1998(1)2013 {
    append using `i'gqwz
    dis `i'
}
keep 年份 省自治区直辖市 行业门类代码- 行业小类代码 ///
省地县码 登记注册类型 工业总产值_当年价格千元 工业销售产值_当年价格千元 资产总计千元-应交所得税千元 县代码-纬度 从业人数合计 年初存货千元- 营业外支出千元
save IndustryInfo, replace

use IndustryInfo, clear
merge m:1 市代码 using RelocationCities
keep if _merge==3
drop _merge
export delimited using "IndustryInfo.csv", replace

erase RelocationCities.dta
