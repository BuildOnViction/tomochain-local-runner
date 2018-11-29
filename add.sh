#!/bin/bash
export $(cat .env | xargs)

WORK_DIR=$PWD
PROJECT_DIR="${HOME}/go/src/github.com/ethereum/go-ethereum"
cd $PROJECT_DIR && make tomo
cd $WORK_DIR

if [ ! -d ./nodes/4/tomo/chaindata ]
then
  wallet4=$(${PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/4 <(echo ${PRIVATE_KEY_4}) | awk -v FS="({|})" '{print $2}')
  ${PROJECT_DIR}/build/bin/tomo --datadir ./nodes/4 init ./genesis/genesis.json
else
  wallet4=$(${PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/4 | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

VERBOSITY=4
GASPRICE="1"
echo $wallet4

echo Starting the nodes ...
${PROJECT_DIR}/build/bin/tomo --bootnodes "enode://7d8ffe6d28f738d8b7c32f11fb6daa6204abae990a842025b0a969aabdda702aca95a821746332c2e618a92736538761b1660aa9defb099bc46b16db28992bc9@159.65.2.149:30301" --syncmode 'full' --datadir ./nodes/4 --networkid 89 --port 30306 --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8548 --rpcvhosts "*" --unlock "${wallet4}" --password ./.pwd --mine --gasprice "${GASPRICE}" --targetgaslimit "420000000" --verbosity ${VERBOSITY} --ethstats "moon:test&test@159.65.2.149:3002"

#${PROJECT_DIR}/build/bin/tomo --datadir ./nodes/4 --syncmode 'full' --port 30311 --rpc --rpcaddr 'localhost' --rpccorsdomain "*" --rpcport 8501 --rpcapi 'personal,db,eth,net,web3,txpool,miner' --bootnodes 'enode://7d8ffe6d28f738d8b7c32f11fb6daa6204abae990a842025b0a969aabdda702aca95a821746332c2e618a92736538761b1660aa9defb099bc46b16db28992bc9@159.65.2.149:30301' --networkid 89 --gasprice 10 --unlock "${wallet4}" --password ./.pwd --mine --verbosity 4
