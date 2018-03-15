#!/bin/bash

# exit at any non-zero status
set -e

. ./cmd.sh
. ./path.sh

if [ ! -L ./utils ]; then
    rm -rf ./utils
    ln -sf $KALDI_ROOT/egs/wsj/s5/utils ./utils
fi

if [ ! -L ./steps ]; then
    rm -rf ./steps
    ln -sf $KALDI_ROOT/egs/wsj/s5/steps ./steps
fi

export PATH=${PATH}:/home/sunghahh/kaldi/tools/python
export IRSTLM=/home/sunghahh/kaldi/tools/irstlm
export PATH=${PATH}:${IRSTLM}/bin
export LIBLBFGS=/home/sunghahh/kaldi/tools/liblbfgs-1.10
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${LIBLBFGS}/lib/.libs

# data directory
data=/data

# mfcc directory
mfcc_dir=mfcc

# urls for resource downloads
data_url=www.openslr.org/resources/12
lm_url=www.openslr.org/resources/11

# num_jobs for training and aligning
train_jobs=16
decode_jobs=16
align_jobs=16

# download the data
local/download_and_untar.sh \
  $data $data_url train-clean-100

# download the LM resources
local/download_lm.sh \
  $lm_url data/local/lm

# format the data as Kaldi data directories
local/data_prep.sh \
  $data/LibriSpeech/train-clean-100 data/train_clean_100

cut -d' ' -f2- data/train_clean_100/text > data/train_clean_100/textraw

sed 's/\ /\n/g' data/train_clean_100/textraw | sort | uniq > data/local/lm/vocab.txt


# prepare the dictionary using CMUdict and Sequitur
prep_dict.sh \
  --nj "$train_jobs" --cmd "$train_cmd" \
  data/local/lm data/local/lm data/local/dict_nosp

utils/prepare_lang.sh \
  data/local/dict_nosp "<UNK>" data/local/lang_nosp_tmp data/lang_nosp

# Create lm.arpa using ngram-count in SRILM
ngram-count -order 3 -text data/train_clean_100/textraw -lm data/local/lm/lm_tg.arpa.gz
ngram-count -order 4 -text data/train_clean_100/textraw -lm data/local/lm/lm_fg.arpa.gz

