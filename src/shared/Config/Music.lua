-- Muzyka w tle. Gdy pole id jest puste, serwer przy starcie sam szuka utworu w Creator Store
-- Robloxa (tylko w opublikowanej grze), próbując kolejnych słów z keywords.
-- Żeby wybrać konkretny utwór: Przybornik → Sklep twórcy → Dźwięk → Muzyka → prawy klik
-- na utworze → Kopiuj ID zasobu, i wpisz tu "rbxassetid://ID". Ręczne ID zawsze wygrywa.
local Music = {}

Music.tracks = {
	-- Spokojna, przyjemna muzyka na co dzień.
	calm = { id = "", volume = 0.25, keywords = { "happy ukulele", "cheerful", "relaxing", "chill" } },
	-- Szybka muzyka podczas napadu i bitwy pisklaków.
	raid = { id = "", volume = 0.35, keywords = { "epic battle", "action", "boss fight", "intense" } },
}

Music.minDuration = 60 -- sekundy; krótsze nagrania to efekty, nie muzyka
Music.fadeTime = 1.5 -- płynne przejście między utworami

return Music
