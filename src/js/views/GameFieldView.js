// src/js/views/GameFieldView.js
import { dimensions } from './config.js';
import CardView from './CardView.js';
import { getCandidateCells } from '../core/Validate.js';

export default class GameFieldView {
	/**
	 * @param {Object} gameField - Объект игрового поля, содержащий массив ячеек:
	 *   { cells: [ { x, y, card } ] }
	 * @param {HTMLElement|string} container - id или DOM-элемент контейнера (по умолчанию 'game-field')
	 * @param {Function} [onCellClick] - callback при клике по ячейке, получает (cellDiv, x, y)
	 */
	constructor(gameField, container = 'game-field', onCellClick = null) {
		//this.gameField = gameField; // gameField.cells – массив ячеек, в которых уже стоят карточки
		this.container = typeof container === 'string' ? document.getElementById(container) : container;
		this.onCellClick = onCellClick;
		this.setField(gameField);
	}

	setField(gameField) {
		this.gameField = gameField;
	}

	setPendingCards(cards) {
		this.pendingCards = cards;
	}

	/**
	 * Отрисовка фоновой сетки.
	 * Вычисляет минимальные и максимальные координаты ячеек с карточками и
	 * добавляет вокруг них отступ, который зависит от того, как изменилось поле.
	 */
	renderGrid(candidateHighlight = false) {
		// Очищаем контейнер
		this.container.innerHTML = '';

		const placedCards = this.gameField.cells;
		let minX, maxX, minY, maxY;

		if (placedCards.length > 0) {
			const xs = placedCards.map((item) => item.x);
			const ys = placedCards.map((item) => item.y);
			minX = Math.min(...xs);
			maxX = Math.max(...xs);
			minY = Math.min(...ys);
			maxY = Math.max(...ys);
		} else {
			// Если карточек нет, рисуем хотя бы одну клетку (0,0)
			minX = maxX = 0;
			minY = maxY = 0;
		}

		// Расширяем границы на 1 клетку с каждой стороны
		minX -= 1;
		maxX += 1;
		minY -= 1;
		maxY += 1;

		// Вычисляем кандидатные ячейки (только если нужна подсветка, например, когда выбрана карта из руки)
		const candidateCells = candidateHighlight ? getCandidateCells(placedCards) : [];

		// Отрисовываем ячейки только в рассчитанном диапазоне
		for (let x = minX; x <= maxX; x++) {
			for (let y = minY; y <= maxY; y++) {
				this._drawCell(x, y, candidateCells);
			}
		}
	}

	/**
	 * Вспомогательный метод для отрисовки одной клетки по координатам (x, y).
	 */
	_drawCell(x, y, candidateCells) {
		const cellDiv = document.createElement('div');
		cellDiv.classList.add('grid-cell');
		cellDiv.style.width = dimensions.cardSize + 'px';
		cellDiv.style.height = dimensions.cardSize + 'px';

		// Перевод координат клетки в пиксели.
		// Центр окна – это точка отсчёта.
		const centerX = dimensions.windowWidth / 2;
		const centerY = dimensions.windowHeight / 2;
		const left = centerX + x * dimensions.cellSize - dimensions.cardSize / 2;
		const top = centerY - y * dimensions.cellSize - dimensions.cardSize / 2;
		cellDiv.style.left = left + 'px';
		cellDiv.style.top = top + 'px';

		// Можно сохранить атрибуты координат для удобства обработки кликов
		cellDiv.dataset.x = x;
		cellDiv.dataset.y = y;

		// Если координаты ячейки содержатся в списке кандидатных – добавляем класс для подсветки
		const isCandidate = candidateCells.some((c) => c.x === x && c.y === y);
		if (isCandidate) {
			cellDiv.classList.add('highlight');
		}

		if (this.onCellClick) {
			cellDiv.addEventListener('click', () => {
				this.onCellClick(cellDiv, x, y);
			});
		}

		// Добавляем клетку в контейнер
		this.container.appendChild(cellDiv);
	}

	/**
	 * Отрисовка карточек внутри клеток.
	 * Для каждой ячейки с карточкой создаётся CardView и помещается в нужную позицию.
	 */
	renderCards() {
		// 1. Собираем все карточки, включая временные (pending)
		const allCells = [...this.gameField.cells];
	
		if (this.pendingCards?.length > 0) {
			for (const { x, y, card } of this.pendingCards) {
				allCells.push({ x, y, card });
			}
		}
	
		// 2. Отрисовываем каждую карточку
		allCells.forEach((cell) => {
			if (cell.card) {
				const cardView = new CardView(cell.card);
				const centerX = dimensions.windowWidth / 2;
				const centerY = dimensions.windowHeight / 2;
				const left = centerX + cell.x * dimensions.cellSize - dimensions.cardSize / 2;
				const top = centerY - cell.y * dimensions.cellSize - dimensions.cardSize / 2;
				cardView.element.style.position = 'absolute';
				cardView.element.style.left = left + 'px';
				cardView.element.style.top = top + 'px';
				this.container.appendChild(cardView.element);
			}
		});
	}

	/**
	 * Основной метод отрисовки игрового поля.
	 * @param {boolean} candidateHighlight – если true, подсвечиваются кандидатные ячейки.
	 */
	render(candidateHighlight = false) {
		this.renderGrid(candidateHighlight);
		this.renderCards();
	}
}
