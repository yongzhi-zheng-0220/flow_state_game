
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