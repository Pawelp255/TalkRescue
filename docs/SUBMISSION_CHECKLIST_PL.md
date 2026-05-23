# TalkRescue — checklist submisji App Store (final)

**Cel:** ostatnia kontrola przed **Submit for Review** w App Store Connect.  
**Projekt:** `~/Projects/iOS/TalkRescue`  
**Wersja docelowa:** 1.0

**Dokumenty pomocnicze:**

| Plik | Zawartość |
|------|-----------|
| `APP_STORE_CONNECT_FINAL_PL.md` | Teksty listingu (copy-paste) |
| `SCREENSHOT_CAPTIONS_FINAL_PL.md` | 5 zrzutów + podpisy |
| `PRIVACY_ANSWERS_APP_STORE_CONNECT_PL.md` | Kwestionariusz App Privacy |
| `PRIVACY_POLICY_PL.md` | Treść polityki (do hostingu) |
| `FINAL_ICON_GUIDE.md` | Ikona i walidacja |

---

## 1. Ikona aplikacji

- [x] Finalna ikona **1024×1024** w `TalkRescue/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`
- [ ] Podgląd na **fizycznym iPhonie** (Home Screen, Ustawienia) po reinstalacji
- [ ] Usunięto starą aplikację z urządzenia przed testem (cache ikon iOS)
- [ ] Ikona w App Store Connect (Large App Icon) zgodna z buildem

**Przypomnienie:** iOS agresywnie cache’uje ikony — **usuń aplikację** z iPhone’a przed instalacją builda review.

---

## 2. Wersja i build

- [ ] `MARKETING_VERSION` = **1.0** (zgodne z Connect)
- [ ] `CURRENT_PROJECT_VERSION` (**build number**) **zwiększony** względem ostatniego uploadu (stan repo: **11** — przed archiwum sprawdź, czy Connect nie ma już buildu 11)
- [ ] Archive **Release** z poprawnym Team / signing
- [ ] Build przesłany przez Xcode Organizer lub `xcodebuild -exportArchive`
- [ ] W Connect: build **Processed** bez błędów

```bash
# Sprawdzenie wersji w projekcie (informacyjnie)
grep -E 'MARKETING_VERSION|CURRENT_PROJECT_VERSION' \
  TalkRescue/TalkRescue.xcodeproj/project.pbxproj | head -4
```

---

## 3. Zrzuty ekranu

- [ ] **5 zrzutów** iPhone (6,7″ lub 6,9″) wg `SCREENSHOT_CAPTIONS_FINAL_PL.md`
- [ ] Kolejność: Główny → Rescue nasłuch → Rescue wynik → Historia → Zaufanie
- [ ] UI po polsku, brak danych osobowych, status bar 9:41
- [ ] Opcjonalne ramki marketingowe (gradient zgodny z ikoną)
- [ ] Upload w sekcji **App Previews and Screenshots** dla wersji 1.0

---

## 4. Polityka prywatności (hosting)

- [ ] `PRIVACY_POLICY_PL.md` opublikowany pod **publicznym HTTPS**
- [ ] Uzupełnione: data wejścia w życie, wydawca, e-mail kontaktowy
- [ ] **Privacy Policy URL** wklejony w App Store Connect (to samo URL w App Privacy)

```
[UZUPEŁNIJ — https://...]
```

---

## 5. Support URL

- [ ] Strona wsparcia lub sekcja z FAQ + e-mail kontaktowy
- [ ] URL w polu **Support URL** w Connect

```
[UZUPEŁNIJ — https://...]
[UZUPEŁNIJ — support@...]
```

---

## 6. Metadane listingu

- [ ] App Name, Subtitle, Description, Keywords — z `APP_STORE_CONNECT_FINAL_PL.md`
- [ ] Promotional Text (opcjonalnie, max 170 znaków)
- [ ] What’s New (1.0)
- [ ] Copyright: `© 2026 [UZUPEŁNIJ]`
- [ ] Kategoria: **Productivity** (+ opcjonalnie Travel)
- [ ] Wiek: kwestionariusz → oczekiwane **4+**
- [ ] Język podstawowy: **Polish**

---

## 7. App Privacy (kwestionariusz)

- [ ] Wypełniono wg `PRIVACY_ANSWERS_APP_STORE_CONNECT_PL.md`
- [ ] Zaznaczono: **Audio Data**, **Other User Content** (jeśli wysyłacie tekst do tłumaczenia)
- [ ] **Nie** zaznaczono: Tracking, reklamy, sprzedaż danych, konto
- [ ] Partnerzy: Apple + dostawca tłumaczenia (OpenAI)
- [ ] Etykieta prywatności zgodna z polityką WWW

---

## 8. App Review Information

- [ ] Notes dla recenzenta (EN) — z `APP_STORE_CONNECT_FINAL_PL.md`
- [ ] **Sign-in required:** No
- [ ] E-mail kontaktowy dla App Review: `[UZUPEŁNIJ]`
- [ ] Opcjonalnie: krótki film z flow głównym + Rescue Mode
- [ ] API key w buildzie review działa (tłumaczenie nie może failować na każdym żądaniu)

**Test recenzenta (30 s):**

1. Zezwól na mikrofon i rozpoznawanie mowy.  
2. Przytrzymaj „Przytrzymaj i mów” → mów po polsku → puść → angielski wynik.  
3. Tryb ratunkowy → mów → cisza lub „Dotknij, gdy skończysz”.

---

## 9. Build w Connect i submisja

- [ ] Wersja **1.0** utworzona w App Store Connect
- [ ] Wybrany poprawny build (numer buildu = upload z Xcode)
- [ ] Wszystkie pola obowiązkowe bez żółtych ostrzeżeń
- [ ] Export compliance / encryption: typowo **No** (tylko standard HTTPS) — potwierdź w Connect
- [ ] Content Rights / Advertising Identifier: zgodnie z faktycznym buildem (brak reklam)
- [ ] Kliknięto **Add for Review** → **Submit for Review**

---

## 10. Po wysłaniu

- [ ] Status: **Waiting for Review**
- [ ] Monitoruj e-mail App Store Connect (pytania recenzenta)
- [ ] Przy odrzuceniu: odpowiedz w Resolution Center z konkretnymi krokami reprodukcji

---

## Pola wymagające ręcznego uzupełnienia

| Element | Gdzie |
|---------|--------|
| Privacy Policy URL | Connect + hosting WWW |
| Support URL | Connect |
| E-mail wsparcia | Strona support + polityka |
| E-mail App Review | App Review Information |
| Copyright — nazwa wydawcy | Connect |
| Cena i kraje | Connect |
| Build number bump | Xcode → Archive → Upload |
| Hosting polityki (data, wydawca) | `PRIVACY_POLICY_PL.md` |

---

## Szybka ścieżka „dzisiaj”

1. Opublikuj politykę prywatności → skopiuj URL.  
2. Podnieś **build number** → Archive → Upload.  
3. Wklej metadane z `APP_STORE_CONNECT_FINAL_PL.md`.  
4. Upload 5 zrzutów + podpisy z `SCREENSHOT_CAPTIONS_FINAL_PL.md`.  
5. Wypełnij App Privacy z `PRIVACY_ANSWERS_APP_STORE_CONNECT_PL.md`.  
6. Wybierz build → Submit for Review.

---

*TalkRescue — submission checklist PL · maj 2026*
