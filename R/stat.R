library(lme4)
library(lmerTest)
library(lsmeans)
library(ggplot2)
library(pbkrtest)
library(devtools)

LC_ALL = "en_US.UTF-8"
par(family='Times New Roman')
setwd("/Users/sunghah/Desktop/thesis/data")
data = read.csv('preb_vowels.csv', stringsAsFactors=FALSE)

# ==================================================
# Convert columns to appropriate data types
data$filename = as.factor(data$filename)
data$phoneme = as.factor(data$phoneme)
data$context = as.factor(data$context)
data$depth = as.factor(data$depth)
data$left = as.factor(data$left)
data$right = as.factor(data$right)
data$start = as.numeric(data$start)
data$end = as.numeric(data$end)
data$sil_dur = as.numeric(data$sil_dur)
data$duration = as.numeric(data$duration)
data$f1_ch1 = as.numeric(data$f1_ch1)
data$f1_ch2 = as.numeric(data$f1_ch2)
data$f1_ch3 = as.numeric(data$f1_ch3)
data$f2_ch1 = as.numeric(data$f2_ch1)
data$f2_ch2 = as.numeric(data$f2_ch2)
data$f2_ch3 = as.numeric(data$f2_ch3)
data$f3_ch1 = as.numeric(data$f3_ch1)
data$f3_ch2 = as.numeric(data$f3_ch2)
data$f3_ch3 = as.numeric(data$f3_ch3)
data$f4_ch1 = as.numeric(data$f4_ch1)
data$f4_ch2 = as.numeric(data$f4_ch2)
data$f4_ch3 = as.numeric(data$f4_ch3)
data$intensity_ch1 = as.numeric(data$intensity_ch1)
data$intensity_ch2 = as.numeric(data$intensity_ch2)
data$intensity_ch3 = as.numeric(data$intensity_ch3)
data$pitch_ch1 = as.numeric(data$pitch_ch1)
data$pitch_ch2 = as.numeric(data$pitch_ch2)
data$pitch_ch3 = as.numeric(data$pitch_ch3)
data$duration = data$duration * 1000 # to milliseconds
data$sil_dur = data$sil_dur * 1000 # to milliseconds
# ==================================================

# histogram of silence duration
sil_dur.mean = mean(data$sil_dur) # add `na.rm = T` param if there's any NA value
sil_dur.median = median(data$sil_dur)
sil_dur.sd = sd(data$sil_dur)
sil_dur.var = var(data$sil_dur)
sil_dur.max = max(data$sil_dur)
sil_dur.min = min(data$sil_dur)

num_obs = dim(data)[1]
num_bins = ceiling(num_obs / 10000)

hist(data$sil_dur, breaks = num_bins, col = "steelblue", border = "white",
     main = "", xlab = "", ylab = "", xaxt = "n", yaxt = "n", 
     xlim = c(0, 1600), ylim = c(0, 0.003), prob = TRUE)

curve(dnorm(x, mean = sil_dur.mean, sd = sil_dur.sd), col = "red", lwd=2, add = T)
xtick = seq(0, 1600, by=200); axis(side=1, at=xtick)
ytick = seq(0, 0.003, by=0.001); axis(side=2, at=ytick)
title("Histogram of Silence Duration with Normal Density Curve", cex.main = 1.1)
title(xlab = "Silence Duration (ms)", ylab = "Probability", cex.lab = 1)
mtext("N = 10000", side = 4, cex = 0.7)
legend("right", c(paste("Mean =", round(sil_dur.mean, 2)),
                  paste("Median =",round(sil_dur.median, 2)),
                  paste("Std.dev. =", round(sil_dur.sd, 2)))
              , bty = "n", cex=0.8, y.intersp=0.5)

# ==================================================
