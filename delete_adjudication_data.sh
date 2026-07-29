#!/bin/bash

echo "======================================"
echo " PostgreSQL Bulk Data Deletion Script "
echo "======================================"

echo ""
echo "Enter PostgreSQL Database Details:"
echo ""

read -p "DB Host: " DB_HOST
read -p "DB Port: " DB_PORT
read -p "Database Name: " DB_NAME
read -p "DB Username: " DB_USER
read -s -p "DB Password: " DB_PASSWORD
echo ""
echo ""

echo "⚠ WARNING: This will DELETE ALL DATA from below tables:"
echo " - adjudication_transactions"
echo ""

read -p "Are you sure you want to delete ALL data? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Operation cancelled."
    exit 1
fi

export PGPASSWORD="$DB_PASSWORD"

echo ""
echo "Connecting to database..."

psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" <<EOF
TRUNCATE TABLE adjudication_transactions CASCADE;
EOF

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Data deleted successfully."
else
    echo ""
    echo "❌ Error occurred while deleting data."
fi

unset PGPASSWORD

#TRUNCATE TABLE public.adjudication_transactions CASCADE;