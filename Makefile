-include .env

all: remove install

# Remove modules
remove :; rm -rf .gitmodules && rm -rf lib && touch .gitmodules

# Install modules
install :;
	forge install dapphub/ds-test --no-commit
	forge install Openzeppelin/openzeppelin-contracts --no-commit
	forge install smartcontractkit/chainlink --no-commit

deploy:
	forge create --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY} src/LuckySix.sol:LuckySix --constructor-args ${VRF_SUBSCRIPTION_ID} ${VRF_COORDINATOR}

test1:
	cast send ${LUCKY_SIX_PUBLIC_KEY} "requestRandomWords()" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}

test2:
	cast call ${LUCKY_SIX_PUBLIC_KEY} "randomNumber2()(uint256)" --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}