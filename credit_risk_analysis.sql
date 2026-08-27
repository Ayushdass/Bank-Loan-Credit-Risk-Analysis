-- ============================================================
-- PROJECT: Bank Loan / Credit Risk Analysis
-- Dataset : Leading Indian Bank & CIBIL Real-World Dataset
-- Author  : Ayush Das
-- ============================================================

-- ============================================================
-- SECTION 1: DATABASE & SCHEMA SETUP
-- ============================================================

CREATE DATABASE IF NOT EXISTS credit_risk_analysis;
USE credit_risk_analysis;

-- Internal Bank Data: customer's own trade-line / loan account summary
CREATE TABLE internal_bank_data (
    PROSPECTID INT PRIMARY KEY,
    Total_TL INT,
    Tot_Closed_TL INT,
    Tot_Active_TL INT,
    Total_TL_opened_L6M INT,
    Tot_TL_closed_L6M INT,
    pct_tl_open_L6M DOUBLE,
    pct_tl_closed_L6M DOUBLE,
    pct_active_tl DOUBLE,
    pct_closed_tl DOUBLE,
    Total_TL_opened_L12M INT,
    Tot_TL_closed_L12M INT,
    pct_tl_open_L12M DOUBLE,
    pct_tl_closed_L12M DOUBLE,
    Tot_Missed_Pmnt INT,
    Auto_TL INT,
    CC_TL INT,
    Consumer_TL INT,
    Gold_TL INT,
    Home_TL INT,
    PL_TL INT,
    Secured_TL INT,
    Unsecured_TL INT,
    Other_TL INT,
    Age_Oldest_TL INT,
    Age_Newest_TL INT
);

-- External CIBIL Data: credit bureau data (delinquency, enquiries, score, demographics)
-- NOTE: DOUBLE used for percentage/ratio columns because the dataset uses a
-- large negative placeholder (-99999) for missing values, which DECIMAL(6,3)
-- cannot store (caused "Out of range value" import error).
CREATE TABLE external_cibil_data (
    PROSPECTID INT PRIMARY KEY,
    time_since_recent_payment INT,
    time_since_first_deliquency INT,
    time_since_recent_deliquency INT,
    num_times_delinquent INT,
    max_delinquency_level INT,
    max_recent_level_of_deliq INT,
    num_deliq_6mts INT,
    num_deliq_12mts INT,
    num_deliq_6_12mts INT,
    max_deliq_6mts INT,
    max_deliq_12mts INT,
    num_times_30p_dpd INT,
    num_times_60p_dpd INT,
    num_std INT,
    num_std_6mts INT,
    num_std_12mts INT,
    num_sub INT,
    num_sub_6mts INT,
    num_sub_12mts INT,
    num_dbt INT,
    num_dbt_6mts INT,
    num_dbt_12mts INT,
    num_lss INT,
    num_lss_6mts INT,
    num_lss_12mts INT,
    recent_level_of_deliq INT,
    tot_enq INT,
    CC_enq INT,
    CC_enq_L6m INT,
    CC_enq_L12m INT,
    PL_enq INT,
    PL_enq_L6m INT,
    PL_enq_L12m INT,
    time_since_recent_enq INT,
    enq_L12m INT,
    enq_L6m INT,
    enq_L3m INT,
    MARITALSTATUS VARCHAR(20),
    EDUCATION VARCHAR(30),
    AGE INT,
    GENDER VARCHAR(10),
    NETMONTHLYINCOME DECIMAL(12,2),
    Time_With_Curr_Empr INT,
    pct_of_active_TLs_ever DOUBLE,
    pct_opened_TLs_L6m_of_L12m DOUBLE,
    pct_currentBal_all_TL DOUBLE,
    CC_utilization DOUBLE,
    CC_Flag INT,
    PL_utilization DOUBLE,
    PL_Flag INT,
    pct_PL_enq_L6m_of_L12m DOUBLE,
    pct_CC_enq_L6m_of_L12m DOUBLE,
    pct_PL_enq_L6m_of_ever DOUBLE,
    pct_CC_enq_L6m_of_ever DOUBLE,
    max_unsec_exposure_inPct DOUBLE,
    HL_Flag INT,
    GL_Flag INT,
    last_prod_enq2 VARCHAR(20),
    first_prod_enq2 VARCHAR(20),
    Credit_Score INT,
    Approved_Flag VARCHAR(5),      -- Risk grade: P1 (best) to P4 (worst)
    FOREIGN KEY (PROSPECTID) REFERENCES internal_bank_data(PROSPECTID)
);

