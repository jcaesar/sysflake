{
  setuptools,
  buildPythonPackage,
  fetchFromGitHub,
}:
buildPythonPackage {
  pname = "pyanidb";
  version = "0.2.1-jc";
  src = fetchFromGitHub {
    owner = "jcaesar";
    repo = "pyanidb";
    rev = "9b0bfb96ce2c59eb90fa3abe57bf53cdc15433e3";
    hash = "sha256-h2sXEFTz6Y3QN7fRlg0P3MtMeFOXWd3LItM80MpnZ5A=";
  };
  propagatedBuildInputs = [setuptools];
  doCheck = false;
}
