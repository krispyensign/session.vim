vim9script noclear

# au VimLeave * :call UpdateSession()
nnoremap <leader>ml :call LoadSession()<CR>
nnoremap <leader>ms :call MakeSession()<CR>
nnoremap <leader>mL :call ListSessions()<CR>
nnoremap <leader>mS ^vg_y :call SwitchSession('<C-R>"')<CR>

# session helpers
def CloseBufferByName(name: string): number
	if bufexists(name)
		let nr = bufnr(name)
		try
			exe 'bd' nr
			return 1
		catch
		endtry
	endif
	return 0
enddef

def MakeSession()
	var sessiondir = $HOME .. '/.vim_sessions' .. getcwd()
	if (filewritable(sessiondir) != 2)
		exe 'silent !mkdir -p' sessiondir
		redraw!
	endif
	exe 'mksession!' sessiondir .. '/session.vim'
enddef


def UpdateSession(): number
	" Updates a session, BUT ONLY IF IT ALREADY EXISTS
	var sessiondir = $HOME .. '/.vim_sessions' .. getcwd()
	var sessionfile = sessiondir .. '/session.vim'
	if (filereadable(sessionfile))
		try
			tabdo CloseBufferByName('NetrwTreeListing')
		catch
		endtry
		try
			tabdo CloseBufferByName('[Plugins]')
		catch
		endtry
		exe 'mksession!' sessionfile
		echo 'updating session'
	else
		echo 'file' sessionfile 'is not readable'
	endif
	return 1
enddef

def LoadSession()
	var sessiondir = $HOME .. '/.vim_sessions' .. getcwd()
	var sessionfile = sessiondir .. '/session.vim'
	if (filereadable(sessionfile))
		exe 'source' sessionfile
		try
			tabdo call CloseBufferByName('[Plugins]')
		catch
		endtry
	else
		echo 'No session loaded, creating new session'
		call MakeSession()
	endif
enddef

def SwitchSession(directory: string)
	if UpdateSession()
		tabonly
		only
		exe 'cd!' a:directory
		call LoadSession()
	endif
enddef

def ListSessions()
	exe 'term ++shell find ~/.vim_sessions -type f -exec ls -1t "{}" + | cut -d "/" -f5- | xargs dirname | sed -e "s;^;/;g"'
enddef

