import GameField from './models/GameField.js';
import Player from './models/Player.js';
import CurrentTurn from './models/CurrentTurn.js';
import { getCandidateCells } from './Validate.js';
import { generateDeck, shuffle } from './Utils.js';


import { updateGameState } from '../Api.js';
import { playCards } from '../Api.js';
import { passTurn } from '../Api.js';
import { swapCards } from '../Api.js';
import { exitLobby } from '../Api.js';

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

export default class Engine {
	constructor() {
		this.previousTurnId = null;
	}

	// инициализация игры
	async init() {
		const response = await updateGameState();
		this.gameState = response;
		this.gameField = new GameField(this.gameState.table_cards);
		this.players = this.gameState.players.map((player) => new Player(player.id, player.nickname));
		this.currentTurn = new CurrentTurn(this.gameState.current_turn_id);
		this.hands_cards = this.gameState.hands_cards;
	}

	// обновление данных клиента
	async update() {
		const response = await updateGameState();
		const currentTurnId = response.current_turn_id;

		this.gameState = response;
		this.players = this.gameState.players.map((player) => new Player(player.id, player.nickname, player.score));
		// проверка смены хода
		if (currentTurnId !== this.previousTurnId) {
			console.log('ход сменился...');
			this.gameField = new GameField(this.gameState.table_cards);
			this.hands_cards = this.gameState.hands_cards;
			this.currentTurn = new CurrentTurn(this.gameState.current_turn_id);
		}
		this.previousTurnId = currentTurnId;
	}

	//
	playCardFromHand(cardIndex, x, y) {
		const currentPlayer = this.players.find((p) => p.id === this.gameState.player_id);
		currentPlayer.cards = this.hands_cards;

		// console.log('pid ', currentPlayer);

		if (this.gameState.current_turn_id !== this.gameState.player_id) {
			console.warn('Не ваш ход');
			showToast('Не ваш ход');
			return;
		}

		const card = this.hands_cards[cardIndex];
		if (!card) {
			console.error('Карта не найдена');
			showToast('Карта не найдена');
			return;
		}

		// Удаляем карту из руки и добавляем её в локальное поле
		currentPlayer.removeCard(cardIndex);
		this.hands_cards = currentPlayer.cards;
		// console.log('CT: ', this.gameState.CurrentTurn);
		this.gameState.hands_cards = currentPlayer.cards;
		this.gameField.placeCard(card, x, y);
		this.currentTurn.addCard(card, x, y);
		this.gameState.CurrentTurn = this.currentTurn;
	}

	//вернуть последнюю карту в руку
	undoTurn() {
		// console.log(this.currentTurn.cards);
		if (this.currentTurn.cards.length === 0) {
			showToast('Нет ходов для отмены');
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
		this.hands_cards.push(lastMove.card);

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
		if (this.currentTurn.cards.length === 0) {
			passTurn()
			updateGameState().then((data) => {
				this.gameState = data;
				this.gameField = new GameField(data.table_cards);
				this.players = data.players.map((p) => new Player(p.id, p.nickname));
				this.currentTurn = new CurrentTurn(data.current_turn_id);
				this.hands_cards = data.hands_cards;
			});
			return;
		}

		console.log('playedCards:', this.currentTurn.cards);

		const payload = this.currentTurn.cards.map(({ x, y, card }) => ({
			x,
			y,
			card_id: card.id
		}));

		playCards(payload)
			.then((response) => {
				if (response.success) {
					console.log('Ход завершён успешно');

					updateGameState().then((data) => {
						this.gameState = data;
						this.gameField = new GameField(data.table_cards);
						this.players = data.players.map((p) => new Player(p.id, p.nickname));
						this.currentTurn = new CurrentTurn(data.current_turn_id);
						this.hands_cards = data.hands_cards;

						if (this._onUpdate) this._onUpdate();
					});
				} else {
					console.error('Ошибка от сервера:', response.error);
					showToast('Такой ход невозможен');
					this._rollbackPlayedCards();
				}
			})
			.catch((err) => {
				console.error('Ошибка отправки:', err);
				alert('Ошибка связи с сервером');
				this._rollbackPlayedCards();
			});
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

		const cardsToSwap = selectedIndices.map(i => ({ card_id: this.hands_cards[i].id }));
		console.log('Cards to swap', cardsToSwap);

		swapCards(cardsToSwap).then((response) => {
			if (response.success) {
				console.log('Ход завершён успешно');

				updateGameState().then((data) => {
					this.gameState = data;
					this.gameField = new GameField(data.table_cards);
					this.players = data.players.map((p) => new Player(p.id, p.nickname));
					this.currentTurn = new CurrentTurn(data.current_turn_id);
					this.hands_cards = data.hands_cards;

					if (this._onUpdate) this._onUpdate();
				});
			} else {
				console.error('Ошибка от сервера:', response.error);
				showToast('Такой ход невозможен');
				this._rollbackPlayedCards();
			}
		})
			.catch((err) => {
				console.error('Ошибка отправки:', err);
				alert('Ошибка связи с сервером');
				this._rollbackPlayedCards();
			});
		// Обновляем состояние игры
		this.gameState.hands_cards = currentPlayer.cards;
		console.log(`Обменено ${selectedIndices.length} карты(к).`);

		// Передаём ход следующему игроку
		this.passTurn();
	}

	exitLobby() {
		exitLobby().then((response) => {
			if (response.success) {
				console.log('Игрок вышел');

				updateGameState();
			} else {
				console.error('Ошибка от сервера:', response.error);
				showToast('Такой ход невозможен');
				this._rollbackPlayedCards();
			}
		});
	}

	_rollbackPlayedCards() {
		if (this.currentTurn.cards.length === 0) return;

		const currentPlayer = this.players.find((p) => p.id === this.gameState.player_id);
		if (!currentPlayer) {
			console.error('Текущий игрок не найден');
			return;
		}

		// Возвращаем карты в руку
		this.gameField = new GameField(this.gameState.table_cards);
		this.currentTurn = new CurrentTurn(this.gameState.current_turn_id);
		this.hands_cards = this.gameState.hands_cards;

		this.gameState.table_cards = this.gameField.cells;

		if (this._onUpdate) this._onUpdate();
	}
}