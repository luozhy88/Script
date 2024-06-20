

########################### Recursive Feature Elimination ######################
rm(list=ls())
set.seed(7)
# load the library
library(mlbench)
library(caret)
library(randomForest)
dir.create("output", showWarnings = FALSE)
# load the Data.raw
data(PimaIndiansDiabetes)
Data.raw=PimaIndiansDiabetes

# Identify predictors and response
y <- "diabetes"
x <- setdiff(names(Data.raw), y)

# define the control using a random forest selection function
control <- rfeControl(functions=rfFuncs, method="cv", number=10)
# run the RFE algorithm
Results <- rfe(  Data.raw[,x]  , Data.raw[,y], sizes=c(1:10), rfeControl=control)
bestnum=Results$bestSubset
# summarize the Results
print(Results)
# list the chosen features
selected_feature=predictors(Results)
# plot the Results
Results=Results$results

#根据Results$selected决定画图点的形状是用实心还是空心
Results$selected=ifelse(Results$Variables==bestnum,"*","o")
line_plot=ggplot(Results, aes(x = Variables, y = Accuracy)) +
  geom_line() +  # 绘制折线
  geom_point(aes(shape = selected), size = 3) +  # 根
  scale_shape_manual(values = c("*" = 16, "o" = 1)) +  # 设置
  labs(title = "", x = "Variables", y = "Accuracy") +  # 添加标题和轴标签
  theme_minimal() + # 使用简洁主题
  theme(legend.position = "none")   # 移除图例
line_plot
ggsave(glue::glue("output/Recursive.Feature.Elimination.line_plot.pdf"),line_plot,width = 7, height = 6)
# Results画个折线图点图，Variables为横坐标，Accuracy为纵坐标，其中横坐标中bestnum所在的点为实心


pp=plot(Results, type=c("g", "o"))
# 去掉右边和上面的刻度线
pp
axis(3, labels = FALSE, tick = FALSE)  # 上面的刻度线
axis(4, labels = FALSE, tick = FALSE)  # 右边的刻度线



Data=Data.raw[,c(selected_feature,y)]
########################### Recursive Feature Elimination ######################

##############################train models######################################
library(h2o)
# Start the H2O cluster (locally)
h2o.init()
Data <- as.h2o(Data)
# Import a sample binary outcome train/test set into H2O
splits <- h2o.splitFrame(Data, ratios = 0.8, seed = 1)
train <- splits[[1]]
test <- splits[[2]]

# For binary classification, response should be a factor
train[, y] <- as.factor(train[, y])
test[, y] <- as.factor(test[, y])

# Run AutoML for 6 base models
aml <- h2o.automl(x = x, y = y,
                  training_frame = train,
                  max_models = 6,
                  include_algos=c("GLM", "DRF", "XGBoost", "GBM"),#, 
                  distribution = "bernoulli",
                  seed = 1)

# View the AutoML Leaderboard
lb <- aml@leaderboard
print(lb, n = nrow(lb))  # Print all rows instead of default (6 rows)
lb <- lb[h2o.strsplit(lb$model_id, "_")[[2]] != "2", ]



lb_df=lb %>% as.data.frame()
lb_df$model_name=gsub("_.*","",lb_df$model_id) 
lb_df=lb_df%>% dplyr::distinct(model_name, .keep_all = TRUE)




# 创建一个空的 dataframe 来存储结果
results <- data.frame(
  model_id = character(),
  accuracy = numeric(),
  precision = numeric(),
  auc = numeric(),
  recall = numeric(),
  F1 = numeric(),
  stringsAsFactors = FALSE
)

ROC_PLOT_LIST=list()
model_ids <- as.vector(lb_df$model_id)
for (model_id in model_ids) {
  print(model_id)
  # model_id="XGBoost_1_AutoML_7_20240620_14354"
  model <- h2o.getModel(model_id)
  performance <- h2o.performance(model, newdata  = test)
  
  Accuracy <- h2o.accuracy(performance)[[2]] %>% mean()
  Precision=h2o.precision(performance)[[2]] %>% mean()
  Auc=h2o.auc(performance)
  Recall=h2o.recall(performance)[[2]] %>% mean()
  F1=h2o.F1(performance)[[2]] %>% mean()
  
  TPR=h2o.tpr(performance)[[2]]
  FPR=h2o.fpr(performance)[[2]]
  Auc.round=round(Auc,3)
  out.name=gsub("_.*","",model_id)
  
  # 生产ROC混合模型图的参数
  ROC_plot=data.frame(TPR=TPR,FPR=FPR )
  ROC_plot$Model=glue::glue(out.name,"(AUC={Auc.round})" )
  ROC_PLOT_LIST[[out.name]]=ROC_plot
  
  # ROC plot
  pdf(glue::glue("output/ROC_{out.name}.pdf"),width = 6, height = 6)
  plot(performance,main =out.name)
  
  legend("bottomright", legend = glue::glue("AUC={Auc.round}"), bty = "l")
  dev.off()
  
  # Varimp plot
  exa <- h2o.explain(model, test)
  Varimp=exa$varimp
  Varimp_plot=Varimp$plots[[1]] +labs(title = out.name)
  ggsave(glue::glue("output/varimp_{out.name}.pdf"),Varimp_plot,width = 5.5, height = 4)
  
  # 将结果添加到 dataframe 中
  results <- rbind(results, data.frame(
    Model_id = model_id,
    Accuracy = Accuracy,
    Precision = Precision,
    Auc = Auc,
    Recall = Recall,
    F1 = F1,
    Model.name = out.name,
    stringsAsFactors = FALSE
  ))
  # plot(performance)
  cat(sprintf("模型 %s 的准确率为: %f\n", model_id, Accuracy))
}
# 过滤多余的模型
filtered_data <- lb[h2o.strsplit(lb$model_id, "_")[[2]] != "2", ]
# filtered_data$model_id <- h2o.gsub("_.*", "", filtered_data$model_id)

#Heatmap
pdf(glue::glue("output/varimp_heatmap.pdf"),width = 5, height = 5)
varimp_heatmap=h2o.varimp_heatmap(filtered_data)
varimp_heatmap+ theme(axis.text.x = element_text(angle = 0, hjust = 0.5))
dev.off()

#ROC plot
roc_data <- dplyr::bind_rows(ROC_PLOT_LIST)
ROC_plot_models=ggplot(roc_data, aes(x = FPR, y = TPR, color = Model)) +
                    geom_line(size = 1) +
                    geom_abline(linetype = "dashed") +
                    labs(title = "ROC Curves for Multiple Models", x = "False Positive Rate", y = "True Positive Rate") +
                    theme_minimal() +
                    theme(legend.title = element_blank())
ggsave(glue::glue("output/ROC_plot_models.pdf"),ROC_plot_models,width = 8, height = 6)

#Model table
results$Model_id=NULL
openxlsx::write.xlsx(results,glue::glue("output/ML_results.xlsx"), sheetName = "Sheet1", row.names = F)

#Model barplot
results_long <- melt(results, id.vars = "Model.name")

# 绘制条形图
colors <- c("#d7191c", "#fdae61", "#ffffbf", "#a6d96a", "#1a9641")
model_barplot=ggplot(results_long, aes(x = Model.name, y = value, fill = variable)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(x = "Score", y = "Model", fill = "") +
  theme_minimal()+
  scale_fill_manual(values = colors) +
  theme(legend.position = "top")
ggsave(glue::glue("output/models_barplot.pdf"),model_barplot,width = 6, height = 6)

