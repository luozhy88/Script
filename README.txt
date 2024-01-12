# Script
## 将pdf to png
find . -type f -name '*.pdf' -exec sh -c 'd="${0%/*}"; mkdir -p "$d/pngs"; pdftoppm "${0}" "$d/pngs/${0##*/}" -png' {} \;  
find . -type f -name '*.pdf' -exec sh -c 'd="${1%.*}"; mkdir -p "pngs"; pdftoppm "${1}" "pngs/${1##*/}" -png' sh {} \;  

find . -type f -name '*.pdf' -exec sh -c 'd="${1%.pdf}"; mkdir -p "pngs"; pdftoppm "${1}" "pngs/${1##*/}" -png' sh {} \;  
find . -type f -name '*.pdf' -exec sh -c 'd="${1%.pdf}"; mkdir -p "pngs"; pdftoppm "${1}" "pngs/${1##*/}" -png' sh {} \;



# 用find函数找到所有以sh结尾的bash文件，然后进入每个bash文件的目录，然后批量进行跑"bash -x file.sh"
find . -type f -name "*.sh" -execdir bash -x '{}' \;
