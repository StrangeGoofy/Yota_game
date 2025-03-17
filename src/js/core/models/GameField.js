import Cell from './Cell.js';

export default class GameField {
	constructor(cells = []) {
		this.cells = cells;
	}

	placeCard(card, x, y) {
		const cell = new Cell(x, y);
		cell.setCard(card);
		this.cells.push(cell);
	}
}
