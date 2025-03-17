import { generateCardSVG } from './SVG_Generator.js';

export default class CardView {
	/**
	 * @param {Object} card – объект карточки (например, { shape, color, number })
	 * @param {number} [index] – необязательный индекс (например, для карточек из руки)
	 * @param {Function} [onClick] – callback при клике по карточке
	 * @param {number} [cardSize] – размер карточки (по умолчанию 80)
	 */
	constructor(card, index = null, onClick = null, cardSize = 80) {
		this.card = card;
		this.index = index;
		this.onClick = onClick;
		this.cardSize = cardSize;
		this.element = document.createElement('div');
		this.element.classList.add('card');
		this.render();
		this.attachEvents();
	}

	render() {
		const svgString = generateCardSVG(this.card, this.cardSize);
		this.element.innerHTML = svgString;
		return this.element;
	}

	attachEvents() {
		this.element.addEventListener('click', (e) => {
			if (this.onClick) {
				this.onClick(this.card, this.index, e);
			}
		});
	}
}
