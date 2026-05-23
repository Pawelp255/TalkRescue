# TalkRescue — odpowiedzi App Privacy (App Store Connect)

**Cel:** przewodnik po kwestionariuszu **App Privacy** (Prywatność aplikacji) w App Store Connect.  
**Wersja aplikacji:** 1.0 MVP · brak konta · brak reklam · brak SDK analityki/śledzenia

**Źródła:** `PRIVACY_POLICY_PL.md`, `APP_STORE_METADATA_PL.md`, kod aplikacji (lokalna historia, OpenAI tłumaczenie, Apple Speech).

> **Uwaga:** Odpowiedzi muszą być zgodne z **rzeczywistym** zachowaniem builda wysłanego do review. Jeśli dodasz analitykę lub logowanie — zaktualizuj ten dokument i politykę prywatności.

---

## Podsumowanie dla developera

| Pytanie wysokiego poziomu | Odpowiedź |
|---------------------------|-----------|
| Czy zbieracie dane? | **Tak** — ograniczony zestaw (patrz poniżej) |
| Czy dane są powiązane z użytkownikiem? | **Nie** (brak konta, brak identyfikatora użytkownika po stronie TalkRescue) |
| Czy używacie danych do śledzenia? | **Nie** |
| Czy dane są używane do reklam? | **Nie** |
| Czy sprzedajecie dane? | **Nie** |
| Czy wymagane jest konto? | **Nie** |

---

## Krok 1: Czy aplikacja zbiera dane?

**Wybierz:** Tak, zbieramy dane z tej aplikacji.

*Nawet jeśli dane nie trafiają na Twój serwer, przesłanie tekstu do OpenAI i użycie mikrofonu/Speech uznaje się za „zbieranie” / przetwarzanie w ramach etykiety prywatności.*

---

## Krok 2: Typy danych — co zaznaczyć

Poniżej typy zgodne z MVP TalkRescue. W Connect wybierz tylko te, które pasują do aktualnego builda.

### A. Dane użytkowania (Usage Data) — opcjonalnie

| Podtyp | Zbieracie? | Uwagi |
|--------|------------|--------|
| Product Interaction | **Nie** (domyślnie MVP) | Brak Firebase/Analytics/Mixpanel w projekcie |
| Inne Usage Data | **Nie** | — |

**Rekomendacja MVP:** **nie zaznaczaj** Usage Data, jeśli nie masz żadnego SDK analityki.

---

### B. Dane diagnostyczne (Diagnostics) — opcjonalnie

| Podtyp | Zbieracie? | Uwagi |
|--------|------------|--------|
| Crash Data | **Tylko jeśli** włączysz Xcode Organizer / third-party crash reporter w przyszłości | Obecny MVP: typowo **Nie** po stronie developera poza standardowymi raportami Apple od użytkowników |
| Performance Data | **Nie** | — |

**Rekomendacja MVP:** **nie zaznaczaj**, chyba że świadomie integrujesz crash reporting do Connect.

---

### C. Treść użytkownika (User Content)

| Podtyp | Zbieracie? | Uwagi |
|--------|------------|--------|
| **Audio Data** | **Tak** | Mikrofon podczas nagrywania / Rescue Mode |
| **Other User Content** | **Tak** | Rozpoznany tekst polski i wynik angielski |

**Wyjaśnienie dla użytkownika (Privacy Nutrition Label):**

- Audio: przetwarzane na urządzeniu do rozpoznania mowy (Apple Speech).  
- Tekst: rozpoznana wypowiedź może zostać wysłana do **dostawcy tłumaczenia (OpenAI)** przez HTTPS.

---

### D. Identyfikatory (Identifiers)

| Podtyp | Zbieracie? | Uwagi |
|--------|------------|--------|
| User ID | **Nie** | Brak konta |
| Device ID | **Nie** | Brak własnego trackingu urządzenia w MVP |

---

### E. Dane kontaktowe, lokalizacja, zakupy, zdrowie itd.

| Kategoria | Zbieracie? |
|-----------|------------|
| Contact Info | **Nie** |
| Location | **Nie** (aplikacja nie używa GPS) |
| Financial Info | **Nie** |
| Sensitive Info | **Nie** |
| Contacts | **Nie** |
| Browsing History | **Nie** |
| Search History | **Nie** |
| Purchases | **Nie** (jeśli aplikacja darmowa bez IAP) |
| Health & Fitness | **Nie** |

---

## Krok 3: Dla każdego zaznaczonego typu — cel i powiązanie

### Audio Data

