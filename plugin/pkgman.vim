function! pkgman#setup()
	call pkgman#determine_package_manager()
	call pkgman#init()
endfunction

function! pkgman#init()
	let g:pkgman_output = #{}
	if !exists('g:pkgman_pad_amount_confirm_dialogue')
		let g:pkgman_pad_amount_confirm_dialogue = 30
	endif
endfunction

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

function! s:HandleOutput(pkgname, id, data, event)
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
	let g:pkgman_output[a:pkgname]['output'] += data2
	call pkgman#rerender()
endfunction

function! s:HandleInput(pkgname, id, data, event)
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
		let user_input = input(input_label)
		echohl Normal
	else
		let user_input = quickui#input#open(Pad(input_label, g:pkgman_pad_amount_confirm_dialogue), fnamemodify(expand('%'), ':~:.'))
	endif
	if user_input !=# ''
		let bytes_sent = chansend(g:pkgman_output[a:pkgname]['job'], user_input)
		if bytes_sent ==# 0
			echohl ErrorMsg
			echomsg "error: pkgman.nvim: Unable to send data"
			echohl Normal
		endif
	endif
endfunction

function! s:HandleExit(pkgname, id, exit_code, event)
	echomsg "HANDLE_EXIT"
	if exists('g:pkgman_output["'.a:pkgname.'"]')
		unlet g:pkgman_output[a:pkgname]
	endif
endfunction

function! pkgman#stop()
	for item in keys(g:pkgman_output)
		if exists('g:pkgman_output["'.item.'"]["job"]')
			call jobstop(g:pkgman_output[item]['job'])
		endif
		unlet g:pkgman_output[item]
	endfor
endfunction

function! pkgman#unload()
	if exists('g:pkgman_output')
		for item in keys(g:pkgman_output)
			if exists('g:pkgman_output["'.item.'"]["job"]')
				call jobstop(g:pkgman_output[item]['job'])
			endif
		endfor
		unlet g:pkgman_output
	endif
	if exists('g:pkgman_pad_amount_confirm_dialogue')
		unlet g:pkgman_pad_amount_confirm_dialogue
	endif
	if exists('g:pkgman_package_manager')
		unlet g:pkgman_package_manager
	endif
	autocmd! pkgman *
endfunction

function! pkgman#install_package(pkgname)
	if !exists('g:pkgman_package_manager')
		echohl ErrorMsg
		echomsg "error: pkgman.nvim: Run :call pkgman#setup()"
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
	let g:pkgman_output[a:pkgname] = #{}
	let g:pkgman_output[a:pkgname]['output'] = []
	let g:pkgman_output[a:pkgname]['job'] = jobstart(
	\	command,
	\	{
	\		'pty': v:true,
	\		'on_stdout': {j, d, e ->
	\			s:HandleOutput(a:pkgname, j, d, e)
	\		},
	\		'on_stderr': {j, d, e ->
	\			s:HandleOutput(a:pkgname, j, d, e)
	\		},
	\       'on_stdin': {j, d, e ->
	\           s:HandleInput(a:pkgname, j, d, e)
	\		},
	\       'on_exit': {j, d, e ->
	\           s:HandleExit(a:pkgname, j, d, e)
    \       },
	\	}
	\)
endfunction

function! pkgman#install_package_interactive()
	if v:false
	\|| $LANG ==# 'ru_RU.UTF-8' || $TERMUX_LANG ==# 'ru_RU.UTF-8'
	\|| exists('g:language')
	\&& g:language ==# "russian"
		let input_label = "Выберите пакет для установки:"
	else
		let input_label = "Select a package to install:"
	endif
	if !exists('g:quickui_version')
		echohl Question
		let user_input = input(input_label)
		echohl Normal
	else
		let user_input = quickui#input#open(Pad(input_label, g:pkgman_pad_amount_confirm_dialogue), fnamemodify(expand('%'), ':~:.'))
	endif
	if user_input !=# ''
		call pkgman#install_package(user_input)
	endif
endfunction

function! pkgman#render()
	call append(2, 'Installing '.len(g:pkgman_output).' packages')
	for item in keys(g:pkgman_output)
		call append(line('$'), 'Installing '.item)
		if exists('g:pkgman_output["'.item.'"]["output"]')
			call append(line('$'), g:pkgman_output[item]['output'])
		endif
	endfor
endfunction

function! pkgman#open()
	let buf = nvim_create_buf(v:false, v:true)
	if has('nvim')
		let ui=nvim_list_uis()[0]
		let ui_width = ui.width
		let ui_height = ui.height
	else
		let ui_width = &columns
		let ui_height = &lines
	endif
	let width = 70
	let height = 40
	if ui_width <# width
		let width = ui_width
	endif
	if ui_height <# height
		let height = ui_height
	endif
	let opts = {'relative': 'editor',
                \ 'width': width,
                \ 'height': height,
                \ 'col': (ui_width/2) - (width/2),
                \ 'row': (ui_height/2) - (height/2),
                \ 'anchor': 'NW',
                \ 'style': 'minimal',
				\ 'focusable': v:true,
				\ 'zindex': 35,
                \ }
    let win = nvim_open_win(buf, 1, opts)
	setlocal filetype=pkgman
	setlocal buftype=nofile
	setlocal bufhidden=hide
	setlocal noswapfile
	setlocal nobuflisted
	setlocal undolevels=-1
	call append(0, Pad_middle('PKGMAN.NVIM', width))
	call append(1, repeat('⎯', width))
	call pkgman#render()
endfunction

function! pkgman#rerender()
	if &filetype !=# "pkgman"
		return
	endif
	if line('$') <# 3
		return
	endif
	let prev_line = line('.')
	silent 3,$delete
	call pkgman#render()
	execute prev_line
endfunction

function! Pad(s, amt)
    return a:s . repeat(' ', a:amt - len(a:s))
endfunction

function! Pad_middle(s, amt)
	return repeat(' ', (a:amt - len(a:s)) / 2).a:s
endfunction

function! pkgman#set_keymaps()
	nnoremap <buffer> q <cmd>call pkgman#stop()<bar>quit<cr>
	xnoremap <buffer> q <c-\><c-n><cmd>call pkgman#stop()<bar>quit<cr>
	nnoremap <buffer> I <cmd>call pkgman#install_package_interactive()<cr>
endfunction

augroup pkgman
	autocmd FileType pkgman call pkgman#set_keymaps()
	autocmd WinEnter * if &filetype==#"pkgman"|call pkgman#rerender()|endif
augroup END
