class ClaudeKeySwitch < Formula
  desc "Rotate through multiple API keys sequentially"
  homepage "https://github.com/anthropics/claude-key-switch"
  url "https://github.com/anthropics/claude-key-switch/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "" # Will be calculated when creating a release
  license "MIT"
  version "1.0.0"

  def install
    # Install POSIX shell scripts
    bin.install "claude-key-switch"
    bin.install "install.sh" => "claude-key-switch-install"

    # Install documentation
    doc.install "README.md"
    doc.install "CLAUDE.md"
  end

  def post_install
    # Run the interactive installer automatically
    system "#{bin}/claude-key-switch-install"
  end

  def caveats
    <<~EOS
      claude-key-switch has been installed and configured!

      The interactive installer has already run. If you need to reconfigure:
        claude-key-switch-install

      Start using it:
        claude-key-switch

      Or use the convenient alias:
        switch-key

      For help:
        claude-key-switch --help

      Documentation:
        #{doc}/README.md
    EOS
  end

  test do
    system "#{bin}/claude-key-switch", "--version"
    assert_match "claude-key-switch v1.0.0", shell_output("#{bin}/claude-key-switch --version")
  end
end
