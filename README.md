# Tycoon: Kopalnia i Fabryka (Roblox)

Gra typu tycoon, w której celem jest zarobienie jak największej ilości pieniędzy.

## Pętla rozgrywki

1. Wszyscy gracze (do 8) są na jednej latającej wyspie. Działki stoją w kręgu, a na środku jest plac ze złotym jajkiem (strefa bezpieczna).
2. Z **fabryki** wychodzi **linia produkcyjna**: co 2 sekundy taśmą jedzie jajko do skupu i zamienia się w $.
3. Jajka mają **rzadkości** (Zwykłe, Niezwykłe, Rzadkie, Epickie, Legendarne, Mityczne) z mnożnikiem wartości od x1 do x200. Każda rzadkość ma swój kolor, Legendarne mienią się tęczą, a Mityczne pulsują.
4. **Szczęście** (kupowane za $) zwiększa szansę na lepsze jajka.
5. **Skórki jajek** (kupowane za $) zmieniają wygląd jajek i podnoszą ich wartość.
6. **Kopalnia** jest w górze: tunelem z torami schodzisz do jaskini i rozbijasz skały z żyłami rudy **kilofem** trzymanym w ręce (klik lub dotknięcie = zamach; celuje w skałę pod kursorem albo najbliższą).
7. **Fabrykę ulepszasz surowcami** z kopalni albo **za Robux**. Wyższy poziom fabryki = droższe jajka.
8. Za $ ulepszasz **kopalnię** (więcej skał, nowe rudy) i kupujesz **lepsze kilofy** (twardsze rudy, mocniejsze uderzenia).
9. **Sklep** otwierasz przyciskiem na dole ekranu albo przy budce SKLEP na działce. Zakładki: Fabryka, Kopalnia, Kilofy, Szczęście, Skórki, Robux.
10. **Napady:** od poziomu fabryki 3 możesz w zakładce Napady wybrać bazę innego gracza. Trafiasz pod jego Bramę napadu i masz 90 s, żeby dobiec do **skarbca** i przytrzymać E. Udany napad zabiera ofierze 20% gotówki i 2 poziomy fabryki, a ofiara widzi nick napastnika i dostaje 10 min tarczy.
11. **Skarbiec:** za $ wzmacniasz skarbiec (dłuższy rabunek). Gdy stoisz przy swoim skarbcu, nie da się go obrabować, a w czasie napadu możesz bić napastnika kilofem. Udana obrona = brak strat.
12. **Obrona działki (zakładka 🛡️ Obrona):** miny (wybuchają pod obcym), niewidzialne pułapki (widzi je tylko właściciel, unieruchamiają), działa i wieże czarodzieja. Stoją na stałych miejscach działki i same atakują każdego obcego, który wejdzie na działkę. Każda kolejna sztuka jest droższa.
12. **Walka:** jajkiem do rzucania (bez limitu) przewracasz i odpychasz innych. Za jajka 🥚 z linii produkcyjnej kupujesz brainrot karabiny. Pokonanie gracza (także zrzucenie go z wyspy) zabiera mu 10% gotówki jako wielkie złote jajko, które trzeba donieść do swojej działki. Trafienie niosącego sprawia, że je upuszcza.
12. Kopalnia pokazuje tylko rudy potrzebne do kolejnych ulepszeń fabryki.
13. Ranking w tabeli graczy: `Pieniądze` i `Zarobione`.

## Struktura projektu (Rojo)

