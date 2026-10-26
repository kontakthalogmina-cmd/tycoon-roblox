# Tycoon: Kopalnia i Fabryka (Roblox)

Gra typu tycoon, w której celem jest zarobienie jak największej ilości pieniędzy.

## Pętla rozgrywki

1. Każdy gracz dostaje własną działkę z **fabryką** i **kopalnią**.
2. **Fabryka** co sekundę produkuje pieniądze ($). Im wyższy poziom, tym większa produkcja.
3. W **kopalni** klikasz bloki surowców, żeby je wykopać. Surowce trafiają do ekwipunku.
4. **Fabrykę ulepszasz surowcami** z kopalni albo **za Robux** (Developer Product).
5. **Pieniądze z fabryki** wydajesz na **ulepszenie kopalni** (więcej bloków, szybszy respawn, nowe surowce) i **lepsze kilofy** (kopią twardsze surowce i mocniej uderzają).
6. Ranking w tabeli graczy: `Pieniądze` (na koncie) i `Zarobione` (łącznie).

## Struktura projektu (Rojo)

```
default.project.json         mapowanie folderów na drzewo gry
src/shared/                  -> ReplicatedStorage.Shared
  Config/Ores.lua            surowce: wymagany kilof, HP, szansa, poziom kopalni
  Config/Pickaxes.lua        kilofy: poziom, siła, cena
  Config/MineLevels.lua      poziomy kopalni: cena, liczba bloków, respawn
  Config/FactoryLevels.lua   poziomy fabryki: dochód/s, koszt w surowcach
  Config/Products.lua        ID Developer Products (Robux)
  Format.lua                 formatowanie liczb (1.2K, 3.4M)
src/server/                  -> ServerScriptService.Server
  Main.server.lua            start serwera, gracze, autozapis
  Services/PlayerData.lua    DataStore: wczytywanie i zapis
  Services/PlotService.lua   budowa działek i przydział graczom
  Services/MineService.lua   bloki surowców i kopanie
  Services/FactoryService.lua  dochód i ulepszenia fabryki
  Services/ShopService.lua   kopalnia i kilofy za $
  Services/MonetizationService.lua  zakupy za Robux (ProcessReceipt)
  Services/Remotes.lua       RemoteEventy klient <-> serwer
src/client/                  -> StarterPlayerScripts.Client
  Main.client.lua            GUI: pieniądze, surowce, panel ulepszeń
```

Mapa jest budowana skryptem (8 działek), więc nie trzeba niczego ustawiać ręcznie w Studio.

## Uruchomienie

1. Zainstaluj [Rokit](https://github.com/rojo-rbx/rokit) i w folderze projektu wpisz `rokit install` (zainstaluje Rojo).
2. Zainstaluj wtyczkę Rojo do Roblox Studio (`rojo plugin install` albo z Creator Store).
3. W folderze projektu uruchom `rojo serve`.
4. Otwórz pustą grę (Baseplate) w Studio, w zakładce Rojo kliknij **Connect**.
5. Kliknij **Play**.

Alternatywnie zbuduj plik gry: `rojo build -o TycoonKopalnia.rbxl` i otwórz go w Studio.

### Zapis danych

Żeby zapis działał w Studio: opublikuj grę, potem **Game Settings -> Security -> Enable Studio Access to API Services**. Bez tego gra działa, ale postęp nie jest zapisywany.

### Zakupy za Robux

1. Opublikuj grę i w Creator Hub utwórz dwa Developer Products: „Ulepszenie fabryki” i „Pakiet gotówki”.
2. Wpisz ich ID w `src/shared/Config/Products.lua` (pole `productId`).
3. Dopóki ID = 0, przyciski Robux są wyłączone.

### Liczba graczy

Jest 8 działek, więc w **Game Settings -> Places -> Max Players** ustaw maksymalnie 8.

## Balans

Wszystkie liczby (ceny, dochody, HP surowców, koszty ulepszeń) są w `src/shared/Config/`. Żeby dodać nowy surowiec, dopisz go w `Ores.lua`, a następnie użyj jego `id` w kosztach `FactoryLevels.lua`. Nowy kilof dodajesz w `Pickaxes.lua`.

## Bezpieczeństwo

Cała logika (kasa, kopanie, zakupy) liczy się na serwerze. Klient tylko wysyła prośby („ulepsz”, „kup kilof”), a serwer sprawdza, czy gracza na to stać. Zakupy za Robux są potwierdzane dopiero po zapisaniu danych, a ID transakcji są pamiętane, żeby nie przyznać nagrody dwa razy.

## Pomysły na dalszy rozwój

- Globalny ranking (OrderedDataStore) najbogatszych graczy.
- Rebirth: reset postępu za stały mnożnik dochodu.
- Kilof jako Tool z animacją uderzenia i dźwiękami.
- Gamepassy (np. x2 dochód, auto-kopanie).
- Model fabryki zmieniający wygląd wraz z poziomem.
