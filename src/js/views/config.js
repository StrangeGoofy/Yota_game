const vw = 0.08;
// Конфигурация размеров для отрисовки
export const dimensions = {
	cardSize: window.innerWidth * vw, // Размер карточки (vw)
	gap: window.innerWidth * vw * 0.1, // gap – 10% от cardSize
	cellSize: window.innerWidth * vw + window.innerWidth * vw * 0.1, // Шаг между ячейками
	windowWidth: window.innerWidth,
	windowHeight: window.innerHeight,
};

export function recalcDimensions() {
	dimensions.cardSize = window.innerWidth * vw;
	dimensions.gap = dimensions.cardSize * 0.1;
	dimensions.cellSize = dimensions.cardSize + dimensions.gap;
	dimensions.windowWidth = window.innerWidth;
	dimensions.windowHeight = window.innerHeight;
}

export const Colors = {
	red: '#d8131d',
	green: '#70b342',
	blue: '#467dd8',
	yellow: '#e79c29',
	white: '#FFFFFF',
	black: '#000000',
};
