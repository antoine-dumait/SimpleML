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

let bool_to_string b = if b then "true" else "false"

let rec verif_expr expr voulu envVar envFun =
  match expr with
  | Syntax.Var id ->
    print_endline "var";
    let rec aux env =
      match env with
      | [] -> false
      | t :: reste ->
        if t.idVar = id then t.valeur = voulu
        else aux reste
    in
    aux envVar

  | Syntax.Int n ->
    print_int n;
    print_endline " int";
    voulu = TInt

  | Syntax.Bool b ->
    print_string (bool_to_string b);
    print_endline "bool";
    voulu = TBool

  | Syntax.UnaryOp (_, expr1) ->
    print_endline "unaryOp";
    verif_expr expr1 TBool envVar envFun

  | Syntax.BinaryOp (op, expr1, expr2) ->
    print_string "binaryOp ";
    if op = And || op = Or then (
      print_endline "TBool";
      verif_expr expr1 TBool envVar envFun && verif_expr expr2 TBool envVar envFun
    ) else (
      print_endline "TInt";
      verif_expr expr1 TInt envVar envFun && verif_expr expr2 TInt envVar envFun
    )

  | Syntax.If (b, expr1, expr2) ->
    print_endline "if";
    verif_expr b TBool envVar envFun &&
    ((verif_expr expr1 TBool envVar envFun && verif_expr expr2 TBool envVar envFun) ||
     (verif_expr expr1 TInt envVar envFun && verif_expr expr2 TInt envVar envFun))

  | Syntax.Let (id, ty, exprIn, exprOut) ->
    print_endline "let";
    if verif_expr exprIn ty envVar envFun then
      verif_expr exprOut voulu ({idVar=id; valeur=ty}::envVar) envFun
    else false

  | Syntax.App (funId, exprList) ->
    print_endline "app";
    let rec aux env =
      match env with
      | [] -> false
      | t :: reste ->
        if t.idFun = funId then
          if t.valeur = voulu then
            let rec aux_params p l =
              match (p, l) with
              | [], [] -> true
              | [], _ | _, [] -> false (*une liste mais pas l'autre donc pas bon*)
              | typeParam :: resteParams, expr :: resteExpr ->
                verif_expr expr typeParam envVar envFun && aux_params resteParams resteExpr
            in
            aux_params t.params exprList
          else false
        else aux reste
    in
    aux envFun

let verif_decl_fun (fonction: Syntax.fun_decl) envVar envFun =
  print_string ("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@\n"
                ^ Syntax.string_of_fun_decl fonction
                ^ "\n----------------------------------------\n");
  let b = verif_expr fonction.corps fonction.typ_retour envVar envFun in
  print_string ("RESULTAT: " ^ fonction.id ^ " = " ^ bool_to_string b ^ "\n");
  b

let verif_prog prog =
  print_string ("Programme à vérifier:\n"
                ^ "-----------------------------------------------------------------\n"
                ^ Syntax.string_of_programme prog
                ^ "--------------------------------------------------------------------------\n");
  
  let rec getparamsTypes idVarTypList =
    match idVarTypList with
    | [] -> []
    | (id, typ) :: reste -> { idVar = id; valeur = typ } :: getparamsTypes reste
  in
  
  let rec verifFunctions prog =
    match prog with
    | [] -> true
    | fonction :: reste ->
      if fonction.Syntax.id = "main" then verifFunctions reste
      else verif_decl_fun fonction (getparamsTypes fonction.Syntax.var_list) []
  in
  
  let functionsTypeForMain =
    let rec second p =
      match p with
      | [] -> []
      | (_, typ) :: reste -> typ :: second reste
    in
    let rec aux funcDeclList =
      match funcDeclList with
      | [] -> []
      | funDec :: reste ->
        { idFun = funDec.Syntax.id;
          params = second funDec.Syntax.var_list;
          valeur = funDec.Syntax.typ_retour } :: aux reste
    in
    aux prog
  in
  
  let rec verifMain prog =
    match prog with
    | [] -> false
    | fonction :: reste ->
      if fonction.Syntax.id = "main" then verif_decl_fun fonction [] functionsTypeForMain (*aucune variable mais possible appeler autre fonction*)
      else verifMain reste
  in
  
  let resultat = if verifFunctions prog then verifMain prog else false in
  print_string ("@@@@@@@@@@@@@@@@@@@@\n" ^ 
                "VERIFICATION PROGRAMME: " ^ bool_to_string resultat ^ "\n");
  resultat
