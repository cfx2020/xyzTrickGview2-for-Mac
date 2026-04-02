# Getting Started with XYZ Monitor macOS

完整的 macOS SwiftUI 应用已经为你准备好了。以下是快速启动方式。

## 项目结构

```
macos-app/
├── Package.swift              # Swift Package Manager 定义
├── XYZMonitor/
│   ├── Sources/               # 源代码
│   │   ├── XYZMonitorApp.swift       # App 入口
│   │   ├── AppDelegate.swift         # 菜单栏 + 事件处理
│   │   ├── Models.swift              # 数据模型
│   │   ├── ConverterService.swift    # XYZ↔GJF 转换
│   │   ├── ClipboardService.swift    # 剪贴板操作
│   │   ├── HotkeyService.swift       # 全局热键
│   │   ├── ConfigStore.swift         # 配置存储
│   │   ├── Logger.swift              # 日志
│   │   └── ConfigurationView.swift   # SwiftUI 界面
│   ├── Tests/                 # 测试
│   └── Resources/             # Info.plist 等
├── build.sh                   # 构建脚本
├── create-dmg.sh              # DMG 打包脚本
└── README.md                  # 详细文档
```

## 快速开始（3 种方式）

### 方式 1：用构建脚本（推荐）

```bash
cd macos-app
chmod +x build.sh
./build.sh release
```

产品在 `dist/XYZMonitor`。

### 方式 2：直接用 Swift

```bash
cd macos-app
swift build -c release
```

产品在 `.build/release/XYZMonitor`。

### 方式 3：用 Xcode

```bash
cd macos-app
open Package.swift  # 在 Xcode 中打开
# ⌘B 构建，⌘R 运行
```

## 创建 DMG（用于分发）

```bash
cd macos-app
chmod +x create-dmg.sh
./create-dmg.sh dist/XYZMonitor XYZMonitor.dmg
```

会生成 `XYZMonitor.dmg` 可在 macOS 间分发（目前未签名）。

## 首次启动

1. 运行 `./dist/XYZMonitor` 或在 Xcode 中点击 Run
2. 菜单栏右上角出现立方体图标 🟦
3. 点击图标 → Preferences
4. 配置：
   - **Viewer Application**: 指向你的分子查看器（如 `/Applications/GaussianView.app/Contents/MacOS/GaussianView`）
   - **Hotkeys**: 自定义快捷键（默认 ⌘⌥X 和 ⌘⌥G）

## 测试转换

### XYZ → 查看器

1. 复制一段 XYZ 坐标：
   ```
   3
   Water molecule
   O    0.000000    0.000000    0.119262
   H    0.000000    0.763239   -0.474648
   H    0.000000   -0.763239   -0.474648
   ```

2. 按快捷键 `⌘⌥X`
3. 查看器应该打开 .gjf 文件

### 反向转换 (查看器 → XYZ)

1. 按快捷键 `⌘⌥G`
2. 粘贴结构文本，点击 "Convert"
3. XYZ 格式应该在剪贴板中

## 常见问题

### "按快捷键没反应"
→ 系统偏好设置 → 安全性与隐私 → 辅助功能 → 允许 XYZ Monitor  
→ 重启应用

### "查看器没有打开"
→ 检查 Preferences 中的路径是否正确  
→ 查看日志：`~/Library/Application Support/XYZMonitor/xyz_monitor.log`

### "看不到菜单栏图标"
→ 检查应用是否还在运行  
→ 用 `Activity Monitor` 查看 XYZMonitor 进程

## 项目特色

✓ 完整的 SwiftUI 实现（无需第三方 GUI 库）  
✓ 纯文本配置，支持 UserDefaults 持久化  
✓ 模块化架构，易于扩展  
✓ 支持多种分子查看器（通过配置命令路径）  
✓ 温和的内存足迹（菜单栏常驻）  

## 下一步

1. **签名与公证**（可选，第 2 阶段）
   ```bash
   # 为分发做签名
   codesign -s - ./dist/XYZMonitor
   ```

2. **自动构建 DMG**（GitHub Actions）
   将 `ci/macos-dmg.yml.example` 复制到 `.github/workflows/macos-dmg.yml`

3. **测试覆盖**
   ```bash
   cd macos-app
   swift test
   ```

4. **添加更多分子格式支持**
   在 `ConverterService` 中扩展 `parseXyz()` 和 `generateGjf()` 方法

## 与 Windows 版本的关系

- ✓ 完全独立的代码库（不改动现有 Windows 代码）
- ✓ 功能对齐但实现方式不同（SwiftUI vs WinAPI）
- ✓ 可同步提 PR 到原仓库作为新的平台支持

## 示例：如何提交 PR

1. Fork 原仓库
2. 新建分支 `feature/macos-swiftui`
3. 复制整个 `macos-app/` 目录到你的仓库
4. 更新主 README 加入 macOS 部分
5. PR 标题：`Add native macOS app (SwiftUI) with feature-parity subset`
6. PR 描述参考 `../macos-swiftui-draft/PR_DRAFT.md`

---

有问题？查看 `../macos-swiftui-draft/IMPLEMENTATION_PLAN.md` 了解更多设计细节。
