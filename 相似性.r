


library(RecordLinkage)
# 计算字符串相似性
levenshteinSim("Nucleoside triphosphate", "2,5-Diaminopyrimidine nucleoside triphosphate")


library(stringdist)
stringsim("hello", "hallo", method = "lv")
# 返回值：0.8（Levenshtein相似性）
stringdist::stringsim("Nucleoside triphosphate", "2,5-Diaminopyrimidine nucleoside triphosphate", method = "cosine")

stringdist::stringsim(a=c("Nucleoside triphosphate"), b=c("2,5-Diaminopyrimidine nucleoside triphosphate","(hydroxy)phosphoryl)oxy](hydroxy)phosphoryl}oxy)phosphonic acid","N-(2,5-diamino-6-oxo-1,6-dihydropyrimidin-4-yl)-5-O-(hydroxy{[hydroxy(phosphonooxy)phosphoryl]oxy}phosphoryl)-beta-D-ribofuranosylamine"), method = "cosine")


b=c("2,5-Diaminopyrimidine nucleoside triphosphate","(hydroxy)phosphoryl)oxy](hydroxy)phosphoryl}oxy)phosphonic acid","N-(2,5-diamino-6-oxo-1,6-dihydropyrimidin-4-yl)-5-O-(hydroxy{[hydroxy(phosphonooxy)phosphoryl]oxy}phosphoryl)-beta-D-ribofuranosylamine")
stringdist::stringsim(a=c("Nucleoside triphosphate"), b=paste(b,collapse = ";"), method = "cosine")

stringdist::stringsim(a=c("Nucleoside triphosphate"), b=b, method = "cosine")


