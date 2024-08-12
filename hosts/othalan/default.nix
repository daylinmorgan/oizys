{
  lib,
  config,
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
      languages = "misc|nim|node|nushell|python|roc|tex|zig" |> listify;
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
