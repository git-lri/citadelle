(******************************************************************************
 * Generation of Language.C Grammar with ML Interface Binding
 *
 * Copyright (c) 2018-2019 Université Paris-Saclay, Univ. Paris-Sud, France
 *
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above
 *       copyright notice, this list of conditions and the following
 *       disclaimer in the documentation and/or other materials provided
 *       with the distribution.
 *
 *     * Neither the name of the copyright holders nor the names of its
 *       contributors may be used to endorse or promote products derived
 *       from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 ******************************************************************************)

section \<open>Command Interface Definition\<close>

theory C_Command
  imports C_Eval
  keywords "C" :: thy_decl % "ML"
       and "C_file" :: thy_load % "ML"
       and "C_export_boot" :: thy_decl % "ML"
       and "C_prf" :: prf_decl % "proof"  (* FIXME % "ML" ?? *)
       and "C_val" "C_export_file" :: diag % "ML"
begin

subsection \<open>Main Module Interface of Commands\<close>

ML \<comment> \<open>\<^theory>\<open>C.C_Eval\<close>\<close> \<open>
structure C_Module =
struct

structure Data_In_Source = Generic_Data
  (type T = Input.source list
   val empty = []
   val extend = K empty
   val merge = K empty)

structure Data_In_Env = Generic_Data
  (type T = C_Env.env_lang
   val empty = C_Env.empty_env_lang
   val extend = K empty
   val merge = K empty)

