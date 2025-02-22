(******************************************************************************
 * Citadelle
 *
 * Copyright (c) 2011-2018 Université Paris-Saclay, Univ. Paris-Sud, France
 *               2013-2017 IRT SystemX, France
 *               2011-2015 Achim D. Brucker, Germany
 *               2016-2018 The University of Sheffield, UK
 *               2016-2017 Nanyang Technological University, Singapore
 *               2017-2018 Virginia Tech, USA
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

section\<open>Regrouping Together All Existing Meta-Models\<close>

theory  Meta_META
imports Meta_UML
        Meta_UML_extended
        Meta_HKB
        "../../compiler_generic/meta_isabelle/Meta_Isabelle"
begin

subsection\<open>A Basic Meta-Model\<close>

text\<open>The following basic Meta-Model is an empty Meta-Model.\<close>

text\<open>Most of the Meta-Model we have defined (in particular those defined in UML)
     can be used in exceptional situations
     for requiring an eager or lazy interactive evaluation of already encountered Meta-Models.
     This is also the case for this basic Meta-Model.\<close>

datatype ocl_flush_all = OclFlushAll

subsection\<open>The Generic Meta-Model\<close>

text\<open>The generic Meta-Model can simulate any other Meta-Models \<open>M\<close> by taking a string representing
     some ML code, which is supposed to express a parsed value inhabiting \<open>M\<close>.\<close>

datatype ocl_generic = OclGeneric string

subsection\<open>The META Meta-Model (I)\<close>

datatype floor = Floor1 | Floor2 | Floor3 (* NOTE nat can be used *)

text\<open>
Meta-Models can be seen as arranged in a semantic tower with several floors.
By default, @{term Floor1} corresponds to the first level we are situating by default,
then a subsequent meta-evaluation would jump to a deeper floor,
to @{term Floor2}, then @{term Floor3}...\<close>

text\<open>
It is not mandatory to jump to a floor superior than the one we currently are.
The important point is to be sure that all jumps will ultimately terminate.\<close>

(* *)

text\<open>
Most of the following constructors are preceded by an additional
@{typ floor} field, which explicitly indicates the intended associated semantic to consider
during the meta-embedding to Isabelle.
In case no @{typ floor} is precised, we fix it to be @{term Floor1} by default.\<close>

(* le meta-model de "tout le monde" - frederic. *)
datatype all_meta_embedding =
  (* TODO: we can merge Enum and ClassRaw into a common record *)

                              \<comment> \<open>USE\<close>
                              META_enum ocl_enum
                            | META_class_raw floor ocl_class_raw
                            | META_association ocl_association
                            | META_ass_class floor ocl_ass_class
                            | META_ctxt floor ocl_ctxt

                              \<comment> \<open>Haskell\<close>
                            | META_haskell IsaUnit

                              \<comment> \<open>invented\<close>
                            | META_class_synonym ocl_class_synonym
                            | META_instance ocl_instance
                            | META_def_base_l ocl_def_base_l
                            | META_def_state floor ocl_def_state
                            | META_def_transition floor ocl_def_transition
                            | META_class_tree ocl_class_tree
                            | META_flush_all ocl_flush_all
                            | META_generic ocl_generic

subsection\<open>Main Compiling Environment\<close>

text\<open>The environment constitutes the main data-structure carried by all monadic translations.\<close>

datatype generation_semantics_ocl = Gen_only_design | Gen_only_analysis | Gen_default
datatype generation_lemma_mode = Gen_sorry | Gen_no_dirty

record compiler_env_config =  D_output_disable_thy :: bool
                              D_output_header_thy :: "(string \<comment> \<open>theory\<close>
                                                      \<times> string list \<comment> \<open>imports\<close>
                                                      \<times> string \<comment> \<open>import optional (compiler bootstrap)\<close>) option"
                              D_ocl_oid_start :: internal_oids
                              D_output_position :: "nat \<times> nat"
                              D_ocl_semantics :: generation_semantics_ocl
                              D_input_class :: "ocl_class option"
                                               \<comment> \<open>last class considered for the generation\<close>
                              D_input_meta :: "all_meta_embedding list"
                              D_input_instance :: "(string\<^sub>b\<^sub>a\<^sub>s\<^sub>e \<comment> \<open>name (as key for rbt)\<close>
                                                   \<times> ocl_instance_single
                                                   \<times> internal_oids) list"
                                                  \<comment> \<open>instance namespace environment\<close>
                              D_input_state :: "(string\<^sub>b\<^sub>a\<^sub>s\<^sub>e \<comment> \<open>name (as key for rbt)\<close>
                                                \<times> (internal_oids
                                                \<times> (string \<comment> \<open>name\<close>
                                                  \<times> ocl_instance_single \<comment> \<open>alias\<close>)
                                                  ocl_def_state_core) list) list"
                                               \<comment> \<open>state namespace environment\<close>
                              D_output_header_force :: bool \<comment> \<open>true : the header should import the compiler for bootstrapping\<close>
                              D_output_auto_bootstrap :: bool \<comment> \<open>true : add the \<open>generation_syntax\<close> command\<close>
                              D_ocl_accessor :: " string\<^sub>b\<^sub>a\<^sub>s\<^sub>e \<comment> \<open>name of the constant added\<close> list \<comment> \<open>pre\<close>
                                                \<times> string\<^sub>b\<^sub>a\<^sub>s\<^sub>e \<comment> \<open>name of the constant added\<close> list \<comment> \<open>post\<close>"
                              D_ocl_HO_type :: "(string\<^sub>b\<^sub>a\<^sub>s\<^sub>e \<comment> \<open>raw HOL name (as key for rbt)\<close>) list"
                              D_hsk_constr :: "(string\<^sub>b\<^sub>a\<^sub>s\<^sub>e \<comment> \<open>name of the constant added\<close>) list"
                              D_output_sorry_dirty :: "generation_lemma_mode option \<times> bool \<comment> \<open>dirty\<close>" \<comment> \<open>\<open>Some Gen_sorry\<close> or \<open>None\<close> and \<open>{dirty}\<close>: activate sorry mode for skipping proofs\<close>

