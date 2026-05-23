# TalkRescue — brief ikony App Store (1024×1024)

Brief dla projektanta / generowania ikony. **Bez tekstu na ikonie** (wymóg czytelności Apple w małym rozmiarze).

---

## Wymiary i format

| Parametr | Wartość |
|----------|---------|
| Rozmiar | **1024 × 1024 px** |
| Format dostawy | PNG, sRGB, bez przezroczystości (pełny kwadrat) |
| Zaokrąlenie | System iOS zaokrągla automatycznie — projektuj na pełnym kwadracie |
| Tekst | **Brak** liter, nazwy, tagline |

---

## Koncepcja

**TalkRescue** = ratunek w rozmowie (polski → angielski). Ikona ma komunikować: **głos / mikrofon** + **natychmiastowa pomoc / energia ratunkowa**, w estetyce **premium, spokojnej, nowoczesnej**.

### Elementy główne

1. **Mikrofon** (symbol rozpoznawania mowy)  
   - Styl: uproszczony, geometryczny, nie fotorealistyczny  
   - Pozycja: centralnie lub lekko przesunięty w górę  
   - Kolor: jasny (biały / bardzo jasny szary) lub delikatny gradient biały→srebrny  

2. **Symbol ratunku / błyskawicy** (energia, „rescue”, szybkość)  
   - Subtelna **błyskawica** obok lub za mikrofonem, albo jako akcent na korpusie mikrofonu  
   - Alternatywa: mały **bolt** (jak ikona ⚡ w aplikacji) zintegrowany z podstawą mikrofonu  
   - Nie przesadzać — jeden dominujący motyw (mic), jeden akcent (lightning)  

### Tło

- **Ciemne, premium**: głęboki granat, antracyt lub czerń z delikatnym gradientem (np. `#0A0E14` → `#141C28`)  
- Opcjonalnie: bardzo subtelny **glow** za mikrofonem (kolor akcentu: stonowany czerwony-koralowy lub niebieski — zgodny z UI aplikacji, bez jaskrawej czerwieni alarmowej)  
- Bez zdjęć, bez map, bez flag  

### Styl wizualny

- Płaskie / lekko **soft 3D** (subtelny cień pod ikoną mikrofonu)  
- Zaokrąglone kształty, przyjazne dla App Store  
- Wysoki kontrast mikrofonu na tle (dostępność w małym rozmiarze)  
- Spójność z **Trybem ratunkowym** (ciemny ekran) i spokojnym czerwonym/koralowym akcentem nagrywania w aplikacji  

---

## Czego unikać

- Tekstu „TalkRescue”, „TR”, flag PL/UK  
- Zbyt wielu elementów (słuchawki + globus + dymki + tłumacz)  
- Jaskrawej czerwieni „nagrania” jako dominującego tła  
- Stockowych clipartów mikrofonu  
- Through-alpha / przezroczyste tło w pliku 1024  

---

## Warianty do rozważenia (opcjonalnie)

| Wariant | Opis |
|---------|------|
| **A (zalecany)** | Mikrofon biały, błyskawica koralowo-pomarańczowa, tło granatowe gradient |
| **B** | Mikrofon + okrągły pierścień „pulse” (nasłuch), bez błyskawicy |
| **C** | Sam symbol mikrofonu w okręgu ratunkowym (jak okrągły badge) |

Dla App Store wystarczy **jeden** wariant A.

---

## Test w małym rozmiarze

Sprawdź podgląd na:

- 60×60 pt (@3x = 180 px) — ekran główny  
- 40×40 pt — ustawienia  

Mikrofon i błyskawica muszą być **rozpoznawalne** bez szczegółów.

---

## Powiązanie z Xcode

Po zatworzeniu grafiki:

1. Wyeksportuj **1024×1024 PNG**  
2. Dodaj do `Assets.xcassets` → **AppIcon** → slot iOS Marketing 1024pt  
3. Uzupełnij pozostałe rozmiary (Xcode może wygenerować z jednego źródła)  

---

*Brief ikony — TalkRescue, maj 2026.*
