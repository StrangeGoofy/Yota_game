// src/js/views/UIOverlay.js
export default class UIOverlay {
	/**
	 * @param {Object} options – конфигурация, содержащая колбэки для кнопок и прочие параметры
	 */
	constructor(options = {}) {
		// Если на странице нет контейнера с классом "ui", создаём его и добавляем в body
		this.container = document.querySelector('.ui');
		if (!this.container) {
			this.container = document.createElement('div');
			this.container.classList.add('ui');
			document.body.appendChild(this.container);
		}
		this.options = options;
		this.createUIElements();
		this.attachEvents();
	}

	createUIElements() {
		// Создаем кнопку завершения хода
		this.finishTurnButton = document.createElement('button');
		this.finishTurnButton.id = 'finishTurnButton';
		this.finishTurnButton.textContent = 'Закончить ход';
		this.container.appendChild(this.finishTurnButton);

		// Создаем кнопку отмены действия
		this.undoButton = document.createElement('button');
		this.undoButton.id = 'undoButton';
		this.undoButton.textContent = 'Отменить действие';
		this.container.appendChild(this.undoButton);

		// Создаем кнопку для обмена карт
		this.swapCardsButton = document.createElement('button');
		this.swapCardsButton.id = 'swapCards';
		this.swapCardsButton.textContent = 'Поменять карты';
		this.container.appendChild(this.swapCardsButton);

		// Создаем дополнительный div для вывода информации об игроках, колоде и времени хода
		this.infoDiv = document.createElement('div');
		this.infoDiv.classList.add('info');
		this.container.appendChild(this.infoDiv);
	}

	attachEvents() {
		this.finishTurnButton.addEventListener('click', () => {
			if (this.options.onEndTurn) {
				this.options.onEndTurn();
			}
		});
		this.undoButton.addEventListener('click', () => {
			if (this.options.onUndo) {
				this.options.onUndo();
			}
		});
		this.swapCardsButton.addEventListener('click', () => {
			if (this.options.onSwap) {
				this.options.onSwap();
			}
		});
	}

	/**
	 * Обновляет UI информацию.
	 * @param {Object} gameState - состояние игры, содержащее players, player_id, deck_cards_count, time и т.д.
	 */
	render(gameState) {
		let html = `<div class="game-info">`;
		// 1) Вывод текущего игрока (по player_id)
		const currentPlayer = gameState.players.find((p) => p.id === gameState.player_id);
		const turnPlayer = gameState.players.find((p) => p.id === gameState.current_turn_id);
		if (currentPlayer) {
			html += `<div class="current-player">
                <strong>Вы:</strong> ${currentPlayer.nickname} 
                (${currentPlayer.cards_count} карт)
								<br/>
								Ход: ${turnPlayer.nickname} 
              </div>`;
		}
		// 2) Остальные игроки (по кругу)
		html += `<div class="other-players">`;
		let currentIndex = gameState.players.findIndex((p) => p.id === gameState.player_id);
		for (let i = 1; i < gameState.players.length; i++) {
			const idx = (currentIndex + i) % gameState.players.length;
			const player = gameState.players[idx];
			html += `<div class="player-info">
                ${player.nickname}: 
                <div class="cards">`;
			// Создаем столько иконок, сколько карт (cards_count)
			for (let j = 0; j < player.cards_count; j++) {
				html += `<span class="card-icon">🂠</span>`;
			}
			html += `   </div>
              </div>`;
		}
		html += `</div>`;
		// 3) Количество карт в колоде
		html += `<div class="deck-info">Колода: ${gameState.deck_cards_count} карт</div>`;
		// 4) Текущее время хода
		html += `<div class="turn-time">Время хода: ${gameState.time}</div>`;
		html += `</div>`;

		this.infoDiv.innerHTML = html;
	}
}
