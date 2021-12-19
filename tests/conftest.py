from brownie import LuckySix, network
from scripts.helpful_scripts import LOCAL_BLOCKCHAIN_ENVIRONMENTS
import pytest

@pytest.fixture
def get_lastest_contract():
    if network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS:
        pytest.skip("Only for integration testing")
    return LuckySix[-1]


@pytest.fixture
def test_combination():
    return [10,26,4,40,46,11]
    #return [1,2,7,4,8,6]


@pytest.fixture
def test_price():
    return 100


@pytest.fixture
def player1():
    return ([10,26,4,40,46,11], 50)


@pytest.fixture
def player2():
    return ([10,26,4,40,46,28], 123)


@pytest.fixture
def player3():
    return ([10,26,4,40,46,3], 200)
