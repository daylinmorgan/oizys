# oizys todo's

## oizys

- [ ] build failures are reported on the command line for `oizys ci update` as 'build successful'

Could make an `oizys check` command:

- `check lock` could encapsulate any diagnostic code I want to run that does things like check for too many "inputs".
  essentially getting the same output as this `jq < flake.lock '.nodes | keys[] | select(contains("_"))`
- `check cache <path>` check for the narinfo in my cache given some nix store path

## software

- [ ] why is my update ci always building llm and rofi?
- [ ] include langservers for enabled languages?

## hardware

- [ ] monitor the presence of these kernel messages on `othalan`,
      possibly resolved with latest kernel, see above
  > kernel: ucsi_acpi USBC000:00: possible UCSI driver bug 2
  > kernel: ucsi_acpi USBC000:00: error -EINVAL: PPM init failed

<!-- generated with <3 by daylinmorgan/todo -->
