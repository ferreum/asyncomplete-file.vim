function! s:filename_map(prefix, cwd, base) abort
  if empty(a:base) || a:base ==# '.' || a:base ==# '..'
    " filtered out later
    return v:null
  endif

  let l:word = a:prefix . a:base

  if isdirectory(a:cwd . '/' . a:base)
    let l:menu = '[dir]'
    let l:word .= '/'
  else
    let l:menu = '[file]'
  endif

  return {
        \ 'menu': l:menu,
        \ 'word': l:word,
        \ 'icase': 1,
        \ 'dup': 0
        \ }
endfunction

let s:last_job = ''
function! asyncomplete#sources#file#completor(opt, ctx) abort
  try
    call job_stop(s:last_job)
  catch
    " first job or already stopped
  endtry
  let s:last_job = ''

  let l:bufnr = a:ctx['bufnr']
  let l:typed = a:ctx['typed']
  let l:col   = a:ctx['col']

  let l:kw    = matchstr(l:typed, '\f*$')
  let l:kwlen = len(l:kw)

  if empty(l:kwlen) || stridx(l:kw, '/') < 0
    return
  endif

  let l:startcol = l:col - l:kwlen

  if l:kw !~ '^\(/\|\~\)'
    let l:cwd = expand('#' . l:bufnr . ':p:h') . '/' . l:kw
  else
    let l:cwd = fnamemodify(l:kw, ':p')
  endif

  if l:cwd =~ '/$'
    let l:tail = ''
  else
    let l:tail = fnamemodify(l:cwd, ':t')
    let l:cwd = fnamemodify(l:cwd, ':h')
  endif

  let l:prefix = fnamemodify(l:kw, ':h')

  if l:prefix !~ '/$'
    let l:prefix = l:prefix . '/'
  endif

  let l:glob = (empty(l:tail) ? '{.,}' : s:smartcasewildcard(l:tail, g:asyncomplete_matchfuzzy)) . '*'
  let l:script = 'shopt -s nullglob; cd ' . shellescape(l:cwd) . ' && printf ''%s\n'' ' . l:glob . ' | sort'

  let l:filectx = {
        \ 'opt': a:opt,
        \ 'ctx': a:ctx,
        \ 'startcol': l:startcol,
        \ 'cwd': l:cwd,
        \ 'prefix': l:prefix,
        \ 'rawlist': [],
        \ }

  let s:last_job = job_start(['/usr/bin/bash', '-c', l:script], {
        \ 'in_io': "null",
        \ 'out_io': "pipe",
        \ 'out_mode': "raw",
        \ 'out_cb': function('s:stdout', [l:filectx.rawlist]),
        \ 'exit_cb': function('s:exit', [l:filectx]),
        \ })
endfunction

function! s:stdout(rawlist, channel, msg) abort
  call add(a:rawlist, a:msg)
endfunction

function! s:exit(filectx, channel, code) abort
  let l:matches = split(join(a:filectx.rawlist, ''), '\n')
  let l:cwd = a:filectx.cwd
  let l:prefix = a:filectx.prefix

  call map(l:matches, {key, val -> s:filename_map(l:prefix, l:cwd, val)})
  call filter(l:matches, {i, m -> m != v:null})

  call asyncomplete#complete(a:filectx.opt.name, a:filectx.ctx, a:filectx.startcol, l:matches)
endfunction

function! asyncomplete#sources#file#get_source_options(opts)
  return extend(extend({}, a:opts), {
        \ 'triggers': {'*': ['/']},
        \ })
endfunction

function! s:smartcasewildcard(str, fuzzy) abort
  if a:str =~ '\u'
    return a:str
  endif
  return s:icasewildcard(a:str, a:fuzzy)
endfunction

function! s:icasewildcard(str, fuzzy) abort
  return map(a:str, { i, c ->
        \  (a:fuzzy && i >= 1 ? '*' : '') .
        \  (c =~ '\a' ? '[' . tolower(c) . toupper(c) . ']' : (c =~ '[-._/]' ? c : shellescape(c)))
        \ })
endfunction
