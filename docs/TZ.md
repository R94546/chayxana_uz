# Texnik Topshiriq (TZ) — Choyxona.uz

> **Maqsad:** Loyihani **production-ready** holatga keltirish — barcha jiddiy buglar tuzatilgan,
> mantiq to'g'rilangan, dead code tozalangan, tarjimalar to'liq, 3 platformada (Web / iOS / Android) ishlaydigan.
>
> **Platformalar:** Web (test/demo), iOS (asosiy klientlar), Android (kerak).
> **Backend:** Mavjud Firebase loyihasi (Auth, Firestore, Storage, FCM, Cloud Functions).
> **Rollar:** `choyxona_admin` va `choyxona_owner` **birlashtiriladi** → bitta "choyxona egasi" roli.

Hujjat sanasi: 2026-06-20. Branch: `claude/jolly-gauss-icfon0`.

---

## 1. Loyiha haqida

Choyxona.uz — O'zbekistondagi an'anaviy choyxona-restoranlarni bron qilish va boshqarish tizimi.

| Qatlam | Texnologiya |
|---|---|
| Frontend | Flutter (Dart), Provider state management |
| Backend | Firebase: Authentication, Cloud Firestore, Storage, Cloud Functions (TypeScript), FCM |
| Lokalizatsiya | `easy_localization` — uz / ru / en |
| Hajm | ~39 000 qator Dart, ~80+ ekran/widget |

**Rollar (yangi, birlashtirilgan model):**
- `client` — oddiy mijoz (bron qiladi, menyu ko'radi, sharh yozadi)
- `choyxona_owner` — choyxona egasi (to'liq boshqaruv: menyu, stollar, bronlar, analitika)
- `superadmin` — platforma administratori (CRM, barcha choyxonalar, egalarni tayinlash)

---

## 2. Aniqlangan muammolar ro'yxati

### 🔴 P0 — Bloker / xavfsizlik / asosiy mantiq

| # | Muammo | Joy | Ta'sir |
|---|---|---|---|
| P0-1 | **Rol nomi nomuvofiqligi.** Ilova `choyxona_owner` ishlatadi, `firestore.rules` esa `hasRole('owner')` tekshiradi. `isChoyxonaOwner()` hech qachon `true` bermaydi. | `firestore.rules`, `user_model.dart` | Owner choyxona/menyu yarata olmasligi, ruxsat buzilishi |
| P0-2 | **Bron bandligi tekshirilmaydi.** `createBooking()` ichida `checkAvailability()` chaqirilmaydi; dublikat/haddan ortiq bron mumkin. `checkAvailability` qo'pol (`< 10`, sig'im hisobga olinmagan). | `booking_service.dart` | Bir vaqtga bir necha bron, biznes-mantiq buzilishi |
| P0-3 | **Email verification yuboriladi, lekin hech qachon tekshirilmaydi.** | `auth_service.dart` | Tasdiqlanmagan akkauntlar to'liq ishlaydi (feature ma'nosiz) |
| P0-4 | **Startupda har safar `_fixAdminChoyxonaId()` ishlaydi** — `admin@gmail.com` ni Firestore'dan qidiradigan bir martalik migration hack. | `main.dart` | Ishga tushish sekinlashishi, keraksiz Firestore o'qish |
| P0-5 | **Firestore qoidalarida `client/user/owner` rollari**, ilovada `choyxona_owner/choyxona_admin`. `users` create rule `role in ['client','user','owner']` — `choyxona_owner` ni rad etadi. | `firestore.rules` | Ro'yxatdan o'tish/rol o'rnatishda xatolik |

### 🟠 P1 — Arxitektura / barqarorlik

| # | Muammo | Joy |
|---|---|---|
| P1-1 | **`AuthProvider` umuman ishlatilmaydi (dead code).** Auth holati har joyda `AuthService()` ni qayta yaratib, Firestore'dan qayta o'qish bilan boshqariladi — sekin, nomuvofiq, navigatsiyada takror so'rovlar. | `auth_provider.dart` + butun loyiha |
| P1-2 | **`DataSyncProvider` da `bookings`/`users` listenerlari o'chirilgan.** Bog'liq metodlar (`getBookingsForDate`, `getBookedSlotsCount`) doim bo'sh qaytaradi — o'lik. | `data_sync_provider.dart` |
| P1-3 | **Rol birlashtirish kerak** — `choyxona_admin` ↔ `choyxona_owner` farqi noaniq, ~8 faylda ishlatiladi. | `user_model.dart`, `role_based_navigator.dart`, `assign_admin_screen.dart`, `all_users_screen.dart`, `booking_screen.dart`, `menu_order_screen.dart`, `login_screen.dart`, `splash_screen.dart` |
| P1-4 | **Xatoliklarni yutib yuborish** — ko'p `catch` bloklari `return false`/`return []` bilan jim qoladi; foydalanuvchiga/logga chiqmaydi. | services/* |

