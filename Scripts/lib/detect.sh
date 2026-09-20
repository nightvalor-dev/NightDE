detect_distro() {
  if command -v pacman >/dev/null 2>&1; then
    echo "arch"
  elif command -v dnf >/dev/null 2>&1; then
    echo "fedora"
  else
    echo "unsupported"
  fi
}

detect_gpu() {
  if lspci 2>/dev/null | grep -qi nvidia; then
    echo "nvidia"
  else
    echo "other"
  fi
}
