export default class Cell {
	constructor(x, y) {
		this.x = x;
		this.y = y;
		this.card = null; // Изначально ячейка пуста
	}

	// Размещает карту в ячейке
	setCard(card) {
		this.card = card;
	}
}
