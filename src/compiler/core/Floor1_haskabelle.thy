(******************************************************************************
 * HOL-HKB
 *
 * Copyright (c) 2017-2018 Virginia Tech, USA
 *               2018-2019 Université Paris-Saclay, Univ. Paris-Sud, France
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

section\<open>Main Translation for: Haskabelle\<close>

theory  Floor1_haskabelle
imports Core_init
begin

definition "gen_zero s = s @@ \<open>0\<close>"

definition "hsk_name0 flatten = (\<lambda> l_name.
 \<lambda> Name n \<Rightarrow> n
 | QName (ThyName n0) n1 \<Rightarrow> 
    (case List.find (\<lambda>(n1, _). n0 \<triangleq> n1) l_name of
       None \<Rightarrow> flatten n0 n1
     | Some (_, Some n0) \<Rightarrow> flatten n0 n1
     | Some (_, None) \<Rightarrow> n1))"

definition "hsk_name = hsk_name0 (\<lambda> n0 n1. S.flatten [n0, \<open>.\<close>, n1])"
definition "hsk_name' names = mk_quote o hsk_name names"
definition "hsk_name'' = hsk_name0 (\<lambda> _. id)"

fun hsk_type where
   "hsk_type names e =
 (\<lambda> Type n [] \<Rightarrow> Typ_base (hsk_name names n)
  | Type n l \<Rightarrow> Typ_apply (Typ_base (hsk_name names n)) (map (hsk_type names) l)
  | Func t1 t2 \<Rightarrow> Typ_apply (hsk_type names t1) [hsk_type names t2]
  | TVar n \<Rightarrow> Typ_base (hsk_name' names n)) e"

definition "hsk_typespec names = (\<lambda> TypeSpec l n \<Rightarrow> (hsk_name names n, L.map (hsk_name' names) l))"

definition "hsk_typesign names = (\<lambda>TypeSign n _ _ \<Rightarrow> hsk_name names n)"

definition "hsk_literal str = (\<lambda> String s \<Rightarrow> str s
                               | Meta_HKB.Int n \<Rightarrow> Term_basic [String.natural_to_digit10 n])"

record lexical = lex_list_cons :: string
                 lex_bool_false :: string
                 lex_string :: "string \<Rightarrow> semi__term"

fun hsk_term and
    hsk_term_app where
   "hsk_term lexi names t =
 (\<lambda> Literal l \<Rightarrow> hsk_literal (lex_string lexi) l
  | Const n \<Rightarrow> 
      let f = \<lambda> (). Term_basic [hsk_name names n] in
      (case n of QName (ThyName s1) s2 \<Rightarrow>
                   if s1 \<triangleq> \<open>List\<close> & s2 \<triangleq> \<open>Nil\<close> then Term_list []
                   else if s1 \<triangleq> \<open>HOL\<close> & s2 \<triangleq> \<open>False\<close> then Term_basic [lex_bool_false lexi]
                   else f ()
               | _ \<Rightarrow> f ())
  | App t1 t2 \<Rightarrow>
      let t2 = hsk_term lexi names t2
        ; f = \<lambda> (). hsk_term_app lexi names [t2] t1 in
      (case t1 of
         App (Const (QName (ThyName s1) s2)) t12 \<Rightarrow>
           let t12 = \<lambda> (). hsk_term lexi names t12 in
           if s1 \<triangleq> \<open>Product_Type\<close> & s2 \<triangleq> \<open>Pair\<close> then Term_pair (t12 ()) t2
           else if s1 \<triangleq> \<open>Prelude\<close> & s2 \<triangleq> \<open>#\<close> then Term_parenthesis (Term_binop (t12 ()) (lex_list_cons lexi) t2)
           else f ()
       | _ \<Rightarrow> f ())
  | Parenthesized t \<Rightarrow> hsk_term lexi names t) t"
 | "hsk_term_app lexi names l t = (\<lambda> App t1 t2 \<Rightarrow> hsk_term_app lexi names (hsk_term lexi names t2 # l) t1
                                   | e \<Rightarrow> Term_parenthesis (Term_apply (hsk_term lexi names e) l)) t"

