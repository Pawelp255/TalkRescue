# TalkRescue — GitHub Pages (strona publiczna)

Minimalna strona HTML/CSS dla App Store Connect:

| Plik | URL (po wdrożeniu) |
|------|---------------------|
| `index.html` | `https://<user>.github.io/<repo>/` |
| `support.html` | `https://<user>.github.io/<repo>/support.html` |
| `privacy.html` | `https://<user>.github.io/<repo>/privacy.html` |

Kontakt i dane wydawcy są uzupełnione w plikach HTML (gotowe do wdrożenia).

---

## Wymagania

- Repozytorium na GitHub (publiczne lub private z GitHub Pages dla org/planów, które to wspierają)
- Folder `docs-site/` w gałęzi `main` (lub innej, której użyjesz)

---

## Wdrożenie (zalecane): Pages z folderu `/docs-site`

### 1. Zatwierdź pliki w repozytorium

```bash
cd ~/Projects/iOS/TalkRescue

git add docs-site/
git status

git commit -m "$(cat <<'EOF'
Add minimal GitHub Pages site for App Store URLs.

Plain HTML/CSS for marketing, support, and privacy policy.
EOF
)"

git push origin main
```

### 2. Włącz GitHub Pages w przeglądarce

1. Otwórz repozytorium na GitHub → **Settings** → **Pages**.
2. **Build and deployment** → **Source:** `Deploy from a branch`.
3. **Branch:** `main` (lub Twoja domyślna gałąź).
4. **Folder:** `/docs-site` (nie `/docs` ani root).
5. Kliknij **Save**.

Po 1–3 minutach strona będzie pod:

```text
https://<GITHUB_USERNAME>.github.io/TalkRescue/
```

(Zamień `TalkRescue` na nazwę repozytorium, jeśli jest inna.)

### 3. Sprawdź lokalnie (opcjonalnie)

```bash
cd ~/Projects/iOS/TalkRescue/docs-site
python3 -m http.server 8080
```

Otwórz: http://127.0.0.1:8080/

---

## Aktualizacja treści po publikacji

```bash
cd ~/Projects/iOS/TalkRescue

# edytuj pliki w docs-site/
git add docs-site/
git commit -m "Update public site copy"
git push origin main
```

GitHub Pages przebuduje stronę automatycznie (zwykle w ciągu minuty).

---

## App Store Connect — które URL wkleić

| Pole w Connect | URL |
|----------------|-----|
| **Privacy Policy URL** | `https://<GITHUB_USERNAME>.github.io/<REPO>/privacy.html` |
| **Support URL** | `https://<GITHUB_USERNAME>.github.io/<REPO>/support.html` |
| Marketing / strona (opcjonalnie) | `https://<GITHUB_USERNAME>.github.io/<REPO>/` |

Użyj **HTTPS** — GitHub Pages dostarcza certyfikat automatycznie.

---

## Własna domena (opcjonalnie)

1. **Settings → Pages → Custom domain** — np. `talkrescue.app`.
2. U dostawcy DNS dodaj rekordy według instrukcji GitHub (zwykle `CNAME` lub `A`/`AAAA`).
3. Włącz **Enforce HTTPS**.

Po propagacji DNS zaktualizuj URL w App Store Connect na domenę własną.

---

## Alternatywa: gałąź `gh-pages` (tylko pliki strony)

Jeśli wolisz osobną gałąź zamiast folderu `/docs-site`:

```bash
cd ~/Projects/iOS/TalkRescue

git checkout --orphan gh-pages
git rm -rf .
cp -R docs-site/. .
git add index.html privacy.html support.html styles.css
git commit -m "Publish TalkRescue GitHub Pages site"
git push -u origin gh-pages

git checkout main
```

W **Settings → Pages** ustaw **Branch:** `gh-pages`, **Folder:** `/ (root)`.

> Uwaga: gałąź `gh-pages` nie zawiera kodu aplikacji — tylko statyczne pliki WWW. Folder `docs-site/` na `main` jest prostszy w utrzymaniu.

---

## Checklist przed App Store

- [x] E-mail w `support.html` i `privacy.html` jest prawdziwy i monitorowany
- [x] Data wejścia w życie i dane wydawcy uzupełnione w `privacy.html`
- [ ] URL-e w Connect otwierają się w Safari na iPhonie
- [ ] Treść polityki zgadza się z `docs/PRIVACY_POLICY_PL.md` i odpowiedziami App Privacy

---

## Struktura plików

```text
docs-site/
├── index.html      # Opis aplikacji
├── support.html    # Wsparcie + e-mail
├── privacy.html    # Polityka prywatności (PL)
├── styles.css      # Ciemny motyw TalkRescue
└── README.md       # Ten plik
```

Brak frameworków, trackerów ani skryptów zewnętrznych — bezpieczne dla wymagań Apple dotyczących prostych stron informacyjnych.
