import Foundation

/// Polish-first user-facing copy. Structured for future localization.
enum L10n {
    enum LanguageUX {
        static let onboardingTitle = "Wybierz język tłumaczenia"
        static let onboardingSubtitle =
            "TalkRescue będzie domyślnie tłumaczyć z polskiego na wybrany język. Możesz to później zmienić."
        static let onboardingOptionEnglish = "Angielski"
        static let onboardingOptionSwedish = "Szwedzki"
        static let onboardingOptionSpanish = "Hiszpański"
        static let onboardingOptionGerman = "Niemiecki"
        static let onboardingCTA = "Zacznij"
        static let sheetTitle = "Język tłumaczenia"
        static let sheetExplainer =
            "Mówisz po polsku — poniżej wybierasz język, na który aplikacja pokazuje i czyta odpowiedź. Zmienisz to później w każdej chwili."
        static let sheetDone = "Gotowe"
        static let chipAccessibilityPrefix = "Język wyjścia"
        static let chipAccessibilityHint = "Otwiera listę języków tłumaczenia"
        static let selectedSuffix = ", wybrano"
        static let translationOutputSection = "Tłumaczenie"
    }

    enum Rescue {
        static let listening = "Słucham…"
        static let preparingMic = "Uruchamianie mikrofonu…"
        static let ready = "Gotowy — mów po polsku"
        static let recordingPolish = "Nagrywam po polsku…"
        static let done = "Gotowe"
        static let noSpeech = "Nie wykryto mowy"
        static let processing = "Przetwarzam…"
        static let translating = "Tłumaczę…"
        static let speaking = "Odtwarzam…"
        static let tapWhenDone = "DOTKNIJ, GDY SKOŃCZYSZ"
        static let tapToListen = "DOTKNIJ, ABY SŁUCHAĆ"
        static let autoContinueHint = "Albo przestań mówić — samo przejdzie dalej"
        static let tryAgain = "Spróbuj ponownie"
        static let retryTranslation = "Ponów tłumaczenie"
        static let englishPlaceholder = "Gotowy do tłumaczenia. Powiedz coś po polsku."
        static let closeAccessibility = "Zamknij tryb ratunkowy"
    }

    enum Main {
        static let holdToSpeak = "Przytrzymaj i mów"
        static let releaseToTranslate = "Puść, aby przetłumaczyć"
        static let noSpeechDetected = "Nie wykryto mowy. Spróbuj ponownie."
        static let shortTapNoSpeech = "Nie wykryto mowy. Przytrzymaj i powiedz coś po polsku."
        static let recordingPolish = "Nagrywam po polsku…"
        static let defaultStatus = "Przytrzymaj przycisk i mów po polsku."
        static let englishLabel = "Angielski"
        static let englishPlaceholder = "Gotowy do tłumaczenia. Naciśnij i zacznij mówić."
        static let targetLanguagePicker = "Język tłumaczenia"
        static let recognizedPolish = "Rozpoznany polski"
        static let nothingRecognized = "Jeszcze nic nie rozpoznano."
        static let speak = "Odtwórz"
        static let copy = "Kopiuj"
        static let save = "Zapisz"
        static let clear = "Wyczyść"
        static let retry = "Ponów"
        static let ready = "Gotowe."
        static let copied = "Skopiowano."
        static let savedToFavorites = "Zapisano w ulubionych."
        static let tabMain = "Główny"
        static let tabHistory = "Historia"
        static let tabFavorites = "Ulubione"
        static let tabAbout = "O aplikacji"
        static let quickPhrases = "Szybkie zwroty"
        static let rescueToolbar = "Ratunek"
        static let noPhrasesYet = "Brak zapisanych zwrotów."
        static let noFavoritesYet = "Brak ulubionych."
        static let couldNotListen = "Nie udało się włączyć nasłuchu. Dotknij, aby spróbować."
        static let nothingToRetry = "Brak tekstu do ponowienia. Najpierw powiedz coś po polsku."
        static let noPolishCaught = "Nie usłyszałem polskiej wypowiedzi."
        static let interrupted = "Przerwano. Dotknij, aby spróbować ponownie."
        static let listenAgain = "Słucham… mów po polsku"
        static let apiKeyMissing = "Usługa tłumaczenia nie jest skonfigurowana."
        static let finishingCapture = "Kończę nagranie…"
        static let gettingEnglish = "Pobieram angielski…"
    }

