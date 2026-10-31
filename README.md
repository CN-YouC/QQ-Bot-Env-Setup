# QQ 官方机器人 · Windows 环境一键配置

给 Windows 10/11 上的 QQ 官方机器人（`qq-botpy-v2`）准备运行环境：找到或装好 Python 3.12、装齐锁定版本的依赖、跑一次导入自检。**不含机器人源码**，只负责「前置环境」。

## 它解决什么

新机器上跑机器人，通常要踩这几步：Python 装哪个版本、装完没勾 PATH、`pip` 慢到超时、`qq-botpy` 和 `qq-botpy-v2` 装串了、装完不确定到底能不能用。这个脚本把这四步做成双击一次。

## 特性

- **不绑路径**：整个文件夹放桌面、D 盘、U 盘都行
- **不绑机器**：x64 / ARM64 自动识别，按当前用户安装，不需要管理员
- **不绑版本**：机器上已有 Python 3.9+ 就直接复用，没有才下载 3.12.10
- **国内镜像优先**：Python 安装包走华为云 → 清华 → 阿里云 → 官方源；pip 走清华镜像，失败回退官方 PyPI
- **依赖锁死**：四个依赖都是精确版本，不会「今天能装、明天装完崩」
- **失败不装成功**：最后一步真做 `import botpy, aiohttp, apscheduler, yaml` 验证，导入失败会明确报错

## 快速开始

1. 双击 `一键配置环境.bat`（**不要**右键「以管理员身份运行」）
2. 等它跑完，看到 `[DONE] Environment is ready.`
3. 到机器人目录双击 `启动主控.bat`

装失败会打印具体原因，日志在同目录 `setup_log.txt`。

## 脚本做了什么

| 步骤 | 行为 |
| --- | --- |
| 1. 找 Python | `py -3` → `python` → `%LOCALAPPDATA%\Programs\Python\Python3*` → `%ProgramFiles%\Python3*`，只认 3.9 及以上 |
| 2. 装 Python | 找不到才下载 `3.12.10`（四个源逐个试，文件小于 20 MB 视为失败、自动换下一个），以当前用户静默安装并勾选 Add to PATH |
| 3. 装依赖 | `pip install -r requirements.txt`（清华镜像，失败回退官方）；若存在 `requirements-extra.txt` 再装一遍 |
| 4. 验证 | `import botpy, aiohttp, apscheduler, yaml`，失败即报错退出 |

## 依赖

| 包 | 版本 | 说明 |
| --- | --- | --- |
| `qq-botpy-v2` | `1.0.2` | 机器人 SDK，导入名仍是 `botpy` |
| `aiohttp` | `3.13.3` | 网络请求；**3.14+ 要求 Python 3.10+**，为了兼容 3.9 锁在 3.13.x |
| `APScheduler` | `3.11.3` | 定时任务 |
| `PyYAML` | `6.0.3` | SDK 读取配置 |

要加库：在 `requirements-extra.txt` 里加一行，重新双击脚本即可，不用改 bat。

## 不想用这个脚本？手动装（四步）

```powershell
# 1. 装 Python 3.12（勾选 "Add python.exe to PATH"）
winget install -e --id Python.Python.3.12
# 或到 https://www.python.org/downloads/ 下 Windows installer (64-bit)

# 2. 在本文件夹装依赖（镜像不通就去掉 -i 参数）
python -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple

# 3. 验证
python -c "import botpy, aiohttp, apscheduler, yaml; print('ok')"
```

手动装和脚本装的结果一致：一个 Python 解释器 + 四个锁定版本的库。

## 风险与注意事项

**这个脚本会静默安装软件，请先了解它做了什么再用。**

1. **静默安装 Python**：不弹安装向导，装完自动写入你的**用户 PATH**（不是系统 PATH）。
2. **不校验安装包哈希**：只检查下载文件大于 20 MB，用来排除「下成了错误页面」。镜像被投毒或遭中间人替换时拦不住——介意就按上面的手动步骤装。
3. **依赖来自 PyPI 镜像**：信任镜像站与包作者；版本已锁死，不会漂移。
4. **可能被杀软/企业策略拦截**：下载 exe 加静默安装是敏感行为，需要白名单，否则会卡在 `[1/4]`。
5. **不要用管理员运行**：安装按当前用户进行，提权可能装到别的用户配置里，机器人反而找不到。
6. **PATH 对新进程才生效**：装完已经开着的终端要重开。

## 环境要求

| 项目 | 要求 |
| --- | --- |
| 系统 | Windows 10 / 11，64 位（x64 或 ARM64） |
| 网络 | 首次需要联网（Python 约 25.7 MB + 依赖 10~30 MB） |
| 权限 | 不需要管理员 |
| 磁盘 | Python 装到 `%LOCALAPPDATA%\Programs\Python` |

## 目录

| 文件 | 说明 |
| --- | --- |
| `一键配置环境.bat` | 全部逻辑，纯 ASCII + CRLF |
| `requirements.txt` | 必需依赖，精确版本 |
| `requirements-extra.txt` | 可选扩展，默认空 |
| `安装说明.txt` | 面向使用者的完整手册 |

## 许可

[MIT](LICENSE)
