function TestQuote() " {{{
  set ft=python

  normal i"
  call vunit#AssertEquals(getline('.'), '""', 'Double quote failed.')
  1,$delete _

  normal i'
  call vunit#AssertEquals(getline('.'), "''", 'Single quote failed.')
  1,$delete _

  normal i"foo"
  call vunit#AssertEquals(getline('.'), '"foo"', 'Double quote overwrite failed.')
  1,$delete _

  normal i'foo'
  call vunit#AssertEquals(getline('.'), "'foo'", 'Single quote overwrite failed.')
  1,$delete _

  call setline('.', '("foo")')
  call cursor(1, 2)
  normal i"bar",
  call vunit#AssertEquals(
    \ getline('.'), '("bar","foo")', 'New string in front of existing failed.')
  1,$delete _

  call setline('.', 'foo = "foo[" + ]"')
  call cursor(1, 16)
  normal i"
  call vunit#AssertEquals(
        \ getline('.'), 'foo = "foo[" + "]"', 'Open string for quoted end delim failed.')
  1,$delete _
endfunction " }}}

function TestParenBracketCurly() " {{{
  exec "normal i[\<esc>"
  call vunit#AssertEquals(getline('.'), '[]', 'Bracket <esc> failed.')
  1,$delete _

  normal i(
  call vunit#AssertEquals(getline('.'), '()', 'Paren failed.')
  1,$delete _

  normal i[
  call vunit#AssertEquals(getline('.'), '[]', 'Bracket failed.')
  1,$delete _

  normal i{
  call vunit#AssertEquals(getline('.'), '{}', 'Curly failed.')
  1,$delete _

  normal i(foo)
  call vunit#AssertEquals(getline('.'), '(foo)', 'Paren overwrite failed.')
  1,$delete _

  normal i[foo]
  call vunit#AssertEquals(getline('.'), '[foo]', 'Bracket overwrite failed.')
  1,$delete _

  normal i{foo}
  call vunit#AssertEquals(getline('.'), '{foo}', 'Curly overwrite failed.')
  1,$delete _
endfunction " }}}

function TestParenNewLine() " {{{
  set ft=python
  exec "normal i(\<cr>\<esc>"
  call vunit#AssertEquals(getline(1), '(', 'Paren failed, line 1.')
  call vunit#AssertEquals(getline(2), ')', 'Paren failed, line 2.')
  1,$delete _

  exec "normal itest = (\<cr>\<esc>"
  call vunit#AssertEquals(getline(1), 'test = (', 'Paren w/ text failed, line 1.')
  call vunit#AssertEquals(getline(2), ')', 'Paren  w/ text failed, line 2.')
  1,$delete _
endfunction " }}}

function TestCurly() " {{{
  set ft=javascript
  exec "normal iif(foo){\<cr>"
  call vunit#AssertEquals(getline(1), 'if(foo){', '1 Wrong line 1.')
  call vunit#AssertEquals(getline(2), '', '1 Wrong line 2.')
  call vunit#AssertEquals(getline(3), '}', '1 Wrong line 3.')
  1,$delete _

  set ft=javascript
  set expandtab shiftwidth=2
  exec "normal iif(foo){\<cr>alert(bar);"
  call vunit#AssertEquals(getline(1), 'if(foo){', '2 Wrong line 1.')
  call vunit#AssertEquals(getline(2), '  alert(bar);', '2 Wrong line 2.')
  call vunit#AssertEquals(getline(3), '}', '2 Wrong line 3.')
  1,$delete _

  set ft=javascript
  exec "normal iif(foo){\<cr>}else{"
  call vunit#AssertEquals(getline(1), 'if(foo){', '3 Wrong line 1.')
  call vunit#AssertEquals(getline(2), '}else{', '3 Wrong line 2.')
  call vunit#AssertEquals(getline(3), '}', '3 Wrong line 3.')
  1,$delete _
endfunction " }}}

function TestManualClose() " {{{
  set ft=python

  call setline('.', 'foo = "bar')
  call vunit#AssertEquals(getline('.'), 'foo = "bar', 'Wrong initial quote state.')
  normal A"
  call vunit#AssertEquals(getline('.'), 'foo = "bar"', 'Wrong manual close quote.')
  1,$delete _

  call setline('.', 'foo = ("bar')
  call vunit#AssertEquals(getline('.'), 'foo = ("bar', 'Wrong initial quote/paren state.')
  normal A")
  call vunit#AssertEquals(getline('.'), 'foo = ("bar")', 'Wrong manual close quote/paren.')
  1,$delete _
endfunction " }}}

function TestManualQuote() " {{{
  call setline('.', 'foo = foo')
  call vunit#AssertEquals(getline('.'), 'foo = foo', 'Wrong initial state.')
  normal A"
  call vunit#AssertEquals(getline('.'), 'foo = foo"', 'Wrong trailing quote result.')
  call cursor(1, 7)
  normal i"
  call vunit#AssertEquals(getline('.'), 'foo = "foo"', 'Wrong leading quote result.')
  1,$delete _
endfunction " }}}

function TestAddParens() " {{{
  set ft=python

  call setline('.', 'foo = ("bar", "baz")')
  call vunit#AssertEquals(
    \ getline('.'), 'foo = ("bar", "baz")', 'Wrong initial state.')
  call cursor(1, 15)
  exec "normal i(\<esc>"
  call vunit#AssertEquals(
    \ getline('.'), 'foo = ("bar", ("baz")', 'Wrong new open paren.')
  call cursor(1, 21)
  exec "normal i)\<esc>"
  call vunit#AssertEquals(
    \ getline('.'), 'foo = ("bar", ("baz"))', 'Wrong new close paren add.')
  call cursor(1, 22)
  exec "normal i)\<esc>"
  call vunit#AssertEquals(
    \ getline('.'), 'foo = ("bar", ("baz"))', 'Wrong new close paren overwrite.')
  1,$delete _

  call setline('.', 'foo = ("bar", "baz")')
  call cursor(1, 7)
  exec "normal i(\<esc>"
  call vunit#AssertEquals(
    \ getline('.'), 'foo = (("bar", "baz")', 'Wrong leading open paren.')
  1,$delete _
