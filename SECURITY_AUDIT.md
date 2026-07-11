# Padavan 4.4 / K2P 安全审计（2026-07-11）

## 范围与结论

本次审计聚焦当前 `K2P.config` 实际启用的固件面：Linux 4.4.198、内置 root 权限 `httpd`、Dropbear、dnsmasq、miniupnpd、KumaSocks、bandwidthd，以及启动、存储和防火墙脚本。检查方式包括人工数据流审查、危险 API 检索、默认配置核验和仓库自带 ShellCheck。

结论：**不应把管理面暴露到 WAN。** 本分支现已完成源码层面的第一轮整改；下列条目保留原始发现和当前状态，便于复核。没有仅凭版本号把“可能存在的 CVE”误报为已确认漏洞；完整 CVE/SBOM 匹配仍需最终固件二进制和持续漏洞情报。

## 整改状态（2026-07-11，按产品取舍更新）

| 原风险 | 状态 | 已实施措施 |
|---|---|---|
| Web CSRF + root 控制台 | 已修复 | 删除控制台页面及 `SystemCmd` 后端；认证 POST 强制同源 Origin/Referer；移除 localhost 免认证 |
| 固定管理凭据 | 保持易用 | 默认仍为 `admin/admin`；不做首次强制改密（产品取舍） |
| 默认 SSH / UPnP | 已收紧 | SSH、UPnP 默认关闭；Dropbear 仍允许口令认证（便于首次启用） |
| HTTP/TLS 默认 | 按易用保留 HTTP | 默认仍 HTTP；可选 HTTPS 时证书自动生成（2048/SHA-256）、TLS≥1.2、去掉 3DES；统一安全响应头 |
| 管理面绑定 | 已修复 | `httpd` 仅绑定 `lan_ipaddr`（IPv4），不再 `INADDR_ANY` |
| bandwidthd XSS/越界 | 已修复 | PTR 有界复制；图形路径 HTML 实体转义（K2P NOGRAPH 仅 IP） |
| root shell 拼接 | 已修复所列点 | USB 清理改 `unlink`；Samba/`ejusb`/`hotplug`/`TZ` 改参数化或 API；生产 Web `SystemCmd` 已删除 |
| 纵深防御不足 | 已缓解 | userspace strong SSP/FORTIFY/RELRO/NOW；内核 strong protector、seccomp、dmesg restrict；Dropbear harden |
| 无用组件 | 已修复 | K2P 移除 VLMCSD；可选 HTTPS 组件保留 |
| CI 使用 MD5 | 已修复 | 改发 SHA-256 |
| 固件签名 | 不做 | 产品取舍：升级仍依赖可信管理面与 CI 产物哈希 |

**刻意未做：** 强制首次改密、随机初始口令、HTTPS-only 默认、固件签名、完整 CSRF token 会话。

**尚未声称解决的系统性风险：** Linux 4.4 生命周期、闭源无线驱动、历史源码包 CVE、无会话 cookie/登录限速等。

## 已确认问题

### P0：Web 管理操作无 CSRF 防护，可借管理员浏览器执行 root 命令

- `trunk/user/httpd/web_ex.c:3491-3514` 接受 `action_mode= SystemCmd ` 和攻击者提供的 `SystemCmd`。
- `trunk/user/httpd/web_ex.c:162-170` 最终将其交给 shell 执行；`httpd` 以 root 运行。
- `trunk/user/httpd/httpd.c:983-1000` 只检查 HTTP Basic 凭据，没有 CSRF token、Origin/Referer 校验或自定义请求头要求。
- `trunk/user/httpd/web_ex.c:4239-4244` 对配置、升级、恢复等敏感 POST 也采用同一认证模型。

影响：管理员登录管理页后访问恶意网页，可能被跨站表单触发配置变更、重启；结合 `SystemCmd` 可成为 root 级命令执行。是否成功受浏览器 Basic Auth 缓存行为影响，但不应作为安全边界。

修复：删除生产固件中的 `SystemCmd` 功能；为每个状态变更请求加入高熵、会话绑定、一次或限时 CSRF token，同时严格校验 `Origin`/`Host`；GET 必须只读。不要仅依赖 Referer。

### P1：出厂管理凭据固定为 admin/admin，SSH 默认开启

