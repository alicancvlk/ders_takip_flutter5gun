import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PaymentSimulationPage extends StatefulWidget {
  const PaymentSimulationPage({super.key});

  @override
  State<PaymentSimulationPage> createState() => _PaymentSimulationPageState();
}

class _PaymentSimulationPageState extends State<PaymentSimulationPage> {
  late final WebViewController _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF5F7FB))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (progress == 100 && mounted) {
              setState(() => _loading = false);
            }
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            setState(() {
              _error = error.description;
              _loading = false;
            });
          },
        ),
      )
      ..loadHtmlString(_paymentDemoHtml);
  }

  Future<void> _reload() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _controller.loadHtmlString(_paymentDemoHtml);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ödeme simülasyonu',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Uygulama içi tarayıcı · HTML + JavaScript',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF737D90),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Sayfayı yenile',
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E8),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Color(0xFF80601C),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Gerçek ödeme yapılmaz. Gerçek kart bilgisi girmeyin.',
                        style: TextStyle(
                          color: Color(0xFF80601C),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (_error == null)
                        WebViewWidget(controller: _controller)
                      else
                        _WebViewError(message: _error!, onRetry: _reload),
                      if (_loading)
                        const Align(
                          alignment: Alignment.topCenter,
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WebViewError extends StatelessWidget {
  const _WebViewError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 40),
          const SizedBox(height: 12),
          const Text('Simülasyon sayfası açılamadı.'),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Yeniden dene'),
          ),
        ],
      ),
    ),
  );
}

