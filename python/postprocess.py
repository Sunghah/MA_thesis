import pandas as pd
import numpy as np


data = '/home/sunghah/thesis/extract.csv'

out_df = pd.DataFrame() # output dataframe

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
lines = len(data)

silence = 'SIL' # silence phone
vowels = ['AA', 'AE', 'AH', 'AO', 'AW', 'AY', 'EH', 'ER',
          'EY', 'IH', 'IY', 'OW', 'OY', 'UH', 'UW', 'W', 'Y'] # all vowels


for idx in range(len(df)):
    print('on line #', idx, "/", lines)

    phone = df.loc[idx, 'phoneme']

    if phone == silence:

        depth = 1

        while (df.loc[idx, 'left'] != 'Start') and \
              (df.loc[idx, 'left'] != silence and (idx-depth > -1):

            left = df.loc[idx-depth, 'phoneme'] # pre-boundary phone

            # first two symbols, excluding lexical stress markers and B/I/E tags
            if left[0:2] in vowels:
                df.loc[idx-depth, 'context'] = 'Pre'
                df.loc[idx-depth, 'depth'] = depth
                df.loc[idx-depth, 'sil_dur'] = df.loc[idx, 'duration']
                out_df = out_df.append(df.iloc[idx-depth])

            depth += 1


        depth = 1

        while (df.loc[idx, 'right'] != 'End') and \
              (df.loc[idx, 'right'] != silence) and (idx+depth < lines):

            right = df.loc[idx+depth, 'phoneme'] # post-boundary phone

            # first two symbols, excluding lexical stress markers and B/I/E tags
            if right[0:2] in vowels:
                df.loc[idx+depth, 'context'] = 'Post'
                df.loc[idx+depth, 'depth'] = depth
                df.loc[idx+depth, 'sil_dur'] = df.loc[idx, 'duration']

                out_df = out_df.append(df.iloc[idx+depth])
                depth += 1


out_df.to_csv('result_proc.csv', sep=',', encoding='utf-8', index=False)
