-- Developer Products (zakupy za Robux).
-- Wpisz tu ID produktów utworzonych w Creator Hub:
-- Creator Hub -> Twoja gra -> Monetization -> Developer Products.
-- productId = 0 oznacza, że produkt jest wyłączony.
return {
	-- Podnosi fabrykę o jeden poziom bez płacenia surowcami.
	FactoryUpgrade = {
		productId = 0,
	},
	-- Daje gotówkę równą X sekundom produkcji fabryki (rośnie razem z fabryką).
	CashPack = {
		productId = 0,
		incomeSeconds = 600,
	},
	-- Game Pass (jednorazowy zakup na zawsze): Brainrot Karabin Maszynowy.
	-- Creator Hub -> Twoja gra -> Monetization -> Passes. Dopóki jest 0, w Studio broń
	-- można wziąć za darmo do testów, a w opublikowanej grze przycisk pokazuje „Wkrótce”.
	BrainrotSMG = {
		gamePassId = 0,
		weaponId = "brainrotsmg",
	},
}
