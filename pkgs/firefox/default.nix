{
  wrapFirefox,
  firefox-unwrapped,
  ...
}:
wrapFirefox firefox-unwrapped {
  # https://raw.githubusercontent.com/corbindavenport/just-the-browser/refs/heads/main/firefox/policies.json
  extraPoliciesFiles = [
    # must be a string?
    "${./policies.json}"
  ];
}
