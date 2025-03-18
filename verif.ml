type typeVar = {
  idVar: string; (*non ?, devrait etre idvar | idfun ??*)  
  valeur: Syntax.typ;
}

type typeFunc = {
  idFun: string; (*non ?, devrait etre idvar | idfun ??*)  
  params: Syntax.typ list;
  valeur: Syntax.typ;
}

type env_var_type = typeVar list
type env_func_type = typeFunc list
let bool_to_string b = if b then "true" else "false"

(* Syntax.expr -> Syntax.typ -> env_var_type -> bool *)
let rec verif_expr expr voulu envVar envFun = match expr with
| Syntax.Var id -> let rec aux env = 
                      (match env with  
                        | [] -> false 
                        | t::reste -> if t.idVar = id then 
                          (if t.valeur = voulu then 
                            true 
                          else 
                            false) 
                        else 
                          aux reste )
                    in aux envVar
| Syntax.IdFun id -> let rec aux env = 
  (match env with  
    | [] -> false 
    | t::reste -> if t.idFun = id then 
      (if t.valeur = voulu then 
        true 
      else 
        false) 
    else 
      aux reste )
in aux envFun
 |Syntax.Int n -> print_int n; print_endline " int"; voulu = TInt
| Syntax.Bool b -> print_string (bool_to_string b); print_endline "bool"; voulu = TBool
| Syntax.UnaryOp (_, expr1) -> print_endline "unaryOp"; verif_expr expr1 TBool envVar envFun 
| Syntax.BinaryOp (op, expr1, expr2) -> print_string "binaryOp "; if (op = And || op = Or) then 
                                                                    let _ = print_endline "TBool" in verif_expr expr1 TBool envVar envFun && verif_expr expr2 TBool envVar envFun 
                                                                  else
                                                                    let _ = print_endline "TInt" in verif_expr expr1 TInt envVar envFun && verif_expr expr2 TInt envVar envFun 
| Syntax.If (b, expr1, expr2) -> print_endline "if"; verif_expr b TBool envVar envFun && 
                                (verif_expr expr1 TBool envVar envFun && verif_expr expr2 TBool envVar envFun) &&
                                (verif_expr expr1 TInt envVar envFun && verif_expr expr2 TInt envVar envFun) 
| Syntax.Let (idd, ty, exprIn, exprOut) -> print_endline "let"; if verif_expr exprIn ty envVar envFun then let a = {idVar=idd; valeur=ty}::envVar in verif_expr exprOut voulu a envFun else false
|Syntax.App (funId, exprList) ->  print_endline "app";let rec aux env = 
  (match env with  
    | [] -> false 
    | t::reste -> if t.idFun = funId then 
      (if t.valeur = voulu then
        let rec aux p l= (match (p, l) with 
          | ([],[]) -> true
          | ([],_) -> false (* une liste vide mais pas lautre*)
          | (_,[]) -> false
          | (typeParam::resteParams, expr::resteExpr) -> verif_expr expr typeParam envVar envFun && aux resteParams resteExpr
          ) in aux t.params exprList
      else 
        false) 
    else 
      aux reste)
in aux envFun

(* Syntax.fun-decl -> bool *)
(* TODO: demander prof si il faut declarer le type d'entrée*)
let verif_decl_fun (fonction: Syntax.fun_decl) envVar envFun = 
 let b = verif_expr fonction.corps fonction.typ_retour envVar envFun
in let _ = print_endline (Syntax.string_of_fun_decl fonction)
in let _ = print_string fonction.id 
in let _ = print_string "=" 
in let _ = print_endline (bool_to_string b)
in b 
(* Syntax.programme/Syntax.fun_ decl list -> bool *)
let verif_prog prog = 
  let _ = print_string (Syntax.string_of_programme prog) in
  let rec verifFunctions prog = match prog with 
  | [] -> true
  | fonction::reste -> if fonction.Syntax.id = "main" then verifFunctions reste else verif_decl_fun fonction [] [] in 
  let functionsTypeForMain = 
    let rec second p = match p with 
      | [] -> []
      | (_, typ)::reste -> typ::(second reste)
    in let rec aux funcDeclList = match funcDeclList with
      | [] -> []
      | funDec::reste -> {idFun=funDec.Syntax.id; params=(second funDec.Syntax.var_list); valeur=funDec.Syntax.typ_retour}::(aux reste)
    in aux prog in         
  let rec verifMain prog = match prog with 
  | [] -> false
  | fonction::reste -> if fonction.Syntax.id = "main" then verif_decl_fun fonction [] functionsTypeForMain else verifMain reste
  in if verifFunctions prog then verifMain prog else false