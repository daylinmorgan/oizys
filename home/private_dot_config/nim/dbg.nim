import std/[strutils, genasts, macros, os]

macro dbg*(args: varargs[untyped]): untyped =
  ## Debugging macro that inspects expressions and transparently returns their values.
  func toRepr(n: NimNode): NimNode =
    let s = n.repr
    if s.splitLines().len > 1:
      result = newLit(s.indent(2," "))
    else:
      result = newLit(s)

  let info = args.lineInfoObj
  let locStr = info.filename.extractFilename & ":" & $info.line
  let loc = newLit(locStr)

  if args.len == 0:
    return genAst(loc):
      echo loc
  elif args.len == 1:
    let arg = args[0]
    let reprStr = arg.toRepr()
    return genAst(loc, reprStr, arg):
      when typeof(arg) is void:
        echo loc, " | ", reprStr
        arg
      else:
        let res = arg
        echo loc, " | ", reprStr, " = ", res
        res
  else:
    var tupleConstr = newNimNode(nnkTupleConstr)
    var resultBlock = newStmtList()

    for arg in args:
      let reprStr = arg.toRepr()
      let tmpSym = genSym(nskLet, "dbgTmp")
      let decl = newLetStmt(tmpSym, arg)
      let printStmt = genAst(loc, reprStr, val = tmpSym):
        echo loc, " | ", reprStr, " = ", val
      resultBlock.add(decl)
      resultBlock.add(printStmt)
      tupleConstr.add(tmpSym)

    resultBlock.add(tupleConstr)
    return newNimNode(nnkStmtListExpr).add(resultBlock)

# when isMainModule:
#   dbg()
#   let x = dbg(1 + 2)
#   let (a, b) = dbg("hello", x * 10)
