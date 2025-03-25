(*
Groupe: 681C
Binôme AGANZE LWABOSHI MOISE et DUMAIT ANTOINE
*)

type typeVar = {
  idVar: Syntax.idvar;
  valeur: Syntax.typ;
}
type typeFunc = {
  idFun: Syntax.idfun;
  params: Syntax.typ list;
  valeur: Syntax.typ;
}

type env_var_type = typeVar list
type env_func_type = typeFunc list

let rec verif_expr expr voulu envVar envFun =
  (* print_endline ("expr: " ^ (Syntax.string_of_expr expr)); *)
  (* print_endline ("voulu: " ^(Syntax.string_of_type voulu)); *)
  match expr with
  | Syntax.Var id ->
    (* print_endline "var"; *)
    let rec aux env =
      match env with
      | [] -> false
      | t::reste ->
        if t.idVar = id then t.valeur = voulu
        else aux reste
    in
    aux envVar

  | Syntax.Int _ ->
    (* print_int n; *)
    (* print_endline " int"; *)
    voulu = TInt

  | Syntax.Float _ ->
    (* print_float f; *)
    (* print_endline " float"; *)
    voulu = TFloat

  | Syntax.Bool _ ->
    (* print_string (string_of_bool b); *)
    (* print_endline "bool"; *)
    voulu = TBool

  | Syntax.Unit -> (*Extension Unit*)
    (* print_endline "unit"; *)
    voulu = TUnit

  | Syntax.UnaryOp (op, expr1) ->
    (* print_endline "unaryOp"; *)
    (match op with
    | Not -> voulu = TBool && verif_expr expr1 TBool envVar envFun
    | Print_int -> voulu = TUnit && verif_expr expr1 TInt envVar envFun) (*Extension Affichage*)

  | Syntax.BinaryOp (op, expr1, expr2) ->
    (* print_string "binaryOp "; *)
    (match op with 
    
      | And | Or -> 
        (* print_endline "opTBool"; *)
        voulu = TBool && verif_expr expr1 TBool envVar envFun && verif_expr expr2 TBool envVar envFun
    
      | Plus |Minus |Mult |Div ->
        (* print_endline "opCalcul"; *)
        (voulu = TInt || voulu = TFloat) && verif_expr expr1 voulu envVar envFun && verif_expr expr2 voulu envVar envFun (*Extension Float*)
      
      | Less |LessEq |Great |GreatEq ->  
        (* print_endline "opComparaison"; *)
        voulu = TBool &&  
        ((verif_expr expr1 TInt envVar envFun && verif_expr expr2 TInt envVar envFun) 
        || (verif_expr expr1 TFloat envVar envFun && verif_expr expr2 TFloat envVar envFun )) (*Extension Float*)
    
      | Equal | NEqual -> 
        (* print_endline "opEqual"; *)
        voulu = TBool &&
        ((verif_expr expr1 TInt envVar envFun && verif_expr expr2 TInt envVar envFun) 
        || (verif_expr expr1 TFloat envVar envFun && verif_expr expr2 TFloat envVar envFun )
        || (verif_expr expr1 TBool envVar envFun && verif_expr expr2 TBool envVar envFun ))
    
  
      | Seq ->  (*Extension Unit*)
        (* print_endline "opTUnit";  *)
        verif_expr expr1 TUnit envVar envFun && verif_expr expr2 voulu envVar envFun
    )

  | Syntax.If (b, expr1, expr2) ->
    (* print_endline "if"; *)
    verif_expr b TBool envVar envFun && verif_expr expr1 voulu envVar envFun && verif_expr expr2 voulu envVar envFun
  
    | Syntax.Let (id, typeArgument, exprIn, exprOut) ->
    (* print_endline "let"; *)
    if verif_expr exprIn typeArgument envVar envFun then
      verif_expr exprOut voulu ({idVar=id; valeur=typeArgument}::envVar) envFun
    else 
      false

  | Syntax.App (funId, exprList) ->
    (* print_endline "app"; *)
    let rec get_function_by_id env =
      match env with
      | [] -> false
      | t::reste ->
        (* let _ = print_endline ("nom fonction: " ^t.idFun ^ " fonction cherché:  " ^ funId)in *)
        if t.idFun = funId then
          (* let _ = print_endline ("nom fonction: " ^funId ^ ", valeur fonction: " ^ Syntax.string_of_type t.valeur)in *)
          if t.valeur = voulu then
            let rec check_params p l =
              match (p, l) with
              | [], [] -> true (*tous les parametres ont le bon type*)
              | [], _ | _, [] -> false (*une liste vide mais pas l'autre -> pas bon*)
              | typeParam::resteParams, expr_arg::resteExpr ->
                verif_expr expr_arg typeParam envVar envFun && check_params resteParams resteExpr
            in
            check_params t.params exprList (*t.params: le type des parametres attendu par la fonction, exprList: les expressions fourni, doivent avoir le meme type que le type des parametres*)
          else false
        else get_function_by_id reste
    in
    get_function_by_id envFun

let verif_decl_fun (fonction: Syntax.fun_decl) envVar envFun =
  (* print_string ("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n" 
                ^ Syntax.string_of_fun_decl fonction
                ^ "\n----------------------------------------\n");*)
  let b = verif_expr fonction.corps fonction.typ_retour envVar envFun in
  (* print_string ("RESULTAT: " ^ fonction.id ^ " = " ^ string_of_bool b ^ "\n"); *)
  b

let verif_prog prog =
  (* print_string ("Programme à vérifier:\n" 
                ^ "-----------------------------------------------------------------\n"
                ^ Syntax.string_of_programme prog
                ^ "--------------------------------------------------------------------------\n");*)
  let rec tuple_id_typ_to_typeVar idvar_typ_list =
    match idvar_typ_list with
    | [] -> []
    | (id, typ)::reste -> {idVar = id; valeur = typ }::tuple_id_typ_to_typeVar reste
  in

  let fun_decl_to_typeFunc fun_decl = 
    {idFun=fun_decl.Syntax.id; 
     params=List.map (fun (_, typ) -> typ) fun_decl.Syntax.var_list; (*on veut que le typ ???*)
     valeur=fun_decl.Syntax.typ_retour}
  in 

  let rec verifFunctionList availableFunctions prog =
    match prog with
    | [] -> false
    | fonction::reste ->
      if reste = [] then 
        if fonction.Syntax.id = "main" && fonction.Syntax.var_list = [] then (*main est la derniere fonction et ne possède pas d'arguments, on arrete de verifier les fonctions*)
          verif_decl_fun fonction [] availableFunctions
        else false
      else verif_decl_fun fonction (tuple_id_typ_to_typeVar fonction.Syntax.var_list) availableFunctions && verifFunctionList ((fun_decl_to_typeFunc fonction)::availableFunctions) reste
  in
  
  let resultat = verifFunctionList [] (List.rev prog) (*liste de fonctions et de bas vers le haut donc on inverse pour avoir haut vers bas et main a la fin*)
  in
  (* print_string ("@@@@@@@@@@@@@@@@@@@@\n" ^ 
                "VERIFICATION PROGRAMME: " ^ string_of_bool resultat ^ "\n");*)
  resultat
