#!/bin/bash
# @Author: gunjianpan
# @Date:   2019-04-30 13:26:25
# @Last Modified time: 2021-10-05 13:58:23
# A zsh deploy shell for ubuntu.
# In this shell, will install zsh, oh-my-zsh, zsh-syntax-highlighting, zsh-autosuggestions, fzf, vimrc, bat

set -e

root=false

while [[ "$#" -gt 0 ]]; do
    case $1 in
        -r|--root) root=true ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# some constant params
FD_VERSION=10.2.0
BAT_VERSION=0.25.0
ZSH_HL=zsh-syntax-highlighting
ZSH_AS=zsh-autosuggestions
ZSH_CUSTOM=${ZSH}/custom
ZSH_P=${ZSH_CUSTOM}/plugins/
ZSH_HL_P=${ZSH_P}${ZSH_HL}
ZSH_AS_P=${ZSH_P}${ZSH_AS}
ZSHRC=${ZDOTDIR:-$HOME}/.zshrc
FZF=${ZDOTDIR:-$HOME}/.fzf
FD_URL=https://github.com/sharkdp/fd/releases/download/v${FD_VERSION}/
BAT_URL=https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/

VIM_P=${ZDOTDIR:-$HOME}/.vim_runtime
VIM_URL='https://github.com/amix/vimrc'
VIMRC=${ZDOTDIR:-$HOME}/.vimrc
VIMPLUG_URL='https://raw.github.com/junegunn/vim-plug/master/plug.vim'
VIMPLUG_P=${ZDOTDIR:-$HOME}'/.vim/autoload/plug.vim'
VIMRC_URL='https://raw.github.com/iofu728/zsh.sh/master/.vimrc'

BASH_SHELL='bash zsh.sh'
SOURCE_SH='source ${ZDOTDIR:-$HOME}/.zshrc'
OH_MY_ZSH_URL='https://raw.github.com/robbyrussell/oh-my-zsh/master/tools/install.sh'
GITHUB='https://github.com/iofu728/zsh.sh'
ZSH_USER_URL='https://github.com/zsh-users/'
ZSH_HL_URL=${ZSH_USER_URL}${ZSH_HL}
ZSH_AS_URL=${ZSH_USER_URL}${ZSH_AS}

HOMEBREW_URL='https://raw.github.com/Homebrew/install/master/install'
HOMEBREW_TUNA='https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/'

GLIBC='glibc-2.18'
GLIBC_TAR=${GLIBC}'.tar.gz'
GLIBC_URL='http://mirrors.ustc.edu.cn/gnu/libc/'${GLIBC_TAR}

SIGN_1='#-#-#-#-#-#-#-#-#-#'
SIGN_2='---__---'
SIGN_3='**************'
INS='Instaling'
DOW='Downloading'
ERROR_MSG="Sorry, this .sh does not support your Linux Distribution ${DISTRIBUTION}. Please open one issue in ${GITHUB} "

DISTRIBUTION=$(lsb_release -a 2>/dev/null | grep -n 'Distributor ID:.*' | awk '{print $3}' 2>/dev/null)
if [ -z $DISTRIBUTION ]; then
    if [ ! -z "$(which yum 2>/dev/null | sed -n '/\/yum/p')" ]; then
        DISTRIBUTION=CentOS
    elif [ ! -z "$(sw_vers 2>/dev/null | sed -n '/[mM]ac/p')" ]; then
        DISTRIBUTION=MacOS
    elif [ ! -z "$(which apt 2>/dev/null | sed -n '/\/apt/p')" ]; then
        DISTRIBUTION=Ubuntu
    elif [ ! -z "$(which pacman 2>/dev/null | sed -n '/\/pacman/p')" ]; then
        DISTRIBUTION=Arch
    elif [ ! -z "$(which apk 2>/dev/null | sed -n '/\/apk/p')" ]; then
        DISTRIBUTION=Alpine
    fi
fi

if [ ! -z "$(echo $DISTRIBUTION | sed -n '/Ubuntu/p')" ]; then
    APT=apt || APT=apt-get
    if [ ! -z "$(which sudo | sed -n '/\/sudo/p')" ]; then
        ag="sudo ${APT}"
    else
        ag="${APT}"
    fi
fi

# echo color
RED='\033[1;91m'
GREEN='\033[1;92m'
YELLOW='\033[1;93m'
BLUE='\033[1;94m'
CYAN='\033[1;96m'
NC='\033[0m'

echo_color() {
    case ${1} in
    red) echo -e "${RED} ${2} ${NC}" ;;
    green) echo -e "${GREEN} ${2} ${NC}" ;;
    yellow) echo -e "${YELLOW} ${2} ${NC}" ;;
    blue) echo -e "${BLUE} ${2} ${NC}" ;;
    cyan) echo -e "${CYAN} ${2} ${NC}" ;;
    *) echo ${2} ;;
    esac
}

