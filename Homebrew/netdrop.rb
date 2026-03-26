cask "netdrop" do
  version "0.1.0"
  sha256 :no_check

  url "https://github.com/perrosenlind/netdrop/releases/download/v#{version}/NetDrop.app.zip"
  name "NetDrop"
  desc "Lightweight macOS SCP file transfer app for network engineers"
  homepage "https://github.com/perrosenlind/netdrop"

  depends_on formula: "hudochenkov/sshpass/sshpass"
  depends_on macos: ">= :sonoma"

  app "NetDrop.app"

  zap trash: [
    "~/Library/Application Support/NetDrop",
  ]
end
