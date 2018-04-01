import sys
import pandas as pd
import numpy as np


spk2gender = '/home/sunghah/thesis/spk2gender'
preb_data = '/home/sunghah/thesis/data/preb_vowels.csv'
postb_data = '/home/sunghah/thesis/data/postb_vowels.csv'


gender_dict = {}
with open(spk2gender) as f:
    lines = f.readlines()
    for line in lines:
        fields = line.strip().split(' ')
        gender_dict[fields[0]] = fields[1]


data = preb_data
# read into dataframe while specifying praat's '--undefined--' as missing value
df = pd.read_csv(data, dtype={'filename': str, 'left': str, 'phoneme': str,
                              'right': str, 'start': np.float64, 'end': np.float64,
                              'duration': np.float64, 'f1_ch1': np.float64,
                              'f2_ch1': np.float64, 'f3_ch1': np.float64,
                              'f4_ch1': np.float64, 'f1_ch2': np.float64,
                              'f2_ch2': np.float64, 'f3_ch2': np.float64,
                              'f4_ch2': np.float64, 'f1_ch3': np.float64,
                              'f2_ch3': np.float64, 'f3_ch3': np.float64,
                              'f4_ch3': np.float64, 'pitch_ch1': np.float64,
                              'pitch_ch2': np.float64, 'pitch_ch3': np.float64,
                              'intensity_ch1': np.float64,
                              'intensity_ch2': np.float64,
                              'intensity_ch3': np.float64,
                              'context': str, 'depth': np.int, 'sil_dur':np.float64},
                       na_values = ['--undefined--'],
                       warn_bad_lines = True)

lines = len(df)

df['gender'] = str() # m or f

for idx in range(len(df)):
    print('preb.csv: on line #', idx+1, "/", lines); sys.stdout.flush()

    filename = df.loc[idx, 'filename']
    spk_id = ('-').join(filename.split('-')[:2])
    df['gender'] = gender_dict[spk_id]

df.to_csv('preb_g_vowels.csv', sep=',', encoding='utf-8', index=False)
del df


data = postb_data
# read into dataframe while specifying praat's '--undefined--' as missing value
df = pd.read_csv(data, dtype={'filename': str, 'left': str, 'phoneme': str,
                              'right': str, 'start': np.float64, 'end': np.float64,
                              'duration': np.float64, 'f1_ch1': np.float64,
                              'f2_ch1': np.float64, 'f3_ch1': np.float64,
                              'f4_ch1': np.float64, 'f1_ch2': np.float64,
                              'f2_ch2': np.float64, 'f3_ch2': np.float64,
                              'f4_ch2': np.float64, 'f1_ch3': np.float64,
                              'f2_ch3': np.float64, 'f3_ch3': np.float64,
                              'f4_ch3': np.float64, 'pitch_ch1': np.float64,
                              'pitch_ch2': np.float64, 'pitch_ch3': np.float64,
                              'intensity_ch1': np.float64,
                              'intensity_ch2': np.float64,
                              'intensity_ch3': np.float64,
                              'context': str, 'depth': np.int, 'sil_dur':np.float64},
                       na_values = ['--undefined--'],
                       warn_bad_lines = True)

df['gender'] = str() # m or f

# get post-boundary phones
for idx in range(len(df)):
    print('postb.csv: on line #', idx+1, "/", lines); sys.stdout.flush()

    filename = df.loc[idx, 'filename']
    spk_id = ('-').join(filename.split('-')[:2])
    df['gender'] = gender_dict[spk_id]

df.to_csv('postb_g_vowels.csv', sep=',', encoding='utf-8', index=False)
