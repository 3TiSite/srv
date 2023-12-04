SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND noninteractive
ENV BUN_INSTALL /opt/bun
ENV TERM xterm-256color
ENV CARGO_HOME /opt/rust
ENV RUSTUP_HOME /opt/rust
ENV PNPM_HOME /opt/pnpm
ENV PATH="$PNPM_HOME:$PATH"
ENV ZINIT_HOME /opt/zinit/zinit.git
ENV ZINIT[HOME_DIR]	/opt/zinit
ENV ZPFX /opt/zinit/polaris

# pgformatter
# 不 passwd -d 这样没法ssh秘钥登录，每次都要输入密码
RUN <<ETO
#!/bin/bash
set -ex
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y
apt-get install -y glances unzip build-essential musl-tools g++ git bat jq libffi-dev zlib1g-dev liblzma-dev libssl-dev pkg-config git-lfs libreadline-dev libbz2-dev libsqlite3-dev libzstd-dev zsh protobuf-compiler software-properties-common curl wget cmake autoconf automake libtool
chsh -s /bin/zsh root
apt remove --purge --assume-yes snapd gnome-software-plugin-snap
apt autoremove -y
git lfs install && \
git clone --depth=1 https://github.com/mobile-shell/mosh.git
cd mosh && ./autogen.sh && ./configure
make && make install && cd .. && rm -rf mosh
add-apt-repository -y ppa:neovim-ppa/unstable
apt-get update
apt-get install -y neovim
ETO

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --no-modify-path --default-toolchain nightly

ENV RTX_DATA_DIR /opt/rtx
ENV RTX_CACHE_DIR /cache/rtx

RUN <<ETO
#!/usr/bin/zsh
set -ex
source $CARGO_HOME/env
curl -L --proto '=https' -sSf https://raw.githubusercontent.com/cargo-bins/cargo-binstall/main/install-from-binstall-release.sh | bash
cargo binstall --no-confirm --root /usr/local stylua erdtree cargo-cache sd tokei diskus cargo-edit cargo-update rtx-cli wasm-bindgen-cli wasm-pack eza atuin watchexec-cli
cargo install --root /usr/local --git https://github.com/3tifork/ripgrep.git

eval $(rtx env)

rm -rf $CARGO_HOME/registry

rustup target add wasm32-unknown-unknown
cargo-cache --remove-dir all

cd $CARGO_HOME
ln -s ~/.cargo/config .

rtxi(){
rtx install $1@latest
rtx global $1@$(rtx ls --json $1|jq -r 'last(.[] | .version)')
eval $(rtx env)
}

rtxi nodejs
rtxi golang
go install github.com/charmbracelet/glow@latest
go install mvdan.cc/sh/cmd/shfmt@latest
go install github.com/muesli/duf@master
go install github.com/louisun/heyspace@latest

rtxi python

git clone --depth=1 https://github.com/skywind3000/czmod.git
cd czmod
./build.sh
mv czmod /usr/local/bin
cd ..
rm -rf czmod

curl https://bun.sh/install | bash

ln -s /usr/bin/gist-paste /usr/bin/gist
cd /usr/local
wget https://cdn.jsdelivr.net/gh/junegunn/fzf/install -O fzf.install.sh
bash ./fzf.install.sh && rm ./fzf.install.sh && cd ~

ETO

COPY _/root /root

RUN <<ETO
#!/usr/bin/zsh
set -ex
declare -A ZINIT
mkdir -p /opt/zinit
git clone --depth=1 https://github.com/zdharma-continuum/zinit.git $ZINIT_HOME
cat /root/.zinit.zsh|grep --invert-match "^zinit ice"|zsh
/opt/zinit/plugins/romkatv---powerlevel10k/gitstatus/install
ETO

COPY _/usr/share/nvim /usr/share/nvim
COPY _/etc/vim /etc/vim

WORKDIR /
COPY _ .
COPY boot .

RUN <<ETO
#!/usr/bin/zsh
set -ex
eval $(rtx env)

npm install -g pnpm

for pkg in $(cat ~/.default-npm-packages); do
  if [ -n "$pkg" ]; then
    pnpm i -g $pkg
  fi
done

pip install -r ~/.default-python-packages

update-alternatives --install /usr/bin/vi vi /usr/bin/nvim 1
update-alternatives --set vi /usr/bin/nvim
update-alternatives --install /usr/bin/vim vim /usr/bin/nvim 1
update-alternatives --set vim /usr/bin/nvim
update-alternatives --install /usr/bin/editor editor /usr/bin/nvim 1
update-alternatives --set editor /usr/bin/nvim
curl -fLo /etc/vim/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

eval $(rtx env)
vi -E -u /etc/vim/sysinit.vim +PlugInstall +qa
vi -u /etc/vim/sysinit.vim +UpdateRemotePlugins +qa
vi +'CocInstall -sync coc-rust-analyzer coc-json coc-yaml coc-css coc-python coc-vetur coc-svelte' +qa

if [ "$(uname -m)" != "aarch64" ]; then
  vi +'CocInstall -sync coc-tabnine' +qa
fi

find /etc/vim -type d -exec chmod 755 {} +

apt-get install -y \
ncdu asciinema man lua5.4 \
tzdata sudo tmux openssh-client libpq-dev \
rsync mlocate gist less util-linux apt-utils \
htop cron bsdmainutils universal-ctags \
direnv iputils-ping dstat zstd jq git-extras \
aptitude clang-format openssh-server mariadb-client
yes | unminimize
ldconfig

rm -rf /root/.cache/pip
python -m pip cache purge
go clean --cache
npm cache clean -f
pnpm store prune
apt-get clean -y
find / | grep -E "(/__pycache__$|\.pyc$|\.pyo$)" | xargs rm -rf
mkdir -p /init/etc/rc.d && mv /etc/rc.d/* /init/etc/rc.d
sed -i 's/^#*\s*PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/^#*\s*PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i "s/#ClientAliveInterval 0/ClientAliveInterval 60/g" /etc/ssh/sshd_config
sed -i "s/#ClientAliveCountMax 3/ClientAliveCountMax 3/g" /etc/ssh/sshd_config
rm -rf /root/.npm /root/.launchpadlib
mkdir -p /root/.npm
#echo "cp -r /init/* / && exec zsh" > /root/.zshrc
#rm -rf /var/lib/apt/lists /var/tmp /tmp /var/log /var/cache/debconf /root/.npm
ETO
