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
ret      <- data.frame(df[3:7])


###===== SET-UP =====###
# ret
GEPU <- data.frame(df[13])
gepu <- cbind(1:length(GEPU$gepu),GEPU$gepu)
nrands = 10

###===== WAVELET-COHHERENT =====###

for (i in 1:5) {
  r <- cbind(1:length(ret[,i]),ret[,i]) 
  # GEPU vs Returns
  filename <- paste0("GEPU - ",toupper(country[i]),".png")
  png(filename, width=1200, height=900)
  wtc1 <- wtc(gepu, r, nrands = nrands)
  main <- paste("Wavelet Coherence: GEPU and",toupper(country[i]))
  par(oma = c(0, 0, 0, 1), mar = c(5, 4, 5, 5) + 0.1)
  plot(wtc1, plot.phase = TRUE, lty.coi = 1, col.coi = "white", lwd.coi = 2, 
       lwd.sig = 2, arrow.lwd = 0.06, arrow.len = 0.36, ylab = "Scale", xlab = "Period", 
       plot.cb = TRUE, main = main)
  n = length(gepu[, 1])
  abline(v = seq(365, n, 365), h = 1:16, col = "seashell4", lty = 3, lwd = 1)
  axis(side = 3, at = c(seq(0, n, 365)), labels = c(seq(2014,2025,1)))
  dev.off()
  
} 

## Remove temp vars
rm(r,GEPU,gepu,wtc1,filename,
   i,n,nrands,main,ret)
