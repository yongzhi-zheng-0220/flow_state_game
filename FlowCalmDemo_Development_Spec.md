# FlowCalmDemo
## Anxiety → Flow 转换引擎
### Development Specification v0.1

---

# 1. 项目目标

## 1.1 项目目的

构建一个本地运行的最小可行 Demo，用于：

- 通过节奏化呼吸引导降低焦虑状态
- 通过轻量级专注任务帮助进入心流状态
- 构建“稳定度 → 难度自适应”机制
- 为后续产品化（数据记录 / 心率接入 / 企业版）打基础

---

## 1.2 MVP 范围（当前版本）

包含：

1. 呼吸同步模块（Breath Sync）
2. 稳定度计算系统（Stability Engine）
3. 简单心流拼图（Flow Puzzle）
4. 状态切换逻辑
5. 本地运行，无外部依赖

不包含：

- 心率设备接入
- 网络功能
- 声音系统
- 数据持久化（后续版本）

---

# 2. 技术架构

## 2.1 引擎选择

- Engine: Godot 4.x
- Language: GDScript
- 平台：Windows / macOS 本地运行

---

## 2.2 模块划分

Main  
 ├── BreathController  
 ├── Stability Engine  
 ├── PuzzleController  
 └── Adaptive Difficulty  

模块职责划分如下：

---

### A. Main（状态管理层）

职责：

- 管理当前游戏状态（BREATH / PUZZLE）
- 接收事件信号
- 控制场景显示与隐藏
- 传递稳定度参数

状态机：

BREATH → PUZZLE → BREATH

---

### B. BreathController（呼吸同步层）

职责：

- 采集输入节奏（Space 按住 / 松开）
- 记录 inhale / exhale 时间
- 计算稳定度
- 判断是否满足进入心流条件

核心变量：

| 变量 | 说明 |
|------|------|
| target_inhale | 目标吸气时间 |
| target_exhale | 目标呼气时间 |
| inhale_times[] | 最近吸气记录 |
| exhale_times[] | 最近呼气记录 |
| stability | 当前稳定度 |
| stable_accum | 连续稳定时间 |

---

### C. Stability Engine（核心算法层）

核心公式：

inh_err = |inhale - target| / target  
exh_err = |exhale - target| / target  

stability = 1 - clamp((inh_err + exh_err) * k)

设计原则：

- 不使用瞬间评分
- 使用平滑插值 lerp
- 允许轻微误差
- 避免满分跳变

---

### D. PuzzleController（心流任务层）

职责：

- 生成网格
- 生成目标格
- 处理移动输入
- 填充目标格
- 判断完成

设计原则：

- 无失败
- 无倒计时
- 只有完成状态

---

### E. AdaptiveDifficulty（自适应层）

当前版本逻辑：

target_count = base + round(stability * scale)

设计目标：

- 稳定度越高 → 目标越多
- 永远略高于当前能力
- 不制造压迫感

---

# 3. 数据流说明

## 3.1 Breath 阶段

输入：

Keyboard Input

输出：

stability_changed(float)  
breath_ready(float)

---

## 3.2 Puzzle 阶段

输入：

stability

输出：

puzzle_completed()

---

## 3.3 状态切换流程

用户呼吸稳定  
    ↓  
stability >= threshold  
    ↓  
持续 stable_time 达标  
    ↓  
emit breath_ready(stability)  
    ↓  
Main 切换到 Puzzle  

---

# 4. UI 设计规范

## 4.1 视觉原则

- 低对比度
- 无闪烁
- 无突然动画
- 色彩缓慢变化

---

## 4.2 Breath 阶段视觉反馈

| 稳定度 | 背景变化 |
|--------|----------|
| 低 | 深色 |
| 中 | 略亮 |
| 高 | 柔和蓝光 |

---

## 4.3 Puzzle 阶段视觉反馈

- 目标格：轻微高亮
- 填充格：柔和蓝色
- 光标：半透明

---

# 5. 核心算法说明

## 5.1 为什么用相对误差

绝对误差在不同目标时间下不公平。

相对误差：

abs(actual - target) / target

更稳定。

---

## 5.2 为什么使用平滑插值

如果直接：

stability = score

会出现：

- 数值剧烈跳动
- 玩家心理波动

使用：

