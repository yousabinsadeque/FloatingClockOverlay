using System.Globalization;

namespace FloatingClockOverlay;

public static class Strings
{
    private static readonly Dictionary<string, Dictionary<string, string>> Table = new()
    {
        ["es"] = new()
        {
            ["Show/Hide"] = "Mostrar/Ocultar",
            ["Click-Through (Ctrl+Alt+C)"] = "Clic a través (Ctrl+Alt+C)",
            ["24-hour"] = "24 horas",
            ["Show Seconds"] = "Mostrar segundos",
            ["Show Day of Week"] = "Mostrar día de la semana",
            ["Adaptive Color"] = "Color adaptativo",
            ["Clock Language"] = "Idioma del reloj",
            ["System Default"] = "Predeterminado del sistema",
            ["Reset Position"] = "Restablecer posición",
            ["Quit"] = "Salir",
        },
        ["ar"] = new()
        {
            ["Show/Hide"] = "إظهار/إخفاء",
            ["Click-Through (Ctrl+Alt+C)"] = "النقر عبر (Ctrl+Alt+C)",
            ["24-hour"] = "24 ساعة",
            ["Show Seconds"] = "إظهار الثواني",
            ["Show Day of Week"] = "إظهار يوم الأسبوع",
            ["Adaptive Color"] = "لون تكيفي",
            ["Clock Language"] = "لغة الساعة",
            ["System Default"] = "افتراضي النظام",
            ["Reset Position"] = "إعادة تعيين الموضع",
            ["Quit"] = "إنهاء",
        },
        ["hi"] = new()
        {
            ["Show/Hide"] = "दिखाएं/छुपाएं",
            ["Click-Through (Ctrl+Alt+C)"] = "क्लिक-थ्रू (Ctrl+Alt+C)",
            ["24-hour"] = "24 घंटे",
            ["Show Seconds"] = "सेकंड दिखाएं",
            ["Show Day of Week"] = "सप्ताह का दिन दिखाएं",
            ["Adaptive Color"] = "अनुकूली रंग",
            ["Clock Language"] = "घड़ी की भाषा",
            ["System Default"] = "सिस्टम डिफ़ॉल्ट",
            ["Reset Position"] = "स्थिति रीसेट करें",
            ["Quit"] = "बंद करें",
        },
    };

    public static string T(string key)
    {
        var lang = CultureInfo.CurrentUICulture.TwoLetterISOLanguageName;
        return Table.TryGetValue(lang, out var d) && d.TryGetValue(key, out var v) ? v : key;
    }
}
