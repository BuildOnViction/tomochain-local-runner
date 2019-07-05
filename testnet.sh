#!/bin/bash

touch .pwd
export $(cat .env | xargs)

WORK_DIR=$PWD
PROJECT_DIR="${HOME}/go/src/github.com/ethereum/go-ethereum"
cd $PROJECT_DIR && make tomo
cd $WORK_DIR

if [ ! -d ./nodes/1/tomo/chaindata ]
then
  wallet1=$(${PROJECT_DIR}/build/bin/tomo account import --password .pwd --datadir ./nodes/1 <(echo ${PRIVATE_KEY_1}) | awk -v FS="({|})" '{print $2}')
  ${PROJECT_DIR}/build/bin/tomo --datadir ./nodes/1 init ./genesis/testnet.json
else
  wallet1=$(${PROJECT_DIR}/build/bin/tomo account list --datadir ./nodes/1 | head -n 1 | awk -v FS="({|})" '{print $2}')
fi

VERBOSITY=5
GASPRICE="250000000"
NODE_NAME="sonnst0915"

echo Starting the nodes ...
${PROJECT_DIR}/build/bin/tomo --unlock "${wallet1}" \
    --bootnodes enode://4d3c2cc0ce7135c1778c6f1cfda623ab44b4b6db55289543d48ecfde7d7111fd420c42174a9f2fea511a04cf6eac4ec69b4456bfaaae0e5bd236107d3172b013@52.221.28.223:30301,enode://298780104303fcdb37a84c5702ebd9ec660971629f68a933fd91f7350c54eea0e294b0857f1fd2e8dba2869fcc36b83e6de553c386cf4ff26f19672955d9f312@13.251.101.216:30301,enode://46dba3a8721c589bede3c134d755eb1a38ae7c5a4c69249b8317c55adc8d46a369f98b06514ecec4b4ff150712085176818d18f59a9e6311a52dbe68cff5b2ae@13.250.94.232:30301 --syncmode "full" --ethstats "${NODE_NAME}:anna-coal-flee-carrie-zip-hhhh-tarry-laue-felon-rhine@stats.testnet.tomochain.com:443" \
    --verbosity "${VERBOSITY}" --datadir ./nodes/1 \
    --identity "${NODE_NAME}" --password ./.pwd --networkid 89 --port 30303 --rpc --rpccorsdomain '*' \
    --rpcaddr 0.0.0.0 --rpcport 8545 --rpcvhosts '*' --ws --wsaddr 0.0.0.0 --wsport 8546 --wsorigins '*' --mine \
    --gasprice "${GASPRICE}" --targetgaslimit 420000000 \
    --announce-txs \
    --tomo-testnet
