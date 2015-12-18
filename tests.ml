open OUnit2

let test_snake_case =
  let t (s, r) =
    let name =
      Printf.sprintf "is_snake_case %S?" s
    in
    name >:: fun ctxt ->
      assert_equal r (Rules.is_snake_case s)
  in
  List.map t
    [ "ident", true
    ; "some_ident", true
    ; "someIdent", false
    ]

let expr_to_string expr =
  let b = Buffer.create 0 in
  let fmt = Format.formatter_of_buffer b in
  Printast.expression 0 fmt expr;
  Format.pp_print_flush fmt ();
  Buffer.contents b

let test_style =
  let t (expr, r) =
    let name =
      Printf.sprintf "Rate %s" (expr_to_string expr)
    in
    name >:: fun ctxt ->
      assert_equal
        ~ctxt
        ~cmp:[%eq:string option]
        ~printer:[%show:string option]
        r
        (Rules.rate_expression expr)
  in
  List.map t
    [ [%expr List.map f [2] ], Some "List.map on singleton"
    ; [%expr List.fold_left f z [2] ], Some "List.fold_left on singleton"
    ; [%expr List.fold_right f [2] z ], Some "List.fold_right on singleton"
    ; [%expr String.sub s 0 i ], Some "Use Str.first_chars"
    ; [%expr String.sub s i (String.length s - i) ], Some "Use Str.string_after"
    ; [%expr String.sub s (String.length s - i) i ], Some "Use Str.last_chars"
    ; [%expr List.length l > 0 ], Some "Use <> []"
    ; [%expr List.length l = 0 ], Some "Use = []"
    ; [%expr result = true ], Some "Useless comparison to boolean"
    ; [%expr (fun x -> x + 1) 2], Some "Use let/in"
    ; [%expr x := !x + 1], Some "Use incr"
    ; [%expr x := !x - 1], Some "Use decr"
    ; [%expr let x = 3 in x ], Some "Useless let"
    ; [%expr [3;14] @ [15;92] ], Some "Merge list litterals"
    ; [%expr [1] @ [61;80] ], Some "Use ::"
    ; [%expr match None with Some _ -> 1 | None -> 2 ], Some "Match on constant or constructor"
    ; [%expr match x with Some _ -> true | None -> true ], Some "Useless match"
    ; [%expr let _ = List.map f xs in e ], Some "Use List.iter"
    ; [%expr Printf.sprintf "hello" ], Some "Useless sprintf"
    ; [%expr Printf.sprintf "%s" "world" ], Some "Useless sprintf %s"
    ]

let suite =
  "Tests" >:::
  [ "Snake case" >::: test_snake_case
  ; "Style" >::: test_style
  ]

let _ =
  run_test_tt_main suite