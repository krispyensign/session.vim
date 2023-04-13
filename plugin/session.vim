vim9script noclear

if exists("g:loaded_sessions")
	finish
endif
g:loaded_sessions = 1

if !exists("g:sessions_auto_update")
	g:sessions_auto_update = 1
endif

if !exists("g:sessions_buffers_to_close")
	g:sessions_buffers_to_close = ["NetrwTreeListing", "[Plugins]"]
endif

if !exists("g:sessions_dir")
	g:sessions_dir = ".vim_sessions/"
endif

if !exists("g:sessions_show_banner")
	g:sessions_show_banner = 1
endif

if !exists("g:sessions_session_file_name")
	g:sessions_session_file_name = "session.vim"
endif

if g:sessions_auto_update != 0
	au VimLeave * :call SessionsUpdate()
endif

noremap <unique> <script> <Plug>SessionsMake;  <SID>SessionsMake
noremap <SID>SessionsMake :call SessionsMake()<CR>

noremap <unique> <script> <Plug>SessionsLoad;  <SID>SessionsLoad
noremap <SID>SessionsLoad :call SessionsLoad()<CR>

noremap <unique> <script> <Plug>SessionsUpdate;  <SID>SessionsUpdate
noremap <SID>SessionsUpdate :call SessionsUpdate()<CR>

noremap <unique> <script> <Plug>SessionsList;  <SID>SessionsList
noremap <SID>SessionsList :call SessionsList()<CR>

if !exists(":SessionsMake")
	command -nargs=0 SessionsMake :call SessionsMake()
endif

if !exists(":SessionsLoad")
	command -nargs=0 SessionsLoad :call SessionsLoad()
endif

if !exists(":SessionsUpdate")
	command -nargs=0 SessionsUpdate :call SessionsUpdate()
endif

if !exists(":SessionsList")
	command -nargs=0 SessionsList :call SessionsList()
endif

var homesessiondir = $HOME .. "/" .. g:sessions_dir
var sessionfilename = "/" .. g:sessions_session_file_name

def SessionsMake()
	var sessiondir = homesessiondir .. getcwd()
	if filewritable(sessiondir) != 2
		exe "silent !mkdir -p" sessiondir
		redraw!
	endif
	exe "mksession!" sessiondir .. sessionfilename
enddef

def SessionsUpdate()
	# updates a session, but only if it already exists
	var sessionfile = homesessiondir .. getcwd() .. sessionfilename
	if filereadable(sessionfile)
		for bname in g:sessions_buffers_to_close
			if bufexists(bname)
				try
					exe "bd" bufnr(bname)
				catch
					echo bname "id:" bufnr(bname) "doesn't exist"
				endtry
			endif
		endfor
		sleep 1m
		exe "mksession!" sessionfile
		echo "updating session"
	else
		echo "no session loaded, skipping update"
	endif
enddef

def SessionsLoad()
	var sessionfile = homesessiondir .. getcwd() .. sessionfilename
	if filereadable(sessionfile)
		exe "source" sessionfile
	else
		echo "no session loaded, creating new session"
		call SessionsMake()
	endif
enddef

def SwitchSession(directory: string)
	var sessionfile = homesessiondir .. directory .. sessionfilename
	if filereadable(sessionfile)
		SessionsUpdate()
		exe "source" sessionfile
	else
		echo "no session loaded"
	endif
enddef

def SessionsList()
	# if the buffer already exists then jump to its window
	var w_sl = bufwinnr("[SessionList]")
	if w_sl != -1
		exe w_sl .. "wincmd w"
		return
	endif

	# create the buffer
	silent! split [SessionList]

	# mark the buffer as scratch
	setlocal buftype=nofile bufhidden=wipe noswapfile nowrap nobuflisted

	# add some key mappings
	nnoremap <buffer> <silent> q :bwipeout!<CR>
	nnoremap <buffer> <silent> o :call <SID>SwitchSession(getline("."))<CR>
	nnoremap <buffer> <silent> <CR> :call <SID>SwitchSession(getline("."))<CR>
	nnoremap <buffer> <silent> <2-LeftMouse> :call <SID>SwitchSession(getline("."))<CR>

	# make it pretty
	if g:sessions_show_banner
		syn match Comment "^\#.*"
		put ="#=====================================================#"
		put ="# q                        - close session list       #"
		put ="# o, <CR>, <2-LeftMouse>   - open session             #"
		put ="#=====================================================#"
	endif
	put =""

	# record first entry line number
	var l = line(".")

	# get a list of full paths for all session files located in the home
	# session directory
	var sessiondir = $HOME .. "/" .. g:sessions_dir
	var sessionfiles = glob(sessiondir .. "/**" .. sessionfilename, 1, 1)

	# strip the leading path from the full paths
	var strippedsessionfiles = mapnew(
		sessionfiles,
		(i, v) => substitute(v, sessiondir, "", "g"))

	# strip the filename to get the path of where the session points to
	var sessionpaths = mapnew(
		strippedsessionfiles,
		# strip the filename and just get the path
		(i, v) => fnamemodify(v, ":h"))

	if len(sessionpaths) != 0
		# if any sessions found then populate the buffer with the results
		silent put =sessionpaths
	else
		# make an error message appear instead if nothing is found
		syn match Error "^\*.*"
		silent put ="*there are no saved sessions*"
	endif

	# delete the first line
	:0,1d
	# jump to first entry
	exe ":" .. l

	# mark the buffer as not modifiable any more and no spell checking
	setlocal nomodifiable nospell
enddef
