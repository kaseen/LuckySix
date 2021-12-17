from brownie import network
from scripts.deploy_and_fund import deploy_and_fund
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
import pytest

from tests.conftest import test_combination, test_price


def allUnique(list):
    return len(list) == len(set(list))


def test_drawn_numbers():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = deploy_and_fund()
    # Act
    luckysix.drawNumbers({"from": account})
    drawnNumbers = luckysix.getDrawnNumbers()
    # Assert
    assert len(drawnNumbers) == 35
    assert allUnique(drawnNumbers)


def test_enter_lottery(test_combination, test_price):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = deploy_and_fund()
    # Act
    luckysix.enterLottery(test_combination, test_price)
    # Assert
    assert(len(luckysix.getTickets(account.address)) == 1)
    return luckysix


def test_index_of_last_drawn_number(test_combination, test_price):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = test_enter_lottery(test_combination, test_price)
    # Act
    luckysix.drawNumbers({"from": account})
    x = luckysix.returnIndexOfLastDrawnNumber(test_combination)
    print(luckysix.getDrawnNumbers())
    print(x)