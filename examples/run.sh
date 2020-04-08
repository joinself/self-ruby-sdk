#!/bin/sh

echo "This script will execute all examples be sure to have in place necessary environment variables SELF_APP_ID and SELF_APP_SECRET"
echo ""
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ -z "${SELF_APP_ID}" ]]; then
  read -p "SELF_APP_ID: "  self_app_id
else
  self_app_id=$SELF_APP_ID
fi

if [[ -z "${SELF_APP_SECRET}" ]]; then
  read -p "SELF_APP_SECRET: "  self_app_secret
else
  self_app_secret=$SELF_APP_SECRET
fi
read -p "Provide the user selfid you want to test against: "  selfid
echo ""

echo "---------------------------------------"
echo "Testing authentication for $selfid"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/authentication/app.rb $selfid
echo ""

echo "---------------------------------------"
echo "Testing blocking authentication for $selfid"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/authentication/blocking.rb $selfid
echo ""

echo "---------------------------------------"
echo "Testing asynchronous authentication for $selfid"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/authentication/subscription.rb $selfid
echo ""

echo "---------------------------------------"
echo "Testing QR auth request for $selfid"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/qr_authentication/app.rb $selfid
echo ""

echo "---------------------------------------"
echo "Testing fact request for $selfid"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/fact_request/app.rb $selfid
echo ""

echo "---------------------------------------"
echo "Testing blocking fact request for $selfid"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/fact_request/blocking.rb $selfid
echo ""

echo "---------------------------------------"
echo "Testing QR fact request for $selfid"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/qr_fact_request/app.rb $selfid
echo ""

echo "---------------------------------------"
echo "Testing intermediary fact request for $selfid"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/intermediary_request/app.rb $selfid
echo ""

echo "---------------------------------------"
echo "Testing app connections management"
echo "---------------------------------------"
SELF_APP_ID=$self_app_id SELF_APP_SECRET=$self_app_secret NO_LOGS=true ruby $DIR/connections/app.rb $selfid
echo ""



