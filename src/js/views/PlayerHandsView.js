// src/js/views/PlayerHandsView.js
import CardView from './CardView.js';

export default class PlayerHandsView {
	/**
	 * @param {Object} hands_cards – массив карт
	 * @param {Function} [onCardClick] – callback при клике по карточке руки
	 * @param {HTMLElement|string} container – id или DOM-элемент контейнера (по умолчанию 'player-hand')
	 */
	constructor(hands_cards, onCardClick = null, container = 'player-hand') {
		this.hands_cards = hands_cards;
		this.onCardClick = onCardClick;
		this.container = typeof container === 'string' ? document.getElementById(container) : container;
	}

	render() {
		this.container.innerHTML = '';
		//console.log('this.hands_cards:', this.hands_cards);
		// Проходим по массиву карт руки и создаем для каждой экземпляр CardView
		this.hands_cards.forEach((card, index) => {
			const cardView = new CardView(card, index, (card, index, e) => {
				if (this.onCardClick) {
					this.onCardClick(card, index, e);
				}
			});

			this.container.appendChild(cardView.element);
		});
	}

	removeCard(index) {
		if (index < 0 || index >= this.hands_cards.length) {
			console.warn('Индекс вне диапазона в removeCard:', index);
			return;
		}

		// Удаляем из массива
		this.hands_cards.splice(index, 1);

		// Перерисовываем руку
		this.render();
	}

	updateCards(newCards) {
		this.hands_cards = newCards;
	}
}
