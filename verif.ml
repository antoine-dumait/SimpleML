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

  | Syntax.Float f ->
    print_float f;
    print_endline " float";
    voulu = TFloat

  | Syntax.Bool b ->
    print_string (string_of_bool b);
    print_endline "bool";
    voulu = TBool

  | Syntax.Unit -> (*Extension Unit*)
    print_endline "unit";
    voulu = TUnit

  | Syntax.UnaryOp (op, expr1) ->
    print_endline "unaryOp";
    (match op with
    | Not -> verif_expr expr1 TBool envVar envFun
    | Print_int -> verif_expr expr1 TInt envVar envFun) (*Extension Affichage*)

  | Syntax.BinaryOp (op, expr1, expr2) ->
    print_string "binaryOp ";
    (match op with 
    | And | Or -> 
      print_endline "opTBool";
      verif_expr expr1 TBool envVar envFun && verif_expr expr2 TBool envVar envFun
    | Plus |Minus |Mult |Div |Less |LessEq |Great |GreatEq ->  print_endline "opTInt";
      print_endline "opNumeric";
         verif_expr expr1 TInt envVar envFun   && verif_expr expr2 TInt envVar envFun (*Extension Float*)
      || verif_expr expr1 TFloat envVar envFun && verif_expr expr2 TFloat envVar envFun 
      (* || verif_expr expr1 TInt envVar envFun   && verif_expr expr2 TFloat envVar envFun  *) (*pour ajouter le casting automatique des int en float*)
      (* || verif_expr expr1 TFloat envVar envFun && verif_expr expr2 TInt envVar envFun  *)
      |Equal |NEqual -> 
        verif_expr expr1 TInt envVar envFun && verif_expr expr2 TInt envVar envFun 
        || verif_expr expr1 TFloat envVar envFun && verif_expr expr2 TFloat envVar envFun 
        || verif_expr expr1 TBool envVar envFun && verif_expr expr2 TBool envVar envFun 
      | Seq ->  (*Extension Unit*)
      print_endline "opTUnit"; 
      verif_expr expr1 TUnit envVar envFun 
      && (verif_expr expr2 voulu envVar envFun || verif_expr expr2 voulu envVar envFun || verif_expr expr2 voulu envVar envFun)
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
  print_string ("RESULTAT: " ^ fonction.id ^ " = " ^ string_of_bool b ^ "\n");
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
                "VERIFICATION PROGRAMME: " ^ string_of_bool resultat ^ "\n");
  resultat
