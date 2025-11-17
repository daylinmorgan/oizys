{ ... }:
{
  environment.etc."containers/systemd/linkding.container" = {
    source = ./linkding.container;
  };
}