-- ============================================================
-- SECTION 2: DATA LOAD
-- Load order matters: parent table (internal_bank_data) first,
-- then child table (external_cibil_data) due to the FK constraint.
-- Update file paths to match your local machine before running.
-- ============================================================

LOAD DATA LOCAL INFILE 'C:/Users/dasaa/Downloads/Internal_Bank_Dataset.csv'
INTO TABLE internal_bank_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE 'C:/Users/dasaa/Downloads/External_Cibil_Dataset.csv'
INTO TABLE external_cibil_data
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- ============================================================
-- SECTION 3: DATA CLEANING
-- ============================================================

-- Approved_Flag values (P1/P2/P3/P4) came in with hidden trailing
-- whitespace/carriage-return characters from the CSV, which caused
-- exact-match filters (WHERE Approved_Flag = 'P4') to silently
-- return zero rows. Cleaning it here, once, for all downstream queries.
SET SQL_SAFE_UPDATES = 0;

UPDATE external_cibil_data
SET Approved_Flag = TRIM(BOTH '\r' FROM TRIM(Approved_Flag));

-- ============================================================
-- SECTION 4: DATA QUALITY CHECK
-- ============================================================

SELECT
    COUNT(*) AS total_rows,
    COUNT(*) - COUNT(Credit_Score) AS missing_credit_score,
    COUNT(*) - COUNT(NETMONTHLYINCOME) AS missing_income,
    COUNT(*) - COUNT(AGE) AS missing_age
FROM external_cibil_data;

-- ============================================================
-- SECTION 5: KPI ANALYSIS
-- ============================================================

-- KPI 1: Risk Category (Approved_Flag) Distribution
-- Insight: P2 (moderate-good risk) holds the majority (~63%) of customers;
-- only ~11% qualify as P1 (best risk). High-risk P3+P4 = ~26% combined.
SELECT
    Approved_Flag,
    COUNT(*) AS total_customers,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM external_cibil_data), 2) AS pct_share
FROM external_cibil_data
GROUP BY Approved_Flag
ORDER BY Approved_Flag;

-- KPI 2: Credit Score vs Risk Category (quartile-based)
-- Fixed score bands (750/650/550) don't work for this dataset because
-- scores are tightly clustered (min 469, max 811, std dev only ~20.5).
-- Quartiles (NTILE) give a meaningful, balanced comparison instead.
-- Insight: Lowest score quartile is dominated by P3/P4; highest quartile
-- is dominated by P1 -- confirming Credit_Score is a strong risk predictor.
WITH scored AS (
    SELECT
        Credit_Score,
        Approved_Flag,
        NTILE(4) OVER (ORDER BY Credit_Score) AS score_quartile
    FROM external_cibil_data
)
SELECT
    score_quartile,
    MIN(Credit_Score) AS min_score,
    MAX(Credit_Score) AS max_score,
    Approved_Flag,
    COUNT(*) AS customer_count
FROM scored
GROUP BY score_quartile, Approved_Flag
ORDER BY score_quartile, Approved_Flag;

-- KPI 3: Delinquency & Missed Payments vs Risk Category
-- Insight: P4 has the highest delinquency/missed-payments as expected,
-- but P1 shows moderate historical delinquency too (higher than P2) --
-- suggesting risk grading isn't based on payment history alone.
SELECT
    e.Approved_Flag,
    ROUND(AVG(i.Tot_Missed_Pmnt), 2) AS avg_missed_payments,
    ROUND(AVG(e.num_times_delinquent), 2) AS avg_delinquency_count,
    ROUND(AVG(e.num_times_30p_dpd), 2) AS avg_30plus_dpd,
    ROUND(AVG(e.num_times_60p_dpd), 2) AS avg_60plus_dpd
