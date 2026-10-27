-- Muzyka w tle. Puste id = brak muzyki.
-- Żeby dodać utwór: Przybornik → Sklep twórcy → Dźwięk → Muzyka → prawy klik
-- na utworze → Kopiuj ID zasobu, i wpisz tu "rbxassetid://ID".
local Music = {}

Music.tracks = {
	-- Spokojna, przyjemna muzyka na co dzień.
	calm = { id = "", volume = 0.25 },
	-- Szybka muzyka podczas napadu i bitwy pisklaków.
	raid = { id = "", volume = 0.35 },
}

Music.fadeTime = 1.5 -- płynne przejście między utworami

return Music