endfunction " }}}

function TestDelete() " {{{
  exec "normal ifoo = '\<bs>"
  call vunit#AssertEquals(getline('.'), 'foo = ', 'Insert + backspace failed.')
  1,$delete _

  call setline('.', "foo = ''")
  call cursor(1, 8)
  exec "normal i\<del>"
  call vunit#AssertEquals(getline('.'), "foo = '", 'Delete from middle failed.')
  1,$delete _

  exec "normal ifoo = '\<del>\<esc>"
  call vunit#AssertEquals(getline('.'), "foo = '", 'Insert + delete from middle failed.')
  1,$delete _

  exec "normal i'\<bs>"
  call vunit#AssertEquals(getline('.'), "", 'Insert + baskspace from middle failed.')
  1,$delete _
endfunction " }}}

function TestRepeat() " {{{
  set ft=python

  " single line repeat
  exec "normal ofoo = \"foo\<esc>"
  call vunit#AssertEquals(getline(2), 'foo = "foo"', 'Double quote close failed.')
  normal .
  call vunit#AssertEquals(getline(2), 'foo = "foo"', 'Wrong line 1 after repeat.')
  call vunit#AssertEquals(getline(3), 'foo = "foo"', 'Wrong line 2 after repeat.')
  1,$delete _

  " multi line repeat
  call setline('.', '#first line')
  call append(1, '#last line')
  exec "normal ofoo = 'foo'\<cr>bar = 'bar'\<cr>baz = 'baz\<esc>"
  call vunit#AssertEquals(getline(1), "#first line", 'Wrong line 1.')
  call vunit#AssertEquals(getline(2), "foo = 'foo'", 'Wrong line 2.')
  call vunit#AssertEquals(getline(3), "bar = 'bar'", 'Wrong line 3.')
  call vunit#AssertEquals(getline(4), "baz = 'baz'", 'Wrong line 4.')
  call vunit#AssertEquals(getline(5), "#last line", 'Wrong line 5.')

  normal .
  call vunit#AssertEquals(getline(1), "#first line", 'Wrong line 1 after repeat.')
  call vunit#AssertEquals(getline(2), "foo = 'foo'", 'Wrong line 2 after repeat.')
  call vunit#AssertEquals(getline(3), "bar = 'bar'", 'Wrong line 3 after repeat.')
  call vunit#AssertEquals(getline(4), "baz = 'baz'", 'Wrong line 4 after repeat.')
  call vunit#AssertEquals(getline(5), "foo = 'foo'", 'Wrong line 5 after repeat.')
  call vunit#AssertEquals(getline(6), "bar = 'bar'", 'Wrong line 6 after repeat.')
  call vunit#AssertEquals(getline(7), "baz = 'baz'", 'Wrong line 7 after repeat.')
  call vunit#AssertEquals(getline(8), '#last line', 'Wrong last line after repeat.')
endfunction " }}}