FROM internal_bank_data i
JOIN external_cibil_data e ON i.PROSPECTID = e.PROSPECTID
GROUP BY e.Approved_Flag
ORDER BY e.Approved_Flag;

-- KPI 4: Income, Credit Utilization & Enquiries vs Risk Category
-- NOTE: -99999 is used as a placeholder for missing values in this dataset,
-- so it's excluded via CASE WHEN >= 0 to avoid distorting the averages.
-- Insight (strongest finding): P4 has the highest CC/PL utilization (71%/83%)
-- and highest enquiry frequency (10.24) -- "credit-hungry" behavior.
-- P1 shows the most disciplined usage (lowest utilization and enquiries).
SELECT
    Approved_Flag,
    ROUND(AVG(CASE WHEN NETMONTHLYINCOME >= 0 THEN NETMONTHLYINCOME END), 0) AS avg_income,
    ROUND(AVG(CASE WHEN CC_utilization >= 0 THEN CC_utilization END), 2) AS avg_cc_utilization,
    ROUND(AVG(CASE WHEN PL_utilization >= 0 THEN PL_utilization END), 2) AS avg_pl_utilization,
    ROUND(AVG(CASE WHEN tot_enq >= 0 THEN tot_enq END), 2) AS avg_total_enquiries
FROM external_cibil_data
GROUP BY Approved_Flag
ORDER BY Approved_Flag;

-- KPI 5: Loan Type-wise Exposure vs Risk Category
-- Insight: P1 customers actually hold MORE accounts across every loan type
-- (especially Gold Loans) -- suggesting P1 = experienced, established
-- borrowers with diversified, well-managed credit, not "fewer loans."
SELECT
    e.Approved_Flag,
    ROUND(AVG(i.Auto_TL), 2) AS avg_auto_loans,
    ROUND(AVG(i.CC_TL), 2) AS avg_credit_cards,
    ROUND(AVG(i.PL_TL), 2) AS avg_personal_loans,
    ROUND(AVG(i.Home_TL), 2) AS avg_home_loans,
    ROUND(AVG(i.Gold_TL), 2) AS avg_gold_loans
FROM internal_bank_data i
JOIN external_cibil_data e ON i.PROSPECTID = e.PROSPECTID
GROUP BY e.Approved_Flag
ORDER BY e.Approved_Flag;

-- KPI 6 (optional): Education & Age vs Risk Category
SELECT
    EDUCATION,
    Approved_Flag,
    COUNT(*) AS customer_count,
    ROUND(AVG(AGE), 1) AS avg_age
FROM external_cibil_data
GROUP BY EDUCATION, Approved_Flag
ORDER BY EDUCATION, Approved_Flag;

-- ============================================================
-- BUSINESS QUESTIONS: Bank Loan / Credit Risk Analysis
-- ------------------------------------------------------------
-- Q1: Which high-risk (P4) customers still have a large number
--     of active trade lines? These should be prioritized for
--     monitoring since they carry active exposure.
-- ------------------------------------------------------------
SELECT
    e.PROSPECTID,
    e.Approved_Flag,
    i.Tot_Active_TL,
    i.Tot_Missed_Pmnt,
    e.Credit_Score
FROM internal_bank_data i
JOIN external_cibil_data e ON i.PROSPECTID = e.PROSPECTID
WHERE TRIM(e.Approved_Flag) = 'P4'
ORDER BY i.Tot_Active_TL DESC
LIMIT 20;

-- ------------------------------------------------------------
-- Q2: Does higher income actually mean lower risk?
--     Bucket customers into income bands and check the
--     risk-category split within each band.
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN NETMONTHLYINCOME >= 50000 THEN 'High Income (50k+)'
        WHEN NETMONTHLYINCOME >= 25000 THEN 'Mid Income (25k-50k)'
        WHEN NETMONTHLYINCOME >= 0 THEN 'Low Income (<25k)'
        ELSE 'Unknown'
    END AS income_band,
    Approved_Flag,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (
        PARTITION BY CASE
            WHEN NETMONTHLYINCOME >= 50000 THEN 'High Income (50k+)'
            WHEN NETMONTHLYINCOME >= 25000 THEN 'Mid Income (25k-50k)'
            WHEN NETMONTHLYINCOME >= 0 THEN 'Low Income (<25k)'
            ELSE 'Unknown'
        END
    ), 2) AS pct_within_income_band
