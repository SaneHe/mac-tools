# Mac Text Actions 交互流程

## 1. 主流程
```mermaid
flowchart TD
    A["用户选中文本"] --> B["按下 global shortcut"]
    B --> C["读取当前默认模式"]
    C --> D["优先读取 selected text"]
    D --> E{"读取成功?"}
    E -- "是" --> F["标记来源: selected text"]
    E -- "否" --> G["尝试 clipboard fallback"]
    G --> H{"剪贴板是否得到可用文本?"}
    H -- "否" --> I["展示错误状态"]
    H -- "是" --> J["标记来源: clipboard fallback"]
    F --> K{"默认模式"}
    J --> K
    K -- "自动识别" --> L["按固定优先级识别内容类型"]
    K -- "指定模式" --> M["直接按选定模式执行"]
    L --> N["生成 primary result 或 secondary action"]
    M --> O["生成该模式对应结果或错误"]
    N --> P["展示 result panel"]
    O --> P
    P --> Q["用户复制结果 / 替换原文 / 执行 secondary action / 关闭"]
```

## 2. 快捷键到结果面板时序
```mermaid
sequenceDiagram
    participant U as User
    participant App as App Shell
    participant S as Shortcut Manager
    participant R as Selection Reader
    participant C as Clipboard Reader
    participant D as Detection Engine
    participant T as Transform Engine
    participant P as Result Panel

    U->>S: Press global shortcut
    S->>App: Read current execution mode
    S->>R: Request selected text
    R-->>S: Text or read failure
    alt selected text 可用
        alt 默认模式 = 自动识别
            S->>D: Detect type (source: selected text)
            D-->>S: DetectionResult
            S->>T: Build primary result
        else 默认模式 = 指定模式
            S->>T: Execute selected mode directly
        end
    else selected text 不可用
        S->>C: Read clipboard text
        C-->>S: Clipboard text or empty
        alt 默认模式 = 自动识别
            S->>D: Detect type (source: clipboard fallback)
            D-->>S: DetectionResult
            S->>T: Build primary result
        else 默认模式 = 指定模式
            S->>T: Execute selected mode directly
        end
    end
    T-->>App: TransformResult
    App->>P: Present result panel
```

## 3. 状态栏菜单切换流程
```mermaid
flowchart TD
    A["用户点击状态栏菜单"] --> B["查看单层模式列表"]
    B --> C{"切换方式"}
    C -- "点击菜单项" --> D["更新默认模式"]
    C -- "菜单展开时按 ⌘1-⌘7" --> D
    D --> E["菜单勾选态即时更新"]
    E --> F["等待下一次 global shortcut 执行"]
```

## 4. 无选中文本流程
```mermaid
flowchart TD
    A["按下 global shortcut"] --> B["读取 selected text"]
    B --> C{"有选中文本?"}
    C -- "是" --> D["进入主流程，来源为 selected text"]
    C -- "否" --> E["读取剪贴板"]
    E --> F{"剪贴板是否得到可用文本?"}
    F -- "是" --> G["进入主流程，来源为 clipboard fallback"]
    F -- "否" --> H["result panel 显示: 未检测到可处理文本"]
```

## 5. 当前应用不支持选区读取
```mermaid
flowchart TD
    A["按下 global shortcut"] --> B["Selection Reader 尝试读取"]
    B --> C{"支持读取?"}
    C -- "是" --> D["进入识别流程，来源为 selected text"]
    C -- "否" --> E["读取剪贴板"]
    E --> F{"剪贴板是否得到可用文本?"}
    F -- "是" --> G["进入识别流程，并显示: 已改用剪贴板内容，不是当前实时选区"]
    F -- "否" --> H["result panel 显示: 当前应用暂不支持读取选中文本"]
```

## 6. 非法 JSON 流程
```mermaid
flowchart TD
    A["识别输入为 JSON 候选"] --> B["执行 JSON 解析"]
    B --> C{"解析成功?"}
    C -- "否" --> D["result panel 显示: JSON 校验失败 + 错误说明"]
    C -- "是" --> E["渲染格式化 JSON"]
```

## 7. 二级动作流程
```mermaid
flowchart TD
    A["result panel 已展示"] --> B["用户点击 secondary action"]
    B --> C{"动作类型"}
    C -- "Copy Result" --> D["复制结果"]
    C -- "Replace Selection" --> E["替换原文"]
    C -- "JSON Compress" --> F["生成压缩结果并刷新 result panel"]
    C -- "MD5" --> G["生成 MD5 并刷新 result panel"]
    C -- "Create Reminder" --> H["打开提醒事项创建流程"]
```

## 8. 交互规则总结
- `global shortcut` 是唯一主入口
- 状态栏菜单负责选择当前默认模式
- 菜单展开时可用 `⌘1` 到 `⌘7` 切换默认模式，其中 `自动识别 = ⌘1`、`创建提醒事项 = ⌘2`、`JSON 格式化 = ⌘3`、`JSON Compress = ⌘4`、`时间戳转本地时间 = ⌘5`、`日期转时间戳 = ⌘6`、`MD5 = ⌘7`
- 菜单顺序中将低频的 `创建提醒事项` 固定放在最后，但不改变其 `⌘2` 快捷键映射
- 主流程优先读取 `selected text`
- 仅在读取失败时才允许 `clipboard fallback`
- 读取失败后允许自动触发一次 `clipboard fallback`
- 发生 `clipboard fallback` 时必须明确标注来源，且不能让用户误以为内容来自直接读取到的实时选区
- `自动识别` 只决定 `primary result`
- 指定模式执行时不回退到自动识别
- `secondary action` 由用户显式触发
- 无可用文本和读取失败必须明确提示