### 🟡 P2 — Sifat / tozalik

| # | Muammo | Joy |
|---|---|---|
| P2-1 | **Dead/keraksiz fayllar:** `*.backup`, `order_model.dart.template`, `lib/fix_choyxona_id.dart`, ishlatilmaydigan `OwnerDashboard`. | `lib/` |
| P2-2 | **86 ta `print()`** — release'da ham chiqadi. `debugPrint`/markazlashgan logger kerak. | butun loyiha |
| P2-3 | **8 ta amalga oshirilmagan TODO:** geopoisk, masofa hisoblash, QR yuklash, share. | services + screens |
| P2-4 | **Tarjimalar to'liq emas:** ru≈610, uz≈551, en≈541 kalit — yuzlab kalit yetishmaydi. Fallback `ru` (asosiy auditoriya uz bo'lsa ham). | `assets/translations/*.json` |
| P2-5 | **`pubspec.yaml` metama'lumotlari:** `description: "A new Flutter project."`, versiya boshlang'ich. | `pubspec.yaml` |
| P2-6 | **`firebase_options.dart` repoda**, ammo `google-services.json`/`plist` gitignore'da — nomuvofiq config strategiyasi. | repo |

---

## 3. Maqsadli arxitektura (to'g'ri ko'rinishi)

### 3.1 Rollar (birlashtirilgan)
- `choyxona_admin` butunlay olib tashlanadi. Mavjud `choyxona_admin` foydalanuvchilar `choyxona_owner` ga migratsiya qilinadi (skript/Cloud Function bilan).
- `UserModel` da: `isChoyxonaOwner` saqlanadi, `isChoyxonaAdmin`/`isViewOnly` olib tashlanadi yoki `isChoyxonaOwner` ga yo'naltiriladi.
- `firestore.rules`: yagona `canManageChoyxona(choyxonaId)` — `ownerId == uid || isAdmin()`. Rol stringlar **ilova bilan bir xil**: `client`, `choyxona_owner`, `superadmin`.

### 3.2 State management
- `AuthProvider` ni `MultiProvider` ga ulash; navigatsiya va ekranlar `AuthService()` ni qayta yaratish o'rniga `context.read/watch<AuthProvider>()` dan foydalanadi.
- Auth holati bitta joyda (provider) kesh qilinadi; rol asosida navigatsiya provider orqali.

### 3.3 Booking mantiqi
- `createBooking()` transaction ichida: sig'im/slot bandligini tekshirib, atomik yozish (double-booking yo'q).
- Sig'im manbai: choyxona/stol sig'imi (`tables`/`rooms` yoki `choyxona.capacity`).

### 3.4 Konfiguratsiya
- Firebase config strategiyasi bitta xil: yoki barchasi repoda (private repo), yoki barchasi gitignore + `README` da sozlash yo'riqnomasi. (Mavjud loyiha bor — `flutterfire configure` orqali qayta generatsiya tavsiya etiladi.)

---

## 4. Ish bosqichlari (rejalashtirilgan tartib)

### Faza 0 — Tayyorgarlik va baseline
- [ ] Flutter SDK o'rnatish/aniqlash, `flutter pub get`.
- [ ] `flutter analyze` ni ishga tushirib, **haqiqiy kompilyatsiya/lint xatolar ro'yxatini** olish (statik o'qishda ko'rinmaganlari).
- [ ] Baseline build (web) — hozir umuman quriladimi?

### Faza 1 — P0 buglar (asosiy mantiq + xavfsizlik)
- [ ] P0-1 / P0-5: `firestore.rules` ni ilova rollari bilan moslashtirish (`choyxona_owner`, `superadmin`, `client`).
- [ ] P0-4: `_fixAdminChoyxonaId()` ni `main.dart` dan olib tashlash; `lib/fix_choyxona_id.dart` ni o'chirish.
- [ ] P0-2: `createBooking()` ga transaction + bandlik/sig'im tekshiruvi.
- [ ] P0-3: Login'da `emailVerified` tekshiruvi (yoki feature'ni ongli ravishda o'chirish — qaror TZ ilovasida).

