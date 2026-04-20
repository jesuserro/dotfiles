---
name: project-structure
description: Standards for creating well-organized Python projects.
---

# Python Project Structure

Standards for creating well-organized Python projects.

## When to Use

- Starting a new Python project
- Structuring a Python package
- Setting up a monorepo
- Reviewing Python project organization
- Configuring build systems

## Standard Structure

### Single Package Project

```
my_project/
├── src/
│   └── my_project/
│       ├── __init__.py
│       ├── main.py
│       ├── config.py
│       ├── models/
│       │   ├── __init__.py
│       │   └── user.py
│       └── services/
│           ├── __init__.py
│           └── user_service.py
├── tests/
│   ├── __init__.py
│   ├── conftest.py
│   └── test_user_service.py
├── docs/
├── pyproject.toml
├── uv.lock
├── .gitignore
└── README.md
```

### Multi-Package Monorepo

```
monorepo/
├── packages/
│   ├── shared/
│   │   ├── pyproject.toml
│   │   └── shared/
│   │       └── __init__.py
│   ├── api/
│   │   ├── pyproject.toml
│   │   └── api/
│   └── cli/
│       ├── pyproject.toml
│       └── cli/
├── scripts/
├── .github/
├── pyproject.toml  # Workspace root
└── uv.lock
```

## File Naming

| Pattern | Example | Notes |
|---------|---------|-------|
| Modules | `user_service.py` | snake_case |
| Classes | `UserService` | PascalCase |
| Constants | `MAX_RETRIES` | UPPER_SNAKE |
| Private | `_internal.py` | Leading underscore |
| Tests | `test_user_service.py` | test_ prefix |

## Package Design

### `__init__.py`

```python
"""Top-level package for my_project."""

__version__ = "1.0.0"

from .config import settings
from .main import create_app

__all__ = ["settings", "create_app", "__version__"]
```

### Public vs Private API

```python
# Public API (exported in __init__.py)
from .user_service import UserService
from .models import User

# Private API (internal use only)
from ._internal import _validate_email  # Leading underscore
```

## Configuration

### Environment-Based Config

```python
# config.py
from pydantic_settings import BaseSettings
from functools import lru_cache

class Settings(BaseSettings):
    app_name: str = "my_project"
    debug: bool = False
    database_url: str
    
    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"

@lru_cache
def get_settings() -> Settings:
    return Settings()
```

### Settings Usage

```python
from .config import get_settings

settings = get_settings()
```

## Dependencies

### pyproject.toml

```toml
[project]
name = "my_project"
version = "1.0.0"
requires-python = ">=3.11"
dependencies = [
    "pydantic>=2.0",
    "sqlalchemy>=2.0",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "ruff>=0.3",
]
```

## Testing Structure

```python
# tests/conftest.py
import pytest
from my_project import create_app

@pytest.fixture
def app():
    return create_app()

@pytest.fixture
def client(app):
    return app.test_client()

# tests/test_user_service.py
def test_create_user(client):
    response = client.post("/users", json={"email": "test@example.com"})
    assert response.status_code == 201
```

## Import Conventions

```python
# Standard library
import json
from datetime import datetime
from pathlib import Path

# Third party
import pydantic
from sqlalchemy import select

# Local (explicit relative)
from .models import User
from .services import UserService
```

## Anti-Patterns

| Pattern | Problem | Solution |
|---------|---------|----------|
| `from . import *` | Unclear API | Explicit imports |
| Circular imports | Import errors | Refactor to avoid |
| Wildcard imports | Namespace pollution | `__all__` |
| Mutable defaults | Bugs | `None` + assign inside |
| Bare `except` | Hidden errors | Catch specific exceptions |

## Code Organization Principles

1. **Flat is better than nested**
2. **Explicit is better than implicit**
3. **Readability counts**
4. **Simple is better than complex**
5. **Practicality beats purity**

## Related Skills

- `sql-style`: For database code in Python
- `data-contracts`: For API contracts
