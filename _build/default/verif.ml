let type_list = []
(* let type_list: (String * Syntax.typ) List = [] *)

let add_var_type var_name _ = print_endline var_name
(* let add_var_type var_name var_type = (var_name, var_type)::type_list *)


(* Syntax.expr -> bool *)
let verif_expr expr = match expr with
(* | Syntax.Var var -> let _ = add_var_type var Syntax.TBool in true *)
| Syntax.IdFun id_fun -> add_var_type id_fun Syntax.TBool; let _ = print_endline "in id_fun" in true
| Syntax.Int i -> let _  = print_int i in true
| _ -> let _ = if List.length type_list >= 1 then 
                  print_endline (fst(List.hd type_list)) 
else print_endline "nothing"; print_int (List.length type_list); print_endline ""
               in true


(* | Syntax.IdFun expr -> true
| Syntax.Int expr  -> true
| Syntax.Bool expr -> true
| Syntax.BinaryOp expr -> true
| Syntax.UnaryOp expr  -> true
| Syntax.If expr  -> true
| Syntax.Let expr  -> true
| Syntax.App expr  -> true *)
  (* let _ = print_endline (Syntax.string_of_expr expr) in true *)

(* Syntax.fun-decl -> bool *)
(* TODO: demander prof *)
let verif_decl_fun (fonction: Syntax.fun_decl) = let _ = print_endline fonction.id in 
verif_expr fonction.corps

(* Syntax.programme/Syntax.fun_decl list -> bool *)
let verif_prog prog = 
  let rec aux prog = match prog with 
  | [] -> true
  | fonction::reste -> if verif_decl_fun fonction then aux reste else false
  in aux prog