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

section \<open>Parsing Support for the Core Language (C11 Instance)\<close>

theory C_Parser_Language
  imports C_Environment
begin

subsection \<open>Core C11 Parsing Library (fully mimicking the Haskell counterpart)\<close>

ML \<comment> \<open>\<^file>\<open>../generated/c_grammar_fun.grm.sml\<close>\<close>
(*
 * Modified by Frédéric Tuong, Université Paris-Saclay
 *
 *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
 *
 * Language.C
 * https://hackage.haskell.org/package/language-c
 *
 * Copyright (c) 1999-2017 Manuel M T Chakravarty
 *                         Duncan Coutts
 *                         Benedikt Huber
 * Portions Copyright (c) 1989,1990 James A. Roskind
 *
 *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *  *
 *
 * Language.C.Comments
 * https://hackage.haskell.org/package/language-c-comments
 *
 * Copyright (c) 2010-2014 Geoff Hulette
 *)
\<open>
signature C_GRAMMAR_RULE_LIB =
sig
  type arg = C_Env.T
  type 'a monad = arg -> 'a * arg

  (* type aliases *)
  type class_Pos = C_Ast.class_Pos
    (**)
  type NodeInfo = C_Ast.nodeInfo
  type CStorageSpec = NodeInfo C_Ast.cStorageSpecifier
  type CFunSpec = NodeInfo C_Ast.cFunctionSpecifier
  type CConst = NodeInfo C_Ast.cConstant
  type 'a CInitializerList = ('a C_Ast.cPartDesignator List.list * 'a C_Ast.cInitializer) List.list
  type CTranslUnit = NodeInfo C_Ast.cTranslationUnit
  type CExtDecl = NodeInfo C_Ast.cExternalDeclaration
  type CFunDef = NodeInfo C_Ast.cFunctionDef
  type CDecl = NodeInfo C_Ast.cDeclaration
  type CDeclr = NodeInfo C_Ast.cDeclarator
  type CDerivedDeclr = NodeInfo C_Ast.cDerivedDeclarator
  type CArrSize = NodeInfo C_Ast.cArraySize
  type CStat = NodeInfo C_Ast.cStatement
  type CAsmStmt = NodeInfo C_Ast.cAssemblyStatement
  type CAsmOperand = NodeInfo C_Ast.cAssemblyOperand
  type CBlockItem = NodeInfo C_Ast.cCompoundBlockItem
  type CDeclSpec = NodeInfo C_Ast.cDeclarationSpecifier
  type CTypeSpec = NodeInfo C_Ast.cTypeSpecifier
  type CTypeQual = NodeInfo C_Ast.cTypeQualifier
  type CAlignSpec = NodeInfo C_Ast.cAlignmentSpecifier
  type CStructUnion = NodeInfo C_Ast.cStructureUnion
  type CEnum = NodeInfo C_Ast.cEnumeration
  type CInit = NodeInfo C_Ast.cInitializer
  type CInitList = NodeInfo CInitializerList
  type CDesignator = NodeInfo C_Ast.cPartDesignator
  type CAttr = NodeInfo C_Ast.cAttribute
  type CExpr = NodeInfo C_Ast.cExpression
  type CBuiltin = NodeInfo C_Ast.cBuiltinThing
  type CStrLit = NodeInfo C_Ast.cStringLiteral
    (**)
  type ClangCVersion = C_Ast.clangCVersion
  type Ident = C_Ast.ident
  type Position = C_Ast.position
  type PosLength = Position * int
  type Name = C_Ast.name
  type Bool = bool
  type CString = C_Ast.cString
  type CChar = C_Ast.cChar
  type CInteger = C_Ast.cInteger
  type CFloat = C_Ast.cFloat
  type CStructTag = C_Ast.cStructTag
  type CUnaryOp = C_Ast.cUnaryOp
  type 'a CStringLiteral = 'a C_Ast.cStringLiteral
  type 'a CConstant = 'a C_Ast.cConstant
  type ('a, 'b) Either = ('a, 'b) C_Ast.either
  type CIntRepr = C_Ast.cIntRepr
  type CIntFlag = C_Ast.cIntFlag
  type CAssignOp = C_Ast.cAssignOp
  type Comment = C_Ast.comment
    (**)
  type 'a Reversed = 'a C_Ast.Reversed
  type CDeclrR = C_Ast.CDeclrR
  type 'a Maybe = 'a C_Ast.optiona
  type 'a Located = 'a C_Ast.Located
    (**)
  structure List : sig val reverse : 'a list -> 'a list end

  (* monadic operations *)
  val return : 'a -> 'a monad
  val bind : 'a monad -> ('a -> 'b monad) -> 'b monad
  val bind' : 'b monad -> ('b -> unit monad) -> 'b monad
  val >> : unit monad * 'a monad -> 'a monad

  (* position reports *)
  val report : Position.T list -> ('a -> Markup.T list) -> 'a -> C_Position.reports_text -> C_Position.reports_text
  val markup_tvar : bool -> Position.T list -> string * serial -> Markup.T list
  val markup_var : bool -> Position.T * C_Env.markup_ident -> Position.T list -> string * serial -> Markup.T list

  (* Language.C.Data.RList *)
  val empty : 'a list Reversed
  val singleton : 'a -> 'a list Reversed
  val snoc : 'a list Reversed -> 'a -> 'a list Reversed
  val rappend : 'a list Reversed -> 'a list -> 'a list Reversed
  val rappendr : 'a list Reversed -> 'a list Reversed -> 'a list Reversed
  val rmap : ('a -> 'b) -> 'a list Reversed -> 'b list Reversed

  (* Language.C.Data.Position *)
  val posOf : 'a -> Position
  val posOf' : bool -> class_Pos -> Position * int
  val make_comment : Symbol_Pos.T list -> Symbol_Pos.T list -> Symbol_Pos.T list -> Position.range -> Comment

  (* Language.C.Data.Node *)
  val mkNodeInfo' : Position -> PosLength -> Name -> NodeInfo
  val decode : NodeInfo -> (class_Pos, string) Either
  val decode_error' : NodeInfo -> Position.range

  (* Language.C.Data.Ident *)
  val mkIdent : Position * int -> string -> Name -> Ident
  val internalIdent : string -> Ident

  (* Language.C.Syntax.AST *)
  val liftStrLit : 'a CStringLiteral -> 'a CConstant

  (* Language.C.Syntax.Constants *)
  val concatCStrings : CString list -> CString

  (* Language.C.Parser.ParserMonad *)
  val getNewName : Name monad
  val isTypeIdent : string -> arg -> bool
  val enterScope : unit monad
  val leaveScope : unit monad
  val getCurrentPosition : Position monad

  (* Language.C.Parser.Tokens *)
  val CTokCLit : CChar -> (CChar -> 'a) -> 'a
  val CTokILit : CInteger -> (CInteger -> 'a) -> 'a
  val CTokFLit : CFloat -> (CFloat -> 'a) -> 'a
  val CTokSLit : CString -> (CString -> 'a) -> 'a

  (* Language.C.Parser.Parser *)
  val reverseList : 'a list -> 'a list Reversed
  val L : 'a -> int -> 'a Located monad
  val unL : 'a Located -> 'a
  val withNodeInfo : int -> (NodeInfo -> 'a) -> 'a monad
  val withNodeInfo_CExtDecl : CExtDecl -> (NodeInfo -> 'a) -> 'a monad
  val withNodeInfo_CExpr : CExpr list Reversed -> (NodeInfo -> 'a) -> 'a monad
  val withLength : NodeInfo -> (NodeInfo -> 'a) -> 'a monad
  val reverseDeclr : CDeclrR -> CDeclr
  val withAttribute : int -> CAttr list -> (NodeInfo -> CDeclrR) -> CDeclrR monad
  val withAttributePF : int -> CAttr list -> (NodeInfo -> CDeclrR -> CDeclrR) -> (CDeclrR -> CDeclrR) monad
  val appendObjAttrs : CAttr list -> CDeclr -> CDeclr
  val withAsmNameAttrs : CStrLit Maybe * CAttr list -> CDeclrR -> CDeclrR monad
  val appendDeclrAttrs : CAttr list -> CDeclrR -> CDeclrR
  val ptrDeclr : CDeclrR -> CTypeQual list -> NodeInfo -> CDeclrR
  val funDeclr : CDeclrR -> (Ident list, (CDecl list * Bool)) Either -> CAttr list -> NodeInfo -> CDeclrR
  val arrDeclr : CDeclrR -> CTypeQual list -> Bool -> Bool -> CExpr Maybe -> NodeInfo -> CDeclrR
  val liftTypeQuals : CTypeQual list Reversed -> CDeclSpec list
  val liftCAttrs : CAttr list -> CDeclSpec list
  val addTrailingAttrs : CDeclSpec list Reversed -> CAttr list -> CDeclSpec list Reversed
  val emptyDeclr : CDeclrR
  val mkVarDeclr : Ident -> NodeInfo -> CDeclrR
  val doDeclIdent : CDeclSpec list -> CDeclrR -> unit monad
  val doFuncParamDeclIdent : CDeclr -> unit monad
end

structure C_Grammar_Rule_Lib : C_GRAMMAR_RULE_LIB =
struct
  open C_Ast
  type arg = C_Env.T
  type 'a monad = arg -> 'a * arg

  (**)
  val To_string0 = String.implode o to_list
  fun reverse l = rev l

  fun report [] _ _ = I
    | report ps markup x =
        let val ms = markup x
        in fold (fn p => fold (fn m => cons ((p, m), "")) ms) ps end

  fun markup_tvar def ps (name, id) =
    let 
      fun markup_elem name = (name, (name, []): Markup.T);
      val (tvarN, tvar) = markup_elem "C type variable";
      val entity = Markup.entity tvarN name
    in
      tvar ::
      (if def then I else cons (Markup.keyword_properties Markup.ML_keyword3))
        (map (fn pos => Markup.properties (Position.entity_properties_of def id pos) entity) ps)
    end

   fun string_of_list f =
     (fn [] => NONE | [s] => SOME s | s => SOME ("[" ^ String.concatWith ", " s ^ "]"))
     o map f
   val string_of_cDeclarationSpecifier =
       fn C_Ast.CStorageSpec0 _ => "storage"
        | C_Ast.CTypeSpec0 t => (case t of 
                                    CVoidType0 _ => "void"
                                  | CCharType0 _ => "char"
                                  | CShortType0 _ => "short"
                                  | CIntType0 _ => "int"
                                  | CLongType0 _ => "long"
                                  | CFloatType0 _ => "float"
                                  | CDoubleType0 _ => "double"
                                  | CSignedType0 _ => "signed"
                                  | CUnsigType0 _ => "unsig"
                                  | CBoolType0 _ => "bool"
                                  | CComplexType0 _ => "complex"
                                  | CInt128Type0 _ => "int128"
                                  | CSUType0 _ => "SU"
                                  | CEnumType0 _ => "enum"
                                  | CTypeDef0 _ => "typedef"
                                  | CTypeOfExpr0 _ => "type_of_expr"
                                  | CTypeOfType0 _ => "type_of_type"
                                  | CAtomicType0 _ => "atomic")
        | C_Ast.CTypeQual0 _ => "type_qual"
        | C_Ast.CFunSpec0 _ => "fun"
        | C_Ast.CAlignSpec0 _ => "align"

  fun markup_var def (pos1, {global, params, ret}) ps (name, id) =
    let 
      fun markup_elem name = (name, (name, []): Markup.T);
      val (varN, var) = markup_elem ("C " ^ (if global then "global" else "local") ^ " variable");
      val entity = Markup.entity varN name
      val params =
        string_of_list
          (fn C_Ast.CPtrDeclr0 _ => "pointer"
            | C_Ast.CArrDeclr0 _ => "array"
            | C_Ast.CFunDeclr0 (C_Ast.Left _, _, _) => "function [...] ->"
            | C_Ast.CFunDeclr0 (C_Ast.Right (l_decl, _), _, _) =>
               "function "
               ^ (String.concatWith
                   " -> "
                   (map (fn CDecl0 ([decl], _, _) => string_of_cDeclarationSpecifier decl
                          | CDecl0 (l, _, _) => "(" ^ String.concatWith " " (map string_of_cDeclarationSpecifier l) ^ ")"
                          | CStaticAssert0 _ => "static_assert")
                        l_decl))
               ^ " ->")
          params
      val ret =
        case ret of C_Env.Previous_in_stack => SOME "..."
                  | C_Env.Parsed ret => string_of_list string_of_cDeclarationSpecifier ret
      val _ = Output.report
                [ Position.reported_text
                    pos1
                    Markup.typing
                    (case (params, ret) of
                       (NONE, NONE) => let val _ = warning "markup_var: Not yet implemented" in "" end
                     | (SOME params, NONE) => params
                     | (NONE, SOME ret) => ret
                     | (SOME params, SOME ret) => params ^ " " ^ ret) ]
    in
      var ::
      (if global
       then if def then cons (Markup.keyword_properties Markup.free) else I (*black constant*)
       else cons (Markup.keyword_properties Markup.bound))
        (map (fn pos => Markup.properties (Position.entity_properties_of def id pos) entity) ps)
    end

  (**)
  val return = pair
  fun bind f g = f #-> g
  fun bind' f g = bind f (fn r => bind (g r) (fn () => return r))
  fun a >> b = a #> b o #2
  fun sequence_ f = fn [] => return ()
                     | x :: xs => f x >> sequence_ f xs

  (* Language.C.Data.RList *)
  val empty = []
  fun singleton x = [x]
  fun snoc xs x = x :: xs
  fun rappend xs ys = rev ys @ xs
  fun rappendr xs ys = ys @ xs
  val rmap = map
  val viewr = fn [] => error "viewr: empty RList"
               | x :: xs => (xs, x)

  (* Language.C.Data.Position *)
  val nopos = NoPosition
  fun posOf _ = NoPosition
  fun posOf' mk_range =
    (if mk_range then Position.range else I)
    #> (fn (pos1, pos2) =>
          let val {offset = offset, end_offset = end_offset, ...} = Position.dest pos1
          in (Position offset (From_string (C_Env.encode_positions [pos1, pos2])) 0 0, end_offset - offset) end)
  fun posOf'' node env =
    let val (stack, len) = #rule_input env
        val (mk_range, (pos1a, pos1b)) = case node of Left i => (true, nth stack (len - i - 1))
                                                    | Right range => (false, range)
        val (pos2a, pos2b) = nth stack 0
    in ( (posOf' mk_range (pos1a, pos1b) |> #1, posOf' true (pos2a, pos2b))
       , env |> C_Env_Ext.map_output_pos (K (SOME (pos1a, pos2b)))
             |> C_Env_Ext.map_output_vacuous (K false)) end
  val posOf''' = posOf'' o Left
  val internalPos = InternalPosition
  fun make_comment body_begin body body_end range =
    Comment ( posOf' false range |> #1
            , From_string (Symbol_Pos.implode (body_begin @ body @ body_end))
            , case body_end of [] => SingleLine | _ => MultiLine)

  (* Language.C.Data.Node *)
  val undefNode = OnlyPos nopos (nopos, ~1)
  fun mkNodeInfoOnlyPos pos = OnlyPos pos (nopos, ~1)
  fun mkNodeInfo pos name = NodeInfo pos (nopos, ~1) name
  val mkNodeInfo' = NodeInfo
  val decode =
   (fn OnlyPos0 range => range
     | NodeInfo0 (pos1, (pos2, len2), _) => (pos1, (pos2, len2)))
   #> (fn (Position0 (_, s1, _, _), (Position0 (_, s2, _, _), _)) =>
            (case (C_Env.decode_positions (To_string0 s1), C_Env.decode_positions (To_string0 s2))
             of ([pos1, _], [_, pos2]) => Left (Position.range (pos1, pos2))
              | _ => Right "Expecting 2 elements")
        | _ => Right "Invalid position")
  fun decode_error' x = case decode x of Left x => x | Right msg => error msg
  fun decode_error x = Right (decode_error' x)
  val nameOfNode = fn OnlyPos0 _ => NONE
                    | NodeInfo0 (_, _, name) => SOME name

  (* Language.C.Data.Ident *)
  local
    val bits7 = Integer.pow 7 2
    val bits14 = Integer.pow 14 2
    val bits21 = Integer.pow 21 2
    val bits28 = Integer.pow 28 2
    fun quad s = case s of
      [] => 0
    | c1 :: [] => ord c1
    | c1 :: c2 :: [] => ord c2 * bits7 + ord c1
    | c1 :: c2 :: c3 :: [] => ord c3 * bits14 + ord c2 * bits7 + ord c1
    | c1 :: c2 :: c3 :: c4 :: s => ((ord c4 * bits21
                                     + ord c3 * bits14
                                     + ord c2 * bits7
                                     + ord c1)
                                    mod bits28)
                                   + (quad s mod bits28)
    fun internalIdent0 pos s = Ident (From_string s, quad (Symbol.explode s), pos)
  in
  fun mkIdent (pos, len) s name = internalIdent0 (mkNodeInfo' pos (pos, len) name) s
  val internalIdent = internalIdent0 (mkNodeInfoOnlyPos internalPos)
  end

  (* Language.C.Syntax.AST *)
  fun liftStrLit (CStrLit0 (str, at)) = CStrConst str at

  (* Language.C.Syntax.Constants *)
  fun concatCStrings cs = CString0 (flatten (map (fn CString0 (s,_) => s) cs), exists (fn CString0 (_, b) => b) cs)

  (* Language.C.Parser.ParserMonad *)
  fun getNewName env =
    (Name (C_Env_Ext.get_namesupply env), C_Env_Ext.map_namesupply (fn x => x + 1) env)
  fun addTypedef (Ident0 (i, _, node)) env =
    let val (pos1, _) = decode_error' node
        val id = serial ()
        val name = To_string0 i
        val pos = [pos1]
    in ((), env |> C_Env_Ext.map_tyidents (Symtab.update (name, (pos, id)))
                |> C_Env_Ext.map_reports_text (report pos (markup_tvar true pos) (name, id))) end
  fun shadowTypedef0 ret global f (Ident0 (i, _, node), params) env =
    let val (pos1, _) = decode_error' node
        val id = serial ()
        val name = To_string0 i
        val pos = [pos1]
        val markup_data = {global = global, params = params, ret = ret}
        val update_id = Symtab.update (name, (pos, id, markup_data))
    in ((), env |> C_Env_Ext.map_tyidents (Symtab.delete_safe (To_string0 i))
                |> C_Env_Ext.map_idents update_id
                |> f update_id
                |> C_Env_Ext.map_reports_text (report pos (markup_var true (pos1, markup_data) pos) (name, id))) end
  fun shadowTypedef_fun ident env =
    shadowTypedef0 C_Env.Previous_in_stack
                   (case C_Env_Ext.get_scopes env of _ :: [] => true | _ => false)
                   (fn update_id => C_Env_Ext.map_scopes (fn (NONE, x) :: xs => (SOME (fst ident), C_Env.map_idents update_id x) :: xs
                                                           | (SOME _, _) :: _ => error "Not yet implemented"
                                                           | [] => error "Not expecting an empty scope"))
                   ident
                   env
  fun shadowTypedef (i, params, ret) env =
    shadowTypedef0 (C_Env.Parsed ret) (List.null (C_Env_Ext.get_scopes env)) (K I) (i, params) env
  fun isTypeIdent s0 = Symtab.exists (fn (s1, _) => s0 = s1) o C_Env_Ext.get_tyidents
  fun enterScope env =
    ((), C_Env_Ext.map_scopes (cons (NONE, C_Env_Ext.get_var_table env)) env)
  fun leaveScope env = 
    case C_Env_Ext.get_scopes env of [] => error "leaveScope: already in global scope"
                                   | (_, var_table) :: scopes => ((), env |> C_Env_Ext.map_scopes (K scopes)
                                                                          |> C_Env_Ext.map_var_table (K var_table))
  val getCurrentPosition = return NoPosition

  (* Language.C.Parser.Tokens *)
  fun CTokCLit x f = x |> f
  fun CTokILit x f = x |> f
  fun CTokFLit x f = x |> f
  fun CTokSLit x f = x |> f

  (* Language.C.Parser.Parser *)
  fun reverseList x = rev x
  fun L a i = posOf''' i #>> curry Located a
  fun unL (Located (a, _)) = a
  fun withNodeInfo00 (pos1, (pos2, len2)) mkAttrNode name =
    return (mkAttrNode (NodeInfo pos1 (pos2, len2) name))
  fun withNodeInfo0 x = x |> bind getNewName oo withNodeInfo00
  fun withNodeInfo0' node mkAttrNode env = let val (range, env) = posOf'' node env
                                           in withNodeInfo0 range mkAttrNode env end
  fun withNodeInfo x = x |> withNodeInfo0' o Left
  fun withNodeInfo' x = x |> withNodeInfo0' o decode_error
  fun withNodeInfo_CExtDecl x = x |>
    withNodeInfo' o (fn CDeclExt0 (CDecl0 (_, _, node)) => node
                      | CDeclExt0 (CStaticAssert0 (_, _, node)) => node
                      | CFDefExt0 (CFunDef0 (_, _, _, _, node)) => node
                      | CAsmExt0 (_, node) => node)
  val get_node_CExpr =
    fn CComma0 (_, a) => a | CAssign0 (_, _, _, a) => a | CCond0 (_, _, _, a) => a |
    CBinary0 (_, _, _, a) => a | CCast0 (_, _, a) => a | CUnary0 (_, _, a) => a | CSizeofExpr0 (_, a) => a | CSizeofType0 (_, a) => a | CAlignofExpr0 (_, a) => a | CAlignofType0 (_, a) => a | CComplexReal0 (_, a) => a | CComplexImag0 (_, a) => a | CIndex0 (_, _, a) => a |
    CCall0 (_, _, a) => a | CMember0 (_, _, _, a) => a | CVar0 (_, a) => a | CConst0 c => (case c of
    CIntConst0 (_, a) => a | CCharConst0 (_, a) => a | CFloatConst0 (_, a) => a | CStrConst0 (_, a) => a) |
    CCompoundLit0 (_, _, a) => a | CGenericSelection0 (_, _, a) => a | CStatExpr0 (_, a) => a |
    CLabAddrExpr0 (_, a) => a | CBuiltinExpr0 cBuiltinThing => (case cBuiltinThing
     of CBuiltinVaArg0 (_, _, a) => a
     | CBuiltinOffsetOf0 (_, _, a) => a
     | CBuiltinTypesCompatible0 (_, _, a) => a)
  fun withNodeInfo_CExpr x = x |> withNodeInfo' o get_node_CExpr o hd
  fun withLength node mkAttrNode =
    bind (posOf'' (decode_error node)) (fn range => 
      withNodeInfo00 range mkAttrNode (case nameOfNode node of NONE => error "nameOfNode"
                                                             | SOME name => name))
  fun reverseDeclr (CDeclrR0 (ide, reversedDDs, asmname, cattrs, at)) = CDeclr ide (rev reversedDDs) asmname cattrs at
  fun appendDeclrAttrs newAttrs (CDeclrR0 (ident, l, asmname, cattrs, at)) =
    case l of
      [] => CDeclrR ident empty asmname (cattrs @ newAttrs) at
    | x :: xs =>
      let val appendAttrs = fn CPtrDeclr0 (typeQuals, at) => CPtrDeclr (typeQuals @ map CAttrQual newAttrs) at
                             | CArrDeclr0 (typeQuals, arraySize, at) => CArrDeclr (typeQuals @ map CAttrQual newAttrs) arraySize at
                             | CFunDeclr0 (parameters, cattrs, at) => CFunDeclr parameters (cattrs @ newAttrs) at
      in CDeclrR ident (appendAttrs x :: xs) asmname cattrs at
      end
  fun withAttribute node cattrs mkDeclrNode =
    bind (posOf''' node) (fn (pos, _) =>
    bind getNewName (fn name =>
        let val attrs = mkNodeInfo pos name
            val newDeclr = appendDeclrAttrs cattrs (mkDeclrNode attrs)
        in return newDeclr end))
  fun withAttributePF node cattrs mkDeclrCtor =
    bind (posOf''' node) (fn (pos, _) =>
    bind getNewName (fn name =>
        let val attrs = mkNodeInfo pos name
            val newDeclr = appendDeclrAttrs cattrs o mkDeclrCtor attrs
        in return newDeclr end))
  fun appendObjAttrs newAttrs (CDeclr0 (ident, indirections, asmname, cAttrs, at)) =
    CDeclr ident indirections asmname (cAttrs @ newAttrs) at
  fun appendObjAttrsR newAttrs (CDeclrR0 (ident, indirections, asmname, cAttrs, at)) =
    CDeclrR ident indirections asmname (cAttrs @ newAttrs) at
  fun setAsmName mAsmName (CDeclrR0 (ident, indirections, oldName, cattrs, at)) =
    case (case (mAsmName, oldName)
          of (None, None) => Right None
           | (None, oldname as Some _) => Right oldname
           | (newname as Some _, None) => Right newname
           | (Some n1, Some n2) => Left (n1, n2))
    of
      Left (n1, n2) => let fun showName (CStrLit0 (CString0 (s, _), _)) = To_string0 s
                       in error ("Duplicate assembler name: " ^ showName n1 ^ " " ^ showName n2) end
    | Right newName => return (CDeclrR ident indirections newName cattrs at)
  fun withAsmNameAttrs (mAsmName, newAttrs) declr = setAsmName mAsmName (appendObjAttrsR newAttrs declr)
  fun ptrDeclr (CDeclrR0 (ident, derivedDeclrs, asmname, cattrs, dat)) tyquals at =
    CDeclrR ident (snoc derivedDeclrs (CPtrDeclr tyquals at)) asmname cattrs dat
  fun funDeclr (CDeclrR0 (ident, derivedDeclrs, asmname, dcattrs, dat)) params cattrs at =
    CDeclrR ident (snoc derivedDeclrs (CFunDeclr params cattrs at)) asmname dcattrs dat
  fun arrDeclr (CDeclrR0 (ident, derivedDeclrs, asmname, cattrs, dat)) tyquals var_sized static_size size_expr_opt at =
    CDeclrR ident
            (snoc
               derivedDeclrs
               (CArrDeclr tyquals (case size_expr_opt of
                                     Some e => CArrSize static_size e
                                   | None => CNoArrSize var_sized) at))
            asmname
            cattrs
            dat
  val liftTypeQuals = map CTypeQual o reverse
  val liftCAttrs = map (CTypeQual o CAttrQual)
  fun addTrailingAttrs declspecs new_attrs =
    case viewr declspecs of
      (specs_init, CTypeSpec0 (CSUType0 (CStruct0 (tag, name, Some def, def_attrs, su_node), node))) =>
        snoc specs_init (CTypeSpec (CSUType (CStruct tag name (Just def) (def_attrs @ new_attrs) su_node) node))
    | (specs_init, CTypeSpec0 (CEnumType0 (CEnum0 (name, Some def, def_attrs, e_node), node))) => 
        snoc specs_init (CTypeSpec (CEnumType (CEnum name (Just def) (def_attrs @ new_attrs) e_node) node))
    | _ => rappend declspecs (liftCAttrs new_attrs)
  val emptyDeclr = CDeclrR Nothing empty Nothing [] undefNode
  fun mkVarDeclr ident = CDeclrR (Some ident) empty Nothing []
  fun doDeclIdent declspecs (decl as CDeclrR0 (mIdent, _, _, _, _)) =
    case mIdent of
      None => return ()
    | Some ident =>
       if exists (fn CStorageSpec0 (CTypedef0 _) => true | _ => false) declspecs
       then addTypedef ident
       else shadowTypedef ( ident
                          , case reverseDeclr decl of CDeclr0 (_, params, _, _, _) => params
                          , declspecs)
  val doFuncParamDeclIdent =
    fn CDeclr0 (mIdent0, param0 as CFunDeclr0 (Right (params, _), _, _) :: _, _, _, _) =>
        (case mIdent0 of None => return ()
                       | Some mIdent0 => shadowTypedef_fun (mIdent0, param0))
        >>
        sequence_
          shadowTypedef
          (maps (fn CDecl0 (ret, l, _) =>
                       maps (fn ((Some (CDeclr0 (Some mIdent, params, _, _, _)),_),_) =>
                                  [(mIdent, params, ret)]
                              | _ => [])
                            l
                  | _ => [])
                params)
     | _ => return ()

  (**)
  structure List = struct val reverse = rev end
end
\<close>

subsection \<open>Loading the Generic Grammar Simulator\<close>

text \<open> The parser consists of a generic module
\<^file>\<open>../copied_from_git/mlton/lib/mlyacc-lib/base.sig\<close>, which interprets an
automata-like format generated from ML-Yacc. \<close>

ML_file "../copied_from_git/mlton/lib/mlyacc-lib/base.sig"
ML_file "../copied_from_git/mlton/lib/mlyacc-lib/join.sml"
ML_file "../copied_from_git/mlton/lib/mlyacc-lib/lrtable.sml"
ML_file "../copied_from_git/mlton/lib/mlyacc-lib/stream.sml"
ML_file "../copied_from_git/mlton/lib/mlyacc-lib/parser1.sml"

subsection \<open>Loading the Generated Grammar (SML signature)\<close>

ML_file "../generated/c_grammar_fun.grm.sig"

subsection \<open>Overloading Grammar Rules\<close>

ML \<comment> \<open>\<^file>\<open>../generated/c_grammar_fun.grm.sml\<close>\<close> \<open>
structure C_Grammar_Rule_Wrap_Overloading = struct
open C_Grammar_Rule_Lib
val To_string0 = String.implode o C_Ast.to_list

val update_env =
 fn C_Transition.Bottom_up => (fn f => fn x => fn arg => ((), C_Env.map_env_tree (f x (#env_lang arg) #> #2) arg))
  | C_Transition.Top_down => fn f => fn x => pair () ##> (fn arg => C_Env_Ext.map_output_env (K (SOME (f x (#env_lang arg)))) arg)

(*type variable definition*)

val specifier3 : (CDeclSpec list) -> unit monad = update_env C_Transition.Bottom_up (fn l => fn env_lang => fn env_tree =>
  ( env_lang
  , fold
      let open C_Ast
      in fn CTypeSpec0 (CTypeDef0 (Ident0 (i, _, node), _)) =>
            let val name = To_string0 i
                val pos1 = [decode_error' node |> #1]
            in case Symtab.lookup (#var_table env_lang |> #tyidents) name of
                 NONE => I
               | SOME (pos0, id) => C_Env.map_reports_text (report pos1 (markup_tvar false pos0) (name, id)) end
          | _ => I
      end
      l
      env_tree))
val declaration_specifier3 : (CDeclSpec list) -> unit monad = specifier3
val type_specifier3 : (CDeclSpec list) -> unit monad = specifier3


(*basic variable definition*)

val primary_expression1 : (CExpr) -> unit monad = update_env C_Transition.Bottom_up (fn e => fn env_lang => fn env_tree =>
  ( env_lang
  , let open C_Ast
    in fn CVar0 (Ident0 (i, _, node), _) =>
          let val name = To_string0 i
              val pos1 = decode_error' node |> #1
          in case Symtab.lookup (#var_table env_lang |> #idents) name of
               NONE => C_Env.map_reports_text (report [pos1] (fn () => [Markup.keyword_properties Markup.free]) ())
             | SOME (pos0, id, markup_data) =>
                 C_Env.map_reports_text (report [pos1] (markup_var false (pos1, markup_data) pos0) (name, id))
          end
        | _ => I
    end
      e
      env_tree))
end
\<close>

ML \<comment> \<open>\<^file>\<open>../generated/c_grammar_fun.grm.sml\<close>\<close> \<open>
structure C_Grammar_Rule_Wrap = struct
  open C_Grammar_Rule_Wrap
  open C_Grammar_Rule_Wrap_Overloading
end
\<close>

subsection \<open>Loading the Generated Grammar (SML structure)\<close>

ML_file "../generated/c_grammar_fun.grm.sml"

subsection \<open>Grammar Initialization\<close>

subsubsection \<open>Functor Application\<close>

ML \<comment> \<open>\<^file>\<open>../generated/c_grammar_fun.grm.sml\<close>\<close> \<open>
structure C_Grammar = C_Grammar_Fun (structure Token = LALR_Parser_Eval.Token)
\<close>

subsubsection \<open>Mapping Lexing Strings to Parsing Tokens\<close>

ML \<comment> \<open>\<^file>\<open>../generated/c_grammar_fun.grm.sml\<close>\<close> \<open>
structure C_Grammar_Tokens =
struct
local open C_Grammar.Tokens in
  fun token_of_string error ty_ClangCVersion ty_cChar ty_cFloat ty_cInteger ty_cString ty_ident ty_string a1 a2 = fn
     "(" => x28 (ty_string, a1, a2)
    | ")" => x29 (ty_string, a1, a2)
    | "[" => x5b (ty_string, a1, a2)
    | "]" => x5d (ty_string, a1, a2)
    | "->" => x2d_x3e (ty_string, a1, a2)
    | "." => x2e (ty_string, a1, a2)
    | "!" => x21 (ty_string, a1, a2)
    | "~" => x7e (ty_string, a1, a2)
    | "++" => x2b_x2b (ty_string, a1, a2)
    | "--" => x2d_x2d (ty_string, a1, a2)
    | "+" => x2b (ty_string, a1, a2)
    | "-" => x2d (ty_string, a1, a2)
    | "*" => x2a (ty_string, a1, a2)
    | "/" => x2f (ty_string, a1, a2)
    | "%" => x25 (ty_string, a1, a2)
    | "&" => x26 (ty_string, a1, a2)
    | "<<" => x3c_x3c (ty_string, a1, a2)
    | ">>" => x3e_x3e (ty_string, a1, a2)
    | "<" => x3c (ty_string, a1, a2)
    | "<=" => x3c_x3d (ty_string, a1, a2)
    | ">" => x3e (ty_string, a1, a2)
    | ">=" => x3e_x3d (ty_string, a1, a2)
    | "==" => x3d_x3d (ty_string, a1, a2)
    | "!=" => x21_x3d (ty_string, a1, a2)
    | "^" => x5e (ty_string, a1, a2)
    | "|" => x7c (ty_string, a1, a2)
    | "&&" => x26_x26 (ty_string, a1, a2)
    | "||" => x7c_x7c (ty_string, a1, a2)
    | "?" => x3f (ty_string, a1, a2)
    | ":" => x3a (ty_string, a1, a2)
    | "=" => x3d (ty_string, a1, a2)
    | "+=" => x2b_x3d (ty_string, a1, a2)
    | "-=" => x2d_x3d (ty_string, a1, a2)
    | "*=" => x2a_x3d (ty_string, a1, a2)
    | "/=" => x2f_x3d (ty_string, a1, a2)
    | "%=" => x25_x3d (ty_string, a1, a2)
    | "&=" => x26_x3d (ty_string, a1, a2)
    | "^=" => x5e_x3d (ty_string, a1, a2)
    | "|=" => x7c_x3d (ty_string, a1, a2)
    | "<<=" => x3c_x3c_x3d (ty_string, a1, a2)
    | ">>=" => x3e_x3e_x3d (ty_string, a1, a2)
    | "," => x2c (ty_string, a1, a2)
    | ";" => x3b (ty_string, a1, a2)
    | "{" => x7b (ty_string, a1, a2)
    | "}" => x7d (ty_string, a1, a2)
    | "..." => x2e_x2e_x2e (ty_string, a1, a2)
    | x => let 
    val alignof = alignof (ty_string, a1, a2)
    val alignas = alignas (ty_string, a1, a2)
    val atomic = x5f_Atomic (ty_string, a1, a2)
    val asm = asm (ty_string, a1, a2)
    val auto = auto (ty_string, a1, a2)
    val break = break (ty_string, a1, a2)
    val bool = x5f_Bool (ty_string, a1, a2)
    val case0 = case0 (ty_string, a1, a2)
    val char = char (ty_string, a1, a2)
    val const = const (ty_string, a1, a2)
    val continue = continue (ty_string, a1, a2)
    val complex = x5f_Complex (ty_string, a1, a2)
    val default = default (ty_string, a1, a2)
    val do0 = do0 (ty_string, a1, a2)
    val double = double (ty_string, a1, a2)
    val else0 = else0 (ty_string, a1, a2)
    val enum = enum (ty_string, a1, a2)
    val extern = extern (ty_string, a1, a2)
    val float = float (ty_string, a1, a2)
    val for0 = for0 (ty_string, a1, a2)
    val generic = x5f_Generic (ty_string, a1, a2)
    val goto = goto (ty_string, a1, a2)
    val if0 = if0 (ty_string, a1, a2)
    val inline = inline (ty_string, a1, a2)
    val int = int (ty_string, a1, a2)
    val int128 = x5f_x5f_int_x31_x32_x38 (ty_string, a1, a2)
    val long = long (ty_string, a1, a2)
    val label = x5f_x5f_label_x5f_x5f (ty_string, a1, a2)
    val noreturn = x5f_Noreturn (ty_string, a1, a2)
    val nullable = x5f_Nullable (ty_string, a1, a2)
    val nonnull = x5f_Nonnull (ty_string, a1, a2)
    val register = register (ty_string, a1, a2)
    val restrict = restrict (ty_string, a1, a2)
    val return0 = return0 (ty_string, a1, a2)
    val short = short (ty_string, a1, a2)
    val signed = signed (ty_string, a1, a2)
    val sizeof = sizeof (ty_string, a1, a2)
    val static = static (ty_string, a1, a2)
    val staticassert = x5f_Static_assert (ty_string, a1, a2)
    val struct0 = struct0 (ty_string, a1, a2)
    val switch = switch (ty_string, a1, a2)
    val typedef = typedef (ty_string, a1, a2)
    val typeof = typeof (ty_string, a1, a2)
    val thread = x5f_x5f_thread (ty_string, a1, a2)
    val union = union (ty_string, a1, a2)
    val unsigned = unsigned (ty_string, a1, a2)
    val void = void (ty_string, a1, a2)
    val volatile = volatile (ty_string, a1, a2)
    val while0 = while0 (ty_string, a1, a2)
    val cchar = cchar (ty_cChar, a1, a2)
    val cint = cint (ty_cInteger, a1, a2)
    val cfloat = cfloat (ty_cFloat, a1, a2)
    val cstr = cstr (ty_cString, a1, a2)
    val ident = ident (ty_ident, a1, a2)
    val tyident = tyident (ty_ident, a1, a2)
    val attribute = x5f_x5f_attribute_x5f_x5f (ty_string, a1, a2)
    val extension = x5f_x5f_extension_x5f_x5f (ty_string, a1, a2)
    val real = x5f_x5f_real_x5f_x5f (ty_string, a1, a2)
    val imag = x5f_x5f_imag_x5f_x5f (ty_string, a1, a2)
    val builtinvaarg = x5f_x5f_builtin_va_arg (ty_string, a1, a2)
    val builtinoffsetof = x5f_x5f_builtin_offsetof (ty_string, a1, a2)
    val builtintypescompatiblep = x5f_x5f_builtin_types_compatible_p (ty_string, a1, a2)
    val clangcversion = clangcversion (ty_ClangCVersion, a1, a2)
    in case x of
      "_Alignas" => alignas
    | "_Alignof" => alignof
    | "__alignof" => alignof
    | "alignof" => alignof
    | "__alignof__" => alignof
    | "__asm" => asm
    | "asm" => asm
    | "__asm__" => asm
    | "_Atomic" => atomic
    | "__attribute" => attribute
    | "__attribute__" => attribute
    | "auto" => auto
    | "_Bool" => bool
    | "break" => break
    | "__builtin_offsetof" => builtinoffsetof
    | "__builtin_types_compatible_p" => builtintypescompatiblep
    | "__builtin_va_arg" => builtinvaarg
    | "case" => case0
    | "char" => char
    | "_Complex" => complex
    | "__complex__" => complex
    | "__const" => const
    | "const" => const
    | "__const__" => const
    | "continue" => continue
    | "default" => default
    | "do" => do0
    | "double" => double
    | "else" => else0
    | "enum" => enum
    | "__extension__" => extension
    | "extern" => extern
    | "float" => float
    | "for" => for0
    | "_Generic" => generic
    | "goto" => goto
    | "if" => if0
    | "__imag" => imag
    | "__imag__" => imag
    | "__inline" => inline
    | "inline" => inline
    | "__inline__" => inline
    | "int" => int
    | "__int128" => int128
    | "__label__" => label
    | "long" => long
    | "_Nonnull" => nonnull
    | "__nonnull" => nonnull
    | "_Noreturn" => noreturn
    | "_Nullable" => nullable
    | "__nullable" => nullable
    | "__real" => real
    | "__real__" => real
    | "register" => register
    | "__restrict" => restrict
    | "restrict" => restrict
    | "__restrict__" => restrict
    | "return" => return0
    | "short" => short
    | "__signed" => signed
    | "signed" => signed
    | "__signed__" => signed
    | "sizeof" => sizeof
    | "static" => static
    | "_Static_assert" => staticassert
    | "struct" => struct0
    | "switch" => switch
    | "__thread" => thread
    | "_Thread_local" => thread
    | "typedef" => typedef
    | "__typeof" => typeof
    | "typeof" => typeof
    | "__typeof__" => typeof
    | "union" => union
    | "unsigned" => unsigned
    | "void" => void
    | "__volatile" => volatile
    | "volatile" => volatile
    | "__volatile__" => volatile
    | "while" => while0
    | _ => error
    end
end
end
\<close>

end
