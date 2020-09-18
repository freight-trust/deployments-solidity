#!/bin/bash

# enforce pragma 0.4.24 (replaces 0.4.19 with 0.4.24)

# find $PWD -type f -exec sed -i 's/0\.4\.19/0\.4\.24/g' {} +
npm i -g solpp 
wget https://github.com/ethereum/solidity/releases/download/v0.4.24/solc-static-linux 
chmod +x solc-static-linux
./solc-static-linux --version
mkdir -p pipeline/compiler
mv solc-static-linux pipeline/
solpp -o $OUTPUT.sol $INTPUT.sol
mv $OUTPUT.sol pipeline/
cd pipeline/

# for production run  ` --optimize-runs 1458 `
./solc-static-linux --abi --bin --ast-compact-json --hashes --optimize -o $PWD/compiler-output Anchoring.sol
cp -rf compiler-output $HOME/$GITHUB_REPO/pipeline

