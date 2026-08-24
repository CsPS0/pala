class Pala < Formula
  desc "Interaktív terminálos felület (TUI) a Kréta e-napló rendszerhez"
  homepage "https://github.com/CsPS0/pala"
  version "1.2.3"
  license "MIT"

  on_macos do
    url "https://github.com/CsPS0/pala/releases/download/v1.2.3/pala-macos"
    sha256 "de68ed50ee753824771e77780733e22e8ebe7774eccab5bdc0076b3c00de4c5b"
  end

  on_linux do
    url "https://github.com/CsPS0/pala/releases/download/v1.2.3/pala-linux"
    sha256 "a2fa26b22c19735fddbc802221b04f62cd462443df381be2df650000c213aadf"
  end

  def install
    if OS.mac?
      bin.install "pala-macos" => "pala"
    elsif OS.linux?
      bin.install "pala-linux" => "pala"
    end
  end

  test do
    system "#{bin}/pala", "--help"
  end
end
