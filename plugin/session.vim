vim9script noclear

if exists("g:loaded_sessions")
	finish
endif
g:loaded_sessions = 1

if !exists("g:sessions_auto_update")
	g:sessions_auto_update = 1
endif

if !exists("g:session_buffers_to_close")
	g:session_buffers_to_close = ['NetrwTreeListing', '[Plugins]']
endif

if !exists("g:session_dir")
	g:session_dir = ".vim_sessions/"
endif

if g:sessions_auto_update != 0
	au VimLeave * :call UpdateSession()
endif

noremap <unique> <script> <Plug>MakeSession;  <SID>MakeSession
noremap <SID>MakeSession :call MakeSession()<CR>

noremap <unique> <script> <Plug>LoadSession;  <SID>LoadSession
noremap <SID>LoadSession :call LoadSession()<CR>

noremap <unique> <script> <Plug>UpdateSession;  <SID>UpdateSession
noremap <SID>UpdateSession :call UpdateSession()<CR>

noremap <unique> <script> <Plug>ListSessions;  <SID>ListSessions
noremap <SID>ListSessions :call ListSessions()<CR>

noremap <unique> <script> <Plug>SwitchSession;  <SID>SwitchSessions
noremap <SID>SwitchSession :call SwitchSession()<CR>

if !exists(":MakeSession")
	command -nargs=0 MakeSession :call MakeSession()
endif

if !exists(":LoadSession")
	command -nargs=0 LoadSession :call LoadSession()
endif

if !exists(":UpdateSession")
	command -nargs=0 UpdateSession :call UpdateSession()
endif

if !exists(":ListSessions")
	command -nargs=0 ListSessions :call ListSessions()
endif

if !exists(":SwitchSession")
	command -nargs=0 SwitchSession :call SwitchSession()
endif

# session helpers
def CloseBufferByName(name: string)
	if bufexists(name)
		let nr = bufnr(name)
		try
			exe 'bd' nr
		catch
		endtry
	endif
enddef

def CloseBufferList(): bool
	for name in g:session_buffers_to_close
		tabdo CloseBufferByName(name)
	endfor
	return true
enddef

def MakeSession()
	var sessiondir = $HOME .. "/" .. g:session_dir .. getcwd()
	if (filewritable(sessiondir) != 2)
		exe 'silent !mkdir -p' sessiondir
		redraw!
	endif
	exe 'mksession!' sessiondir .. '/session.vim'
enddef

def UpdateSession(): number
	" Updates a session, BUT ONLY IF IT ALREADY EXISTS
	var sessiondir = $HOME .. "/" .. g:session_dir .. getcwd()
	var sessionfile = sessiondir .. '/session.vim'
	if (filereadable(sessionfile))
		if CloseBufferList()
			exe 'mksession!' sessionfile
			echo 'updating session'
		endif
	else
		echo 'file' sessionfile 'is not readable'
	endif
	return 1
enddef

def LoadSession()
	var sessiondir = $HOME .. "/" .. g:session_dir .. getcwd()
	var sessionfile = sessiondir .. '/session.vim'
	if (filereadable(sessionfile))
		tabonly
		only
		exe 'source' sessionfile
		CloseBufferList()
	else
		echo 'No session loaded, creating new session'
		call MakeSession()
	endif
enddef

def SwitchSession()
	var directory = getline(".")
	if UpdateSession()
		tabonly
		only
		exe 'cd!' directory
		call LoadSession()
	endif
enddef

def ListSessions()
	exe 'term ++shell find ~/.vim_sessions -type f -exec ls -1rt "{}" + | cut -d "/" -f5- | xargs dirname | sed -e "s;^;/;g"'
enddef

