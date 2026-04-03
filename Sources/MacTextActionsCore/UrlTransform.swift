import Foundation

/// URL 编码解码转换工具
public enum UrlTransform {
    /// 对输入字符串进行 URL query 组件百分号编码
    public static func encode(_ input: String) -> String? {
        input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    }

    /// 移除输入字符串中的百分号编码，还原为普通文本
    public static func decode(_ input: String) -> String? {
        input.removingPercentEncoding
    }
}
