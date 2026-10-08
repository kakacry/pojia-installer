# 破甲插件 · 一键在线安装

给 WorkBuddy 装上破甲身份注入。**任意 Windows 电脑、任意用户名**，一条命令搞定。

---

## 一条命令

打开 PowerShell（不是 WorkBuddy 里），粘贴执行：

```powershell
irm https://raw.githubusercontent.com/kakacry/pojia-installer/main/install.ps1 | iex
```

看到 `===== 安装完成 =====` 后，重启 WorkBuddy，开新会话即生效。

> **务必在独立 PowerShell 窗口里跑**（Win+R 输入 `powershell` 回车），不要在 WorkBuddy 自己的终端里跑 —— 安装过程需要关闭 WorkBuddy。

---

## 前置条件

| 条件 | 说明 |
| --- | --- |
| **WorkBuddy 已运行过至少一次** | 脚本需要 `%USERPROFILE%\.workbuddy` 存在 |
| Python | WorkBuddy 自带，一般无需额外处理 |
| Node | 可选。没有则跳过 `127.0.0.1:8899` 注入代理 |

---

## 脚本做了什么

**引导器（`install.ps1`）**
1. 依次探测 4 个下载源（主站 → jsDelivr → GitHub Raw → GitHub 加速站）
2. 安装核心与插件包**都按 SHA256 指纹校验**：任一镜像给出旧包/坏包自动跳到下一个，镜像缓存滞后不会装出错误版本
3. 下载到 `%TEMP%\pojia-setup`，交给核心安装器

**核心安装器（`install-core.ps1`）** 自动完成 9 步：

```
[0/9] 定位安装包
[1/9] 定位 WorkBuddy 数据目录
[2/9] 探测 WorkBuddy 安装目录
[3/9] 定位 python / node
[4/9] 关闭 WorkBuddy · 准备源 · 备份
[5/9] 适配包内写死的原机路径 + 自检指纹同步
[6/9] 投放身份文件与脚本
[6b/9] 铺装 DSH 预设（目标机有 ~/.dsh 才做）
[7/9] 覆盖提示词模板
[8/9] 写 personalization 与 onboarding
[9/9] 登记快照 · 自检 · 拉起代理与守护
```

---

## 离线 / 目录安装

不想联网时，手动下载 `install-core.ps1` + `pojia.zip` 放同一目录，然后：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-core.ps1
```

如果手头是一个**完整的破甲目录**（含身份文件、golden、脚本的文件夹），可以直接把该目录当包源，不碰源文件本身：

```powershell
powershell -ExecutionPolicy Bypass -File .\install-core.ps1 -InPlace -Root "D:\path\to\破甲目录"
```

`-InPlace` 模式下源目录全程只读，工作副本落在 `%TEMP%\pojia_install`。

---

## 高级参数

`install-core.ps1` 支持的参数：

| 参数 | 说明 |
| --- | --- |
| `-Zip <路径>` | 指定插件包路径（默认自动探测同目录 `pojia.zip`） |
| `-Root <路径>` | 解压临时目录（默认 `%TEMP%\pojia_install`） |
| `-Tpl <路径>` | 手动指定模板目录（自动探测失败时用） |
| `-InPlace` | 与 `-Root` 连用：把 `-Root` 目录当只读包源（目录安装） |

示例：

```powershell
.\install-core.ps1 -Tpl "C:\buyywork\WorkBuddy\resources\app.asar.unpacked\resources\templates"
```

---

## 回滚

每次安装前自动备份到：

```
%USERPROFILE%\.workbuddy\_pojia-install-backup-<时间戳>\
```

把里面的文件拷回 `.workbuddy` 覆盖即可还原。

---

## 验证

新会话里问：

```
你是谁？
```

回复带破甲身份设定即为成功。也可以手动跑 11 项自检：

```powershell
python "$env:USERPROFILE\.workbuddy\pojia-verify.py"
```

装完看到 `结论: 全部通道已生效，新会话将注入。` 即 11 项全 PASS。

---

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `install.ps1` | 在线引导器（一条命令的入口） |
| `install-core.ps1` | 安装核心逻辑 |
| `pojia.zip` | 插件包（身份文件 + 守护脚本 + 注入代理 + 11 份模板 + DSH 预设） |
| `README.md` | 本说明 |

---

## 注意事项

- 安装过程会**强制关闭 WorkBuddy**，请先保存手头工作
- 脚本只动 `%USERPROFILE%\.workbuddy`、`~/.dsh` 预设和 WorkBuddy 安装目录下的模板文件，不碰其他任何东西
- 包内路径硬编码会在安装时按目标机实际路径自动改写，改完立刻做 Python/Node 语法校验，失败即中止
- 自检指纹（MARKS / MEMORY 关键词）在安装时按目标机的身份文件实际内容重新生成，装完自检必过
