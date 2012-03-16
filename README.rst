.. Copyright (c) 2012, Eric Van Dewoestine
   All rights reserved.

   Redistribution and use of this software in source and binary forms, with
   or without modification, are permitted provided that the following
   conditions are met:

   * Redistributions of source code must retain the above
     copyright notice, this list of conditions and the
     following disclaimer.

   * Redistributions in binary form must reproduce the above
     copyright notice, this list of conditions and the
     following disclaimer in the documentation and/or other
     materials provided with the distribution.

   * Neither the name of Eric Van Dewoestine nor the names of its
     contributors may be used to endorse or promote products derived from
     this software without specific prior written permission of
     Eric Van Dewoestine.

   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

.. _overview:

==================
Overview
==================

MatchEm is a vim plugin which auto adds closing quotes, parens, brackets,
curlies and other such characters as you type.  Using matchem doesn't involve
any change of behavior on your part. Simple type your code as you normally
would and matchem will handle auto adding closing quotes, etc as necessary and
overwriting them accordingly if you continue to manually type the closing
character.

Why write another auto matching plugin?
---------------------------------------

**tl;dr** Matchem is built to handle `edge cases`_ not handled by
delimitMate and other similar plugins.

At this point delimitMate_ seems to be the standard plugin to choose for auto
adding of closing characters. DelimitMate is a great plugin and while writing
matchem I quickly learned how much effort goes into a seemingly simple plugin
so I certainly don't want to diminish its usefulness.

However, after using delimiteMate for awhile I found myself running into
several edge cases where delimitMate didn't do the right thing and I had to
stop, correct its mistake, then get back to what I was doing. This happened
enough that I removed delimitMate altogether, but then I found my self missing
it for the cases it did get right. I looked at the delimitMate code in hopes to
just updated it to handle the edge cases, but I decided that it might be easier
to just start from scratch.

Matchem was written with the intention to clearly address as many edge cases as
possible (and provide the means to inject your own edge case handlers) so that
you aren't interrupting your flow by correcting mistakes made by the matcher.

.. _edge cases:

Below is a non-comprehensive list of various scenarios where delimitMate didn't
do the right thing. The example text you see is the result when using matchem,
but you can try typing these "as is" using delimitMate to see how it handles
these cases. For the cases with "before:" and "after:", the | denotes where
the insert was started on the existing "before" text.

- Handle not auto-adding closing curly if one already exists on a lower line

  ::

    if (foo){
    }else{
    }

- Better handling of when closing character should be added or overwritten

  ::

    before: foo = ("bar", |"baz"|)
    after:  foo = ("bar", ("baz"))

- Inserting a quoted string before another quoted string

  ::

    before: (|"foo")
    after:  ("bar", "foo")

- Inserting quotes inside existing matched characters in a string

  ::

    before: foo = "bar[|i]"
    after:  foo = "bar[" + i + "]"

- Wrapping open/close characters around existing code

  ::

    before: foo = |(bar)
    after:  foo = [(bar)]

- Don't consider an escaped quote as a match when deciding when to overwrite

  ::

    foo = "\""

- Don't auto match < when typing within script tags in html and php files

  ::

    <html>
      <script>
        if (foo < 0){
        }
      </script>
    </html>

- Python unicode and raw string matching

  ::

    u'test'
    r'test'

- Python triple quote string matching.

  ::

    """
    Test
    """

- Don't auto match ' in lisp, scheme, etc files.

- Avoid matching quotes on trailing vim script comments.

  ::

    function Test() " test comment

- Better undo/repeat support. Still not perfect due to at least one
  outstanding vim bug that delimiMate suffers from as well.

.. _delimitMate: https://github.com/Raimondi/delimitMate
