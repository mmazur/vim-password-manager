" vpm.vim 2013 Mariusz Mazur <mmazur@axeos.com>
" based on openssl.vim version 3.2 2008 Noah Spurrier <noah@noah.org>
"
" The original author put the following copyright notice regarding this
" particular file and I'm keeping it:
"
"   I release all copyright claims. This code is in the public domain.
"   Permission is granted to use, copy modify, distribute, and sell this
"   software for any purpose. I make no guarantee about the suitability of this
"   software for any purpose and I am not liable for any damages resulting from
"   its use. Further, I am under no obligation to maintain or extend this
"   software. It is provided on an 'as is' basis without any expressed or
"   implied warranty.
"
" Note: rest of the code in this repo is GPL 3



augroup openssl_encrypted
if exists("openssl_encrypted_loaded")
    finish
endif
let openssl_encrypted_loaded = 1
autocmd!

function! s:OpenSSLReadPre()
    set cmdheight=3
    set viminfo=
    set noswapfile
    set shell=/bin/sh
    set bin
endfunction

function! s:OpenSSLReadPost()
    let l:cipher = expand("%:e")
"    if l:cipher == "aes"
"        let l:cipher = "aes-256-cbc"
"    endif
    let l:cipher = "bf"
    let l:expr = "0,$!openssl " . l:cipher . " -pass env:VPMPASS -d -a -salt"

    silent! execute l:expr
    if v:shell_error
        silent! 0,$y
        silent! undo
        echo "COULD NOT DECRYPT USING EXPRESSION: " . expr
        echo "Note that your version of openssl may not have the given cipher engine built-in"
        echo "even though the engine may be documented in the openssl man pages."
        echo "ERROR FROM OPENSSL:"
        echo @"
        echo "COULD NOT DECRYPT"
        :cq!
        return
    endif
    set nobin
    set cmdheight&
    set shell&
    execute ":doautocmd BufReadPost ".expand("%:r")
    redraw!
endfunction

function! s:OpenSSLWritePre()
    set cmdheight=3
    set shell=/bin/sh
    set bin

    if !exists("g:openssl_backup")
        let g:openssl_backup=0
    endif
    if (g:openssl_backup)
        silent! execute '!cp % %:r.bak.%:e'
    endif

    let l:cipher = expand("<afile>:e") 
"    if l:cipher == "aes"
"        let l:cipher = "aes-256-cbc"
"    endif
    let l:cipher = "bf"
    let l:expr = "0,$!openssl " . l:cipher . " -pass env:VPMPASS -e -a -salt"

    silent! execute l:expr
    if v:shell_error
        silent! 0,$y
        silent! undo
        echo "COULD NOT ENCRYPT USING EXPRESSION: " . expr
        echo "Note that your version of openssl may not have the given cipher engine built in"
        echo "even though the engine may be documented in the openssl man pages."
        echo "ERROR FROM OPENSSL:"
        echo @"
        echo "COULD NOT ENCRYPT"
        return
    endif
endfunction

function! s:OpenSSLWritePost()
    silent! undo
    set nobin
    set shell&
    set cmdheight&
    redraw!
endfunction

autocmd BufReadPre,FileReadPre     *.vpmbf call s:OpenSSLReadPre()
autocmd BufReadPost,FileReadPost   *.vpmbf call s:OpenSSLReadPost()
autocmd BufWritePre,FileWritePre   *.vpmbf call s:OpenSSLWritePre()
autocmd BufWritePost,FileWritePost *.vpmbf call s:OpenSSLWritePost()

function! HeadlineDelimiterExpression(lnum)
    if getline(a:lnum) =~ "^\\s*=[^=].*[^=]=\\s*$"
        return "0"
    elseif getline(a:lnum) =~ "^\\s*==.*==\\s*$"
        return ">1"
    else
        return "="
    endif
endfunction
autocmd BufReadPost,FileReadPost   *.vpmbf set foldexpr=HeadlineDelimiterExpression(v:lnum)
autocmd BufReadPost,FileReadPost   *.vpmbf set foldlevel=0
autocmd BufReadPost,FileReadPost   *.vpmbf set foldcolumn=0
autocmd BufReadPost,FileReadPost   *.vpmbf set foldmethod=expr
autocmd BufReadPost,FileReadPost   *.vpmbf set foldtext=getline(v:foldstart)
autocmd BufReadPost,FileReadPost   *.vpmbf nnoremap <silent><space> :exe 'silent! normal! za'.(foldlevel('.')?'':'l')<CR>
autocmd BufReadPost,FileReadPost   *.vpmbf nnoremap <silent>q :q<CR>
autocmd BufReadPost,FileReadPost   *.vpmbf highlight Folded ctermbg=green ctermfg=black
"autocmd BufReadPost,FileReadPost   *.pmbf set updatetime=300000
autocmd CursorHold                 *.pmbf quit

augroup END

