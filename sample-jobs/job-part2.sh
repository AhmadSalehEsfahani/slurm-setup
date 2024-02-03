#!/bin/bash
#SBATCH --job-name=batch_part2
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --partition=part2

# Your script goes here
sleep 60
echo "hello"
