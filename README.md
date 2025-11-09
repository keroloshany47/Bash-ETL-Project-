# BrewTopia Coffee Shop ETL Pipeline

##  Overview
BrewTopia ETL Pipeline integrates sales data from multiple sources (online orders, in-store sales, and inventory) into unified reports for business analysis.  

**Key Features:**
- Multi-source data extraction (JSON, CSV, MySQL)  
- Data transformation and validation  
- Automated daily reports  
- Low inventory alerts via email  
- Cron scheduling for automation  
- Logging and error handling  

---

##  Architecture

```

Data Sources (JSON/CSV/MySQL)
│
▼
Extract & Transform
│
▼
Merge & Analyze
│
▼
Reports & Alerts

```

**Directory Structure:**
```

coffee_etl_project/
├── config/       # config.env
├── data/         # sales files
├── sql/          # DB initialization
├── scripts/      # ETL scripts
├── logs/         # logs
├── reports/      # daily reports
└── temp/         # temp files

````

---

##  Installation & Setup

1. **Install dependencies (Ubuntu/Debian):**
```bash
sudo apt-get update
sudo apt-get install -y jq mysql-client mailutils
````

2. **Initialize database:**

```bash
mysql -u root -p < sql/init_coffee_db.sql
```

3. **Configure settings:**
   Edit `config/config.env`:

```bash
DB_HOST="localhost"
DB_PORT="3306"
DB_USER="coffee_admin"
DB_PASS="your_secure_password"
DB_NAME="coffeeshop"

EMAIL_ALERTS="true"
ALERT_EMAIL="your_email@gmail.com"
```

4. **Make scripts executable:**

```bash
chmod +x scripts/coffee_etl.sh
```

---

##  Usage

### Run manually:

```bash
./scripts/coffee_etl.sh
```

### Schedule daily (Cron):

```bash
0 2 * * * cd /path/to/coffee_etl_project && ./scripts/coffee_etl.sh >> logs/cron.log 2>&1
```

### View reports & logs:

```bash
# Latest report
tail -n 50 reports/daily_report_*.txt

# Check logs
tail -f logs/etl_*.log
```

---

##  Sample Output

```
========================================
BREWTOPIA DAILY SALES REPORT
Generated: 2025-11-09 07:38:27
========================================

REVENUE BY CATEGORY:
--------------------
Food           : $  442.71 (60 items)
Beverages      : $  397.65 (65 items)

TOP 10 PRODUCTS BY QUANTITY:
----------------------------
 1. Oatmeal Cookie                : 10 units
 2. Chocolate Chip Cookie         : 9 units
 3. Green Tea                     : 8 units
 4. Vanilla Scone                 : 7 units
 5. Iced Latte                    : 7 units
 6. Cold Brew                     : 6 units
 7. Espresso                      : 5 units
 8. Croissant                     : 5 units
 9. Blueberry Muffin              : 5 units
10. Turkey Sandwich               : 4 units

SALES BY STORE LOCATION:
------------------------
Mall           : $  191.12 (25 sales)
Downtown       : $  178.80 (25 sales)
Airport        : $  177.50 (25 sales)

LOW INVENTORY ALERTS:
---------------------

SUMMARY STATISTICS:
-------------------
Total Revenue:       $840.36
Total Transactions:  125
Average Transaction: $6.72

Report saved to: /root/coffee_etl_project/reports/daily_report_20251109_073827.txt

```


