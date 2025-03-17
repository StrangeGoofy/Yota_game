import GameField from './models/GameField.js';
import Player from './models/Player.js';
import CurrentTurn from './models/CurrentTurn.js';
import { getCandidateCells } from './Validate.js';
import { generateDeck, shuffle } from './Utils.js';

import { updateGameState } from '../Api.js';

export default class Engine {
	constructor(mode = 'singleplayer', gameId) {
		this.mode = mode;
		if (this.mode === 'multiplayer') {
			this.initMultiplayer(gameId);
		} else {
			this.initSingleMode();
		}
	}

	initSingleMode() {
		this.gameField = new GameField();

		this.deck_cards = shuffle(generateDeck());
		this.deck_cards_count = this.deck_cards.length;

		// Инициализируем игроков (пример: два игрока)
		this.players = [new Player(1, 'Alice'), new Player(2, 'Bob')];
		this.currentTurn = new CurrentTurn(this.players[0].id);

		// Раздаем по 4 карты каждому игроку
		this.players.forEach((player) => {
			for (let i = 0; i < 4; i++) {
				const card = this.deck_cards.shift();
				player.addCard(card);
			}
		});

		// Обновляем количество карт в колоде после раздачи
		this.deck_cards_count = this.deck_cards.length;

		// Первая карта из колоды ставится сразу на поле в ячейку (0,0)
		const firstCard = this.deck_cards.shift();
		this.gameField.placeCard(firstCard, 0, 0);

		// Формируем состояние игры (GameState)
		this.gameState = {
			players: this.players.map((p) => ({
				id: p.id,
				nickname: p.nickname,
				cards_count: p.cards_count,
				score: p.score,
			})),
			player_id: this.players[0].id,
			current_turn_id: this.currentTurn.player_id,
			table_cards: this.gameField.cells,
			deck_cards: this.deck_cards,
			deck_cards_count: this.deck_cards.length,
			hands_cards: this.players[0].cards, // рука текущего игрока
			time: Date.now(),
		};

		console.log('Инициализирована игра:', this.gameState);
	}

	initMultiplayer(gameId) {
		// Начальная загрузка состояния игры
		updateGameState(gameId).then((data) => {
			this.gameState = data;
			this.gameField = new GameField(this.gameState.table_cards);

			this.players = data.players.map((player) => new Player(player.id, player.nickname));

			this.currentTurn = new CurrentTurn(data.current_turn_id);
			this.hands_cards = data.hands_cards;

			console.log(this.gameField.cells.length);
			console.log('Инициализирована мультиплеерная игра:', this.gameState);
		});

		// Периодическое обновление состояния каждые 3 секунды
		setInterval(() => {
			updateGameState(gameId).then((data) => {
				this.gameState = data;
				console.log('Обновлено состояние мультиплеерной игры:', this.gameState);
			});
		}, 3000);
	}

	playCardFromHand(cardIndex, x, y) {
		// if (this.mode === 'multiplayer') {
		// 	console.warn('В мультиплеерном режиме ход выполняется через API');
		// 	return;
		// }

		// 1. Проверяем, что текущий игрок имеет ход
		console.log(this.gameState.players);
		const currentPlayer = this.players.find((p) => p.id === this.gameState.player_id);
		if (!currentPlayer) {
			console.error('Текущий игрок не найден');
			return;
		}

		if (this.gameState.current_turn_id !== currentPlayer.id) {
			console.error('Сейчас не ваш ход');
			return;
		}
		console.log(this.gameState.hands_cards);
		// // 2. Проверяем, что у игрока есть карта с заданным индексом
		// if (cardIndex < 0 || cardIndex >= currentPlayer.cards.length) {
		// 	console.error('Нет карты с таким индексом в руке');
		// 	return;
		// }
		const card = this.hands_cards[cardIndex];
		console.log(currentPlayer);

		// 3. Валидируем правило: карта должна касаться хотя бы одной уже поставленной
		const placedCells = this.gameField.cells.filter((cell) => cell.card);
		const candidates = getCandidateCells(placedCells);
		const isCandidate = candidates.some((candidate) => candidate.x === x && candidate.y === y);
		if (!isCandidate) {
			alert('Выбранная ячейка не является допустимой для размещения карты');
			console.error('Выбранная ячейка не является допустимой для размещения карты');
			return;
		}

		// 4. Удаляем карту из руки, размещаем её на поле и добавляем в текущий ход
		currentPlayer.removeCard(cardIndex);
		this.gameField.placeCard(card, x, y);
		this.currentTurn.addCard(card, x, y);

		// Обновляем состояние игры
		this.gameState.hands_cards = currentPlayer.cards;
		this.gameState.table_cards = this.gameField.cells;
		console.log(`Карта ${card.shape} ${card.color} ${card.number} поставлена в (${x}, ${y})`);
	}

