"""Regression tests for safe database setup and teardown."""

from pathlib import Path

import pytest

from employee_dialogue import app
from employee_dialogue import database

from .conftest import TEST_DATABASE_PATH


def test_client_uses_temporary_database(client, request):
    with app.app_context():
        database_path = database.engine.url.database
        assert database_path is not None
        assert Path(database_path).resolve() == request.config.stash[TEST_DATABASE_PATH].resolve()
        assert Path(database_path).parent == Path(app.instance_path)
        assert Path(database_path).resolve() != (
            Path(__file__).resolve().parents[1] / "instance" / "app.db"
        ).resolve()


def test_client_refuses_unexpected_database(request, tmp_path):
    expected_database = request.config.stash[TEST_DATABASE_PATH]
    request.config.stash[TEST_DATABASE_PATH] = tmp_path / "unexpected.db"
    try:
        with pytest.raises(pytest.fail.Exception, match="Refusing to create or drop tables"):
            request.getfixturevalue("client")
    finally:
        request.config.stash[TEST_DATABASE_PATH] = expected_database
