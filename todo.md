# oizys todo's

## software

- [ ] lid closed does not engage hyprlock?
- [ ] include langservers for enabled languages?

## hardware

- [ ] monitor the presence of these kernel messages on `othalan`,
      possibly resolved with latest kernel, see above
  > kernel: ucsi_acpi USBC000:00: possible UCSI driver bug 2
  > kernel: ucsi_acpi USBC000:00: error -EINVAL: PPM init failed


GHA is running out of space to build `othalan`.
I really just want the CI to pre-compile a subset of the packages.
Currently, it just burns resources downloading packages over and over again.
Maybe I could use nix flake checks to accomplish this?

<!-- generated with <3 by daylinmorgan/todo -->
