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

	execute '!'.command
endfunction
