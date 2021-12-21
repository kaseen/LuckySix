from brownie import network, exceptions
from scripts.deploy_and_fund import deploy_and_fund
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
import pytest

from tests.conftest import test1, test2, test3


def allUnique(list):
    return len(list) == len(set(list))


def test_cant_enter_unless_started(test1):
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = deploy_and_fund(account)
    # Act / Assert
    with pytest.raises(exceptions.VirtualMachineError):
        luckysix.enterLottery(test1[0], {"from": account, "value": test1[1]})


def test_drawn_numbers():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    account = get_account()
    luckysix = deploy_and_fund(account)
    # Act
    luckysix.startLottery({"from": account})
    luckysix.endLottery({"from": account})
    luckysix.drawNumbers({"from": account})
    drawnNumbers = luckysix.getDrawnNumbers()
    # Assert
    assert len(drawnNumbers) == 35
    assert allUnique(drawnNumbers)


def test_empty_map_multiple_users(test1, test2, test3):
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
    luckysix.enterLottery(test1[0], {"from": pl1, "value": test1[1]})
    luckysix.enterLottery(test2[0], {"from": pl2, "value": test2[1]})
    luckysix.enterLottery(test3[0], {"from": pl3, "value": test3[1]})
    luckysix.endLottery({"from": owner})
    luckysix.drawNumbers({"from": owner})
    luckysix.emptyMap({"from": owner})
    # Assert
    assert(len(luckysix.getTickets(pl1.address)) == 0)
    assert(len(luckysix.getTickets(pl2.address)) == 0)
    assert(len(luckysix.getTickets(pl3.address)) == 0)
    assert(len(luckysix.getListOfPlayers()) == 0)