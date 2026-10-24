import json
from pathlib import Path
from typing import Any

from jsonschema import Draft7Validator, FormatChecker
from referencing import Registry, Resource
from requests import Response

RESOURCE_SCHEMAS = {
    "books": "book",
    "customers": "customer",
    "employees": "employee",
    "sales": "sale",
}


class ResponseContractValidator:
    """Compara cada resposta HTTP com o JSON Schema do endpoint correspondente."""

    def __init__(self, schema_root: Path | None = None) -> None:
        """Carrega os schemas uma vez para reutiliza-los em toda a execucao."""
        self.schema_root = (schema_root or Path("schemas")).resolve()
        self._schemas: dict[str, dict[str, Any]] = {}
        resources = []
        for schema_path in self.schema_root.rglob("*.schema.json"):
            schema = json.loads(schema_path.read_text(encoding="utf-8"))
            schema_uri = schema_path.as_uri()
            schema["$id"] = schema_uri
            self._schemas[schema_path.relative_to(self.schema_root).as_posix()] = schema
            resources.append((schema_uri, Resource.from_contents(schema)))

        self._registry = Registry().with_resources(resources)

    def validate(self, method: str, path: str, response: Response) -> None:
        """Valida corpo vazio ou JSON, conforme status e contrato da API."""
        status = response.status_code
        if status in {204, 404}:
            if response.content:
                raise AssertionError(
                    f"Expected an empty HTTP {status} response, "
                    f"received {response.text!r}."
                )
            return

        schema_name = self._schema_name(method, path, status)
        if schema_name is None:
            raise ValueError(
                f"No response schema configured for {method.upper()} {path} "
                f"with HTTP {status}."
            )
        schema = self._schemas.get(schema_name)
        if schema is None:
            raise FileNotFoundError(
                f"Response schema was not found: {schema_name}.schema.json"
            )
        try:
            body = response.json()
        except ValueError as exc:
            raise AssertionError(
                f"Expected JSON matching {schema_name}.schema.json, "
                f"received: {response.text!r}."
            ) from exc

        validator = Draft7Validator(
            schema,
            registry=self._registry,
            format_checker=FormatChecker(),
        )
        errors = list(validator.iter_errors(body))
        if errors:
            details = "; ".join(
                f"{'.'.join(map(str, error.path)) or '$'}: {error.message}"
                for error in errors
            )
            raise AssertionError(
                f"HTTP {status} response violates {schema_name}.schema.json: {details}"
            )

    @staticmethod
    def _schema_name(method: str, path: str, status: int) -> str | None:
        """Escolhe o schema usando metodo, recurso, caminho e status HTTP."""
        normalized_method = method.upper()
        segments = [segment for segment in path.split("?", 1)[0].split("/") if segment]
        if status == 400:
            return "common/api-error.schema.json"
        if not segments or len(segments) > 2:
            return None

        resource = segments[0]
        collection = len(segments) == 1
        if resource == "health":
            if collection and normalized_method == "GET" and status == 200:
                return "health/health.schema.json"
            return None

        schema_name = RESOURCE_SCHEMAS.get(resource)
        if schema_name is None:
            return None

        if normalized_method == "GET" and status == 200:
            if collection:
                return f"{resource}/{schema_name}-list.schema.json"
            return f"{resource}/{schema_name}.schema.json"

        if resource == "sales":
            if normalized_method == "POST" and collection and status == 201:
                return "sales/sale.schema.json"
            return None

        if (normalized_method == "POST" and collection and status == 201) or (
            normalized_method == "PUT" and not collection and status == 200
        ):
            return f"{resource}/{schema_name}.schema.json"
        return None
