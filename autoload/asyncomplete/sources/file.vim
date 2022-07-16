if has('win32') || has('win64')
  echohl ErrorMsg
  echom "this version of asyncomplete-file.vim does not work on MS-Windows"
  echohl None
  finish
endif

function! asyncomplete#sources#file#get_source_options(opts)
  let l:opts = extend(extend({}, a:opts), {
        \ 'triggers': {'*': ['/']},
        \ })
  let l:opts['config'] = extend({
        \ 'max_path_length': 256,
        \ }, get(l:opts, 'config', {}))
  return l:opts
endfunction

let s:last_job = ''
function! asyncomplete#sources#file#completor(opt, ctx) abort
  try
    call job_stop(s:last_job)
  catch
    " first job or already stopped
  endtry
  let s:last_job = ''

  let l:typed = a:ctx['typed']
  let l:col   = a:ctx['col']

  let [l:kw, l:cwd, l:escaped] = s:find_path(a:opt, a:ctx, l:typed)
  let l:kwlen = len(l:kw)

  if l:kwlen < 1
    return
  endif

  if l:kw =~ '/$'
    let l:tail = ''
    let l:prefix = l:kw
  else
    let l:tail = fnamemodify(l:cwd . '/', ':h:t')
    let l:cwd = fnamemodify(l:cwd . '/', ':h:h') . '/'
    " strip tail; fnamemodify strips duplicate trailing slashes
    let l:prefix = matchstr(l:kw, '^.*/')
  endif

  let l:glob = (empty(l:tail) ? '{.,}' : s:smartcasewildcard(l:tail, get(g:, 'asyncomplete_matchfuzzy', 0))) . '*'
  let l:script = 'shopt -s nullglob; cd ' . shellescape(l:cwd) . ' && printf ''%s\n'' ' . l:glob

  let l:filectx = {
        \ 'opt': a:opt,
        \ 'ctx': a:ctx,
        \ 'startcol': l:col - l:kwlen,
        \ 'cwd': l:cwd,
        \ 'escaped': l:escaped,
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
  let l:escaped = a:filectx.escaped

  call map(l:matches, {key, val -> s:filename_map(l:prefix, l:cwd, val, l:escaped)})
  call filter(l:matches, {i, m -> m != v:null})

  call asyncomplete#complete(a:filectx.opt.name, a:filectx.ctx, a:filectx.startcol, l:matches)
endfunction

function! s:filename_map(prefix, cwd, base, escaped) abort
  if empty(a:base) || a:base ==# '.' || a:base ==# '..'
    " filtered out later
    return v:null
  endif

  if a:escaped
    let l:word = a:prefix . substitute(a:base, '[[:space:]*?&\\]', '\\\0', 'g')
  else
    let l:word = a:prefix . a:base
  endif

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

function! s:find_path(opt, ctx, typed) abort
  let l:typed = a:typed[-(a:opt['config']['max_path_length']):]
  let l:kw = substitute(l:typed, '^\s*', '', '')
  while stridx(l:kw, '/') >= 0
    if l:kw =~# '\\.'
      let l:path = s:goodpath(a:ctx, substitute(l:kw, '\\\(.\)', '\1', 'g'))
      if !empty(l:path)
        return [l:kw, l:path, 1]
      endif
    endif
    let l:path = s:goodpath(a:ctx, l:kw)
    if !empty(l:path)
      if l:path =~# '\\$' && l:kw !=# '\\.'
        return [l:kw, l:path[:-2], 1]
      endif
      return [l:kw, l:path, 0]
    endif
    let l:kw = matchstr(l:kw, '\([^[:fname:]]\|[,=]\)\zs[\\[:fname:]].*')
  endwhile
  return ['', '', 0]
endfunction

function! s:goodpath(ctx, path) abort
  let l:path = substitute(a:path, '//\+', '/', 'g')
  if l:path !~ '^\(/\|\~\)'
    let l:abspath = expand('#' . a:ctx.bufnr . ':p:h') . '/' . l:path
  else
    let l:abspath = fnamemodify(l:path, ':p')
  endif
  if !isdirectory(fnamemodify(l:abspath, ':h'))
    return ''
  endif
  return l:abspath
endfunction

function! s:smartcasewildcard(str, fuzzy) abort
  if a:str =~ '\u'
    return shellescape(a:str)
  endif
  return s:icasewildcard(a:str, a:fuzzy)
endfunction

function! s:icasewildcard(str, fuzzy) abort
  return map(a:str, { i, c ->
        \  (a:fuzzy && (i >= 1 || c !=# '.') ? '*' : '') .
        \  (c =~# '^\a$' ? '[' . tolower(c) . toupper(c) . ']' : (c =~# '^[-._/]$' ? c : shellescape(c)))
        \ })
endfunction