subsection\<open>Operations of Fold, Map, ..., on the Meta-Model\<close>

definition "ignore_meta_header = (\<lambda> META_ctxt Floor1 _ \<Rightarrow> True
                                  | META_def_state Floor1 _ \<Rightarrow> True
                                  | META_def_transition Floor1 _ \<Rightarrow> True
                                  | _ \<Rightarrow> False)"

text\<open>
As remark in @{term ignore_meta_header}, @{term META_class_raw} and @{term META_ass_class} do not occur,
even if the associated meta-commands will be put at the beginning when generating files during the reordering step.
This is because some values for which @{term ignore_meta_header} returns @{term False} can exist just before
meta-commands associated to @{term META_class_raw} or @{term META_ass_class}.
\<close>

definition "map2_ctxt_term f =
 (let f_prop = \<lambda> OclProp_ctxt n prop \<Rightarrow> OclProp_ctxt n (f prop)
    ; f_inva = \<lambda> T_inv b prop \<Rightarrow> T_inv b (f_prop prop) in
  \<lambda> META_ctxt Floor2 c \<Rightarrow>
    META_ctxt Floor2
      (Ctxt_clause_update
        (L.map (\<lambda> Ctxt_pp pp \<Rightarrow> Ctxt_pp (Ctxt_expr_update (L.map (\<lambda> T_pp pref prop \<Rightarrow> T_pp pref (f_prop prop)
                                                                        | T_invariant inva \<Rightarrow> T_invariant (f_inva inva))) pp)
                   | Ctxt_inv l_inv \<Rightarrow> Ctxt_inv (f_inva l_inv))) c)
  | x \<Rightarrow> x)"

definition "compiler_env_config_more_map f ocl =
            compiler_env_config.extend  (compiler_env_config.truncate ocl) (f (compiler_env_config.more ocl))"

definition "compiler_env_config_empty output_disable_thy output_header_thy oid_start design_analysis sorry_dirty =
  compiler_env_config.make
    output_disable_thy
    output_header_thy
    oid_start
    (0, 0)
    design_analysis
    None [] [] [] False False ([], []) [] []
    sorry_dirty"

definition "compiler_env_config_reset_no_env env =
  compiler_env_config_empty
    (D_output_disable_thy env)
    (D_output_header_thy env)
    (oidReinitAll (D_ocl_oid_start env))
    (D_ocl_semantics env)
    (D_output_sorry_dirty env)
    \<lparr> D_input_meta := D_input_meta env \<rparr>"

subsection\<open>The META Meta-Model (II)\<close>
subsubsection\<open>Type Definition\<close>

