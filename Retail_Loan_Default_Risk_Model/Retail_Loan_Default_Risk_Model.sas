proc import datafile = "C:\Users\karab\Downloads\Retail_Loan_Default_Risk_Model\credit_risk_dataset.csv"
    out = loan_data
    dbms = csv
    replace;
    getnames = yes;
run;


/* CHECK FOR DUPLICATE OBSERVATIONS                                           */
proc sort data=loan_data
    out=loan_data_sorted
    nodupkey
    dupout=duplicate_rows;
    by _all_;
run;

proc sql;
    select count(*) as duplicate_count
    from duplicate_rows;
quit;


/*==========================UNDERSTANDING THE DATA==============================*/

proc means data=loan_data n nmiss mean median min max;
run;


/*==========================REMOVE DUPLICATE VALUES==============================*/

proc sort data=loan_data
    out=data_clean
    nodupkey;
    by _all_;
run;


/*==========================IMPUTING MISSING AND EXTREME VALUES==============================*/

data data_clean;
    set data_clean;

/*===============USE MEDIANS TO IMPUTE BECAUSE WE ARE DEALING WITH SKEWED DATA================*/

    if missing(person_emp_length) then person_emp_length = 4;
    if missing(loan_int_rate) then loan_int_rate = 10.99;

    if person_emp_length = 123 then person_emp_length = 4;
    if person_age > 100 then person_age = 26;

run;


/*==========================FINAL CHECK==============================*/

proc means data=data_clean n nmiss mean median min max;
run;
/*==========================DONE WITH CLEANING THE DATA==============================*/



/*==========================EXPLORATORY DATA ANALYSIS==============================*/

/*WE ARE CHECKING WHERE DO PEOPLE WHO DEFAULT THE MOST STAY*/ 
proc sql;
create table home_default as
select 
person_home_ownership,
mean(loan_status) * 100 as default_rate
from data_clean
group by person_home_ownership;
quit;

proc sgplot data=home_default;
title "Home Ownership vs Default Rate(%)";
vbar person_home_ownership / response=default_rate datalabel;
yaxis label="Default Rate (%)";
xaxis label="Home Ownership";
run;

/*CONCLUSION*/
proc odstext;
p "CONCLUSION: RENTERS HAVE THE HIGHEST OBSERVED DEFAULT RATE AMONG THE MAIN HOME-OWNERSHIP CATEGORIES. HOWEVER, THIS DOES NOT MEAN THAT RENTING CAUSES DEFAULT, AS OTHER BORROWER CHARACTERISTICS MAY ALSO EXPLAIN THE DIFFERENCE.";
run;


/*WE ARE CHECKING WHICH LOAN GRADES HAVE THE HIGHEST DEFAULT RATES*/
proc sql;
create table grade_default as
select 
loan_grade,
mean(loan_status) * 100 as default_rate
from data_clean
group by loan_grade
order by loan_grade;
quit;

proc sgplot data=grade_default;
title "Loan Grade vs Default Rate(%)";
vbar loan_grade / response=default_rate datalabel;
yaxis label="Default Rate (%)";
xaxis label="Loan Grade";
run;

/*CONCLUSION*/
proc odstext;
p "CONCLUSION: LOAN GRADE SHOWS A STRONG RELATIONSHIP WITH DEFAULT RATE. GRADE A HAS A LOW OBSERVED DEFAULT RATE, WHILE THE DEFAULT RATE INCREASES AS THE GRADE MOVES TOWARDS G. GRADE G HAS AN EXTREMELY HIGH OBSERVED DEFAULT RATE. THIS SUGGESTS THAT HIGHER-RISK LOAN GRADES ARE ASSOCIATED WITH MUCH HIGHER DEFAULT RATES IN THIS DATASET.";
run;

/*WE ARE CHECKING WHETHER THE REASON FOR TAKING A LOAN IS ASSOCIATED WITH DEFAULT RATE*/
proc sql;
create table intent_default as
select 
loan_intent,
mean(loan_status) * 100 as default_rate
from data_clean
group by loan_intent;
quit;

