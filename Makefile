all: remove install

# Remove modules
remove :; rm -rf .gitmodules && rm -rf lib && touch .gitmodules

# Install modules
install :;
	forge install dapphub/ds-test --no-commit
	forge install Openzeppelin/openzeppelin-contracts --no-commit
	forge install smartcontractkit/chainlink --no-commit