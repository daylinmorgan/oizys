{ ... }:
{
  environment.etc."containers/systemd/soft-serve.container" = {
    source = ./soft-serve.container;
  };
}