# create G.fst transducers for 3-gram & 4-gram LMs
for lm_suffix in tg fg; do
  lang_dir=data/lang_nosp_"$lm_suffix"
  mkdir -p "$lang_dir"
  cp -r data/lang_nosp/* "$lang_dir"
  gunzip -c data/local/lm/lm_"$lm_suffix".arpa.gz | \
  arpa2fst \
    --disambig-symbol=#0 \
    --read-symbol-table="$lang_dir"/words.txt - "$lang_dir"/G.fst
  utils/validate_lang.pl --skip-determinization-check "$lang_dir" || exit 1
done

# create ConstArpaLM format language models for 3-gram & 4-gram LMs
utils/build_const_arpa_lm.sh \
  data/local/lm/lm_tg.arpa.gz data/lang_nosp data/lang_nosp_tg

utils/build_const_arpa_lm.sh \
  data/local/lm/lm_fg.arpa.gz data/lang_nosp data/lang_nosp_fg

# extract MFCC features from  data
steps/make_mfcc.sh \
  --nj "$train_jobs" --cmd "$train_cmd" \
  data/train_clean_100 exp/make_mfcc/train_clean_100 $mfcc_dir

steps/compute_cmvn_stats.sh \
  data/train_clean_100 exp/make_mfcc/train_clean_100 $mfcc_dir

# train a monophone system with train-clean-100 (29k utterances, 100 hours)
steps/train_mono.sh \
  --boost-silence 1.25 --nj "$train_jobs" --cmd "$train_cmd" \
  data/train_clean_100 data/lang_nosp exp/mono

# decode using the monophone model ("nosp" = no silence prior)
(
  utils/mkgraph.sh \
    data/lang_nosp_tg exp/mono exp/mono/graph_nosp

  steps/decode.sh \
    --nj "$decode_jobs" --cmd "$decode_cmd" \
    exp/mono/graph_nosp data/train_clean_100 exp/mono/decode_nosp
)&

steps/align_si.sh \
  --boost-silence 1.25 --nj "$align_jobs" --cmd "$train_cmd" \
  data/train_clean_100 data/lang_nosp exp/mono exp/mono_ali


# train tri1 model (delta + delta-delta triphone system)
steps/train_deltas.sh \
  --boost-silence 1.25 --cmd "$train_cmd" \
  4200 40000 data/train_clean_100 data/lang_nosp exp/mono_ali exp/tri1

# decode using the tri1 model & align
(
  utils/mkgraph.sh \
    data/lang_nosp_tg exp/tri1 exp/tri1/graph_nosp

  steps/decode.sh \
    --nj "$decode_jobs" --cmd "$decode_cmd" \
    exp/tri1/graph_nosp data/train_clean_100 exp/tri1/decode_nosp_tg

  steps/lmrescore.sh \
    --cmd "$decode_cmd" \
    data/lang_nosp_{tg,fg} data/train_clean_100 exp/tri1/decode_nosp_{tg,fg}

  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" \
    data/lang_nosp_{tg,fg} data/train_clean_100 exp/tri1/decode_nosp_{tg,fg}
)&

steps/align_si.sh \
  --nj "$align_jobs" --cmd "$train_cmd" \
  data/train_clean_100 data/lang_nosp exp/tri1 exp/tri1_ali


# train tri2 model (LDA+MLLT)
steps/train_lda_mllt.sh \
  --cmd "$train_cmd" \
  --splice-opts "--left-context=3 --right-context=3" \
  4200 40000 data/train_clean_100 data/lang_nosp exp/tri1_ali exp/tri2

# decode using the tri2 model & align
(
  utils/mkgraph.sh \
    data/lang_nosp_tg exp/tri2 exp/tri2/graph_nosp

  steps/decode.sh \
    --nj "$decode_jobs" --cmd "$decode_cmd" \
    exp/tri2/graph_nosp data/train_clean_100 exp/tri2/decode_nosp_tg

  steps/lmrescore.sh \
    --cmd "$decode_cmd" \
    data/lang_nosp_{tg,fg} data/train_clean_100 exp/tri2/decode_nosp_{tg,fg}

  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" \
    data/lang_nosp_{tg,fg} data/train_clean_100 exp/tri2/decode_nosp_{tg,fg}
)&

steps/align_si.sh \
  --use-graphs true \
  --nj "$align_jobs" --cmd "$train_cmd" \
  data/train_clean_100 data/lang_nosp exp/tri2 exp/tri2_ali


# train tri3 (nosp) model (LDA+MLLT+SAT)
steps/train_sat.sh \
  --cmd "$train_cmd" \
  4200 40000 data/train_clean_100 data/lang_nosp exp/tri2_ali exp/tri3A

# decode using the tri3 model & align
(
  utils/mkgraph.sh \
    data/lang_nosp_tg exp/tri3A exp/tri3A/graph_nosp

  steps/decode_fmllr.sh \
    --nj "$decode_jobs" --cmd "$decode_cmd" \
    exp/tri3A/graph_nosp data/train_clean_100 exp/tri3A/decode_nosp_tg

  steps/lmrescore.sh \
    --cmd "$decode_cmd" \
    data/lang_nosp_{tg,fg} data/train_clean_100 exp/tri3A/decode_nosp_{tg,fg}

  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" \
    data/lang_nosp_{tg,fg} data/train_clean_100 exp/tri3A/decode_nosp_{tg,fg}
)&

steps/align_fmllr.sh \
  --nj "$align_jobs" --cmd "$train_cmd" \
  data/train_clean_100 data/lang_nosp exp/tri3A exp/tri3A_ali


# train another tri3 model (LDA+MLLT+SAT)
steps/train_sat.sh \
  --cmd "$train_cmd" \
  4200 40000 data/train_clean_100 data/lang_nosp exp/tri2_ali exp/tri3B

# compute pronunciation and silence probabilities & re-create the lang dir
steps/get_prons.sh \
  --cmd "$train_cmd" \
  data/train_clean_100 data/lang_nosp exp/tri3B

utils/dict_dir_add_pronprobs.sh \
  --max-normalize true \
  data/local/dict_nosp \
  exp/tri3B/pron_counts_nowb.txt exp/tri3B/sil_counts_nowb.txt \
  exp/tri3B/pron_bigram_counts_nowb.txt data/local/dict

utils/prepare_lang.sh \
  data/local/dict "<UNK>" data/local/lang_tmp data/lang

for lm_suffix in tg fg; do
  lang_dir=data/lang_"$lm_suffix"
  mkdir -p "$lang_dir"
  cp -r data/lang/* "$lang_dir"
  gunzip -c data/local/lm/lm_"$lm_suffix".arpa.gz | \
  arpa2fst \
    --disambig-symbol=#0 \
    --read-symbol-table="$lang_dir"/words.txt - "$lang_dir"/G.fst
  utils/validate_lang.pl --skip-determinization-check "$lang_dir" || exit 1
done


# create ConstArpaLM format language models for 3-gram & 4-gram LMs
utils/build_const_arpa_lm.sh \
  data/local/lm/lm_tg.arpa.gz data/lang data/lang_tg

utils/build_const_arpa_lm.sh \
  data/local/lm/lm_fg.arpa.gz data/lang data/lang_fg

# decode using the tri3 model with pronunciation and silence probs & align
(
  utils/mkgraph.sh \
    data/lang_tg exp/tri3B exp/tri3B/graph

  steps/decode_fmllr.sh \
    --nj "$decode_jobs" --cmd "$decode_cmd" \
    exp/tri3B/graph data/train_clean_100 exp/tri3B/decode_tg

  steps/lmrescore.sh \
    --cmd "$decode_cmd" \
    data/lang_{tg,fg} data/train_clean_100 exp/tri3B/decode_{tg,fg}

  steps/lmrescore_const_arpa.sh \
    --cmd "$decode_cmd" \
    data/lang_{tg,fg} data/train_clean_100 exp/tri3B/decode_{tg,fg}
)&

steps/align_fmllr.sh \
  --nj "$align_jobs" --cmd "$train_cmd" \
  data/train_clean_100 data/lang exp/tri3B exp/tri3B_ali


# train and test NN model(s) on the 100 hour subset
train_stage=-10
use_gpu=true

if $use_gpu; then
  if ! cuda-compiled; then
    cat <<EOF && exit 1
This script is intended to be used with GPUs but you have not compiled Kaldi with CUDA
If you want to use GPUs (and have them), go to src/, and configure and make on a machine
where "nvcc" is installed.
EOF
  fi
  parallel_opts="--gpu 1"
  num_threads=1
  minibatch_size=512
  nnet_dir=exp/nnet5a_gpu
else
  num_threads="$train_jobs"
  parallel_opts="--num-threads $num_threads"
  minibatch_size=128
  nnet_dir=exp/nnet5a
fi

if [ ! -f $nnet_dir/final.mdl ]; then
  steps/nnet2/train_pnorm_fast.sh \
    --stage $train_stage \
    --samples-per-iter 400000 \
    --parallel-opts "$parallel_opts" \
    --num-threads "$num_threads" \
    --minibatch-size "$minibatch_size" \
    --num-jobs-nnet 4 --mix-up 8000 \
    --initial-learning-rate 0.01 --final-learning-rate 0.001 \
    --num-hidden-layers 4 \
    --pnorm-input-dim 2000 --pnorm-output-dim 400 \
    --cmd "$decode_cmd" \
    data/train_clean_100 data/lang exp/tri3B_ali $nnet_dir
fi


steps/nnet2/decode.sh \
  --nj "decode_jobs" --cmd "$decode_cmd" \
  --transform-dir exp/tri3/decode \
  exp/tri3/graph data/train_clean_100 $nnet_dir/decode

steps/lmrescore.sh \
  --cmd "$decode_cmd" \
  data/lang data/train_clean_100 $nnet_dir/decode

steps/lmresecore_const_arpa.sh \
  --cmd "$decode_cmd" \
  data/lang data/train_clean_100 $nnet_dir/decode
