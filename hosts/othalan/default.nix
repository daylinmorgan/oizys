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
      ''
        vpn|desktop|hyprland|chrome
        backups|hp-scanner|llm
        podman|docker|vbox
      ''
      |> listify
      |> enableAttrs
    );
}
