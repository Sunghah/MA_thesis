library(mltools)
library(devtools)
library(ggplot2)
library(ggthemes)
library(gridExtra)
library(lme4)
library(lmerTest)
library(lsmeans)
library(effects)
library(phonR)

LC_ALL = "en_US.UTF-8"
par(family='Times New Roman')
options(digits=10)

source("/Users/sunghah/Desktop/thesis/pub_theme.R")
setwd("/Users/sunghah/Desktop/thesis/data")


# ==================================================
# ==================================================
# Pre-boundary data
# ==================================================
# ==================================================

preb_data = '/Users/sunghah/Desktop/thesis/data/preb_vowels.csv'
data = read.csv(preb_data, stringsAsFactors=FALSE)
num_obs = dim(data)[1]

# ==================================================
# Convert columns to appropriate data types
data$filename = as.factor(data$filename)
data$phoneme = as.factor(data$phoneme)
data$context = as.factor(data$context)
data$depth = as.factor(data$depth)
data$left = as.factor(data$left)
data$right = as.factor(data$right)
data$gender = as.factor(data$gender)
data$start = as.double(data$start)
data$end = as.double(data$end)
data$sil_dur = as.double(data$sil_dur)
data$duration = as.double(data$duration)
data$f1_ch1 = as.double(data$f1_ch1)
data$f1_ch2 = as.double(data$f1_ch2)
data$f1_ch3 = as.double(data$f1_ch3)
data$f2_ch1 = as.double(data$f2_ch1)
data$f2_ch2 = as.double(data$f2_ch2)
data$f2_ch3 = as.double(data$f2_ch3)
data$f3_ch1 = as.double(data$f3_ch1)
data$f3_ch2 = as.double(data$f3_ch2)
data$f3_ch3 = as.double(data$f3_ch3)
data$f4_ch1 = as.double(data$f4_ch1)
data$f4_ch2 = as.double(data$f4_ch2)
data$f4_ch3 = as.double(data$f4_ch3)
data$intensity_ch1 = as.double(data$intensity_ch1)
data$intensity_ch2 = as.double(data$intensity_ch2)
data$intensity_ch3 = as.double(data$intensity_ch3)
data$pitch_ch1 = as.double(data$pitch_ch1)
data$pitch_ch2 = as.double(data$pitch_ch2)
data$pitch_ch3 = as.double(data$pitch_ch3)
data$duration = data$duration * 1000 # to milliseconds
data$sil_dur = data$sil_dur * 1000 # to milliseconds

# ==================================================
# exclude outliers
# F1 & F2 outside 3 sd.'s
f1_ch2.mean = mean(data$f1_ch2); f1_ch2.sd = sd(data$f1_ch2)
f2_ch2.mean = mean(data$f2_ch2); f2_ch2.sd = sd(data$f2_ch2)

data = data[ which( ((data$f1_ch2 - f1_ch2.mean)/f1_ch2.sd < 3) |
                    ((data$f2_ch2 - f2_ch2.mean)/f2_ch2.sd < 3) ), ]

# pitch outside 3 sd.'s
m_p_ch2.mean = mean(data$pitch_ch2[data$gender == "m"]); m_p_ch2.sd = sd(data$pitch_ch2[data$gender == "m"])
f_p_ch2.mean = mean(data$pitch_ch2[data$gender == "f"]); f_p_ch2.sd = sd(data$pitch_ch2[data$gender == "f"])

data = data[ which( (data$gender == "m" & (data$pitch_ch2 - m_p_ch2.mean)/m_p_ch2.sd < 3) |
                    (data$gender == "f" & (data$pitch_ch2 - f_p_ch2.mean)/f_p_ch2.sd < 3) ), ]

