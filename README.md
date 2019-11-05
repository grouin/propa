# propa
Automatic BRAT annotations propagation

## Documentation ##

This toolbox allows to manage annotations produced using the BRAT
rapid annotation tool. Several scripts are provided, to propagate or
to delete annotations.

Files:

* *propagation-configuration.txt*: main configuration file. Please
  indicate the minimum number of characters in entities to authorize
  propagation (e.g., size=3), the minimum number of occurrences that
  must be found along existing annotations for the propagation (e.g.,
  frequency=0), tags for which existing annotations will not be
  propagated (e.g., forbidden=age,date), value to be used in the
  'AnnotatorNotes' field from BRAT to indicate a given annotation must
  not be propagated (e.g., value=STOP), and tokens that must not be
  propagated if found in previous annotations (e.g.,
  blacklist=John,Jane)

* *propagation-v2.pl*: current main script (v1 is an old version)

* *deletion-lexicon.txt*: list of tokens for which existing annotations
  must be deleted

* *deletion-annotation.pl*: script to delete annotations that have been
  erroneously propagated, based on the deletion-lexicon.txt file

* *supprime-annotations-imbriquees.pl*: script to delete overlap
  annotations. Allows to keep the longest annotation for annotations
  having the same start offset. Not a stable version

The same two options are available for all PERL scripts:

* -r &lt;directory containing ann/txt files&gt;
* -s &lt;starting file name&gt;

The last option is useful in order to do not propagate existing
annotations on already processed files
  
## License ##

This toolbox is licenced under the term of the two-clause BSD Licence:

    Copyright (c) 2016  CNRS
    All rights reserved.

    Redistribution and use in source and binary forms, with or without
    modification, are permitted provided that the following conditions
    are met:
        * Redistributions of source code must retain the above
          copyright notice, this list of conditions and the following
          disclaimer.
        * Redistributions in binary form must reproduce the above
          copyright notice, this list of conditions and the following
          disclaimer in the documentation and/or other materials
          provided with the distribution.

    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND
    CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES,
    INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
    MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
    DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS
    BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
    EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
    TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
    ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
    TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
    THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
    SUCH DAMAGE.

## Citing ##

If you do make use of brat or components from brat for annotation
purposes, please cite the following publication:

    @inproceedings{grouin2016lrec,
        author      = {Grouin, Cyril},
        title       = {Controlled propagation
                of concept annotations in textual corpora},
        booktitle   = {Proc of LREC},
        year        = {2016},
        address     = {Portoro\v{z}, Slovenia},
        publisher   = {European Language Resources Association (ELRA)},
    }

## Contact ##

For help and feedback please contact the author below:

* Grouin Cyril       &lt;cyril.grouin@limsi.fr&gt;

This work was supported by the ANSM (French National Agency for
Medicines and Health Products Safety) through the Vigi4MED project
(grant ANSM-2013-S-060).