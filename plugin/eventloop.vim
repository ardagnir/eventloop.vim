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

let s:initiated=0

let s:groups = {}
let s:groups["DEFAULT"] = {}
let s:groups["DEFAULT"].timer = 1
let s:groups["DEFAULT"].progress = 0
let s:groups["DEFAULT"].cmds = []

function! s:ElGroup(bang, name)
  if a:bang=="!"
    call s:DeleteGroup(a:name)
  else
    call s:SetGroup(a:name)
  endif
endfunction
 
function! s:SetGroup(name)
  if s:initiated==0
    "Calls CallEvents 5 times a second max.
    silent call system("(while [ $(vim --servername ".v:servername." --remote-expr 'EventLoop_CallEvents()') -eq 1 ]; do sleep .2; done) >/dev/null 2>/dev/null &")
    let s:initiated=1
  endif
  if a:name=="END"
    let s:currentGroup = "DEFAULT"
    return
  endif
  
  if !has_key(s:groups, a:name)
    let s:groups[a:name] = {}
    let s:groups[a:name].timer=-1
    let s:groups[a:name].progress=0
    let s:groups[a:name].cmds=[]
  endif
  let s:currentGroup = a:name
endfunction

function! s:AddToGroup(function)
  call add(s:groups[s:currentGroup].cmds,a:function)
endfunction

function! s:DeleteGroup(name)
  if a:name==""
    let s:groups = {} 
    return
  endif
  try
    call remove(s:groups, a:name)
  catch
  endtry
endfunction

function! EventLoop_CallEvents()
  for group in values(s:groups)
    let group.progress += 2
    let timer = group.timer
    if timer == -1
      let timer = s:groups["DEFAULT"].timer
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
    let s:groups[s:currentGroup].timer = argList[1]
  else
    echoerr "Invalid setting ".argList[0]
  endif
endfunction

let g:loaded_eventloop_vim = 1

let &cpo = g:save_cpo
unlet g:save_cpo
