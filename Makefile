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

# Script for deployment on Sepolia/Mumbai Testnet
deploySepolia:
	forge script DeployScript --rpc-url ${RPC_SEPOLIA} --private-key ${PRIVATE_KEY} --broadcast
deployMumbai:
	forge script DeployScript --rpc-url ${RPC_MUMBAI} --private-key ${PRIVATE_KEY} --broadcast