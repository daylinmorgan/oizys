#  https://github.com/gwsw/less/issues/709

inputs: final: prev:

let
  version = "692";
in
{
  less = prev.less.overrideAttrs {
    version = version;
    src = final.fetchurl {
      url = "https://www.greenwoodsoftware.com/less/less-${version}.tar.gz";
      hash = "sha256-YTAPYDeY7PHXeGVweJ8P8/WhrPB1pvufdWg30WbjfRQ=";
    };
  };
}