- `trunk/user/shared/defaults.h:28,47` 定义用户名和密码均为 `admin`。
- `trunk/user/shared/defaults.c:149-155` 默认 HTTP 明文、固定口令。
- `trunk/user/shared/defaults.c:989-990` Telnet 默认关闭，但 SSH 默认开启。
- `trunk/user/rc/services.c:233-252` 启动 Dropbear；WAN 开放虽默认关闭，但 LAN 内任意设备均可尝试默认凭据。

影响：新刷机、恢复出厂或遗忘改密时，LAN/Wi-Fi 内攻击者可直接取得 root shell；HTTP Basic 凭据还会在默认 HTTP 中明文传输。

修复：首次启动强制设置随机强密码后才允许管理；每台设备生成唯一初始密码；默认关闭 SSH，开启时优先仅允许密钥并禁止口令/root 远程登录；管理面默认 HTTPS-only。

### P1：固件升级入口未看到镜像真实性验证

- `trunk/user/httpd/web_ex.c:4242` 暴露固件上传入口。
- 上传处理和 MTD 写入链路主要校验格式/CRC；K2P 内核配置中 `CONFIG_MODULE_SIG` 关闭，仓库也未发现固件公钥签名验证链。

影响：一旦管理凭据、浏览器会话或供应链被攻破，攻击者可持久化任意固件。CRC/哈希只能检测损坏，不能证明发布者身份。

修复：在 bootloader 可承受范围内建立 Ed25519/ECDSA 签名校验；至少在 Web 升级器中嵌入只读公钥并拒绝未签名镜像。CI artifact 另发 SHA-256 和签名，避免 MD5 作为信任依据。

### P2：管理服务绑定所有地址，安全性依赖防火墙/NVRAM

- `trunk/user/httpd/httpd.c:545-582` 将 HTTP/HTTPS socket 绑定到 `INADDR_ANY`/IPv6 any。
- `trunk/user/shared/defaults.c:151` 的 `http_access=0` 是“All”，不是接口级绑定。
- WAN 防火墙开放默认关闭是积极措施，但配置错误、桥接/AP/VPN/IPv6 变化会扩大可达面。

修复：直接绑定 LAN 管理地址/接口；WAN 管理使用独立显式 listener；对 IPv4、IPv6、VPN 分别采用默认拒绝策略。

### P2：带宽报告存在存储型 XSS/内存安全风险

- `trunk/user/bandwidthd/src/graph.c:214-218` 把不可信反向 DNS 主机名用 `sprintf` 写入固定缓冲区。
- `trunk/user/bandwidthd/src/graph.c:521-533` 将该主机名未 HTML 转义地写入认证后的管理页面。

影响：能控制 PTR/DNS 回答的网络参与者可能注入 HTML/JavaScript，攻击管理源；过长主机名还形成固定缓冲区溢出风险（具体可利用性需目标 libc/DNS 行为动态验证）。

修复：使用有界复制，拒绝超长名称；输出 HTML 时统一实体编码。更稳妥的默认值是禁用反向解析，仅显示 IP。

### P2：存在多处 shell 拼接，扩大二次注入面

- `trunk/user/rc/services_stor.c:549-554` 将存储账户用户名/密码拼入 `smbpasswd` shell 命令。
- `trunk/user/httpd/aidisk.c:1519-1533` 将挂载点拼入 `rm` 命令。
- `trunk/user/shared/shutils.c:443-452` 的通用 `doSystem()` 广泛经 shell 执行。
- `trunk/user/rc/hotplug_stor.c:108-123` 使用环境变量参与 shell 脚本调用。

影响：当前部分输入有 UI 长度限制或来源约束，未全部证明为远程直接可利用；但恶意 NVRAM、恢复包、USB 元数据或其他漏洞可把它们升级成 root 命令执行。

修复：全部改为 `fork` + `execve`/现有 `eval()` 参数数组；文件删除使用 `unlinkat`/目录遍历 API；永不把密码放在命令行。

### P2：内核与进程缺少现代纵深防御

- K2P 内核为 4.4.198；`CONFIG_SECCOMP`、`CONFIG_SECURITY`、`CONFIG_MODULE_SIG` 关闭。
- 仅启用 regular stack protector，未启用 strong；未见全局 PIE/完整 RELRO/FORTIFY 策略。
- `httpd` 直接以 root 处理解析、上传和命令执行。

