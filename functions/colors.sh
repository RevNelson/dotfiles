red() {
    echo "$(tput setaf 1)$@$(tput sgr 0)"
}

green() {
    echo ""$(tput setaf 2)$@$(tput sgr 0)""
}

yellow() {
    echo "$(tput setaf 3)$@$(tput sgr 0)"
}

blue() {
    echo ""$(tput setaf 4)$@$(tput sgr 0)""
}

magenta() {
    echo "$(tput setaf 5)$@$(tput sgr 0)"
}

cyan() {
    echo ""$(tput setaf 6)$@$(tput sgr 0)""
}
