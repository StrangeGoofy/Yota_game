import Card from './models/Card.js';

// Генерирует колоду из 66 карточек с различными комбинациями признаков
export function generateDeck() {
	const deck = [];
	const shapes = ['circle', 'square', 'triangle', 'cross'];
	const colors = ['red', 'blue', 'green', 'yellow'];
	const numbers = [1, 2, 3, 4];

	for (let number of numbers) {
		for (let shape of shapes) {
			for (let color of colors) {
				deck.push(new Card(shape, color, number));
			}
		}
	}

	return deck;
}

// Перемешивает массив карточек (алгоритм Фишера-Йетса)
export function shuffle(deck) {
	for (let i = deck.length - 1; i > 0; i--) {
		const j = Math.floor(Math.random() * (i + 1));
		[deck[i], deck[j]] = [deck[j], deck[i]];
	}
	return deck;
}
