#this script is to deploy an existing Cosmos-SDK app as a rollup on top of Celestia
##I. Install OKP4
cd $HOME
rm -rf okp4d
git clone https://github.com/okp4/okp4d.git
cd okp4d
git checkout v4.1.0

##II. Change OKP4 to roll up 
go mod edit -replace github.com/cosmos/cosmos-sdk=github.com/rollkit/cosmos-sdk@v0.46.7-rollkit-v0.7.3-no-fraud-proofs
go mod edit -replace github.com/tendermint/tendermint=github.com/celestiaorg/tendermint@v0.34.22-0.20221202214355-3605c597500d
go mod tidy
go mod download
make install

##III. Rollup Setting
###1. reset chain and create monikier
okp4d tendermint unsafe-reset-all
opk4d init luciolaKami --chain-id okp4-nemeton-2

###2. create 2 wallet keys wallet1 and wallet2
okp4d keys add wallet1 --keyring-backend test
okp4d keys add wallet2 --keyring-backend test

###3. change denom in genesis.json
sed -i.bak -e "s|\"stake\"|\"$DENOM\"|g" /root/.okp4d/config/genesis.json

###4. add wallet1 and wallet2 to genesis
okp4d add-genesis-account wallet1 90000000000000000000000000uknow --keyring-backend test
okp4d add-genesis-account wallet2 90000000000000000000000000uknow --keyring-backend test

okp4d gentx wallet1 90000000000000uknow --chain-id okp4-nemeton-2 --keyring-backend test

###5. Add transactions to genesis.json
okp4d collect-gentxs

##IV. Install celestia full/light/bridge storage node 
#please follow this link 
# https://medium.com/@chanhphat630/f183db6c4b53

##V. Starting rollup chain
###1. get your namespace following link below
##### https://go.dev/play/p/7ltvaj8lhRl
### example
NAMESPACE_ID=ede480b6acc7a1c7
###2. get DA block height 
DA_HEIGHT=$(curl https://rpc-1.celestia.nodes.guru/block | jq -r '.result.block.header.height')
echo $DA_HEIGHT
###3. starting rollup
okp4d --rollkit.aggregator true --rollkit.block_time 2.5s --rollkit.da_block_time 2.5s --rollkit.da_layer celestia --rollkit.da_config='{"base_url":"http://localhost:26659","timeout":60000000000,"fee":100,"gas_limit":100000}' --rollkit.namespace_id $NAMESPACE_ID  --rollkit.da_start_height $DA_HEIGHT --p2p.laddr "0.0.0.0:26656" --p2p.seed_mode --log_level debug
