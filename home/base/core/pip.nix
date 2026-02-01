{
  # 中国大陆 pip 优化：镜像、超时、重试
  xdg.configFile."pip/pip.conf".text = ''
    [global]
    # 主镜像（南大）
    index-url = https://mirror.nju.edu.cn/pypi/web/simple
    # 备用镜像（清华），主镜像不可用时自动尝试
    extra-index-url = https://pypi.tuna.tsinghua.edu.cn/simple
    # 信任镜像域名，避免 SSL 校验问题
    trusted-host = mirror.nju.edu.cn
                   pypi.tuna.tsinghua.edu.cn
                   mirrors.ustc.edu.cn
    # 超时与重试（国内网络波动）
    timeout = 120
    retries = 5
    # 输出格式
    format = columns
  '';

  # 环境变量兜底（pip、uv 等工具读取）
  home.sessionVariables = {
    # pip
    PIP_INDEX_URL = "https://mirror.nju.edu.cn/pypi/web/simple";
    PIP_EXTRA_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
    PIP_TRUSTED_HOST = "mirror.nju.edu.cn pypi.tuna.tsinghua.edu.cn";
    # uv（国内网络优化）
    UV_DEFAULT_INDEX = "https://mirror.nju.edu.cn/pypi/web/simple";
    UV_EXTRA_INDEX_URL = "https://pypi.tuna.tsinghua.edu.cn/simple";
    UV_HTTP_TIMEOUT = "120";
    UV_HTTP_RETRIES = "5";
  };
}