影响：任何解析器或服务漏洞更容易直接转为完整系统控制。

修复：在不换 Padavan 的前提下，优先回移仍受维护分支的网络栈安全修复；全局启用 `-fstack-protector-strong -D_FORTIFY_SOURCE=2 -fPIE`、PIE、RELRO/NOW（逐包验证 16 MB/性能影响）；httpd 拆出最小权限 helper。

## 组件与默认攻击面

| 组件 | 当前观察 | 建议 |
|---|---|---|
| Linux | 4.4.198，已停止上游维护 | 最高优先级维护补丁队列；关闭不用的协议/模块 |
| Dropbear | 2020.81，默认 LAN 开启 | 升级；默认关闭或 key-only |
| BusyBox | 1.24.x | 升级并最小化 applet |
| pppd | 2.4.7 | 若不用 PPTP/L2TP/PPP 功能则裁剪；否则升级 |
| vsftpd | 3.0.3，默认关闭 | 保持关闭，避免 WAN |
| Samba | 3.6，默认关闭 | 极老；建议从 K2P 镜像彻底裁剪 |
| dnsmasq | 2.92rel2 | 当前较新；继续跟踪补丁 |
| OpenSSL | README 标注 3.0.20 | 继续跟踪 3.0 LTS 安全更新 |
| miniupnpd | 2.3.10，UPnP 默认开启且 secure=1 | 不需要则默认关闭；限制内外端口与 ACL |
| VLMCSD | 编译进入镜像、默认关闭 | 自用无需求应裁剪 |
| HTTP | 默认明文 80 | HTTPS-only；禁止 WAN；加入安全响应头 |

## 其他核验结果

- 正面项：Telnet、FTP、Samba、VLMCSD 和 WAN SSH 默认关闭；UPnP `secure_mode` 默认开启；Web 路径有基础 `..` 拒绝和 50 MB body 上限；uClibc 配置启用了 RELRO/no-exec-stack。
- Web 的“本机请求免认证”（`httpd.c:525-531`）意味着任何可向 `127.0.0.1` 发请求的本地服务漏洞/SSRF 都会直接越权，应移除。
- HTTP Basic 采用普通 `strcmp` 且无速率限制/失败退避；LAN 爆破成本低。应改为会话 cookie（Secure/HttpOnly/SameSite=Strict）、强口令 KDF 和速率限制。
- 缺少 CSP、`X-Frame-Options`/`frame-ancestors`、HSTS 等统一响应头；这会放大 XSS/点击劫持风险。
- CI 使用 `md5sum` 仅适合损坏检测，不适合发布完整性；GitHub Actions 第三方 action 应固定到 commit SHA。

## 工具结果与限制

- `sh trunk/tools/shellcheck.sh` 完成，发现一个明确脚本错误：`trunk/user/shadowsocks/scripts/shadowsocks.sh:353` 在赋值符两侧加空格；另有大量未引用展开、非 POSIX `local`/`==` 等警告。K2P 当前只启用 KumaSocks，但共享脚本仍应清理。
- 本次没有刷入真机做端口扫描、ASan/UBSan、模糊测试或 Web 浏览器 PoC；也没有最终 `.trx` 可用于 ELF hardening 和真实包清单核验。
- Linux 4.4 和仓库内历史组件的 CVE 数量很大；“代码在仓库”不等于“进入 K2P 镜像”。下一阶段应以最终 rootfs 生成 CycloneDX/SPDX SBOM，再做 OSV/NVD/vendor advisory 匹配并人工确认可达性。

## 建议修复顺序

1. 删除 Web `SystemCmd`，为所有变更接口加 CSRF/Origin 防护。
2. 强制首次改密，默认关闭 SSH/UPnP，管理面 HTTPS-only 且仅绑定 LAN。
3. 为固件建立签名验证；CI 发布 SHA-256 + 签名。
4. 修复 bandwidthd 的 HTML 转义和有界复制；消灭 shell 字符串拼接。
5. 裁剪 Samba/FTP/VLMCSD/PPTP 等不用组件，升级 Dropbear/BusyBox/pppd。
6. 对最终镜像做 SBOM+CVE 核验、端口扫描、Web fuzz、上传/恢复格式 fuzz 和 ELF hardening 检查。
