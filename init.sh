#!/bin/bash
set -e


GO_LINT_VERSION="1.57.1"
KIND_VERSION="0.22.0"

PLATFORM=$(uname -s)

function announce_platform() {
    instance_platform=$1
    instance_version=$2

    printf "\nFound platform ${instance_platform} ${instance_version}.\n"
}

function install_vscode_extensions() {
    code --install-extension vscodevim.vim
    code --install-extension shardulm94.trailing-spaces
    code --install-extension bierner.markdown-preview-github-styles
    code --install-extension golang.go
    code --install-extension ms-python.python
}

if [[ "${PLATFORM}" == 'Linux' ]]; then
    if [ -f /etc/redhat-release ]; then
        distro=$(cat /etc/redhat-release | awk '{print $1}')
        announce_platform ${PLATFORM} ${distro}

        if [[ "${distro}" == 'Fedora' ]]; then
            # Add VSCode repository
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

            sudo dnf update

            sudo dnf install -y code curl fedora-workstation-repositories flatpak git golang gnome-tweaks helm htop jq podman vim

            sudo flatpak install flathub com.google.Chrome -y

            ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ''

            # Install golangci-lint
            if ! $(go env GOPATH)/bin/golangci-lint version &>/dev/null; then
                printf "\nInstalling golangci-lint....\n"
                curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v${GO_LINT_VERSION}
            else
                printf "\nFound golangci-lint.\n"
                $(go env GOPATH)/bin/golangci-lint version
            fi

            # Install kubectl
            if ! kubectl version &>/dev/null; then
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
                kubectl version --client --output=yaml
            else
                printf "\nFound kubectl client.\n"
                kubectl version --client --output=yaml
            fi

            # Install KIND
            if ! kind version &>/dev/null; then
                curl -Lo ./kind https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-amd64
                chmod +x ./kind
                sudo mv ./kind /usr/local/bin/kind
                kind version
            else
                printf "\nFound KIND.\n"
                kind version
            fi

            install_vscode_extensions
            code --install-extension codeium.codeium
            cp ./config/Code/User/keybindings.json ~/.config/Code/User/

            gsettings set org.gnome.desktop.sound event-sounds false

            cp -R ./.* ~/
        fi
    else
        printf "\nThis script does not support ${distro} ${PLATFORM}.\n"
    fi
elif [[ "${PLATFORM}" == 'Darwin' ]]; then
    platform=$(sw_vers -productName)
    version=$(sw_vers -productVersion)
    announce_platform ${platform} ${version}

    if ! xcode-select -p &>/dev/null; then
        xcode-select --install
    fi

    if ! brew --version &>/dev/null; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    brew install awscli azure-cli docker docker-credential-helper git go golangci-lint goreleaser helm jq kind kubectl \
        terraform-docs tfenv tflint watch yq

    brew install --cask iterm2 slack visual-studio-code

    brew install colima

    install_vscode_extensions
    code --install-extension 4ops.terraform
    cp ./config/Code/User/keybindings.json ~/Library/Application Support/Code/User/
else
    printf "\nThis script does not support ${PLATFORM} systems.\n"
fi
