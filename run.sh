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
  wallet2=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/2 <(echo ${PRIVATE_KEY_2}) | awk -v FS="({|})" '{print $2}')
  wallet3=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/3 <(echo ${PRIVATE_KEY_3}) | awk -v FS="({|})" '{print $2}')
  ${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo --datadir ./nodes/1 init ./genesis/genesis.json
  ${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo --datadir ./nodes/2 init ./genesis/genesis.json
  ${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo --datadir ./nodes/3 init ./genesis/genesis.json
else
  wallet1=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/1 | head -n 1 | awk -v FS="({|})" '{print $2}')
  wallet2=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/2 | head -n 1 | awk -v FS="({|})" '{print $2}')
  wallet3=$(${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/3 | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

VERBOSITY=3
GASPRICE="2500"

echo Starting netstats ...
if [ "$(docker ps -q -f name=netstats)" ]; then
    if [ "$(docker ps -aq -f 'status=exited' -f name=netstats)" ]; then
        docker start netstats
    fi
else
    docker run -d --env WS_SECRET=test2test --name netstats -p 3004:3000 tomochain/netstats:latest
fi

echo Starting the bootnode ...
${TOMOCHAIN_PROJECT_DIR}/build/bin/bootnode -nodekey ./bootnode.key &
child_proc=$! 

echo Starting the nodes ...
${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo \
    --bootnodes "enode://7d8ffe6d28f738d8b7c32f11fb6daa6204abae990a842025b0a969aabdda702aca95a821746332c2e618a92736538761b1660aa9defb099bc46b16db28992bc9@127.0.0.1:30301" --syncmode "full" \
    --datadir ./nodes/1 --networkid 89 --port 30303 \
    --announce-txs \
    --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8545 --rpcvhosts "*" \
    --ws --wsaddr 0.0.0.0 --wsport 8546 --wsorigins "*" --unlock "${wallet1}" \
	--ethstats "sun:test2test@localhost:3004" \
    --password ./.pwd --mine --gasprice "${GASPRICE}" --targetgaslimit "420000000" --verbosity ${VERBOSITY} &
child_proc="$child_proc $!"

${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo \
    --bootnodes "enode://7d8ffe6d28f738d8b7c32f11fb6daa6204abae990a842025b0a969aabdda702aca95a821746332c2e618a92736538761b1660aa9defb099bc46b16db28992bc9@127.0.0.1:30301" --syncmode "full" \
    --datadir ./nodes/2 --networkid 89 --port 30304 \
    --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8547 --rpcvhosts "*" \
    --unlock "${wallet2}" --password ./.pwd --mine --gasprice "${GASPRICE}" --targetgaslimit "420000000" \
	--ethstats "moon:test2test@localhost:3004" \
    --verbosity ${VERBOSITY} &
child_proc="$child_proc $!"

${TOMOCHAIN_PROJECT_DIR}/build/bin/tomo \
    --bootnodes "enode://7d8ffe6d28f738d8b7c32f11fb6daa6204abae990a842025b0a969aabdda702aca95a821746332c2e618a92736538761b1660aa9defb099bc46b16db28992bc9@127.0.0.1:30301" \
    --syncmode "full" --datadir ./nodes/3 --networkid 89 --port 30305 \
    --rpc --rpccorsdomain "*" --rpcaddr 0.0.0.0 --rpcport 8548 --rpcvhosts "*" \
    --unlock "${wallet3}" --password ./.pwd --mine --gasprice "${GASPRICE}" \
	--ethstats "earth:test2test@localhost:3004" \
    --targetgaslimit "420000000" --verbosity ${VERBOSITY}
