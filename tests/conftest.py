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
    return ([13,17,28,31,1,41], 0.013 * 10 ** 18)


@pytest.fixture
def test2():
    return ([1,2,3,4,5,6], 0.05 * 10 ** 18)


@pytest.fixture
def test3():
    return ([6,9,13,19,23,43], 0.0069 * 10 ** 18)