definition "hsk_stmt version names app_end =
 (let b = \<lambda>s. Term_basic [s] in
  map_prod concat concat o L.split o map
   (\<lambda> Meta_HKB.Datatype l \<Rightarrow>
        let l_data = L.map (map_prod (hsk_typespec names) (L.map (map_prod (hsk_name names) (L.map (hsk_type names))))) l
          ; l_data' = concat (L.map (L.map (\<lambda>(s, _). (s, gen_zero s)) o snd) l_data) in
        ( O.datatype (Datatype version (L.map (map_prod id (L.map (map_prod gen_zero id))) l_data))
          # (* For each constructor, we additionally generate an alias definition, for it to be used
               in the SML code generated part as an alternative of the SML generated constructor:
               its type will be not curried (whereas the SML type of the constructor will be). *)
            L.map (\<lambda>(s, s'). O.definition (Definition (Term_rewrite (b s) \<open>=\<close> (b s')))) l_data'
        , L.map fst l_data')
    | TypeSynonym [(t0, t1)] \<Rightarrow> ([O.type_synonym (Type_synonym (hsk_typespec names t0) (hsk_type names t1))], [])
    | Function (Function_Stmt Meta_HKB.Definition [t] [((lhs_n, lhs_arg), rhs)]) \<Rightarrow>
        let s_empty = b \<open>v\<close>
          ; T_string = Term_string'
          ; hsk_term = hsk_term \<lparr> lex_list_cons = \<open>#\<close>, lex_bool_false = \<open>False\<close>, lex_string = (\<lambda>s. if s \<triangleq> \<open>\<close> then s_empty else T_string s) \<rparr> names in
        ( [(O.definition o Definition)
            (Term_rewrite (Term_app (hsk_name'' names lhs_n) (map hsk_term lhs_arg))
                          \<open>=\<close>
                          (let t = Term_parenthesis (Term_let [(s_empty, T_string \<open>\<close>)] (hsk_term rhs)) in
                           case app_end of Gen_apply_hol f \<Rightarrow> Term_app f [t]
                                         | _ \<Rightarrow> t))]
        , [])
    | Meta_HKB.SML (Function_Stmt Meta_HKB.Definition [t] [((lhs_n, lhs_arg), rhs)]) \<Rightarrow>
        let s_empty = b \<open>v\<close>
          ; f_content = b \<open>content\<close>
          ; T_string = Term_string'' f_content
          ; hsk_term = hsk_term \<lparr> lex_list_cons = \<open>::\<close>, lex_bool_false = \<open>false\<close>, lex_string = (\<lambda>s. if s \<triangleq> \<open>\<close> then s_empty else T_string s) \<rparr> names in
        ( (O.ML o SML o SML_top)
            [SML_val_fun
               (Some Sval)
               (hol_to_sml (Term_rewrite (Term_app (hsk_name'' names lhs_n) (map hsk_term lhs_arg))
                                         \<open>=\<close>
                                         (let t = Term_parenthesis (Term_let [ (f_content, term_binop \<open>o\<close> (map b [\<open>SS_base\<close>, \<open>ST\<close>, \<open>Input.source_content\<close>]))
                                                                             , (s_empty, T_string \<open>\<close>)]
                                                                             (hsk_term rhs)) in
                                          case app_end of Gen_apply_sml f \<Rightarrow> Term_app f [t]
                                                        | Gen_apply_sml_cmd f _ \<Rightarrow> Term_app f [t]
                                                        | _ \<Rightarrow> t)))]
          # (case app_end of Gen_apply_sml_cmd _ s \<Rightarrow>
                              [(META_all_meta_embedding o META_generic o OclGeneric) s]
                           | _ \<Rightarrow> [])
        , [])
    | _ \<Rightarrow> ([], [])))"

definition "print_haskell = (\<lambda> IsaUnit version l_name app_end name_new (l_mod, b_concat) \<Rightarrow> \<lambda>env.
  (map_prod concat ((\<lambda>l1. D_hsk_constr_update (\<lambda>l0. l0 @ l1) env) o L.map String.to_String\<^sub>b\<^sub>a\<^sub>s\<^sub>e o concat)
   o L.split
   o map
    (\<lambda> Module (ThyName name_old) _ m _ \<Rightarrow>
         hsk_stmt (case map_prod id nat_of_natural version of (False, _) \<Rightarrow> Datatype_new
                                                            | (True, 0) \<Rightarrow> Datatype_old
                                                            | (True, Suc 0) \<Rightarrow> Datatype_old_atomic
                                                            | (True, Suc (Suc 0)) \<Rightarrow> Datatype_old_atomic_sub)
                  ((name_old, Some name_new) # l_name)
                  app_end
                  m))
    (if b_concat then l_mod else [last l_mod]))"

end
