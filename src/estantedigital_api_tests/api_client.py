import os
from dataclasses import dataclass
from urllib.parse import urlparse

import requests
from dotenv import dotenv_values
from requests import Response


@dataclass(frozen=True)
class Settings:
    base_url: str
    timeout_seconds: float
    token: str | None

    @classmethod
    def from_env(cls, overrides: dict[str, str] | None = None) -> "Settings":
        overrides = overrides or {}
        dotenv = dotenv_values()

        base_url = (
            os.getenv("API_BASE_URL")
            or overrides.get("base_url")
            or dotenv.get("API_BASE_URL")
            or "http://localhost:8080"
        )
        raw_timeout = (
            os.getenv("API_TIMEOUT_SECONDS")
            or overrides.get("timeout")
            or dotenv.get("API_TIMEOUT_SECONDS")
            or "10"
        )
        token = (
            os.getenv("API_TOKEN")
            or overrides.get("token")
            or dotenv.get("API_TOKEN")
            or None
        )

        parsed_url = urlparse(base_url)
        if parsed_url.scheme not in {"http", "https"} or not parsed_url.netloc:
            raise ValueError("API_BASE_URL must be an absolute HTTP or HTTPS URL.")

        try:
            timeout_seconds = float(raw_timeout)
        except ValueError:
            raise ValueError("API_TIMEOUT_SECONDS must be a number.") from None
        if timeout_seconds <= 0:
            raise ValueError("API_TIMEOUT_SECONDS must be greater than zero.")

        return cls(base_url.rstrip("/"), timeout_seconds, token)


class ApiClient:
    """Centraliza os detalhes HTTP usados pelos steps do Behave."""

    def __init__(
        self,
        base_url: str,
        timeout_seconds: float,
        token: str | None = None,
        session: requests.Session | None = None,
    ) -> None:
        """Prepara a URL base, o timeout, a autenticacao e a sessao HTTP."""
        self.base_url = base_url.rstrip("/")
        self.timeout_seconds = timeout_seconds
        self.token = token
        self.session = session or requests.Session()

    def request(self, method: str, endpoint: str, **kwargs: object) -> Response:
        """Envia uma requisicao JSON para um endpoint da API."""
        normalized_method = method.upper()
        if normalized_method not in {"GET", "POST", "PUT", "DELETE"}:
            raise ValueError(f"Unsupported HTTP method: {method}")

        url = f"{self.base_url}/{endpoint.lstrip('/')}"
        headers = {
            "Accept": "application/json",
            "Content-Type": "application/json",
        }
        if self.token:
            headers["Authorization"] = f"Bearer {self.token}"
        headers.update(kwargs.pop("headers", {}) or {})
        return self.session.request(
            method=normalized_method,
            url=url,
            timeout=self.timeout_seconds,
            headers=headers,
            **kwargs,
        )

    def close(self) -> None:
        """Encerra a sessao HTTP no final da execucao."""
        self.session.close()
