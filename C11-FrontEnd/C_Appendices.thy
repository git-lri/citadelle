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

theory C_Appendices imports C_examples.C1 begin

section \<open>Structure of folders\<close>

text \<open>
\<^dir>\<open>copied_from_git\<close> represents the location of
external libraries needed by the C parser at run-time. At the time of
writing, it only contains
\<^dir>\<open>copied_from_git/mlton\<close>, and more specifically
\<^dir>\<open>copied_from_git/mlton/lib/mlyacc-lib\<close>. All
files in this last folder are solely used by
\<^theory>\<open>C.C_Parser_Language\<close>. The rest has been copied
from the original repository of MLton
\<^footnote>\<open>\<^url>\<open>https://github.com/MLton/mlton\<close>
and \<^url>\<open>https://gitlri.lri.fr/ftuong/mlton\<close>\<close>.
\<close>

text \<open>
The purpose of \<^dir>\<open>generated\<close> is to host generated
files, which are necessary for a first boot of the front-end. A major
subset of these files can actually be seen as superfluous, i.e., in
theory a simpler loading of a ``root un-generated file'' (generating
these files) would suffice, using for instance
\<^theory_text>\<open>code_reflect\<close>. However certain generators
are not written in a pure ML form (or are not yet automatically seen
as being translated to ML), so some manual steps of decomposition and
static generation was undertaken. In more detail:

  \<^item> \<^file>\<open>generated/c_ast.ML\<close> contains the
  Abstract Syntax Tree of C, which is loaded by
  \<^theory>\<open>C.C_Ast\<close>.
  
  \<^item> \<^file>\<open>generated/c_grammar_fun.grm\<close> is a
  generated file not used by the project, except for further
  generating \<^file>\<open>generated/c_grammar_fun.grm.sig\<close>
  and \<^file>\<open>generated/c_grammar_fun.grm.sml\<close>, or
  informative documentation purposes. It represents the basis point of
  our SML grammar file, generated by an initial Haskell grammar file
  (namely
  \<^url>\<open>https://github.com/visq/language-c/blob/master/src/Language/C/Parser/Parser.y\<close>).

  In short, it has to be compiled with a modified version of ML-Yacc,
  included in MLton itself
  (\<^url>\<open>https://gitlri.lri.fr/ftuong/mlton\<close>).

  \<^item> \<^file>\<open>generated/c_grammar_fun.grm.sig\<close>
  and \<^file>\<open>generated/c_grammar_fun.grm.sml\<close> are
  generated using the process described above.

\<close>

section \<open>Case study: mapping on the parsed AST\<close>

text \<open> In this section, we give a concrete example of a situation where one is interested to
do some automated transformations on the parsed AST, such as changing the type of every encountered
variables from \<open>int\<close> to \<open>array int\<close>. The main theory of interest here is
\<^theory>\<open>C.C_Parser_Language\<close>, where the C grammar is loaded, in contrast to
\<^theory>\<open>C.C_Lexer\<close> which is only dedicated to build a list of C tokens. As another
example, \<^theory>\<open>C.C_Parser_Language\<close> also contains the portion of the code
implementing the report to the user of various characteristics of encountered variables during
parsing: if a variable is bound or free, or if the declaration of a variable is made in the global
topmost space or locally declared in a function. \<close>

subsection \<open>Prerequisites\<close>

text \<open> Even if \<^file>\<open>generated/c_grammar_fun.grm.sig\<close> and
\<^file>\<open>generated/c_grammar_fun.grm.sml\<close> are files written in ML syntax, we have
actually modified \<^dir>\<open>copied_from_git/mlton/lib/mlyacc-lib\<close> in such a way that
at run time, the overall loading and execution of \<^theory>\<open>C.C_Parser_Language\<close> will
mimic all necessary features of the Haskell parser generator Happy
\<^footnote>\<open>\<^url>\<open>https://www.haskell.org/happy/doc/html/index.html\<close>\<close>,
including any monadic interactions between the lexing (\<^theory>\<open>C.C_Lexer\<close>) and
parsing part (\<^theory>\<open>C.C_Parser_Language\<close>).

This is why in the remaining part, we will at least assume a mandatory familiarity with Happy (e.g.,
the reading of ML-Yacc's manual can happen later if wished
\<^footnote>\<open>\<^url>\<open>https://www.cs.princeton.edu/~appel/modern/ml/ml-yacc/manual.html\<close>\<close>). In
particular, we will use \<^emph>\<open>rule code\<close> to designate \<^emph>\<open>a Haskell
expression enclosed in braces\<close>
\<^footnote>\<open>\<^url>\<open>https://www.haskell.org/happy/doc/html/sec-grammar.html\<close>\<close>.
\<close>

subsection \<open>Structure of \<^theory>\<open>C.C_Parser_Language\<close>\<close>

text \<open> In more detail, \<^theory>\<open>C.C_Parser_Language\<close> can be seen as being
principally divided into two parts:
\begin{itemize}
\item a first part containing the implementation of the ML structure
  \<open>C_Grammar_Rule_Lib\<close>, which provides the ML implementation library used by any rule
  code written in the C grammar
  \<^url>\<open>https://github.com/visq/language-c/blob/master/src/Language/C/Parser/Parser.y\<close>
  (\<^file>\<open>generated/c_grammar_fun.grm.sml\<close>).
\item a second part implementing the structure \<open>C_Grammar_Rule_Wrap\<close>, providing one
  wrapping function for each rule code, for potentially complementing the rule code with an
  additional action to be executed after its call. The use of wrapping functions is very optional:
  by default, they are all assigned as identity functions.
\end{itemize}
The difference between \<open>C_Grammar_Rule_Lib\<close> and \<open>C_Grammar_Rule_Wrap\<close>
relies in how often functions in the two structures are called: while building subtree pieces of the
final AST, grammar rules are free to call any functions in \<open>C_Grammar_Rule_Lib\<close> for
completing their respective tasks, but also free to not use \<open>C_Grammar_Rule_Lib\<close> at
all. On the other hand, irrespective of the actions done by a rule code, the function associated to
the rule code in \<open>C_Grammar_Rule_Wrap\<close> is retrieved and always executed (but a visible
side-effect will likely mostly happen whenever one has provided an implementation far different from
the identity function). \<close>

text \<open> Because the grammar
\<^url>\<open>https://github.com/visq/language-c/blob/master/src/Language/C/Parser/Parser.y\<close>
(\<^file>\<open>generated/c_grammar_fun.grm.sml\<close>) has been defined in such a way that
computation of variable scopes are completely handled by functions in
\<open>C_Grammar_Rule_Lib\<close> and not in rule code (which are just calling functions in
\<open>C_Grammar_Rule_Lib\<close>), it is enough to overload functions in
\<open>C_Grammar_Rule_Lib\<close> whenever it is wished to perform new actions depending on variable
scopes, for example to do a specific PIDE report at the first time when a C variable is being
declared. In particular, functions in \<open>C_Grammar_Rule_Lib\<close> are implemented in monadic
style, making a subsequent modification on the parsing environment
\<^theory>\<open>C.C_Environment\<close> possible (whenever appropriate) as this last is carried in
the monadic state.

Fundamentally, this is feasible because the monadic environment fulfills the property of being
always properly enriched with declared variable information at any time, because we assume
\begin{itemize}
  \item working with a language where a used variable must be at most declared or redeclared
    somewhere before its actual used,
  \item and using a parser scanning tokens uniquely, from left to right, in the same order than the
    execution of rule code actions.
\end{itemize}
\<close>

subsubsection \<open>Example\<close>

text \<open> As illustration, \<open>C_Grammar_Rule_Lib.markup_var true\<close> is (implicitly)
called by a rule code while a variable being declared is encountered. Later, a call to
\<open>C_Grammar_Rule_Lib.markup_var false\<close> in \<open>C_Grammar_Rule_Wrap\<close> (actually,
in \<open>C_Grammar_Rule_Wrap_Overloading\<close>) is made after the execution of another rule code
to signal the position of a variable in use, together with the information retrieved from the
environment of the position of where it is declared. \<close>

text \<open> In more detail, the second argument of \<open>C_Grammar_Rule_Lib.markup_var\<close> is
among other of the form: \<open>Position.T * {global: bool, ...}\<close>, where particularly the
field \<open>global\<close> of the record is informing \<open>C_Grammar_Rule_Lib.markup_var\<close>
if the variable being reported (at either first declaration time, or first use time) is global or
local (inside a function for instance). Because once declared, the property \<open>global\<close> of
a variable does not change afterwards, it is enough to store that information in the monadic
environment:
\<^item> \<^bold>\<open>Storing the information at declaration time\<close> The part deciding if a
variable being declared is global or not is implemented in
\<open>C_Grammar_Rule_Lib.doDeclIdent\<close> and
\<open>C_Grammar_Rule_Lib.doFuncParamDeclIdent\<close>. The two functions come from
\<^url>\<open>https://github.com/visq/language-c/blob/master/src/Language/C/Parser/Parser.y\<close>
(so do any functions in \<open>C_Grammar_Rule_Lib\<close>). Ultimately, they are both calling
\<open>C_Grammar_Rule_Lib.markup_var true\<close> at some point.
\<^item> \<^bold>\<open>Retrieving the information at use time\<close>
\<open>C_Grammar_Rule_Lib.markup_var false\<close> is only called by
\<open>C_Grammar_Rule_Wrap.primary_expression1\<close>, while treating a variable being already
declared. In particular the second argument of \<open>C_Grammar_Rule_Lib.markup_var\<close> is just
provided by what has been computed by the above point when the variable was declared (e.g., the
globality versus locality information). \<close>

subsection \<open>Rewriting of AST node\<close>

text \<open> For the case of rewriting a specific AST node, from subtree \<open>T1\<close> to
subtree \<open>T2\<close>, it is useful to zoom on the different parsing evaluation stages, as well
as make precise when the evaluation of semantic back-ends are starting.

\<^enum> Whereas annotations in Isabelle/C code have the potential of carrying arbitrary ML code (as
in \<^theory>\<open>C_examples.C1\<close>), the moment when they are effectively evaluated will not be
discussed here, because to closely follow the semantics of the language in embedding (so C), we
suppose comments --- comprising annotations --- may not affect any parsed tokens living outside
comments. So no matter when annotations are scheduled to be future evaluated in Isabelle/C, it will
be not possible to write a code changing \<open>T1\<close> to \<open>T2\<close> inside annotations.

\<^enum> To our knowledge, the sole category of code having the capacity to affect incoming stream
of tokens are directives, which are processed and evaluated before the ``major'' parsing step
occurs. Since in Isabelle/C, directives are relying on ML code, changing an AST node from
\<open>T1\<close> to \<open>T2\<close> can then be perfectly implemented in directives.

\<^enum> After the directive (pre)processing step, the main parsing happens. But since what are
driving the parsing engine are principally rule code, this step means to execute
\<open>C_Grammar_Rule_Lib\<close> and \<open>C_Grammar_Rule_Wrap\<close>, i.e., rules in
\<^file>\<open>generated/c_grammar_fun.grm.sml\<close>.

\<^enum> Once the parsing finishes, we have a final AST value, which topmost root type entry-point
constitutes the last node built before the grammar parser
\<^url>\<open>https://github.com/visq/language-c/blob/master/src/Language/C/Parser/Parser.y\<close>
ever entered in a stop state. For the case of a stop acceptance state, that moment happens when we
reach the first rule code building the type \<open>C_Ast.CTranslUnit\<close>, since there is only
one possible node making the parsing stop, according to what is currently written in the C
grammar. (For the case of a state stopped due to an error, it is the last successfully built value
that is returned, but to simplify the discussion, we will assume in the rest of the document the
parser is taking in input a fully well-parsed C code.)

\<^enum> By \<^emph>\<open>semantic back-ends\<close>, we denote any kind of ``relatively
efficient'' compiled code generating Isabelle/HOL theorems, proofs, definitions, and so with the
potential of generally generating Isabelle packages. In our case, the input of semantic back-ends
will be the type \<open>C_Ast.CTranslUnit\<close> (actually, whatever value provided by the above
parser). But since our parser is written in monadic style, it is as well possible to give slightly
more information to semantic back-ends, such as the last monadic computed state, so including the
last state of the parsing environment. \<close>

text \<open> Generally, semantic back-ends can be written in full ML starting from
\<open>C_Ast.CTranslUnit\<close>, but to additionally support formalizing tasks requiring to start
from an AST defined in Isabelle/HOL, we provide an equivalent AST in HOL in the project, such as the
one obtained after loading \<^file>\<open>../Featherweight-OCL/doc/Meta_C_generated.thy\<close>
\<^footnote>\<open>from the Citadelle project
\<^url>\<open>gitlri.lri.fr/ftuong/citadelle-devel\<close>\<close> (In fact, the ML AST is just
generated from the HOL one.) \<close>



text \<open>
Based on the above information, there are now several \<^emph>\<open>equivalent\<close> ways to
proceed for the purpose of having an AST node be mapped from \<open>T1\<close> to \<open>T2\<close>:
\<^item> For example, we can modify
\<^url>\<open>https://github.com/visq/language-c/blob/master/src/Language/C/Parser/Parser.y\<close>
by hand, by explicitly writing \<open>T2\<close> at the specific position of the rule code
generating \<open>T1\<close>. However, this solution implies to re-generate
\<^file>\<open>generated/c_grammar_fun.grm.sml\<close>.

\<^item> Instead of modifying the grammar, it should be possible to first locate which rule code is
building \<open>T1\<close>. Then it would remain to retrieve and modify the respective function of
\<open>C_Grammar_Rule_Wrap\<close> executed after that rule code, by providing a replacement
function to be put in \<open>C_Grammar_Rule_Wrap_Overloading\<close>. However, as a design decision,
wrapping functions generated in \<^file>\<open>generated/c_grammar_fun.grm.sml\<close> have only
been generated to affect monadic states, not AST values. This is to prevent an erroneous replacement
of an end-user while parsing C code. (It is currently left open about whether or not this feature
will be implemented in future versions of the parser...)

\<^item> Another solution consists in directly writing a mapping function acting on the full AST, so
writing a ML function of type \<open>C_Ast.CTranslUnit -> C_Ast.CTranslUnit\<close> (or a respective
HOL function) which has to act on every constructor of the AST (so in the worst case about hundred
of constructors for the considered AST, i.e., whenever a node has to be not identically
returned). However, as we have already implemented a conversion function from
\<open>C_Ast.CTranslUnit\<close> (subset of C11) to a subset AST of C99, it might be useful to save
some effort by starting from this conversion function, locate where \<open>T1\<close> is
pattern-matched by the conversion function, and generate \<open>T2\<close> instead.

As example, the conversion function \<open>C_Ast.main\<close> is particularly used to connect the
C11 front-end to the entry-point of AutoCorres in
\<^verbatim>\<open>l4v/src/tools/c-parser/StrictCParser.ML\<close>.

\<^item> If it is allowed to modify the C code in input, then one can add a directive
\<open>#define\<close> performing the necessary rewrite.

\<close>

text \<open> More generally, to better inspect the list of rule code really executed when a C code
is parsed, it might be helpful to proceed as in \<^theory>\<open>C_examples.C1\<close>, by activating
\<^theory_text>\<open>declare[[C_parser_trace]]\<close>. Then, the output window will display the
sequence of Shift Reduce actions associated to the \<^theory_text>\<open>C\<close> command of
interest.
\<close> 

end
