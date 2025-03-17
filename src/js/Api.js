// export async function updateGameState(gameId, newState) {
// 	const response = await fetch('/api/update_game_state.php', {
// 		method: 'POST',
// 		headers: { 'Content-Type': 'application/json' },
// 		body: JSON.stringify({ game_id: gameId, state: newState }),
// 	});
// 	return await response.json();
// }

export async function updateGameState(gameId, newState) {
	// Для тестирования загружаем данные из assets/mock-data.json
	const response = await fetch('/assets/mock_data.json');
	if (!response.ok) {
		throw new Error('Ошибка загрузки mock-данных');
	}
	const data = await response.json();
	return data;
}