function TestUndo() " {{{
  set ft=python

  call setline('.', '#first line')
  call append(1, '#last line')
  exec "normal i\<c-g>u"
  exec "normal ofoo = 'foo'\<cr>bar = 'bar\<esc>"
  call vunit#AssertEquals(getline(1), "#first line", 'Wrong line 1.')
  call vunit#AssertEquals(getline(2), "foo = 'foo'", 'Wrong line 2.')
  call vunit#AssertEquals(getline(3), "bar = 'bar'", 'Wrong line 3.')
  call vunit#AssertEquals(getline(4), "#last line", 'Wrong line 4.')

  undo
  call vunit#AssertEquals(line('$'), 2, 'Wrong line numbers after undo.')
  call vunit#AssertEquals(getline(1), '#first line', 'Wrong first line after undo.')
  call vunit#AssertEquals(getline(2), '#last line', 'Wrong last line after undo.')
  1,$ delete _

  " For some reason this fails. Something about the third+ set of match
  " completions is tripping up vim's undo logic. DelimitMate suffers from the
  " same issue (tested w/ vim 7.3.69).
"  call setline('.', '#first line')
"  call append(1, '#last line')
"  exec "normal i\<c-g>u"
"  exec "normal ofoo = 'foo'\<cr>bar = 'bar'\<cr>baz = 'baz\<esc>"
"  call vunit#AssertEquals(getline(1), "#first line", 'Wrong line 1.')
"  call vunit#AssertEquals(getline(2), "foo = 'foo'", 'Wrong line 2.')
"  call vunit#AssertEquals(getline(3), "bar = 'bar'", 'Wrong line 3.')
"  call vunit#AssertEquals(getline(4), "baz = 'baz'", 'Wrong line 4.')
"  call vunit#AssertEquals(getline(5), "#last line", 'Wrong line 5.')

"  undo
"  let l = 1
"  while l <= line('$')
"    echom '## line: ' . l . ' |' . getline(l) . '|'
"    let l += 1
"  endwhile
"  call vunit#AssertEquals(line('$'), 2, 'Wrong line numbers after undo.')
"  call vunit#AssertEquals(getline(1), '#first line', 'Wrong first line after undo.')
"  call vunit#AssertEquals(getline(2), '#last line', 'Wrong last line after undo.')
endfunction " }}}

function TestParenUndo() " {{{
  exec "normal i(\<cr>\<esc>"
  call vunit#AssertEquals(line('$'), 2, 'Wrong line numbers pre undo.')
  call vunit#AssertEquals(getline(1), "(", 'Wrong pre undo line 1.')
  call vunit#AssertEquals(getline(2), ")", 'Wrong pre undo line 2.')
  undo
  call vunit#AssertEquals(line('$'), 1, 'Wrong line numbers after undo.')
  call vunit#AssertEquals(getline(1), "", 'Wrong after undo line 1.')
endfunction " }}}

function TestExpandCr() " {{{
  set ft=python
  let indent = ''
  let index = 0
  while index < &sw
    let indent .= ' '
    let index += 1
  endwhile

  exec "normal i{\<cr>'foo': 'bar'\<esc>"
  call vunit#AssertEquals(getline(1), '{', 'Curly failed, line 1.')
  call vunit#AssertEquals(getline(2), indent . "'foo': 'bar'", 'Curly failed, line 2.')
  call vunit#AssertEquals(getline(3), '}', 'Paren failed, line 3.')
  1,$delete _

  call setline(1, "test = {'foo': 'bar'}")
  call cursor(1, 9)
  exec "normal i\<cr>\<esc>"
  call vunit#AssertEquals(getline(1), 'test = {', 'Curly insert <cr> failed, line 1.')
  call vunit#AssertEquals(
    \ getline(2), indent . "'foo': 'bar'}", 'Curly insert <cr> failed, line 2.')
  call cursor(2, &sw + 13)
  exec "normal i\<cr>\<esc>"
  call vunit#AssertEquals(getline(1), 'test = {', 'Curly insert <cr> failed, line 1.')
  call vunit#AssertEquals(
    \ getline(2), indent . "'foo': 'bar'", 'Curly insert <cr> failed, line 2.')
  call vunit#AssertEquals(getline(3), '}', 'Curly insert <cr> failed, line 3.')
endfunction " }}}

function TestNestedParenEdgeCase() " {{{
  set ft=python
  call setline(1, 'foo(bar=[])')
  call cursor(1, 10)
  normal i()
  call vunit#AssertEquals(getline('.'), 'foo(bar=[()])', 'Nested paren failed.')
  1,$delete _
endfunction " }}}

" vim:ft=vim:fdm=marker
