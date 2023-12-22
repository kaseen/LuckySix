-include .env

all: remove install

# Remove modules
remove :; rm -rf .gitmodules && rm -rf lib && touch .gitmodules

# Install modules
install :;
	forge install dapphub/ds-test --no-commit
	forge install smartcontractkit/chainlink --no-commit
	forge install Openzeppelin/openzeppelin-contracts --no-commit
	forge install Openzeppelin/openzeppelin-contracts-upgradeable --no-commit

# These addresses remain consistent when the deployment script is executed on a fresh localnet.
LOCAL_KEEPER_ADDRESS := "0xA15BB66138824a1c7167f5E85b957d04Dd34E468"
LOCAL_GAME_ADDRESS := "0x8ce361602B935680E8DeC218b820ff5056BeB7af"
LOCAL_RPC := "http://127.0.0.1:8545"
LOCAL_PRIVATE_KEY := "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d"

# Script for generating the ABI of the contract and saving it as `abi.json` in the root directory.
ABI_FILE_NAME := "abi.json"

getABI:
# 	Check if `ABI_FILE_NAME` exists
	@if [ -a $(ABI_FILE_NAME) ]; then \
		rm $(ABI_FILE_NAME); \
	fi
#	Create `ABI_FILE_NAME` with that abi
	@forge build --silent && jq '.abi' ./out/LuckySix.sol/LuckySix.json >> abi.json


# Script to deploy contracts on a given network
deploy:
	@if [ "$(network)" = "sepolia" ]; then \
		forge script DeployScript --rpc-url ${RPC_SEPOLIA} --private-key ${PRIVATE_KEY} --broadcast; \
	elif [ "$(network)" = "mumbai" ]; then \
		forge script DeployScript --rpc-url ${RPC_MUMBAI} --private-key ${PRIVATE_KEY} --broadcast; \
	elif [ "$(network)" = "local" ]; then \
		forge script LocalDeployGameScript --rpc-url "http://127.0.0.1:8545" --broadcast; \
	else \
		echo "Correct input: make deploy network=<network>"; \
		echo "Networks available: sepolia, mumbai, local."; \
	fi

# Script to play ticket for a given network and combination
playTicket:
	@if [ "$(network)" = "sepolia" ]; then \
		cast send ${LUCKY_SIX_SEPOLIA} "playTicket(uint8[6])" $(combination) --rpc-url ${RPC_SEPOLIA} --private-key ${PRIVATE_KEY} --value 0.02ether; \
	elif [ "$(network)" = "mumbai" ]; then \
		cast send ${LUCKY_SIX_MUMBAI} "playTicket(uint8[6])" $(combination) --rpc-url ${RPC_MUMBAI} --private-key ${PRIVATE_KEY} --value 0.02ether; \
	elif [ "$(network)" = "local" ]; then \
		cast send $(LOCAL_GAME_ADDRESS) "playTicket(uint8[6])" $(combination) --rpc-url $(LOCAL_RPC) --private-key $(LOCAL_PRIVATE_KEY) --value 0.02ether; \
	else \
		echo "Correct input: make playTicket network=<network> combination=<[]>"; \
		echo "Networks available: sepolia, mumbai, local."; \
	fi

# Script for executing the keeper locally
checkUpkeep:
	cast send $(LOCAL_KEEPER_ADDRESS) "checkUpkeep()" --rpc-url $(LOCAL_RPC) --private-key $(LOCAL_PRIVATE_KEY)