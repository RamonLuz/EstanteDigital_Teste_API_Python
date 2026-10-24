Feature: Gerenciamento de livros
  Como equipe de QA
  Quero validar as operacoes e regras de negocio da API de livros
  Para detectar defeitos e regressões no catalogo

  @smoke
  Scenario: CT002 - Cadastrar um livro
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json"
    Then o status da resposta deve ser 201
    And o campo JSON "id" deve ser um numero positivo
    And o campo JSON "title" deve ser "Livro BDD ${unique}"

  @smoke
  Scenario: CT003 - Consultar um livro por ID
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json"
    When envio uma requisicao GET para "/books/${id}"
    Then o status da resposta deve ser 200
    And o campo JSON "title" deve ser "Livro BDD ${unique}"
    And o campo JSON "author" deve ser "Autor de Teste"

  @smoke
  Scenario: CT004 - Listar livros cadastrados
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json"
    When envio uma requisicao GET para "/books"
    Then o status da resposta deve ser 200
    And a lista JSON deve conter "Livro BDD ${unique}" no campo "title"

  @smoke
  Scenario: Atualizar livro cadastrado
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao PUT para "/books/${id}" com o payload "books/update-book.json"
    Then o status da resposta deve ser 200
    And o campo JSON "title" deve ser "Livro Atualizado ${unique}"
    When envio uma requisicao GET para "/books/${id}"
    Then o status da resposta deve ser 200
    And o campo JSON "author" deve ser "Autor Atualizado"

  @smoke
  Scenario: Excluir livro cadastrado
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao DELETE para "/books/${id}"
    Then o status da resposta deve ser 204
    When envio uma requisicao GET para "/books/${id}"
    Then o status da resposta deve ser 404

  @regression
  Scenario: CT005 - Rejeitar livro com preco invalido
    When envio uma requisicao POST para "/books" com o payload "books/invalid-book.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Required fields were not provided"

  @regression
  Scenario Outline: Rejeitar livro com campo obrigatorio invalido, nulo ou ausente
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json" e altero o campo "<field>" para "<mutation>"
    Then o status da resposta deve ser 400

    Examples:
      | field  | mutation   |
      | title  | blank      |
      | title  | null       |
      | title  | missing    |
      | author | blank      |
      | author | null       |
      | author | missing    |
      | price  | zero       |
      | price  | negative   |
      | price  | null       |
      | price  | missing    |
      | price  | wrong-type |

  @regression
  Scenario Outline: Rejeitar requisicao de livro sem campo obrigatorio
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json" e altero o campo "<field>" para "<mutation>"
    Then o status da resposta deve ser 400

    Examples:
      | field  | mutation   |
      | title  | whitespace |
      | author | whitespace |

  @regression
  Scenario Outline: Informar identificador numerico inexistente para livros
    When envio uma requisicao GET para "<path>"
    Then o status da resposta deve ser 404

    Examples:
      | path               |
      | /books/0           |
      | /books/999999999   |

  @regression
  Scenario: Rejeitar identificador de livro que nao seja numerico
    When envio uma requisicao GET para "/books/nao-numerico"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"

  @regression
  Scenario: Rejeitar criacao de livro duplicado pelo titulo e autor
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Book already exists for this author and title"

  @regression
  Scenario: Rejeitar criacao de livro sem corpo
    When envio uma requisicao POST para "/books"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Request body is required"

  @regression
  Scenario: Rejeitar atualizacao de livro inexistente
    When envio uma requisicao PUT para "/books/999999999" com o payload "books/update-book.json"
    Then o status da resposta deve ser 404

  @regression
  Scenario: Rejeitar atualizacao de livro sem corpo
    When envio uma requisicao PUT para "/books/1"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "Request body is required"

  @regression
  Scenario: Rejeitar atualizacao de livro com campo obrigatorio invalido
    When envio uma requisicao POST para "/books" com o payload "books/create-book.json"
    Then o status da resposta deve ser 201
    When envio uma requisicao PUT para "/books/${id}" com o payload "books/update-book.json" e altero o campo "price" para "null"
    Then o status da resposta deve ser 400

  @regression
  Scenario: Rejeitar exclusao de livro inexistente
    When envio uma requisicao DELETE para "/books/999999999"
    Then o status da resposta deve ser 404

  @regression
  Scenario: Rejeitar identificador nao numerico em atualizacao de livro
    When envio uma requisicao PUT para "/books/invalido" com o payload "books/update-book.json"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"

  @regression
  Scenario: Rejeitar identificador nao numerico em exclusao de livro
    When envio uma requisicao DELETE para "/books/invalido"
    Then o status da resposta deve ser 400
    And o campo JSON "message" deve ser "ID must be numeric"