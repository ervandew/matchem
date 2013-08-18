function TestDoubleBrace() " {{{
  setfiletype htmldjango

  normal i{
  call vunit#AssertEquals(getline('.'), '{', 'Single brace failed.')
  1,$delete _

  normal i{{
  call vunit#AssertEquals(getline('.'), '{{}}', 'Double brace failed.')
  1,$delete _

  normal i{{}}
  call vunit#AssertEquals(getline('.'), '{{}}', 'Double closed brace failed.')
  1,$delete _
endfunction " }}}

" vim:ft=vim:fdm=marker
