<!DOCTYPE html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}"
      dir="{{ in_array(app()->getLocale(), ['ar', 'fa', 'he', 'ur']) ? 'rtl' : 'ltr' }}"
      data-theme="b5hunt">
    <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>{{ config('app.name') }} — منصة الذكاء التكتيكي لـ EA FC</title>

        <link rel="preconnect" href="https://fonts.bunny.net">
        <link href="https://fonts.bunny.net/css?family=cairo:400,500,600,700,800&display=swap" rel="stylesheet" />

        @vite(['resources/css/app.css', 'resources/js/app.js'])
    </head>
    <body class="font-sans antialiased bg-base-200 text-base-content min-h-screen">

        {{-- Navbar --}}
        <div class="navbar bg-base-100/80 backdrop-blur border-b border-base-300 sticky top-0 z-50">
            <div class="container mx-auto px-4">
                <div class="flex-1">
                    <a class="text-2xl font-extrabold text-primary">b5hunt</a>
                    <span class="badge badge-secondary badge-sm mx-2 hidden sm:inline-flex">EA FC</span>
                </div>
                <div class="flex-none gap-2">
                    @auth
                        <a href="{{ url('/dashboard') }}" class="btn btn-primary btn-sm">لوحة التحكم</a>
                    @else
                        <a href="{{ route('login') }}" class="btn btn-ghost btn-sm">تسجيل الدخول</a>
                        <a href="{{ route('register') }}" class="btn btn-primary btn-sm">ابدأ مجاناً</a>
                    @endauth
                </div>
            </div>
        </div>

        {{-- Hero --}}
        <section class="container mx-auto px-4 py-20 text-center">
            <div class="badge badge-outline badge-lg mb-6 gap-2">
                <span class="inline-block w-2 h-2 rounded-full bg-success animate-pulse"></span>
                النطاق الجغرافي: الشرق الأوسط أولاً
            </div>
            <h1 class="text-4xl md:text-6xl font-extrabold leading-tight">
                منصة <span class="text-primary">الذكاء التكتيكي</span> المطلقة لـ EA FC
            </h1>
            <p class="mt-6 text-lg md:text-xl max-w-2xl mx-auto text-base-content/70">
                تحويل بيانات اللعبة المعقدة إلى انتصارات مؤكدة ورؤى قابلة للتنفيذ — حلول SBC جاهزة،
                تنبيهات سوق لحظية، وبناء تشكيلات بالذكاء الاصطناعي.
            </p>
            <div class="mt-10 flex items-center justify-center gap-3">
                <a href="{{ route('register') }}" class="btn btn-primary btn-lg">ابدأ الآن مجاناً</a>
                <a href="#tools" class="btn btn-outline btn-lg">استكشف الأدوات</a>
            </div>
        </section>

        {{-- Tools grid (the 7 tools) --}}
        <section id="tools" class="container mx-auto px-4 py-12">
            <h2 class="text-3xl font-bold text-center mb-2">بنية النظام البيئي</h2>
            <p class="text-center text-base-content/60 mb-10">أدوات تشكّل تفوقك التكتيكي</p>

            <div class="grid gap-5 sm:grid-cols-2 lg:grid-cols-3">
                @php
                    $tools = [
                        ['SBC Solver', 'أرخص تشكيلة تحقّق متطلبات التحدي في ثوانٍ.', '🧩'],
                        ['Squad Builder', 'بناء تشكيلات متكاملة بالتناغم (Chemistry).', '⚽'],
                        ['Market Alerts', 'إشعارات لحظية بارتفاع وانخفاض الأسعار.', '🔔'],
                        ['Pack Analytics', 'تحليل قيمة الباكات ونسبة الربح المتوقعة.', '📦'],
                        ['Price Tracker', 'تتبّع السعر الحالي وأعلى/أقل وتغيّرات السوق.', '📈'],
                        ['Evolutions Finder', 'مطابقة مثالية لأفضل اللاعبين للتطوير.', '⭐'],
                    ];
                @endphp

                @foreach ($tools as [$title, $desc, $icon])
                    <div class="card bg-base-100 border border-base-300 hover:border-primary/60 transition shadow-sm hover:shadow-lg">
                        <div class="card-body">
                            <div class="text-3xl">{{ $icon }}</div>
                            <h3 class="card-title text-primary">{{ $title }}</h3>
                            <p class="text-base-content/70">{{ $desc }}</p>
                        </div>
                    </div>
                @endforeach
            </div>
        </section>

        {{-- CTA --}}
        <section class="container mx-auto px-4 py-16">
            <div class="card bg-gradient-to-l from-secondary to-base-300 text-secondary-content">
                <div class="card-body items-center text-center">
                    <h2 class="card-title text-2xl">جاهز تسيطر على السوق؟</h2>
                    <p class="opacity-80">الخطة الأساسية مجانية — جرّب قاعدة بيانات اللاعبين والبحث الأساسي الآن.</p>
                    <a href="{{ route('register') }}" class="btn btn-primary mt-3">إنشاء حساب مجاني</a>
                </div>
            </div>
        </section>

        <footer class="footer footer-center p-8 text-base-content/60 border-t border-base-300">
            <aside>
                <p>© {{ date('Y') }} b5hunt — جميع الحقوق محفوظة.</p>
            </aside>
        </footer>
    </body>
</html>
