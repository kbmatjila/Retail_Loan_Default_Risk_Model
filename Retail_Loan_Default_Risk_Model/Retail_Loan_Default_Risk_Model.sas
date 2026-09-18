proc import datafile = "C:\Users\karab\Downloads\Retail_Loan_Default_Risk_Model\credit_risk_dataset.csv"
out = loan_data
dbms = csv
replace;
getnames = yes;
run;

/*==========================UNDERSTANDING THE DATA==============================*/
proc means data=loan_data n nmiss mean median min max;
run;


/*==========================FREQUENCIES==============================*/
proc freq data=loan_data;
tables loan_status person_home_ownership loan_intent loan_grade cb_person_default_on_file / missing;
run;


/*==========================IMPUTING MISSING AND EXTREME VALUES==============================*/
data data_clean;
set loan_data;
/*===============USE MEDIANS TO IMPUTE BECAUSE WE ARE DEALING WITH SKEWED DATA================*/
if missing(person_emp_length) then person_emp_length = 4;
if missing(loan_int_rate) then loan_int_rate = 10.99;
if person_emp_length = 123 then person_emp_length = 4; 
if person_age > 100 then person_age = 26;
run;


/*==========================UNDERSTANDING THE DISTRIBUTION OF THE DATA==============================*/
proc means data=data_clean n nmiss min p1 p5 p25 median p75 p95 p99 max;
var person_age person_income loan_amnt loan_int_rate loan_percent_income cb_person_cred_hist_length;
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


/*=============================================MODEL FITTING==================================================*/

ods select ModelAnova
           ParameterEstimates
           OddsRatios
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

ods select ModelAnova
           ParameterEstimates
           OddsRatios
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

run;
ods select all;

/* APPLY THE TRAINED MODEL TO THE TEST DATA */
/* CREATE PREDICTED PROBABILITIES OF DEFAULT */
ods select ModelAnova
           ParameterEstimates
           OddsRatios
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

proc freq data=test_predictions;
title "Confusion Matrix";
tables loan_status * I_loan_status / norow nocol nopercent;
run;

data model_metrics;

    /* Confusion matrix values */
    TN = 7267;
    FP = 387;
    FN = 949;
    TP = 1171;

    /* Calculate metrics */
    Accuracy    = (TP + TN) / (TN + FP + FN + TP);
    Sensitivity = TP / (TP + FN);
    Specificity = TN / (TN + FP);
    Precision   = TP / (TP + FP);

    format Accuracy Sensitivity Specificity Precision percent8.2;

run;

proc print data=model_metrics noobs;
    var Accuracy Sensitivity Specificity Precision;
    title "Loan Default Model Performance Metrics";
run;

proc odstext;
    p "ACCURACY: Measures the proportion of all borrowers that the model classified correctly. The model achieved approximately 86.3% accuracy, meaning it correctly classified about 86% of borrowers in the test data.";

    p "SENSITIVITY: Measures how well the model identifies borrowers who actually default. The model achieved approximately 55.2% sensitivity, meaning it correctly identified about 55% of the borrowers who actually defaulted.";

    p "SPECIFICITY: Measures how well the model identifies borrowers who do not default. The model achieved approximately 94.9% specificity, meaning it correctly identified about 95% of borrowers who did not default.";

    p "PRECISION: Measures how often the model is correct when it predicts that a borrower will default. The model achieved approximately 75.2% precision, meaning about 75% of borrowers predicted to default actually defaulted.";

    p "OVERALL INTERPRETATION: The model has high specificity but lower sensitivity. This means the model is much better at identifying non-defaulting borrowers than detecting borrowers who actually default. The false negatives should therefore be considered when evaluating the model for lending applications.";
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

    score data=test
        out=test_roc
        outroc=roc_data;
run;

proc odstext;
    p "AREA UNDER THE CURVE (AUC): The AUC summarises how well the model separates borrowers who default from borrowers who do not default.";

    p "An AUC of 0.50 means the model is not separating the two groups better than random guessing. An AUC closer to 1.00 indicates stronger separation.";

    p "RESULT: The test AUC is 86.73%. This means the model has a fairly strong ability to separate borrowers who default from borrowers who do not default.";

    p "IMPORTANT: AUC is not the same as accuracy. It evaluates how well the model ranks borrowers by their predicted probability of default across different classification cutoffs.";
run;

data gini_result;

    /* Test AUC from the ROC analysis */
    AUC = 0.8673;

    /* Calculate Gini */
    Gini = (2 * AUC) - 1;

    format AUC Gini percent8.2;

run;

proc print data=gini_result noobs;
    title "Retail Loan Default Risk Modelling Using Logistic Regression";
run;

proc odstext;
    p "GINI: Gini is calculated from the AUC using Gini = 2(AUC) - 1. It provides another way of describing how well the model separates borrowers who default from borrowers who do not default.";

    p "RESULT: The test AUC is 86.73%, which gives a Gini value of 73.46%. This indicates that the model has a fairly strong ability to separate borrowers who default from borrowers who do not default.";

    p "IMPORTANT: Gini and AUC are closely related measures. Gini is not a completely separate test of the model. It is another way of expressing the information contained in the AUC.";
run;

/*=============================RISK SEGMENTATION=======================================*/

data lending_risk;

    set test_predictions;

    /* Predicted probability of default */
    probability_of_default = P_1;

    /* Classify borrowers into risk groups */
    if probability_of_default < 0.10 then risk_group = "Low Risk";
    else if probability_of_default < 0.30 then risk_group = "Medium Risk";
    else risk_group = "High Risk";

run;

proc sgplot data=lending_risk;

    vbar risk_group /
        categoryorder=respdesc
        datalabel;

    title "Borrowers by Predicted Risk Group";
    xaxis label="Risk Group";
    yaxis label="Number of Borrowers";

run;

proc sgplot data=risk_performance;

    vbar risk_group /
        response=actual_default_rate
        datalabel;

    title "Actual Default Rate by Predicted Risk Group";
    xaxis label="Risk Group";
    yaxis label="Actual Default Rate (%)";

run;

proc odstext;

    p "LENDING APPLICATION: The model produces a predicted probability of default for each borrower. These probabilities can be used to segment borrowers into different levels of predicted risk.";

    p "RISK SEGMENTATION: Borrowers with lower predicted probabilities of default are placed into lower-risk groups, while borrowers with higher predicted probabilities are placed into higher-risk groups.";

    p "BUSINESS USE: In a lending environment, predicted risk can be used as one input into decisions such as credit assessment, risk segmentation, pricing and portfolio monitoring. The model probability does not by itself determine whether a loan should be approved or declined.";

    p "KEY IDEA: The purpose of the model is not simply to predict default. It is to provide an estimate of borrower risk that can support the broader lending decision process.";

run;
