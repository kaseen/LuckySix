from brownie import network
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
from scripts.deploy_and_fund import deploy_and_fund
import pytest
import time


def test_random():
    # Arrange
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = deploy_and_fund(account)
    # Act
    tx = luckysix.startLottery({"from": account})
    tx.wait(1)
    tx = luckysix.endLottery({"from": account})
    tx.wait(1)
    time.sleep(70)
    # Assert
    assert(luckysix._randomResult() != 0)
    tx = luckysix.drawNumbers({"from": account})
    tx.wait(1)
    assert(len(luckysix.getDrawnNumbers()) != 0)
    print("Drawn numbers are:")
    print(luckysix.getDrawnNumbers())
    