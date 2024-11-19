#!/bin/bash


GPUS_PER_NODE=4 # <- Specify the number of GPUs per machine here

## Master node setup
MAIN_HOST=`hostname -s`
export MASTER_ADDR=$MAIN_HOST

# Get a free port using python
export MASTER_PORT=$(python - <<EOF
import socket
sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
sock.bind(('', 0))  # OS will allocate a free port
free_port = sock.getsockname()[1]
sock.close()
print(free_port)
EOF
)

export NNODES=1
NODE_RANK=0
WORLD_SIZE=$(($GPUS_PER_NODE*$NNODES)) # M nodes x N GPUs

echo "nnodes: ${NNODES}"

export NCCL_IB_DISABLE=1
export OMP_NUM_THREADS=1

export NCCL_DEBUG=INFO

dataroot="dataset/train_npz/All_npy"
pretrained_checkpoint="work_dir/LiteMedSAM/lite_medsam.pth"

python train_multi_gpus_KT2.py \
    -i ${dataroot} \
    -task_name LiteMedSAM_light_Total \
    -pretrained_checkpoint ${pretrained_checkpoint} \
    -work_dir ./work_dir_lite_medsam \
    -batch_size 48 \
    -num_workers 32 \
    -lr 0.0001 \
    --data_aug \
    -world_size ${WORLD_SIZE} \
    -node_rank ${NODE_RANK} \
    -init_method tcp://${MASTER_ADDR}:${MASTER_PORT}

echo "END TIME: $(date)"
