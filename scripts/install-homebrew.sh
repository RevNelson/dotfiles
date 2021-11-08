OS="$(uname -s)"

if [ "$OS" = "Darwin"]; then
    if ! cmd_exists brew; then
        echo "Installing homebrew"
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    else
        echo "Homebrew already installed."
    fi
else
    echo "You must be running macOS to install homebrew"
fi
