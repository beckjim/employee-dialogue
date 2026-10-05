"""Configure database isolation before pytest imports application modules."""

from __future__ import annotations

import sys

from collections.abc import Iterator
from pathlib import Path
from tempfile import TemporaryDirectory
from typing import TYPE_CHECKING

import pytest

if TYPE_CHECKING:
    from flask.testing import FlaskClient


TEST_DATABASE_PATH = pytest.StashKey[Path]()


def pytest_configure(config: pytest.Config) -> None:
    if "employee_dialogue" in sys.modules:
        raise pytest.UsageError(
            "The application was imported before test database isolation was configured."
        )

    instance_directory = TemporaryDirectory(prefix="employee-dialogue-tests-")
    config.add_cleanup(instance_directory.cleanup)
    config.stash[TEST_DATABASE_PATH] = Path(instance_directory.name) / "app.db"

    environment = pytest.MonkeyPatch()
    environment.setenv("FLASK_INSTANCE_PATH", instance_directory.name)
    environment.setenv("SKIP_DB_INIT", "1")
    config.add_cleanup(environment.undo)

    def close_test_database() -> None:
        application = sys.modules.get("employee_dialogue")
        if application is not None:
            with application.app.app_context():
                application.database.session.remove()
                application.database.engine.dispose()

    config.add_cleanup(close_test_database)


@pytest.fixture
def client(request: pytest.FixtureRequest, monkeypatch: pytest.MonkeyPatch) -> Iterator[FlaskClient]:
    from employee_dialogue import app
    from employee_dialogue import database

    expected_database = request.config.stash[TEST_DATABASE_PATH]

    def require_test_database() -> None:
        actual_database = database.engine.url.database
        if actual_database is None or Path(actual_database).resolve() != expected_database.resolve():
            pytest.fail("Refusing to create or drop tables outside the isolated test database.")

    monkeypatch.setitem(app.config, "TESTING", True)
    monkeypatch.setitem(app.config, "SECRET_KEY", "test-secret-key")

    with app.app_context():
        require_test_database()
        database.create_all()

    try:
        with app.test_client() as test_client:
            yield test_client
    finally:
        with app.app_context():
            require_test_database()
            database.session.remove()
            database.drop_all()
