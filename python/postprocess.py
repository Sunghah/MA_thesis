import sys
import pandas as pd
import numpy as np


data = '/home/sunghah/thesis/extract.csv'

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
                              'intensity_ch3': np.float64},
                       na_values = ['--undefined--'],
                       warn_bad_lines = True)


df['context'] = str # pre- or post-boundary
df['depth'] = np.int # distance from SIL
df['sil_dur'] = np.float64()
lines = len(df)

silence = 'SIL' # silence phone
vowels = ['AA', 'AE', 'AH', 'AO', 'AW', 'AY', 'EH', 'ER',
          'EY', 'IH', 'IY', 'OW', 'OY', 'UH', 'UW', 'W', 'Y'] # all vowels


preb_df = pd.DataFrame() # output dataframe

# get pre-boundary phones
for idx in range(len(df)):
    print('on line #', idx+1, "/", lines)
    sys.stdout.flush()

    phone = df.loc[idx, 'phoneme']
    left = df.loc[idx, 'left']
    depth = 1

    if phone == silence:
        # shift left up to 'SIL' or 'Start'
        while (phone == silence) and (left != 'Start') and (idx-depth > -1):

            if left[0:2] in vowels:
                df.loc[idx-depth, 'context'] = 'Pre'
                df.loc[idx-depth, 'depth'] = depth
                df.loc[idx-depth, 'sil_dur'] = df.loc[idx, 'duration']
                preb_df = preb_df.append(df.iloc[idx-depth])

            phone = df.loc[idx, 'phoneme']
            left = df.loc[idx, 'left']
            right = df.loc[idx, 'right']
            depth += 1


preb_df.to_csv('preb.csv', sep=',', encoding='utf-8', index=False)
del preb_df


postb_df = pd.DataFrame() # output dataframe

# get post-boundary phones
for idx in range(len(df)):
    print('on line #', idx, "/", lines)
    sys.stdout.flush()

    phone = df.loc[idx, 'phoneme']
    right = df.loc[idx, 'right']
    depth = 1


    if phone == silence:
        # shift right up to 'SIL' or 'Start'
        while (right == silence) and (right != 'End') and (idx+depth < lines):

            if right[0:2] in vowels:
                df.loc[idx+depth, 'context'] = 'Post'
                df.loc[idx+depth, 'depth'] = depth
                df.loc[idx+depth, 'sil_dur'] = df.loc[idx, 'duration']
                postb_df = postb_df.append(df.iloc[idx+depth])

            phone = df.loc[idx, 'phoneme']
            left = df.loc[idx, 'left']
            right = df.loc[idx, 'right']
            depth += 1


postb_df.to_csv('postb.csv', sep=',', encoding='utf-8', index=False)
