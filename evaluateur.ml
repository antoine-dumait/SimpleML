type myType = MInt of int | MBool of bool 
| MFloat of float (*Extension Float*) 
| MUnit (*Extension Unit*)

let mType_to_string = function
  | MBool true -> "true"
  | MBool false -> "false"
  | MInt n -> string_of_int n 
  | MFloat f -> string_of_float f (*Extension Float*)
  | MUnit -> "unit" (*Extension Unit*)

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

  | Syntax.Float f ->
      print_endline (string_of_float f);
      MFloat f
  
  | Syntax.Bool b ->
    print_endline (string_of_bool b);
    MBool b
      
  | Syntax.Unit -> (*Extension Unit*)
    print_endline "unit";
    MUnit

  | Syntax.UnaryOp (op, expr1) -> 
    print_string "unaryOp ";
    let v = eval_expr expr1 envVar envFun in 
      (match op, v with
      | Not, MBool b -> MBool (not b)
      | Print_int, MInt n -> print_endline ("SimpleML: " ^ (string_of_int n)); MUnit (*Extension Affichage*)
      | _, _ -> failwith "unaryOp, inconnu") 
  
  | Syntax.BinaryOp (op, expr1, expr2) -> 
      print_endline "binaryOp ";
      let v1, v2 = eval_expr expr1 envVar envFun, eval_expr expr2 envVar envFun in
      (match op, v1, v2 with
      | Plus, MInt n, MInt m -> MInt (n + m)
      | Plus, MFloat n, MFloat m -> MFloat (n +. m) (*Extension Float*)
      (* | Plus, MInt n, MFloat m -> MFloat (float_of_int n +. m) (*pour ajouter le casting automatique des int en float*)
      | Plus, MFloat n, MInt m -> MFloat (n +. float_of_int m) *)
      
      | Minus, MInt n, MInt m -> MInt (n - m)
      | Minus, MFloat n, MFloat m -> MFloat (n -. m)
      (* | Minus, MInt n, MFloat m -> MFloat (float_of_int n -. m)
      | Minus, MFloat n, MInt m -> MFloat (n -. float_of_int m) *)
      
      | Mult, MInt n, MInt m -> MInt (n * m)
      | Mult, MFloat n, MFloat m -> MFloat (n *. m)
      (* | Mult, MInt n, MFloat m -> MFloat (float_of_int n *. m)
      | Mult, MFloat n, MInt m -> MFloat (n *. float_of_int m) *)
      
      | Div, MInt n, MInt m -> MInt (n / m)
      | Div, MFloat n, MFloat m -> MFloat (n /. m)
      (* | Div, MInt n, MFloat m -> MFloat (float_of_int n /. m)
      | Div, MFloat n, MInt m -> MFloat (n /. float_of_int m) *)
      
      | Equal, MInt n, MInt m -> MBool (n = m)
      | Equal, MFloat n, MFloat m -> MBool (n = m)
      (* | Equal, MInt n, MFloat m -> MBool (float_of_int n = m)
      | Equal, MFloat n, MInt m -> MBool (n = float_of_int m) *)

      | NEqual, MInt n, MInt m -> MBool (n != m)
      | NEqual, MFloat n, MFloat m -> MBool (n != m)
      (* | NEqual, MInt n, MFloat m -> MBool (float_of_int n != m)
      | NEqual, MFloat n, MInt m -> MBool (n != float_of_int m) *)
      
      | Less, MInt n, MInt m -> MBool (n < m)
      | Less, MFloat n, MFloat m -> MBool (n < m)
      (* | Less, MInt n, MFloat m -> MBool (float_of_int n < m)
      | Less, MFloat n, MInt m -> MBool (n < float_of_int m) *)
    
      | LessEq, MInt n, MInt m -> MBool (n <= m)
      | LessEq, MFloat n, MFloat m -> MBool (n <= m)
      (* | LessEq, MInt n, MFloat m -> MBool (float_of_int n <= m)
      | LessEq, MFloat n, MInt m -> MBool (n <= float_of_int m) *)
    
      | Great, MInt n, MInt m -> MBool (n > m)
      | Great, MFloat n, MFloat m -> MBool (n > m)
      (* | Great, MInt n, MFloat m -> MBool (float_of_int n > m)
      | Great, MFloat n, MInt m -> MBool (n > float_of_int m) *)
    
      | GreatEq, MInt n, MInt m -> MBool (n >= m)
      | GreatEq, MFloat n, MFloat m -> MBool (n >= m)
      (* | GreatEq, MInt n, MFloat m -> MBool (float_of_int n >= m)
      | GreatEq, MFloat n, MInt m -> MBool (n >= float_of_int m) *)

      | Seq, MUnit, x -> x 
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
      let rec find = function
        | [] -> failwith "Erreur: fonction non trouvée dans App"
        | f :: reste -> if f.idFun = funId then f else find reste
      in
      let f = find envFun in
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
