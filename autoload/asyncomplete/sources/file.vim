function! s:filename_map(prefix, file) abort
  let l:base = fnamemodify(a:file, ':t')

  if l:base ==# '.' || l:base ==# '..'
    " filtered out below
    return v:null
  endif

  let l:word = a:prefix . l:base

  if isdirectory(a:file)
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

function! asyncomplete#sources#file#completor(opt, ctx)
  let l:bufnr = a:ctx['bufnr']
  let l:typed = a:ctx['typed']
  let l:col   = a:ctx['col']

  let l:kw    = matchstr(l:typed, '\f*$')
  let l:kwlen = len(l:kw)

  if empty(l:kwlen) || stridx(l:kw, '/') < 0
    return
  endif

  if l:kw !~ '^\(/\|\~\)'
    let l:cwd = expand('#' . l:bufnr . ':p:h') . '/' . l:kw
  else
    let l:cwd = l:kw
  endif

  let l:glob = escape(fnamemodify(l:cwd, ':t'), '`*\')
  if has('win32')
    let l:glob .= '*'
  else
    " need special pattern to include dotfiles
    let l:glob .= '.\=*'
  endif
  let l:cwd  = fnamemodify(l:cwd, ':p:h')
  let l:pre  = fnamemodify(l:kw, ':h')

  if l:pre !~ '/$'
    let l:pre = l:pre . '/'
  endif

  let l:cwdlen = strlen(l:cwd)
  let l:startcol = l:col - l:kwlen
  let l:matches = globpath(escape(l:cwd, ',*`\'), l:glob, 0, 1)
  call map(l:matches, {key, val -> s:filename_map(l:pre, val)})
  call filter(l:matches, {i, m -> m != v:null})
  call sort(l:matches, function('s:sort'))

  call asyncomplete#complete(a:opt['name'], a:ctx, l:startcol, l:matches)
endfunction

function! asyncomplete#sources#file#get_source_options(opts)
  return extend(extend({}, a:opts), {
        \ 'triggers': {'*': ['/']},
        \ })
endfunction

function! s:sort(item1, item2) abort
  if a:item1.menu ==# '[dir]' && a:item2.menu !=# '[dir]'
    return -1
  endif
  if a:item1.menu !=# '[dir]' && a:item2.menu ==# '[dir]'
    return 1
  endif
  return 0
endfunction
