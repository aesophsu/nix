{
  # Pip: mirror, timeout, retries (mainland-friendly)
  xdg.configFile."pip/pip.conf".text = ''
    [global]
    # primary mirror (NJU)
    index-url = https://mirror.nju.edu.cn/pypi/web/simple
    # fallback mirror (Tsinghua)
    extra-index-url = https://pypi.tuna.tsinghua.edu.cn/simple
    # trust mirror hosts for SSL
    trusted-host = mirror.nju.edu.cn
                   pypi.tuna.tsinghua.edu.cn
                   mirrors.ustc.edu.cn
    # timeout and retries
    timeout = 120
    retries = 5
    format = columns
  '';

  # Only package index and client tuning vars live here.
  # Generic HTTP(S)_PROXY/ALL_PROXY are managed in user/darwin/services/mihomo/default.nix.
  home.sessionVariables = {
    PIP_INDEX_URL = "https://mirror.nju.edu.cn/pypi/web/simple";
    PIP_EXTRA_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
    PIP_TRUSTED_HOST = "mirror.nju.edu.cn pypi.tuna.tsinghua.edu.cn";
    # uv mirror/timeout
    UV_DEFAULT_INDEX = "https://mirror.nju.edu.cn/pypi/web/simple";
    UV_EXTRA_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
    UV_HTTP_TIMEOUT = "120";
    UV_HTTP_RETRIES = "5";
  };
}
