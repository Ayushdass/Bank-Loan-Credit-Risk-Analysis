# Bank Loan / Credit Risk Analysis — Power BI Dashboard

An end-to-end credit risk analytics project built on the **CIBIL Credit Risk Dataset**, covering data cleaning in **MySQL** and a 3-page interactive **Power BI** dashboard that segments customers by risk category (P1–P4) and surfaces high-risk accounts for action.

**Dataset:** [Leading Indian Bank and CIBIL Real World Dataset](https://www.kaggle.com/datasets/saurabhbadole/leading-indian-bank-and-cibil-real-world-dataset) (Kaggle)

## 📌 Project Overview

Banks and lenders classify loan applicants into risk bands to guide approval decisions. This project analyzes a customer base of **51,336 records** to:
- Understand the overall risk profile of the customer base
- Identify what drives higher risk (income, employment tenure, credit utilization, loan mix, demographics)
- Build a watchlist of high-risk customers (P3 + P4) for follow-up action

## 🛠️ Tools Used
- **MySQL** — data cleaning, transformation, and query-based analysis
- **Power BI** — dashboard design, DAX measures, data modeling
- **DAX** — calculated measures (Avg Credit Score, High Risk %, Avg CC Utilization, etc.)

## 📊 Dashboard Pages

### 1. Summary Dashboard
High-level KPIs and risk distribution across the entire customer base.
- Total Customers: **51,336**
- Average Credit Score: **679.86**
- % High Risk (P3+P4): **26.0%**
- Average CC Utilization: **62.83**
- Customer distribution by risk category (P1–P4)
- Average credit score and credit/loan utilization trends by risk category

![Summary Dashboard](summary%20dashboard.png)

### 2. Deep-Dive by Customer Profile
Breaks down risk by customer attributes to find patterns behind the numbers.
- Average loan count by type (Auto, CC, Personal, Home, Gold) across risk categories
- Risk category split by employment tenure and income band
- Risk distribution by gender and marital status
- Interactive slicers: Education, Approved Flag (P1–P4), Gender

![Deep-Dive by Customer Profile](deep%20drive.png)

### 3. High-Risk Customer Watchlist
An action-oriented view built for a risk/collections team.
- Watchlist table of P3/P4 customers with conditional formatting (P4 highlighted)
- Risk Count (P3+P4): **13,334** | Critical Risk Customers (P4): **5,882**
- High-risk breakdown by income band, employment tenure, and gender

![High-Risk Customer Watchlist](risk%20watch.png)

## 🔍 Key Insights
- **~26% of customers fall in the high-risk band (P3+P4)**, with P4 (critical risk) alone accounting for 5,882 customers.
- Credit score declines steadily from P1 (715.95 avg) to P4 (645.63 avg), confirming the risk segmentation is well-calibrated.
- High-risk customers skew heavily male (11,803 of 13,334) and are concentrated in the low-to-mid income bands.
- Employment tenure of 5+ years still shows the highest count of high-risk customers, suggesting tenure alone isn't a reliable risk signal — income and credit behavior matter more.
- Gold loans show a disproportionately higher average count among P1 (lowest risk) customers, hinting at a possible link between asset-backed borrowing and lower default risk.

## 📁 Repository Structure
```
├── credit_risk_analysis.sql        # Data cleaning & analysis queries (MySQL)
├── credit_risk_analysis_BI.pbix    # Power BI dashboard file
├── summary dashboard.png           # Page 1 — Summary Dashboard
├── deep drive.png                  # Page 2 — Deep-Dive by Customer Profile
├── risk watch.png                  # Page 3 — High-Risk Customer Watchlist
└── README.md
```

## 👤 Author
**Ayush**
🔗 [LinkedIn](https://www.linkedin.com/in/ayush-das-5a2b65191/)) | 💻 [GitHub](https://github.com/Ayushdass)
