cmark2ctags
===========

*Convert MarkDown files to Exuberant Ctags using libcmark.*

Building and Installation
-------------------------

There are a number of build types for cmark2ctags. All of them require the `libcmark` library for static linking.

|                  |                                                                |
|:-----------------|:---------------------------------------------------------------|
|`ldc-production` :|Build production code using the `ldc2` compiler.                |
|`dmd-production` :|Build production code using the `dmd` compiler.                 |
|`dmd-profile`    :|Build profiling code using the `dmd` compiler.                  |
|`dmd-profile-gc` :|Build garbage collector profiling code using the `dmd` compiler.|
|`ldc-coverage`   :|Build coverage checking/debugging code using the `ldc` compiler.|
|`dmd-coverage`   :|Build coverage checking/debugging code using the `dmd` compiler.|

Choose a build type and run `dub build -b <build type>`

Vim Integration
---------------

Using the [tagbar-markdown](https://github.com/lvht/tagbar-markdown) plugin for Vim, cmark2ctags offers an alternative option for ctags generation. Try the following code in your vimrc:

```
let g:tagbar_type_markdown = {
    \ 'ctagstype': 'markdown',
    \ 'ctagsbin' : '/opt/cmark2ctags',
    \ 'ctagsargs' : '-f - -r "<sro>" -e "<sro_escaped>" --sort=yes',
    \ 'kinds' : [
        \ 's:section',
		\ 'r:reference',
        \ 'i:image',
		\ 'l:link'
    \ ],
    \ 'sro' : '<sro>',
    \ 'kind2scope' : {
        \ 's' : 'section',
    \ },
    \ 'sort': 0,
\ }
```
