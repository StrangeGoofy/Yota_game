export default class CurrentTurn {
	constructor(player_id) {
		this.player_id = player_id;
		// Массив объектов { card, x, y } – карты, сыгранные в этом ходе
		this.cards = [];
	}

	// Добавление карты в текущий ход
	addCard(card, x, y) {
		this.cards.push({ card, x, y });
	}
}
