function! pkgman#determine_package_manager()
	let g:pkgman_run_as_yes = v:false
	if executable('pkg')
		let g:pkgman_package_manager = "pkg install -y"
	elseif executable('apt')
		let g:pkgman_package_manager = "apt install -y"
	elseif executable('apt-get')
		let g:pkgman_package_manager = "apt-get install -y"
	elseif executable('winget')
		let g:pkgman_package_manager = "WINGET"
	elseif executable('pacman')
		let g:pkgman_package_manager = "pacman -Suy --noconfirm"
	elseif executable('zypper')
		let g:pkgman_package_manager = "zypper install -y"
	elseif executable('xbps-install')
		let g:pkgman_package_manager = "xbps-install -Sy"
	elseif executable('yum')
		let g:pkgman_package_manager = "yum install -y"
	elseif executable('aptitude')
		let g:pkgman_package_manager = "aptitude install -y"
	elseif executable('dnf')
		let g:pkgman_package_manager = "dnf install -y"
	elseif executable('emerge')
		let g:pkgman_package_manager = "emerge --ask --verbose"
	elseif executable('up2date')
		let g:pkgman_package_manager = "up2date"
	elseif executable('urpmi')
		let g:pkgman_package_manager = "urpmi --force"
	elseif executable('slackpkg')
		let g:pkgman_package_manager = "slackpkg install"
	elseif executable('apk')
		let g:pkgman_package_manager = "apk add"
	elseif executable('brew')
		let g:pkgman_run_as_yes = v:true
		let g:pkgman_package_manager = "brew install"
	elseif executable('flatpak')
		let g:pkgman_package_manager = "flatpak install"
	elseif executable('snap')
		let g:pkgman_package_manager = "snap install"
	else
		let g:pkgman_package_manager = "NOT FOUND"
	endif
endfunction

function! pkgman#is_superuser_needed()
	if expand('$USERNAME') !=# ""
		let username = $USERNAME
	elseif expand('$USER') !=# ""
		let username = $USER
	else
		let username = system('whoami')
	endif
	return username !=# "root" && expand('$TERMUX_VERSION') ==# ""
endfunction

function! pkgman#superuser_command()
	if executable('sudo')
		return 'sudo'
	elseif executable('doas')
		return 'doas'
	else
		echohl ErrorMsg
		echomsg "error: pkgman.nvim: sudo or doas command not found"
		echomsg "Abort"
		echohl Normal
		finish
	endif
endfunction

function! s:HandleOutput(id, data, event)
	if &filetype !=# "pkgman"
		return
	endif
	if a:data ==# []
		return
	endif
	let data = join(a:data, "")
	let data = split(data, "[\n\<c-m>]")
	let data2 = []
	for item in data
		let substituted = substitute(item, "\<c-[>.\\+m", '', 'g')
		if substituted =~# '^\s*$'
			continue
		endif
		call insert(data2, substituted)
	endfor
	if data2 ==# []
		return
	endif
	let last = line('$')
	if last ==# 1
		call append(0, data2)
		3delete
		1
	else
		call append(last, data2)
	endif
endfunction

if !exists('g:pad_amount_confirm_dialogue')
	let g:pad_amound_confirm_dialogue = 30
endif

function! s:HandleInput(id, data, event)
	echomsg "HANDLE_INPUT"
	if v:false
	\|| $LANG ==# 'ru_RU.UTF-8' || $TERMUX_LANG ==# 'ru_RU.UTF-8'
	\|| exists('g:language')
	\&& g:language ==# "russian"
		let input_label = "Пакетный менеджер просит ввод:"
	else
		let input_label = "Package manager asks for input:"
	endif
	if !exists('g:quickui_version')
		echohl Question
		let user_input = input(find_file_label)
		echohl Normal
	else
		let user_input = quickui#input#open(Pad(find_file_label, g:pad_amount_confirm_dialogue), fnamemodify(expand('%'), ':~:.'))
	endif
	if user_input !=# ''
		let bytes_sent = chansend(g:pkgman_job, user_input)
		if bytes_sent ==# 0
			echohl ErrorMsg
			echomsg "error: pkgman.nvim: Unable to send data"
			echohl Normal
		endif
	endif
endfunction

function! s:HandleExit(id, exit_code, event)
	echomsg "HANDLE_EXIT"
	unlet g:pkgman_job
endfunction

function! pkgman#stop()
	if exists('g:pkgman_job')
		call jobstop(g:pkgman_job)
	endif
endfunction

function! pkgman#install_package(pkgname)
	if !exists('g:pkgman_package_manager')
		echohl ErrorMsg
		echomsg "error: pkgman.nvim: Run :call pkgman#determine_package_manager()"
		echohl Normal
		return
	endif
	if g:pkgman_package_manager ==# "NOT FOUND"
		echohl ErrorMsg
		echomsg "error: pkgman.nvim: Package manager not found"
		echohl Normal
		return
	endif
	if g:pkgman_package_manager ==# "WINGET"
		echohl ErrorMsg
		echomsg "error: pkgman.nvim: Winget is not supported"
		echohl Normal
		return
	endif

	let command = ""
	if pkgman#is_superuser_needed()
		let command .= pkgman#superuser_command().' '
	endif
	let command .= g:pkgman_package_manager.' '.a:pkgname

	new
	setlocal filetype=pkgman
	echomsg "command is:".command.";"
	let g:pkgman_job = jobstart(
	\	command,
	\	{
	\		'pty': v:true,
	\		'on_stdout': {j, d, e ->
	\			s:HandleOutput(j, d, e)
	\		},
	\		'on_stderr': {j, d, e ->
	\			s:HandleOutput(j, d, e)
	\		},
	\       'on_stdin': {j, d, e ->
	\           s:HandleInput(j, d, e)
	\		},
	\       'on_exit': {j, d, e ->
	\           s:HandleExit(j, d, e)
    \       },
	\	}
	\)
endfunction

function! Pad(s, amt)
    return a:s . repeat(' ', a:amt - len(a:s))
endfunction

function! pkgman#set_keymaps()
	noremap q <cmd>call pkgman#stop()<bar>quit<cr>
endfunction

autocmd FileType pkgman call pkgman#set_keymaps()