### Faza 2 — Rollarni birlashtirish (P1-3)
- [ ] `choyxona_admin` → `choyxona_owner` ga kod bo'ylab migratsiya (~8 fayl).
- [ ] Mavjud foydalanuvchilar uchun Firestore migration (Cloud Function yoki bir martalik admin skript).
- [ ] `assign_admin_screen` / `all_users_screen` ni yangi modelga moslashtirish.
- [ ] Eskirgan `ChoyxonaAdminDashboard` vs `OwnerDashboard` ni yagona dashboardga keltirish (dead `OwnerDashboard` ni olib tashlash).

### Faza 3 — State management tozalash (P1-1, P1-2, P1-4)
- [ ] `AuthProvider` ni ulash va ekranlarni unga o'tkazish.
- [ ] `DataSyncProvider` ni qayta ko'rib chiqish — yo listenerlarni to'g'ri ruxsatlar bilan yoqish, yoki o'lik metodlarni olib tashlash.
- [ ] Xatoliklarni markazlashgan handler orqali ko'rsatish/loglash.

### Faza 4 — Sifat va tozalik (P2)
- [ ] Dead/keraksiz fayllarni o'chirish (`*.backup`, `*.template`, ishlatilmaydigan ekranlar).
- [ ] `print()` → `debugPrint`/logger.
- [ ] TODO'larni yopish (geopoisk, masofa, QR yuklash, share) yoki ongli kechiktirish.
- [ ] Tarjimalarni 3 tilda **to'liq tenglashtirish** (kalitlarni sinxronlash, yetishmaganini to'ldirish). Asosiy til bo'yicha fallback qarori.
- [ ] `pubspec.yaml` metama'lumotlari, app nomi, versiya.

### Faza 5 — Platforma va build
- [ ] Web build + sozlash (`vercel.json` mavjud).
- [ ] Android build (signing, `min_sdk 21`, ruxsatlar manifesti).
- [ ] iOS build (Info.plist ruxsatlari: lokatsiya, kamera, bildirishnoma).
- [ ] Har platformada smoke-test.

### Faza 6 — Test va qabul
- [ ] Asosiy oqimlar bo'yicha qo'lda/avtomatik smoke-testlar.
- [ ] Acceptance criteria (5-bo'lim) bo'yicha tekshirish.

---

## 5. "100% ishlash" — Qabul mezonlari (Acceptance Criteria)

Quyidagilarning **har biri** xatosiz ishlashi kerak (Web + Android + iOS):

1. **Auth:** ro'yxatdan o'tish → (email verification qarori) → login → rol bo'yicha to'g'ri ekranga yo'naltirish → logout.
2. **Mijoz:** choyxona ro'yxati/qidiruv/xarita → choyxona detali → bron qilish (band slot rad etiladi) → bron tarixi → bekor qilish → sharh yozish → sevimlilar.
3. **Choyxona egasi:** dashboard → menyu CRUD → stollar CRUD → bronlarni tasdiqlash/rad etish → analitika → aksiyalar → hisobotlar.
4. **Superadmin:** barcha choyxonalar/foydalanuvchilar → egani tayinlash → CRM → obunalar.
5. **Bildirishnomalar:** yangi bron → egaga push/FCM (Cloud Function) keladi.
6. **Lokalizatsiya:** 3 tilda hech bo'sh/tarjimasiz matn yo'q.
7. **`flutter analyze`:** 0 error (warning'lar minimal va asoslangan).
8. **Build:** 3 platformada release build muvaffaqiyatli quriladi.

---

## 6. Ochiq savollar / qarorlar

| # | Savol | Tavsiya |
|---|---|---|
| Q1 | Email verification yoqilsinmi yoki telefon orqali kirish asosiy bo'lsin? | Klientlar uchun telefon+SMS qulayroq, lekin Firebase SMS sozlash kerak. Hozircha email verification'ni **majburiy qilamiz** yoki ongli o'chiramiz. |
| Q2 | Sig'im manbai (bron limiti) nima? Choyxona umumiy sig'imimi yoki stol/xona darajasimi? | Stol/xona darajasi to'g'riroq (real bron). |
| Q3 | Asosiy til (fallback) uz bo'lsinmi? | Auditoriya O'zbekiston — `uz` ni asosiy, `ru` ni fallback qilish mumkin. |
| Q4 | Firebase config repoda saqlansinmi (private) yoki gitignore? | Private repo bo'lsa repoda saqlash CI/build uchun qulay. |

---

> **Keyingi qadam:** ushbu TZ tasdiqlangach, **Faza 0** dan boshlaymiz (Flutter o'rnatish + `flutter analyze` bilan haqiqiy xatolar ro'yxatini olish), so'ng Faza 1 (P0 buglar).
</content>
</invoke>
