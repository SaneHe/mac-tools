# Mac Text Actions 交互流程

## 1. 主流程
```mermaid
flowchart TD
    A["用户选中文本"] --> B["按下 global shortcut"]
    B --> C["优先读取 selected text"]
    C --> D{"读取成功?"}
    D -- "是" --> E["标记来源: selected text"]
    D -- "否" --> F["尝试 clipboard fallback"]
    F --> G{"剪贴板有可用文本?"}
    G -- "否" --> H["展示错误状态"]
    G -- "是" --> I["标记来源: clipboard fallback"]
    E --> J["识别内容类型"]
    I --> J
    J --> K{"类型"}
    K -- "合法 JSON" --> L["生成 primary result: 格式化 JSON"]
    K -- "时间戳" --> M["生成 primary result: 本地日期时间"]
    K -- "日期字符串" --> N["生成 primary result: 时间戳"]
    K -- "普通文本" --> O["展示 secondary action"]
    L --> P["展示 result panel"]
    M --> P
    N --> P
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
    S->>R: Request selected text
    R-->>S: Text or read failure
    alt selected text 可用
        S->>D: Detect type (source: selected text)
    else selected text 不可用
        S->>C: Read clipboard text
        C-->>S: Clipboard text or empty
        S->>D: Detect type (source: clipboard fallback)
    end
    D-->>S: DetectionResult
    S->>T: Build primary result
    T-->>App: TransformResult
    App->>P: Present result panel
```

## 3. 无选中文本流程
```mermaid
flowchart TD
    A["按下 global shortcut"] --> B["读取 selected text"]
    B --> C{"有选中文本?"}
    C -- "是" --> D["进入主流程，来源为 selected text"]
    C -- "否" --> E["读取剪贴板"]
    E --> F{"剪贴板有可用文本?"}
    F -- "是" --> G["进入主流程，来源为 clipboard fallback"]
    F -- "否" --> H["result panel 显示: 未检测到可处理文本"]
```

## 4. 当前应用不支持选区读取
```mermaid
flowchart TD
    A["按下 global shortcut"] --> B["Selection Reader 尝试读取"]
    B --> C{"支持读取?"}
    C -- "是" --> D["进入识别流程，来源为 selected text"]
    C -- "否" --> E["读取剪贴板"]
    E --> F{"剪贴板有可用文本?"}
    F -- "是" --> G["进入识别流程，并显示: 已改用剪贴板内容"]
    F -- "否" --> H["result panel 显示: 当前应用暂不支持读取选中文本"]
```

## 5. 非法 JSON 流程
```mermaid
flowchart TD
    A["识别输入为 JSON 候选"] --> B["执行 JSON 解析"]
    B --> C{"解析成功?"}
    C -- "否" --> D["result panel 显示: JSON 校验失败 + 错误说明"]
    C -- "是" --> E["渲染格式化 JSON"]
```

## 6. 二级动作流程
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

## 7. 交互规则总结
- `global shortcut` 是唯一主入口
- 主流程优先读取 `selected text`
- 仅在读取失败时才允许 `clipboard fallback`
- 发生 `clipboard fallback` 时必须明确标注来源
- 自动识别只决定 `primary result`
- `secondary action` 由用户显式触发
- 无可用文本和读取失败必须明确提示