check_install() {
    if [ -z "$(which ${1} 2>/dev/null | sed -n '/\/'${1}'/p')" ]; then
        echo_color green "${SIGN_1} ${INS} ${1} ${SIGN_1}"
        case $DISTRIBUTION in
        MacOS) brew install ${1} ;;
        Ubuntu) $ag install ${1} -y ;;
        CentOS) yum install ${1} -y ;;
        Arch) pacman -Sy ${1} --noconfirm ;;
        Alpine) apk add ${1} ;;
        *) echo_color red ${ERROR_MSG} && exit 2 ;;
        esac
    fi

}

install_dkpg() {
    if [ -z "$(which ${1} 2>/dev/null | sed -n '/\/'${1}'/p')" ]; then
        if [ ! -z "$(echo $DISTRIBUTION | sed -n '/CentOS/p')" ]; then
            if [ -z "$(which dpkg 2>/dev/null | sed -n '/\/dpkg/p')" ]; then
                echo_color yellow "${SIGN_2} ${INS} dpkg ${SIGN_2}"
                yum epel-release -y && yum repolist && yum install dpkg-devel dpkg-dev -y
            fi
            if [ -z "$(strings /lib64/libc.so.6 | sed -n '/GLIBC_2.18/p')" ]; then
                if [ -z "$(which gcc 2>/dev/null | sed -n '/\/gcc/p')" ]; then
                    echo_color yellow "${SIGN_2} ${INS} gcc ${SIGN_2}"
                    yum update -y && yum install gcc -y
                fi
                echo_color yellow "${SIGN_2} ${DOW} ${GLIBC} ${SIGN_2}"
                cd ${ZDOTDIR:-$HOME} && wget ${GLIBC_URL}
                tar -zxvf ${GLIBC_TAR} && cd ${GLIBC}
                echo_color yellow "${SIGN_2} ${INS} ${GLIBC} ${SIGN_2}"
                mkdir build && cd build && bash ../configure --prefix=/usr
                make -j4 >/dev/null && make install >/dev/null
            fi
        elif [ ! -z "$(echo $DISTRIBUTION | sed -n '/Ubuntu/p')" ]; then
            if [ -z "$(which dpkg | sed -n '/\/dpkg/p')" ]; then
                $ag install dpkg -y
            fi
        fi

        # install $1
        echo_color yellow "${SIGN_2} ${DOW} ${1} ${SIGN_2}"
        case $DISTRIBUTION in
        MacOS) check_install ${1} ;;
        Arch)
            if [ -z "$(which git | sed -n '/mingw64/p')" ]; then
                pacman -S ${1} --noconfirm
            fi
            ;;
        Alpine) apk add ${1} ;;
        *)
            BIT=$(dpkg --print-architecture)
            INSTALL_P=${1}_${2}_${BIT}.deb
            if [ ! -z "$(which sudo | sed -n '/\/sudo/p')" ]; then
                sdpkg='sudo dpkg'
            else
                sdpkg='dpkg'
            fi
            cd ${ZDOTDIR:-$HOME} && rm -rf ${INSTALL_P}* && wget ${3}${INSTALL_P} && $sdpkg -i ${INSTALL_P}
            ;;
        esac
    fi
}

update_list() {
    case $DISTRIBUTION in
    MacOS)
        if [ -z "$(ls /Library/Developer/CommandLineTools 2>/dev/null)" ]; then
            xcode-select --install
        fi
        # Homebrew
        if [ -z "$(which brew | sed -n '/\/brew/p')" ]; then
            echo_color yellow "${SIGN_2} ${DOW} homebrew ${SIGN_2}"
            wget ${HOMEBREW_URL}
            echo_color yellow "${SIGN_2} ${INS} homebrew ${SIGN_2}"
            /usr/bin/ruby install

            echo_color green "${SIGN_1} ${INS} git ${SIGN_1}"
            brew install git

            cd "$(brew --repo)"
            git remote set-url origin ${HOMEBREW_TUNA}brew.git
            cd "$(brew --repo)/Library/Taps/homebrew/homebrew-core"
            git remote set-url origin ${HOMEBREW_TUNA}homebrew-core.git
        fi
        check_install truncate
        ;;
    Ubuntu) $ag update -y && $ag install dpkg ;;
    CentOS) yum update -y && yum install which -y ;;
    Arch) pacman -Syu --noconfirm ;;
    Alpine) apk update ;;
    *) echo_color red ${ERROR_MSG} && exit 1 ;;
    esac
}

if [ -z "$(ls -a ${ZDOTDIR:-$HOME} | sed -n '/\.oh-my-zsh/p')" ]; then
    update_list
    check_install zsh
    check_install curl
    check_install git
    check_install vim
    if [ -z "$(echo $DISTRIBUTION | sed -n '/\(Arch\|Alpine\)/p')" ]; then
        if [ "$root" = true ]; then
            chsh -s $(which zsh)
        fi
    fi

    echo_color yellow "${SIGN_1} ${INS} oh-my-zsh ${SIGN_1}"
    echo_color red "${SIGN_3} After Install you should ·${BASH_SH} && ${SOURCE_SH}· Again ${SIGN_3}"
    sh -c "$(curl -fsSL ${OH_MY_ZSH_URL})" "" --unattended