stability = lerp(old, new, 0.08)

产生缓慢过渡。

---

# 6. 扩展设计预留

## 6.1 数据持久化

未来可以记录：

{
  session_id,
  avg_stability,
  breath_duration,
  puzzle_time,
  timestamp
}

用于：

- 焦虑恢复曲线分析
- 企业版报表
- 心理干预辅助

---

## 6.2 心率接入预留

接口预留：

func external_heart_rate_input(hr: float):

将 hr 作为辅助稳定度因子。

---

## 6.3 声音层设计预留

稳定度驱动：

- 背景频率
- 音阶层数
- 白噪强度

---

# 7. 性能要求

- 单场景无超过 1000 节点
- 每帧计算 < 0.5ms
- 不使用复杂物理系统
- 不使用高分辨率贴图

---

# 8. 心理学设计说明

本 Demo 不是：

- 娱乐游戏
- 竞争游戏

它是：

神经系统节奏校准工具

设计遵循：

- 可预测
- 可控制
- 无惩罚
- 轻反馈

---

# 9. 后续版本路线图

## v0.2

- 加入音效系统
- Session 记录
- 关卡渐进

## v0.3

- 心率设备接入
- 日夜模式
- UI 优化

## v1.0

- 可发布 Steam / iOS
- 企业专注辅助模式

---

# 10. 风险评估

| 风险 | 应对 |
|------|------|
| 玩家觉得无聊 | 增加渐进式视觉成长 |
| 呼吸不标准导致挫败 | 降低阈值 |
| 稳定度算法过严 | 加入容差 |

---

# 11. 当前版本验收标准

必须满足：

- 呼吸稳定后自动进入 Puzzle
- Puzzle 可完成
- 完成后返回 Breath
- 无报错
- 无明显卡顿

---

# 12. macOS 本地开发环境配置步骤

## 12.1 开发目标

在 macOS 上搭建可运行的 Godot 本地开发环境，实现：

- 本地调试运行 Demo
- 编辑脚本
- 导出 macOS 可执行文件
- 支持后续版本迭代

---

## 12.2 环境准备

### 系统要求

- macOS 12 以上推荐
- 至少 8GB 内存
- 1GB 可用磁盘空间

---

## 12.3 安装 Godot 4.x

### 步骤

1. 从官网下载安装 Godot 4.x 标准版（.zip）
2. 解压后将 `Godot.app` 拖入：

```
/Applications
```

3. 首次运行若被拦截：

系统设置 → 隐私与安全性 → 允许打开

---

## 12.4 创建项目目录

在终端执行：

```bash
mkdir -p ~/Dev/FlowCalmDemo
```

然后在 Godot 中：

- 项目管理器 → 新建项目
- 项目路径：选择 `~/Dev/FlowCalmDemo`
- 渲染器：选择 Forward+
- 点击“创建并编辑”

---

## 12.5 推荐开发工具：Visual Studio Code（VS Code）

### 安装 VS Code

若未安装，下载安装后：

打开 VS Code  
命令面板 → 执行：

```
Shell Command: Install 'code' command in PATH
```

---

### 推荐插件

- Godot Tools
- Markdown Preview Enhanced

---

## 12.6 设置外部编辑器（可选但推荐）

在 Godot：

编辑器 → 编辑器设置 → 文本编辑器 → 外部

勾选：

使用外部编辑器

执行路径设置为：

```
/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code
```

---

## 12.7 输入映射配置

用于配置键盘控制（呼吸键与方向键）。

### 第一步：打开输入映射界面

在 Godot 顶部菜单栏：

项目 → 项目设置 → 输入映射

进入后可以看到“动作（Action）列表”。

---

### 第二步：检查或添加 ui_accept（呼吸键）

1. 在上方搜索框输入：`ui_accept`
2. 如果已存在：
   - 点击右侧“+”按钮
   - 在弹出窗口中选择“按键”
   - 按下键盘 `Space`
   - 点击“确定”
3. 如果不存在：
   - 在顶部“添加新动作”输入框中输入：`ui_accept`
   - 点击“添加”
   - 然后按上述步骤添加 Space 键

作用说明：

`ui_accept` 将用于检测按住 Space 进行“吸气”。

---

### 第三步：确认方向键动作存在

在搜索框分别检查：