```
default.project.json         mapowanie folderów na drzewo gry
src/shared/                  -> ReplicatedStorage.Shared
  Config/Ores.lua            surowce: wymagany kilof, HP, szansa, poziom kopalni
  Config/Pickaxes.lua        kilofy: poziom, siła, cena
  Config/MineLevels.lua      poziomy kopalni: cena, liczba bloków, respawn
  Config/FactoryLevels.lua   poziomy fabryki: dochód/s, koszt w surowcach
  Config/Products.lua        ID Developer Products (Robux)
  Config/EggRarities.lua     rzadkości jajek: szansa i mnożnik wartości
  Config/EggSkins.lua        skórki jajek: cena, wygląd, premia
  Config/LuckLevels.lua      poziomy szczęścia: mnożnik i cena
  Config/ProductionLine.lua  tempo i prędkość taśmy
  Config/Raids.lua           napady i poziomy ochrony bazy
  Config/Weapons.lua         rzucanie jajkami, karabiny, złote jajko
  OreNeeds.lua               które rudy są jeszcze potrzebne
  EggOdds.lua                losowanie rzadkości ze szczęściem
  Format.lua                 formatowanie liczb (1.2K, 3.4M)
src/server/                  -> ServerScriptService.Server
  Main.server.lua            start serwera, gracze, autozapis
  Services/PlayerData.lua    DataStore: wczytywanie i zapis
  Services/PlotService.lua   przydział działek graczom
  Services/PlotBuilder.lua   budowa działki: teren, fabryka, taśma, kopalnia
  Services/MineService.lua   skały z rudą i kopanie
  Services/PickaxeTool.lua   kilof w ręce (Tool)
  Services/ProductionLineService.lua  jajka na taśmie
  Services/FactoryService.lua  dochód i ulepszenia fabryki
  Services/RaidService.lua   napady, wieże obronne, skarbiec
  Services/CombatService.lua rzuty jajkami, strzały, złote jajko
  Services/WeaponTools.lua   jajko i karabin w plecaku
  Services/ShopService.lua   kopalnia, kilofy, szczęście, skórki za $
  Services/MonetizationService.lua  zakupy za Robux (ProcessReceipt)
  Services/Remotes.lua       RemoteEventy klient <-> serwer
src/client/                  -> StarterPlayerScripts.Client
  Main.client.lua            GUI: pieniądze, surowce, panel ulepszeń
  Mining.client.lua          zamach kilofem i trafianie w skały
  Effects.client.lua         tęczowe i pulsujące jajka
  Combat.client.lua          rzucanie, strzelanie, przewracanie
```

Mapa jest budowana skryptem (8 działek, teren z Terrain), więc nie trzeba niczego ustawiać ręcznie w Studio.

## Uruchomienie

1. Zainstaluj [Rokit](https://github.com/rojo-rbx/rokit) i w folderze projektu wpisz `rokit install` (zainstaluje Rojo).
2. Zainstaluj wtyczkę Rojo do Roblox Studio (`rojo plugin install` albo z Creator Store).
3. W folderze projektu uruchom `rojo serve`.
4. Otwórz pustą grę (Baseplate) w Studio, w zakładce Rojo kliknij **Connect**.
5. Kliknij **Play**.

Najszybciej bez Rojo: otwórz w Studio gotowy plik `TycoonKopalnia.rbxlx` (File -> Open from File) i kliknij **Play**.

Możesz też zbudować plik gry sam: `rojo build -o TycoonKopalnia.rbxl` i otwórz go w Studio.

### Zapis danych

Żeby zapis działał w Studio: opublikuj grę, potem **Game Settings -> Security -> Enable Studio Access to API Services**. Bez tego gra działa, ale postęp nie jest zapisywany.

### Zakupy za Robux

1. Opublikuj grę i w Creator Hub utwórz dwa Developer Products: „Ulepszenie fabryki” i „Pakiet gotówki”.
2. Wpisz ich ID w `src/shared/Config/Products.lua` (pole `productId`).
3. Dopóki ID = 0, przyciski Robux są wyłączone.

### Liczba graczy

Jest 8 działek, więc w **Game Settings -> Places -> Max Players** ustaw maksymalnie 8.

## Balans

Wszystkie liczby (ceny, dochody, HP surowców, koszty ulepszeń, szanse jajek, skórki) są w `src/shared/Config/`. Żeby dodać nowy surowiec, dopisz go w `Ores.lua`, a następnie użyj jego `id` w kosztach `FactoryLevels.lua`. Nowy kilof dodajesz w `Pickaxes.lua`.

## Bezpieczeństwo

Cała logika (kasa, kopanie, zakupy) liczy się na serwerze. Klient tylko wysyła prośby („ulepsz”, „kup kilof”), a serwer sprawdza, czy gracza na to stać. Zakupy za Robux są potwierdzane dopiero po zapisaniu danych, a ID transakcji są pamiętane, żeby nie przyznać nagrody dwa razy.

## Plan kolejnych etapów

- ~~Etap 2: obrona jako osobny system~~ (zrobione: `Config/Defenses.lua`, `Services/DefenseService.lua`).
- Etap 3: pisklaki z jajek, obozy treningowe i wysyłanie piskląt na wojnę.

## Pomysły na dalszy rozwój

- Globalny ranking (OrderedDataStore) najbogatszych graczy.
- Rebirth: reset postępu za stały mnożnik dochodu.
- Dźwięki kopania i taśmy (wymagają ID dźwięków z Creator Store).
- Gamepassy (np. x2 dochód, auto-kopanie).
- Model fabryki zmieniający wygląd wraz z poziomem.
