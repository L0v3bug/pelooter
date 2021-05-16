download:
	git clone https://github.com/rebootuser/LinEnum.git
	git clone https://github.com/diego-treitos/linux-smart-enumeration.git
	git clone https://github.com/mzet-/linux-exploit-suggester.git
	git clone https://github.com/sleventyeleven/linuxprivchecker.git
	git clone https://github.com/pentestmonkey/unix-privesc-check.git
	git clone https://github.com/carlospolop/privilege-escalation-awesome-scripts-suite.git
	git clone https://github.com/jondonas/linux-exploit-suggester-2.git
	git clone https://github.com/redcode-labs/Bashark.git
	mkdir pspy
	wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy32 -O pspy/pspy32
	wget https://github.com/DominicBreuker/pspy/releases/download/v1.2.0/pspy64 -O pspy/pspy64

install: download
	@echo -e '\e[33;1mPeLooter has been installed\e[0m'