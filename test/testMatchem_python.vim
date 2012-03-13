function TestPythonDoubleQuotes() " {{{
  setfiletype python

  normal ir"
  call vunit#AssertEquals(getline('.'), 'r""', 'Raw double quote failed.')
  1,$delete _

  exec "normal iu\"\<esc>"
  call vunit#AssertEquals(getline('.'), 'u""', 'Unicode double quote failed.')
  1,$delete _
endfunction " }}}

function TestPythonSingleQuotes() " {{{
  setfiletype python

  normal ir'
  call vunit#AssertEquals(getline('.'), "r''", 'Raw quote failed.')
  1,$delete _

  exec "normal iu'\<esc>"
  call vunit#AssertEquals(getline('.'), "u''", 'Unicode quote failed.')
  1,$delete _
endfunction " }}}

function TestPythonTripleQuote() " {{{
  set ft=python

  normal i"""
  call vunit#AssertEquals(getline('.'), '"""', 'Triple quote failed.')
  1,$delete _

  normal ir"""
  call vunit#AssertEquals(getline('.'), 'r"""', 'Raw triple quote failed.')
  1,$delete _

  normal iu"""
  call vunit#AssertEquals(getline('.'), 'u"""', 'Unicode triple quote failed.')
  1,$delete _
endfunction " }}}

" vim:ft=vim:fdm=marker
