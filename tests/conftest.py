import pytest


@pytest.fixture
def test_combination():
    return [10,26,4,40,46,11]
    #return [1,2,7,4,8,6]


@pytest.fixture
def test_price():
    return 100