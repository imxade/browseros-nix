{
  lib,
  appimageTools,
  fetchurl,
  makeDesktopItem,
}:

let
  source = import ./source.nix;

  _sourceIsInitialized = lib.assertMsg (
    source.hash != lib.fakeHash
  ) "source.nix is not initialized; run ./scripts/update-browseros first";

  src = fetchurl {
    inherit (source) url hash;
    name = "BrowserOS-${source.version}-x64.AppImage";
  };

  contents = appimageTools.extractType2 {
    pname = "browseros";
    inherit (source) version;
    inherit src;
  };

  desktopItem = makeDesktopItem {
    name = "browseros";
    desktopName = "BrowserOS";
    genericName = "Web Browser";
    comment = "Open-source agentic browser";
    exec = "browseros %U";
    icon = "browseros";
    terminal = false;
    categories = [
      "Network"
      "WebBrowser"
    ];
    mimeTypes = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    startupNotify = true;
  };
in
assert _sourceIsInitialized;
appimageTools.wrapType2 {
  pname = "browseros";
  inherit (source) version;
  inherit src;

  extraInstallCommands = ''
    install -Dm444 \
      ${desktopItem}/share/applications/browseros.desktop \
      "$out/share/applications/browseros.desktop"

    # AppImage layouts can change between BrowserOS releases. Keep icon
    # integration best-effort rather than making an otherwise valid release
    # unpackageable because an icon moved.
    icon="$(find ${contents} -type f \
      \( -iname 'browseros.png' -o -iname '*browseros*.png' -o -name '.DirIcon' \) \
      -print -quit 2>/dev/null || true)"

    if [ -n "$icon" ]; then
      install -Dm444 "$icon" \
        "$out/share/icons/hicolor/512x512/apps/browseros.png"
    fi
  '';

  meta = {
    description = "Open-source agentic browser";
    homepage = "https://github.com/browseros-ai/BrowserOS";
    license = lib.licenses.agpl3Only;
    mainProgram = "browseros";
    platforms = [ "x86_64-linux" ];
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
  };
}
