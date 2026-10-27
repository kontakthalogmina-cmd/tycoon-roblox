# Brainrot Egg Tycoon: Kopalnia i Pisklaki (Roblox)

Jak wydać grę: zobacz [RELEASE.md](RELEASE.md). Ikona i miniaturka są w `release/`.

Gra typu tycoon, w której celem jest zarobienie jak największej ilości pieniędzy.

## Pętla rozgrywki

1. Wszyscy gracze (do 8, czyli 8 fabryk na wyspę) są na jednej latającej wyspie. Działki stoją w kręgu, a na środku jest plac ze złotym jajkiem (strefa bezpieczna). **Ustaw w Game Settings → Places maks. 8 graczy na serwer.**
2. Każda baza na starcie wygląda tak samo: żywopłot dookoła, brama z nazwą właściciela, fabryka, taśma, kopalnia w górze, skarbiec, obóz pisklaków i latarnie.
3. Z **fabryki** wychodzi **linia produkcyjna**: co 2 sekundy taśmą jedzie jajko do skupu i zamienia się w $ (z dźwiękiem monety). Jajka mają **rzadkości** z mnożnikiem wartości. **Szczęście** i **skórki jajek** kupujesz za $.
4. **Kopalnia** jest w górze: tunelem schodzisz do jaskini i rozbijasz skały kilofem. **Fabrykę ulepszasz rudami** albo **za Robux** (fajerwerki przy awansie). Kopalnia pokazuje tylko rudy potrzebne do kolejnych ulepszeń.
5. **Sklep:** przycisk na dole ekranu albo budka SKLEP. Panel **🎯 Co teraz?** w lewym dolnym rogu zawsze podpowiada następny krok, a **❓ Jak grać** pokazuje krótką instrukcję.
6. **Dekoracje (🌸):** kwiaty, ławki, drzewa, flagi, fontanna i pomnik złotej kury za $. Stają w stałych miejscach, więc baza zawsze wygląda porządnie.
7. **Walka:** jajkiem (za darmo, bez limitu) przewracasz innych. Jedyna broń palna to **Brainrot Karabin Maszynowy** (Game Pass za Robux): każdy strzał to latający, kręcący się brainrot z okrzykiem. Pokonany gracz gubi 10% gotówki jako złote jajko, które trzeba donieść do swojej bazy.
8. **Obrona (🛡️):** miny, niewidzialne pułapki (widzi je tylko właściciel), działa i wieże czarodzieja same atakują obcych na działce.
9. **Pisklaki (🐣):** wykluwasz je za jajka, trenujesz w obozie (XP i poziomy) i wysyłasz na napady. Napad zabiera najwyżej **10% gotówki** celu. Kilku sojuszników może zaatakować tę samą bazę (przycisk 🤝 Dołącz) i dzielą łup po równo. Bazy bronią pisklaki w domu, budowle obronne i pisklaki sojuszników obrońcy; po przegranej obrońca ma 10 min tarczy.
10. **Sojusze (🤝):** zapraszasz gracza, a on widzi okienko **Akceptuj / Ignoruj / Blokuj** (zablokowany nie może więcej zapraszać). Sojusznicy się nie ranią, obrona ich nie atakuje, a nad głowami widać znaczek 🤝. Do 4 graczy w sojuszu.
11. **Napady na skarbiec (⚔️):** od poziomu fabryki 3 możesz też osobiście obrabować skarbiec innego gracza (90 s, przytrzymaj E). Udany napad zabiera 20% gotówki i 2 poziomy fabryki. Gdy stoisz przy swoim skarbcu, nie da się go obrabować.
12. Ranking w tabeli graczy: `Pieniądze` i `Zarobione`.

## Dźwięki

Domyślnie gra używa dźwięków wbudowanych w Robloxa (`src/shared/Config/Sounds.lua`, tam też głośność).

### Prawdziwe obrazki i okrzyki brainrotów

W `src/shared/Config/Weapons.lua` każdy brainrot (`Weapons.brainrots`) ma pola `image` i `sound`. W Roblox Studio otwórz View → Toolbox → Marketplace, wybierz Images albo Audio, wpisz nazwę (np. „tralalero tralala”, „tung tung sahur”), kliknij wynik prawym przyciskiem → Copy Asset ID i wklej jako `"rbxassetid://ID"`. Assety z Creator Store są sprawdzone przez Robloxa, więc można ich używać w grze; plików z internetu skrypt nie wgra.

## Robux

ID wpisujesz w `src/shared/Config/Products.lua`: Developer Products (ulepszenie fabryki, pakiet gotówki) i Game Pass `BrainrotSMG`. Dopóki ID = 0, w Studio karabin maszynowy można wziąć za darmo do testów.

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
- ~~Etap 3: pisklaki, obozy treningowe, wojna~~ (zrobione: `Config/Chicks.lua`, `Services/ChickService.lua`).

## Pomysły na dalszy rozwój

- Globalny ranking (OrderedDataStore) najbogatszych graczy.
- Rebirth: reset postępu za stały mnożnik dochodu.
- Dźwięki kopania i taśmy (wymagają ID dźwięków z Creator Store).
- Gamepassy (np. x2 dochód, auto-kopanie).
- Model fabryki zmieniający wygląd wraz z poziomem.