else
    echo_color green "ZSH_CUSTOM: ${ZSH_CUSTOM}"

    # zsh syntax highlighting
    if [ -z "$(ls ${ZSH_P} | sed -n '/'${ZSH_HL}'/p')" ]; then
        echo_color yellow "${SIGN_2} ${DOW} ${ZSH_HL} ${SIGN_2}"
        git clone ${ZSH_HL_URL} ${ZSH_HL_P}
        echo "source \$ZSH_CUSTOM/plugins/${ZSH_HL}/${ZSH_HL}.zsh" >>${ZSHRC}
    fi

    # zsh-autosuggestions
    if [ -z "$(ls ${ZSH_P} | sed -n '/'${ZSH_AS}'/p')" ]; then
        echo_color yellow "${SIGN_2} ${DOW} ${ZSH_AS} ${SIGN_2}"
        git clone ${ZSH_AS_URL} ${ZSH_AS_P}
        echo "source \$ZSH_CUSTOM/plugins/${ZSH_AS}/${ZSH_AS}.zsh" >>${ZSHRC}
    fi

    # change ~/.zshrc
    case $DISTRIBUTION in
    MacOS) sed -i '' 's/plugins=(git)/plugins=(git docker zsh-autosuggestions)/' ${ZSHRC} ;;
    *) sed -i 's/plugins=(git)/plugins=(git docker zsh-autosuggestions)/' ${ZSHRC} ;;
    esac

    # install fd, from https://github.com/sharkdp/fd
    install_dkpg fd $FD_VERSION $FD_URL

    # install bat, from https://github.com/sharkdp/bat
    if [ -z "$(echo $DISTRIBUTION | sed -n '/Alpine/p')" ]; then
        install_dkpg bat $BAT_VERSION $BAT_URL
    fi

    # install fzf & bind default key-binding
    if [ -z "$(ls -a ${ZDOTDIR:-$HOME} | sed -n '/\.fzf/p')" ] && [ -z "$(echo $DISTRIBUTION | sed -n '/Alpine/p')" ]; then

        echo_color yellow "${SIGN_2} ${DOW} fzf ${SIGN_2}"
        git clone --depth 1 https://github.com/junegunn/fzf ${FZF}
        echo_color yellow "${SIGN_2} ${INS} fzf ${SIGN_2}"
        bash ${FZF}/install <<<'yyy'

        # alter filefind to fd
        echo "export FZF_DEFAULT_COMMAND='fd --type file'" >>${ZSHRC}
        echo "export FZF_CTRL_T_COMMAND=\$FZF_DEFAULT_COMMAND" >>${ZSHRC}
        echo "export FZF_ALT_C_COMMAND='fd -t d . '" >>${ZSHRC}

        # Ctrl+R History command; Ctrl+R file catalog
        # if you want to DIY key of like 'Atl + C'
        # maybe line-num is not 64, but must nearby
        case $DISTRIBUTION in
        MacOS) sed -i '' 's/\\ec/^\\/' ${FZF}/shell/key-bindings.zsh ;;
        *) sed -i 's/\\ec/^\\/' ${FZF}/shell/key-bindings.zsh ;;
        esac
    fi

    # vimrc
    if [ -z "$(ls -a ${ZDOTDIR:-$HOME} | sed -n '/\.vim_runtime/p')" ] && [ -z "$(echo $DISTRIBUTION | sed -n '/Alpine/p')" ]; then
        echo_color yellow "${SIGN_2} ${DOW} vimrc ${SIGN_2}"
        git clone --depth=1 ${VIM_URL} ${VIM_P}
        echo_color yellow "${SIGN_2} ${INS} vimrc ${SIGN_2}"
        sh ${VIM_P}/install_awesome_vimrc.sh

        curl -fLo ${VIMPLUG_P} --create-dirs ${VIMPLUG_URL}
        cp ${VIMRC} ${VIMRC}.old.1
        truncate -s 0 ${VIMRC}
        curl -fsSL ${VIMRC_URL} >>${VIMRC}

        if [ -z "$(echo ${IS_DOCKER})" ]; then
            echo_color yellow "${SIGN_2} ${INS} vim plugs ${SIGN_2}"
            vim +'PlugInstall --sync' +qall &>/dev/null </dev/tty
        fi
    fi

    echo_color red "Warning: If you only execute ·${BASH_SH}·. You need ·${SOURCE_SH}· After running this shell."
    echo_color blue 'Zsh deploy finish. Now you can enjoy it💂'
    echo_color yellow "More Info Can Find in https://wyydsb.xin/other/terminal.html & ${GITHUB} 😶"
fi
