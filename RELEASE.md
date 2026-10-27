# Wydanie gry: lista kroków

Kolejność ma znaczenie: najpierw publikacja (żeby gra miała ID), potem Robux i ustawienia, na końcu test i otwarcie dla wszystkich.

## 1. Publikacja miejsca

1. Otwórz `TycoonKopalnia.rbxlx` w Roblox Studio.
2. File → **Publish to Roblox As...** → *Create new experience*. Nazwa i opis są niżej, możesz je zmienić później.
3. Po publikacji gra jest prywatna. Nikt jej nie zobaczy, dopóki nie zrobisz kroku 6.

## 2. Ustawienia gry (Home → Game Settings)

- **Security → Enable Studio Access to API Services: ON**. Bez tego w Studio nie działa zapis postępu.
- **Places → (Twoje miejsce) → Server Fill / Max Players: 8**. Na wyspie jest 8 działek.
- **Avatar → Avatar Type: R15** (domyślne jest OK).
- **Permissions**: Playability **Private** do czasu testów.

## 3. Robux (Creator Hub → Twoja gra → Monetization)

1. **Passes → Create a Pass**: „Brainrot Karabin Maszynowy”, cena np. 199 R$. Włącz *Item for Sale*. Skopiuj **Pass ID**.
2. **Developer Products → Create**:
   - „Ulepszenie fabryki” (np. 49 R$),
   - „Pakiet gotówki” (np. 25 R$).
   Skopiuj ich **Product ID**.
3. Wpisz ID w `src/shared/Config/Products.lua`:
   - `FactoryUpgrade.productId`,
   - `CashPack.productId`,
   - `BrainrotSMG.gamePassId`.

   Potem przebuduj plik albo daj mi ID, a ja to zrobię.

Dopóki ID = 0, przyciski pokazują „Wkrótce”. W Studio karabin jest wtedy darmowy do testów.

## 4. Brainroty (obrazki i okrzyki)

- Serwer przy starcie sam szuka okrzyków (AssetService:SearchAudio) i obrazków (miniaturki z katalogu Robloxa) dla każdego brainrota.
- W Output zobaczysz linię `[BrainrotAssets] Znaleziono assety dla X z 6 brainrotów`.
- Jeśli coś się nie znalazło albo wygląda źle, wpisz ID ręcznie w `src/shared/Config/Weapons.lua` (`Weapons.brainrots`, pola `image` i `sound`). Ręczne ID zawsze wygrywa.
- ID znajdziesz tak: Toolbox → Marketplace → Images/Audio → wpisz nazwę → prawy klik → Copy Asset ID.

## 5. Test przed wydaniem

1. **Test → Clients and Servers → 2 Players → Start**. Sprawdź:
   - Kopanie, ulepszenie fabryki i kilofa.
   - Zakup dekoracji i obrony.
   - Zaproszenie do sojuszu: okienko Akceptuj / Ignoruj / Blokuj.
   - Rzut jajkiem w drugiego gracza.
   - Pisklaki: wyklucie, trening, napad na drugiego gracza i na dziki obóz.
   - Karabin brainrot (Test (Studio)).
2. Okno **Output** nie powinno mieć czerwonych błędów. Jeśli są, wklej je w czacie.
3. Wyjdź i wejdź ponownie, żeby sprawdzić, czy pieniądze się zapisały. Wymaga kroku 2 (API Services).

## 6. Strona gry i otwarcie

- Creator Hub → Twoja gra → **Configure → Basic Info**:
  - nazwa i opis (niżej),
  - gatunek: Tycoon,
  - urządzenia: komputer, telefon, tablet.
- **Places → Thumbnails / Icon**: wgraj `release/icon.png` (512×512) i `release/thumbnail.png` (1920×1080).
- **Questionnaire (Maturity & Compliance)**: wypełnij ankietę treści. Walka jest „kreskówkowa”, bez krwi.
- **Permissions → Public**. Gra jest wydana.

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

- Analytics w Creator Hub pokazuje, ile osób gra i kupuje.
- Nowe wersje: poprawiasz w Studio i dajesz File → Publish to Roblox. Gracze dostają nową wersję po wejściu na nowy serwer.
