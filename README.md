# Platform Channel Lab

Flutter ile Android Kotlin kodunu `MethodChannel` ve `EventChannel` kullanarak konuşturan öğretici örnek.

## Örnek akışı

- `lib/main.dart`: Material 3 arayüzü, MethodChannel çağrıları ve EventChannel stream aboneliği.
- `lib/features/hardware_info/`: Donanım bilgisi modeli, platform repository'si ve ayrı Donanım sayfası.
- `lib/features/payment_simulation/`: `webview_flutter` ile uygulama içinde açılan ödeme simülasyonu.
- `android/app/src/main/kotlin/com/example/platform_channel/MainActivity.kt`: Bluetooth durumunu, Android ID'yi ve erişim varsa IMEI'yi sağlayan Kotlin tarafı.
- Donanım ekranı: üretici/model, Android sürümü/API, desteklenen işlemci mimarileri, çekirdek sayısı, RAM, ekran ölçüleri ve cihazın sunduğu donanım yetenekleri.
- `MethodChannel`: Flutter'dan Kotlin'e Bluetooth durumunu sorgulama, izin isteme, ayar ekranını açma ve cihaz bilgilerini alma çağrıları.
- `EventChannel`: Android Bluetooth yayınını Dart tarafına stream olarak iletme.
- Ödeme demo: yerel HTML formu ve JavaScript doğrulaması; gerçek banka/ödeme servisine bağlantı yoktur. Kart numarası ile güvenlik kodu gönderilmez ve kaydedilmez.

## Çalıştırma

Android Studio'da bu klasörü açın. Flutter SDK yolunun tanımlı olduğundan emin olun. Terminalden:

```bash
flutter pub get
flutter devices
flutter run -d <emulator-id>
```

Windows'ta proje ve varsayılan Pub önbelleği farklı sürücülerdeyse (bu projede proje `D:`, varsayılan önbellek `C:`), Android Kotlin derleyicisi eklenti kaynak yollarını işlerken sürücü kökü hatası verebilir. PowerShell terminalinde paketleri proje yanındaki önbelleğe çözün:

```powershell
$env:PUB_CACHE = "$PWD\.pub-cache"
flutter pub get
flutter run -d emulator-5554
```

Bu klasör `.gitignore` içindedir; paket önbelleği projeye commit edilmez.

Android 12 ve üzeri cihazlarda uygulama `BLUETOOTH_CONNECT` çalışma zamanı iznini ister. Android 9 ve öncesinde IMEI sorgulaması için `READ_PHONE_STATE` izni istenir. Bluetooth'u açıp kapatmak için Android'in sistem Bluetooth ayarları açılır; durum değişikliği ekrana EventChannel ile düşer.

Alt menüdeki **Ödeme Demo** sayfasında örnek başarılı kart olarak `4242 4242 4242 4242`, son kullanma tarihi olarak `12/30`, güvenlik kodu olarak `123` kullanılabilir. Simüle edilen ret akışını görmek için `4000 0000 0000 0002` numarasını deneyebilirsiniz. Bunlar yalnızca yerel demo değerleridir; gerçek kart bilgisi girmeyin.

## IMEI notu

Uygulama IMEI'yi Android'in `TelephonyManager` API'sinden okumayı dener ve erişimi reddedilirse bunu ekranda açıkça belirtir. Android 10 ve üzeri IMEI'yi sıradan uygulamalara kapatır; bu erişim yalnızca önceden yüklenmiş/ayrıcalıklı uygulama, cihaz yöneticisi veya operatör ayrıcalığı gibi koşullarda mümkündür. Emulator'da telefon modülü olmayabilir. Android ID ayrı ve daha sınırlı kapsamlı bir tanımlayıcı olarak gösterilir.

## Öğrenme noktaları

1. Dart ve Kotlin tarafında aynı channel adını kullanmak.
2. MethodChannel sonuçlarını ve platform hatalarını yönetmek.
3. EventChannel'i Dart `Stream` olarak dinlemek.
4. Android runtime permission isteğini Kotlin'den sonuçlandırmak.
5. Android'e özel kodun Flutter arayüzünden ayrılması.