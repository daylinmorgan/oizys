{
  lib,
  config,
  enabled,
  enableAttrs,
  pipeList,
  ...
}:
{
  oizys = {
    nix-ld = enabled // {
      overkill = enabled;
    };
    languages = "misc|nim|node|nushell|python|roc|tex|zig" |> pipeList;
  } // ("vpn|desktop|hyprland|chrome|docker|vbox|backups|hp-scanner|llm" |> pipeList |> enableAttrs);

}
