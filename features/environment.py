from behave.model import Scenario
from behave.model_core import Status
from behave.runner import Context

from estantedigital_api_tests.api_client import ApiClient, Settings
from estantedigital_api_tests.response_contract import ResponseContractValidator
from estantedigital_api_tests.test_data import PayloadLoader, scenario_variables


def before_all(context: Context) -> None:
    """Cria os recursos compartilhados pela execucao Behave."""
    context.api = None
    settings = Settings.from_env(dict(context.config.userdata))
    context.api = ApiClient(
        settings.base_url,
        settings.timeout_seconds,
        token=settings.token,
    )
    context.contract_validator = ResponseContractValidator()


def before_scenario(context: Context, scenario: Scenario) -> None:
    """Cria valores e estado novos para cada cenario."""
    context.scenario_name = scenario.name
    context.values = scenario_variables()
    context.response = None
    context.last_id = None
    context.payload_loader = PayloadLoader()


def after_scenario(context: Context, scenario: object) -> None:
    """Mostra a resposta HTTP que ajudara a investigar um cenario com falha."""
    if scenario.status == Status.failed and context.response is not None:
        print(
            f"\nScenario: {context.scenario_name}\n"
            f"Last HTTP response: {context.response.status_code}\n"
            f"{context.response.text}"
        )


def after_all(context: Context) -> None:
    if context.api is not None:
        context.api.close()
