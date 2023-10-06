/***************************************************************
Stata code for Causal Inference: What If by Miguel Hernan & Jamie Robins
Date: 10/10/2019
Author: Eleanor Murray 
For errors contact: ejmurray@bu.edu
***************************************************************/

/***************************************************************
PROGRAM 13.1
Estimating the mean outcome within levels of treatment 
and confounders: Data from NHEFS
Section 13.2
***************************************************************/
clear
use "nhefs.dta"

*Estimate the the conditional mean outcome within strata of quitting smoking and covariates, among the uncensored*/
glm wt82_71 qsmk sex race c.age##c.age ib(last).education c.smokeintensity##c.smokeintensity c.smokeyrs##c.smokeyrs ib(last).exercise ib(last).active c.wt71##c.wt71 qsmk##c.smokeintensity
predict meanY
summarize meanY

/*Look at the predicted value for subject ID = 24770*/
list meanY if seqn == 24770

/*Observed mean outcome for comparison */
summarize wt82_71


/***************************************************************
PROGRAM 13.2
Standardizing the mean outcome to the baseline confounders
Data from Table 2.2
Section 13.3
****************************************************************/

clear
input str10 ID L A Y
"Rheia" 	0 0 0 
"Kronos" 	0 0 1 
"Demeter" 	0 0 0 
"Hades" 	0 0 0 
"Hestia" 	0 1 0 
"Poseidon" 	0 1 0 
"Hera"  	0 1 0 
"Zeus" 		0 1 1 
"Artemis" 	1 0 1
"Apollo"	1 0 1
"Leto"		1 0 0
"Ares"		1 1 1
"Athena"	1 1 1
"Hephaestus" 1 1 1
"Aphrodite" 1 1 1
"Cyclope"	1 1 1
"Persephone" 1 1 1
"Hermes"	1 1 0
"Hebe"		1 1 0
"Dionysus"	1 1	0 
end

*i.Data set up for standardization: create 3 copies of each subject*
*first, duplicate the dataset and create a variable 'interv' which indicates which copy is the duplicate (interv =1)
expand 2, generate(interv)
*next, duplicate the original copy (interv = 0) again, and create another variable 'interv2' to indicate the copy
expand 2 if interv == 0, generate(interv2)
*now, change the value of 'interv' to -1 in one of the copies so that there are unique values of interv for each copy*
replace interv = -1  if interv2 ==1
drop interv2 
*check that the data has the structure you want: there should be 1566 people in each of the 3 levels of interv*
tab interv
*two of the copies will be for computing the standardized result*
*for these two copies (interv = 0 and interv = 1), set the outcome to missing and force qsmk to either 0 or 1, respectively*
*you may need to edit this part of the code for your outcome and exposure variables*
replace Y = . if interv != -1
replace A = 0 if interv == 0
replace A = 1 if interv == 1
*check that the data has the structure you want: for interv = -1, some people quit and some do not; for interv = 0 or 1, noone quits or everyone quits, respectively*
by interv, sort: summarize A

*ii.Estimation in original sample*
*Now, we do a parametric regression with the covariates we want to adjust for*
*You may need to edit this part of the code for the variables you want.*
*Because the copies have missing Y, this will only run the regression in the original copy*
*The double hash between A & L creates a regression model with A and L and a product term between A and L*
regress Y A##L
*Ask Stata for expected values - Stata will give you expected values for all copies, not just the original ones*
predict predY, xb
*Now ask for a summary of these values by intervention*
*These are the standardized outcome estimates: you can subtract them to get the standardized difference*
by interv, sort: summarize predY