proc sgplot data=intent_default;
title "Loan Intent vs Default Rate (%)";
vbar loan_intent / response=default_rate datalabel;
yaxis label="Default Rate (%)";
xaxis label="Loan Intent";
run;
/*CONCLUSION*/
proc odstext;
p "CONCLUSION: LOAN INTENT APPEARS TO BE ASSOCIATED WITH DEFAULT RATE. DEBT CONSOLIDATION LOANS HAVE THE HIGHEST OBSERVED DEFAULT RATE, WHILE VENTURE LOANS HAVE THE LOWEST. THIS SUGGESTS THAT THE PURPOSE OF A LOAN MAY PROVIDE USEFUL INFORMATION WHEN ASSESSING DEFAULT RISK.";
run;

/*WE ARE CHECKING WHETHER PREVIOUS DEFAULT HISTORY IS ASSOCIATED WITH CURRENT DEFAULT*/
proc sql;
create table previous_default as
select 
cb_person_default_on_file,
mean(loan_status) * 100 as default_rate
from data_clean
group by cb_person_default_on_file;
quit;

proc sgplot data=previous_default;
title "Previous Default History vs Default Rate (%)";
vbar cb_person_default_on_file / response=default_rate datalabel;
yaxis label="Default Rate (%)";
xaxis label="Previous Default on File";
run;

/*CONCLUSION*/
proc odstext;
p "CONCLUSION: PREVIOUS DEFAULT HISTORY APPEARS TO BE STRONGLY ASSOCIATED WITH CURRENT DEFAULT. BORROWERS WITH A PREVIOUS DEFAULT ON FILE HAVE A HIGHER OBSERVED DEFAULT RATE THAN BORROWERS WITHOUT A PREVIOUS DEFAULT ON FILE. THIS SUGGESTS THAT PREVIOUS CREDIT BEHAVIOUR COULD BE AN IMPORTANT VARIABLE WHEN ASSESSING DEFAULT RISK.";
run;


/*WE ARE CHECKING WHETHER LOAN BURDEN RELATIVE TO INCOME DIFFERS BETWEEN DEFAULTING AND NON-DEFAULTING BORROWERS*/
proc sgplot data=data_clean;
    where loan_status = 0;
    title "Loan Percent Income for Non-Defaulting Borrowers";
    histogram loan_percent_income;
    xaxis label="Loan Percent Income";
    yaxis label="Number of Borrowers";
run;

proc sgplot data=data_clean;
    where loan_status = 1;
    title "Loan Percent Income for Defaulting Borrowers";
    histogram loan_percent_income;
    xaxis label="Loan Percent Income";
    yaxis label="Number of Borrowers";
run;

proc odstext;
p "CONCLUSION: LOAN PERCENT INCOME APPEARS TO BE ASSOCIATED WITH DEFAULT. BORROWERS WHO DEFAULT TEND TO HAVE A HIGHER LOAN BURDEN RELATIVE TO THEIR INCOME THAN BORROWERS WHO DO NOT DEFAULT. THIS SUGGESTS THAT THE SIZE OF A LOAN RELATIVE TO A BORROWER'S INCOME MAY BE USEFUL WHEN ASSESSING DEFAULT RISK.";
run;

/*WE ARE CHECKING WHETHER INTEREST RATE IS ASSOCIATED WITH DEFAULT*/
proc sql;
create table interest_default as
select 
loan_status,
mean(loan_int_rate) as avg_interest_rate
from data_clean
group by loan_status;
quit;

proc sgplot data=interest_default;
title "Interest Rate vs Default Status";
vbar loan_status / response=avg_interest_rate datalabel;
yaxis label="Average Interest Rate (%)";
xaxis label="Default Status";
run;

/*CONCLUSION*/
proc odstext;
p "CONCLUSION: INTEREST RATE APPEARS TO BE ASSOCIATED WITH DEFAULT. BORROWERS WHO DEFAULT TEND TO HAVE HIGHER INTEREST RATES THAN BORROWERS WHO DO NOT DEFAULT. THIS SUGGESTS THAT INTEREST RATE MAY CONTAIN INFORMATION ABOUT THE RISK LEVEL OF A LOAN.";
run;


/*WE ARE CHECKING WHETHER DEFAULT RATE CHANGES ACROSS DIFFERENT INCOME LEVELS*/
data income_groups;
set data_clean;

if person_income < 30000 then income_group = "Under 30k";
else if person_income < 50000 then income_group = "30k-50k";
else if person_income < 75000 then income_group = "50k-75k";
else if person_income < 100000 then income_group = "75k-100k";
else income_group = "100k+";
run;

proc sql;
create table income_default as
select 
income_group,
mean(loan_status) * 100 as default_rate
from income_groups
group by income_group;
quit;

