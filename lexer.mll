{
  open Lexing
  open Parser

  exception SyntaxError of string

  let newline lexbuf =
    let pos = lexbuf.lex_curr_p in
      lexbuf.lex_curr_p <-
        { pos with pos_lnum = pos.pos_lnum + 1; pos_bol = pos.pos_cnum }
}

let space = [' ' '\t' '\n' '\r']
let digit = ['0'-'9']
let alpha = ['a'-'z' 'A'-'Z']
let ident = ['a'-'z'] (alpha | '_' | '\'' | digit)*
let integer = digit+
let float = digit+ '.' digit* (* 1.: oui, 0.23: oui, .23: non*) (*Extension Float*)

rule token = parse
  | '\n'  { newline lexbuf; token lexbuf }
  | space  { token lexbuf }
  | "(*"  { comment 0 lexbuf }

  | '=' { EQ }

  | '+'  { PLUS }
  | '-'  { MINUS }
  | '*'  { MULT }
  | '/'  { DIV }

  | "true" { TRUE }
  | "false" { FALSE }
  | "&&" { LAND }
  | "||" { LOR }
  | "not" { NOT }
  | ">" { GREAT }
  | ">=" { GREATEQ }
  | "<" { LESS }
  | "<=" { LESSEQ }
  | "<>" { NEQ }
  | "!=" { NEQ }
  | ";" { SEQ } (*Extension Unit*)

  | "let"  { LET }
  | "in"  { IN }


  | "if" { IF }
  | "then" { THEN }
  | "else" { ELSE }


  | "int" { TINT }
  | "bool" { TBOOL }


  | '('  { LPAR }
  | ')'  { RPAR }
  | ','  { COMMA }
  | ':'  { COLON }

  | '@' {UNIT} (*Extension Unit*)
  
  | "print_int" {PRINT_INT} (*Extension Affichage*)

  | eof  { EOF }


  | integer as n  { INT (int_of_string n) }
  | float as f  { FLOAT (float_of_string f) } (*Extension Float*)
  | ident as id  { VAR id }

  | _  { raise Error }

and comment depth = parse
  | '\n'  { newline lexbuf; comment depth lexbuf }
  | "(*"  { comment (depth + 1) lexbuf }
  | "*)"
    {
      match depth with
      | 0 -> token lexbuf
      | _ -> comment (depth - 1) lexbuf
    }
  | eof     { raise Error }
  | _       { comment depth lexbuf }
