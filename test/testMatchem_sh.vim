function TestShQuote() " {{{
  " use split since vunit/vim can't fully clear the syntax
  "set ft=sh
  split test.sh
  echom 'ft: ' . &ft

  call setline('.', 'foo="bar')
  normal A"
  call vunit#AssertEquals(getline('.'), 'foo="bar"', 'Wrong manual close quote.')
  1,$delete _

  call setline('.', 'foo=`bar')
  normal A`
  call vunit#AssertEquals(getline('.'), 'foo=`bar`', 'Wrong manual close tick.')
  1,$delete _

  call setline('.', 'foo=`bar`')
  call cursor(0, 9)
  normal i`
  call vunit#AssertEquals(getline('.'), 'foo=`bar`', 'Wrong end tick.')
  1,$delete _
endfunction " }}}

function TestBashBrackets() " {{{
  " use split since vunit/vim can't fully clear the syntax
  "set ft=sh
  split test.sh
  echom 'ft: ' . &ft

  call setline('.', 'if [ foo ]')
  call cursor(0, 4)
  normal i[
  call vunit#AssertEquals(getline('.'), 'if [[ foo ]', 'Close bracket inserted.')
  1,$delete _

  exec "normal iif [[ foo "
  call vunit#AssertEquals(getline('.'), 'if [[ foo ]]', 'Close brackets not inserted.')
  1,$delete _
endfunction " }}}

" vim:ft=vim:fdm=marker
