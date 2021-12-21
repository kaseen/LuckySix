from brownie import network
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
from scripts.deploy_and_fund import deploy_and_fund
from tests.conftest import get_lastest_contract, test1, test2, test3
import pytest
import time


def test_start_lottery():
    # Arrange
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = deploy_and_fund(account)
    # Act / Assert
    assert(luckysix.lottery_state() == 1)
    tx = luckysix.startLottery({"from": account})
    tx.wait(1)
    assert(luckysix.lottery_state() == 0)


def test_enter_lottery(get_lastest_contract, test1, test2, test3):
    # Arrange
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = get_lastest_contract
    # Act / Assert
    assert(luckysix.lottery_state() == 0)
    tx = luckysix.enterLottery(test1[0], test1[1], {"from": account})
    tx.wait(2)
    tx = luckysix.enterLottery(test2[0], test2[1], {"from": account})
    tx.wait(2)
    tx = luckysix.enterLottery(test3[0], test3[1], {"from": account})
    tx.wait(2)
    assert(len(luckysix.getTickets(account.address)) > 0)


def test_end_lottery(get_lastest_contract):
    # Arrange
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = get_lastest_contract
    # Act / Assert
    assert(luckysix.lottery_state() == 0)
    tx = luckysix.endLottery({"from": account})
    tx.wait(1)
    time.sleep(70)
    assert(luckysix.lottery_state() == 2)


def test_draw_numbers(get_lastest_contract):
    # Arrange
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = get_lastest_contract
    # Act / Assert
    assert(luckysix._randomResult() != 0)
    tx = luckysix.drawNumbers({"from": account})
    tx.wait(1)
    assert(len(luckysix.getDrawnNumbers()) != 0)
    assert(luckysix.lottery_state() == 1)


def test_empty_map(get_lastest_contract):
    # Arrange
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    account = get_account()
    luckysix = get_lastest_contract
    # Act
    tx = luckysix.emptyMap({"from": account})
    tx.wait(1)
    # Assert
    assert(len(luckysix.getListOfPlayers({"from": account})) == 0)
    assert(len(luckysix.getTickets(account.address)) == 0)
