# Package

version       = "0.1.0"
author        = "Daylin Morgan"
description   = "nix begat oizys"
license       = "MIT"
srcDir        = "src"
bin           = @["oizys"]


# Dependencies

requires "nim >= 2.0.8"
requires "jsony"
requires "zippy"
requires "https://github.com/daylinmorgan/hwylterm#6a6bd269"
requires "https://github.com/daylinmorgan/resultz#43ed7f7e"