*iii.OPTIONAL: Output standardized point estimates and difference*
*The summary from the last command gives you the standardized estimates*
*We can stop there, or we can ask Stata to calculate the standardized difference and display all the results in a simple table*
*The code below can be used as-is without changing any variable names*
*The option "quietly" asks Stata not to display the output of some intermediate calculations*
*You can delete this option if you want to see what is happening step-by-step*
quietly summarize predY if(interv == -1)
matrix input observe = (-1,`r(mean)')
quietly summarize predY if(interv == 0)
matrix observe = (observe \0,`r(mean)')
quietly summarize predY if(interv == 1)
matrix observe = (observe \1,`r(mean)')
matrix observe = (observe \., observe[3,2]-observe[2,2]) 
*Add some row/column descriptions and print results to screen*
matrix rownames observe = observed E(Y(a=0)) E(Y(a=1)) difference
matrix colnames observe = interv value
matrix list observe 
*to interpret these results:*
*row 1, column 2, is the observed mean outcome value in our original sample*
*row 2, column 2, is the mean outcome value if everyone had not quit smoking*
*row 3, column 2, is the mean outcome value if everyone had quit smoking*
*row 4, column 2, is the mean difference outcome value if everyone had quit smoking compared to if everyone had not quit smoking*


/***************************************************************
 PROGRAM 13.3
Standardizing the mean outcome to the baseline confounders:
Data from NHEFS
Section 13.3
***************************************************************/

clear
use "nhefs.dta"

*i.Data set up for standardization: create 3 copies of each subject*
*first, duplicate the dataset and create a variable 'interv' which indicates which copy is the duplicate (interv =1)
expand 2, generate(interv)
*next, duplicate the original copy (interv = 0) again, and create another variable 'interv2' to indicate the copy
expand 2 if interv == 0, generate(interv2)
*now, change the value of 'interv' to -1 in one of the copies so that there are unique values of interv for each copy*
replace interv = -1  if interv2 ==1
drop interv2 
*check that the data has the structure you want: there should be 1566 people in each of the 3 levels of interv*
tab interv
*two of the copies will be for computing the standardized result*
*for these two copies (interv = 0 and interv = 1), set the outcome to missing and force qsmk to either 0 or 1, respectively*
*you may need to edit this part of the code for your outcome and exposure variables*
replace wt82_71 = . if interv != -1
replace qsmk = 0 if interv == 0
replace qsmk = 1 if interv == 1
*check that the data has the structure you want: for interv = -1, some people quit and some do not; for interv = 0 or 1, noone quits or everyone quits, respectively*
by interv, sort: summarize qsmk

*ii.Estimation in original sample*
*Now, we do a parametric regression with the covariates we want to adjust for*
*You may need to edit this part of the code for the variables you want.*
*Because the copies have missing wt82_71, this will only run the regression in the original copy*
regress wt82_71 qsmk sex race c.age##c.age ib(last).education c.smokeintensity##c.smokeintensity c.smokeyrs##c.smokeyrs ib(last).exercise ib(last).active c.wt71##c.wt71 qsmk#c.smokeintensity
*Ask Stata for expected values - Stata will give you expected values for all copies, not just the original ones*
predict predY, xb
*Now ask for a summary of these values by intervention*
*These are the standardized outcome estimates: you can subtract them to get the standardized difference*
by interv, sort: summarize predY

*iii.OPTIONAL: Output standardized point estimates and difference*
*The summary from the last command gives you the standardized estimates*
*We can stop there, or we can ask Stata to calculate the standardized difference and display all the results in a simple table*
*The code below can be used as-is without changing any variable names*
*The option "quietly" asks Stata not to display the output of some intermediate calculations*
*You can delete this option if you want to see what is happening step-by-step*
quietly summarize predY if(interv == -1)
matrix input observe = (-1,`r(mean)')
quietly summarize predY if(interv == 0)
matrix observe = (observe \0,`r(mean)')
quietly summarize predY if(interv == 1)
matrix observe = (observe \1,`r(mean)')
matrix observe = (observe \., observe[3,2]-observe[2,2]) 
*Add some row/column descriptions and print results to screen*
matrix rownames observe = observed E(Y(a=0)) E(Y(a=1)) difference
matrix colnames observe = interv value
matrix list observe 
*to interpret these results:*
*row 1, column 2, is the observed mean outcome value in our original sample*
*row 2, column 2, is the mean outcome value if everyone had not quit smoking*
*row 3, column 2, is the mean outcome value if everyone had quit smoking*
*row 4, column 2, is the mean difference outcome value if everyone had quit smoking compared to if everyone had not quit smoking*



/***************************************************************
PROGRAM 13.4
Computing the 95% confidence interval of the standardized means 
and their difference: Data from NHEFS
Section 13.3
***************************************************************/

*Run program 13.3 to obtain point estimates, and then the code below*

*drop the copies*
drop if interv != -1
gen meanY_b =.
save nhefs_std, replace
capture program drop bootstdz
program define bootstdz, rclass
	u nhefs_std, clear
		preserve
		*draw bootstrap sample from original observations*
		bsample 
		*create copies with each value of qsmk in bootstrap sample*
		*first, duplicate the dataset and create a variable 'interv' which indicates which copy is the duplicate (interv =1)
		expand 2, generate(interv_b)
		*next, duplicate the original copy (interv = 0) again, and create another variable 'interv2' to indicate the copy
		expand 2 if interv_b == 0, generate(interv2_b)
		*now, change the value of 'interv' to -1 in one of the copies so that there are unique values of interv for each copy*
		replace interv_b = -1  if interv2_b ==1
		drop interv2_b
		*two of the copies will be for computing the standardized result*
		*for these two copies (interv = 0 and interv = 1), set the outcome to missing and force qsmk to either 0 or 1, respectively*
		replace wt82_71 = . if interv_b != -1
		replace qsmk = 0 if interv_b == 0
		replace qsmk = 1 if interv_b == 1
		*run regression*
		regress wt82_71 qsmk sex race c.age##c.age ib(last).education c.smokeintensity##c.smokeintensity c.smokeyrs##c.smokeyrs ib(last).exercise ib(last).active c.wt71##c.wt71 qsmk#c.smokeintensity
		*Ask Stata for expected values - Stata will give you expected values for all copies, not just the original ones*
		predict predY_b, xb
		summarize predY_b if interv_b == 0
		return scalar boot_0 = r(mean)
		summarize predY_b if interv_b == 1
		return scalar boot_1 = r(mean)
		return scalar boot_diff = return(boot_1) - return(boot_0)
	drop meanY_b
	restore
end

*Then we use the 'simulate' command to run the bootstraps as many times as we want*
*Start with reps(10) to make sure your code runs, and then change to reps(1000) to generate your final CIs*
simulate EY_a0=r(boot_0) EY_a1 = r(boot_1) difference = r(boot_diff), reps(10) seed(1): bootstdz /

*Next, format the point estimate to allow Stata to calculate our standard errors and confidence intervals
matrix pe = observe[2..4, 2]'
matrix list pe

*Finally, the bstat command generates valid 95% confidence intervals under the normal approximation using our bootstrap results*
*The default results use a normal approximation to calcutlate the confidence intervals*
*note, n contains the original sample size of your data before censoring*
bstat, stat(pe) n(1629) 

