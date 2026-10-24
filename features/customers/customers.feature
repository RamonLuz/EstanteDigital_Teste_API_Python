Feature: Gerenciamento de clientes
  @smoke
  Scenario: CT006 - Cadastrar um cliente
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json"
    Then o status da resposta deve ser 201
    And o campo JSON "id" deve ser um numero positivo
    And o campo JSON "cpf" deve ser "${unique}"

  @smoke
  Scenario: CT007 - Consultar um cliente por ID
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json"
    When envio uma requisicao GET para "/customers/${id}"
    Then o status da resposta deve ser 200
    And o campo JSON "status" deve ser "ACTIVE"

  @smoke
  Scenario: Listar clientes cadastrados
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao GET para "/customers"
    Then o status da resposta deve ser 200
    And a lista JSON deve conter "Cliente BDD ${unique}" no campo "name"

  @smoke
  Scenario: Atualizar cliente cadastrado
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao PUT para "/customers/${id}" com o payload "customers/update-customer.json"
    Then o status da resposta deve ser 200
    And o campo JSON "status" deve ser "INACTIVE"
    When envio uma requisicao GET para "/customers/${id}"
    Then o status da resposta deve ser 200
    And o campo JSON "status" deve ser "INACTIVE"

  @smoke
  Scenario: Excluir cliente cadastrado
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao DELETE para "/customers/${id}"
    Then o status da resposta deve ser 204
    When envio uma requisicao GET para "/customers/${id}"
    Then o status da resposta deve ser 404

  @regression
  Scenario: CT008 - Rejeitar cliente com CPF invalido
    When envio uma requisicao POST para "/customers" com o payload "customers/invalid-customer.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "CPF must have 11 digits"

  @regression
  Scenario Outline: Rejeitar cliente com campo obrigatorio invalido, nulo ou ausente
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json" e altero o campo "<field>" para "<mutation>"
    Then o status da resposta deve ser 400

    Examples:
      | field  | mutation   |
      | name   | blank      |
      | name   | whitespace |
      | name   | null       |
      | name   | missing    |
      | cpf    | invalid-cpf |
      | cpf    | too-long-cpf |
      | cpf    | null       |
      | cpf    | missing    |
      | status | blank      |
      | status | whitespace |
      | status | null       |
      | status | missing    |

  @regression
  Scenario Outline: Aceitar campo opcional purchases quando valido, nulo ou ausente
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer-with-purchases.json" e altero o campo "purchases" para "<mutation>"
    Then o status da resposta deve ser 201

    Examples:
      | mutation    |
      | empty-array |
      | null        |
      | missing     |

  @regression
  Scenario: Rejeitar campo purchases com tipo invalido
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer-with-purchases.json" e altero o campo "purchases" para "wrong-type"
    Then o status da resposta deve ser 400

  @regression
  Scenario Outline: Informar identificador numerico inexistente para clientes
    When envio uma requisicao GET para "<path>"
    Then o status da resposta deve ser 404

    Examples:
      | path                  |
      | /customers/0          |
      | /customers/999999999  |

  @regression
  Scenario: Rejeitar identificador de cliente que nao seja numerico
    When envio uma requisicao GET para "/customers/nao-numerico"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"

  @regression
  Scenario: Rejeitar criacao de cliente com CPF ja cadastrado
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "CPF already registered"

  @regression
  Scenario: Rejeitar criacao de cliente sem corpo
    When envio uma requisicao POST para "/customers"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Request body is required"

  @regression
  Scenario: Rejeitar atualizacao de cliente inexistente
    When envio uma requisicao PUT para "/customers/999999999" com o payload "customers/update-customer.json"
    Then o status da resposta deve ser 404

  @regression
  Scenario: Rejeitar atualizacao de cliente sem corpo
    When envio uma requisicao PUT para "/customers/1"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Request body is required"

  @regression
  Scenario: Rejeitar atualizacao de cliente com campo obrigatorio invalido
    When envio uma requisicao POST para "/customers" com o payload "customers/create-customer.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao PUT para "/customers/${id}" com o payload "customers/update-customer.json" e altero o campo "status" para "blank"
    Then o status da resposta deve ser 400

  @regression
  Scenario: Rejeitar exclusao de cliente inexistente
    When envio uma requisicao DELETE para "/customers/999999999"
    Then o status da resposta deve ser 404

  @regression
  Scenario: Rejeitar identificador nao numerico em atualizacao de cliente
    When envio uma requisicao PUT para "/customers/invalido" com o payload "customers/update-customer.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"

  @regression
  Scenario: Rejeitar identificador nao numerico em exclusao de cliente
    When envio uma requisicao DELETE para "/customers/invalido"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"