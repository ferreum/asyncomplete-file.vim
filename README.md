# asyncomplete-file.vim

Filename completion source for [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim)

Improved version of the original
[asyncomplete-file.vim](https://github.com/prabirshrestha/asyncomplete-file.vim)
source with the following features:

- Files are completed asynchronously
- Full support for fuzzy matching
- 'smartcase' behavior; see `:h 'smartcase'`
- Uses 'isfname' option for detection, but also works on paths containing
  unusual characters
- Detection of shell-escaped paths
- Appends '/' to directories to help traversing paths

There are additional limitations:

- Not supported on MS-Windows
- Only Vim8+ supported for now (see #1)
- Requires `/usr/bin/bash`

## Installing

```vim
Plug 'prabirshrestha/asyncomplete.vim'
Plug 'https://gitlab.com/ferreum/asyncomplete-file.vim'
```

## Register asyncomplete-file.vim

```vim
au User asyncomplete_setup call asyncomplete#register_source(asyncomplete#sources#file#get_source_options({
    \ 'name': 'file',
    \ 'allowlist': ['*'],
    \ 'priority': 10,
    \ 'completor': function('asyncomplete#sources#file#completor')
    \ }))
```
