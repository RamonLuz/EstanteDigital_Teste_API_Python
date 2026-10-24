Feature: Registro de vendas
  @smoke
  Scenario: CT011 - Registrar venda com cliente, funcionario e livro existentes
    When envio uma requisicao POST para "/books" com o payload "sales/create-sale-book.json"
    Then o status da resposta deve ser 201

    When envio uma requisicao POST para "/customers" com o payload "sales/create-sale-customer.json"
    Then o status da resposta deve ser 201

    When envio uma requisicao POST para "/employees" com o payload "sales/create-sale-employee.json"
    Then o status da resposta deve ser 201

    When envio uma requisicao POST para "/sales" com o payload "sales/create-sale.json"
    Then o status da resposta deve ser 201
    And o campo JSON "id" deve ser um numero positivo
    And o campo JSON "customer.cpf" deve ser "${unique}"
    And o campo JSON "employee.registrationNumber" deve ser "${registration}"
    And o campo JSON "book.title" deve ser "Livro de Venda ${unique}"
    When envio uma requisicao GET para "/sales/${id}"
    Then o status da resposta deve ser 200
    And o campo JSON "book.title" deve ser "Livro de Venda ${unique}"
    When envio uma requisicao GET para "/sales"
    Then o status da resposta deve ser 200
    And a lista JSON deve conter "Livro de Venda ${unique}" no campo "book.title"

  @regression
  Scenario Outline: Rejeitar venda com campo invalido, nulo ou ausente
    When envio uma requisicao POST para "/sales" com o payload "sales/create-sale.json" e altero o campo "<field>" para "<mutation>"
    Then o status da resposta deve ser 400

    Examples:
      | field                    | mutation    |
      | customerCpf              | blank       |
      | customerCpf              | invalid-cpf |
      | customerCpf              | null        |
      | customerCpf              | missing     |
      | employeeRegistrationNumber | zero      |
      | employeeRegistrationNumber | null      |
      | employeeRegistrationNumber | missing   |
      | employeeRegistrationNumber | wrong-type|
      | bookTitle                | blank       |
      | bookTitle                | null        |
      | bookTitle                | missing     |
      | bookAuthor               | blank       |
      | bookAuthor               | null        |
      | bookAuthor               | missing     |
      | saleDate                 | invalid-date|
      | saleDate                 | null        |
      | saleDate                 | missing     |

  @regression
  Scenario: Rejeitar venda sem cliente associado
    When envio uma requisicao POST para "/books" com o payload "sales/create-sale-book.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao POST para "/employees" com o payload "sales/create-sale-employee.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao POST para "/sales" com o payload "sales/create-sale.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Customer does not exist"

  @regression
  Scenario: Rejeitar venda sem funcionario associado
    When envio uma requisicao POST para "/books" com o payload "sales/create-sale-book.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao POST para "/customers" com o payload "sales/create-sale-customer.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao POST para "/sales" com o payload "sales/create-sale.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Employee does not exist"

  @regression
  Scenario: Rejeitar venda sem livro associado
    When envio uma requisicao POST para "/customers" com o payload "sales/create-sale-customer.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao POST para "/employees" com o payload "sales/create-sale-employee.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao POST para "/sales" com o payload "sales/create-sale.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Book does not exist"

  @regression
  Scenario Outline: Informar identificador numerico inexistente para vendas
    When envio uma requisicao GET para "<path>"
    Then o status da resposta deve ser 404

    Examples:
      | path              |
      | /sales/0          |
      | /sales/999999999  |

  @regression
  Scenario: Rejeitar identificador de venda que nao seja numerico
    When envio uma requisicao GET para "/sales/nao-numerico"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"

  @regression
  Scenario: Rejeitar criacao de venda sem corpo
    When envio uma requisicao POST para "/sales"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Request body is required"

  @regression
  Scenario: Rejeitar consulta de venda inexistente
    When envio uma requisicao GET para "/sales/999999999"
    Then o status da resposta deve ser 404