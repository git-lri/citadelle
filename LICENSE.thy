theory LICENSE imports LICENSE0 begin license "3-Clause BSD" where \<open>

Copyright (c) 2017-2018 Virginia Tech, USA
              2018-2019 Université Paris-Saclay, Univ. Paris-Sud, France \<close>\<open>

All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above
      copyright notice, this list of conditions and the following
      disclaimer in the documentation and/or other materials provided
      with the distribution.

    * Neither the name of the copyright holders nor the names of its
      contributors may be used to endorse or promote products derived
      from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
"AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
\<close>

country ch where \<open>Switzerland\<close>
country de where \<open>Germany\<close>
country fr where \<open>France\<close>
country sg where \<open>Singapore\<close>
country uk where \<open>UK\<close>
country us where \<open>USA\<close>

holder brucker :: de where \<open>Achim D. Brucker\<close>
holder cam :: uk where \<open>University of Cambridge\<close>
holder contributors where \<open>Contributors (in the changeset history)\<close>
holder ethz :: ch where \<open>ETH Zurich\<close>
holder "irt-systemx" :: fr where \<open>IRT SystemX\<close>
holder ntu :: sg where \<open>Nanyang Technological University\<close>
holder sheffield :: uk where \<open>The University of Sheffield\<close>
holder tum :: de where \<open>Technische Universität München\<close>
holder "u-psud" :: fr where \<open>Université Paris-Saclay\<close>, \<open>Univ. Paris-Sud\<close>
holder vt :: us where \<open>Virginia Tech\<close>
holder wolff :: fr where \<open>B. Wolff\<close>, \<open>Univ. Paris-Saclay\<close>, \<open>Univ. Paris-Sud\<close>

copyright default where 2011-2019 "u-psud"
                        2013-2017 "irt-systemx"
                        2011-2015 brucker
                        2016-2019 sheffield
                        2016-2017 ntu
                        2017-2018 vt

project ROOT :: "3-Clause BSD" where \<open>
http://www.brucker.ch/projects/hol-testgen/
This file is part of HOL-TestGen.
\<close> imports default

project LICENSE0 :: "3-Clause BSD" where \<open>LICENSE\<close> defines 2017-2018 vt
                                                           2018-2019 "u-psud"

project LICENSE :: "3-Clause BSD" where \<open>
theory LICENSE imports LICENSE0 begin license "3-Clause BSD" where
\<close> defines 2017-2018 vt
          2018-2019 "u-psud"

project "Featherweight OCL" :: "3-Clause BSD" where \<open>
Featherweight-OCL --- A Formal Semantics for UML-OCL Version OCL 2.5
                      for the OMG Standard.
                      http://www.brucker.ch/projects/hol-testgen/

This file is part of HOL-TestGen.
\<close> imports default

project Citadelle :: "3-Clause BSD" where \<open>Citadelle\<close> imports default

project Isabelle_Meta_Model :: "3-Clause BSD" where \<open>A Meta-Model for the Isabelle API\<close> imports default

project Isabelle :: "3-Clause BSD" where \<open>
ISABELLE COPYRIGHT NOTICE, LICENCE AND DISCLAIMER.
\<close> defines 1986-2019 cam
          1986-2019 tum
          1986-2019 contributors

project Haskabelle_Meta_Model :: "3-Clause BSD" where \<open>
A Meta-Model for the Haskabelle API
\<close> defines 2007-2015 tum
          2017-2018 vt
          2018-2019 "u-psud"

project "HOL-OCL" :: "3-Clause BSD" where \<open>HOL-OCL\<close> imports default

project "HOL-TOY" :: "3-Clause BSD" where \<open>HOL-TOY\<close> imports default

project "HOL-HKB" :: "3-Clause BSD" where \<open>HOL-HKB\<close> defines 2017-2018 vt
                                                            2018-2019 "u-psud"

project C_Meta_Model :: "3-Clause BSD" where \<open>
A Meta-Model for the Language.C Haskell Library
\<close> defines 2016-2017 ntu
          2017-2018 vt
          2018-2019 "u-psud"

project C_ML :: "3-Clause BSD" where \<open>
Generation of Language.C Grammar with ML Interface Binding
\<close> defines 2018-2019 "u-psud"

project Miscellaneous_Monads :: "3-Clause BSD" where \<open>
HOL-TestGen --- theorem-prover based test case generation
                http://www.brucker.ch/projects/hol-testgen/

Monads.thy --- a base testing theory for sequential computations.
This file is part of HOL-TestGen.
\<close> defines 2005-2007 ethz
          2009 wolff
          2009,2012 brucker
          2013-2016 "u-psud"
          2013-2016 "irt-systemx"

check_license Miscellaneous_Monads
  in file "examples/archive/Monads.thy"
(*
check_license C_ML
  in "../C11-FrontEnd"
*)(*
check_license ROOT
              LICENSE0
              LICENSE
              "Featherweight OCL"
              Citadelle
              Isabelle_Meta_Model
              Isabelle
              Haskabelle_Meta_Model
              "HOL-OCL"
              "HOL-TOY"
              "HOL-HKB"
              C_Meta_Model
  in "."
*)(*
insert_license
map_license
*)
end