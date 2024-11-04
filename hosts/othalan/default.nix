{
  enabled,
  enableAttrs,
  listify,
  ...
}:
{
  oizys =
    {
      nix-ld = enabled // {
        overkill = enabled;
      };
      languages =
        "misc|nim|node|nushell|python|tex"
        # + "roc|zig"
        |> listify;
    }
    // (
      # llm
      ''
        vpn|desktop|hyprland|chrome
        backups|hp-scanner
        podman|docker|vbox
      ''
      |> listify
      |> enableAttrs
    );
}