proc sgplot data=income_default;
title "Income Group vs Default Rate (%)";
vbar income_group / response=default_rate datalabel;
yaxis label="Default Rate (%)";
xaxis label="Income Group";
run;

proc odstext;
p "CONCLUSION: INCOME APPEARS TO BE ASSOCIATED WITH DEFAULT. BORROWERS IN THE LOWER INCOME GROUPS HAVE HIGHER OBSERVED DEFAULT RATES, WHILE DEFAULT RATES GENERALLY DECREASE AS INCOME INCREASES. THIS SUGGESTS THAT INCOME MAY PROVIDE USEFUL INFORMATION WHEN ASSESSING DEFAULT RISK.";
run;


/*====================================================MODEL FITTING (LOGISTIC REGRESSION)=========================================================*/

ods select ParameterEstimates
 	 	   Association;

proc logistic data=data_clean;
    
class person_home_ownership (ref="MORTGAGE") loan_intent (ref="PERSONAL") loan_grade (ref="A") cb_person_default_on_file (ref="N");
        
model loan_status(event="1") =
        person_age
        person_income
        person_home_ownership
        person_emp_length
        loan_intent
        loan_grade
        loan_amnt
        loan_int_rate
        loan_percent_income
        cb_person_default_on_file
        cb_person_cred_hist_length;       
run;
ods select all;


/* SPLIT DATA INTO TRAINING AND TESTING SETS */
/* 70% TRAINING, 30% TESTING */

proc surveyselect data=data_clean
out=data_split
samprate=0.7
outall
seed=2026;
run;


/* CREATE SEPARATE TRAINING AND TESTING DATASETS */

data train test;
set data_split;

if selected = 1 then output train;
else output test;
run;

/* FIT LOGISTIC REGRESSION USING TRAINING DATA */
/* THE MODEL LEARNS FROM THE TRAINING DATA ONLY */

ods select ParameterEstimates
 	 	   Association;

proc logistic data=train;
	title "Training Dataset";
    class
        person_home_ownership (ref="MORTGAGE")
        loan_intent (ref="PERSONAL")
        loan_grade (ref="A")
        cb_person_default_on_file (ref="N");

    model loan_status(event="1") =
        person_age
        person_income
        person_home_ownership
        person_emp_length
        loan_intent
        loan_grade
        loan_amnt
        loan_int_rate
        loan_percent_income
        cb_person_default_on_file
        cb_person_cred_hist_length;

run;
ods select all;

/* APPLY THE TRAINED MODEL TO THE TEST DATA */
/* CREATE PREDICTED PROBABILITIES OF DEFAULT */
ods select ParameterEstimates
 	 	   Association;

proc logistic data=train;

    class
        person_home_ownership (ref="MORTGAGE")
        loan_intent (ref="PERSONAL")
        loan_grade (ref="A")
        cb_person_default_on_file (ref="N");

    model loan_status(event="1") =
        person_age
        person_income
        person_home_ownership
        person_emp_length
        loan_intent
        loan_grade
        loan_amnt
        loan_int_rate
        loan_percent_income
        cb_person_default_on_file
        cb_person_cred_hist_length;

    score data=test out=test_predictions;
    
run;
ods select all;


/*====================================================METRICS=========================================================*/

/*============================================================================*/
/* APPLY 30% PROBABILITY CUTOFF                                               */
/*============================================================================*/

data cutoff_predictions;
    set test_predictions;

    /* 30% cutoff */
    if P_1 >= 0.30 then pred_30 = 1;
    else pred_30 = 0;
run;


/*============================================================================*/
/* CONFUSION MATRIX                                                           */
/*============================================================================*/

proc freq data=cutoff_predictions;
    tables loan_status * pred_30 / norow nocol nopercent;
    title "Confusion Matrix - 30% Cutoff";
run;

proc odstext;
p "I initially used the standard 50% cutoff, but I noticed the sensitivity was relatively low. I tested lower cutoffs and found that 30% increased sensitivity substantially, so the model could identify more of the borrowers who actually defaulted. I understood that this came at the cost of lower specificity and precision, so I wouldn't say 30% is universally optimal. I used it in the project to illustrate the trade-off and how the cutoff can be adjusted depending on the lending objective.";
run;

/*============================================================================*/
/* CALCULATE PERFORMANCE METRICS                                              */
/*============================================================================*/

