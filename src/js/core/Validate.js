/**
 * Функция возвращает массив кандидатных ячеек для размещения карты.
 * Кандидатными считаются пустые ячейки, соседние (по вертикали и горизонтали)
 * с уже поставленными карточками.
 *
 * @param {Array} placedCells - массив объектов с координатами уже поставленных карточек, например: [{ x, y, card }]
 * @returns {Array} - массив объектов { x, y } кандидатных ячеек
 */
export function getCandidateCells(placedCells) {
	const candidates = new Set();

	placedCells.forEach((cell) => {
		const { x, y } = cell;
		// Определяем соседей по 4 направлениям
		const neighbors = [
			{ x: x + 1, y },
			{ x: x - 1, y },
			{ x, y: y + 1 },
			{ x, y: y - 1 },
		];

		neighbors.forEach((neighbor) => {
			// Если в списке поставленных карточек уже нет ячейки с такими координатами
			const occupied = placedCells.some((item) => item.x === neighbor.x && item.y === neighbor.y);
			if (!occupied) {
				// Сохраним координаты в виде строки, чтобы не было дубликатов
				candidates.add(`${neighbor.x},${neighbor.y}`);
			}
		});
	});

	// Преобразуем набор строк обратно в объекты { x, y }
	return Array.from(candidates).map((key) => {
		const [x, y] = key.split(',').map(Number);
		return { x, y };
	});
}