    enum Voice {
        static let settingsSection = "Głos odtwarzania"
        static let styleStandard = "Standardowy"
        static let styleNatural = "Naturalny"
        static let styleStandardHint = "Szybsze tempo — codzienne użycie."
        static let styleNaturalHint = "Wolniejsze tempo — podróże i słuchawki."
        static let currentVoiceLabel = "Aktywny głos"
        static let tierPremium = "Premium"
        static let tierEnhanced = "Ulepszony"
        static let tierCompact = "Podstawowy"
        static let tierUnknown = "Nieznany"
        static let enhancedAvailableCardTitle = "Lepszy głos dostępny"
        static let showInstructionsButton = "Pokaż instrukcję"
        static let instructionsTitle = "Jak pobrać lepszy głos"
        static let instructionsIntro =
            "Pobierz ulepszony głos w Ustawieniach iPhone’a. TalkRescue użyje go automatycznie."
        static let instructionsStep1 = "Ustawienia"
        static let instructionsStep2 = "Ułatwienia dostępu"
        static let instructionsStep3 = "Treść mówiona"
        static let instructionsStep4 = "Głosy"
        static let instructionsStep5 = "Wybierz język i pobierz głos ze znaczkiem ⬇️"
        static let instructionsDone = "Gotowe"

        static func enhancedCardBody(languageName: String) -> String {
            "Możesz pobrać bardziej naturalny głos systemowy dla \(languageName). Zajmuje to chwilę i działa offline."
        }
    }

    enum UsageStats {
        static let sectionTitle = "Statystyki użycia"
        static let totalTranslations = "Tłumaczenia łącznie"
        static let mostUsedLanguage = "Najczęściej używany język"
        static let rescueUses = "Użycia trybu ratunkowego"
        static let cacheHits = "Trafienia pamięci podręcznej"
        static let localOnlyNote = "Licznik lokalny na tym urządzeniu. Dane nie są wysyłane na serwer."
        static let sendFeedback = "Wyślij opinię"
        static let feedbackUnavailable = "Nie można otworzyć aplikacji pocztowej."
    }

    enum About {
        static let title = "O aplikacji"
        static let privacySection = "Prywatność"
        static let appSection = "Aplikacja"
        static let voiceSection = "Głos"
        static let feedbackSection = "Opinia"
        static let quickLaunchSection = "Szybki start"
        static let translationSection = "Tłumaczenie"
        static let nameLabel = "Nazwa"
        static let versionLabel = "Wersja"
        static let buildLabel = "Build"
        static let privacyBody = """
        Głos służy do rozpoznawania mowy. Tekst może być wysłany do usługi tłumaczenia. Konto nie jest wymagane. Historia i ulubione są przechowywane tylko na tym urządzeniu.
        """
        static let quickLaunchBody = """
        Dodaj skrót „Tryb ratunkowy” w aplikacji Skróty, przypisz go do przycisku Action (iPhone 15 Pro i nowsze) albo powiedz do Siri: „Uruchom tryb ratunkowy w TalkRescue”. Aplikacja otworzy się i od razu zacznie nasłuch.
        """
        static let translationBody = """
        Polska mowa jest rozpoznawana na iPhonie. Rozpoznany tekst może zostać wysłany do usługi tłumaczenia, aby uzyskać angielski. Tłumaczenie wymaga internetu.
        """
    }

    enum Permissions {
        static let recoveryTitle = "Dostęp do mikrofonu jest wyłączony"
        static let recoveryDescription =
            "Aby korzystać z TalkRescue, włącz Mikrofon i Rozpoznawanie mowy w Ustawieniach."
        static let openSettings = "Otwórz ustawienia"
        static let recheck = "Sprawdź ponownie"
    }

    enum Errors {
        static let translationNotConfigured = "Usługa tłumaczenia nie jest skonfigurowana."
        static let translationUnauthorized = "Usługa tłumaczenia jest niedostępna. Spróbuj ponownie później."
        static let translationRateLimited = "Zbyt wiele prób. Spróbuj za chwilę."
        static let invalidTranslationRequest = "Nie udało się przetłumaczyć tej wypowiedzi. Spróbuj krócej."
        static let networkFailed = "Brak połączenia. Sprawdź internet i spróbuj ponownie."
        static let translationTimedOut = "Tłumaczenie trwało zbyt długo. Sprawdź internet i spróbuj ponownie."
        static let emptyTranslation = "Odpowiedź tłumaczenia była pusta."
        static let translationFailed = "Tłumaczenie nie powiodło się."
    }
}
