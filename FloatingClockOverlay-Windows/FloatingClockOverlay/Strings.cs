using System.Globalization;

namespace FloatingClockOverlay;

public static class Strings
{
    private static readonly Dictionary<string, Dictionary<string, string>> Table = new()
    {
        ["es"] = new()
        {
            ["Check for Updates"] = "Buscar actualizaciones",
            ["Automatically Check for Updates"] = "Buscar actualizaciones automáticamente",
            ["Update available"] = "Actualización disponible",
            ["Version {0} is ready to install."] = "La versión {0} está lista para instalarse.",
            ["Skip This Version"] = "Omitir esta versión",
            ["Later"] = "Más tarde",
            ["Update Now"] = "Actualizar ahora",
            ["Downloading…"] = "Descargando…",
            ["Download failed."] = "La descarga falló.",
            ["Couldn't check for updates. Please try again later."] = "No se pudo buscar actualizaciones. Inténtalo más tarde.",
            ["You're up to date (v{0})."] = "Tienes la última versión (v{0}).",
            ["The download is damaged. Please try again."] = "La descarga está dañada. Inténtalo de nuevo.",
            ["Couldn't prepare the update."] = "No se pudo preparar la actualización.",
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
            ["Check for Updates"] = "التحقق من التحديثات",
            ["Automatically Check for Updates"] = "التحقق من التحديثات تلقائيًا",
            ["Update available"] = "يتوفر تحديث",
            ["Version {0} is ready to install."] = "الإصدار {0} جاهز للتثبيت.",
            ["Skip This Version"] = "تخطي هذا الإصدار",
            ["Later"] = "لاحقًا",
            ["Update Now"] = "التحديث الآن",
            ["Downloading…"] = "جارٍ التنزيل…",
            ["Download failed."] = "فشل التنزيل.",
            ["Couldn't check for updates. Please try again later."] = "تعذر التحقق من التحديثات. حاول مرة أخرى لاحقًا.",
            ["You're up to date (v{0})."] = "لديك أحدث إصدار (v{0}).",
            ["The download is damaged. Please try again."] = "التنزيل تالف. حاول مرة أخرى.",
            ["Couldn't prepare the update."] = "تعذر تجهيز التحديث.",
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
            ["Check for Updates"] = "अपडेट जांचें",
            ["Automatically Check for Updates"] = "अपडेट अपने-आप जांचें",
            ["Update available"] = "अपडेट उपलब्ध है",
            ["Version {0} is ready to install."] = "संस्करण {0} इंस्टॉल के लिए तैयार है।",
            ["Skip This Version"] = "यह संस्करण छोड़ें",
            ["Later"] = "बाद में",
            ["Update Now"] = "अभी अपडेट करें",
            ["Downloading…"] = "डाउनलोड हो रहा है…",
            ["Download failed."] = "डाउनलोड विफल रहा।",
            ["Couldn't check for updates. Please try again later."] = "अपडेट जांच नहीं हो सकी। बाद में फिर कोशिश करें।",
            ["You're up to date (v{0})."] = "आपके पास नवीनतम संस्करण है (v{0})।",
            ["The download is damaged. Please try again."] = "डाउनलोड खराब है। फिर से कोशिश करें।",
            ["Couldn't prepare the update."] = "अपडेट तैयार नहीं हो सका।",
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
