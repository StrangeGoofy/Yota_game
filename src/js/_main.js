import Engine from './core/Engine.js';
import GameFieldView from './views/GameFieldView.js';
import PlayerHandsView from './views/PlayerHandsView.js';
import Camera from './controllers/Camera.js';
import { recalcDimensions } from './views/config.js';

const engine = new Engine('multiplayer', 1);

let selectedCardIndex = null;
// Для обмена карт можно хранить массив выбранных индексов
let swapSelectedIndices = [];

// Функция обновления отрисовки всех компонентов и текста кнопки
function updateViews() {
	playerHand.render();
	gameField.render();
	updateTurnButtonText();
}

const playerHand = new PlayerHandsView(engine.gameState, (card, index, e) => {
	// Обработка клика по карточке руки –	 переключаем выделение
	const cardElement = e.currentTarget;

	if (document.body.classList.contains('swap-mode')) {
		// Переключаем выделение для обмена
		if (cardElement.classList.contains('selected')) {
			cardElement.classList.remove('selected');
			swapSelectedIndices = swapSelectedIndices.filter((i) => i !== index);
		} else {
			cardElement.classList.add('selected');
			swapSelectedIndices.push(index);
		}
	} else {
		// Режим обычного хода: выделение одной карты для постановки
		if (cardElement.classList.contains('selected')) {
			cardElement.classList.remove('selected');
			selectedCardIndex = null;
			gameField.render(selectedCardIndex !== null);
		} else {
			// Снимаем выделение с других карточек
			const handContainer = document.getElementById('player-hand');
			handContainer
				.querySelectorAll('.card.selected')
				.forEach((el) => el.classList.remove('selected'));
			cardElement.classList.add('selected');
			selectedCardIndex = index;
			gameField.render(selectedCardIndex !== null);
		}
	}
});

const gameField = new GameFieldView(engine.gameField, 'game-field', (cellDiv, x, y) => {
	// Если выделена карта, размещаем её по координатам ячейки
	if (selectedCardIndex !== null) {
		engine.playCardFromHand(selectedCardIndex, x, y);
		selectedCardIndex = null;
		// Перерисовываем игровое поле и руку
		updateViews();
		camera.autoFit(engine.gameField.cells);
	}
});

const turnButton = document.getElementById('finishTurnButton');
function updateTurnButtonText() {
	if (engine.currentTurn.cards.length === 0) {
		turnButton.textContent = 'Пропустить ход';
	} else {
		turnButton.textContent = 'Завершить ход';
	}
}

updateViews();

// Обработчик кнопки "Завершить ход"
document.getElementById('finishTurnButton').addEventListener('click', () => {
	engine.finishTurn();
	camera.autoFit(engine.gameField.cells);
	updateViews();
});

// Обработчик кнопки "Отменить действие"
document.getElementById('undoButton').addEventListener('click', () => {
	engine.undoTurn();
	camera.autoFit(engine.gameField.cells);
	updateViews();
});

// Обработчик кнопки "Поменять карты" с переключением режима обмена
document.getElementById('swapCards').addEventListener('click', () => {
	const swapButton = document.getElementById('swapCards');
	if (!document.body.classList.contains('swap-mode')) {
		// Включаем режим обмена
		document.body.classList.add('swap-mode');
		swapButton.textContent = 'Не изменять карты';
		// Динамически создаём кнопку "Подтвердить обмен", если её ещё нет
		let confirmButton = document.getElementById('confirm-swap');
		if (!confirmButton) {
			confirmButton = document.createElement('button');
			confirmButton.id = 'confirm-swap';
			confirmButton.textContent = 'Подтвердить обмен';
			// Можно добавить в нужное место на странице; здесь просто добавляем в body
			document.getElementsByClassName('ui')[0].appendChild(confirmButton);
			confirmButton.addEventListener('click', () => {
				engine.swapCards(swapSelectedIndices);
				// Выключаем режим обмена
				document.body.classList.remove('swap-mode');
				swapSelectedIndices = [];
				swapButton.textContent = 'Поменять карты';
				confirmButton.remove();
				updateViews();
			});
		}
	} else {
		// Если режим уже включён – выключаем его
		document.body.classList.remove('swap-mode');
		swapSelectedIndices = [];
		swapButton.textContent = 'Поменять карты';
		let confirmButton = document.getElementById('confirm-swap');
		if (confirmButton) {
			confirmButton.remove();
		}
		updateViews();
	}
});

const camera = new Camera('game-field', updateViews);
camera.autoFit(engine.gameField.cells);

window.addEventListener('resize', () => {
	// Обновляем размеры окна в объекте dimensions, если это требуется
	recalcDimensions();
	// Применяем трансформацию камеры для корректного позиционирования
	camera.applyTransform();

	// Перерисовываем все компоненты с учетом новых размеров
	updateViews();
});
