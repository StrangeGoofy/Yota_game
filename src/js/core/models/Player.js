export default class Player {
	constructor(id, nickname, score) {
		this.id = id;
		this.nickname = nickname;
		this.cards = []; // Карты в руке
		this.score = score;
	}

	// Добавление карты в руку
	addCard(card) {
		this.cards.push(card);
	}

	// Удаление карты из руки по индексу
	removeCard(index) {
		// console
		if (index >= 0 && index < this.cards.length) {
			return this.cards.splice(index, 1)[0];
		}
		return null;
	}
}
