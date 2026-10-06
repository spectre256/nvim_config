;; extends

(let_declaration
  "let" @keyword)

(let_declaration
  name: (simple_identifier) @function
  (let_port_list))

(let_declaration
  name: (simple_identifier) @variable
  .
  (expression))
