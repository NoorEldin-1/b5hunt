# b5hunt — منصة الذكاء التكتيكي لـ EA FC

منصة **ويب عربية أولاً (RTL)** للاعبي **EA FC Ultimate Team** — بتحوّل بيانات اللعبة المعقدة
(أسعار، تقييمات، احتمالات الباكات) إلى قرارات وتوصيات جاهزة: حلول SBC، تنبيهات سوق لحظية،
بناء تشكيلات بالذكاء الاصطناعي، وتحليل الباكات. النموذج: Freemium + اشتراكات Premium + B2B.

> خطة المشروع الكاملة والأدوات السبعة في [PLAN.md](PLAN.md).

## الـ Stack

| الطبقة | التقنية |
|---|---|
| Backend | **Laravel 12** (PHP 8.2+) |
| Database | **MySQL 8** |
| Cache / Queue / Session | **Redis** (predis محلياً، phpredis على السيرفر) |
| UI | **Livewire 3** · **Alpine** · **Tailwind 3** · **DaisyUI 4** · خط Cairo · RTL |
| Admin | **Filament 3** (`/admin`) |
| Real-time | **Laravel Reverb** + Echo (WebSockets) |
| Queues | **Laravel Horizon** |
| Auth | **Breeze** (Livewire) + تحقّق بريد + **spatie/permission** |
| Localization | عربي/إنجليزي (laravel-lang) |
| Quality | **Pest** · **Larastan** (level 5) · **Pint** |

> **مفيش APIs** عمومية حالياً — تطبيق monolith يُعرض من الخادم (server-rendered). الـ APIs مؤجّلة للـ Phase 2.

## التشغيل المحلي (Windows / XAMPP)

المتطلبات: PHP 8.2+، Composer، Node 20+، MySQL، Redis (Memurai على Windows).

```bash
composer install
cp .env.example .env
php artisan key:generate
# عدّل DB_* و REDIS_* في .env ثم:
php artisan migrate --seed     # ينشئ الأدوار + مستخدم أدمن
npm install && npm run build
```

التشغيل أثناء التطوير:

```bash
php artisan serve          # التطبيق
php artisan queue:work     # المهام (محلياً؛ على السيرفر Horizon)
php artisan reverb:start   # WebSockets
npm run dev                # Vite
```

**حساب الأدمن الافتراضي:** `admin@b5hunt.test` / `password` → لوحة الإدارة على `/admin`.

## النشر على السيرفر (SSH)

```bash
# أول مرة فقط على السيرفر:
git clone <repo-url> /home/b5hunt && cd /home/b5hunt
bash setup.sh        # تجهيز env + deps + migrate + caches + دليل الخدمات
#   ↑ بعدها عدّل .env (DB/Redis/Reverb/APP_URL) ثم أعد تشغيله

# كل إصدار بعد كده:
bash deploy.sh       # pull → composer → build → migrate → caches → restart workers
```

> اضبط document root في CyberPanel/OpenLiteSpeed على مجلد **`public/`**.
> الخدمات المطلوبة (systemd): `horizon` ، `reverb:start` ، و `schedule:run` في الـ crontab — التفاصيل داخل [setup.sh](setup.sh).
> لو مسار PHP مختلف على السيرفر: `PHP=/usr/local/lsws/lsphp82/bin/php bash deploy.sh`

## الاختبارات والجودة

```bash
php artisan test              # Pest (26 ✓)
./vendor/bin/pint             # تنسيق الكود
./vendor/bin/phpstan analyse  # تحليل ساكن (Larastan)
```
