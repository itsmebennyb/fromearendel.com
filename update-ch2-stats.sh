#!/bin/bash
# Update Ch2 stats from Gumroad API and push to GitHub Pages
# Ch2 epoch: Feb 28, 2026 12:00 CST = Feb 28 18:00 UTC

TOKEN=$(security find-generic-password -s "gumroad-access-token" -w)
SITE_DIR="$(dirname "$0")"

page=1
total_downloads=0
paid_sales=0
revenue_cents=0

while true; do
  resp=$(curl -s "https://api.gumroad.com/v2/sales?after=2026-02-28T18:00:00Z&page=$page" \
    -H "Authorization: Bearer $TOKEN")
  
  count=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(len(d.get('sales',[])))")
  if [ "$count" = "0" ]; then break; fi
  
  stats=$(echo "$resp" | python3 -c "
import json,sys
d=json.load(sys.stdin)
dl=len(d['sales'])
paid=sum(1 for s in d['sales'] if s.get('paid'))
rev=sum(s.get('price',0) - s.get('gumroad_fee',0) for s in d['sales'] if s.get('paid'))
print(f'{dl} {paid} {rev}')
")
  read dl p r <<< "$stats"
  total_downloads=$((total_downloads + dl))
  paid_sales=$((paid_sales + p))
  revenue_cents=$((revenue_cents + r))
  
  next=$(echo "$resp" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d.get('next_page_url',''))")
  if [ -z "$next" ] || [ "$next" = "None" ]; then break; fi
  page=$((page + 1))
done

# Convert cents to dollars (Gumroad prices are in cents)
revenue_dollars=$(python3 -c "print(round($revenue_cents / 100, 2))")

# Write JSON
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)
cat > "$SITE_DIR/ch2-stats.json" << EOF
{"earned":${revenue_dollars},"downloads":${total_downloads},"paid":${paid_sales},"updated":"${NOW}"}
EOF

# Push if changed
cd "$SITE_DIR"
if ! git diff --quiet ch2-stats.json 2>/dev/null; then
  git add ch2-stats.json
  git commit -m "Update Ch2 stats: \$${revenue_dollars} earned, ${total_downloads} downloads, ${paid_sales} paid"
  git push
  echo "Pushed: \$${revenue_dollars} earned, ${total_downloads} downloads, ${paid_sales} paid"
else
  echo "No changes"
fi
