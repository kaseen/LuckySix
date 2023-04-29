-include .env

all: remove install

# Remove modules
remove :; rm -rf .gitmodules && rm -rf lib && touch .gitmodules

# Install modules
install :;
	forge install dapphub/ds-test --no-commit
	forge install Openzeppelin/openzeppelin-contracts --no-commit
	forge install smartcontractkit/chainlink --no-commit

# Deploy to Sepolia Testnet
deploy:
	forge create --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} src/LuckySix.sol:LuckySix --constructor-args ${VRF_SUBSCRIPTION_ID} ${VRF_COORDINATOR} ${CHAINLINK_KEEPER}

# Test chainlink randomness
testRandomness: openLottery endLottery
openLottery:
	cast send ${LUCKY_SIX_PUBLIC_KEY} "startLottery()" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}
endLottery:
	cast send ${LUCKY_SIX_PUBLIC_KEY} "endLottery()" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}