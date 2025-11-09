#!/bin/bash

#############################################

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="$PROJECT_ROOT/config/config.env"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found at $CONFIG_FILE"
    exit 1
fi

source "$CONFIG_FILE"

# Setup directories
LOG_DIR="$PROJECT_ROOT/logs"
REPORT_DIR="$PROJECT_ROOT/reports"
DATA_DIR="$PROJECT_ROOT/data"
TEMP_DIR="$PROJECT_ROOT/temp"

mkdir -p "$LOG_DIR" "$REPORT_DIR" "$TEMP_DIR"

# Log file setup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$LOG_DIR/etl_${TIMESTAMP}.log"

# Logging function
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Error handling function
error_exit() {
    log "ERROR: $1"
    exit 1
}

log "=========================================="
log "Starting BrewTopia ETL Pipeline"
log "=========================================="

#############################################
#  DATA EXTRACTION
#############################################

log "Phase 1: Data Extraction"

# Extract Online Orders (JSON)
extract_online_orders() {
    log "Extracting online orders from JSON..."
    
    JSON_FILE="$DATA_DIR/online_orders.json"
    ONLINE_EXTRACT="$TEMP_DIR/online_orders_extract.csv"
    
    if [ ! -f "$JSON_FILE" ]; then
        error_exit "JSON file not found: $JSON_FILE"
    fi
    
    # Convert JSON to CSV using jq
    jq -r '["order_id","customer_id","product","category","size","price","quantity","order_date","payment_method"], 
           (.[] | [.order_id, .customer_id, .product, .category, .size, .price, .quantity, .order_date, .payment_method]) 
           | @csv' "$JSON_FILE" > "$ONLINE_EXTRACT"
    
    if [ $? -eq 0 ]; then
        local count=$(wc -l < "$ONLINE_EXTRACT")
        log "Successfully extracted $((count-1)) online orders"
    else
        error_exit "Failed to extract online orders"
    fi
}

# Extract In-Store Sales (CSV)
extract_instore_sales() {
    log "Extracting in-store sales from CSV..."
    
    CSV_FILE="$DATA_DIR/instore_sales.csv"
    INSTORE_EXTRACT="$TEMP_DIR/instore_sales_extract.csv"
    
    if [ ! -f "$CSV_FILE" ]; then
        error_exit "CSV file not found: $CSV_FILE"
    fi
    
    cp "$CSV_FILE" "$INSTORE_EXTRACT"
    
    if [ $? -eq 0 ]; then
        local count=$(wc -l < "$INSTORE_EXTRACT")
        log "Successfully extracted $((count-1)) in-store sales"
    else
        error_exit "Failed to extract in-store sales"
    fi
}

# Extract Inventory Data (MySQL)
extract_inventory() {
    log "Extracting inventory data from MySQL database..."
    
    INVENTORY_EXTRACT="$TEMP_DIR/inventory_extract.csv"
    
    # Test database connection
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -e "SELECT 1;" > /dev/null 2>&1
    if [ $? -ne 0 ]; then
        error_exit "Cannot connect to database. Check credentials."
    fi
    
    # Extract inventory data
    mysql -h"$DB_HOST" -P"$DB_PORT" -u"$DB_USER" -p"$DB_PASS" -D"$DB_NAME" \
        --batch --skip-column-names -e \
        "SELECT product_id, product_name, category, supplier, cost_price, 
                retail_price, current_stock, min_stock_level, last_restocked 
         FROM store_inventory;" | \
        sed 's/\t/,/g' > "$INVENTORY_EXTRACT"
    
    if [ $? -eq 0 ]; then
        local count=$(wc -l < "$INVENTORY_EXTRACT")
        log "Successfully extracted $count inventory items"
    else
        error_exit "Failed to extract inventory data"
    fi
}

#############################################
# TASK 3: DATA TRANSFORMATION
#############################################

log "Phase 2: Data Transformation"