const _paymentDemoHtml = r'''<!doctype html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
  <meta name="color-scheme" content="light">
  <title>Ödeme Simülasyonu</title>
  <style>
    :root { color-scheme: light; --ink:#172033; --muted:#758097; --blue:#3157d5; --line:#e7ebf2; }
    * { box-sizing:border-box; }
    body { margin:0; padding:16px; background:#f5f7fb; color:var(--ink); font:15px/1.45 system-ui,-apple-system,"Segoe UI",sans-serif; }
    .shell { max-width:560px; margin:0 auto; }
    .eyebrow { color:#5268ad; font-size:11px; font-weight:800; letter-spacing:1.4px; }
    h1 { margin:7px 0 4px; font-size:25px; letter-spacing:-.6px; }
    .lead { margin:0 0 16px; color:var(--muted); font-size:13px; }
    .amount { display:flex; align-items:center; justify-content:space-between; padding:16px; margin-bottom:14px; border:1px solid var(--line); border-radius:18px; background:#fff; }
    .amount small { display:block; color:var(--muted); font-size:12px; }
    .amount strong { font-size:21px; }
    .badge { padding:6px 9px; border-radius:20px; color:#3157d5; background:#edf1ff; font-size:11px; font-weight:800; }
    .panel { padding:17px; border:1px solid var(--line); border-radius:20px; background:#fff; box-shadow:0 8px 26px #25304a0a; }
    label { display:block; margin:0 0 6px; color:#424e65; font-size:12px; font-weight:700; }
    input { width:100%; height:47px; margin:0 0 13px; padding:0 12px; border:1px solid #dce2ec; border-radius:12px; outline:none; background:#fff; color:var(--ink); font:inherit; font-size:14px; }
    input:focus { border-color:var(--blue); box-shadow:0 0 0 3px #3157d51a; }
    .row { display:grid; grid-template-columns:1fr 1fr; gap:12px; }
    .card-number { letter-spacing:1.3px; }
    .helper { margin:-4px 0 14px; color:#7b8496; font-size:11px; }
    button { width:100%; min-height:49px; border:0; border-radius:14px; background:var(--blue); color:#fff; font-size:15px; font-weight:800; }
    button:active { transform:scale(.99); }
    .secure { margin:12px 0 0; color:#8a93a3; text-align:center; font-size:11px; }
    .result { display:none; margin-top:14px; padding:14px; border-radius:14px; font-size:13px; }
    .result.ok { display:block; color:#086849; background:#e9f8f1; }
    .result.fail { display:block; color:#a53838; background:#fff0ef; }
    .result strong { display:block; margin-bottom:3px; font-size:14px; }
    .foot { margin:13px 4px 0; color:#8791a2; font-size:11px; text-align:center; }
    @media (max-width:360px) { body { padding:12px; } .panel { padding:14px; } }
  </style>
</head>
<body>
  <main class="shell">
    <div class="eyebrow">DERS DEFTERİ · TEST ORTAMI</div>
    <h1>Ödeme al</h1>
    <p class="lead">Bu form HTML ve JavaScript ile yerel olarak çalışır.</p>

    <section class="amount" aria-label="Ödeme tutarı">
      <div><small>Matematik dersi</small><strong>₺ 750,00</strong></div>
      <span class="badge">SİMÜLASYON</span>
    </section>

    <form id="paymentForm" class="panel" autocomplete="off" novalidate>
      <label for="holder">Kart üzerindeki isim</label>
      <input id="holder" name="holder" type="text" maxlength="60" placeholder="ÖRNEK ÖĞRENCİ" autocomplete="off">

      <label for="cardNumber">Deneme kart numarası</label>
      <input id="cardNumber" class="card-number" name="cardNumber" type="text" inputmode="numeric" maxlength="23" placeholder="4242 4242 4242 4242" autocomplete="off">
      <p class="helper">Örnek başarılı kart: 4242 4242 4242 4242</p>

      <div class="row">
        <div>
          <label for="expiry">Son kullanma tarihi</label>
          <input id="expiry" name="expiry" type="text" inputmode="numeric" maxlength="5" placeholder="12/30" autocomplete="off">
        </div>
        <div>
          <label for="cvc">Güvenlik kodu</label>
          <input id="cvc" name="cvc" type="password" inputmode="numeric" maxlength="4" placeholder="123" autocomplete="off">
        </div>
      </div>

      <button id="payButton" type="submit">₺ 750,00 simüle et</button>
      <div id="result" class="result" role="status" aria-live="polite"></div>
      <p class="secure">Demo verileri gönderilmez ve kaydedilmez.</p>
    </form>
    <p class="foot">Gerçek banka bağlantısı yok · Gerçek kart bilgisi kullanmayın</p>
  </main>

  <script>
    const form = document.getElementById('paymentForm');
    const cardInput = document.getElementById('cardNumber');
    const expiryInput = document.getElementById('expiry');
    const cvcInput = document.getElementById('cvc');
    const result = document.getElementById('result');
    const button = document.getElementById('payButton');

    cardInput.addEventListener('input', () => {
      const digits = cardInput.value.replace(/\D/g, '').slice(0, 16);
      cardInput.value = digits.replace(/(.{4})/g, '$1 ').trim();
    });
    expiryInput.addEventListener('input', () => {
      const digits = expiryInput.value.replace(/\D/g, '').slice(0, 4);
      expiryInput.value = digits.length > 2 ? digits.slice(0, 2) + '/' + digits.slice(2) : digits;
    });
    cvcInput.addEventListener('input', () => {
      cvcInput.value = cvcInput.value.replace(/\D/g, '').slice(0, 4);
    });

    function luhnIsValid(number) {
      let sum = 0;
      let doubleDigit = false;
      for (let i = number.length - 1; i >= 0; i--) {
        let digit = Number(number[i]);
        if (doubleDigit) {
          digit *= 2;
          if (digit > 9) digit -= 9;
        }
        sum += digit;
        doubleDigit = !doubleDigit;
      }
      return sum % 10 === 0;
    }

    function expiryIsValid(value) {
      if (!/^\d{2}\/\d{2}$/.test(value)) return false;
      const [month, shortYear] = value.split('/').map(Number);
      if (month < 1 || month > 12) return false;
      const year = 2000 + shortYear;
      const now = new Date();
      return year > now.getFullYear() ||
        (year === now.getFullYear() && month >= now.getMonth() + 1);
    }

    function showResult(isSuccess, title, detail) {
      result.className = 'result ' + (isSuccess ? 'ok' : 'fail');
      result.innerHTML = '<strong>' + title + '</strong>' + detail;
    }

    form.addEventListener('submit', (event) => {
      event.preventDefault();
      result.className = 'result';

      const holder = document.getElementById('holder').value.trim();
      const number = cardInput.value.replace(/\D/g, '');
      const expiry = expiryInput.value.trim();
      const cvc = cvcInput.value.trim();
      let message = '';

      if (holder.length < 2) message = 'Kart üzerindeki ismi girin.';
      else if (number.length < 12 || number.length > 19 || !luhnIsValid(number)) message = 'Deneme kart numarası geçerli görünmüyor.';
      else if (!expiryIsValid(expiry)) message = 'Son kullanma tarihi geçerli değil.';
      else if (!/^\d{3,4}$/.test(cvc)) message = 'Güvenlik kodu 3 veya 4 rakam olmalı.';

      if (message) {
        showResult(false, 'Bilgileri kontrol edin', message);
        return;
      }

      button.disabled = true;
      button.textContent = 'Simülasyon yapılıyor…';
      window.setTimeout(() => {
        const declined = number.endsWith('0002');
        const reference = 'DEMO-' + Math.random().toString(36).slice(2, 8).toUpperCase();
        if (declined) {
          showResult(false, 'Simüle edilen ret', 'İşlem tamamlanmadı. Referans: ' + reference);
        } else {
          showResult(true, 'Simülasyon başarılı', '₺ 750,00 için demo makbuzu: ' + reference + '. Gerçek ödeme alınmadı.');
        }
        form.reset();
        button.disabled = false;
        button.textContent = '₺ 750,00 simüle et';
      }, 850);
    });
  </script>
</body>
</html>''';
