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
LOCAL_PRIVATE_KEY_USER := "0x2a871d0798f97d79848a013d4936a73bf4cc922c825d33c1cf7073dff6d409c6"

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
		cast send $(LOCAL_GAME_ADDRESS) "playTicket(uint8[6])" $(combination) --rpc-url $(LOCAL_RPC) --private-key $(LOCAL_PRIVATE_KEY_USER) --value 0.12ether; \
	else \
		echo "Correct input: make playTicket network=<network> combination=<[]>"; \
		echo "Networks available: sepolia, mumbai, local."; \
	fi

# Script for executing the keeper locally
checkUpkeep:
	cast send $(LOCAL_KEEPER_ADDRESS) "checkUpkeep()" --rpc-url $(LOCAL_RPC) --private-key $(LOCAL_PRIVATE_KEY_USER)

# Script for initializing the lottery to facilitate front-end testing using Anvil as a local testnet. 
initializeLocalLotteryForTesting:
	anvil --chain-id 1337 & \
	make deploy network=local; \
	make playTicket network=local combination=[1,2,3,4,5,6]; \
	make playTicket network=local combination=[10,15,20,25,30,35]; \
	make playTicket network=local combination=[13,23,37,40,41,42]; \
	make playTicket network=local combination=[1,22,33,14,15,36]; \
	make playTicket network=local combination=[1,6,18,28,30,31]; \
	make playTicket network=local combination=[12,23,34,45,15,16]; \
	make playTicket network=local combination=[7,8,19,21,37,40]; \
	make playTicket network=local combination=[6,9,16,23,34,38]; \
	make playTicket network=local combination=[10,11,12,14,15,16]; \
	make playTicket network=local combination=[13,15,37,44,24,25]; \
	make playTicket network=local combination=[13,17,29,31,32,33]; \
	make checkUpkeep; \
	make checkUpkeep; \
	make checkUpkeep