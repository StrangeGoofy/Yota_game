import { Colors, dimensions } from './config.js';

/**
 * Генерирует SVG-изображение карточки.
 * @param {Object} card - объект карточки с полями { color, shape, number }
 * @param {number} cardSize - размер карточки, по умолчанию берётся из dimensions.cardSize
 * @returns {string} SVG-строка
 */
export function generateCardSVG(card, cardSize = dimensions.cardSize) {
	// Отступ для центрального черного квадрата – 1/6 от cardSize
	const margin = cardSize / 6;
	const blackX = margin;
	const blackY = margin;
	const blackSize = cardSize - 2 * margin;

	// Внутренний отступ для большой фигуры внутри черного квадрата (10% от blackSize)
	const innerMargin = blackSize * 0.1;
	const shapeX = blackX + innerMargin;
	const shapeY = blackY + innerMargin;
	const shapeSize = blackSize - 2 * innerMargin;

	// Базовые настройки для маленьких фигур: базовый размер ~10% от shapeSize
	const defaultSmallSizeFactor = 0.1;
	const smallShapeSize = shapeSize * defaultSmallSizeFactor;
	const spacing = smallShapeSize * 0.5; // используется для стандартного ряда (не для треугольника)
	const count = card.number;

	let bigShapeSVG = '';
	let smallShapesSVG = '';

	// Цвет для большой фигуры: если Colors содержит card.color, берём его HEX, иначе само значение.
	const fillColor = Colors[card.color] || card.color;

	// Отрисовка большой фигуры
	switch (card.shape) {
		case 'circle':
			bigShapeSVG = `<circle cx="${shapeX + shapeSize / 2}" cy="${shapeY + shapeSize / 2}" r="${
				shapeSize / 2
			}" fill="${fillColor}" />`;
			break;
		case 'square':
			bigShapeSVG = `<rect x="${shapeX}" y="${shapeY}" width="${shapeSize}" height="${shapeSize}" fill="${fillColor}" />`;
			break;
		case 'triangle': {
			const t1 = `${shapeX + shapeSize / 2},${shapeY}`;
			const t2 = `${shapeX},${shapeY + shapeSize}`;
			const t3 = `${shapeX + shapeSize},${shapeY + shapeSize}`;
			bigShapeSVG = `<polygon points="${t1} ${t2} ${t3}" fill="${fillColor}" />`;
			break;
		}
		case 'cross': {
			// Для крестика толщина = shapeSize * 0.5
			const crossThickness = shapeSize * 0.5;
			const crossVerticalX = shapeX + (shapeSize - crossThickness) / 2;
			const crossHorizontalY = shapeY + (shapeSize - crossThickness) / 2;
			bigShapeSVG =
				`<rect x="${crossVerticalX}" y="${shapeY}" width="${crossThickness}" height="${shapeSize}" fill="${fillColor}" />` +
				`<rect x="${shapeX}" y="${crossHorizontalY}" width="${shapeSize}" height="${crossThickness}" fill="${fillColor}" />`;
			break;
		}
		default:
			bigShapeSVG = `<circle cx="${shapeX + shapeSize / 2}" cy="${shapeY + shapeSize / 2}" r="${
				shapeSize / 2
			}" fill="${fillColor}" />`;
	}

	// Определяем центр для размещения маленьких фигур.
	// Если большая фигура – треугольник, используем центр масс равностороннего треугольника,
	// иначе – центр большого квадрата.
	let centerX, centerY;
	if (card.shape === 'triangle') {
		centerX = shapeX + shapeSize / 2;
		centerY = shapeY + (2 * shapeSize) / 3;
	} else {
		centerX = shapeX + shapeSize / 2;
		centerY = shapeY + shapeSize / 2;
	}

	// Если большая фигура – треугольник, отрисовываем маленькие фигуры всегда как треугольники.
	if (card.shape === 'triangle') {
		if (count === 2) {
			// Для count=2 уменьшаем горизонтальное смещение, чтобы маленькие треугольники были ближе
			const offset = shapeSize / 16;
			const pos1 = { cx: centerX - offset, cy: centerY };
			const pos2 = { cx: centerX + offset, cy: centerY };
			const renderSmallTriangle = (cx, cy) => {
				const s1 = `${cx},${cy - smallShapeSize / 2}`;
				const s2 = `${cx - smallShapeSize / 2},${cy + smallShapeSize / 2}`;
				const s3 = `${cx + smallShapeSize / 2},${cy + smallShapeSize / 2}`;
				return `<polygon points="${s1} ${s2} ${s3}" fill="${Colors.white}" />`;
			};
			smallShapesSVG =
				renderSmallTriangle(pos1.cx, pos1.cy) + renderSmallTriangle(pos2.cx, pos2.cy);
		} else if (count === 3) {
			const R = shapeSize / 9;
			smallShapesSVG = '';
			for (let k = 0; k < 3; k++) {
				const angle = (2 * Math.PI * k) / 3;
				const cx = centerX + R * Math.cos(angle);
				const cy = centerY + R * Math.sin(angle);
				// Так как большая фигура – треугольник, всегда отрисовываем маленькие как треугольники
				const s1 = `${cx},${cy - smallShapeSize / 2}`;
				const s2 = `${cx - smallShapeSize / 2},${cy + smallShapeSize / 2}`;
				const s3 = `${cx + smallShapeSize / 2},${cy + smallShapeSize / 2}`;
				smallShapesSVG += `<polygon points="${s1} ${s2} ${s3}" fill="${Colors.white}" />`;
			}
		} else if (count === 4) {
			const offset = shapeSize / 12;
			const positions = [
				{ cx: centerX - offset, cy: centerY - offset },
				{ cx: centerX + offset, cy: centerY - offset },
				{ cx: centerX - offset, cy: centerY + offset },
				{ cx: centerX + offset, cy: centerY + offset },
			];
			smallShapesSVG = '';
			positions.forEach((pos) => {
				const s1 = `${pos.cx},${pos.cy - smallShapeSize / 2}`;
				const s2 = `${pos.cx - smallShapeSize / 2},${pos.cy + smallShapeSize / 2}`;
				const s3 = `${pos.cx + smallShapeSize / 2},${pos.cy + smallShapeSize / 2}`;
				smallShapesSVG += `<polygon points="${s1} ${s2} ${s3}" fill="${Colors.white}" />`;
			});
		} else {
			// Для остальных значений count для треугольника – выстраиваем маленькие треугольники по ряду относительно центра треугольника.
			const totalSmallWidth = count * smallShapeSize + (count - 1) * spacing;
			const smallStartX = centerX - totalSmallWidth / 2;
			const smallYPos = centerY - smallShapeSize / 2;
			smallShapesSVG = '';
			for (let i = 0; i < count; i++) {
				const posX = smallStartX + i * (smallShapeSize + spacing);
				const s1 = `${posX + smallShapeSize / 2},${smallYPos}`;
				const s2 = `${posX},${smallYPos + smallShapeSize}`;
				const s3 = `${posX + smallShapeSize},${smallYPos + smallShapeSize}`;
				smallShapesSVG += `<polygon points="${s1} ${s2} ${s3}" fill="${Colors.white}" />`;
			}
		}
	} else {
		// Если большая фигура не треугольник, отрисовываем маленькие фигуры согласно card.shape
		if (count === 2) {
			const offset = shapeSize / 8;
			const pos1 = { cx: centerX - offset, cy: centerY };
			const pos2 = { cx: centerX + offset, cy: centerY };
			const renderSmallShape = (cx, cy) => {
				switch (card.shape) {
					case 'circle':
						return `<circle cx="${cx}" cy="${cy}" r="${smallShapeSize / 2}" fill="${
							Colors.white
						}" />`;
					case 'square':
						return `<rect x="${cx - smallShapeSize / 2}" y="${
							cy - smallShapeSize / 2
						}" width="${smallShapeSize}" height="${smallShapeSize}" fill="${Colors.white}" />`;
					case 'cross': {
						const st = smallShapeSize * 0.3;
						return (
							`<rect x="${cx - st / 2}" y="${
								cy - smallShapeSize / 2
							}" width="${st}" height="${smallShapeSize}" fill="${Colors.white}" />` +
							`<rect x="${cx - smallShapeSize / 2}" y="${
								cy - st / 2
							}" width="${smallShapeSize}" height="${st}" fill="${Colors.white}" />`
						);
					}
					default:
						// По умолчанию для "triangle" не используется, т.к. эта ветка для НЕ треугольника
						return `<circle cx="${cx}" cy="${cy}" r="${smallShapeSize / 2}" fill="${
							Colors.white
						}" />`;
				}
			};
			smallShapesSVG = renderSmallShape(pos1.cx, pos1.cy) + renderSmallShape(pos2.cx, pos2.cy);
		} else if (count === 3) {
			const R = shapeSize / 9;
			smallShapesSVG = '';
			for (let k = 0; k < 3; k++) {
				const angle = (2 * Math.PI * k) / 3;
				const cx = centerX + R * Math.cos(angle);
				const cy = centerY + R * Math.sin(angle);
				switch (card.shape) {
					case 'circle':
						smallShapesSVG += `<circle cx="${cx}" cy="${cy}" r="${smallShapeSize / 2}" fill="${
							Colors.white
						}" />`;
						break;
					case 'square':
						smallShapesSVG += `<rect x="${cx - smallShapeSize / 2}" y="${
							cy - smallShapeSize / 2
						}" width="${smallShapeSize}" height="${smallShapeSize}" fill="${Colors.white}" />`;
						break;
					case 'cross': {
						const st = smallShapeSize * 0.3;
						smallShapesSVG += `<rect x="${cx - st / 2}" y="${
							cy - smallShapeSize / 2
						}" width="${st}" height="${smallShapeSize}" fill="${Colors.white}" />`;
						smallShapesSVG += `<rect x="${cx - smallShapeSize / 2}" y="${
							cy - st / 2
						}" width="${smallShapeSize}" height="${st}" fill="${Colors.white}" />`;
						break;
					}
					default:
						smallShapesSVG += `<circle cx="${cx}" cy="${cy}" r="${smallShapeSize / 2}" fill="${
							Colors.white
						}" />`;
				}
			}
		} else if (count === 4) {
			const offset = shapeSize / 12;
			const positions = [
				{ cx: centerX - offset, cy: centerY - offset },
				{ cx: centerX + offset, cy: centerY - offset },
				{ cx: centerX - offset, cy: centerY + offset },
				{ cx: centerX + offset, cy: centerY + offset },
			];
			smallShapesSVG = '';
			positions.forEach((pos) => {
				switch (card.shape) {
					case 'circle':
						smallShapesSVG += `<circle cx="${pos.cx}" cy="${pos.cy}" r="${
							smallShapeSize / 2
						}" fill="${Colors.white}" />`;
						break;
					case 'square':
						smallShapesSVG += `<rect x="${pos.cx - smallShapeSize / 2}" y="${
							pos.cy - smallShapeSize / 2
						}" width="${smallShapeSize}" height="${smallShapeSize}" fill="${Colors.white}" />`;
						break;
					case 'cross': {
						const st = smallShapeSize * 0.3;
						smallShapesSVG += `<rect x="${pos.cx - st / 2}" y="${
							pos.cy - smallShapeSize / 2
						}" width="${st}" height="${smallShapeSize}" fill="${Colors.white}" />`;
						smallShapesSVG += `<rect x="${pos.cx - smallShapeSize / 2}" y="${
							pos.cy - st / 2
						}" width="${smallShapeSize}" height="${st}" fill="${Colors.white}" />`;
						break;
					}
					default:
						smallShapesSVG += `<circle cx="${pos.cx}" cy="${pos.cy}" r="${
							smallShapeSize / 2
						}" fill="${Colors.white}" />`;
				}
			});
		} else {
			const totalSmallWidth = count * smallShapeSize + (count - 1) * spacing;
			const smallStartX = centerX - totalSmallWidth / 2;
			const smallYPos = centerY - smallShapeSize / 2;
			smallShapesSVG = '';
			for (let i = 0; i < count; i++) {
				const posX = smallStartX + i * (smallShapeSize + spacing);
				switch (card.shape) {
					case 'circle':
						smallShapesSVG += `<circle cx="${posX + smallShapeSize / 2}" cy="${
							smallYPos + smallShapeSize / 2
						}" r="${smallShapeSize / 2}" fill="${Colors.white}" />`;
						break;
					case 'square':
						smallShapesSVG += `<rect x="${posX}" y="${smallYPos}" width="${smallShapeSize}" height="${smallShapeSize}" fill="${Colors.white}" />`;
						break;
					case 'cross': {
						const st = smallShapeSize * 0.3;
						smallShapesSVG += `<rect x="${
							posX + smallShapeSize / 2 - st / 2
						}" y="${smallYPos}" width="${st}" height="${smallShapeSize}" fill="${Colors.white}" />`;
						smallShapesSVG += `<rect x="${posX}" y="${
							smallYPos + smallShapeSize / 2 - st / 2
						}" width="${smallShapeSize}" height="${st}" fill="${Colors.white}" />`;
						break;
					}
					default:
						smallShapesSVG += `<circle cx="${posX + smallShapeSize / 2}" cy="${
							smallYPos + smallShapeSize / 2
						}" r="${smallShapeSize / 2}" fill="${Colors.white}" />`;
				}
			}
		}
	}

	// Собираем итоговый SVG:
	// Ширина и высота установлены на 100% для масштабирования по размеру контейнера,
	// viewBox от 0 до cardSize.
	const svg = `
<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%" viewBox="0 0 ${cardSize} ${cardSize}">
  <!-- Текст по углам с жирным шрифтом -->
  <text x="5" y="15" font-size="12" font-weight="bold" fill="${fillColor}">${card.number}</text>
  <text x="${
		cardSize - 5
	}" y="15" font-size="12" font-weight="bold" fill="${fillColor}" text-anchor="end">${
		card.number
	}</text>
  <text x="5" y="${cardSize - 5}" font-size="12" font-weight="bold" fill="${fillColor}">${
		card.number
	}</text>
  <text x="${cardSize - 5}" y="${
		cardSize - 5
	}" font-size="12" font-weight="bold" fill="${fillColor}" text-anchor="end">${card.number}</text>

  <!-- Центральный черный квадрат -->
  <rect x="${margin}" y="${margin}" width="${blackSize}" height="${blackSize}" fill="${
		Colors.black
	}" />

  <!-- Большая фигура внутри черного квадрата -->
  ${bigShapeSVG}
  <!-- Маленькие фигуры внутри большой фигуры -->
  ${smallShapesSVG}
</svg>
  `;
	return svg;
}
