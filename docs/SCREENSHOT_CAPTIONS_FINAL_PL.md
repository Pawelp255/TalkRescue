# TalkRescue — podpisy i kolejność zrzutów (final, PL)

**Cel:** gotowe tytuły i podpisy do ramek marketingowych (Figma / App Store Connect / narzędzia third-party).  
**Zestaw:** 5 zrzutów · język UI na ekranie: **polski**  
**Rozmiar urządzenia:** iPhone 6,7″ lub 6,9″ (np. iPhone 15 Pro Max / 16 Pro Max w symulatorze)

**Powiązane:** `SCREENSHOT_PLAN.md`, `APP_STORE_CONNECT_FINAL_PL.md`, `FINAL_ICON_GUIDE.md`

---

## Kolejność w App Store Connect (zalecana)

| # | Plik (sugerowana nazwa) | Ekran w aplikacji |
|---|-------------------------|-------------------|
| **1** | `01-main-result.png` | Główny — po tłumaczeniu |
| **2** | `02-rescue-listening.png` | Tryb ratunkowy — nasłuch |
| **3** | `03-rescue-done.png` | Tryb ratunkowy — wynik |
| **4** | `04-history.png` | Historia |
| **5** | `05-trust-about.png` | O aplikacji *lub* Szybkie zwroty |

---

## Zrzut 1 — Hook (główny ekran)

| Pole | Treść |
|------|--------|
| **Tytuł (overlay)** | Mów po polsku. Czytaj po angielsku. |
| **Podpis (caption)** | Duży angielski tekst — od razu w rozmowie. |
| **Ekran do uchwycenia** | Zakładka **Główny**: po udanym tłumaczeniu. Przykład: PL „Proszę powtórzyć” → EN „Could you repeat that, please?” Status **Gotowe.** |
| **Uwagi** | Spokojny status (zielony / neutralny), nie czerwony „nagrywanie”. Status bar: 9:41, pełna bateria. |

**Tekst do wklejenia (rama):**

```
TYTUŁ: Mów po polsku. Czytaj po angielsku.
PODPIS: Duży angielski tekst — od razu w rozmowie.
```

---

## Zrzut 2 — Tryb ratunkowy (nasłuch)

| Pole | Treść |
|------|--------|
| **Tytuł** | Tryb ratunkowy |
| **Podpis** | Jedno naciśnięcie Action Button — i już nasłuchujesz. |
| **Ekran** | **Rescue Mode** (ciemne tło): banner **Gotowy — mów po polsku**, widoczny przycisk **DOTKNIJ, GDY SKOŃCZYSZ**. |
| **Uwagi** | Podkreśla prostotę i zaufanie; opcjonalnie lekka aktywność fali mowy. |

**Tekst do wklejenia:**

```
TYTUŁ: Tryb ratunkowy
PODPIS: Jedno naciśnięcie Action Button — i już nasłuchujesz.
```

---

## Zrzut 3 — Tryb ratunkowy (wynik)

| Pole | Treść |
|------|--------|
| **Tytuł** | Gotowe w kilka sekund |
| **Podpis** | Przestań mówić — aplikacja sama przejdzie dalej. |
| **Ekran** | **Rescue Mode** po tłumaczeniu: duży angielski wynik (np. „I need a moment.”), status **Gotowe**. |
| **Uwagi** | Pokazuje auto-zakończenie po ciszy; spójne z produktem. |

**Tekst do wklejenia:**

```
TYTUŁ: Gotowe w kilka sekund
PODPIS: Przestań mówić — aplikacja sama przejdzie dalej.
```

---

## Zrzut 4 — Historia (prywatność lokalna)

| Pole | Treść |
|------|--------|
| **Tytuł** | Twoja historia rozmów |
| **Podpis** | Ostatnie tłumaczenia — tylko na tym iPhonie. |
| **Ekran** | Zakładka **Historia**: 2–3 karty z angielskim (duży) i polskim (mniejszy). |
| **Uwagi** | Wcześniej wykonaj 2–3 tłumaczenia na urządzeniu testowym. Brak danych osobowych. |

**Tekst do wklejenia:**

```
TYTUŁ: Twoja historia rozmów
PODPIS: Ostatnie tłumaczenia — tylko na tym iPhonie.
```

---

## Zrzut 5 — Zaufanie / funkcje

| Pole | Treść |
|------|--------|
| **Tytuł** | Bez konta. Bez zbędnych kroków. |
| **Podpis** | Mikrofon, rozpoznanie na iPhonie, tłumaczenie gdy potrzebujesz. |
| **Ekran (zalecany)** | Zakładka **O aplikacji** — sekcje Prywatność i Szybki start (Action Button / Siri). |
| **Alternatywa** | **Główny** z sekcją **Szybkie zwroty** + włączonym **Mów po angielsku**. |
| **Uwagi** | Wybierz wariant bardziej czytelny w miniaturze; **O aplikacji** lepsze dla zaufania. |

**Tekst do wklejenia:**

```
TYTUŁ: Bez konta. Bez zbędnych kroków.
PODPIS: Mikrofon, rozpoznanie na iPhonie, tłumaczenie gdy potrzebujesz.
```

---

## Spójność wizualna (ramki marketingowe)

| Element | Zalecenie |
|---------|-----------|
| Tło ramki | Ciemny gradient zgodny z ikoną: `#0A0C10` → `#121820`, opcjonalny delikatny niebieski bloom |
| Akcent w ramce | Biały + bursztyn `#E8A84A` (jak ikona) |
| UI na zrzutach | Główny / Historia: **jasny** tryb; Rescue Mode: naturalnie **ciemny** |
| Czcionka overlay | SF Pro / systemowa, bold tytuł, regular podpis |
| Ikona w rogu ramki | Opcjonalnie mała ikona TalkRescue (nie duplikuj na samym zrzucie UI) |

---

## Checklist przed uploadem

- [ ] 5 plików PNG w wymaganej rozdzielczości Apple dla wybranego rozmiaru iPhone  
- [ ] Teksty overlay **po polsku**, zgodne z `APP_STORE_CONNECT_FINAL_PL.md`  
- [ ] Brak danych osobowych, prawdziwych imion, numerów  
- [ ] Status bar czysty (9:41, pełna bateria, mocny sygnał)  
- [ ] Kolejność 1→5 jak w tabeli powyżej  
- [ ] Zrzut 1 = najmocniejszy hook (pierwszy ekran w sklepie)

---

## Szybka lista copy-paste (same podpisy)

```
1. Mów po polsku. Czytaj po angielsku. — Duży angielski tekst — od razu w rozmowie.
2. Tryb ratunkowy — Jedno naciśnięcie Action Button — i już nasłuchujesz.
3. Gotowe w kilka sekund — Przestań mówić — aplikacja sama przejdzie dalej.
4. Twoja historia rozmów — Ostatnie tłumaczenia — tylko na tym iPhonie.
5. Bez konta. Bez zbędnych kroków. — Mikrofon, rozpoznanie na iPhonie, tłumaczenie gdy potrzebujesz.
```

---

*TalkRescue — screenshot captions final PL · maj 2026*
