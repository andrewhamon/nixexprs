{
  weechat-matrix-contrib = { python3Packages, weechat-matrix }: python3Packages.buildPythonApplication rec {
    pname = "weechat-matrix-contrib";
    inherit (weechat-matrix) version src;

    propagatedBuildInputs = with python3Packages; [ magic requests matrix-nio ];

    format = "other";

    postPatch = ''
      substituteInPlace contrib/matrix_upload \
        --replace "env -S " ""
    '';

    buildPhase = "true";
    installPhase = ''
      install -Dm0755 -t $out/bin contrib/matrix_{upload,decrypt}
    '';
  };

  weechat-matrix = { pythonPackages, fetchFromGitHub, weechat-matrix-contrib }: pythonPackages.buildPythonPackage rec {
    pname = "weechat-matrix";
    version = "2019-07-16";

    src = fetchFromGitHub {
      owner = "poljar";
      repo = pname;
      rev = "dc97101d47187f15e106579200ad0d17e9e67192";
      sha256 = "19294nzvk4vxj8zna9vrqbyg2swyighqvfja4kknj3i1d9szdy3p";
    };

    propagatedBuildInputs = with pythonPackages; [
      pyopenssl
      webcolors
      future
      atomicwrites
      attrs
      Logbook
      pygments
      matrix-nio
    ];

    passAsFile = [ "setup" ];
    setup = ''
      from io import open
      from setuptools import find_packages, setup

      with open('requirements.txt') as f:
        requirements = f.read().splitlines()

      setup(
        name='@name@',
        version='@version@',
        install_requires=requirements,
        packages=find_packages(),
      )
    '';

    weechatMatrixContrib = weechat-matrix-contrib;
    postPatch = ''
      substituteInPlace matrix/uploads.py \
        --replace matrix_upload $weechatMatrixContrib/bin/matrix_upload
      substituteAll $setupPath setup.py
    '';
  };
}
