# Testing

This application includes comprehensive unit tests using pytest.

## Running Tests

To run the tests:

```bash
# Install test dependencies
uv sync --extra dev

# Run all tests
uv run pytest

# Run tests with verbose output
uv run pytest -v

# Run tests with coverage report
uv run pytest --cov=app --cov-report=html

# Run specific test class
uv run pytest test_app.py::TestModels -v

# Run specific test
uv run pytest test_app.py::TestModels::test_entry_creation -v
```

## Test Coverage

The test suite covers:

### Model Tests (`TestModels`)
- Entry model creation
- FinalEntry model creation with source_entry_id

### Validation Tests (`TestValidation`)
- Choice validation (objective and ability ratings)
- Entry access permissions
- Entry management permissions

### Route Tests (`TestRoutes`)
- Authentication redirects for protected routes
- Index page access
- Entry creation form access
- Entry creation with validation
- Successful entry creation
- Entry deletion
- Login/logout flows

### Form Validation Tests (`TestFormValidation`)
- Invalid objective rating rejection
- Invalid ability rating rejection

## Test Database

Before test collection imports the application, `tests/conftest.py` sets
`FLASK_INSTANCE_PATH` to a temporary directory and disables startup migrations.
SQLAlchemy therefore initializes against a temporary SQLite database, never
the development database. The shared `client` fixture creates and drops tables
for each test only after verifying the engine points to that temporary database.
Connections are disposed and the temporary directory is removed at the end of
the run.

Reuse the shared `client` fixture for new tests. Do not change
`SQLALCHEMY_DATABASE_URI` after importing the application: SQLAlchemy has already
initialized its engine, so changing the configuration does not switch databases.

## Fixtures

- `client`: Flask test client with a guarded temporary SQLite database
- `authenticated_session`: Test client with authenticated user session

## Continuous Integration

To integrate these tests into CI/CD:

```yaml
# Example GitHub Actions workflow
- name: Run tests
  run: |
    pip install uv
    uv sync --extra dev
    uv run pytest -v
```
