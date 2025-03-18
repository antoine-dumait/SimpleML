type myType = MInt of int | MBool of bool

let mType_to_string = function
  | MBool true -> "true"
  | MBool false -> "false"
  | MInt n -> string_of_int n

type typeVar = {
  idVar: Syntax.idvar;
  valeur: myType;
}
type typeFunc = {
  idFun: Syntax.idfun;
  varNames: Syntax.idvar list;
  corps: Syntax.expr;
}

type env_var_type = typeVar list
type env_func_type = typeFunc list

let rec eval_expr expr envVar envFun =
  match expr with
  | Syntax.Var id ->     
      print_string "var ";
      let rec aux = function
        | [] -> failwith "Erreur: variable non trouvée"
        | t :: reste ->
            if t.idVar = id then (
              print_endline (t.idVar ^ ": " ^ mType_to_string t.valeur);
              t.valeur
            ) else aux reste
      in aux envVar
  
  | Syntax.Int n ->
      print_endline (string_of_int n);
      MInt n
  
  | Syntax.Bool b ->
      print_endline (string_of_bool b);
      MBool b
  
  | Syntax.UnaryOp (op, expr) -> 
      print_string "unaryOp ";
      if op = Syntax.Not then (
        print_endline "not";
        match eval_expr expr envVar envFun with
        | MBool b -> MBool (not b)
        | _ -> failwith "Erreur: opérateur unaire invalide"
      ) else failwith "Erreur: seul 'not' est supporté"
  
  | Syntax.BinaryOp (op, expr1, expr2) -> 
      print_endline "binaryOp ";
      let v1, v2 = eval_expr expr1 envVar envFun, eval_expr expr2 envVar envFun in
      (match op, v1, v2 with
      | Syntax.Plus, MInt n, MInt m -> MInt (n + m)
      | Syntax.Minus, MInt n, MInt m -> MInt (n - m)
      | Syntax.Mult, MInt n, MInt m -> MInt (n * m)
      | Syntax.Div, MInt n, MInt m -> MInt (n / m)
      | Syntax.And, MBool b1, MBool b2 -> MBool (b1 && b2)
      | Syntax.Or, MBool b1, MBool b2 -> MBool (b1 || b2)
      | Syntax.Equal, MInt n, MInt m -> MBool (n = m)
      | Syntax.NEqual, MInt n, MInt m -> MBool (n != m)
      | Syntax.Less, MInt n, MInt m -> MBool (n < m)
      | Syntax.LessEq, MInt n, MInt m -> MBool (n <= m)
      | Syntax.Great, MInt n, MInt m -> MBool (n > m)
      | Syntax.GreatEq, MInt n, MInt m -> MBool (n >= m)
      | _ -> failwith "Erreur: opération binaire invalide")
  
  | Syntax.If (b, expr1, expr2) -> 
      print_endline "If";
      (match eval_expr b envVar envFun with 
      | MBool true -> eval_expr expr1 envVar envFun
      | MBool false -> eval_expr expr2 envVar envFun
      | _ -> failwith "Erreur: condition non booléenne")
  
  | Syntax.Let (id, _, exprIn, exprOut) -> 
      print_endline "let";
      let valeur = eval_expr exprIn envVar envFun in
      eval_expr exprOut ({ idVar = id; valeur } :: envVar) envFun
  
  | Syntax.App (funId, exprList) -> 
      print_string "app ";
      let rec find_function = function
        | [] -> failwith "Erreur: fonction non trouvée dans App"
        | f :: reste -> if f.idFun = funId then f else find_function reste
      in
      let f = find_function envFun in
      print_endline f.idFun;
      let paramsEval =
        List.map2 (fun param name -> { idVar = name; valeur = eval_expr param envVar envFun })
          exprList f.varNames
      in
      eval_expr f.corps (paramsEval @ envVar) envFun
      
let eval_prog prog = 
  print_endline "EVALUATION PROGRAMME";
  
  let funcTypes =
    List.map (fun f -> { idFun = f.Syntax.id; varNames = List.map fst f.Syntax.var_list; corps = f.Syntax.corps }) prog
  in
  
  let rec evalMain = function
    | [] -> failwith "Erreur: fonction 'main' non trouvée"
    | f :: reste -> if f.Syntax.id = "main" then eval_expr f.corps [] funcTypes else evalMain reste
  in
  print_endline ("RESULTAT EVALUATION: " ^ mType_to_string (evalMain prog))
