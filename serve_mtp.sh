#!/bin/bash

echo "🔍 Select a model to serve:"
echo ""

models=($(find ./ -name \*.gguf 2>/dev/null))

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

extra_args=""
if [[ "$model_name" == *qwen3-coder-next* ]]; then
    extra_args="--temp 1.0 --top-p 0.95 --min-p 0.01 --top-k 40"
elif [[ "$model_name" == *qwen3.6-35b-a3b* ]]; then
    extra_args="--temp 1.0 --top-p 0.95 --top-k 20 --min-p 0.00"
elif [[ "$model_name" == *qwen3.6-27b* ]]; then
    extra_args="--temp 0.7 --top-p 0.8 --top-k 20 --presence-penalty 1.5 --min-p 0.00"
fi

# --cache_reuse 256 \
llama-server -m "$selected_model" \
 -c 262144 -ngl 999 -fa on \
 --spec-type draft-mtp --spec-draft-n-max 3 -n 3 -np 1 \
 --cache-type-k q8_0 --cache-type-v q8_0 \
 --no-mmap --metrics --host 0.0.0.0 \
 --chat-template-kwargs '{"preserve_thinking":true}' \
 --cache_reuse 256 \
 --reasoning-preserve \
 -t 30 \
 $extra_args

