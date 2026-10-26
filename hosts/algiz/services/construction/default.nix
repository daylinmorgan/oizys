{
  lib,
  flake,
  enabled,
  ...
}:

{
  imports = [
    (flake.modules "daylin-website").construction
  ];
  services.under-construction = enabled // {
    domains = [
      "cloud.dayl.in"
      "blog.dayl.in"
    ];
  };
}
