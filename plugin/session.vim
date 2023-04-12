vim9script noclear

if exists("g:loaded_sessions")
	finish
endif
g:loaded_sessions = 1

if !exists("g:sessions_auto_update")
	g:sessions_auto_update = 1
endif

if !exists("g:session_buffers_to_close")
	g:session_buffers_to_close = ["NetrwTreeListing", "[Plugins]"]
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

# session helpers
var Nameref: func
def CloseBufferList(): bool
	for bname in g:session_buffers_to_close
		if bufexists(bname)
			Nameref = () => bname
			try
				g/^/exe "bd" bufnr(Nameref())
			catch
			endtry
		endif
	endfor
	return true
enddef

def MakeSession()
	var sessiondir = $HOME .. "/" .. g:session_dir .. getcwd()
	if filewritable(sessiondir) != 2
		exe "silent !mkdir -p" sessiondir
		redraw!
	endif
	exe "mksession!" sessiondir .. "/session.vim"
enddef

def UpdateSession(): bool
	# updates a session, but only if it already exists
	var sessiondir = $HOME .. "/" .. g:session_dir .. getcwd()
	var sessionfile = sessiondir .. "/session.vim"
	if filereadable(sessionfile)
		if CloseBufferList()
			exe "mksession!" sessionfile
		endif
		echo "updating session"
	else
		echo "file" sessionfile "is not readable"
	endif
	return true
enddef

def LoadSession()
	var sessiondir = $HOME .. "/" .. g:session_dir .. getcwd()
	var sessionfile = sessiondir .. "/session.vim"
	if filereadable(sessionfile)
		exe "source" sessionfile
	else
		echo "No session loaded, creating new session"
		call MakeSession()
	endif
enddef

def SwitchSession(directory: string)
	echo "switching to" directory
	if UpdateSession()
		exe "cd!" directory
		call LoadSession()
	endif
enddef

def ListSessions()
	# if the buffer already exists then jump to its window
	var w_sl = bufwinnr("__SessionList__")
	if w_sl != -1
		exe w_sl .. "wincmd w"
		return
	endif

	# create the buffer
	silent! split __SessionList__

	# mark the buffer as scratch
	setlocal buftype=nofile
	setlocal bufhidden=wipe
	setlocal noswapfile
	setlocal nowrap
	setlocal nobuflisted

	# add some key mappings
	nnoremap <buffer> <silent> q :bwipeout!<CR>
	nnoremap <buffer> <silent> o :call <SID>SwitchSessionB(getline("."))<CR>
	nnoremap <buffer> <silent> <CR> :call <SID>SwitchSessionB(getline("."))<CR>
	nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>SwitchSessionB(getline("."))<CR>

	# make it pretty
	syn match Identifier "^\".*"
	put ='"-----------------------------------------------------'
	put ='" q                        - close session list'
	put ='" o, <CR>, <2-LeftMouse>   - open session'
	put ='"-----------------------------------------------------'
	put =''
	var l = line(".")

	# create a list of sessions
	var sessionpaths = mapnew(
		# get a list of full paths for all session.vim files located in the
		# home session directory
		glob($HOME .. '/' .. g:session_dir .. '/**/session.vim', 1, 1),
		# strip the leading path from the full paths to get the target
		# directory
		(i, v) => substitute(v, $HOME .. '/' .. g:session_dir, "", "g"))
	# strip the filename and just get the path
	var sessiontargets = mapnew(sessionpaths, (i, v) => fnamemodify(v, ":h"))

	if len(sessiontargets) != 0
		# populate the buffer with the results
		silent put =sessiontargets
	else
		# make an error message appear instead if nothing is found
		syn match Error "^\" There.*"
		silent put ='" There are no saved sessions'
	endif

	# delete the first line
	exe ":0,1d"
	exe ":" .. l

	# mark the buffer as not modifiable any more and no spell checking
	setlocal nomodifiable
	setlocal nospell
enddef
