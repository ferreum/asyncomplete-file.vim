# asyncomplete-file.vim

Filename completion source for [asyncomplete.vim](https://github.com/prabirshrestha/asyncomplete.vim)

Improved version of the original
[asyncomplete-file.vim](https://github.com/prabirshrestha/asyncomplete-file.vim)
source with the following features:

- Files are completed asynchronously
- Full support for fuzzy matching
- Uses `'smartcase'` behavior; see `:h 'smartcase'`
- Uses `'isfname'` option for detection, but also works on paths containing
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
    \ 'config': {
    \    'max_path_length': 256,
    \    'max_glob_length': 16,
    \ },
    \ }))
```

Note: `config` is optional. The shown values are the defaults.
- `max_path_length` is the maximum length to search for an existing path to the
  left of the cursor. If no existing directory is found, or there is no `/`
  character, no file completion is performed.
- `max_glob_length` is the maximum length of the last path segment to prefix
  the glob pattern with. If the last path segment is longer, files are
  searched using the truncated prefix.
