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
		// Создаем дополнительный div для вывода информации об игроках, колоде и времени хода
		/*Блок с информацией про игроков*/
		this.infoDiv = document.createElement('div');
		this.infoDiv.classList.add('info');
		document.body.appendChild(this.infoDiv);

		/*Блок кнопок для управления игрой*/
		this.gameButtons = document.createElement('div');
		this.gameButtons.classList.add('game-buttons');

		// Создаем кнопку завершения хода
		this.finishTurnButton = document.createElement('button');
		this.finishTurnButton.id = 'finishTurnButton';
		this.finishTurnButton.classList.add('hidden');
		this.finishTurnButton.textContent = 'Закончить ход';
		this.gameButtons.appendChild(this.finishTurnButton);

		// Создаем кнопку отмены действия
		this.undoButton = document.createElement('button');
		this.undoButton.id = 'undoButton';
		this.undoButton.classList.add('hidden');
		this.undoButton.textContent = 'Отменить действие';
		this.gameButtons.appendChild(this.undoButton);

		// Создаем кнопку для обмена карт
		this.swapCardsButton = document.createElement('button');
		this.swapCardsButton.id = 'swapCards';
		this.swapCardsButton.classList.add('hidden');
		this.swapCardsButton.textContent = 'Поменять карты';
		this.gameButtons.appendChild(this.swapCardsButton);

		/*Блок вспомогательных кнопок*/
		this.utilButtons = document.createElement('div');
		this.utilButtons.classList.add('util-buttons');

		// Создаем кнопку с правилами
		this.ruleButton = document.createElement('button');
		this.ruleButton.id = 'ruleButton';
		this.ruleButton.classList.add('hidden');
		this.ruleButton.textContent = 'Правила';
		this.utilButtons.appendChild(this.ruleButton);

		// Создаем кнопку выхода из лобби
		this.exitButton = document.createElement('button');
		this.exitButton.id = 'exitButton';
		this.exitButton.classList.add('hidden');
		this.exitButton.textContent = 'Выйти';
		this.utilButtons.appendChild(this.exitButton);

		document.body.appendChild(this.gameButtons);
		document.body.appendChild(this.utilButtons);

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
		this.ruleButton.addEventListener('click', () => {
			if (this.options.onOpenRule) {
				this.options.onOpenRule();
			}
		});
		this.exitButton.addEventListener('click', () => {
			if (this.options.onExit) {
				this.options.onExit();
			}
		});
		const closeRuleModalButton = document.getElementById('closeRuleModal');
		if (closeRuleModalButton) {
			closeRuleModalButton.addEventListener('click', () => {
				const ruleModal = document.getElementById('rule_modal');
				if (ruleModal) {
					ruleModal.classList.add('hidden');
				}
			});
		}
	}

	/**
	 * Обновляет UI информацию.
	 * @param {Object} gameState - состояние игры, содержащее players, player_id, deck_cards_count, time и т.д.
	 */
	render(gameState) {
		if (gameState.lobby_state === "NotReady") {
			let html = `<div class="game-wait screen">`;
			html += `<div class="state-title">Ожидание игроков</div>`;
			let currentIndex = gameState.players.findIndex((p) => p.id === gameState.player_id);

			// Проверяем, что gameState.players - это массив и он не пуст
			if (Array.isArray(gameState.players) && gameState.players.length > 0) {
				for (let i = 0; i < gameState.players.length; i++) {  // Начинаем с индекса 0
					const idx = (currentIndex + i) % gameState.players.length; // Если currentIndex нужен
					const player = gameState.players[idx];
					html += `<div class="player-info-state">
						${player.nickname}: ${player.state}
					</div>`;
				}
			} else {
				html += `<div class="error-message">Нет игроков в лобби</div>`;
			}

			html += `</div>`;
			const exitBtn = document.createElement('button');
			exitBtn.textContent = 'Выйти';
			exitBtn.classList.add('exitButton');

			// Добавляем обработчик
			exitBtn.addEventListener('click', () => {
				if (this.options.onExit) {
					this.options.onExit();
				}
			});

			this.infoDiv.innerHTML = html;
			this.infoDiv.querySelector('.screen').appendChild(exitBtn);
		} else if (gameState.lobby_state === "Gaming") {
			this.finishTurnButton.classList.remove("hidden");
			this.undoButton.classList.remove("hidden");
			this.swapCardsButton.classList.remove("hidden");

			this.ruleButton.classList.remove("hidden");
			this.exitButton.classList.remove("hidden");

			let html = `<div class="game-info">`;
			// 1) Вывод текущего игрока (по player_id)
			const currentPlayer = gameState.players.find((p) => p.id === gameState.player_id);
			const turnPlayer = gameState.players.find((p) => p.id === gameState.current_turn_id);
			if (currentPlayer) {
				html += `<div class="current-player">
                <strong>Вы:</strong> ${currentPlayer.nickname} 
                <strong>очки:</strong> ${currentPlayer.score}
								<br/>
              </div>`;
			}
			html += `<strong>Ход</strong>: ${turnPlayer.nickname}`;
			// 2) Остальные игроки (по кругу)
			html += `<div class="other-players"><strong>Игроки</strong>:<br/>`;
			let currentIndex = gameState.players.findIndex((p) => p.id === gameState.player_id);
			for (let i = 1; i < gameState.players.length; i++) {
				const idx = (currentIndex + i) % gameState.players.length;
				const player = gameState.players[idx];
				html += `<div class="player-info">
                ${player.nickname}, score: ${player.score} 
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
		} else if (gameState.lobby_state === "EndGame") {
			this.finishTurnButton.classList.add("hidden");
			this.undoButton.classList.add("hidden");
			this.swapCardsButton.classList.add("hidden");
			this.ruleButton.classList.add("hidden");
			this.exitButton.remove();

			let html = `<div class="game-end screen">`;
			html += `<div class="state-title">Игра окончена</div>`;
			let currentIndex = gameState.players.findIndex((p) => p.id === gameState.player_id);

			// Проверяем, что gameState.players - это массив и он не пуст
			if (Array.isArray(gameState.players) && gameState.players.length > 0) {
				const sortedPlayers = [...gameState.players].sort((a, b) => b.score - a.score);
				for (const player of sortedPlayers) {
					html += `<div class="player-info-state">
						<strong>${player.nickname}</strong>: ${player.score}
					</div>`;
				}
				html += `</div>`;

				const exitBtn = document.createElement('button');
				exitBtn.textContent = 'Выйти';
				exitBtn.classList.add('exitButton');

				// Добавляем обработчик
				exitBtn.addEventListener('click', () => {
					if (this.options.onExit) {
						this.options.onExit();
					}
				});

				this.infoDiv.innerHTML = html;
				this.infoDiv.querySelector('.screen').appendChild(exitBtn);
			}
		}
	}
}
