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

# Interact with contract deployed on live testnet
playTicket:
	cast send ${LUCKY_SIX_PUBLIC_KEY} "playTicket(uint256[6])" "[1,2,3,4,5,6]" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} --value 0.02ether
getPayoutForTicket:
	cast send ${LUCKY_SIX_PUBLIC_KEY} "getPayoutForTicket(uint256,uint256)" "5" "0" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}
getLotteryState:
	cast call ${LUCKY_SIX_PUBLIC_KEY} "lotteryState()(uint256)" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}
unpackResultForRound:
	cast call ${LUCKY_SIX_PUBLIC_KEY} "unpackResultForRound(uint256)(uint256[])" "5" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}