# Transform Online Orders
transform_online_orders() {
    log "Transforming online orders..."
    
    ONLINE_TRANSFORMED="$TEMP_DIR/online_transformed.csv"
    
    # Skip header, calculate total, add source, filter invalid records
    awk -F',' 'NR==1 {next} 
    {
        # Remove quotes from fields
        gsub(/"/, "", $0)
        
        order_id = $1
        product = $3
        category = $4
        size = $5
        price = $6
        quantity = $7
        date = $8
        payment = $9
        
        # Validate data
        if (price > 0 && quantity > 0) {
            total = price * quantity
            source = "online"
            print order_id","product","category","size","price","quantity","total","date","source","payment
        }
    }' "$TEMP_DIR/online_orders_extract.csv" > "$ONLINE_TRANSFORMED"
    
    local count=$(wc -l < "$ONLINE_TRANSFORMED")
    log "Transformed $count valid online orders"
}

# Transform In-Store Sales
transform_instore_sales() {
    log "Transforming in-store sales..."
    
    INSTORE_TRANSFORMED="$TEMP_DIR/instore_transformed.csv"
    
    # Skip header, standardize columns, calculate total
    awk -F',' 'NR==1 {next}
    {
        sale_id = $1
        product = $2
        category = $3
        size = $4
        price = $5
        quantity = $6
        date = $7
        location = $8
        
        # Validate data
        if (price > 0 && quantity > 0) {
            total = price * quantity
            source = "instore"
            print sale_id","product","category","size","price","quantity","total","date","source","location
        }
    }' "$TEMP_DIR/instore_sales_extract.csv" > "$INSTORE_TRANSFORMED"
    
    local count=$(wc -l < "$INSTORE_TRANSFORMED")
    log "Transformed $count valid in-store sales"
}

# Transform Inventory
transform_inventory() {
    log "Transforming inventory data..."
    
    INVENTORY_TRANSFORMED="$TEMP_DIR/inventory_transformed.csv"
    
    awk -F',' '{
        product_id = $1
        product = $2
        category = $3
        cost = $5
        retail = $6
        stock = $7
        min_stock = $8
        
        if (cost > 0 && retail > 0) {
            margin = retail - cost
            margin_pct = (margin / cost) * 100
            source = "inventory"
            print product_id","product","category","cost","retail","margin","margin_pct","stock","min_stock","source
        }
    }' "$INVENTORY_EXTRACT" > "$INVENTORY_TRANSFORMED"
    
    local count=$(wc -l < "$INVENTORY_TRANSFORMED")
    log "Transformed $count inventory items"
}

#############################################
# TASK 4: DATA LOADING & ANALYSIS
#############################################

log "Phase 3: Data Loading and Analysis"

# Merge all data sources
merge_data() {
    log "Merging transformed datasets..."
    
    UNIFIED_DATA="$TEMP_DIR/unified_sales_data.csv"
    
    # Create unified header
    echo "id,product,category,size,price,quantity,total,date,source,extra" > "$UNIFIED_DATA"
    
    # Append transformed data
    cat "$ONLINE_TRANSFORMED" >> "$UNIFIED_DATA"
    cat "$INSTORE_TRANSFORMED" >> "$UNIFIED_DATA"
    
    local total_records=$(wc -l < "$UNIFIED_DATA")
    log "Merged data contains $((total_records-1)) total records"
}

