#!/bin/bash
# 모켓 상품 사진을 imgbb에서 이 저장소로 복사한다 (공유할 때 빨리 받으려고).
# 주소 짝: https://i.ibb.co/<id>/<이름> → https://moketorder.github.io/photos/<id>/<이름>
# imgbb는 한꺼번에 많이 받으면 막으니 2장씩, 한 번에 20분까지만 받고 나머지는 다음 차례(15분 뒤)에 받는다.
set -u
DB=https://moketdb-default-rtdb.asia-southeast1.firebasedatabase.app
curl -sf -m 90 "$DB/published_products.json" -o /tmp/pp.json || { echo "상품 목록을 못 받음"; exit 0; }
grep -oE 'https://i\.ibb\.co/[A-Za-z0-9]+/[A-Za-z0-9._-]+\.(jpg|jpeg|png|webp|gif)' /tmp/pp.json | sort -u > /tmp/urls.txt
: > /tmp/todo.txt
while read -r u; do p=${u#https://i.ibb.co/}; [ -s "$p" ] || echo "$u" >> /tmp/todo.txt; done < /tmp/urls.txt
# [2026-11-06] 새로 등록한 상품 사진 먼저 — 지난 차례 목록(.github/seen.txt)에 없던 주소를 앞에 세운다
touch .github/seen.txt
grep -vxF -f .github/seen.txt /tmp/todo.txt > /tmp/todo_new.txt || true
grep -xF -f .github/seen.txt /tmp/todo.txt > /tmp/todo_old.txt || true
cat /tmp/todo_new.txt /tmp/todo_old.txt > /tmp/todo.txt
cp /tmp/urls.txt .github/seen.txt
echo "전체 $(wc -l < /tmp/urls.txt)장 · 새로 받을 사진 $(wc -l < /tmp/todo.txt)장 (새로 등록 $(wc -l < /tmp/todo_new.txt)장 먼저)"
export END=$(( $(date +%s) + 1200 ))
dl() {
  [ "$(date +%s)" -lt "$END" ] || return 0
  u=$1; p=${u#https://i.ibb.co/}; mkdir -p "$(dirname "$p")"
  for a in 1 2; do
    c=$(curl -s -m 15 -w '%{http_code}' "$u" -o "$p.tmp")
    if [ "$c" = 200 ] && [ -s "$p.tmp" ]; then mv "$p.tmp" "$p"; return 0; fi
    sleep 5
  done
  rm -f "$p.tmp"; echo "실패($c) $u"
}
export -f dl
xargs -P 2 -I{} bash -c 'dl "$@"' _ {} < /tmp/todo.txt
find . -type d -empty -not -path './.git*' -delete 2>/dev/null
exit 0
