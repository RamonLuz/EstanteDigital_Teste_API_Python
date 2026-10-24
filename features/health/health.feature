Feature: Disponibilidade da API
  @smoke
  Scenario: CT001 - Consultar o estado da aplicacao
    When envio uma requisicao GET para "/health"
    Then o status da resposta deve ser 200
    And o campo JSON "status" deve ser "UP"
    And o campo JSON "application" deve ser "estantedigital"