| Pole w Connect | Odpowiedź |
|----------------|-----------|
| **Powiązane z tożsamością użytkownika?** | **Nie** |
| **Używane do śledzenia?** | **Nie** |
| **Cele przetwarzania** | **Funkcjonalność aplikacji** (App Functionality) |

**Opis (wewnętrzny):** Nagranie z mikrofonu służy wyłącznie rozpoznaniu mowy i tłumaczeniu w ramach sesji użytkownika. Brak konta TalkRescue.

---

### Other User Content (tekst rozmowy / tłumaczenie)

| Pole w Connect | Odpowiedź |
|----------------|-----------|
| **Powiązane z tożsamością użytkownika?** | **Nie** |
| **Używane do śledzenia?** | **Nie** |
| **Cele przetwarzania** | **Funkcjonalność aplikacji** |

**Opis:** Rozpoznany tekst polski jest wysyłany do API tłumaczenia w celu uzyskania angielskiego wyniku. Historia i ulubione są zapisywane **lokalnie** na urządzeniu (UserDefaults) — nie na serwerze TalkRescue.

---

## Krok 4: Śledzenie (Tracking)

**Pytanie:** Czy Ty lub partnerzy trzeciej strony używacie danych do śledzenia użytkowników?

**Odpowiedź:** **Nie**

| Element | Stan w MVP |
|---------|------------|
| Reklamy | Brak |
| ATT / IDFA pod reklamy | Nie dotyczy |
| SDK analityki (Firebase Analytics itp.) | Brak w projekcie |
| „Tracking” wg Apple (łączenie z tożsamością z innych firm) | Nie |

---

## Krok 5: Prywatność a praktyki produktu (tekst do polityki / review)

Skopiuj lub zaadaptuj do komunikacji ze sklepem:

```
• Konto: nie jest wymagane ani oferowane.
• Historia i ulubione: przechowywane wyłącznie lokalnie na iPhonie użytkownika.
• Rozpoznawanie mowy: na urządzeniu (Apple Speech, język polski).
• Tłumaczenie: wymaga internetu; rozpoznany tekst może zostać przesłany do OpenAI (HTTPS).
• Reklamy: brak.
• Śledzenie reklamowe: brak.
• Sprzedaż danych: nie dotyczy — TalkRescue nie sprzedaje danych użytkowników.
• Klucz API: konfigurowany przy budowaniu aplikacji, nie wpisywany przez użytkownika w UI.
```

---

## Podmioty trzecie (Third-Party Partners)

W sekcji partnerów / danych wskazuj (zgodnie z faktycznym buildem):

| Partner | Rodzaj danych | Cel |
|---------|---------------|-----|
| **Apple** | Audio (mikrofon), przetwarzanie mowy | Speech framework, iOS, opcjonalnie TTS |
| **OpenAI** (lub aktualny dostawca API) | Tekst (rozpoznana wypowiedź po polsku) | Tłumaczenie na angielski |

**Nie dodawaj** partnerów reklamowych ani analitycznych, jeśli ich nie ma w buildzie.

---

## App Tracking Transparency (ATT)

**Czy wyświetlasz prośbę ATT?** **Nie** — aplikacja nie śledzi użytkowników pod reklamy ani nie używa IDFA w tym celu.

---

## Privacy Policy URL

Musi być **publiczny HTTPS** przed submisją. Treść: `PRIVACY_POLICY_PL.md` (uzupełnij datę, wydawcę, e-mail).

```
[UZUPEŁNIJ — ten sam URL co w APP_STORE_CONNECT_FINAL_PL.md]
```

---

## Zgodność z etykietą a kodem — checklist

- [ ] W buildzie review **nie ma** ukrytego SDK analytics  
- [ ] Opis w Connect = to samo co `PRIVACY_POLICY_PL.md`  
- [ ] Historia / ulubione — tylko lokalnie (nie zaznaczaj „Collected and linked” dla własnego serwera)  
- [ ] OpenAI / tłumaczenie — zaznaczone jako User Content + App Functionality  
- [ ] Po dodaniu crash reporting lub konta — **zaktualizuj** kwestionariusz

---

## Szablon odpowiedzi PL dla użytkownika (opcjonalny blok w polityce)

> TalkRescue nie wymaga konta. Historia i ulubione zostają na Twoim iPhonie. Mowa jest rozpoznawana na urządzeniu; tekst do tłumaczenia może trafić do dostawcy tłumaczenia w internecie. Nie wyświetlamy reklam i nie śledzimy Cię pod reklamy w tej wersji aplikacji.

---

*TalkRescue — App Privacy answers PL · maj 2026*
