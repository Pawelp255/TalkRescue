# TalkRescue — plan zrzutów ekranu App Store

Zalecany zestaw: **5 zrzutów** (iPhone 6,7″ / 6,9″ — np. iPhone 15 Pro Max lub aktualny simulator).  
Język interfejsu na zrzutach: **polski** (domyślny w aplikacji).  
Tło marketingowe: ciemny gradient lub jednolity kolor zgodny z ikoną (opcjonalnie w Figma / App Store frames).

---

## Zrzut 1 — Główny ekran z wynikiem

| Pole | Treść |
|------|--------|
| **Tytuł (overlay)** | Mów po polsku. Czytaj po angielsku. |
| **Podpis** | Duży angielski tekst — od razu w rozmowie. |
| **Ekran do uchwycenia** | Zakładka **Główny**: po udanym tłumaczeniu (np. polski: „Proszę powtórzyć” → angielski: „Could you repeat that, please?”). Widoczny status **Gotowe.** i sekcja rozpoznanego polskiego. |
| **Uwagi techniczne** | Unikaj pustego placeholdera; użyj realistycznej, krótkiej frazy. Status w spokojnym kolorze (zielony / neutralny), nie czerwony „nagrywanie”. |

---

## Zrzut 2 — Tryb ratunkowy (nasłuch)

| Pole | Treść |
|------|--------|
| **Tytuł** | Tryb ratunkowy |
| **Podpis** | Jedno naciśnięcie Action Button — i już nasłuchujesz. |
| **Ekran** | **Rescue Mode** (czarne tło): banner **Gotowy — mów po polsku** (zielony), duży placeholder lub już częściowy angielski, przycisk **DOTKNIJ, GDY SKOŃCZYSZ**. |
| **Uwagi** | Pokaż zaufanie i prostotę UI; można lekko podświetlić falę aktywności mowy. |

---

## Zrzut 3 — Tryb ratunkowy (tłumaczenie gotowe)

| Pole | Treść |
|------|--------|
| **Tytuł** | Gotowe w kilka sekund |
| **Podpis** | Przestań mówić — aplikacja sama przejdzie dalej. |
| **Ekran** | **Rescue Mode** po tłumaczeniu: duży angielski wynik (np. „I need a moment.”), status **Gotowe**, opcjonalnie zielone obramowanie instant cache. |
| **Uwagi** | Podkreśla auto-zakończenie ciszą (zgodne z produktem). |

---

## Zrzut 4 — Historia

| Pole | Treść |
|------|--------|
| **Tytuł** | Twoja historia rozmów |
| **Podpis** | Ostatnie tłumaczenia — tylko na tym iPhonie. |
| **Ekran** | Zakładka **Historia**: 2–3 karty (`PhraseCardRow`) — angielski duży, polski mniejszy, subtelna data. |
| **Uwagi** | Wygląd „produktowy”, nie lista debug. W razie potrzeby wcześniej wykonaj 2–3 tłumaczenia na urządzeniu testowym. |

---

## Zrzut 5 — Szybki start / zaufanie

| Pole | Treść |
|------|--------|
| **Tytuł** | Bez konta. Bez zbędnych kroków. |
| **Podpis** | Mikrofon, rozpoznanie na iPhonie, tłumaczenie gdy potrzebujesz. |
| **Ekran (opcja A)** | Zakładka **O aplikacji** — sekcje Prywatność i Szybki start (Action Button / Siri). |
| **Ekran (opcja B)** | **Główny** z sekcją **Szybkie zwroty** + włączonym **Mów po angielsku**. |
| **Uwagi** | Wybierz wariant bardziej czytelny w miniaturze; A lepszy dla zaufania, B dla funkcji. |

---

## Kolejność w App Store Connect

1. Główny z wynikiem (hook)  
2. Tryb ratunkowy — gotowy do mowy  
3. Tryb ratunkowy — wynik  
4. Historia  
5. Prywatność / szybkie zwroty  

---

## Checklist przed eksportem

- [ ] Tryb jasny lub ciemny — spójny na wszystkich zrzutach (zalecany **jasny** dla czytelności w sklepie, Rescue Mode naturalnie ciemny).  
- [ ] Brak paska statusu z niską baterią / dziwną godziną (użyj 9:41 lub Clean Status Bar).  
- [ ] Brak danych osobowych na zrzutach.  
- [ ] Rozdzielczość zgodna z wymaganiami Apple dla wybranego rozmiaru iPhone.  
- [ ] Teksty overlay po polsku, zgodne z metadanymi w `APP_STORE_METADATA_PL.md`.

---

*Plan zrzutów — maj 2026.*
