###===== RESET ALL =====###
rm(list = ls(all.names = TRUE))



###===== LIBRARY =====###
## Data In/Out
library(readxl)
library(openxlsx)      # bỏ nếu không write.xlsx
## Statistics & tests
library(tseries)       # kpss.test
library(FinTS)         # ArchTest
library(fBasics)       # skewness, kurtosis
library(psych)         # corr.test
library(forecast)      # dm.test
## Time-series & models
library(xts)
library(rumidas)       # GARCH-MIDAS
library(biwavelet)     # wavelet coherence

###===== IMPORT DATA =====###
dir      <- dirname(rstudioapi::getActiveDocumentContext()$path)
setwd(dir)
# High frequency data
df       <- read_excel("Data.xlsx", sheet = "dat")  # df high freq table
df$date  <- as.Date(df$date)
df$month <- as.Date(df$month)
df       <- as.data.frame(df)
# Low frequency data
X        <- read_excel("Data.xlsx", sheet = "x")     # X low freq table
X$month  <- as.Date(X$month)
X        <- as.data.frame(X)
# Some vectors
country  <- c("ina","mas","phi","tha","vie")
gepu     <- c("gepu")

###==== FUNCTIONS ====###

## Add star function

add_star <- function(p_val) if (p_val < 0.01) "***" else if (p_val < 0.05) "**" else if (p_val < 0.1) "*" else ""

## Estimators formatting function

fmt_coef <- function(coef, row) {
  stat   <- round(coef[row, 1], digits = 3)
  se     <- round(coef[row, 2], digits = 3)
  p_val  <- coef[row, 4]
  
  c(paste0(stat, add_star(p_val)), paste0("(",se,")"))
}


###==== K PARAMETER FOR GARCH MIDAS ====###

h_set  <- c(10, 30, 60, 180)
K = 73

###===== GARCH-MIDAS-RV =====###
## Create Table of Result


result_rv <- data.frame(
  check.names    = FALSE,
  K              = numeric(),
  INDEX          = character(),
  "\u03b1"       = numeric(),
  "\u03b2"       = numeric(),
  "m"            = numeric(),
  "\u03b8"       = numeric(),
  "\u03c9\u2082" = numeric(),
  "LL"           = numeric(),
  "AIC"          = numeric(),
  "BIC"          = numeric()
)


result_gepu <- data.frame(
  check.names    = FALSE,
  K              = numeric(),
  INDEX          = character(),
  "\u03b1"       = numeric(),
  "\u03b2"       = numeric(),
  "m"            = numeric(),
  "\u03b8"       = numeric(),
  "\u03c9\u2082" = numeric(),
  "LL"           = numeric(),
  "AIC"          = numeric(),
  "BIC"          = numeric()
)

## Create Table to Save Forecast Results

rv_f10  <- data.frame(no = 1:10)
rv_f30  <- data.frame(no = 1:30)
rv_f60  <- data.frame(no = 1:60)
rv_f180 <- data.frame(no = 1:180)

## Create DM Test Table of Result

dmtest <- data.frame(
  K     = numeric(),
  INDEX = character(),
  h10   = numeric(),
  h30   = numeric(),
  h60   = numeric(),
  h180  = numeric()
)

## Setting Time-series

gepu <- xts(X$gepu, order.by  = X$month)

##==== Run GARCH-MIDAS-RV ====##

for (i in 1:5){
  print(i)
  
  return <- xts(df[,i+2], order.by = df[,1])
  rv     <- xts(X[,i+1], order.by  = X[,1])
  mv     <- mv_into_mat(return, rv, K = K, type = "monthly")

  
  ## Model fitting
  
  result <- ugmfit(
    model = "GM",
    skew = "NO",
    distribution = "norm",
    daily_ret = return,
    mv,
    K = K,
    lag_fun = "Beta",
    out_of_sample = 180
  )
  
  ## Save forecast for DM-test
  
  for (h in h_set) {
    f    <- multi_step_ahead_pred(result, h = h)
    name <- paste0("rv_f", h)
    assign(name, cbind(get(name), f))
  }
  
  coef <- result$rob_coef_mat
  
  alpha <- fmt_coef(coef, 1)
  beta  <- fmt_coef(coef, 2)
  m     <- fmt_coef(coef, 3)
  theta <- fmt_coef(coef, 4)
  w2    <- fmt_coef(coef, 5)
  
  LL  <- c(round(result$loglik, digits = 3), "")
  AIC <- c(round(result$inf_criteria[1], digits = 3), "")
  BIC <- c(round(result$inf_criteria[2], digits = 3), "")
  
  #Temporary result saving
  
  temp <- data.frame(
    K = K,
    INDEX = country[i],
    alpha = alpha,
    beta = beta,
    m = m,
    theta = theta,
    w2 = w2,
    LL = LL,
    AIC = AIC,
    BIC = BIC
  )
  
  colnames(temp) <- colnames(result_rv)
  result_rv <- rbind(result_rv, temp)

}


