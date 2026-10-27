# Wydanie gry na Robloxa: krok po kroku

Nazwy menu podaję z polskiego Studio, a w nawiasie z angielskiego. Kolejność ma znaczenie: najpierw publikacja (wtedy gra dostaje swój numer), potem ustawienia i Robux, na końcu test i otwarcie gry dla wszystkich.

## 1. Publikacja (gra zostaje prywatna)

1. Otwórz `TycoonKopalnia.rbxlx` w Roblox Studio.
2. Wybierz **Plik → Opublikuj w Roblox jako…** (*File → Publish to Roblox As…*).
3. Kliknij **Utwórz nowe doświadczenie** (*Create new experience*), wpisz nazwę z dołu tej strony i kliknij **Utwórz**.
4. Gra jest teraz na Robloxie, ale **prywatna**. Nikt jej nie zobaczy, dopóki nie zrobisz kroku 6.

Od tej chwili po każdej zmianie wystarczy **Plik → Opublikuj w Roblox** (*Publish to Roblox*, Alt+P).

## 2. Ustawienia gry

W Studio: zakładka **Strona główna → Ustawienia gry** (*Home → Game Settings*).

- **Bezpieczeństwo** (*Security*): włącz **dostęp Studio do usług API** (*Enable Studio Access to API Services*). Bez tego postęp nie zapisuje się podczas testów w Studio. Na prawdziwych serwerach zapis działa zawsze.
- **Miejsca** (*Places*) → Twoje miejsce → **Maksymalna liczba graczy**: **8**. Na wyspie jest 8 działek.
- Kliknij **Zapisz**.

## 3. Muzyka, okrzyki i obrazki brainrotów (samo się robi)

Po publikacji serwer przy każdym starcie sam szuka w Sklepie twórcy Robloxa:

- spokojnej muzyki w tle i szybkiej muzyki na napady,
- okrzyków i obrazków brainrotów do karabinu.

Sprawdź to tak: **Okno → Wyjście**, potem ▶ **Graj**. Po kilku sekundach powinny pojawić się linie:

- `[BrainrotAssets] Muzyka calm: …` i `Muzyka raid: …`
- `[BrainrotAssets] Znaleziono assety dla X z 6 brainrotów.`

Jeśli coś nie pasuje (na przykład muzyka jest brzydka albo brainrot ma zły obrazek), wpisz konkretne ID ręcznie. Ręczne ID zawsze wygrywa.

1. W **Przyborniku** (*Toolbox*) otwórz **Sklep twórcy → Dźwięk** (muzyka lub efekty) albo **Zasoby 2D** (obrazki).
2. Wpisz nazwę, na przykład `cappuccino assassino`, i posłuchaj wyników.
3. Prawy klik na wybranym → **Kopiuj ID zasobu** (*Copy Asset ID*).
4. Wklej ID:
   - muzykę do `src/shared/Config/Music.lua`, w pole `id`, jako `"rbxassetid://ID"`;
   - brainroty do `src/shared/Config/Weapons.lua`, w pola `sound` i `image`.

   Możesz też po prostu wysłać mi te ID, a ja je wpiszę.

Przycisk 🎵 w prawym dolnym rogu ekranu wycisza muzykę.

## 4. Robux (opcjonalnie, można później)

Na stronie **create.roblox.com → Kreacje → Twoja gra → Monetyzacja** (*Creations → Monetization*):

1. **Przepustki** (*Passes*) → **Utwórz przepustkę**:
   - nazwa „Brainrot Karabin Maszynowy”, cena na przykład 199 R$;
   - włącz **Na sprzedaż** (*Item for Sale*);
   - skopiuj **ID przepustki**.
2. **Produkty dewelopera** (*Developer Products*) → **Utwórz**:
   - „Ulepszenie fabryki”, na przykład 49 R$;
   - „Pakiet gotówki”, na przykład 25 R$.

   Skopiuj ich ID.
3. Wyślij mi te trzy ID, a ja wpiszę je w `src/shared/Config/Products.lua` i przygotuję nowy plik.

Dopóki tych ID nie ma, przyciski Robux pokazują „Wkrótce”. Reszta gry działa normalnie, więc z tym krokiem możesz poczekać.

## 5. Test przed otwarciem

1. W Studio: **Test → Klienci i serwery → 2 graczy → Start** (*Clients and Servers*). Otworzą się dwa okna gry. Sprawdź:
   - kopanie, ulepszenie fabryki i kilofa;
   - zakup dekoracji i obrony;
   - zaproszenie do sojuszu (okienko Akceptuj / Ignoruj / Blokuj);
   - rzut jajkiem w drugiego gracza;
   - napad: muzyka powinna zmienić się na szybką;
   - pisklaki: wyklucie, trening, atak na dziki obóz i na drugiego gracza;
   - karabin brainrot (przycisk „Test (Studio)”).
2. W oknie **Wyjście** nie powinno być czerwonych błędów. Jeśli są, wklej mi zrzut.
3. Zagraj w opublikowaną grę z poziomu strony Robloxa. Zarób trochę pieniędzy, wyjdź i wejdź ponownie: pieniądze powinny zostać.

## 6. Strona gry i otwarcie dla wszystkich

Na stronie **create.roblox.com → Kreacje → Twoja gra**:

1. **Konfiguracja → Podstawowe informacje** (*Configure → Basic Info*):
   - wklej nazwę i opis z dołu tej strony;
   - gatunek: **Tycoon**;
   - urządzenia: komputer, telefon, tablet.
2. **Ikona i miniaturki** (*Icon / Thumbnails*): wgraj `release/icon.png` oraz `release/thumbnail.png`.
3. **Ankieta o treściach** (*Maturity & Compliance Questionnaire*): wypełnij ją uczciwie. W grze jest kreskówkowa walka bez krwi, bez czatu głosowego i bez zakupów losowych.
4. **Dostęp** (*Audience / Permissions*): przełącz grę na **Publiczna** (*Public*) i zapisz.

Gotowe, gra jest wydana! Link do niej znajdziesz na stronie gry w Creator Hub.

## Proponowana nazwa i opis

**Nazwa:** 🥚 Brainrot Egg Tycoon: Kopalnia i Pisklaki

**Opis:**
> Zbuduj najbogatszą fabrykę jajek na latającej wyspie!
> 🥚 Fabryka robi jajka, a taśma zamienia je w pieniądze. Rzadkie jajka są warte nawet x200!
> ⛏️ Kop rudy w kopalni i ulepszaj fabrykę.
> 🐣 Wykluwaj pisklaki, trenuj je i napadaj na bazy innych graczy.
> 🤝 Zawieraj sojusze i atakujcie razem.
> 🛡️ Broń bazy minami, działami i wieżami czarodzieja.
> 🎯 Rzucaj jajkami w innych i strzelaj z Brainrot Karabinu Maszynowego!
> 🌸 Upiększ bazę dekoracjami.

## Po wydaniu

- **Analityka** (*Analytics*) w Creator Hub pokazuje, ile osób gra i ile kupuje.
- Nową wersję wydajesz tak: poprawiasz w Studio i klikasz **Plik → Opublikuj w Roblox**. Gracze dostaną ją po wejściu na nowy serwer.
