type myTyp = Var | Fonc
(* que des variables dans le env_eval ???? *)
type trucEval = {
  niveau: int;
  id: Syntax.idvar;
  retour: Syntax.typ;
}

type env_eval = trucEval list

(* Syntax.expr ->  bool|int*)
(* Syntax.expr ->  (bool option * int option) ????*) 
let eval_expr _ = failwith "Not yet implemented <- Evaluateur.eval_expr"

(* Syntax.programme/Syntax.fun_decl list -> unit (affiche un entier ou un booléen)*)
let eval_prog _ = failwith "Not yet implemented <- Evaluateur.eval_prog"
