#!/bin/bash
# 모켓 상품 사진을 imgbb에서 이 저장소로 복사한다 (공유할 때 빨리 받으려고).
# 주소 짝: https://i.ibb.co/<id>/<이름> → https://moketorder.github.io/photos/<id>/<이름>
set -u
DB=https://moketdb-default-rtdb.asia-southeast1.firebasedatabase.app
curl -sf -m 90 "$DB/published_products.json" -o /tmp/pp.json || { echo "상품 목록을 못 받음"; exit 0; }
grep -oE 'https://i\.ibb\.co/[A-Za-z0-9]+/[A-Za-z0-9._-]+\.(jpg|jpeg|png|webp|gif)' /tmp/pp.json | sort -u > /tmp/urls.txt
: > /tmp/todo.txt
while read -r u; do p=${u#https://i.ibb.co/}; [ -s "$p" ] || echo "$u" >> /tmp/todo.txt; done < /tmp/urls.txt
echo "전체 $(wc -l < /tmp/urls.txt)장 · 새로 받을 사진 $(wc -l < /tmp/todo.txt)장"
dl() {
  u=$1; p=${u#https://i.ibb.co/}; mkdir -p "$(dirname "$p")"
  for a in 1 2 3; do
    if curl -sf -m 20 "$u" -o "$p.tmp" && [ -s "$p.tmp" ]; then mv "$p.tmp" "$p"; return 0; fi
    sleep 3
  done
  rm -f "$p.tmp"; echo "실패 $u"
}
export -f dl
head -n 1500 /tmp/todo.txt | xargs -P 4 -I{} bash -c 'dl "$@"' _ {}
exit 0
