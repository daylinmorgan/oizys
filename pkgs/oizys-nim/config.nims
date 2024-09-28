task build, "build oizys":
  selfExec "c -o:oizys src/oizys.nim"

# begin Nimble config (version 2)
--noNimblePath
when withDir(thisDir(), system.fileExists("nimble.paths")):
  include "nimble.paths"
# end Nimble config
