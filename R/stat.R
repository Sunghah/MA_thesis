library(devtools)
library(ggplot2)
library(ggthemes)
library(gridExtra)

library(lme4)
library(lmerTest)
library(lsmeans)
library(pbkrtest)


LC_ALL = "en_US.UTF-8"
par(family='Times New Roman')
#theme_update(plot.title = element_text(hjust = 0.5)) # center ggplot titles

setwd("/Users/sunghah/Desktop/thesis/data")
source("/Users/sunghah/Desktop/thesis/pub_theme.R")
data = read.csv('preb_vowels.csv', stringsAsFactors=FALSE)
num_obs = dim(data)[1]

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
# histogram of silence durations
sil_dur.mean = mean(data$sil_dur) # add `na.rm = T` param if there's any NA value
sil_dur.median = median(data$sil_dur)
sil_dur.sd = sd(data$sil_dur)
sil_dur.var = var(data$sil_dur)
sil_dur.max = max(data$sil_dur)
sil_dur.min = min(data$sil_dur)

p = ggplot(data, aes(x=sil_dur))
p = p + geom_histogram(aes(y=..density..), breaks=seq(0, 1500, by=50), col="white", alpha=.8)
p = p + geom_density(col=2) + xlim(0, 1500)
p = p + labs(title="Distribution of Silence Durations", x="duration (ms)", y="density")
p = p + scale_color_Publication() + theme_Publication()
p

# ==================================================
# violin plot of vowel durations

p = ggplot(data, aes(x=depth, y=duration)) + geom_violin()
p = p + geom_boxplot(width=0.1)
#p = p + scale_x_discrete(limits=c(1, 2, 3, 4, 5, 6, 7, 8, 9, 10))
p = p + scale_x_discrete(limits=c(1, 2, 3, 4, 5))
p = p + labs(title="Vowel Duration by Depth", x="Depth", y="Duration (ms)")
p = p  + scale_color_Publication() + theme_Publication()
#p = p + coord_flip()
p

#  ==================================================
# data with (depth > 5)
data5 = data[ which(data$depth == 1 |
                    data$depth == 2 |
                    data$depth == 3 |
                    data$depth == 4 | 
                    data$depth == 5
                    ), ]


#  ==================================================
# 


# ==================================================
# 


# ==================================================
# 


# ==================================================
# 