proc sql;
    create table model_metrics_counts as
    select
        sum(case when loan_status = 0 and pred_30 = 0 then 1 else 0 end) as TN,
        sum(case when loan_status = 0 and pred_30 = 1 then 1 else 0 end) as FP,
        sum(case when loan_status = 1 and pred_30 = 0 then 1 else 0 end) as FN,
        sum(case when loan_status = 1 and pred_30 = 1 then 1 else 0 end) as TP
    from cutoff_predictions;
quit;


/*============================================================================*/
/* CALCULATE METRICS                                                          */
/*============================================================================*/

data model_metrics;
    set model_metrics_counts;

    Accuracy    = (TP + TN) / (TN + FP + FN + TP);
    Sensitivity = TP / (TP + FN);
    Specificity = TN / (TN + FP);
    Precision   = TP / (TP + FP);

    format Accuracy Sensitivity Specificity Precision percent8.2;
run;


/*============================================================================*/
/* DISPLAY PERFORMANCE METRICS                                                 */
/*============================================================================*/

proc print data=model_metrics noobs;
    var Accuracy Sensitivity Specificity Precision;
    title "Loan Default Model Performance Metrics - 30% Cutoff";
run;


/*============================================================================*/
/* INTERPRETATION                                                              */
/*============================================================================*/

proc odstext;
    p "ACCURACY: Measures the proportion of all borrowers that the model classified correctly. Using a 30% probability cutoff, the model correctly classifies approximately 84% of borrowers in the test data.";

    p "SENSITIVITY/RECALL: Measures how well the model identifies borrowers who actually default. Using a 30% probability cutoff, the model identifies approximately 73% of borrowers who actually default.";

    p "SPECIFICITY: Measures how well the model identifies borrowers who do not default. Using a 30% probability cutoff, the model correctly identifies approximately 88% of borrowers who do not default.";

    p "PRECISION: Measures how often the model is correct when it predicts that a borrower will default. Using a 30% probability cutoff, approximately 62% of borrowers predicted to default actually default.";

    p "OVERALL INTERPRETATION: Lowering the probability cutoff from 50% to 30% increases sensitivity, allowing the model to identify more borrowers who actually default. However, this comes with a reduction in specificity and precision because more borrowers who do not default are classified as potential defaults. This demonstrates the trade-off involved when selecting a probability cutoff for a lending application.";
run;


/*====================================AREA UNDER THE CURVE==================================================*/
proc logistic data=train plots(only)=roc;

    class
        person_home_ownership (ref="MORTGAGE")
        loan_intent (ref="PERSONAL")
        loan_grade (ref="A")
        cb_person_default_on_file (ref="N");

    model loan_status(event="1") =
        person_age
        person_income
        person_home_ownership
        person_emp_length
        loan_intent
        loan_grade
        loan_amnt
        loan_int_rate
        loan_percent_income
        cb_person_default_on_file
        cb_person_cred_hist_length;

run;

ods graphics on;

proc logistic data=test_predictions plots(only)=roc;

    model loan_status(event="1") = / nofit;

    roc "Testing" pred=P_1;

run;

proc odstext;
p "AREA UNDER THE CURVE (AUC): The AUC summarises how well the model separates borrowers who default from borrowers who do not default.";
p "An AUC of 0.50 means the model is not separating the two groups better than random guessing. An AUC closer to 1.00 indicates stronger separation.";
p "RESULT: The test AUC is 87.07%. This means the model has a fairly strong ability to separate borrowers who default from borrowers who do not default.";
p "IMPORTANT: AUC is not the same as accuracy. It evaluates how well the model ranks borrowers by their predicted probability of default across different classification cutoffs.";
run;

data gini_result;

    /* Calculate Gini */
    Gini = (2 * 0.87066) - 1;

    format Gini percent8.2;

run;

proc print data=gini_result noobs;
    title "Retail Loan Default Risk Modelling Using Logistic Regression";
run;

proc odstext;
p "GINI: Gini is calculated from the AUC using Gini = 2(AUC) - 1. It provides another way of describing how well the model separates borrowers who default from borrowers who do not default.";
p "RESULT: The test AUC is 87.07%, which gives a Gini value of 74.13%. This indicates that the model has a fairly strong ability to separate borrowers who default from borrowers who do not default.";
p "IMPORTANT: Gini and AUC are closely related measures. Gini is not a completely separate test of the model. It is another way of expressing the information contained in the AUC.";
run;
