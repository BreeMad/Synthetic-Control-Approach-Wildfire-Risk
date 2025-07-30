*Econ 798 Wildfires

clear

import delimited "/Users/MusicMelody/Downloads/Econ 798 Wildfire /National_Interagency_Fire_Occurrence_1992-2009__Feature_Layer_.csv", encoding(windows-1252) 

* Without Controls

collapse (mean) fire_size (count) objectid, by (state fire_year)

rename objectid num_fires

fillin state fire_year
foreach v of varlist fire_size num_fires {
    replace `v' = 0 if _fillin
}

ssc install synth, replace all

encode state, generate(states)

tsset states fire_year

synth fire_size fire_size(1992) fire_size(1994) fire_size(1998), trunit(5) trperiod(1999) xperiod(1992(1)1998) nested fig

graph save "Fire_Size.gph", replace

synth num_fires num_fires(1992) num_fires(1994) num_fires(1998), trunit(5) trperiod(1999) xperiod(1992(1)1998) nested fig

graph save "Num_Fires.gph", replace

graph combine Fire_Size.gph Num_Fires.gph, col(1) iscale(.5) title("Synthetic Control Graphs") saving(Wildfires.gph, replace)

graph use Wildfires

graph export Wildfires.pdf, replace

* With Controls

clear

import delimited "/Users/MusicMelody/Downloads/Econ 798 Wildfire /National_Interagency_Fire_Occurrence_1992-2009__Feature_Layer_.csv", encoding(windows-1252) 

tabulate stat_cause_code, generate(cause)

tabulate owner_code, generate(owner)

collapse (mean) fire_size (count) objectid (sum) lightning=cause1 (sum) equipment_use=cause2 (sum) smoking=cause3 campfire=cause4 debris_burning=cause5 railroad=cause6 arson=cause7 children=cause8 miscellaneous=cause9 fireworks=cause10 powerline=cause11 structure=cause12 missing_undefined=cause13 foreign=owner1 BLM=owner2 BIA=owner3 NPS=owner4 FWS=owner5 USFS=owner6 other_federal=owner7 State=owner8 private=owner9 tribal=owner10 BOR=owner11 state_or_private=owner12 missing_not_specified=owner13, by (state fire_year)

rename objectid num_fires

fillin state fire_year
foreach v of varlist fire_size num_fires {
    replace `v' = 0 if _fillin
}

encode state, generate(states)

tsset states fire_year

synth fire_size lightning equipment smoking campfire debris_burning railroad arson children miscellaneous fireworks powerline structure missing_undefined foreign BLM BIA NPS FWS USFS other_federal State private tribal BOR state_or_private missing_not_specified fire_size(1992) fire_size(1994) fire_size(1998), trunit(5) trperiod(1999) xperiod(1992(1)1998) nested fig

graph save "Fire_Size_Control.gph", replace

use s_out.dta, clear

gen effect = _Y_treated - _Y_synthetic

synth num_fires lightning equipment smoking campfire debris_burning railroad arson children miscellaneous fireworks powerline structure missing_undefined foreign BLM BIA NPS FWS USFS other_federal State private tribal BOR state_or_private missing_not_specified num_fires(1992) num_fires(1994) num_fires(1998), trunit(5) trperiod(1999) xperiod(1992(1)1998) nested fig

graph save "Num_Fires_Control.gph", replace

graph combine Fire_Size_Control.gph Num_Fires_Control.gph, col(1) iscale(.5) title("Graphs with Controls") saving(WildfireControl.gph, replace)

graph use WildfireControl

graph export WildfireControl.pdf, replace

***********************************************************************************************
*Placebo Test

synth_runner fire_size lightning equipment smoking campfire debris_burning railroad arson children miscellaneous fireworks powerline structure missing_undefined foreign BLM BIA NPS FWS USFS other_federal State private tribal BOR state_or_private missing_not_specified fire_size(1992) fire_size(1994) fire_size(1998), trunit(5) trperiod(1999) xperiod(1992(1)1998) keep("sr.dta") replace

use sr.dta, clear

label variable effect "Estimated Effect"

sort states fire_year

gen donor_code = states if states!= 5

levelsof(donor_code)
local donor_pool = r(levels) 

foreach dc of local donor_pool{
		local plotline_donor  "`plotline_donor' line effect fire_year if states == `dc', lc(ltblue) lwidth(thin) lpattern(solid)  || "
	}
	
twoway `plotline_donor' line effect fire_year if states == 5, lpattern(solid) lc(black) ||, legend(off) xline(1999) bgcolor(white) graphregion(color(white))	

graph save "placebo_wildfire_treat.gph", replace

graph export "placebo_wildfire_treat.pdf", replace

***********************************************************************************************

* MSPE ratios
gen mspe_ratio = post_rmspe/pre_rmspe
keep if fire_year==2009
label variable mspe_ratio "MSPE Ratio"



twoway (histogram mspe_ratio, start(0) width(.2) freq lcolor(gs6) fcolor(gs10)) ///
       (histogram mspe_ratio if states==5, start(0) width(.2) freq  ///
	   fcolor(midblue) lcolor(black)), legend(order(1 "All States" 2 "California" )) 

graph save "Wildfire_MSPE.gph", replace
graph export "Wildfire_MSPE.pdf", replace
	   
	   
gsort -mspe_ratio
gen place = _n
gen qpval = place/11
sum qpval if states==5


