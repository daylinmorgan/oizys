# Package

version       = "0.1.0"
author        = "Daylin Morgan"
description   = "nix begat oizys"
license       = "MIT"
srcDir        = "src"
bin           = @["oizys"]


# Dependencies

requires "nim >= 2.0.8"
requires "cligen"
requires "jsony"
requires "https://github.com/daylinmorgan/bbansi#9a85d9e"
