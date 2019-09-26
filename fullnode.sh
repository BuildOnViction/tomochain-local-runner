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

if [ ! -d ./nodes/5/tomo/chaindata ]
then
  wallet5=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/5 <(echo ${PRIVATE_KEY_1}) | awk -v FS="({|})" '{print $2}')
  wallet6=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/6 <(echo ${PRIVATE_KEY_2}) | awk -v FS="({|})" '{print $2}')
  wallet7=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/7 <(echo ${PRIVATE_KEY_3}) | awk -v FS="({|})" '{print $2}')
  ${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo --datadir ./nodes/5 init ./genesis/genesis.json
  ${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo --datadir ./nodes/6 init ./genesis/genesis.json
  ${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo --datadir ./nodes/7 init ./genesis/genesis.json
else
  wallet5=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/5 | head -n 1 | awk -v FS="({|})" '{print $2}')
  wallet6=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/6 | head -n 1 | awk -v FS="({|})" '{print $2}')
  wallet7=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/7 | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

VERBOSITY=3

GASPRICE="250000000"

echo Starting the nodes ...
${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo \
    --bootnodes "enode://7d8ffe6d28f738d8b7c32f11fb6daa6204abae990a842025b0a969aabdda702aca95a821746332c2e618a92736538761b1660aa9defb099bc46b16db28992bc9@127.0.0.1:30301" --syncmode "full" \
    --datadir ./nodes/5 --networkid 89 --port 30307 \
    --tomox --tomox.datadir "$WORK_DIR/nodes/5/tomox" --tomox.dbengine "leveldb" \
	--ethstats "fullnode5:test2test@localhost:3004" \
    --password ./.pwd --mine --gasprice "${GASPRICE}" --targetgaslimit "420000000" --verbosity ${VERBOSITY}
