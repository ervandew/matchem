" Author: Eric Van Dewoestine
" Version: 0.1
"
" Description: {{{
"   Auto adds closing quotes, parens, brackets, etc.
" }}}
"
" License: {{{
"   Copyright (c) 2010 - 2013, Eric Van Dewoestine
"   All rights reserved.
"
"   Redistribution and use of this software in source and binary forms, with
"   or without modification, are permitted provided that the following
"   conditions are met:
"
"   * Redistributions of source code must retain the above
"     copyright notice, this list of conditions and the
"     following disclaimer.
"
"   * Redistributions in binary form must reproduce the above
"     copyright notice, this list of conditions and the
"     following disclaimer in the documentation and/or other
"     materials provided with the distribution.
"
"   * Neither the name of Eric Van Dewoestine nor the names of its
"     contributors may be used to endorse or promote products derived from
"     this software without specific prior written permission of
"     Eric Van Dewoestine.
"
"   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
"   IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
"   THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
"   PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
"   CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
"   EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
"   PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
"   PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
"   LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
"   NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
"   SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
" }}}

if v:version < 700
  finish
endif

runtime plugin/delimitMate.vim
if exists(':DelimitMate')
  echom 'warn: delimitMate detected, disabling matchem.'
  finish
endif

let s:save_cpo=&cpo
set cpo&vim

" Global Variables {{{

if !exists('g:MatchemRepeatFixup')
  let g:MatchemRepeatFixup = 1
endif

if !exists('g:MatchemEndOfLineMapping')
  let g:MatchemEndOfLineMapping = 0
endif

if !exists('g:MatchemExpandCr')
  let g:MatchemExpandCr = 1
endif

if !exists('g:MatchemExpandCrEndChars')
  let g:MatchemExpandCrEndChars = ['}', ']']
endif

if !exists('g:MatchemMaxMatchSearchDepth')
  let g:MatchemMaxMatchSearchDepth = 100
endif

let g:MatchemEdgeCases = {
    \ 'perl': ['s:PerlBackTick'],
    \ 'python': ['s:PythonTripleQuote'],
    \ 'sh': ['s:ShQuote'],
    \ 'vim': ['s:VimCommentStart'],
    \ '*': ['s:HtmlJsLessThan'],
  \ }

let g:MatchemUndoBreakChars = [
    \ '<esc>', '<c-[>', '<c-c>',
    \ '<left>', '<right>', '<up>', '<down>',
    \ '<s-left>', '<s-right>', '<s-up>', '<s-down>',
    \ '<pageup>', '<pagedown>', '<home>', '<end>',
  \ ]

" }}}