# Generate business insights
generate_insights() {
    log "Generating business insights..."
    
    REPORT_FILE="$REPORT_DIR/daily_report_${TIMESTAMP}.txt"
    
    cat > "$REPORT_FILE" << EOF
========================================
BREWTOPIA DAILY SALES REPORT
Generated: $(date +'%Y-%m-%d %H:%M:%S')
========================================

EOF

    # Total Revenue by Category
    echo "REVENUE BY CATEGORY:" >> "$REPORT_FILE"
    echo "--------------------" >> "$REPORT_FILE"
    awk -F',' 'NR>1 {category[$3]+=$7; count[$3]++} 
    END {
        for (cat in category) 
            printf "%-15s: $%8.2f (%d items)\n", cat, category[cat], count[cat]
    }' "$UNIFIED_DATA" | sort -t'$' -k2 -rn >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    
    # Most Popular Products (Top 10)
    echo "TOP 10 PRODUCTS BY QUANTITY:" >> "$REPORT_FILE"
    echo "----------------------------" >> "$REPORT_FILE"
    awk -F',' 'NR>1 {products[$2]+=$6} 
    END {
        for (prod in products) 
            print products[prod], prod
    }' "$UNIFIED_DATA" | sort -rn | head -10 | \
    awk '{printf "%2d. %-30s: %d units\n", NR, substr($0, index($0,$2)), $1}' >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    
    # Sales by Location
    echo "SALES BY STORE LOCATION:" >> "$REPORT_FILE"
    echo "------------------------" >> "$REPORT_FILE"
    awk -F',' 'NR>1 && $9=="instore" {location[$10]+=$7; count[$10]++}
    END {
        for (loc in location)
            printf "%-15s: $%8.2f (%d sales)\n", loc, location[loc], count[loc]
    }' "$UNIFIED_DATA" | sort -t'$' -k2 -rn >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    
    # Low Inventory Alert
    echo "LOW INVENTORY ALERTS:" >> "$REPORT_FILE"
    echo "---------------------" >> "$REPORT_FILE"
    awk -F',' '$8 < $9 {
        printf "⚠ %-30s: Current: %3d | Min: %3d | Need: %d\n", 
               $2, $8, $9, ($9 - $8)
    }' "$INVENTORY_TRANSFORMED" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    
    # Summary Statistics
    echo "SUMMARY STATISTICS:" >> "$REPORT_FILE"
    echo "-------------------" >> "$REPORT_FILE"
    
    local total_revenue=$(awk -F',' 'NR>1 {sum+=$7} END {printf "%.2f", sum}' "$UNIFIED_DATA")
    local total_transactions=$(awk 'END {print NR-1}' "$UNIFIED_DATA")
    local avg_transaction=$(awk -F',' 'NR>1 {sum+=$7; count++} END {printf "%.2f", sum/count}' "$UNIFIED_DATA")
    
    echo "Total Revenue:       \$$total_revenue" >> "$REPORT_FILE"
    echo "Total Transactions:  $total_transactions" >> "$REPORT_FILE"
    echo "Average Transaction: \$$avg_transaction" >> "$REPORT_FILE"
    
    echo "" >> "$REPORT_FILE"
    echo "Report saved to: $REPORT_FILE" >> "$REPORT_FILE"
    
    log "Business insights report generated: $REPORT_FILE"
    
    # Display report to console
    cat "$REPORT_FILE"
}

# Send low inventory alerts
send_inventory_alerts() {
    log "Checking for low inventory alerts..."

    LOW_INVENTORY=$(awk -F',' '$8 < $9 {count++} END {print count+0}' "$INVENTORY_TRANSFORMED")

    ALERT_FILE="$TEMP_DIR/inventory_alert.txt"
    echo "Inventory Alert Report - $(date)" > "$ALERT_FILE"
    echo "================================" >> "$ALERT_FILE"
    echo "" >> "$ALERT_FILE"

    if [ "$LOW_INVENTORY" -gt 0 ]; then
        log "WARNING: $LOW_INVENTORY items below minimum stock level"

        awk -F',' '$8 < $9 {
            printf "%-30s: Stock=%d, Min=%d, Shortage=%d\n",
                   $2, $8, $9, ($9-$8)
        }' "$INVENTORY_TRANSFORMED" >> "$ALERT_FILE"

        echo "" >> "$ALERT_FILE"
        echo "Total low inventory items: $LOW_INVENTORY" >> "$ALERT_FILE"
    else
        log "All inventory levels are adequate"
        echo "All inventory levels are adequate." >> "$ALERT_FILE"
    fi

    # Send email (requires mail/sendmail configured)
    if [ "$EMAIL_ALERTS" = "true" ] && [ -n "$ALERT_EMAIL" ]; then
        if command -v mail &> /dev/null; then
            mail -s "BrewTopia Inventory Alert" "$ALERT_EMAIL" < "$ALERT_FILE"
            log "Email alert sent to $ALERT_EMAIL"
        else
            log "Email command not available. Alert saved to $ALERT_FILE"
        fi
    fi
}

#############################################
# TASK 5: CLEANUP & MAINTENANCE
#############################################

cleanup() {
    log "Cleaning up temporary files..."
    
    if [ "$KEEP_TEMP_FILES" = "false" ]; then
        rm -rf "$TEMP_DIR"/*
        log "Temporary files removed"
    else
        log "Temporary files preserved for debugging"
    fi
    
    # Log rotation (keep last 30 days)
    find "$LOG_DIR" -name "etl_*.log" -mtime +30 -delete
    log "Old log files cleaned up"
}

#############################################
# MAIN EXECUTION
#############################################

main() {
    # Extraction
    extract_online_orders
    extract_instore_sales
    extract_inventory
    
    # Transformation
    transform_online_orders
    transform_instore_sales
    transform_inventory
    
    # Loading & Analysis
    merge_data
    generate_insights
    send_inventory_alerts
    
    # Cleanup
    cleanup
    
    log "=========================================="
    log "ETL Pipeline completed successfully"
    log "=========================================="
}

# Execute main function
main
