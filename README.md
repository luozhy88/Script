# Script
## 将pdf to png
find . -type f -name '*.pdf' -exec sh -c 'd="${0%/*}"; mkdir -p "$d/pngs"; pdftoppm "${0}" "$d/pngs/${0##*/}" -png' {} \;  
find . -type f -name '*.pdf' -exec sh -c 'd="${1%.*}"; mkdir -p "pngs"; pdftoppm "${1}" "pngs/${1##*/}" -png' sh {} \;  

find . -type f -name '*.pdf' -exec sh -c 'd="${1%.pdf}"; mkdir -p "pngs"; pdftoppm "${1}" "pngs/${1##*/}" -png' sh {} \;  
