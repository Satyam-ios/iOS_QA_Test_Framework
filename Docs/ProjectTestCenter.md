# ProjectTestCenter Documentation

`ProjectTestCenter` is the command-line orchestrator, automated discovery engine, and developer quality gate CLI for the iOS engineering ecosystem.

---

## 1. Capabilities & Supported Commands

`ProjectTestCenter` provides a streamlined command-line interface for local developers and CI/CD pipelines:

| Command | Action | Output / Behavior |
| :--- | :--- | :--- |
| **`quality`** (Default) | **Master Quality Pipeline** | Runs `analyze` → `discover` → `generate` → `test` → `regression` → `report` → `gate` in one step. |
| **`analyze`** | Architecture & Health Scan | Verifies module decoupling, Swift 6 strict concurrency, and environment health. |
| **`discover`** | Screen & Journey Discovery | Lists all reachable screens, UI element counts, APIs, and multi-step user workflows. |
| **`generate`** | Automated Test Generation | Synthesizes functional, UI, platform, and journey test scenarios from discovered screens. |
| **`test`** | Journey Execution | Executes all end-to-end user navigation journeys step-by-step. |
| **`regression`** | Defect Learning Catalog | Executes the learned defect regression catalog to guarantee past bugs never recur. |
| **`report`** | QA Handoff Report | Generates detailed report with passed tests, not-executed hardware tests, and QA focus areas. |
| **`gate`** | Release Quality Gate | Evaluates 12 quality criteria. Exits with `0` on `RELEASE READY` or `1` on `RELEASE BLOCKED`. |

---

## 2. Developer CLI Usage

### A. Run Master Quality Pipeline (Single Combined Command)
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run ProjectTestCenter quality
```

### B. Discover Screens & User Journeys
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run ProjectTestCenter discover
```

### C. Synthesize Automated Test Cases
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run ProjectTestCenter generate
```

### D. Execute Defect Regression Catalog
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run ProjectTestCenter regression
```

### E. Enforce Release Quality Gate
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run ProjectTestCenter gate
```

---

## 3. CI/CD Integration (GitHub Actions / Xcode Cloud)

```yaml
name: Automated QA & Quality Gate

jobs:
  validate:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode Toolchain
        run: sudo xcode-select -s /Applications/Xcode.app
      - name: Run Test Suites
        run: swift test
      - name: Enforce Release Quality Gate
        run: swift run ProjectTestCenter quality
```