- ui_left
- ui_right
- ui_up
- ui_down

通常 Godot 默认已经存在，并自动绑定方向键。

如果某个不存在：

1. 在“添加新动作”输入框输入对应名称
2. 点击“添加”
3. 点击该动作右侧“+”
4. 选择“按键”
5. 按下对应方向键（← ↑ → ↓）
6. 点击“确定”

---

### 第四步：保存设置

完成后关闭“项目设置”窗口即可。

Godot 会自动保存输入映射配置。

---

### 验证方式（详细步骤）

用于确认输入映射是否真正生效。

#### 第一步：确认项目已设置主场景

项目 → 项目设置 → 应用 → 运行

确认“主场景”已设置为：

```
scenes/Main.tscn
```

如果当前项目中 **不存在 `scenes/Main.tscn` 文件**，请按以下步骤创建：

##### 创建 Main 主场景步骤

1. 在左侧“文件系统”面板中，右键项目根目录（最上层）
2. 选择“新建文件夹”，命名为：`scenes`
3. 在顶部菜单栏点击：场景 → 新建场景（或工具栏左上角的“+”新建场景）
4. 在“选择根节点”窗口中选择：`Node`
5. 创建后，在“场景”面板中选中根节点，将其重命名为：`Main`
6. 点击顶部菜单栏：场景 → 保存场景（或按 ⌘S）
7. 在保存对话框中选择 `scenes` 文件夹，并将文件名保存为：

```
Main.tscn
```

8. 保存完成后，在“文件系统”面板中应能看到：

```
scenes/Main.tscn
```

如果你在第 3 步找不到“新建场景”，请确认你已经进入项目编辑界面（不是项目管理器的新建项目界面）。

保存后，再回到：

项目 → 项目设置 → 应用 → 运行

将“主场景”设置为刚刚创建的 `scenes/Main.tscn`。

完成后即可正常运行项目。

如果未设置，运行时不会加载正确逻辑。

---

#### 第二步：运行项目

点击右上角 ▶ 运行。

进入 Breath 画面后进行测试。

---

#### 第三步：测试 Space（呼吸输入）

1. 按住 Space 键
2. 观察：
   - 背景颜色是否发生变化
   - 稳定度 ProgressBar 是否开始变化
3. 松开 Space
   - 背景应恢复
   - 稳定度继续根据节奏更新

若无反应：

- 返回 项目 → 项目设置 → 输入映射
- 搜索 `ui_accept`
- 确认已绑定 Space 键
- 确认拼写完全一致（区分大小写）

---

#### 第四步：测试方向键（Puzzle 阶段）

1. 保持稳定呼吸直到进入 Puzzle 阶段
2. 按方向键 ← ↑ → ↓
3. 观察光标是否移动

若光标不移动：

- 检查 ui_left / ui_right / ui_up / ui_down 是否存在
- 确认是否绑定对应方向键
- 确认没有误删默认输入动作

---

#### 调试建议（可选）

如果仍然没有响应，可以在脚本中临时添加调试输出：

```gdscript
print("Space pressed")
```

放在 `_process()` 中检测输入的位置，用于确认是否成功接收到输入事件。

---

## 12.8 设置启动场景

项目 → 项目设置 → 应用 → 运行

主场景设置为：

```
scenes/Main.tscn
```

---

## 12.9 首次运行验收

点击右上角 ▶ 运行

应满足：

- Breath 阶段按住 Space 背景变化
- 稳定度条动态更新
- 稳定后自动进入 Puzzle
- Puzzle 可完成并返回 Breath
- 无报错

---

## 12.10 安装导出模板（用于打包）

编辑器 → 管理导出模板  
下载并安装官方模板

然后：

项目 → 导出 → 添加 → macOS

即可导出本地可执行文件。

---

## 12.11 Git 初始化（推荐）

在项目根目录执行：

```bash
cd ~/Dev/FlowCalmDemo
git init
```

建议添加 `.gitignore`：

```
.godot/
.import/
export/
```

---

## 12.12 建议目录结构

```
FlowCalmDemo/
 ├── scenes/
 ├── scripts/
 ├── docs/
 └── assets/
```

开发文档建议存放：

```
docs/FlowCalmDemo_Development_Spec.md
```

---

至此，macOS 本地开发环境搭建完成。