# ==================================================
# monopthongs (as defined in CMUDict)
mono = data[ which(substr(data$phoneme, 1, 2) == 'AA' |
                   substr(data$phoneme, 1, 2) == 'AE' |
                   substr(data$phoneme, 1, 2) == 'AH' |
                   substr(data$phoneme, 1, 2) == 'AO' |
                   substr(data$phoneme, 1, 2) == 'EH' |
                   substr(data$phoneme, 1, 2) == 'IH' |
                   substr(data$phoneme, 1, 2) == 'IY' |
                   substr(data$phoneme, 1, 2) == 'UH' |
                   substr(data$phoneme, 1, 2) == 'UW'
                  ),
           ]
remove(data)

#  ==================================================
# vowels with (depth >= 3)
mono3 = mono[ which(mono$depth == 1 |
                    mono$depth == 2 |
                    mono$depth == 3
                   ),
            ]
remove(mono)

# exclude those with '_B' tag since they are post-boundary
mono3 = mono3[ which( substr(mono3$phoneme, 4, 5) != '_B' ), ]

# truncate stress markers and '_I', '_E' tags
mono3$phoneme = substr(mono3$phoneme, 1, 2)
mono3$phoneme = as.factor(mono3$phoneme)
summary(mono3$phoneme)

# tag speaker ID's
mono3$filename = as.character(mono3$filename)
for (i in 1:(dim(mono3)[1])) {
  # speaker ID is the first field of the filename
  mono3$speaker[i] = unlist(strsplit(mono3$filename[i], '-'))[1]
}
mono3$speaker = as.factor(mono3$speaker)

# ==================================================
# histogram of silence durations
summary(mono3$sil_dur)
p = ggplot(mono3, aes(x=sil_dur)) +
    geom_histogram(aes(y=..density..), breaks=seq(0, 1500, by=50), fill="#808080", col="white", alpha=0.9)
p = p + geom_density(col=2) + xlim(0, 1500) + ylim(0, 0.004)
p = p + labs(title="Distribution of Silence Durations", x="Duration (ms)", y="Density")
p + scale_color_Publication() + theme_Publication()

# ==================================================
# divide into 3 bins by quantiles
bins = bin_data(mono3$sil_dur, bins=3, binType = "quantile")
summary(bins)

mono3$strength[mono3$sil_dur < 150] = "Weak"
mono3$strength[mono3$sil_dur >= 150 & mono3$sil_dur <= 380] = "Medium"
mono3$strength[mono3$sil_dur > 380] = "Strong"
mono3$strength = factor(mono3$strength, levels=c("Weak", "Medium", "Strong"))
summary(mono3$strength)