##==== FORECAST RV TABLE ====##

col_names <- c("no", country)
colnames(rv_f10)  <- col_names
colnames(rv_f30)  <- col_names
colnames(rv_f60)  <- col_names
colnames(rv_f180) <- col_names

##==== Run GARCH-MIDAS-GEPU ====##

for (i in 1:5){
  print(i)
  
  return <- xts(df[,i+2], order.by = df[,1])
  mv     <- mv_into_mat(return, gepu, K = K, type = "monthly")
  
  
  ## Model fitting
  
  result <- ugmfit(
    model = "GM",
    skew = "NO",
    distribution = "norm",
    daily_ret = return,
    mv,
    K = K,
    lag_fun = "Beta",
    out_of_sample = 180
  )
  
  ## Actual out-of-sample proxy (squared daily returns = daily variance)
  proxy <- tail(as.numeric(return), 180)^2
  
  ## DM test on forecast ERRORS: GEPU vs RV
  dm_stat <- c()
  for (h in h_set) {
    f_gepu <- as.numeric(multi_step_ahead_pred(result, h = h))  # GEPU vol forecast
    f_rv   <- as.numeric(get(paste0("rv_f", h))[, i + 1])       # RV vol forecast 
    act    <- proxy[1:h]                                         
    e_gepu <- act - f_gepu^2    # errors for gepu variance
    e_rv   <- act - f_rv^2      # same but rv
    
    test <- dm.test(e_gepu, e_rv,
                    alternative = "two.sided", h = 1, power = 2, varestimator = "acf")
    dm_stat[paste0("h", h)] <- paste0(round(test$statistic, 3), add_star(test$p.value))
  }
  
  temp <- data.frame(
    K = K, INDEX = toupper(country[i]),
    h10 = dm_stat["h10"], h30 = dm_stat["h30"],
    h60 = dm_stat["h60"], h180 = dm_stat["h180"],
    row.names = NULL
  )
  dmtest <- rbind(dmtest, temp)
  
  
  
  coef <- result$rob_coef_mat
  
  alpha <- fmt_coef(coef, 1)
  beta  <- fmt_coef(coef, 2)
  m     <- fmt_coef(coef, 3)
  theta <- fmt_coef(coef, 4)
  w2    <- fmt_coef(coef, 5)
  
  LL  <- c(round(result$loglik, digits = 3), "")
  AIC <- c(round(result$inf_criteria[1], digits = 3), "")
  BIC <- c(round(result$inf_criteria[2], digits = 3), "")
  
  #Temporary result saving
  
  temp <- data.frame(
    K = K,
    INDEX = country[i],
    alpha = alpha,
    beta = beta,
    m = m,
    theta = theta,
    w2 = w2,
    LL = LL,
    AIC = AIC,
    BIC = BIC
  )
  
  colnames(temp) <- colnames(result_gepu)
  result_gepu <- rbind(result_gepu, temp)
  
}

print(result_rv)
print(result_gepu)
print(dmtest)

## Export tables → CSV
dir.create("tables", showWarnings = FALSE)

write.csv(result_rv,   "tables/garch_midas_rv.csv",    row.names = FALSE, fileEncoding = "UTF-8")
write.csv(result_gepu, "tables/garch_midas_gepu.csv",  row.names = FALSE, fileEncoding = "UTF-8")
write.csv(dmtest,      "tables/dm_test.csv",           row.names = FALSE, fileEncoding = "UTF-8")
