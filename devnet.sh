#!/bin/bash
_interupt() {
    echo "Shutdown $child_proc"
    kill -TERM $child_proc
    exit
}

trap _interupt INT TERM

touch .pwd
export $(cat .env | xargs)

WORK_DIR=$PWD
PROJECT_DIR="${HOME}/go/src/github.com/ethereum/go-ethereum"
cd $PROJECT_DIR && make tomo
cd $WORK_DIR

if [ ! -d ./nodes/1/tomo/chaindata ]
then
  wallet1=$(${PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/1 <(echo ${PRIVATE_KEY_1}) | awk -v FS="({|})" '{print $2}')
  ${PROJECT_DIR}/build/bin/tomo --datadir ./nodes/1 init ./genesis/devnet.json
else
  wallet1=$(${PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/1 | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

VERBOSITY=3
GASPRICE="1"
NODE_NAME="sonnst-devnet"

echo Starting the nodes ...
${PROJECT_DIR}/build/bin/tomo --unlock "${wallet1}" --bootnodes enode://f3d3d5d6cd0fdde8996722ff5b5a92f331029b2dcbdb9748f50db1421851a939eb660bf81a7ec7f359454aa0fd65fe4c03ae5c6bb2382b34dfaaca7eb6ecaf4e@52.77.194.164:30301,enode://34b923ddfcba1bfafdd1ac7a030436f9fbdc565919189f5e62c8cadd798c239b5807a26ab7f6b96a44200eb0399d1ebc2d9c1be94d2a774c8cc7660ff4c10367@13.228.93.232:30301,enode://e2604862d18049e025f294d63d537f9f54309ff09e45ed69ff4f18c984831f5ef45370053355301e3a4da95aba2698c6116f4d2a347e5a5e0a3152ac0ae0f574@18.136.42.72:30301 --syncmode "full" --ethstats "${NODE_NAME}:torn-fcc-caper-drool-jelly-zip-din-fraud-rater-darn@stats.devnet.tomochain.com:443" --verbosity "${VERBOSITY}" --datadir ./nodes/1 --identity "${NODE_NAME}" --password ./.pwd --networkid 89 --port 30303 --rpc --rpccorsdomain '*' --rpcaddr 0.0.0.0 --rpcport 8545 --rpcvhosts '*' --ws --wsaddr 0.0.0.0 --wsport 8546 --wsorigins '*' --mine --gasprice "${GASPRICE}" --targetgaslimit 420000000
child_proc=$!
tail -f ./genesis/devnet.json