structure Data_Accept = Generic_Data
  (type T = C_Ast.CTranslUnit -> C_Env.env_lang -> Context.generic -> Context.generic
   fun empty _ _ = I
   val extend = I
   val merge = #2)

fun env context =
  if Config.get (Context.proof_of context) C_Options.propagate_env
  then Data_In_Env.get context
  else C_Env.empty_env_lang

fun err _ _ pos _ =
  error ("Parser: No matching grammar rule" ^ Position.here pos)

fun accept env_lang (_, (res, _, _)) =
  C_Env.map_context
    (Data_In_Env.put env_lang
     #> (fn context => Data_Accept.get context res env_lang context))

val eval_source = C_Context.eval_source env err accept

fun eval_in ctxt = C_Context.eval_in ctxt env err accept

fun exec_eval source =
  Data_In_Source.map (cons source)
  #> ML_Context.exec (fn () => eval_source source)

fun C_prf source =
  Proof.map_context (Context.proof_map (exec_eval source))
  #> Proof.propagate_ml_env

fun C_export_boot source context =
  context
  |> ML_Env.set_bootstrap true
  |> exec_eval source
  |> ML_Env.restore_bootstrap context
  |> Local_Theory.propagate_ml_env

fun C source =
  exec_eval source
  #> Local_Theory.propagate_ml_env

fun C' err env_lang src =
  C_Env.empty_env_tree
  #> C_Context.eval_source'
       env_lang
       err
       accept
       src
  #> (fn {context, reports_text} => C_Stack.Data_Tree.map (curry C_Stack.Data_Tree_Args.merge reports_text) context)

fun C_export_file context =
  context
  |> Data_In_Source.get
  |> rev
  |> map Input.source_content
  |>  let val thy = Context.theory_of context
          fun check_file_not path =
            tap
              (fn _ =>
                if File.exists path andalso not (File.is_dir path)
                then (if Config.get (Context.proof_of context) C_Options.export_file_exist
                      then error
                      else Output.information)
                       ("Existing file: " ^ Path.print (Path.expand path))
                else ())
              path;
      in
        File.write_list
          (check_file_not (File.full_path (Resources.master_directory thy)
                                          (thy |> Context.theory_name |> Path.explode |> Path.ext "c")))
      end
end
\<close>

subsection \<open>Definitions of Inner Directive Commands\<close>

subsubsection \<open>Initialization\<close>

ML \<comment> \<open>\<^theory>\<open>Pure\<close>\<close> \<open>
local
val _ =
  Theory.setup
  (Context.theory_map
    (C_Context.Directives.map
      (C_Context.directive_update ("define", \<^here>)
        (fn C_Lex.Define (_, C_Lex.Group1 ([], [tok3]), NONE, C_Lex.Group1 ([], toks)) =>
            let val map_ctxt = 
                case (tok3, toks) of
                  (C_Lex.Token (_, (C_Lex.Ident, ident)),
                   [C_Lex.Token (_, (C_Lex.Integer (_, C_Ast.DecRepr0, []), integer))]) =>
                    C_Env.map_context
                      (Context.map_theory
                        (Named_Target.theory_map
                          (Specification.definition_cmd
                            NONE
                            []
                            []
                            ((Binding.make ("", Position.none), []), ident ^ " \<equiv> " ^ integer)
                            true
                           #> tap (fn ((_, (_, t)), ctxt) => Output.information ("Generating " ^ Pretty.string_of (Syntax.pretty_term ctxt (Thm.prop_of t)) ^ Position.here (Position.range_position (C_Lex.pos_of tok3, C_Lex.end_pos_of (List.last toks)))))
                           #> #2)))
                | _ => I
            in fn (env_dir, env_tree) =>
                ( NONE
                , []
                , let val name = C_Lex.content_of tok3
                      val id = serial ()
                      val pos = [C_Lex.pos_of tok3]
                  in
                    ( Symtab.update (name, (pos, id, toks)) env_dir
                    , env_tree |> C_Env.map_reports_text (C_Grammar_Rule_Lib.report pos (C_Context.markup_directive_define true false pos) (name, id))
                               |> map_ctxt)
                  end)
            end
          | C_Lex.Define (_, C_Lex.Group1 ([], [tok3]), SOME (C_Lex.Group1 (_ :: toks_bl, _)), _) =>
              tap (fn _ => (* not yet implemented *)
                           warning ("Ignored functional macro directive" ^ Position.here (Position.range_position (C_Lex.pos_of tok3, C_Lex.end_pos_of (List.last toks_bl)))))
              #> (fn env => (NONE, [], env))
          | _ => fn env => (NONE, [], env))
       #>
       C_Context.directive_update ("undef", \<^here>)
        (fn C_Lex.Undef (C_Lex.Group2 (_, _, [tok])) =>
              (fn (env_dir, env_tree) =>
                ( NONE
                , []
                , let val name = C_Lex.content_of tok
                      val pos1 = C_Lex.pos_of tok
                  in case Symtab.lookup env_dir name of
                       NONE => (env_dir, C_Env.map_reports_text (cons ((pos1, Markup.intensify), "")) env_tree)
                     | SOME (pos0, id, _) =>
                         ( Symtab.delete name env_dir
                         , C_Env.map_reports_text (C_Grammar_Rule_Lib.report [pos1] (C_Context.markup_directive_define false true pos0) (name, id))
                                                  env_tree)
                  end))
          | _ => fn env => (NONE, [], env)))))
in end
\<close>

subsection \<open>Definitions of Inner Annotation Commands\<close>
subsubsection \<open>Library\<close>

ML \<comment> \<open>\<^file>\<open>~~/src/Pure/Isar/toplevel.ML\<close>\<close> \<open>
structure C_Inner_Toplevel =
struct
val theory = Context.map_theory
fun local_theory' target f gthy =
  let
    val (finish, lthy) = Named_Target.switch target gthy;
    val lthy' = lthy
      |> Local_Theory.new_group
      |> f false
      |> Local_Theory.reset_group;
  in finish lthy' end
val generic_theory = I
end
\<close>

ML \<comment> \<open>\<^file>\<open>~~/src/Pure/Isar/isar_cmd.ML\<close>\<close> \<open>
structure C_Inner_Isar_Cmd = 
struct
fun setup0 f_typ f_val src =
 fn NONE =>
    let val setup = "setup"
    in C_Context.expression
        "C_Ast"
        (Input.range_of src)
        setup
        (f_typ "C_Stack.stack_data" "C_Stack.stack_data_elem -> C_Env.env_lang -> Context.generic -> Context.generic")
        ("fn context => \
           \let val (stack, env_lang) = C_Stack.Data_Lang.get context \
           \in " ^ f_val setup "stack" ^ " (stack |> hd) env_lang end context")
        (ML_Lex.read_source false src) end
  | SOME rule => 
    let val hook = "hook"
    in C_Context.expression
        "C_Ast"
        (Input.range_of src)
        hook
        (f_typ "C_Stack.stack_data" (C_Grammar_Rule.type_reduce rule ^ " C_Stack.stack_elem -> C_Env.env_lang -> Context.generic -> Context.generic"))
        ("fn context => \
           \let val (stack, env_lang) = C_Stack.Data_Lang.get context \
           \in " ^ f_val hook "stack" ^ " (stack |> hd |> C_Stack.map_svalue0 C_Grammar_Rule.reduce" ^ Int.toString rule ^ ") env_lang end context")
        (ML_Lex.read_source false src)
    end
val setup = setup0 (fn a => fn b => a ^ " -> " ^ b) (fn a => fn b => a ^ " " ^ b)
val setup' = setup0 (K I) K
end
\<close>

ML \<comment> \<open>\<^file>\<open>~~/src/Pure/Isar/outer_syntax.ML\<close>\<close> \<open>
structure C_Inner_Syntax =
struct
fun command00 f kind scan dir name =
  C_Annotation.command'' kind name ""
    (fn (stack1, (to_delay, stack2)) =>
      C_Parse.range scan >>
        (fn (src, range) =>
          C_Transition.Parsing ((stack1, stack2), (range, dir, Symtab.empty, to_delay, f src))))

fun command00_no_range f kind dir name =
  C_Annotation.command'' kind name ""
    (fn (stack1, (to_delay, stack2)) =>
      Scan.succeed () >>
        K (C_Transition.Parsing ((stack1, stack2), (Position.no_range, dir, Symtab.empty, to_delay, f))))

fun command f = command00 f Keyword.thy_decl
fun command_no_range f = command00_no_range f Keyword.thy_decl

fun command0 f = command (K o f)
fun local_command' spec scan f =
  command (K o (fn (target, arg) => C_Inner_Toplevel.local_theory' target (f arg)))
          (C_Token.syntax' (Parse.opt_target -- scan))
          C_Transition.Bottom_up
          spec
val command0_no_range = command_no_range o K

fun command0' f = command00 (K o f)
end
\<close>

ML \<comment> \<open>\<^file>\<open>~~/src/Pure/ML/ml_file.ML\<close>\<close> \<open>
structure C_Inner_File =
struct

fun command_c ({lines, pos, ...}: Token.file) =
  C_Module.C (Input.source true (cat_lines lines) (pos, pos));

fun C files gthy =
  command_c (hd (files (Context.theory_of gthy))) gthy;

fun command_ml SML debug files gthy =
  let
    val {lines, pos, ...}: Token.file = hd (files (Context.theory_of gthy));
    val source = Input.source true (cat_lines lines) (pos, pos);

    val _ = Thy_Output.check_comments (Context.proof_of gthy) (Input.source_explode source);

    val flags =
      {SML = SML, exchange = false, redirect = true, verbose = true,
        debug = debug, writeln = writeln, warning = warning};
  in
    gthy
    |> ML_Context.exec (fn () => ML_Context.eval_source flags source)
    |> Local_Theory.propagate_ml_env
  end;

val ML = command_ml false;
val SML = command_ml true;
end;
\<close>

subsubsection \<open>Initialization\<close>

setup \<comment> \<open>\<^theory>\<open>Pure\<close>\<close> \<open>
C_Thy_Header.add_keywords_minor
  [ (("apply", \<^here>), ((Keyword.prf_script, []), ["proof"]))
  , (("by", \<^here>), ((Keyword.qed, []), ["proof"]))
  , (("done", \<^here>), ((Keyword.qed_script, []), ["proof"])) ]
\<close>

ML \<comment> \<open>\<^theory>\<open>Pure\<close>\<close> \<open>
local
val semi = Scan.option (C_Parse.$$$ ";");

structure C_Isar_Cmd = 
struct
fun ML source = ML_Context.exec (fn () =>
                   ML_Context.eval_source (ML_Compiler.verbose true ML_Compiler.flags) source) #>
                 Local_Theory.propagate_ml_env

fun theorem schematic ((long, binding, includes, elems, concl), (l_meth, o_meth)) int lthy =
     (if schematic then Specification.schematic_theorem_cmd else Specification.theorem_cmd)
       long Thm.theoremK NONE (K I) binding includes elems concl int lthy
  |> fold (fn m => tap (fn _ => Method.report m) #> Proof.apply m #> Seq.the_result "") l_meth
  |> (case o_meth of
        NONE => Proof.global_done_proof
      | SOME (m1, m2) =>
          tap (fn _ => (Method.report m1; Option.map Method.report m2))
          #> Proof.global_terminal_proof (m1, m2))

fun definition (((decl, spec), prems), params) =
  #2 oo Specification.definition_cmd decl params prems spec

fun declare (facts, fixes) =
  #2 oo Specification.theorems_cmd "" [(Binding.empty_atts, flat facts)] fixes
end

local
val long_keyword =
  Parse_Spec.includes >> K "" ||
  Parse_Spec.long_statement_keyword;

val long_statement =
  Scan.optional (Parse_Spec.opt_thm_name ":" --| Scan.ahead long_keyword) Binding.empty_atts --
  Scan.optional Parse_Spec.includes [] -- Parse_Spec.long_statement
    >> (fn ((binding, includes), (elems, concl)) => (true, binding, includes, elems, concl));

val short_statement =
  Parse_Spec.statement -- Parse_Spec.if_statement -- Parse.for_fixes
    >> (fn ((shows, assumes), fixes) =>
      (false, Binding.empty_atts, [], [Element.Fixes fixes, Element.Assumes assumes],
        Element.Shows shows));
in
fun theorem spec schematic =
  C_Inner_Syntax.local_command'
    spec
    ((long_statement || short_statement)
     -- let val apply = Parse.$$$ "apply" |-- Method.parse
        in Scan.repeat1 apply -- (Parse.$$$ "done" >> K NONE)
        || Scan.repeat apply -- (Parse.$$$ "by" |-- Method.parse -- Scan.option Method.parse >> SOME)
        end)
    (C_Isar_Cmd.theorem schematic)
end

val _ = Theory.setup (   C_Inner_Syntax.command (C_Inner_Toplevel.generic_theory oo C_Inner_Isar_Cmd.setup) C_Parse.ML_source C_Transition.Bottom_up ("\<approx>setup", \<^here>)
                      #> C_Inner_Syntax.command (C_Inner_Toplevel.generic_theory oo C_Inner_Isar_Cmd.setup) C_Parse.ML_source C_Transition.Top_down ("\<approx>setup\<Down>", \<^here>)
                      #> C_Inner_Syntax.command0 (C_Inner_Toplevel.theory o Isar_Cmd.setup) C_Parse.ML_source C_Transition.Bottom_up ("setup", \<^here>)
                      #> C_Inner_Syntax.command0 (C_Inner_Toplevel.theory o Isar_Cmd.setup) C_Parse.ML_source C_Transition.Top_down ("setup\<Down>", \<^here>)
                      #> C_Inner_Syntax.command0 (C_Inner_Toplevel.generic_theory o C_Isar_Cmd.ML) C_Parse.ML_source C_Transition.Bottom_up ("ML", \<^here>)
                      #> C_Inner_Syntax.command0 (C_Inner_Toplevel.generic_theory o C_Isar_Cmd.ML) C_Parse.ML_source C_Transition.Top_down ("ML\<Down>", \<^here>)
                      #> C_Inner_Syntax.command0 (C_Inner_Toplevel.generic_theory o C_Module.C) C_Parse.C_source C_Transition.Bottom_up ("C", \<^here>)
                      #> C_Inner_Syntax.command0 (C_Inner_Toplevel.generic_theory o C_Module.C) C_Parse.C_source C_Transition.Top_down ("C\<Down>", \<^here>)
                      #> C_Inner_Syntax.command0' (C_Inner_Toplevel.generic_theory o C_Inner_File.ML NONE) Keyword.thy_load (C_Resources.parse_files "ML_file" --| semi) C_Transition.Bottom_up ("ML_file", \<^here>)
                      #> C_Inner_Syntax.command0' (C_Inner_Toplevel.generic_theory o C_Inner_File.ML NONE) Keyword.thy_load (C_Resources.parse_files "ML_file\<Down>" --| semi) C_Transition.Top_down ("ML_file\<Down>", \<^here>)
                      #> C_Inner_Syntax.command0' (C_Inner_Toplevel.generic_theory o C_Inner_File.C) Keyword.thy_load (C_Resources.parse_files "C_file" --| semi) C_Transition.Bottom_up ("C_file", \<^here>)
                      #> C_Inner_Syntax.command0' (C_Inner_Toplevel.generic_theory o C_Inner_File.C) Keyword.thy_load (C_Resources.parse_files "C_file\<Down>" --| semi) C_Transition.Top_down ("C_file\<Down>", \<^here>)
                      #> C_Inner_Syntax.command0 (C_Inner_Toplevel.generic_theory o C_Module.C_export_boot) C_Parse.C_source C_Transition.Bottom_up ("C_export_boot", \<^here>)
                      #> C_Inner_Syntax.command0 (C_Inner_Toplevel.generic_theory o C_Module.C_export_boot) C_Parse.C_source C_Transition.Top_down ("C_export_boot\<Down>", \<^here>)
                      #> C_Inner_Syntax.command0_no_range (C_Inner_Toplevel.generic_theory o tap C_Module.C_export_file) C_Transition.Bottom_up ("C_export_file", \<^here>)
                      #> C_Inner_Syntax.command0_no_range (C_Inner_Toplevel.generic_theory o tap C_Module.C_export_file) C_Transition.Top_down ("C_export_file\<Down>", \<^here>)
                      #> C_Inner_Syntax.command_no_range
                           (C_Inner_Toplevel.generic_theory oo C_Inner_Isar_Cmd.setup
                             \<open>fn ((_, (_, pos1, pos2)) :: _) =>
                                  (fn _ => fn _ =>
                                    tap (fn _ =>
                                          Position.reports_text [((Position.range (pos1, pos2)
                                                                   |> Position.range_position, Markup.intensify), "")]))
                               | _ => fn _ => fn _ => I\<close>)
                           C_Transition.Bottom_up
                           ("highlight", \<^here>)
                      #> theorem ("theorem", \<^here>) false
                      #> theorem ("lemma", \<^here>) false
                      #> theorem ("corollary", \<^here>) false
                      #> theorem ("proposition", \<^here>) false
                      #> theorem ("schematic_goal", \<^here>) true
                      #> C_Inner_Syntax.local_command'
                          ("definition", \<^here>)
                          (Scan.option Parse_Spec.constdecl -- (Parse_Spec.opt_thm_name ":" -- Parse.prop) --
                            Parse_Spec.if_assumes -- Parse.for_fixes)
                          C_Isar_Cmd.definition
                      #> C_Inner_Syntax.local_command'
                          ("declare", \<^here>)
                          (Parse.and_list1 Parse.thms1 -- Parse.for_fixes)
                          C_Isar_Cmd.declare)
in end
\<close>

subsection \<open>Definitions of Outer Commands\<close>
subsubsection \<open>Library\<close>
(*  Author:     Frédéric Tuong, Université Paris-Saclay *)
(*  Title:      Pure/Pure.thy
    Author:     Makarius

The Pure theory, with definitions of Isar commands and some lemmas.
*)

ML \<comment> \<open>\<^file>\<open>~~/src/Pure/Isar/parse.ML\<close>\<close> \<open>
structure C_Outer_Parse =
struct
  val C_source = Parse.input (Parse.group (fn () => "C source") Parse.text)
end
\<close>

ML \<comment> \<open>\<^file>\<open>~~/src/Pure/Isar/outer_syntax.ML\<close>\<close> \<open>
structure C_Outer_Syntax =
struct
val _ =
  Outer_Syntax.command \<^command_keyword>\<open>C\<close> ""
    (C_Outer_Parse.C_source >> (Toplevel.generic_theory o C_Module.C));
end
\<close>

ML \<comment> \<open>\<^file>\<open>~~/src/Pure/Isar/isar_cmd.ML\<close>\<close> \<open>
structure C_Outer_Isar_Cmd =
struct
(* diagnostic ML evaluation *)

structure Diag_State = Proof_Data
(
  type T = Toplevel.state;
  fun init _ = Toplevel.toplevel;
);

fun C_diag source state =
  let
    val opt_ctxt =
      try Toplevel.generic_theory_of state
      |> Option.map (Context.proof_of #> Diag_State.put state);
  in Context.setmp_generic_context (Option.map Context.Proof opt_ctxt)
    (fn () => C_Module.eval_source source) () end;

val diag_state = Diag_State.get;
val diag_goal = Proof.goal o Toplevel.proof_of o diag_state;

val _ = Theory.setup
  (ML_Antiquotation.value (Binding.qualify true "Isar" \<^binding>\<open>C_state\<close>)
    (Scan.succeed "C_Outer_Isar_Cmd.diag_state ML_context") #>
   ML_Antiquotation.value (Binding.qualify true "Isar" \<^binding>\<open>C_goal\<close>)
    (Scan.succeed "C_Outer_Isar_Cmd.diag_goal ML_context"));

end
\<close>

ML \<comment> \<open>\<^file>\<open>~~/src/Pure/ML/ml_file.ML\<close>\<close> \<open>
structure C_Outer_File =
struct

fun command_c ({src_path, lines, digest, pos}: Token.file) =
  let
    val provide = Resources.provide (src_path, digest);
  in I
    #> C_Module.C (Input.source true (cat_lines lines) (pos, pos))
    #> Context.mapping provide (Local_Theory.background_theory provide)
  end;

fun C files gthy =
  command_c (hd (files (Context.theory_of gthy))) gthy;

end;
\<close>

subsubsection \<open>Initialization\<close>

ML \<comment> \<open>\<^theory>\<open>Pure\<close>\<close> \<open>
local

val semi = Scan.option \<^keyword>\<open>;\<close>;

val _ =
  Outer_Syntax.command \<^command_keyword>\<open>C_file\<close> "read and evaluate Isabelle/C file"
    (Resources.parse_files "C_file" --| semi >> (Toplevel.generic_theory o C_Outer_File.C));

val _ =
  Outer_Syntax.command \<^command_keyword>\<open>C_export_boot\<close>
    "C text within theory or local theory, and export to bootstrap environment"
    (C_Outer_Parse.C_source >> (Toplevel.generic_theory o C_Module.C_export_boot));

val _ =
  Outer_Syntax.command \<^command_keyword>\<open>C_prf\<close> "C text within proof"
    (C_Outer_Parse.C_source >> (Toplevel.proof o C_Module.C_prf));

val _ =
  Outer_Syntax.command \<^command_keyword>\<open>C_val\<close> "diagnostic C text"
    (C_Outer_Parse.C_source >> (Toplevel.keep o C_Outer_Isar_Cmd.C_diag));

val _ =
  Outer_Syntax.command \<^command_keyword>\<open>C_export_file\<close> "diagnostic C text"
    (Scan.succeed () >> K (Toplevel.keep (Toplevel.generic_theory_of #> C_Module.C_export_file)));
in end\<close>

end
