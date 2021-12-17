from brownie import network
from scripts.deploy_and_fund import deploy_and_fund
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
import pytest


def allUnique(list):
    return len(list) == len(set(list))


def test_drawn_numbers():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing")
    account = get_account()
    luckysix = deploy_and_fund()
    # Act
    luckysix.drawNumbers({"from": account})
    drawnNumbers = luckysix.getDrawnNumbers()
    # Assert
    assert len(drawnNumbers) == 35
    assert allUnique(drawnNumbers)
