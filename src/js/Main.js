import Engine from './core/Engine.js';
import GameFieldView from './views/GameFieldView.js';
import PlayerHandsView from './views/PlayerHandsView.js';
import UIOverlay from './views/UI_Overlay.js';
import Camera from './controllers/Camera.js';
import { recalcDimensions } from './views/config.js';

function showToast(message, duration = 3000) {
	const toast = document.getElementById("toast");
	toast.textContent = message;
	toast.classList.add("show");
	toast.classList.remove("hidden");

	setTimeout(() => {
		toast.classList.remove("show");
		toast.classList.add("hidden");
	}, duration);
}

const engine = new Engine();
engine.init();

let playerHand, gameField, camera, uiOverlay;

playerHand = new PlayerHandsView(engine.hands_cards, (card, index, e) => {
	// Проверка хода игрока
	if (engine.gameState.player_id != engine.gameState.current_turn_id) {
		console.warn('Не ваш ход');
		showToast('Не ваш ход');
		return;
	}

	const cardElement = e.currentTarget;

	console.log(document.body.classList.contains('swap-mode'));

	// Если включен режим обмена
	if (document.body.classList.contains('swap-mode')) {
		if (cardElement.classList.contains('selected')) {
			cardElement.classList.remove('selected');
			swapSelectedIndices = swapSelectedIndices.filter((i) => i !== index);
		} else {
			cardElement.classList.add('selected');
			// console.log('sI', swapSelectedIndices);
			swapSelectedIndices.push(index);
			console.log('sI2', swapSelectedIndices);
		}
	} else {
		// Обычный режим – выбор карты для постановки на поле
		if (cardElement.classList.contains('selected')) {
			cardElement.classList.remove('selected');
			gameField.render(selectedCardIndex !== null);
			selectedCardIndex = null;
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

gameField = new GameFieldView(engine.gameField, 'game-field', (cellDiv, x, y) => {
	if (!document.body.classList.contains('swap-mode') && selectedCardIndex !== null) {
		engine.playCardFromHand(selectedCardIndex, x, y);
		selectedCardIndex = null;
		updateViews();
		camera.autoFit(engine.gameField.cells);
	}
});

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

setInterval(() => {
	engine.update();
	console.log(engine);
	if (engine.gameState.player_id != engine.gameState.current_turn_id &&
		engine.gameState.lobby_state == "Gaming"
	) {
		updateViews();
	} else { uiOverlay.render(engine.gameState); }
}, 1000);

let selectedCardIndex = null; // Выбранная карта
let swapSelectedIndices = []; // Для режима обмена

function updateViews() {
	playerHand.updateCards(engine.hands_cards);
	gameField.setField(engine.gameField);
	playerHand.render();
	gameField.render();
	uiOverlay.render(engine.gameState);
}

// Инициализируем камеру
camera = new Camera('game-field', updateViews);
camera.autoFit(engine.gameField.cells);



updateViews();

window.addEventListener('resize', () => {
	recalcDimensions();
	camera.applyTransform();
	updateViews();
});
