import Engine from './core/Engine.js';
import GameFieldView from './views/GameFieldView.js';
import PlayerHandsView from './views/PlayerHandsView.js';
import UIOverlay from './views/UI_Overlay.js';
import Camera from './controllers/Camera.js';
import { recalcDimensions } from './views/config.js';

const engine = new Engine('multiplayer', 1);

let selectedCardIndex = null; // Для обычного размещения карты
let swapSelectedIndices = []; // Для режима обмена

let playerHand, gameField, camera, uiOverlay;

// Функция обновления всех представлений
function updateViews() {
	if (playerHand && gameField && uiOverlay) {
		playerHand.render();
		gameField.render();
		uiOverlay.render(engine.gameState);
	}
}

// Функция инициализации приложения, вызывается после появления engine.gameState
function initApp() {
	// Создаем представление руки игрока
	playerHand = new PlayerHandsView(engine.hands_cards, (card, index, e) => {
		// Проверка хода игрока
		if (engine.gameState.player_id != engine.gameState.current_turn_id) {
			console.warn('Не ваш ход');
			return;
		}

		const cardElement = e.currentTarget;
		// Если включен режим обмена
		if (document.body.classList.contains('swap-mode')) {
			if (cardElement.classList.contains('selected')) {
				cardElement.classList.remove('selected');
				swapSelectedIndices = swapSelectedIndices.filter((i) => i !== index);
			} else {
				cardElement.classList.add('selected');
				swapSelectedIndices.push(index);
			}
		} else {
			// Обычный режим – выбор карты для постановки на поле
			if (cardElement.classList.contains('selected')) {
				cardElement.classList.remove('selected');
				selectedCardIndex = null;
				gameField.render(selectedCardIndex !== null);
			} else {
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

	// Создаем представление игрового поля
	gameField = new GameFieldView(engine.gameField, 'game-field', (cellDiv, x, y) => {
		if (!document.body.classList.contains('swap-mode') && selectedCardIndex !== null) {
			engine.playCardFromHand(selectedCardIndex, x, y);
			selectedCardIndex = null;
			updateViews();
			camera.autoFit(engine.gameField.cells);
		}
	});

	// Инициализируем камеру
	camera = new Camera('game-field', updateViews);
	camera.autoFit(engine.gameField.cells);

	// Создаем UIOverlay, который в свою очередь создаст контейнер .ui с кнопками и будет выводить информацию
	uiOverlay = new UIOverlay({
		onEndTurn: () => {
			engine.finishTurn();
			camera.autoFit(engine.gameField.cells);
			updateViews();
		},
		onUndo: () => {
			engine.undoTurn();
			camera.autoFit(engine.gameField.cells);
			updateViews();
		},
		onSwap: () => {
			// Если режим обмена не включен – включаем его и меняем текст кнопки
			if (!document.body.classList.contains('swap-mode')) {
				document.body.classList.add('swap-mode');
				uiOverlay.swapCardsButton.textContent = 'Не изменять карты';
				// Создаем кнопку подтверждения обмена, если её ещё нет
				let confirmButton = document.getElementById('confirm-swap');
				if (!confirmButton) {
					confirmButton = document.createElement('button');
					confirmButton.id = 'confirm-swap';
					confirmButton.textContent = 'Подтвердить обмен';
					uiOverlay.container.appendChild(confirmButton);
					confirmButton.addEventListener('click', () => {
						engine.swapCards(swapSelectedIndices);
						document.body.classList.remove('swap-mode');
						swapSelectedIndices = [];
						uiOverlay.swapCardsButton.textContent = 'Поменять карты';
						confirmButton.remove();
						updateViews();
					});
				}
			} else {
				// Если режим уже включен – выключаем его
				document.body.classList.remove('swap-mode');
				swapSelectedIndices = [];
				uiOverlay.swapCardsButton.textContent = 'Поменять карты';
				let confirmButton = document.getElementById('confirm-swap');
				if (confirmButton) {
					confirmButton.remove();
				}
				updateViews();
			}
		},
	});

	updateViews();

	window.addEventListener('resize', () => {
		recalcDimensions();
		camera.applyTransform();
		updateViews();
	});
}

// Функция ожидания, пока engine.gameState не будет проинициализирован, затем вызывает callback (один раз)
function waitForGameState(callback) {
	if (engine.gameState && engine.gameState.hands_cards !== undefined) {
		callback();
	} else {
		setTimeout(() => waitForGameState(callback), 100);
	}
}

waitForGameState(initApp);
