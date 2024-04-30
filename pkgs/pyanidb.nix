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
    rev = "e9963b4669ce3f0026e8c9853813b989ea97999e";
    hash = "sha256-aBqwvcXXELgIJOQICnOr6HecWNUkUdyqMaC4UNrU98M=";
  };
  propagatedBuildInputs = [setuptools];
  doCheck = false;
  postInstall = ''
    install -Dm444 ./openssl.cnf.legacy $out/share/openssl.legacy.cnf
    wrapProgram $out/bin/anidb --set OPENSSL_CONF $out/share/openssl.legacy.cnf
  '';
}
