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
	else \
		echo "Correct input: make deploy network=<network>"; \
		echo "Networks available: sepolia, mumbai."; \
	fi

# Script to play ticket for a given network and combination
playTicket:
	@if [ "$(network)" = "sepolia" ]; then \
		cast send ${LUCKY_SIX_SEPOLIA} "playTicket(uint8[6])" $(combination) --rpc-url ${RPC_SEPOLIA} --private-key ${PRIVATE_KEY} --value 0.02ether; \
	elif [ "$(network)" = "mumbai" ]; then \
		cast send ${LUCKY_SIX_MUMBAI} "playTicket(uint8[6])" $(combination) --rpc-url ${RPC_MUMBAI} --private-key ${PRIVATE_KEY} --value 0.02ether; \
	else \
		echo "Correct input: make playTicket network=<network> combination=<[]>"; \
		echo "Networks available: sepolia, mumbai."; \
	fi