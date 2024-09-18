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
        docker|vbox|backups|hp-scanner|llm
      ''
      |> listify
      |> enableAttrs
    );

}
