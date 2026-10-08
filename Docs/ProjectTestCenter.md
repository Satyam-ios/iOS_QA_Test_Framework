# ProjectTestCenter Documentation

`ProjectTestCenter` is the command-line orchestrator and developer quality gate CLI for the engineering ecosystem.

---

## 1. Capabilities & Workflow

* **Analyze:** Scans codebase architecture, identifies targets, features, services, and reports architectural health.
* **Gate:** Evaluates test execution telemetry against strict release criteria:
  * 0 Critical / High defects.
  * 100% test pass rate for required suites.
  * 0 unresolved security concerns.
  * Returns process exit code `0` on `RELEASE READY` and exit code `1` on `RELEASE BLOCKED`.

---

## 2. CLI Usage

### Running Discovery & Health Analysis
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run ProjectTestCenter analyze
```

### Running Release Quality Gate
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcrun swift run ProjectTestCenter gate
```

---

## 3. CI/CD Integration Example

In GitHub Actions or Xcode Cloud workflows:

```yaml
name: Quality Gate & Test Matrix

jobs:
  validate:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Select Xcode
        run: sudo xcode-select -s /Applications/Xcode.app
      - name: Run Test Suite
        run: swift test
      - name: Enforce Release Quality Gate
        run: swift run ProjectTestCenter gate
```
