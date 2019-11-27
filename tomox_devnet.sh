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
TOMOCHAIN_PROJECT_DIR="${HOME}/go/src/github.com/ethereum/go-ethereum"
cd $TOMOCHAIN_PROJECT_DIR && make all
cd $WORK_DIR

if [ ! -d ./nodes/1/tomo/chaindata ]
then
  wallet1=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/1 <(echo ${PRIVATE_KEY_1}) | awk -v FS="({|})" '{print $2}')
  ${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo --datadir ./nodes/1 init ./genesis/genesis.json
else
  wallet1=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/1 | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

VERBOSITY=4

GASPRICE="250000000"

echo Starting netstats ...
if [ "$(docker ps -aq -f name=netstats)" ]; then
    if [ ! "$(docker ps -aq -f 'status=running' -f name=netstats)" ]; then
        docker start netstats
    fi
else
    docker run -d --env WS_SECRET=test2test --name netstats -p 3004:3000 tomochain/netstats:latest
fi

${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo \
    --bootnodes "enode://7d8ffe6d28f738d8b7c32f11fb6daa6204abae990a842025b0a969aabdda702aca95a821746332c2e618a92736538761b1660aa9defb099bc46b16db28992bc9@127.0.0.1:30301" \
    --syncmode "full" --datadir ./nodes/4 --networkid 99 --port 30306 \
    --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8549 --rpcvhosts "*" \
    --rpcapi "personal,db,eth,net,web3,txpool,miner,tomoX" \
    --tomox --tomox.datadir "$WORK_DIR/nodes/4/tomox" --tomox.dbengine "mongodb" \
    --unlock "${wallet4}" --password ./.pwd --mine --gasprice "${GASPRICE}" \
    --ethstats "tomox-fullnode:test2test@localhost:3004" \
    --targetgaslimit "420000000" --verbosity ${VERBOSITY}

