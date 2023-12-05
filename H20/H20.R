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
dl_perf

plot(dl_perf)
h2o.auc(dl_perf)


