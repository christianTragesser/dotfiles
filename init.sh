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

if [[ "${PLATFORM}" == 'Linux' ]]; then
    if [ -f /etc/redhat-release ]; then
        distro=$(cat /etc/redhat-release | awk '{print $1}')
        announce_platform ${PLATFORM} ${distro}

        if [[ "${distro}" == 'Fedora' ]]; then
            # Add Google Chrome repository
            sudo dnf config-manager --add-repo https://dl.google.com/linux/chrome/rpm/stable/x86_64

            # Add VSCode repository
            sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
            sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'

            sudo dnf update

            sudo dnf install -y code curl git google-chrome-stable golang gnome-tweaks helm htop jq podman vim

            # Install golangci-lint
            if ! $(go env GOPATH)/bin/golangci-lint version &>/dev/null; then
                printf "\nInstalling golangci-lint....\n"
                curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | sh -s -- -b $(go env GOPATH)/bin v${GO_LINT_VERSION}
            else
                printf "\nFound golangci-lint.\n"
                $(go env GOPATH)/bin/golangci-lint version
            fi

            # Install KIND
            if ! kind version &>/dev/null; then
                curl -Lo ./kind https://kind.sigs.k8s.io/dl/v${KIND_VERSION}/kind-linux-amd64
                chmod +x ./kind
                sudo mv ./kind /usr/local/bin/kind
            else
                printf "\nFound KIND.\n"
                kind version
            fi

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
else
    printf "\nThis script does not support ${PLATFORM} systems.\n"
fi

