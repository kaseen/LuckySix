from brownie import network
from scripts.deploy_and_fund import deploy_and_fund
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
import pytest

from tests.conftest import test_combination, test_price, player1, player2, player3


def allUnique(list):
    return len(list) == len(set(list))


def test_drawn_numbers():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = deploy_and_fund(account)
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
    luckysix = deploy_and_fund(account)
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
    index = luckysix.returnIndexOfLastDrawnNumber(test_combination)
    # Assert
    assert(index >= -1);
    assert(index <= 48);
    return luckysix, index


def test_cash_earned(test_combination, test_price):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix, index = test_index_of_last_drawn_number(test_combination, test_price)
    # Act
    cash = luckysix.cashEarned(account.address);
    # Assert
    if(index == -1):
        assert(cash == 0)
    else:
        assert(cash > 0)


def test_lottery_multiple_users(player1, player2, player3):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    owner = get_account()
    pl1 = get_account(index=1)
    pl2 = get_account(index=2)
    pl3 = get_account(index=3)
    luckysix = deploy_and_fund(owner)
    # Act
    luckysix.drawNumbers({"from": owner})
    luckysix.enterLottery(player1[0], player1[1],  {"from": pl1})
    luckysix.enterLottery(player2[0], player2[1],  {"from": pl2})
    luckysix.enterLottery(player3[0], player3[1],  {"from": pl3})
    print(luckysix.cashEarned(pl1.address))
    print(luckysix.cashEarned(pl2.address))
    print(luckysix.cashEarned(pl3.address))