function! s:Init() " {{{
  augroup matchem
    autocmd!
    autocmd BufEnter,FileType * call <SID>InitBuffer()
  augroup END

  inoremap <silent> <bs> <c-r>=<SID>MatchRemove("\<lt>bs>")<cr>
  inoremap <silent> <del> <c-r>=<SID>MatchRemove("\<lt>del>")<cr>

  if g:MatchemRepeatFixup
    " hack and a half to get working undo/repeat support
    for char in g:MatchemUndoBreakChars
      let escaped = substitute(char, '<', '\<lt>', '')
      exec 'inoremap <silent> ' . char .
        \ ' <c-r>=<SID>RepeatFixupFlush("' . escaped . '")<cr>' . char
    endfor

    " blatantly stolen from delimitMate to fix the repeat fix up mappings in
    " console vim. without this, having the <esc> mapping makes <left>,
    " <right> and others do weird things.
    if !has('gui_running')
      imap <silent> <C-[>OC <RIGHT>
    endif
  endif

  if g:MatchemExpandCr
    let expr_map = 0
    try
      let map_dict = maparg('<cr>', 'i', 0, 1)
      let expr_map = map_dict.expr
    catch
      " ignore
    endtry

    if expr_map
      " Not compatible w/ expr mappings.
    elseif maparg('<CR>','i') =~ '<CR>'
      let map = maparg('<cr>', 'i')
      let cr = (map =~? '\(^\|[^)]\)<cr>')
      if map =~ '<Plug>'
        let plug = substitute(map, '.\{-}\(<Plug>\w\+\).*', '\1', '')
        let plug_map = maparg(plug, 'i')
        let map = substitute(map, '.\{-}\(<Plug>\w\+\).*', plug_map, '')
      endif
      let funcmap = '^<C-R>=\(\%\(<SNR>\)\?\w\+\)(\(.\{-}\))<CR>$'
      if map =~? funcmap
        let s:CrFunc = substitute(map, funcmap, '\1', '')
        let s:CrFuncArgs = substitute(map, funcmap, '\2', '')
        inoremap <silent> <cr> <c-r>=<SID>ExpandCr(1)<cr>
      else
        exec "inoremap <script> <cr> <c-r>=<SID>ExpandCr(" . cr . ")<cr>" . map
      endif
    else
      inoremap <silent> <cr> <c-r>=<SID>ExpandCr(1)<cr>
    endif
  endif
endfunction " }}}

function! s:InitBuffer() " {{{
  let b:matchemqueue = []
  let b:matchempairs = {}
  let quotes = ['"', "'"]

  if &ft =~ '^\(perl\|ruby\|sh\)$'
    call add(quotes, '`')
  endif

  for pair in split(&matchpairs, ',')
    let [start, end] = split(pair, ':')
    let b:matchempairs[start] = end
  endfor

  for quote in quotes
    if !has_key(b:matchempairs, quote)
      let b:matchempairs[quote] = quote
    endif
  endfor

  for [start, end] in items(b:matchempairs)
    exec printf('inoremap <silent> <buffer> %s %s<c-r>=<SID>MatchStart()<cr>', start, start)
    if start != end
      exec printf('inoremap <silent> <buffer> %s <c-r>=<SID>MatchEnd("%s")<cr>', end, end)
    endif
  endfor

  if g:MatchemEndOfLineMapping
    " add file type based mappings to characters that typically occur at the
    " end of a line to jump to the end of the line and add the character when
    " appropriate

    " open curly and semicoln for langs with c like syntax
    if &ft =~ '^\(c\(pp\|s\)\?\|html.*\|java\|javascript\|perl\|php\)$'
      if maparg(';', 'i') == ''
        inoremap <buffer> <expr> ; <SID>EndOfLine(';')
      endif
      if maparg('{', 'i') == '' || maparg('{', 'i') =~ '_MatchStart()'
        imap <buffer> <expr> { <SID>EndOfLine('{')
      endif

    " colon for python
    elseif &ft == 'python'
      if maparg(':', 'i') == ''
        inoremap <buffer> <expr> : <SID>EndOfLine(':')
      endif
    endif
  endif
endfunction " }}}

function! s:MatchStart() " {{{
  if &paste
    return ''
  endif

  let result = ''
  let col = col('.') - 1
  let line = getline('.')
  let char = line[col - 1]
  let prev_char = len(line) >= col ? line[col - 2] : ''
  let next_char = line[col]
  let match = get(b:matchempairs, char, '')
  let syntax = synIDattr(synIDtrans(synID(line('.'), col, 1)), 'name')
  let ft_syntax = synIDattr(synID(line('.'), col, 1), 'name')
  let prev_syntax = synIDattr(synIDtrans(synID(line('.'), col - 1, 1)), 'name')
  let prev_prev_syntax = synIDattr(synIDtrans(synID(line('.'), col - 2, 1)), 'name')
  let pair = char == match ? s:SearchPair(col, char, char, 0, 0) : 0
  let pairs = char == match ? s:SearchPair(col, char, char, 1, 0) : 0
  let end_chars = values(filter(copy(b:matchempairs), 'v:key != v:val'))

  " handle edge cases
  if !exists('b:MatchemEdgeCases')
    let b:MatchemEdgeCases =
      \ get(g:MatchemEdgeCases, &ft, []) +
      \ get(g:MatchemEdgeCases, '*', [])
  endif
  for edge in b:MatchemEdgeCases
    try
      let Edge = function(edge)
      let [edge_status, edge_result] = Edge(col, line, char)
      if edge_status
        return edge_result
      endif
    catch /E700/
      echohl Error
      echom 'matchem: no edge case function "' . edge . '" found.'
      echohl None
    endtry
  endfor

  " don't auto close ' in lisp files, that would be annoying
  if &lisp && char == "'"
    return ''
  endif

  " starting char preceded by the escape character, so assume it doesn't need
  " to be matched
  if prev_char == '\'
    let result = ''

  " the end match already exists (must check before the apostrophe case below)
  elseif line[col] == match &&
       \ char == match &&
       \ ((pairs % 2) == 1 || s:RepeatFixupPeek(char))
    if s:RepeatFixupDequeue(char)
      " delete the character without polluting the repeat register
      let line = len(line) > 2 ? line[:col - 2] . line[col + 0:] : line[0]
      call setline('.', line)
    else
      let result = "\<del>"
    endif

  " edge case for apostrophes in comments, strings, and plain text (be sure to
  " handle python u'' and r'')
  elseif char == "'" && prev_char =~ '[[:alpha:]]' &&
       \ prev_syntax =~ '^\(Comment\|String\|Normal\|\)$' &&
       \ prev_prev_syntax == prev_syntax
    let result = ''

  " a quote after a word character most likely means that the user is
  " attempting to wrap quotes around existing text (python's raw and unicode
  " string syntax excluded).
  elseif (char == '"' || char == "'") && prev_char =~ '\w' &&
      \ !(&ft == 'python' && ft_syntax =~ 'python\(Raw\|Uni\)String')
    let result = ''

  " starting delimiter is being added in front of something that isn't a
  " space, closing delim, or some punctuations, so don't annoy the user by
  " adding the end automatically.
  elseif next_char != '' &&
       \ next_char != char &&
       \ next_char !~ '[[:space:];:.,' . escape(join(end_chars, ''), ']') . ']'
    let result = ''

  " open paren being added in front of an open paren, don't auto close since
  " this is a common case where a user may just want to wrap another
  " expression in parens.
  elseif char == '(' && next_char == '('
    let result = ''

  " starting delimiter in front of a closing one, and the closing one has its
  " starting counterpart in a string, so don't auto close
  elseif next_char =~ '[' . escape(join(end_chars, ''), ']') . ']' &&
       \ synIDattr(synID(
       \   line('.'),
       \   s:SearchPair(col + 1, s:GetStartChar(next_char), next_char, 0, 0), 1), 'name'
       \ ) =~ 'String'
    let result = ''

  " user is manually closing an open string
  elseif char == match && pair > 0 && pair < col &&
       \ (pairs % 2) == 1 &&
       \ (syntax =~ '^\(String\|Constant\|Delimiter\)$' || &ft == '')
    let result = ''

  " user possibly wrapping existing code block in {}.
  " last condition here accounts for adding an }else{ to an exiting if {}
  elseif char == '{' && col('.') == col('$') && &indentkeys =~ '{' && &ft != 'ruby' &&
       \ prev_char != ']' &&
       \ (getline(line('.') + 1) !~ '^\s*}\?\s*$' ||
       \  (getline(line('.') + 1) =~ '^\s*}' && indent('.') == indent(line('.') + 1)))
    let result = ''

  " all other cases exhausted, so add the match and move the cursor
  else
    let line = getline('.')
    let col = col('.')
    call setline('.', line[:col - 2] . match . line[col - 1:])
    call s:RepeatFixupQueue(match)
  endif

  return result
endfunction " }}}

function! s:MatchEnd(char) " {{{
  if &paste
    return a:char
  endif

  let result = ''
  let col = col('.')
  let line = getline('.')

  if line[col - 1] != a:char
    return a:char
  endif

  " the same end character already exists, see if we should delete it

  " get the start and end characters
  let end = line[col - 1]
  let start = s:GetStartChar(end)

  " if we've added the end character, then overwrite it.
  if s:RepeatFixupPeek(end)
    call s:RepeatFixupDequeue(end)
    call setline('.', line[:col - 2] . line[col + 0:])
    let result = a:char

  else
    " find the last occurrence of the end character in the series
    let last_col = len(substitute(
      \ getline('.'), '\M\(\.\*\%' . col . 'c' . end . '\*\)\.\*', '\1', ''))

    " move to that position
    let pos = getpos('.')
    call cursor(0, last_col)

    " now see if that one has a matching start
    let skip = "getline('.')[col('.') - 2] == '\\' || " .
      \ "synIDattr(synIDtrans(synID(line('.'), col('.'), 1)), 'name') == 'String'"
    let pair = searchpairpos('\M' . start, '', '\M' . end, 'bn', skip)
    call setpos('.', pos)

    " no matching start, so add the character
    if pair[0] == 0
      let result = a:char

    " matching start found
    else
      " we auto added the end char, so dequeue it and return the user entered one
      if s:RepeatFixupDequeue(end)
        call setline('.', line[:col - 2] . line[col + 0:])
        let result = a:char

      else
        let result = a:char . "\<del>"

        " walk up the file until we find a start w/ no end or hit the top. in
        " the prior case we know the char needs to be added, in the latter we
        " assume we'll just overwrite it.
        let save_pos = getpos('.')
        try
          let cur = [line('.'), col('.')]
          let pick = cur
          let pair = [0, 0]
          let depth = 0
          let pos = searchpos(start, 'bW')
          while pos[0] && depth < g:MatchemMaxMatchSearchDepth
            let pair = searchpairpos('\M' . start, '', '\M' . end, 'nW', skip)
            if !pair[0]
              let pick = pos
              break
            endif
            let pos = searchpos(start, 'bW')
            let depth += 1
          endwhile

          if pick != cur
            let result = a:char
          endif
        finally
          call setpos('.', save_pos)
        endtry
      endif
    endif
  endif

  return result
endfunction " }}}

function! s:MatchRemove(char) " {{{
  if !exists('b:matchempairs')
    return a:char
  endif

  let result = a:char
  let col = col('.') - 1
  let line = getline('.')
  let char = line[col - 1]
  let match = get(b:matchempairs, char, '')
  if match != '' && line[col] == match
    if s:RepeatFixupDequeue(match)
      " delete the auto matched character w/out polluting the repeat register
      if a:char == "\<bs>"
        if len(line) == 2
          call setline('.', ' ')
        else
          call setline('.', line[:col - 2] . line[col + 0:])
        endif

      " <del>, just remove the auto added end char.
      else
        call setline('.', line[:col - 1] . line[col + 1:])
        return ''
      endif
    endif
  elseif match != '' && line[col - 2] == match
    call s:RepeatFixupDequeue(match)
  endif
  return result
endfunction " }}}

function! s:RepeatFixupQueue(char) " {{{
  call add(b:matchemqueue, a:char)
endfunction " }}}

function! s:RepeatFixupDequeue(char) " {{{
  if len(b:matchemqueue) && b:matchemqueue[-1] == a:char
    call remove(b:matchemqueue, -1)
    return 1
  endif
  return 0
endfunction " }}}

function! s:RepeatFixupPeek(char) " {{{
  if len(b:matchemqueue) && b:matchemqueue[-1] == a:char
    return 1
  endif
  return 0
endfunction " }}}

function! s:RepeatFixupFlush(char) " {{{
  if !exists('b:matchemqueue')
    return ''
  endif

  let result = ''
  if len(b:matchemqueue) && !(a:char =~ 'up\|down' && pumvisible())
    let result = join(reverse(b:matchemqueue), '')
    let b:matchemqueue = []
    let line = getline('.')
    let col = col('.')
    let start = max([col - 2, 0])
    if start >= 0 || a:char == '<cr>'
      let pre = line[:start]
    else
      let pre = ''
    endif
    call setline('.', pre . line[col + len(result) - 1:])

    " make sure the cursor ends up where the user expects it to when leaving
    " insert mode.
    if a:char =~ '^\(<esc>\|<c-\[>\|<c-c>\)$'
      let num = len(result)
      while num > 0
        let result .= "\<left>"
        let num -= 1
      endwhile
    endif
  endif
  return result
endfunction " }}}

function! s:EndOfLine(char) " {{{
  let col = col('.')
  let line = getline('.')
  let end = line[col - 1]

  " if we are in a string/comment, error on the side of assuming the user
  " wants to input the character at the current cursor position.
  let syntax_id = synID(line('.'), col, 1)
  let syntax_base = synIDattr(synIDtrans(syntax_id), 'name')
  let syntax_name = synIDattr(syntax_id, 'name')
  if syntax_base =~ 'String\|Comment' || syntax_name =~ 'javaCharacter'
    return a:char
  endif

  " if the next char is not a closing delim or it is but wasn't auto
  " added, then don't prevent the user from manually adding the char at
  " the current position.
  if !s:RepeatFixupPeek(end)
    if has_key(b:matchempairs, a:char)
      call feedkeys(a:char . "\<c-r>=<SNR>" . s:SID() . "_MatchStart()\<cr>", 'n')
      return ''
    endif
    return a:char
  endif

  " if cursor is already at the end of the line, don't prevent the user
  " from manually adding the char (for cases that the logic below gets
  " it wrong)
  if col('.') == col('$')
    if has_key(b:matchempairs, a:char)
      call feedkeys(a:char . "\<c-r>=<SNR>" . s:SID() . "_MatchStart()\<cr>", 'n')
      return ''
    endif
    return a:char
  endif

  " edge case for ; and 'for' loops
  if a:char == ';' && line =~ '^\s*for\>'
    return a:char
  endif

  " edge case for : in python w/ dicts and list slicing
  if a:char == ':' && &ft == 'python' && end =~ '[}\]]'
    return a:char
  endif

  call feedkeys("\<END>")

  let start = 1
  while line[start - 1] =~ '\s'
    let start += 1
  endwhile
  "let start_syntax = synIDattr(synIDtrans(synID(line('.'), start, 1)), 'name')
  "if line =~ '^\s*\(return\|my\)\>'
  "  let start_syntax = ''
  "endif
  if line !~ a:char . '\s*$' "&& start_syntax !~ 'Conditional\|PreProc\|Statement\|Type'
    if has_key(b:matchempairs, a:char)
      call feedkeys(a:char . "\<c-r>=<SNR>" . s:SID() . "_MatchStart()\<cr>", 'n')
    else
      call feedkeys(a:char, 'n')
    endif
  endif

  return ''
endfunction " }}}

function! s:ExpandCr(cr) " {{{
  let CrFuncResult = ''
  if exists('s:CrFunc')
    exec 'let CrFuncResult = function(s:CrFunc)(' . s:CrFuncArgs . ')'
  endif

  if &paste
    return ''
  endif

  " don't get in the way of code completion mappings
  if pumvisible()
    return CrFuncResult
  endif

  " hack to cooperate with supertab
  if exists('b:supertab_pumwasvisible')
    return ''
  endif

  if !exists('b:MatchemExpandCrEndChars')
    let b:MatchemExpandCrEndChars = g:MatchemExpandCrEndChars
  endif

  let col = col('.')
  let line = getline('.')

  " flush on every <cr> to handle apparent vim bug w/ undo:
  " - empty file:
  "   (<cr>)
  "   - undo won't remove the auto added close paren
  "   - if there is blank line below, then undo works correctly
  "     - somehow related to Path 7.3.452 (undo + paste close to last line)?
  let result = s:RepeatFixupFlush('<cr>')
  let lefts = ""
  let index = 0
  while index < len(result)
    let lefts .= "\<left>"
    let index += 1
  endwhile
  let result .= lefts

  let char = line[col - 1]
  let prev = len(line) >= (col - 2) ? line[col - 2] : ''
  if index(b:MatchemExpandCrEndChars, char) != -1 &&
   \ index(values(b:matchempairs), char) != -1 &&
   \ prev == s:GetStartChar(char)

    " only return a cr if nothing else is mapped to it since we don't want
    " to duplicate a cr returned by another mapping.
    let result .= (a:cr ? "\<cr>" : "")

    " ensures that the indenting is handled by the ft indent script, but
    " breaks redo.
    return result . "\<esc>\<up>o"
  endif

  let result .= ((a:cr && CrFuncResult !~ "\<cr>") ? "\<cr>" : "")
  return result . CrFuncResult
endfunction " }}}

function! s:GetStartChar(end) " {{{
  let start = ''
  for [s, e] in items(b:matchempairs)
    if e == a:end
      let start = s
      break
    endif
  endfor
  return start
endfunction " }}}

function! s:SearchPair(col, start, end, count, skip_string) " {{{
  let start = '\M' . a:start
  let end = '\M' . a:end
  " skip over escape sequences
  let skip = "getline('.')[col('.') - 2] == '\\'"
  if a:skip_string
    let skip .= ' || synIDattr(synIDtrans(synID(line("."), col("."), 1)), "name") == "String"'
  endif
  if a:count
    let flags = 'bnmr'
    let Search = function('searchpair')
  else
    let flags = 'bn'
    let Search = function('searchpairpos')
  endif
  if a:col != col('.')
    let pos = getpos('.')
    call cursor(0, a:col)
    let result = Search(start, '', end, flags, skip, line('.'))
    call setpos('.', pos)
  else
    let result = Search(start, '', end, flags, skip, line('.'))
  endif
  return a:count ? result : result[1]
endfunction " }}}

function! s:SID() "{{{
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfunction " }}}

function! s:VimCommentStart(col, line, char) " {{{
  " for vim files don't complete a double quote if it's starting a comment.
  if a:char == '"'
    " crazy edge case for vim syntax where a trailing comment on a line isn't
    " recognized until after a character follows the quote
    let restore = 0
    if a:line =~ '"$'
      let restore = 1
      call setline('.', a:line . ' ')
      redraw
    endif
    let syntax_here = synIDattr(synID(line('.'), a:col, 1), 'name')
    let prev_col = len(substitute(getline('.'), '^\(.*\S\)\s*\%' . a:col . 'c.*', '\1', ''))
    if prev_col < a:col
      let syntax_prev = synIDattr(synID(line('.'), prev_col, 1), 'name')
    else
      let syntax_prev = synIDattr(synID(line('.'), a:col - 1, 1), 'name')
    endif
    if restore
      call setline('.', a:line)
    endif
    if syntax_here =~? 'Comment' && (
          \ (syntax_prev !~? 'Comment' && syntax_prev != 'vimOper') ||
          \ a:line =~ '^\s*\%' . (a:col - 1) . 'c')
      return [1, '']
    endif
  endif
  return [0, '']
endfunction " }}}

function! s:PythonTripleQuote(col, line, char) " {{{
  " for python files, don't add the end quote for the third quote in a series.
  if a:char == '"' || a:char == "'"
    if a:line[a:col - 2] == a:char && a:line[a:col - 3] == a:char
      if a:line[a:col - 1] == a:char
        " handle case where second quote added the third, then user typed the
        " third, so we need to eat the one auto added.
        if s:RepeatFixupDequeue(a:char)
          call setline('.', a:line[:a:col - 2] . a:line[a:col + 0:])
        endif
      endif
      return [1, '']
    endif
  endif
  return [0, '']
endfunction " }}}

function! s:PerlBackTick(col, line, char) " {{{
  " handle manual back tick close for perl files
  if s:SpecialQuote(a:col, a:line, a:char, '`', 'perlMatchStartEnd')
    return [1, '']
  endif
  return [0, '']
endfunction " }}}

function! s:HtmlJsLessThan(col, line, char) " {{{
  if a:char == '<' && (&ft =~ 'html' || &ft == 'php')
    let script_start = search('<script\>', 'bnW')
    let script_end = search('</script\>', 'bnW')
    if script_start && script_start > script_end
      return [1, '']
    endif
  endif
  return [0, '']
endfunction " }}}

function! s:ShQuote(col, line, char) " {{{
  " handle manual quote close for sh files
  if s:SpecialQuote(a:col, a:line, a:char, '"', 'shQuote')
    return [1, '']
  endif

  " handle manual back tick close for sh files
  if s:SpecialQuote(a:col, a:line, a:char, '`', 'shCommandSub')
    return [1, '']
  endif

  return [0, '']
endfunction " }}}

function! s:SpecialQuote(col, line, char, quote, syntax_name) " {{{
  if a:char == a:quote
    let syntax = synIDattr(synID(line('.'), a:col, 1), 'name')
    let pair = s:SearchPair(a:col, a:char, a:char, 0, 0)
    let pairs = s:SearchPair(a:col, a:char, a:char, 1, 0)
    if pair > 0 &&
     \ pair < a:col &&
     \ syntax == a:syntax_name &&
     \ (pairs % 2) == 1 &&
     \ a:line[a:col] != a:char
      return 1
    endif
  endif

  return 0
endfunction " }}}

call s:Init()

let &cpo = s:save_cpo

" vim:ft=vim:fdm=marker
