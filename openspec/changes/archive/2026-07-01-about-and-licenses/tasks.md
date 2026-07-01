# Tasks

## 1. Picture-matching expansion (content)
- [x] 1.1 Add ~25 more OpenMoji everyday-vocabulary emojis (family, body, animals, food) to `content/exercise-assets/`, named by Spanish word
- [x] 1.2 Author 6 more `picture-matching` exercises on A1-30 (family, body, animals, fruit, food, mixed) — 14 total
- [x] 1.3 Run `tools/validate.py` (asset existence) and `tools/compile.py`

## 2. About / Licenses screen (Features)
- [x] 2.1 Define a `LicenseEntry` value type and a static credits list including OpenMoji (CC BY-SA 4.0) and MarkdownUI (MIT)
- [x] 2.2 Build `AboutView` rendering the list (name, license, detail, source) with DesignSystem tokens
- [x] 2.3 Wire a «О приложении» `NavigationLink` into `SettingsView`
- [x] 2.4 Add a Features test: the credits list is non-empty and includes OpenMoji

## 3. Verify
- [x] 3.1 Run `cd Packages/LoritoKit && swift test` (green)
- [x] 3.2 Build the app and confirm the About/Licenses screen opens from Settings on the simulator (screenshot)
- [x] 3.3 Run `openspec validate about-and-licenses --strict`
