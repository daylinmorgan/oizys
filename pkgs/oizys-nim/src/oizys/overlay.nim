import std/macros

type
  OverlayKind = enum
    oPre
    oPost
  OverlayProc = object
    node: NimNode
    kind: OverlayKind


proc applyOverlay(child: NimNode, overlayProc: OverlayProc) =
  let node = overlayProc.node
  for p in node.params:
    if p.kind == nnkIdentDefs:
      child.params.add copyNimTree(p)
  case overlayProc.kind:
  of oPre:
    let startIdx = if child.body[0].kind == nnkCommentStmt: 1 else: 0
    for i in countdown(node.body.len()-1, 0):
      child.body.insert(startIdx, copyNimTree(node.body[i]))
  of oPost:
    for stmt in node.body.children():
      child.body.add copyNimTree(stmt)


macro overlay*(x: untyped): untyped =
  ##[
   apply pre and post operations to procs:
   ```nim
   overlay:
     proc pre(a: bool) =
       echo "before"
     proc post(c: bool) =
       echo "after"
     proc mine(b: bool) = 
       echo "inside mine"
   ```
   would result in:
   ```nim
   proc pre(a: bool; b: bool; c: bool) =
     echo "before"
     echo "inside mine"
     echo "after"
   ```
   ]##
  result = newStmtList()
  var overlays: seq[OverlayProc]
  for child in x.children():
    case child.kind:
    of nnkProcDef:
      case ($child.name):
      of "pre": overlays.add OverlayProc(node: child, kind: oPre)
      of "post": overlays.add OverlayProc(node: child, kind: oPost)
      else: result.add child
    else: result.add child

  if overlays.len == 0:
    error "failed to create overlays: didn't find proc pre() or proc post()"

  for i, child in result.pairs():
    if child.kind == nnkProcDef:
      for overlay in overlays:
        applyOverlay(child, overlay)
