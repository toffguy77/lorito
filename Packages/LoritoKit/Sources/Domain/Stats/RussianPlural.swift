/// Russian plural forms for counts shown in the UI.
public enum RussianPlural {
    /// Pick the form for `n`: one (1, 21…), few (2–4, 22–24…), many (0, 5–20…).
    public static func form(_ n: Int, one: String, few: String, many: String) -> String {
        let mod100 = abs(n) % 100, mod10 = abs(n) % 10
        if (11...14).contains(mod100) { return many }
        if mod10 == 1 { return one }
        if (2...4).contains(mod10) { return few }
        return many
    }

    /// "1 день", "3 дня", "8 дней".
    public static func days(_ n: Int) -> String {
        "\(n) \(form(n, one: "день", few: "дня", many: "дней"))"
    }
}
