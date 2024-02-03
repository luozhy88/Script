#install.packages("h2o", type="source", repos=(c("http://h2o-release.s3.amazonaws.com/h2o/latest_stable_R")))
# library(h2o)
# localH2O = h2o.init()
# demo(h2o.kmeans)

library(h2o)

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

# Run AutoML for 20 base models
aml <- h2o.automl(x = x, y = y,
                  training_frame = train,
                  max_models = 20,
                  distribution = "bernoulli",
                  seed = 1)


# View the AutoML Leaderboard
lb <- aml@leaderboard
print(lb, n = nrow(lb))  # Print all rows instead of default (6 rows)

# h2o.varimp_heatmap(lb)


# Explain leader model & compare with all AutoML models
exa <- h2o.explain(aml, test)
exa$varimp
exa$varimp_heatmap
exa$model_correlation_heatmap

# Explain a single H2O model (e.g. leader model from AutoML)
exm <- h2o.explain(aml@leader, test)
exm

# ROC
model <- aml@leader
dl_perf <- h2o.performance(model,train = T)
dl_perf <- h2o.performance(model,newdata = test)
dl_perf

plot(dl_perf)
h2o.auc(dl_perf)
h2o.auc(dl_perf, train = TRUE, valid = TRUE, xval = FALSE)

pred <- h2o.predict(object = aml, newdata = test)
pred
# View a summary of the prediction with a probability of TRUE
summary(pred$p1, exact_quantiles = TRUE)


###############################example2#######################################
#https://docs.h2o.ai/h2o/latest-stable/h2o-docs/explain.html
library(h2o)

h2o.init()

# Import wine quality dataset
f <- "https://h2o-public-test-data.s3.amazonaws.com/smalldata/wine/winequality-redwhite-no-BOM.csv"
df <- h2o.importFile(f)

# Response column
y <- "quality"

# Split into train & test
splits <- h2o.splitFrame(df, ratios = 0.8, seed = 1)
train <- splits[[1]]
test <- splits[[2]]

# Run AutoML for 1 minute
aml <- h2o.automl(y = y, training_frame = train, max_runtime_secs = 60, seed = 1)

# Explain leader model & compare with all AutoML models
exa <- h2o.explain(aml, test)
exa

# Explain a single H2O model (e.g. leader model from AutoML)
exm <- h2o.explain(aml@leader, test)
exm

###############################example3#######################################
df_ZSH <- df_ZSH[,-c(1:2)] %>% as.h2o()
df_JG6 <- df_JG6[,-2] %>% as.h2o()

library(h2o)
h2o.init()


# Response column


# Split into train & test
splits <- h2o.splitFrame(df_JG6 ,ratios = 0.8, seed = 100)
train <- splits[[1]]
test <- splits[[2]]


# Identify predictors and response
y <- "Effect"
x <- setdiff(names(train), y)

# For binary classification, response should be a factor
train[, y] <- as.factor(train[, y])
test[, y] <- as.factor(test[, y])

# Run AutoML for 20 base models
aml <- h2o.automl(x = x, y = y,
                  training_frame = train,
                  max_models = 20,
                  exclude_algos = c("XGBoost"),
                  distribution = "bernoulli",
                  seed = 1)

# View the AutoML Leaderboard
lb <- aml@leaderboard
print(lb, n = nrow(lb))  # Print all rows instead of default (6 rows)
h2o.varimp(lb)

pdf(file = "output/H2O/H20_featur_importance_heatmap_plot.pdf", width = 8, height = 6)
h2o.varimp_heatmap(lb)
dev.off()



# # Explain leader model & compare with all AutoML models
# exa <- h2o.explain(aml, test)
# exa$varimp
# exa$varimp_heatmap
# exa$model_correlation_heatmap

# Explain a single H2O model (e.g. leader model from AutoML)
exm <- h2o.explain(aml@leader, train)
exm 

varimp_df <- as.data.frame(h2o.varimp(aml@leader))
write.csv(varimp_df, file = "output/H2O/H20_feature_importance.csv", row.names = FALSE)

pdf(file = "output/H2O/H20_featur_importance_plot.pdf", width = 8, height = 4)
exm$varimp 
dev.off()


# ROC
model <- aml@leader
# dl_perf <- h2o.performance(model,train = T)
# dl_perf
dl_perf <- h2o.performance(model,newdata = test)
dl_perf

pdf(file = "output/H2O/H20_ROC_test_plot.pdf", width = 6, height = 6)
plot(dl_perf)
dev.off()

h2o.auc(dl_perf)
h2o.auc(dl_perf, train = TRUE, valid = TRUE, xval = FALSE)


######prective external################

pred <- h2o.predict(object = aml, newdata = df_ZSH)
pred <- as.data.frame(pred)
dir.create("output/H2O")
write.csv(pred, file = "output/H2O/ZSH_31samples_prediction.csv", row.names = TRUE)

# View a summary of the prediction with a probability of TRUE
summary(pred$p1, exact_quantiles = TRUE)




