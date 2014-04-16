" EventLoop.vim
"
" Copyright (C) 2014, James Kolb <jck1089@gmail.com>
"
" This program is free software: you can redistribute it and/or modify
" it under the terms of the GNU Affero General Public License as published by
" the Free Software Foundation, either version 3 of the License, or
" (at your option) any later version.
" 
" This program is distributed in the hope that it will be useful,
" but WITHOUT ANY WARRANTY; without even the implied warranty of
" MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
" GNU Affero General Public License for more details.
" 
" You should have received a copy of the GNU Affero General Public License
" along with this program.  If not, see <http://www.gnu.org/licenses/>.
"

let g:save_cpo = &cpo
set cpo&vim
if exists("g:loaded_eventloop_vim")
  finish
endif

command! -nargs=1 -bang ElGroup call s:ElGroup("<bang>","<args>")
command! -nargs=1 ElCmd call s:AddToGroup("<args>")

command! -nargs=1 ElSetting call s:ChangeSetting("<args>")

let g:initiated=0

let g:groups = {}
let g:groups["DEFAULT"] = {}
let g:groups["DEFAULT"].timer = 1
let g:groups["DEFAULT"].progress = 0
let g:groups["DEFAULT"].cmds = []

function! s:ElGroup(bang, name)
  if a:bang=="!"
    call DeleteGroup(a:name)
  else
    call SetGroup(a:name)
  endif
endfunction
 
function! s:SetGroup(name)
  if g:initiated==0
    "Calls CallEvents 10 times a second max.
    silent call system("(while [ $(vim --servername ".v:servername." --remote-expr 'CallEvents()') -eq 1 ]; do sleep .2; done) >/dev/null 2>/dev/null &")
    let g:initiated=1
  endif
  if a:name=="END"
    let g:currentGroup = "DEFAULT"
    return
  endif
  
  if !has_key(g:groups, a:name)
    let g:groups[a:name] = {}
    let g:groups[a:name].timer=-1
    let g:groups[a:name].progress=0
    let g:groups[a:name].cmds=[]
  endif
  let g:currentGroup = a:name
endfunction

function! s:AddToGroup(function)
  call add(g:groups[g:currentGroup].cmds,a:function)
endfunction

function! s:DeleteGroup(name)
  if a:name==""
    let g:groups = {} 
    return
  endif
  call remove(g:groups, a:name)
endfunction

function! s:CallEvents()
  for group in values(g:groups)
    let group.progress += 2
    let timer = group.timer
    if timer == -1
      let timer = g:groups["DEFAULT"].timer
    endif
    if group.progress >= timer
      let group.progress = 0
      for cmd in group.cmds
        exec cmd
      endfor
    endif
  endfor
  return 1
endfunction

function! s:ChangeSetting(args)
  let argList=split(a:args," ")
  if argList[0]=="timer"
    let g:groups[g:currentGroup].timer = argList[1]
  else
    echoerr "Invalid setting ".argList[0]
  endif
endfunction

let g:loaded_eventloop_vim = 1

let &cpo = g:save_cpo
unlet g:save_cpo
