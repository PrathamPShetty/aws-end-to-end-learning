#!/bin/bash
# Usage: ./scripts/place_order.sh <product> <quantity> <price>
# Example: ./scripts/place_order.sh laptop 2 999.99

PRODUCT=${1:-laptop}
QUANTITY=${2:-1}
PRICE=${3:-999.99}
CUSTOMER="CUST-$(( RANDOM % 900 + 100 ))"

echo ""
echo "▶ Placing order..."
echo "  Customer : $CUSTOMER"
echo "  Product  : $PRODUCT"
echo "  Quantity : $QUANTITY"
echo "  Price    : \$$PRICE each"
echo ""

PAYLOAD=$(cat <<EOF
{
  "customerId": "$CUSTOMER",
  "product": "$PRODUCT",
  "quantity": $QUANTITY,
  "price": $PRICE
}
EOF
)

echo "$PAYLOAD" > /tmp/order_payload.json
RESULT=$(awslocal lambda invoke \
  --function-name place-order \
  --payload file:///tmp/order_payload.json \
  /tmp/order_result.json 2>&1)

cat /tmp/order_result.json | python3 -m json.tool
echo ""
echo "✅ Order placed! Check invoices and inventory with: ./scripts/check_status.sh"
echo ""
