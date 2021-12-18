import pytest


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
