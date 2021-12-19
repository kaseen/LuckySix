from brownie import Contract, LuckySix, network
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
from scripts.deploy_and_fund import deploy_and_fund
from tests.conftest import test_combination, test_price, get_lastest_contract
import pytest
import time

# Treba fix na startLottery i endLottery ValueError: Gas estimation failed: 'The execution failed due to an exception.'


def allUnique(list):
    return len(list) == len(set(list))


def test_randomness():
    # Arrange
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = deploy_and_fund(account)
    time.sleep(60)
    # Act
    tx = luckysix.startLottery({"from": account})
    tx.wait(1)
    # ne treba ovde da se izvlace brojevi vec u endLottery
    # tx = luckysix.drawNumbers({"from": account})
    # tx.wait(1)
    drawnNumbers = luckysix.getDrawnNumbers()
    # Assert
    assert(luckysix._randomResult() != 0)
    assert len(drawnNumbers) == 35
    assert allUnique(drawnNumbers)


def test_enter_lottery_integration(get_lastest_contract, test_combination, test_price):
    # Arrange
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = get_lastest_contract
    # Act
    luckysix.enterLottery(test_combination, test_price, {"from": account, "value": test_price})
    # Assert
    assert(len(luckysix.getTickets(account.address)) > 0)


def test_end_lottery_integration(get_lastest_contract):
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = Contract.from_abi(LuckySix._name, get_lastest_contract.address, LuckySix.abi)
    # Act
    luckysix.endLottery({"from": account, "value": 100000000000000000})
    print(luckysix.cashEarned({"from": account}))