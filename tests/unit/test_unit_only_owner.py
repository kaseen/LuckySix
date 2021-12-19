from brownie import network, exceptions
from scripts.deploy_and_fund import deploy_and_fund
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS, get_account
import pytest


def test_only_owner_draw_numbers():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    owner = get_account()
    non_owner = get_account(index=1)
    luckysix = deploy_and_fund(owner)
    # Act / Assert
    with pytest.raises(exceptions.VirtualMachineError):
        luckysix.drawNumbers({"from": non_owner})


def test_only_owner_can_start():
    # Arrange
    if network.show_active() not in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for local testing!")
    owner = get_account()
    non_owner = get_account(index=1)
    luckysix = deploy_and_fund(owner)
    # Act / Assert
    with pytest.raises(exceptions.VirtualMachineError):
        luckysix.startLottery({"from": non_owner})