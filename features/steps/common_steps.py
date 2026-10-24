from typing import Any

from behave import then, use_step_matcher, when
from behave.runner import Context

from estantedigital_api_tests.test_data import render_placeholders

_MUTATIONS: dict[str, object] = {
    "null": None,
    "blank": "",
    "whitespace": "   ",
    "invalid-cpf": "123",
    "invalid-date": "not-a-date",
    "zero": 0,
    "negative": -1,
    "empty-array": [],
    "wrong-type": "not-a-number",
}

use_step_matcher("re")


def _render(context: Context, value: str) -> str:
    """Substitui os valores variaveis de um cenario em texto ou rota."""
    return render_placeholders(value, _scenario_values(context))


def _send_request(context: Context, method: str, path: str, body: Any = None) -> None:
    """Envia uma requisicao e guarda os dados para as verificacoes do cenario."""
    resolved_path = _render(context, path)
    if body is None:
        response = context.api.request(method, resolved_path)
    else:
        response = context.api.request(method, resolved_path, json=body)

    context.response = response
    context.request_method = method
    context.request_path = resolved_path
    if (
        200 <= response.status_code < 300
        and "json" in response.headers.get("Content-Type", "").lower()
        and response.content
    ):
        response_body = response.json()
        if isinstance(response_body, dict):
            response_id = response_body.get("id")
            if response_id is not None:
                context.last_id = str(response_id)


def _scenario_values(context: Context) -> dict[str, str]:
    """Retorna os valores do cenario e o ultimo ID recebido da API."""
    values = dict(context.values)
    if context.last_id is not None:
        values["id"] = context.last_id
    return values


@when(r'envio uma requisicao (\w+) para "([^"]+)"')
def send_request(context: Context, method: str, path: str) -> None:
    """Envia GET, POST, PUT ou DELETE sem corpo."""
    _send_request(context, method, path)


@when(r'envio uma requisicao (\w+) para "([^"]+)" com o payload "([^"]+)"')
def send_request_with_payload(
    context: Context, method: str, path: str, payload_file: str
) -> None:
    """Carrega o JSON de payload indicado pela feature e envia a requisicao."""
    body = context.payload_loader.load(payload_file, _scenario_values(context))
    _send_request(context, method, path, body)


@when(
    r'envio uma requisicao (\w+) para "([^"]+)" com o payload "([^"]+)" '
    r'e altero o campo "([^"]+)" para "([^"]+)"'
)
def send_request_with_modified_payload(
    context: Context,
    method: str,
    path: str,
    payload_file: str,
    field: str,
    mutation: str,
) -> None:
    """Altera um campo do payload para testar a validacao da API."""
    body = context.payload_loader.load(payload_file, _scenario_values(context))
    if field not in body:
        raise ValueError(f"JSON field was not found in payload: {field}")

    if mutation == "missing":
        del body[field]
    elif mutation == "too-long-cpf":
        body[field] = f"{context.values['unique']}1"
    elif mutation in _MUTATIONS:
        body[field] = _MUTATIONS[mutation]
    else:
        raise ValueError(f"Unknown JSON field mutation: {mutation}")

    _send_request(context, method, path, body)


@then(r"o status da resposta deve ser (\d+)")
def verify_response_status(context: Context, expected_status: int) -> None:
    """Compara o status HTTP recebido com o esperado na feature."""
    expected_status = int(expected_status)
    assert context.response is not None, "Nenhuma requisicao HTTP foi enviada."
    assert context.response.status_code == expected_status, (
        f"Esperado HTTP {expected_status}, recebido "
        f"{context.response.status_code}: {context.response.text}"
    )
    context.contract_validator.validate(
        context.request_method,
        context.request_path,
        context.response,
    )


@then(r'o campo JSON "([^"]+)" deve ser "([^"]+)"')
def verify_json_field(context: Context, json_path: str, expected_value: str) -> None:
    """Compara um campo da resposta com o valor esperado."""
    assert context.response is not None, "Nenhuma requisicao HTTP foi enviada."
    actual = _json_path(context.response.json(), json_path)
    expected = _render(context, expected_value)
    assert str(actual) == expected, (
        f"Esperado JSON {json_path!r} = {expected!r}, recebido {actual!r}."
    )


@then(r'o campo JSON "([^"]+)" deve ser um numero positivo')
def verify_positive_json_number(context: Context, json_path: str) -> None:
    """Confirma que um campo numérico da resposta é maior que zero."""
    assert context.response is not None, "Nenhuma requisicao HTTP foi enviada."
    value = _json_path(context.response.json(), json_path)
    assert isinstance(value, (int, float)) and not isinstance(value, bool), (
        f"JSON {json_path!r} deveria ser um numero, recebido {value!r}."
    )
    assert value > 0, f"JSON {json_path!r} deveria ser positivo, recebido {value!r}."


@then(r'a lista JSON deve conter "([^"]+)" no campo "([^"]+)"')
def verify_list_contains(context: Context, expected_value: str, json_path: str) -> None:
    """Confirma que uma lista da resposta contém o valor esperado."""
    assert context.response is not None, "Nenhuma requisicao HTTP foi enviada."
    values = _json_path(context.response.json(), json_path)
    expected = _render(context, expected_value)
    assert isinstance(values, list), (
        f"JSON {json_path!r} deveria ser uma lista, recebido {type(values).__name__}."
    )
    assert expected in [str(value) for value in values], (
        f"Lista JSON {json_path!r} nao contem {expected!r}: {values!r}."
    )


def _json_path(value: Any, path: str) -> Any:
    """Lê campos JSON aninhados, como customer.cpf ou book.title."""
    current = value
    for segment in path.split("."):
        if isinstance(current, list):
            current = [item[segment] for item in current]
        elif isinstance(current, dict):
            current = current[segment]
        else:
            raise AssertionError(
                f"Cannot resolve JSON path {path!r} at segment {segment!r}."
            )
    return current
