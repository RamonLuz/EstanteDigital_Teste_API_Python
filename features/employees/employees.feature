Feature: Gerenciamento de funcionarios
  @smoke
  Scenario: CT009 - Cadastrar um funcionario
    When envio uma requisicao POST para "/employees" com o payload "employees/create-employee.json"
    Then o status da resposta deve ser 201
    And o campo JSON "registrationNumber" deve ser "${registration}"

  @smoke
  Scenario: Consultar funcionario cadastrado por ID
    When envio uma requisicao POST para "/employees" com o payload "employees/create-employee.json"
    When envio uma requisicao GET para "/employees/${id}"
    Then o status da resposta deve ser 200
    And o campo JSON "registrationNumber" deve ser "${registration}"

  @smoke
  Scenario: CT010 - Atualizar o status de um funcionario
    When envio uma requisicao POST para "/employees" com o payload "employees/create-employee.json"
    When envio uma requisicao PUT para "/employees/${id}" com o payload "employees/update-employee.json"
    Then o status da resposta deve ser 200
    And o campo JSON "status" deve ser "INACTIVE"

  @smoke
  Scenario: Listar funcionarios cadastrados
    When envio uma requisicao POST para "/employees" com o payload "employees/create-employee.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao GET para "/employees"
    Then o status da resposta deve ser 200
    And a lista JSON deve conter "Funcionario BDD ${unique}" no campo "name"

  @smoke
  Scenario: Excluir funcionario cadastrado
    When envio uma requisicao POST para "/employees" com o payload "employees/create-employee.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao DELETE para "/employees/${id}"
    Then o status da resposta deve ser 204
    When envio uma requisicao GET para "/employees/${id}"
    Then o status da resposta deve ser 404

  @regression
  Scenario Outline: Rejeitar funcionario com campo obrigatorio invalido, nulo ou ausente
    When envio uma requisicao POST para "/employees" com o payload "employees/create-employee.json" e altero o campo "<field>" para "<mutation>"
    Then o status da resposta deve ser 400

    Examples:
      | field              | mutation   |
      | name               | blank      |
      | name               | whitespace |
      | name               | null       |
      | name               | missing    |
      | cpf                | invalid-cpf |
      | cpf                | too-long-cpf |
      | cpf                | null       |
      | cpf                | missing    |
      | registrationNumber | zero       |
      | registrationNumber | null       |
      | registrationNumber | missing    |
      | registrationNumber | wrong-type |
      | position           | blank      |
      | position           | whitespace |
      | position           | null       |
      | position           | missing    |
      | status             | blank      |
      | status             | whitespace |
      | status             | null       |
      | status             | missing    |

  @regression
  Scenario Outline: Informar identificador numerico inexistente para funcionarios
    When envio uma requisicao GET para "<path>"
    Then o status da resposta deve ser 404

    Examples:
      | path                  |
      | /employees/0          |
      | /employees/999999999  |

  @regression
  Scenario: Rejeitar identificador de funcionario que nao seja numerico
    When envio uma requisicao GET para "/employees/nao-numerico"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"

  @regression
  Scenario: Rejeitar criacao de funcionario sem corpo
    When envio uma requisicao POST para "/employees"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Request body is required"

  @regression
  Scenario: Rejeitar atualizacao de funcionario inexistente
    When envio uma requisicao PUT para "/employees/999999999" com o payload "employees/update-employee.json"
    Then o status da resposta deve ser 404

  @regression
  Scenario: Rejeitar atualizacao de funcionario sem corpo
    When envio uma requisicao PUT para "/employees/1"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Request body is required"

  @regression
  Scenario: Rejeitar atualizacao de funcionario com status invalido
    When envio uma requisicao POST para "/employees" com o payload "employees/create-employee.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao PUT para "/employees/${id}" com o payload "employees/update-employee.json" e altero o campo "status" para "blank"
    Then o status da resposta deve ser 400

  @regression
  Scenario: Rejeitar exclusao de funcionario inexistente
    When envio uma requisicao DELETE para "/employees/999999999"
    Then o status da resposta deve ser 404

  @regression
  Scenario: Rejeitar identificador nao numerico em atualizacao de funcionario
    When envio uma requisicao PUT para "/employees/invalido" com o payload "employees/update-employee.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"

  @regression
  Scenario: Rejeitar identificador nao numerico em exclusao de funcionario
    When envio uma requisicao DELETE para "/employees/invalido"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"