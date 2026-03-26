# Mac Text Actions 交互流程

## 1. 主流程
```mermaid
flowchart TD
    A["用户选中文本"] --> B["按下 global shortcut"]
    B --> C["读取 selected text"]
    C --> D{"读取成功?"}
    D -- "否" --> E["展示错误状态"]
    D -- "是" --> F["识别内容类型"]
    F --> G{"类型"}
    G -- "合法 JSON" --> H["生成 primary result: 格式化 JSON"]
    G -- "时间戳" --> I["生成 primary result: 本地日期时间"]
    G -- "日期字符串" --> J["生成 primary result: 时间戳"]
    G -- "普通文本" --> K["展示 secondary action"]
    H --> L["展示 result panel"]
    I --> L
    J --> L
    K --> L
    L --> M["用户复制结果 / 替换原文 / 执行 secondary action / 关闭"]
```

## 2. 快捷键到结果面板时序
```mermaid
sequenceDiagram
    participant U as User
    participant App as App Shell
    participant S as Shortcut Manager
    participant R as Selection Reader
    participant D as Detection Engine
    participant T as Transform Engine
    participant P as Result Panel

    U->>S: Press global shortcut
    S->>R: Request selected text
    R-->>S: Text or error
    S->>D: Detect type
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
    C -- "否" --> D["result panel 显示: 未检测到选中文本"]
    C -- "是" --> E["进入主流程"]
```

## 4. 当前应用不支持选区读取
```mermaid
flowchart TD
    A["按下 global shortcut"] --> B["Selection Reader 尝试读取"]
    B --> C{"支持读取?"}
    C -- "否" --> D["result panel 显示: 当前应用暂不支持读取选中文本"]
    C -- "是" --> E["进入识别流程"]
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
- 自动识别只决定 `primary result`
- `secondary action` 由用户显式触发
- 无选中文本和读取失败必须明确提示
- 不做剪贴板回退
