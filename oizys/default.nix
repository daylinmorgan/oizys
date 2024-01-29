{
  buildNimPackage,
}:
buildNimPackage (_final: _prev: {
  pname = "oizys";
  version = "unstable";
  src = ./.;
})
