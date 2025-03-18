type typ = TInt | TBool
type idvar = string
type idfun = idvar
type binary_op =
    Plus
  | Minus
  | Mult
  | Div
  | And
  | Or
  | Equal
  | NEqual
  | Less
  | LessEq
  | Great
  | GreatEq
type unary_op = Not
type expr =
    Var of idfun
  | Int of int
  | Bool of bool
  | BinaryOp of binary_op * expr * expr
  | UnaryOp of unary_op * expr
  | If of expr * expr * expr
  | Let of idfun * typ * expr * expr
  | App of idfun * expr list
type fun_decl = {
  id : idfun;
  var_list : (idfun * typ) list;
  typ_retour : typ;
  corps : expr;
}
type programme = fun_decl list
val string_of_type : typ -> string
val string_of_binary_op : binary_op -> string
val string_of_unary_op : unary_op -> string
val string_of_expr_list : expr list -> idvar
val string_of_expr : expr -> idvar
val string_of_var_list : (string * typ) list -> string
val string_of_fun_decl : fun_decl -> string
val string_of_programme : fun_decl list -> string