text\<open>
For bootstrapping the environment through the jumps to another semantic floor, we additionally
consider the environment as a Meta-Model.\<close>

datatype boot_generation_syntax = Boot_generation_syntax generation_semantics_ocl
datatype boot_setup_env = Boot_setup_env compiler_env_config

datatype all_meta = \<comment> \<open>pure Isabelle\<close>
                    META_semi__theories semi__theories

                    \<comment> \<open>bootstrapping embedded languages\<close>
                  | META_boot_generation_syntax boot_generation_syntax
                  | META_boot_setup_env boot_setup_env
                  | META_all_meta_embedding all_meta_embedding

text\<open>As remark, the Isabelle Meta-Model represented by @{typ semi__theories} can be merged
with the previous META Meta-Model @{typ all_meta_embedding}.
However a corresponding parser and printer would then be required, instead we can just regroup them
in a temporary type:\<close>

datatype fold_all_input = Fold_meta all_meta_embedding
                        | Fold_custom "all_meta list"

subsubsection\<open>Extending the Meta-Model\<close>

locale O \<comment> \<open>outer syntax\<close>
begin
definition "i x = META_semi__theories o Theories_one o x"
definition "datatype = i Theory_datatype"
definition "type_synonym = i Theory_type_synonym"
definition "type_notation = i Theory_type_notation"
definition "instantiation = i Theory_instantiation"
definition "overloading = i Theory_overloading"
definition "consts = i Theory_consts"
definition "definition = i Theory_definition"
definition "lemmas = i Theory_lemmas"
definition "lemma = i Theory_lemma"
definition "axiomatization = i Theory_axiomatization"
definition "section = i Theory_section"
definition "text = i Theory_text"
definition "text_raw = i Theory_text_raw"
definition "ML = i Theory_ML"
definition "setup = i Theory_setup"
definition "thm = i Theory_thm"
definition "interpretation = i Theory_interpretation"
definition "hide_const = i Theory_hide_const"
definition "abbreviation = i Theory_abbreviation"
definition "code_reflect' = i Theory_code_reflect'"
end

lemmas [code] =
  \<comment> \<open>def\<close>
  O.i_def
  O.datatype_def
  O.type_synonym_def
  O.type_notation_def
  O.instantiation_def
  O.overloading_def
  O.consts_def
  O.definition_def
  O.lemmas_def
  O.lemma_def
  O.axiomatization_def
  O.section_def
  O.text_def
  O.text_raw_def
  O.ML_def
  O.setup_def
  O.thm_def
  O.interpretation_def
  O.hide_const_def
  O.abbreviation_def
  O.code_reflect'_def

locale O'
begin
definition "datatype = Theory_datatype"
definition "type_synonym = Theory_type_synonym"
definition "type_notation = Theory_type_notation"
definition "instantiation = Theory_instantiation"
definition "overloading = Theory_overloading"
definition "consts = Theory_consts"
definition "definition = Theory_definition"
definition "lemmas = Theory_lemmas"
definition "lemma = Theory_lemma"
definition "axiomatization = Theory_axiomatization"
definition "section = Theory_section"
definition "text = Theory_text"
definition "ML = Theory_ML"
definition "setup = Theory_setup"
definition "thm = Theory_thm"
definition "interpretation = Theory_interpretation"
definition "hide_const = Theory_hide_const"
definition "abbreviation = Theory_abbreviation"
definition "code_reflect' = Theory_code_reflect'"
end

lemmas [code] =
  \<comment> \<open>def\<close>
  O'.datatype_def
  O'.type_synonym_def
  O'.type_notation_def
  O'.instantiation_def
  O'.overloading_def
  O'.consts_def
  O'.definition_def
  O'.lemmas_def
  O'.lemma_def
  O'.axiomatization_def
  O'.section_def
  O'.text_def
  O'.ML_def
  O'.setup_def
  O'.thm_def
  O'.interpretation_def
  O'.hide_const_def
  O'.abbreviation_def
  O'.code_reflect'_def

subsubsection\<open>Operations of Fold, Map, ..., on the Meta-Model\<close>

definition "map_semi__theory f = (\<lambda> META_semi__theories (Theories_one x) \<Rightarrow> META_semi__theories (Theories_one (f x))
                                  | META_semi__theories (Theories_locale data l) \<Rightarrow> META_semi__theories (Theories_locale data (L.map (L.map f) l))
                                  | x \<Rightarrow> x)"

end
