


library(ggplot2)
library(h2o)
library(dplyr)
# Start the H2O cluster (locally)
h2o.init()

# Import a sample binary outcome train/test set into H2O

train <- h2o.importFile("https://s3.amazonaws.com/erin-data/higgs/higgs_train_10k.csv")
test <- h2o.importFile("https://s3.amazonaws.com/erin-data/higgs/higgs_test_5k.csv")

# Identify predictors and response
y <- "response"
x <- setdiff(names(train), y)

# For binary classification, response should be a factor
train[, y] <- as.factor(train[, y])
test[, y] <- as.factor(test[, y])




# 创建一个空的 dataframe 来存储结果
results <<- data.frame(
  model_id = character(),
  accuracy = numeric(),
  precision = numeric(),
  auc = numeric(),
  recall = numeric(),
  F1 = numeric(),
  stringsAsFactors = FALSE
)
ROC_PLOT_LIST<<-list()
Varimp.df_LIST<<-list()


get.re.ml=function(model.name="DRF",train,test,x,y){
  # model.name="DRF"
  print(model.name)
  aml <- h2o.automl(x = x, y = y,
                    training_frame = train,
                    max_models = 1,
                    # include_algos=c( "XGBoost"),
                    include_algos=c( model.name),
                    # include_algos=c( "DRF","XGBoost"),
                    distribution = "bernoulli",
                    seed = 1)
  
  # View the AutoML Leaderboard
  lb <- aml@leaderboard
  print(lb, n = nrow(lb))  # Print all rows instead of default (6 rows)
  lb_df=lb %>% as.data.frame()
  model_id=lb_df$model_id[1]
  lb_df$model_name=gsub("_.*","",model_id) 
  lb_df=lb_df%>% dplyr::distinct(model_name, .keep_all = TRUE)
  
  
  model <- h2o.getModel(lb_df$model_id[1])
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
  ROC_PLOT_LIST[[model.name]]<<-ROC_plot
  dir.create("output", showWarnings = FALSE)
  try({
    # ROC plot
    pdf(glue::glue("output/ROC_{out.name}.pdf"),width = 6, height = 6)
    plot(performance,main =out.name)
    legend("bottomright", legend = glue::glue("AUC={Auc.round}"), bty = "l")
    dev.off()
    
    # Varimp plot
    exa <- h2o.explain(model, test)
    Varimp=exa$varimp
  
    Varimp.df=h2o.varimp(model) %>% as.data.frame()
    Varimp.df$model=model.name
    Varimp.df_LIST[[model.name]]<<-Varimp.df
    
    Varimp_plot=Varimp$plots[[1]] +labs(title = out.name)
    
    width=Varimp_plot[["data"]][["variable"]] %>% unique() %>% nchar() %>% max()
    Width=0.15*width +3
    ggsave(glue::glue("output/varimp_{out.name}.pdf"),Varimp_plot,width = Width, height = 4)
  },silent = T)
  
  # 将结果添加到 dataframe 中
  results <<- rbind(results, data.frame(
    Model_id = model_id,
    Accuracy = Accuracy,
    Precision = Precision,
    Auc = Auc,
    Recall = Recall,
    F1 = F1,
    Model.name = out.name,
    stringsAsFactors = FALSE
  ))
  print(results)
  # plot(performance)
  cat(sprintf("模型在测试集 %s 的准确率为: %f\n", model_id, Accuracy))


}



get.re.ml(model.name="DRF",train,test,x,y)
get.re.ml(model.name="XGBoost",train,test,x,y)
get.re.ml(model.name="GBM",train,test,x,y)
get.re.ml(model.name="GLM",train,test,x,y)
get.re.ml(model.name="DeepLearning",train,test,x,y)


#ROC plot
roc_data <- dplyr::bind_rows(ROC_PLOT_LIST)
ROC_plot_models=ggplot(roc_data, aes(x = FPR, y = TPR, color = Model)) +
  geom_line(size = 1) +
  geom_abline(linetype = "dashed") +
  labs(title = "ROC Curves for Multiple Models", x = "False Positive Rate", y = "True Positive Rate") +
  theme_minimal() +
  theme(legend.title = element_blank())
ggsave(glue::glue("output/ROC_plot_models.pdf"),ROC_plot_models,width = 8, height = 6)

results$Model_id=NULL
openxlsx::write.xlsx(results,glue::glue("output/ML_results.xlsx"), sheetName = "Sheet1", row.names = F)


#Model barplot
results_long <- reshape2::melt(results, id.vars = "Model.name")
colors <- c("#d7191c", "#fdae61", "#ffffbf", "#a6d96a", "#1a9641")
model_barplot=ggplot(results_long, aes(x = Model.name, y = value, fill = variable)) +
  geom_bar(stat = "identity", position = "dodge") +
  labs(x = "Score", y = "Model", fill = "") +
  theme_minimal()+
  scale_fill_manual(values = colors) +
  theme(legend.position = "top")
ggsave(glue::glue("output/models_barplot.pdf"),model_barplot,width = 6, height = 6)

#Var.imp.heatmap
varimp_combined <- dplyr::bind_rows(Varimp.df_LIST)
varimp_combined$Importance=varimp_combined$scaled_importance 
varimp_combined.plot=ggplot(varimp_combined, aes(y = variable, x = model, fill = Importance)) +
  geom_tile() +
  scale_fill_gradient(low = "white", high = "#a6d96a") +
  theme_minimal() +
  labs(title = "Feature Importance Heatmap",
       x = "",
       y = ""
       )+
  theme(axis.text.x = element_text(angle = 45, vjust = 1, hjust = 1))

ggsave(glue::glue("output/varimp_combined.plot.pdf"),varimp_combined.plot,width = 4, height = 6)
