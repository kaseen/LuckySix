from brownie import LuckySix, network
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS
import pytest

@pytest.fixture
def get_lastest_contract():
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    return LuckySix[-1]


@pytest.fixture
def test1():
    return ([6,9,10,16,20,23], 0.001 * 10 ** 18)


@pytest.fixture
def test2():
    return ([10,26,4,40,46,28], 0.0002 * 10 ** 18)


@pytest.fixture
def test3():
    return ([1,10,20,30,40,43], 0.00003 * 10 ** 18)