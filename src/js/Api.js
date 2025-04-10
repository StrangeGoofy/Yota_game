export async function updateGameState() {
	const authToken = getCookie('auth_token');

	const response = await fetch('/api/update_game_state.php', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({ token: authToken }),
	});
	return await response.json();
}

export async function playCards(cards) {
	const authToken = getCookie('auth_token');

	const response = await fetch('/api/play_cards.php', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({
			token: authToken,
			cards: cards, // массив объектов: [{ x, y, card_id }]
		}),
	});
	const result = await response.json();
	return result;
}

export async function passTurn() {
	const authToken = getCookie('auth_token');

	const response = await fetch('/api/pass_turn.php', {
		method: 'POST',
		headers: { 'Content-Type': 'application/json' },
		body: JSON.stringify({
			token: authToken
		}),
	});
	const result = await response.json();
	return result;
}




// export async function updateGameState(gameId, newState) {
// 	// Для тестирования загружаем данные из assets/mock-data.json
// 	const response = await fetch('../assets/mock_data.json');
// 	if (!response.ok) {
// 		throw new Error('Ошибка загрузки mock-данных');
// 	}
// 	const data = await response.json();
// 	return data;
// }

function getCookie(name) {
	const matches = document.cookie.match(
		new RegExp('(?:^|; )' + name.replace(/([$?*|{}\]\\\/+^])/g, '\\$1') + '=([^;]*)')
	);
	return matches ? decodeURIComponent(matches[1]) : null;
}
