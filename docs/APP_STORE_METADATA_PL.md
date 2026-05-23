# TalkRescue — metadane App Store (PL)

Dokument roboczy do wklejenia w App Store Connect (wersja polska).  
Bundle ID: `com.pawelp.talkrescue` · Nazwa wyświetlana: **TalkRescue**

---

## Nazwa aplikacji (App Name)

**TalkRescue**

*(limit App Store: 30 znaków — mieści się)*

---

## Podtytuł (Subtitle)

**Polski głos → angielski w rozmowie**

*(limit: 30 znaków — sprawdź w App Store Connect przed wysłaniem)*

Alternatywa (krótsza): **Tłumacz rozmowę na angielski**

---

## Tekst promocyjny (Promotional Text)

Mów po polsku — od razu zobacz angielski. Tryb ratunkowy z przycisku Action: jedno naciśnięcie, nasłuch i tłumaczenie bez rozpraszania. Bez konta. Historia na urządzeniu.

*(limit: 170 znaków — dostosuj długość w Connect)*

---

## Pełny opis (Description)

**TalkRescue pomaga w trudnej rozmowie, gdy mówisz po polsku, a potrzebujesz szybko angielskiego.**

Nie jest to kolejny ogólny translator. To narzędzie „ratunkowe” pod presją: duży tekst, proste gesty, minimum rozproszeń.

### Jak to działa

1. **Przytrzymaj i mów** — powiedz coś po polsku na ekranie głównym.  
2. **Puść** — aplikacja rozpozna mowę na iPhonie i przetłumaczy na angielski.  
3. **Przeczytaj lub odtwórz** — duży angielski tekst; opcjonalnie automatyczne odczytanie na głos.

### Tryb ratunkowy (Rescue Mode)

- Uruchom z aplikacji **Skróty**, przycisku **Action** (iPhone 15 Pro i nowsze) lub Siri.  
- Aplikacja od razu zaczyna nasłuch.  
- Po chwili ciszy sama kończy nagrywanie i tłumaczy.  
- Jednym dotknięciem zakończysz ręcznie, gdy chcesz.

Idealny, gdy nie masz czasu na menu — liczy się szybkość i spokój.

### Co jeszcze oferuje TalkRescue

- **Szybkie zwroty** — gotowe angielskie frazy jednym dotknięciem (np. „Can you repeat that?”).  
- **Historia** — ostatnie tłumaczenia zapisane lokalnie na telefonie.  
- **Ulubione** — zapisz najczęściej używane pary polski / angielski.  
- **Kopiuj, odtwórz, wyczyść** — proste akcje pod dużym wynikiem.  
- **Część zwrotów offline** — natychmiastowe tłumaczenie popularnych polskich fraz bez czekania na sieć.

### Prywatność i konto

- **Bez konta** — nie zakładasz profilu w TalkRescue.  
- Rozpoznawanie mowy odbywa się na urządzeniu (Apple Speech).  
- Do tłumaczenia na angielski potrzebny jest internet; rozpoznany tekst może zostać wysłany do usługi tłumaczenia.  
- Historia i ulubione zostają **tylko na Twoim iPhonie**.

### Wymagania

- iPhone z iOS 17 lub nowszym  
- Zezwolenie na **mikrofon** i **rozpoznawanie mowy**  
- Połączenie internetowe do tłumaczenia (poza wbudowanymi szybkimi zwrotami)

### Dla kogo

- Polacy rozmawiający z osobami anglojęzycznymi  
- Podróże, praca, codzienne sytuacje, w których liczy się jasność i tempo  
- Każdy, kto woli **jedno proste narzędzie** zamiast rozbudowanego tłumacza

TalkRescue: mów po polsku — mów po angielsku z większą pewnością.

---

## Słowa kluczowe (Keywords)

`tłumacz,polski,angielski,rozmowa,mikrofon,głos,ratunek,Action Button,Siri,krótka rozmowa,pomoc,w podróży`

*(limit: 100 znaków łącznie, bez spacji po przecinkach — skróć lub zamień synonimy w Connect)*

Wersja alternatywna (jeśli brakuje miejsca):

`polski,angielski,tłumaczenie,rozmowa,mikrofon,ratunek,Action,Siri,głos`

---

## Notatki wsparcia (Support)

**Temat:** TalkRescue — wsparcie użytkownika

- **Strona / polityka prywatności:** umieść publiczny URL do `PRIVACY_POLICY_PL.md` (np. GitHub Pages, Notion, lub strona autora) w polu Privacy Policy URL w App Store Connect.  
- **E-mail wsparcia (do uzupełnienia przez autora):** `support@TWOJA-DOMENA.pl`  
- **Typowe pytania:**  
  - Brak tłumaczenia → sprawdź internet i uprawnienia mikrofonu / rozpoznawania mowy.  
  - „Nie wykryto mowy” → mów wyraźniej, bliżej mikrofonu, w cichszym otoczeniu.  
  - Action Button → wymaga skrótu „Tryb ratunkowy” w aplikacji Skróty (iPhone 15 Pro+).  
- **Język wsparcia:** polski (opcjonalnie angielski w odpowiedziach).

---

## Notatki dla zespołu App Review (App Review Information)

**Krótki opis dla recenzenta (Notes):**

TalkRescue is a Polish → English conversation rescue app. No login or user accounts.

**How to test (recommended path):**

1. Launch the app and grant **Microphone** and **Speech Recognition** when prompted.  
2. On the **Main** tab: press and hold the blue **“Przytrzymaj i mów”** button, speak a short Polish phrase (e.g. „Proszę powtórzyć”), release, wait for English translation.  
3. Tap **Rescue** (bolt icon) or use the in-app path to **Rescue Mode**: black full-screen UI, auto-listen, speak Polish, stop speaking — silence auto-finish triggers translation.  
4. Optional: **Auto Speak** toggle reads English aloud after translation.  
5. **History** and **Favorites** tabs show locally stored phrases only.

**Third-party services:**

- Polish speech recognition: on-device via Apple `Speech` framework.  
- Translation: HTTPS request to OpenAI API with recognized Polish text (user’s build includes API key in `Secrets.xcconfig` at compile time; not entered in UI).

**No advertising, no analytics SDK, no tracking** in this version.

**Action Button / Shortcuts:**

- Requires user-created Shortcut “Rescue Mode” in the Shortcuts app (documented in About). Not enabled by default on all devices.

**Test account:** Not required (no account system).

**Contact for review questions:** [uzupełnij e-mail developera]

---

## Pola App Store Connect — checklist

| Pole | Wartość / plik |
|------|----------------|
| Primary language | Polish |
| Category | Productivity lub Travel (do decyzji autora) |
| Age rating | 4+ (brak treści dla dorosłych) |
| Privacy Policy URL | Host `docs/PRIVACY_POLICY_PL.md` jako strona WWW |
| Copyright | © [rok] [nazwa autora] |
| Version release notes (1.0) | Pierwsza wersja: tryb ratunkowy, tłumaczenie PL→EN, historia lokalna |

---

*Ostatnia aktualizacja dokumentu: maj 2026 — zgodnie z funkcjami MVP TalkRescue.*
