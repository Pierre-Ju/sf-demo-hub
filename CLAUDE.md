# sf-demo-hub

面向 **制造 / 零售 / 医疗 / 金融** 四个行业的 Salesforce Demo 中枢仓库。所有 demo 跑在 **Scratch Org** 上，用同一套脚本一键拉起、播种、销毁。

---

## 目录结构

```
sf-demo-hub/
├── sfdx-project.json                    # SFDX 项目根
├── .mcp.json                            # Claude Code MCP（默认接 Salesforce MCP）
├── CLAUDE.md
├── create-demo.sh                       # 一键创建某行业 demo
├── config/<industry>-scratch-def.json   # 四个行业的 scratch-def
├── scripts/
│   ├── apex/seed-<industry>.apex        # 行业种子数据（幂等）
│   └── reset.sh                         # 销毁指定 alias 的 scratch org
└── force-app/main/default/              # SFDX 源代码
```

---

## 常用命令

| 目的 | 命令 |
| --- | --- |
| 列出 / 登录 dev hub | `sf org list` / `sf org login web --set-default-dev-hub --alias devhub` |
| **创建某行业 demo** | `./create-demo.sh <industry>` |
| 只播种数据 | `sf apex run -o <alias> -f scripts/apex/seed-<industry>.apex` |
| 打开 default org | `sf org open` |
| **销毁 demo org** | `./scripts/reset.sh demo-<industry>` |

> Windows：用 Git Bash / WSL 跑 `.sh`，或把脚本逻辑改成 PowerShell 逐条执行。

---

## 命名约定

- **alias**：`demo-<industry>`（如 `demo-finance`）
- **orgName**：`SF Demo Hub - <Industry>`
- **种子脚本**：`seed-<industry>.apex`，**幂等**（开头 `SELECT ... LIMIT 1` 判存）

---

## Scratch org 配置（重要）

### 1. 标准模板 — 贴近正式 org

每个 `config/<industry>-scratch-def.json` 都以下面为基线，行业差异只动 `orgName` 和 `features` 里追加的行业云项：

```json
{
  "orgName": "SF Demo Hub - <Industry>",
  "edition": "Enterprise",
  "language": "zh_CN",
  "country": "CN",
  "features": [
    "Sales",
    "ServiceCloud",
    "Chatter",
    "MultiCurrency"
  ],
  "settings": {
    "lightningExperienceSettings": { "enableS1DesktopEnabled": true },
    "languageSettings": {
      "enableTranslationWorkbench": true,
      "enableEndUserLanguages": true
    },
    "currencySettings": { "enableMultiCurrency": true },
    "forecastingSettings": { "enableForecasts": true },
    "activitiesSettings": { "enableActivityReminders": true }
  }
}
```

**为何这些字段必须写**（事后 Metadata API 改不了，或行为不符合正式 org）：

| 字段 | 原因 |
| --- | --- |
| `language` + `country` | scratch org 默认 `en_US`/`US`，**无 Metadata API 改 org default language**，错了只能销毁重建 |
| `languageSettings.enableEndUserLanguages` | 启用后用户可在 personal settings 切换 UI 语言（注意：字段名是复数） |
| `languageSettings.enableTranslationWorkbench` | 打开 Translation Workbench，跟正式 org 一致 |
| `MultiCurrency` feature + `enableMultiCurrency: true` | 开启多币种支持；**激活后不可回退**，跨币种 demo 场景需要 |
| `forecastingSettings` / `activitiesSettings` | Sales Cloud 默认开关跟正式 org 一致 |

### 2. 行业 feature 授权（依赖 Dev Hub）

在基线 `features` 之上，按行业追加：`ManufacturingCloud` / `HealthCloud` / `FinancialServicesCloud` / `ConsumerGoodsCloud` / `B2BCommerce` 等。这些**依赖 Dev Hub 授权**：

- 公司 Production Dev Hub 通常有
- 个人 Trailhead Playground / Developer Edition Dev Hub 通常没有
- 报 `feature not allowed`：去掉该 feature 即降级为通用 Enterprise，种子脚本仍可跑（只创建标准对象）

### 3. 创建后 checklist（Metadata API 控不了的部分）

每个 demo org 按顺序跑：

1. **开邮件投递（两个开关都要开）** — Setup → Email → **Deliverability**：
   - dropdown `Access to Send Email (All Email Services)` → `All email`（默认 "System email only" 会**静默丢弃** Apex / Flow 邮件）
   - checkbox `Use a substitute email address for unverified domains` **勾上**（中文："对未验证的域使用替代邮件地址"）
   - 两项缺一不可：dropdown 决定能不能发，checkbox 让 unverified 域（如公司域 `accenture.com`）用 SF 提供的替代 From 地址发出去
   - Spring '24+ 后 SF 强制要求 sender 域已验证才能用真实 From；公司域域级验证要 DNS 配合通常不可行，所以 **substitute checkbox 是 demo 标准做法**。From 会被替换为 SF 域地址，邮件内容不变
   - 想让 From 显示真实邮箱（公司域可控时）才需要做：(i) User avatar → Settings → My Email Settings → Verify（per-user）；(ii) Setup → Verified Email Domains → Add Domain
2. **开 Pipeline Inspection** — Setup → Pipeline Inspection → 开关打开
   - **无 Metadata API 支持**：`pipelineInspectionSettings` 不是合法的 Settings 类型，只能 UI 开
3. **验证语言/区域** — Setup → Company Information 确认 Language / Locale 符合预期
4. **List View 权限** — 试某对象 List Views 的 "New"；失败去 Setup → Profiles → System Administrator 补 "Manage Public List Views" / "Customize Application"
5. **播种数据** — `sf apex run -o demo-<industry> -f scripts/apex/seed-<industry>.apex`

---

## 种子脚本设计原则

1. **只用标准对象** — 避免依赖行业包安装后才有的自定义对象
2. **幂等** — 开头 `SELECT ... LIMIT 1` 判存，重复跑不炸库
3. **小而精** — 每行业 5–10 个 Account + 配套 Contact/Opportunity
4. **行业差异化** — 体现在 Industry 字段、Account 名字、Opportunity 金额量级、行业阶段名

---

## MCP

`.mcp.json` 默认接 [Salesforce 官方 MCP](https://www.npmjs.com/package/@salesforce/mcp)，跟随当前默认 org。如需固定 alias，把 `DEFAULT_TARGET_ORG` 改成具体 alias。
