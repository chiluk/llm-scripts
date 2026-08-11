#!/bin/bash

echo "🔍 Select a model to serve:"
echo ""

models=($(ls -1 ~/models/*.gguf 2>/dev/null))

if [ ${#models[@]} -eq 0 ]; then
    echo "❌ No GGUF models found in ~/models"
    exit 1
fi

for i in "${!models[@]}"; do
    basename_model=$(basename "${models[$i]}")
    echo "  $((i+1)). $basename_model"
done

echo ""
read -p "Enter model number (1-${#models[@]}): " choice

if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt ${#models[@]} ]; then
    echo "❌ Invalid selection"
    exit 1
fi

selected_model="${models[$((choice-1))]}"

echo ""
echo "🚀 Starting server with: $(basename "$selected_model")"
echo ""

model_name=$(basename "$selected_model" | tr '[:upper:]' '[:lower:]')


CONTEXT=262144
extra_args=""
if [[ "$selected_model" == *qwen3-coder-next* ]]; then
    extra_args="--temp 1.0 --top-p 0.95 --min-p 0.01"
elif [[ "$selected_model" == *qwen3.6-35b-a3b* ]]; then
    extra_args="--temp 1.0 --top-p 0.95 --min-p 0.00"
elif [[ "$selected_model" == *qwen3.6-27b* ]]; then
    extra_args="--temp 0.7 --top-p 0.8 --presence-penalty 1.5 --min-p 0.00"
elif [[ "$selected_model" == *gemma-4-26B* ]]; then
    extra_args="--temp 1.0 --top-p 0.95"
    mtp_models="--mmproj ./mmproj-BF16.gguf --model-draft ./mtp-gemma-4-26B-A4B-it-Q8_0.gguf"
fi


# decided to turn off context quantization --cache-type-k q8_0 --cache-type-v q8_0
export ROCBLAS_USE_HIPBLASLT=1
llama-server -m "$selected_model" ${mtp_models}\
 -np 1 --ctx-size $CONTEXT -ngl 999 -fa on -lv 4\
 --no-mmap --metrics --host 0.0.0.0 \
 --spec-type draft-mtp --spec-draft-n-max 3 \
 --reasoning on --reasoning-preserve \
 --cache_reuse 256 \
 --log-colors on \
 -t 16 \
 $extra_args
 
