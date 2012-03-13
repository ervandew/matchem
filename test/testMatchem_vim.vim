function TestVimComment() " {{{
  set ft=vim

  normal ilet foo = "foo
  call vunit#AssertEquals(getline('.'), 'let foo = "foo"', 'Double quote failed.')
  1,$delete _

  normal i"
  call vunit#AssertEquals(getline('.'), '"', 'Leading comment failed.')
  1,$delete _

  normal ifunction foo() "
  call vunit#AssertEquals(getline('.'), 'function foo() "', 'Trailing vim comment failed.')
  1,$delete _
endfunction " }}}

" vim:ft=vim:fdm=marker
