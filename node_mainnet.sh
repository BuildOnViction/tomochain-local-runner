#!/bin/bash
touch .pwd
export $(cat .env | xargs)

WORK_DIR=$PWD
TOMOCHAIN_PROJECT_DIR="${HOME}/go/src/github.com/ethereum/go-ethereum"
cd $TOMOCHAIN_PROJECT_DIR && make all
cd $WORK_DIR

if [ ! -d ./nodes/1/tomo/chaindata ]
then
  wallet1=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/1 <(echo ${PRIVATE_KEY_1}) | awk -v FS="({|})" '{print $2}')
  ${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo --datadir ./nodes/1 init ./genesis/mainnet.json
else
  wallet1=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/1 | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

VERBOSITY=3
GASPRICE="250000000"

echo Starting netstats ...
if [ "$(docker ps -aq -f name=netstats)" ]; then
    if [ ! "$(docker ps -aq -f 'status=running' -f name=netstats)" ]; then
        docker start netstats
    fi
else
    docker run -d --env WS_SECRET=test2test --name netstats -p 3004:3000 tomochain/netstats:latest
fi

echo Starting the nodes ...
${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo \
    --bootnodes "enode://c8f2f0643527d4efffb8cb10ef9b6da4310c5ac9f2e988a7f85363e81d42f1793f64a9aa127dbaff56b1e8011f90fe9ff57fa02a36f73220da5ff81d8b8df351@104.248.98.60:30301" --syncmode "full" \
    --datadir ./nodes/1 --networkid 88 \
    --ethstats "TomoChain-Local:test2test@localhost:3004" \
    --unlock "${wallet1}" \
    --password ./.pwd --mine --gasprice "${GASPRICE}" --targetgaslimit "420000000" --verbosity ${VERBOSITY}
#    --datadir ./nodes/1 --networkid 88 --port 30303 \
#    --announce-txs \
#    --store-reward \
#    --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8545 --rpcvhosts "*" \
#    --ws --wsaddr 0.0.0.0 --wsport 8546 --wsorigins "*" --unlock "${wallet1}" \
