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

## Stat function

desc_row <- function(x, label, kpss_null = "Level", kpss_lshort = TRUE) {
  x  <- as.numeric(x)
  lb <- Box.test(x^2, lag = 10, type = "Ljung-Box")
  ar <- ArchTest(x, lags = 10, demean = TRUE)
  kp <- kpss.test(x, null = kpss_null, lshort = kpss_lshort)

###===== DESCRIPTIVE STATISTICS =====###

## Table-setting
  
  data.frame(
    index = label,
    no    = length(x),
    mean  = round(mean(x), 3),
    med   = round(median(x), 3),
    min   = round(min(x), 3),
    max   = round(max(x), 3),
    skew  = round(skewness(x), 3),
    kurt  = round(kurtosis(x), 3),
    lb    = paste0(round(lb$statistic, 3), add_star(lb$p.value)),
    arch  = paste0(round(ar$statistic, 3), add_star(ar$p.value)),
    kpss  = paste0(round(kp$statistic, 3), add_star(kp$p.value)),
    row.names = NULL
  )
}

## Returns + GEPU (KPSS: Trend, lshort = FALSE)
ret <- df[3:7]
ds  <- do.call(rbind, lapply(1:5, function(i) desc_row(ret[[i]], country[i])))
ds  <- rbind(ds, desc_row(X[[7]], "gepu", kpss_null = "Trend", kpss_lshort = FALSE))

print(ds)


###===== CORRELATION MATRIX =====###

## Returns
corr <- corr.test(x = ret, y = NULL, use = "pairwise", method = "pearson")
corr$stars

## Export tables → CSV
dir.create("tables", showWarnings = FALSE)

write.csv(ds,          "tables/descriptive_stats.csv", row.names = FALSE, fileEncoding = "UTF-8")
write.csv(corr$stars,  "tables/correlation.csv",       row.names = TRUE,  fileEncoding = "UTF-8")