	undoTurn() {
		if (this.mode === 'multiplayer') {
			console.warn('В мультиплеерном режиме ход выполняется через API');
			return;
		}
		if (this.currentTurn.cards.length === 0) {
			alert('Нет ходов для отмены');
			console.error('Нет ходов для отмены');
			return;
		}
		// Извлекаем последний сыгранный ход
		const lastMove = this.currentTurn.cards.pop(); // { card, x, y }
		// Находим индекс ячейки, в которую была поставлена карта
		const cellIndex = this.gameField.cells.findIndex(
			(cell) => cell.x === lastMove.x && cell.y === lastMove.y
		);
		if (cellIndex > -1) {
			// Удаляем ячейку полностью
			this.gameField.cells.splice(cellIndex, 1);
		}
		// Возвращаем карту обратно в руку текущего игрока
		const currentPlayer = this.players.find((p) => p.id === this.gameState.player_id);
		currentPlayer.cards.push(lastMove.card);

		console.log(
			`Отменён ход: карта ${lastMove.card.shape} ${lastMove.card.color} ${lastMove.card.number} убрана с (${lastMove.x}, ${lastMove.y})`
		);
	}

	/**
	 * Завершает ход текущего игрока:
	 * 1) Если игрок сыграл хоть одну карту, добавляет недостающие карты до 4.
	 * 2) Если не сыграл ни одной карты, фактически "пропускает ход".
	 * 3) Передаёт ход следующему игроку.
	 */
	finishTurn() {
		if (this.mode === 'multiplayer') {
			console.warn('В мультиплеерном режиме ход завершается через API');
			return;
		}
		const currentPlayer = this.players.find((p) => p.id === this.gameState.player_id);
		if (this.currentTurn.cards.length > 0) {
			// Добавляем недостающие карты до 4 для игрока, который сделал ход
			while (currentPlayer.cards.length < 4 && this.deck_cards.length > 0) {
				currentPlayer.addCard(this.deck_cards.shift());
			}
		} else {
			console.log('Ход пропущен. Игрок не сыграл ни одной карты.');
		}
		// Передача хода следующему игроку
		this.passTurn();
	}

	/**
	 * Передаёт ход следующему игроку.
	 */
	passTurn() {
		if (this.mode === 'multiplayer') {
			console.warn('В мультиплеерном режиме передача хода осуществляется через API');
			return;
		}
		let currentIndex = this.players.findIndex((p) => p.id === this.gameState.player_id);
		let nextIndex = (currentIndex + 1) % this.players.length;
		const nextPlayer = this.players[nextIndex];

		// Передаем идентификатор следующего игрока
		this.gameState.player_id = nextPlayer.id;
		this.gameState.current_turn_id = nextPlayer.id;

		// Инициализируем новый текущий ход для следующего игрока
		this.currentTurn = new CurrentTurn(nextPlayer.id);

		// Обновляем состояние руки, чтобы отобразить карты следующего игрока
		this.gameState.hands_cards = nextPlayer.cards;

		console.log('Ход передан следующему игроку:', nextPlayer.nickname);
	}

	swapCards(selectedIndices) {
		if (this.mode === 'multiplayer') {
			console.warn('В мультиплеерном режиме обмен карт осуществляется через API');
			return;
		}
		const currentPlayer = this.players.find((p) => p.id === this.gameState.player_id);
		if (!currentPlayer) {
			console.error('Текущий игрок не найден');
			return;
		}

		if (!Array.isArray(selectedIndices) || selectedIndices.length === 0) {
			console.log('Нет выбранных карт для обмена. Пропуск хода.');
			this.passTurn();
			return;
		}

		// Чтобы удалять карты без смещения индексов, сортируем по убыванию
		selectedIndices.sort((a, b) => b - a);
		let numSwapped = 0;
		for (const index of selectedIndices) {
			if (index < 0 || index >= currentPlayer.cards.length) continue;
			// Удаляем карту из руки и помещаем её в конец колоды
			const card = currentPlayer.cards.splice(index, 1)[0];
			this.deck_cards.push(card);
			numSwapped++;
		}

		// Из колоды извлекаем столько новых карт, сколько было обменяно
		for (let i = 0; i < numSwapped; i++) {
			if (this.deck_cards.length > 0) {
				// Предполагается, что верх колоды находится в начале массива (shift)
				const newCard = this.deck_cards.shift();
				currentPlayer.cards.push(newCard);
			}
		}

		// Обновляем состояние игры
		this.gameState.hands_cards = currentPlayer.cards;
		console.log(`Обменено ${numSwapped} карты(к).`);

		// Передаём ход следующему игроку
		this.passTurn();
	}
}
