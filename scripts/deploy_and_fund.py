from brownie import LuckySix, config, network
from scripts.helpful_scripts import get_contract, fund_with_link

# 'TransactionReceipt' object has no attribute 'address' kad se prvi put pokrece na nekoj mrezi?
# ne radi ganache-local


def deploy_and_fund(account):
    luckysix = LuckySix.deploy(
        get_contract("vrf_coordinator").address,
        get_contract("link_token").address,
        config["networks"][network.show_active()]["keyhash"],
        config["networks"][network.show_active()]["fee"],
        {"from": account},
    )
    tx = fund_with_link(luckysix.address)
    tx.wait(1)
    luckysix.getRandomNumber({"from": account})
    return luckysix


def main():
    deploy_and_fund()