# ==================================================
# violin plot of vowel durations by depth
p = ggplot(mono3, aes(x=depth, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    geom_boxplot(width=0.1) + labs(title="Pre-boundary Vowel Duration by Depth", x="Depth", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# violin plot of vowel durations by strength
p = ggplot(mono3, aes(x=strength, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    geom_boxplot(width=0.1) + labs(title="Pre-boundary Vowel Duration by Strength", x="Strength", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# duration of each vowel by depth
p = ggplot(mono3, aes(x=depth, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) + 
    facet_wrap(~phoneme, scales="free") + geom_boxplot(width=0.1) + scale_x_discrete(limits=c(1, 2, 3)) +
    labs(title="Pre-boundary Vowel Duration by Depth", x="Depth", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# duration of each vowel by strength
p = ggplot(mono3, aes(x=strength, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~phoneme, scales="free") + geom_boxplot(width=0.1) +
    labs(title="Pre-boundary Vowel Duration by Strength", x="Strength", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# vowel durations by depth given strength
p = ggplot(mono3, aes(x=depth, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~strength, scales="fixed") + geom_boxplot(width=0.1) +
    labs(title="Pre-boundary Vowel Duration by Depth Given Strength", x="Depth", y="Duration (ms)")
p  + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# vowel durations by strength given depth
p = ggplot(mono3, aes(x=strength, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~depth, scales="fixed") + geom_boxplot(width=0.1) +
    labs(title="Pre-boundary Vowel Duration by Strength Given Depth", x="Strength", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# intensity by depth given strength
mono3$meanIntensity = (mono3$intensity_ch1 + mono3$intensity_ch2 + mono3$intensity_ch3)/3
p = ggplot(mono3, aes(x=depth, y=intensity_ch2)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~strength, scales="fixed") + geom_boxplot(width=0.1) +
    labs(title="Pre-boundary Vowel Intensity by Depth Given Strength", x="Depth", y="Amplitude (dB)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# intensity by strength given depth
p = ggplot(mono3, aes(x=strength, y=meanIntensity)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~depth, scales="fixed") + geom_boxplot(width=0.1) +
    labs(title="Pre-boundary Vowel Intensity by Strength Given Depth", x="Strength", y="Amplitude (dB)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# pitch by strength given depth
m_mono3 = mono3[ which(mono3$gender == "m"), ]
f_mono3 = mono3[ which(mono3$gender == "f"), ]
m_mono3$meanPitch = (m_mono3$pitch_ch1 + m_mono3$pitch_ch2 + m_mono3$pitch_ch3) / 3
f_mono3$meanPitch = (f_mono3$pitch_ch1 + f_mono3$pitch_ch2 + f_mono3$pitch_ch3) / 3
mf_mono3 = rbind(m_mono3, f_mono3)

# rename columns and levels to make it look better when facetted
names(mf_mono3)[names(mf_mono3)=="depth"] = "Depth"
names(mf_mono3)[names(mf_mono3)=="gender"] = "Gender"
levels(mf_mono3$Gender) = c("Female", "Male")
levels(mf_mono3$Depth) = seq(1, 151, 1)

# pitch by depth given strength
p = ggplot(mf_mono3, aes(x=strength, y=meanPitch)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_grid(Gender ~ Depth, scales="free", labeller=label_both) + geom_boxplot(width=0.1) +
    labs(title="Pre-boundary Vowel Pitch by Depth Given Strength", x="Depth", y="Frequency (Hz)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# pitch by strength given depth
p = ggplot(mf_mono3, aes(x=Depth, y=meanPitch)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_grid(Gender ~ strength, scales="free", labeller=label_both) + geom_boxplot(width=0.1) +
    labs(title="Pre-boundary Vowel Pitch by Strength Given Depth", x="Strength", y="Frequency (Hz)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# tests
# DV: duration
# IV: strength, depth
# Random factor: filename (speaker ID)
fit1.lmer = lmer(duration ~ strength * depth + (1|speaker), mono3)
coef(fit1.lmer)
anova(fit1.lmer)
lsmeans(fit1.lmer, pairwise~depth|strength, adjust="tukey")

df = as.data.frame( Effect(c("depth", "strength"), fit1.lmer) )
df$Depth = factor(df$depth, levels = c(1, 2, 3))
df$Strength = factor(df$strength, levels = c("Weak", "Medium", "Strong"))

p = ggplot(df, aes(Depth, fit, group=Strength)) + geom_point() + geom_line(color="#808080") + 
    facet_wrap(~Strength, scales="fixed", labeller=labeller(Strength=label_both)) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Pre-boundary Vowel Duration by Depth Given Strength", x = "Depth", y = "Duration (ms)")
p + scale_color_Publication() + theme_Publication()

p = ggplot(df, aes(Strength, fit, group=Depth)) + geom_point() + geom_line(color="#808080") +
    facet_wrap(~Depth, scales="fixed", labeller=labeller(Depth=label_both)) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Pre-boundary Vowel Duration by Strength Given Depth", x = "Strength", y = "Duration (ms)")
p + scale_color_Publication() + theme_Publication()

# ==================================================
# tests
# DV: intensity
# IV: strength, depth
# Random factor: filename (speaker ID)
fit2.lmer = lmer(meanIntensity ~ strength * depth + (1|speaker), mono3)
coef(fit2.lmer)
anova(fit2.lmer)
lsmeans(fit2.lmer, pairwise~depth|strength, adjust="tukey")

df = as.data.frame( Effect(c("depth", "strength"), fit2.lmer) )
df$Depth = factor(df$depth, levels = c(1, 2, 3))
df$Strength = factor(df$strength, levels = c("Weak", "Medium", "Strong"))

p = ggplot(df, aes(Depth, fit, group=strength)) + geom_point() + geom_line(color="#808080") +
    facet_wrap(~Strength, scales="fixed", labeller=labeller(Strength=label_both)) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Pre-boundary Vowel Intensity by Depth Given Strength", x="Depth", y="Amplitude (dB)")
p + scale_color_Publication() + theme_Publication()

p = ggplot(df, aes(Strength, fit, group=Depth)) + geom_point() + geom_line(color="#808080") +
    facet_grid(~Depth, scales="fixed", labeller=labeller(Depth=label_both)) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Pre-boundary Vowel Intensity by Strength Given Depth", x="Strength", y="Amplitude (dB)")
p + scale_color_Publication() + theme_Publication()

# ==================================================
# tests
# DV: pitch (male & female)
# IV: strength, depth
# Random factor: filename (speaker ID)
fit3.lmer = lmer(meanPitch ~ strength * depth + (1|speaker), m_mono3)
coef(fit3.lmer)
anova(fit3.lmer)
lsmeans(fit3.lmer, pairwise~depth|strength, adjust="tukey")

fit4.lmer = lmer(meanPitch ~ strength * depth + (1|speaker), f_mono3)
coef(fit4.lmer)
anova(fit4.lmer)
lsmeans(fit4.lmer, pairwise~depth|strength, adjust="tukey")

df1 = as.data.frame( Effect(c("depth", "strength"), fit3.lmer) )
df1$Depth = factor(df1$depth, levels = c(1, 2, 3))
df1$Strength = factor(df1$strength, levels = c("Weak", "Medium", "Strong"))
df1$Gender = "Male"

df2 = as.data.frame( Effect(c("depth", "strength"), fit4.lmer) )
df2$Depth = factor(df2$depth, levels = c(1, 2, 3))
df2$Strength = factor(df2$strength, levels = c("Weak", "Medium", "Strong"))
df2$Gender = "Female"

df = rbind(df1, df2)

p = ggplot(df, aes(Depth, fit, group=Strength)) + geom_point() + geom_line(color="#808080") +
    facet_grid(Gender~Strength, scales="free", labeller=label_both) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Pre-boundary Vowel Pitch by Depth Given Strength", x="Depth", y="Frequency (Hz)")
p + scale_color_Publication() + theme_Publication()

p = ggplot(df, aes(Strength, fit, group=Depth)) + geom_point() + geom_line(color="#808080") +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    facet_grid(Gender~Depth, scales="free", labeller=label_both) +
    labs(title="Pre-boundary Vowel Pitch by Strength Given Depth", x="Strength", y="Frequency (Hz)")
p + scale_color_Publication() + theme_Publication()

# ==================================================
# Vowel contour plot

mono3$norm_f1_ch2 = normLobanov(mono3$f1_ch2)
mono3$norm_f2_ch2 = normLobanov(mono3$f2_ch2)

bins = 5
size = 1.2

p = ggplot(mono3, aes(norm_f2_ch2, norm_f1_ch2, color=phoneme)) + stat_density2d(bins=bins, size=size) +
  facet_grid(~strength, scales="fixed") + scale_x_reverse() + scale_y_reverse() +
  labs(title="Pre-boundary Vowel Contours by Strength", x="F2 (normalized)", y="F1 (normalized)")
p + scale_color_Publication() + theme_Publication()

p = ggplot(mono3, aes(norm_f2_ch2, norm_f1_ch2, color=phoneme)) + stat_density2d(bins=bins, size=size) +
  facet_grid(~depth, scales="fixed") + scale_x_reverse() + scale_y_reverse() +
  labs(title="Pre-boundary Vowel Contours by Depth", x="F2 (normalized)", y="F1 (normalized)")
p + scale_color_Publication() + theme_Publication()


# ==================================================
# ==================================================
# Post-boundary data
# ==================================================
# ==================================================


postb_data = '/Users/sunghah/Desktop/thesis/data/postb_vowels.csv'
data = read.csv(postb_data, stringsAsFactors=FALSE)
num_obs = dim(data)[1]

# ==================================================
# Convert columns to appropriate data types
data$filename = as.factor(data$filename)
data$phoneme = as.factor(data$phoneme)
data$context = as.factor(data$context)
data$depth = as.factor(data$depth)
data$left = as.factor(data$left)
data$right = as.factor(data$right)
data$gender = as.factor(data$gender)
data$start = as.double(data$start)
data$end = as.double(data$end)
data$sil_dur = as.double(data$sil_dur)
data$duration = as.double(data$duration)
data$f1_ch1 = as.double(data$f1_ch1)
data$f1_ch2 = as.double(data$f1_ch2)
data$f1_ch3 = as.double(data$f1_ch3)
data$f2_ch1 = as.double(data$f2_ch1)
data$f2_ch2 = as.double(data$f2_ch2)
data$f2_ch3 = as.double(data$f2_ch3)
data$f3_ch1 = as.double(data$f3_ch1)
data$f3_ch2 = as.double(data$f3_ch2)
data$f3_ch3 = as.double(data$f3_ch3)
data$f4_ch1 = as.double(data$f4_ch1)
data$f4_ch2 = as.double(data$f4_ch2)
data$f4_ch3 = as.double(data$f4_ch3)
data$intensity_ch1 = as.double(data$intensity_ch1)
data$intensity_ch2 = as.double(data$intensity_ch2)
data$intensity_ch3 = as.double(data$intensity_ch3)
data$pitch_ch1 = as.double(data$pitch_ch1)
data$pitch_ch2 = as.double(data$pitch_ch2)
data$pitch_ch3 = as.double(data$pitch_ch3)
data$duration = data$duration * 1000 # to milliseconds
data$sil_dur = data$sil_dur * 1000 # to milliseconds

# ==================================================
# exclude outliers
# F1 & F2 outside 3 sd.'s
f1_ch2.mean = mean(data$f1_ch2); f1_ch2.sd = sd(data$f1_ch2)
f2_ch2.mean = mean(data$f2_ch2); f2_ch2.sd = sd(data$f2_ch2)

data = data[ which( ((data$f1_ch2 - f1_ch2.mean)/f1_ch2.sd < 3) |
                    ((data$f2_ch2 - f2_ch2.mean)/f2_ch2.sd < 3) ), ]

# pitch outside 3 sd.'s
m_p_ch2.mean = mean(data$pitch_ch2[data$gender == "m"]); m_p_ch2.sd = sd(data$pitch_ch2[data$gender == "m"])
f_p_ch2.mean = mean(data$pitch_ch2[data$gender == "f"]); f_p_ch2.sd = sd(data$pitch_ch2[data$gender == "f"])

data = data[ which( (data$gender == "m" & (data$pitch_ch2 - m_p_ch2.mean)/m_p_ch2.sd < 3) |
                    (data$gender == "f" & (data$pitch_ch2 - f_p_ch2.mean)/f_p_ch2.sd < 3) ), ]

# ==================================================
# monopthongs (as defined in CMUDict)
mono = data[ which(substr(data$phoneme, 1, 2) == 'AA' |
                   substr(data$phoneme, 1, 2) == 'AE' |
                   substr(data$phoneme, 1, 2) == 'AH' |
                   substr(data$phoneme, 1, 2) == 'AO' |
                   substr(data$phoneme, 1, 2) == 'EH' |
                   substr(data$phoneme, 1, 2) == 'IH' |
                   substr(data$phoneme, 1, 2) == 'IY' |
                   substr(data$phoneme, 1, 2) == 'UH' |
                   substr(data$phoneme, 1, 2) == 'UW'
                  ),
           ]
remove(data)

#  ==================================================
# vowels with (depth >= 3)
mono3 = mono[ which(mono$depth == 1 |
                    mono$depth == 2 |
                    mono$depth == 3
                   ),
            ]
remove(mono)

# exclude those with '_E' tag since they are pre-boundary
mono3 = mono3[ which(substr(mono3$phoneme, 4, 5) != '_E'), ]

# truncate stress markers and '_B', '_I' tags
mono3$phoneme = substr(mono3$phoneme, 1, 2)
mono3$phoneme = as.factor(mono3$phoneme)
summary(mono3$phoneme)

# tag speaker ID's
mono3$filename = as.character(mono3$filename)
for (i in 1:(dim(mono3)[1])) {
  # speaker ID is the first field of the filename
  mono3$speaker[i] = unlist(strsplit(mono3$filename[i], '-'))[1]
}
mono3$speaker = as.factor(mono3$speaker)

# ==================================================
# divide into 3 bins by quantiles
bins = bin_data(mono3$sil_dur, bins=3, binType = "quantile")
summary(bins)

mono3$strength[mono3$sil_dur < 150] = "Weak"
mono3$strength[mono3$sil_dur >= 150 & mono3$sil_dur <= 380] = "Medium"
mono3$strength[mono3$sil_dur > 380] = "Strong"
mono3$strength = factor(mono3$strength, levels=c("Weak", "Medium", "Strong"))
summary(mono3$strength)

# ==================================================
# violin plot of vowel durations by depth
p = ggplot(mono3, aes(x=depth, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    geom_boxplot(width=0.1) + labs(title="Post-boundary Vowel Duration by Depth", x="Depth", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# violin plot of vowel durations by strength
p = ggplot(mono3, aes(x=strength, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    geom_boxplot(width=0.1) + labs(title="Post-boundary Vowel Duration by Strength", x="Strength", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# duration of each vowel by depth
p = ggplot(mono3, aes(x=depth, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) + 
    facet_wrap(~phoneme, scales="free") + geom_boxplot(width=0.1) + scale_x_discrete(limits=c(1, 2, 3)) +
    labs(title="Post-boundary Vowel Duration by Depth", x="Depth", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# duration of each vowel by strength
p = ggplot(mono3, aes(x=strength, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~phoneme, scales="free") + geom_boxplot(width=0.1) +
    labs(title="Post-boundary Vowel Duration by Strength", x="Strength", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# vowel durations by depth given strength
p = ggplot(mono3, aes(x=depth, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~strength, scales="fixed") + geom_boxplot(width=0.1) +
    labs(title="Post-boundary Vowel Duration by Depth Given Strength", x="Depth", y="Duration (ms)")
p  + scale_color_Publication() + theme_Publication() # + coord_flip()

# vowel durations by strength given depth
p = ggplot(mono3, aes(x=strength, y=duration)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~depth, scales="fixed") + geom_boxplot(width=0.1) +
    labs(title="Post-boundary Vowel Duration by Strength Given Depth", x="Strength", y="Duration (ms)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# intensity by depth given strength
mono3$meanIntensity = (mono3$intensity_ch1 + mono3$intensity_ch2 + mono3$intensity_ch3)/3
p = ggplot(mono3, aes(x=depth, y=intensity_ch2)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~strength, scales="fixed") + geom_boxplot(width=0.1) +
    labs(title="Post-boundary Vowel Intensity by Depth Given Strength", x="Depth", y="Amplitude (dB)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# intensity by strength given depth
p = ggplot(mono3, aes(x=strength, y=meanIntensity)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_wrap(~depth, scales="fixed") + geom_boxplot(width=0.1) +
    labs(title="Post-boundary Vowel Intensity by Strength Given Depth", x="Strength", y="Amplitude (dB)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# pitch by strength given depth
m_mono3 = mono3[ which(mono3$gender == "m"), ]
f_mono3 = mono3[ which(mono3$gender == "f"), ]
m_mono3$meanPitch = (m_mono3$pitch_ch1 + m_mono3$pitch_ch2 + m_mono3$pitch_ch3) / 3
f_mono3$meanPitch = (f_mono3$pitch_ch1 + f_mono3$pitch_ch2 + f_mono3$pitch_ch3) / 3
mf_mono3 = rbind(m_mono3, f_mono3)

# rename columns and levels to make it look better when facetted
names(mf_mono3)[names(mf_mono3)=="strength"] = "Strength"
names(mf_mono3)[names(mf_mono3)=="depth"] = "Depth"
names(mf_mono3)[names(mf_mono3)=="gender"] = "Gender"
levels(mf_mono3$Strength) = c("Weak", "Medium", "Strong")
levels(mf_mono3$Depth) = seq(1, 151, 1)
levels(mf_mono3$Gender) = c("Female", "Male")

# pitch by depth given strength
p = ggplot(mf_mono3, aes(x=Strength, y=meanPitch)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_grid(Gender ~ Depth, scales="free", labeller=label_both) + geom_boxplot(width=0.1) +
    labs(title="Post-boundary Vowel Pitch by Depth Given Strength", x="Depth", y="Frequency (Hz)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# pitch by strength given depth
p = ggplot(mf_mono3, aes(x=Depth, y=meanPitch)) + geom_violin(fill="#D3D3D3", trim=TRUE) +
    facet_grid(Gender ~ Strength, scales="free", labeller=label_both) + geom_boxplot(width=0.1) +
    labs(title="Post-boundary Vowel Pitch by Strength Given Depth", x="Strength", y="Frequency (Hz)")
p + scale_color_Publication() + theme_Publication() # + coord_flip()

# ==================================================
# tests
# DV: duration
# IV: strength, depth
# Random factor: filename (speaker ID)
fit1.lmer = lmer(duration ~ strength * depth + (1|speaker), mono3)
coef(fit1.lmer)
anova(fit1.lmer)
lsmeans(fit1.lmer, pairwise~depth|strength, adjust="tukey")

df = as.data.frame( Effect(c("depth", "strength"), fit1.lmer) )
df$Depth = factor(df$depth, levels = c(1, 2, 3))
df$Strength = factor(df$strength, levels = c("Weak", "Medium", "Strong"))

p = ggplot(df, aes(Depth, fit, group=Strength)) + geom_point() + geom_line(color="#808080") +
    facet_wrap(~Strength, scales="fixed", labeller=labeller(Strength=label_both)) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Post-boundary Vowel Duration by Depth Given Strength", x = "Depth", y = "Duration (ms)")
p + scale_color_Publication() + theme_Publication()

p = ggplot(df, aes(Strength, fit, group=Depth)) + geom_point() + geom_line(color="#808080") +
    facet_wrap(~Depth, scales="fixed", labeller=labeller(Depth=label_both)) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Post-boundary Vowel Duration by Strength Given Depth", x = "Strength", y = "Duration (ms)")
p + scale_color_Publication() + theme_Publication()

# ==================================================
# tests
# DV: intensity
# IV: strength, depth
# Random factor: filename (speaker ID)
fit2.lmer = lmer(meanIntensity ~ strength * depth + (1|speaker), mono3)
coef(fit2.lmer)
anova(fit2.lmer)
lsmeans(fit2.lmer, pairwise~depth|strength, adjust="tukey")

df = as.data.frame( Effect(c("depth", "strength"), fit2.lmer) )
df$Depth = factor(df$depth, levels = c(1, 2, 3))
df$Strength = factor(df$strength, levels = c("Weak", "Medium", "Strong"))

p = ggplot(df, aes(Depth, fit, group=strength)) + geom_point() + geom_line(color="#808080") +
    facet_wrap(~Strength, scales="fixed", labeller=labeller(Strength=label_both)) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Post-boundary Vowel Intensity by Depth Given Strength", x="Depth", y="Amplitude (dB)")
p + scale_color_Publication() + theme_Publication()

p = ggplot(df, aes(Strength, fit, group=Depth)) + geom_point() + geom_line(color="#808080") +
    facet_grid(~Depth, scales="fixed", labeller=labeller(Depth=label_both)) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Post-boundary Vowel Intensity by Strength Given Depth", x="Strength", y="Amplitude (dB)")
p + scale_color_Publication() + theme_Publication()

# ==================================================
# tests
# DV: pitch (male & female)
# IV: strength, depth
# Random factor: filename (speaker ID)
fit3.lmer = lmer(meanPitch ~ strength * depth + (1|speaker), m_mono3)
coef(fit3.lmer)
anova(fit3.lmer)
lsmeans(fit3.lmer, pairwise~depth|strength, adjust="tukey")

fit4.lmer = lmer(meanPitch ~ strength * depth + (1|speaker), f_mono3)
coef(fit4.lmer)
anova(fit4.lmer)
lsmeans(fit4.lmer, pairwise~depth|strength, adjust="tukey")

df1 = as.data.frame( Effect(c("depth", "strength"), fit3.lmer) )
df1$Gender = "Male"
df1$Depth = factor(df1$depth, levels = c(1, 2, 3))
df1$Strength = factor(df1$strength, levels = c("Weak", "Medium", "Strong"))

df2 = as.data.frame( Effect(c("depth", "strength"), fit4.lmer) )
df2$Gender = "Female"
df2$Depth = factor(df2$depth, levels = c(1, 2, 3))
df2$Strength = factor(df2$strength, levels = c("Weak", "Medium", "Strong"))

df = rbind(df1, df2)
df$Gender = factor(df$Gender, levels = c("Female", "Male"))

p = ggplot(df, aes(Depth, fit, group=Strength)) + geom_point() + geom_line(color="#808080") +
    facet_grid(Gender~Strength, scales="free", labeller=label_both) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Post-boundary Vowel Pitch by Depth Given Strength", x="Depth", y="Frequency (Hz)")
p + scale_color_Publication() + theme_Publication()

p = ggplot(df, aes(Strength, fit, group=Depth)) + geom_point() + geom_line(color="#808080") + 
    facet_grid(Gender~Depth, scales="free", labeller=label_both) +
    geom_errorbar(aes(ymin=lower, ymax=upper), width=0.5) +
    labs(title="Post-boundary Vowel Pitch by Strength Given Depth", x="Strength", y="Frequency (Hz)")
p + scale_color_Publication() + theme_Publication()

# ==================================================
# Vowel contour plot

mono3$norm_f1_ch2 = normLobanov(mono3$f1_ch2)
mono3$norm_f2_ch2 = normLobanov(mono3$f2_ch2)

bins = 5
size = 1.2

p = ggplot(mono3, aes(norm_f2_ch2, norm_f1_ch2, color=phoneme)) + stat_density2d(bins=bins, size=size)
    facet_grid(~strength, scales="fixed")+ scale_x_reverse() + scale_y_reverse() +
    labs(title="Post-boundary Vowel Contours by Strength", x="F2 (normalized)", y="F1 (normalized)")
p + scale_color_Publication() + theme_Publication()

p = ggplot(mono3, aes(norm_f2_ch2, norm_f1_ch2, color=phoneme)) + stat_density2d(bins=bins, size=size) +
    facet_grid(~depth, scales="fixed") + scale_x_reverse() + scale_y_reverse() +
    labs(title="Post-boundary Vowel Contours by Depth", x="F2 (normalized)", y="F1 (normalized)")
p + scale_color_Publication() + theme_Publication()
