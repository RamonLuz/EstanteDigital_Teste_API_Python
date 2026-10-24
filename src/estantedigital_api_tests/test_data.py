import json
from datetime import date
from pathlib import Path
from secrets import randbelow
from typing import Any


def scenario_variables() -> dict[str, str]:
    """Gera valores distintos para que cenarios nao reutilizem os mesmos dados."""
    unique_value = f"{randbelow(90_000_000_000) + 10_000_000_000:011d}"
    return {
        "unique": unique_value,
        "registration": str(randbelow(900_000) + 100_000),
        "date": date.today().isoformat(),
    }


class PayloadLoader:
    def __init__(self, payload_root: Path | None = None) -> None:
        self.payload_root = (payload_root or Path("payloads")).resolve()

    def load(self, filename: str, values: dict[str, str]) -> dict[str, Any]:
        payload_path = (self.payload_root / filename).resolve()
        if not payload_path.is_relative_to(self.payload_root):
            raise ValueError(f"Payload path escapes the payload directory: {filename}")
        if not payload_path.is_file():
            raise FileNotFoundError(f"Payload file was not found: {payload_path}")

        content = payload_path.read_text(encoding="utf-8")
        payload = json.loads(render_placeholders(content, values))
        if not isinstance(payload, dict):
            raise ValueError(f"Payload {filename!r} must contain a JSON object.")
        return payload


def render_placeholders(value: str, values: dict[str, str]) -> str:
    for name, replacement in values.items():
        value = value.replace(f"${{{name}}}", replacement)

    if "${" in value:
        missing = value.split("${", 1)[1].split("}", 1)[0]
        raise ValueError(f"Placeholder {missing!r} has no value in this scenario.")
    return value
