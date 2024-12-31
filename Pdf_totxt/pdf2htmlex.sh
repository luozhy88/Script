docker run -ti --rm -v /home/zhiyu/test:/pdf sergiomtzlosa/pdf2htmlex:latest pdf2htmlEX --zoom 1.3 /pdf/Comparison.pdf
alias pdf2htmlEX='docker run -ti --rm -v `pwd`:/pdf sergiomtzlosa/pdf2htmlex pdf2htmlEX'
pdf2htmlEX --zoom 1.3 test.pdf
