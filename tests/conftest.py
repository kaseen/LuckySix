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
    return ([6,9,10,16,20,23], 50)


@pytest.fixture
def test2():
    return ([10,26,4,40,46,28], 123)


@pytest.fixture
def test3():
    return ([1,10,20,30,40,43], 200)


@pytest.fixture
def test4():
    return ([3,8,12,16,30,35], 300)


@pytest.fixture
def test5():
    return ([13,19,21,31,41,45], 500)
