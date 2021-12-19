from brownie import network, exceptions
from scripts.deploy_and_fund import deploy_and_fund
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
import pytest

from tests.conftest import test1, test2, test3


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


def test_cant_enter_unless_started(test1):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = deploy_and_fund(account)
    # Act / Assert
    with pytest.raises(exceptions.VirtualMachineError):
        luckysix.enterLottery(test1[0], test1[1], {"from": account})


def test_enter_lottery(test1):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = deploy_and_fund(account)
    # Act
    luckysix.startLottery({"from": account})
    luckysix.enterLottery(test1[0], test1[1], {"from": account})
    # Assert
    assert(len(luckysix.getTickets(account.address)) == 1)
    return luckysix


def test_index_of_last_drawn_number(test1):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = test_enter_lottery(test1)
    # Act
    luckysix.drawNumbers({"from": account})
    index = luckysix.returnIndexOfLastDrawnNumber(test1[0])
    # Assert
    assert(index >= -1)
    assert(index <= 48)
    return luckysix, index


def test_cash_earned(test1):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix, index = test_index_of_last_drawn_number(test1)
    # Act
    cash = luckysix.cashEarned(account.address);
    # Assert
    if(index == -1):
        assert(cash == 0)
    else:
        assert(cash > 0)


def test_lottery_multiple_users(test1, test2, test3):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    owner = get_account()
    pl1 = get_account(index=1)
    pl2 = get_account(index=2)
    pl3 = get_account(index=3)
    luckysix = deploy_and_fund(owner)
    # Act
    luckysix.startLottery({"from": owner})
    luckysix.enterLottery(test1[0], test1[1],  {"from": pl1})
    luckysix.enterLottery(test2[0], test2[1],  {"from": pl2})
    luckysix.enterLottery(test3[0], test3[1],  {"from": pl3})
    luckysix.endLottery({"from": owner})
    print(luckysix.cashEarned(pl1.address))
    print(luckysix.cashEarned(pl2.address))
    print(luckysix.cashEarned(pl3.address))