FROM external_cibil_data
WHERE NETMONTHLYINCOME >= 0
GROUP BY income_band, Approved_Flag
ORDER BY income_band, Approved_Flag;
 
-- ------------------------------------------------------------
-- Q3: How many customers have Credit Card utilization above 50%,
--     and what percentage of them fall into high-risk (P3/P4)?
-- ------------------------------------------------------------
SELECT
    COUNT(*) AS total_high_utilization_customers,
    SUM(CASE WHEN Approved_Flag IN ('P3', 'P4') THEN 1 ELSE 0 END) AS high_risk_count,
    ROUND(SUM(CASE WHEN Approved_Flag IN ('P3', 'P4') THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS pct_high_risk
FROM external_cibil_data
WHERE CC_utilization >= 0.50;
 
-- ------------------------------------------------------------
-- Q4: Are there customers with unusually high enquiries (10+)
--     who still fall into the low-risk categories (P1/P2)?
--     This flags an inconsistent or unusual profile.
-- ------------------------------------------------------------
SELECT
    PROSPECTID,
    Approved_Flag,
    tot_enq,
    Credit_Score,
    CC_utilization,
    PL_utilization
FROM external_cibil_data
WHERE tot_enq >= 10
  AND Approved_Flag IN ('P1', 'P2')
ORDER BY tot_enq DESC
LIMIT 20;
 
-- ------------------------------------------------------------
-- Q5: Does marital status show any difference in risk profile?
-- ------------------------------------------------------------
SELECT
    MARITALSTATUS,
    Approved_Flag,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY MARITALSTATUS), 2) AS pct_within_status
FROM external_cibil_data
GROUP BY MARITALSTATUS, Approved_Flag
ORDER BY MARITALSTATUS, Approved_Flag;
 
-- ------------------------------------------------------------
-- Q6: Do customers with shorter employment tenure carry higher risk?
-- ------------------------------------------------------------
SELECT
    CASE
        WHEN Time_With_Curr_Empr >= 60 THEN '5+ years'
        WHEN Time_With_Curr_Empr >= 24 THEN '2-5 years'
        WHEN Time_With_Curr_Empr >= 0 THEN 'Under 2 years'
        ELSE 'Unknown'
    END AS employment_tenure_band,
    Approved_Flag,
    COUNT(*) AS customer_count
FROM external_cibil_data
WHERE Time_With_Curr_Empr >= 0
GROUP BY employment_tenure_band, Approved_Flag
ORDER BY employment_tenure_band, Approved_Flag;
 
-- ------------------------------------------------------------
-- Q7: Is the risk-category distribution significantly different
--     across genders?
-- ------------------------------------------------------------
SELECT
    GENDER,
    Approved_Flag,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY GENDER), 2) AS pct_within_gender
FROM external_cibil_data
GROUP BY GENDER, Approved_Flag
ORDER BY GENDER, Approved_Flag;
 
-- ------------------------------------------------------------
-- Q8: Build a "watchlist" of the top 10 riskiest customers,
--     ranked by combined delinquency count and credit utilization.
-- ------------------------------------------------------------
SELECT
    e.PROSPECTID,
    e.Approved_Flag,
    e.num_times_delinquent,
    e.CC_utilization,
    e.PL_utilization,
    e.tot_enq,
    e.Credit_Score
FROM external_cibil_data e
WHERE e.CC_utilization >= 0 
  AND e.PL_utilization >= 0
  AND e.num_times_delinquent IS NOT NULL
ORDER BY e.num_times_delinquent DESC, (e.CC_utilization + e.PL_utilization) DESC
LIMIT 10;
