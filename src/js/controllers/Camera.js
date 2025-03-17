// src/js/controllers/Camera.js
import { dimensions } from '../views/config.js';

export default class Camera {
	/**
	 * @param {HTMLElement|string} container – id или DOM-элемент игрового поля (по умолчанию 'game-field')
	 * @param {Function} [onTransform] – callback, который вызывается после изменения трансформации (например, для перерисовки поля)
	 */
	constructor(container = 'game-field', onTransform = null) {
		this.container = typeof container === 'string' ? document.getElementById(container) : container;
		this.translateX = 0;
		this.translateY = 0;
		this.scale = 1;

		this.onTransform = onTransform;

		// Для панорамирования мышью
		this.isPanning = false;
		this.startPan = { x: 0, y: 0 };

		// Для сенсорных событий
		this.touchMode = null;
		this.initialPinchDistance = 0;
		this.initialScaleForPinch = this.scale;
		this.startPinchTranslate = { x: 0, y: 0 };
		this.pinchMidpoint = { x: 0, y: 0 };
		this.initEvents();
	}

	initEvents() {
		// Панорамирование мышью (левая и правая кнопки)
		this.container.addEventListener('mousedown', (e) => {
			// Разрешаем пэн, если нажата левая (button === 0) или правая (button === 2) кнопка
			if (e.button === 0 || e.button === 2) {
				this.isPanning = true;
				this.startPan = { x: e.clientX - this.translateX, y: e.clientY - this.translateY };
				this.container.style.cursor = 'grabbing';
			}
		});

		document.addEventListener('mousemove', (e) => {
			if (!this.isPanning) return;
			this.translateX = e.clientX - this.startPan.x;
			this.translateY = e.clientY - this.startPan.y;
			this.applyTransform();
			if (this.onTransform) this.onTransform();
		});

		document.addEventListener('mouseup', () => {
			if (this.isPanning) {
				this.isPanning = false;
				this.container.style.cursor = 'default';
			}
		});

		// Отключаем контекстное меню на правую кнопку в контейнере
		this.container.addEventListener('contextmenu', (e) => {
			e.preventDefault();
		});

		// Сенсорные события для панорамирования и зума
		this.container.addEventListener('touchstart', (e) => {
			if (e.touches.length === 1) {
				this.touchMode = 'pan';
				this.startPan = {
					x: e.touches[0].clientX - this.translateX,
					y: e.touches[0].clientY - this.translateY,
				};
			} else if (e.touches.length === 2) {
				this.touchMode = 'pinch';
				this.initialPinchDistance = Math.hypot(
					e.touches[0].clientX - e.touches[1].clientX,
					e.touches[0].clientY - e.touches[1].clientY
				);
				this.initialScaleForPinch = this.scale;
				this.startPinchTranslate = { x: this.translateX, y: this.translateY };
				this.pinchMidpoint = {
					x: (e.touches[0].clientX + e.touches[1].clientX) / 2,
					y: (e.touches[0].clientY + e.touches[1].clientY) / 2,
				};
			}
		});

		this.container.addEventListener(
			'touchmove',
			(e) => {
				e.preventDefault();
				if (this.touchMode === 'pan' && e.touches.length === 1) {
					this.translateX = e.touches[0].clientX - this.startPan.x;
					this.translateY = e.touches[0].clientY - this.startPan.y;
					this.applyTransform();
					if (this.onTransform) this.onTransform();
				} else if (this.touchMode === 'pinch' && e.touches.length === 2) {
					const currentDistance = Math.hypot(
						e.touches[0].clientX - e.touches[1].clientX,
						e.touches[0].clientY - e.touches[1].clientY
					);
					let newScale = this.initialScaleForPinch * (currentDistance / this.initialPinchDistance);
					newScale = Math.min(Math.max(newScale, 0.5), 2);
					this.translateX =
						this.pinchMidpoint.x -
						(newScale / this.initialScaleForPinch) *
							(this.pinchMidpoint.x - this.startPinchTranslate.x);
					this.translateY =
						this.pinchMidpoint.y -
						(newScale / this.initialScaleForPinch) *
							(this.pinchMidpoint.y - this.startPinchTranslate.y);
					this.scale = newScale;
					this.applyTransform();
					if (this.onTransform) this.onTransform();
				}
			},
			{ passive: false }
		);

		this.container.addEventListener('touchend', (e) => {
			if (e.touches.length === 0) {
				this.touchMode = null;
			}
		});

		// Зум колесиком мыши с зумированием в сторону указателя
		this.container.addEventListener('wheel', (e) => {
			e.preventDefault();
			const oldScale = this.scale;
			const delta = e.deltaY > 0 ? -0.1 : 0.1;
			this.scale = Math.min(Math.max(this.scale + delta, 0.5), 2);
			const mouseX = e.clientX;
			const mouseY = e.clientY;
			this.translateX = mouseX - (mouseX - this.translateX) * (this.scale / oldScale);
			this.translateY = mouseY - (mouseY - this.translateY) * (this.scale / oldScale);
			this.applyTransform();
			if (this.onTransform) this.onTransform();
		});
	}

	applyTransform() {
		this.container.style.transform = `translate(${this.translateX}px, ${this.translateY}px) scale(${this.scale})`;
	}

	/**
	 * Анимирует переход камеры к заданным параметрам.
	 * @param {number} targetScale – целевой масштаб
	 * @param {number} targetTranslateX – целевое смещение по X
	 * @param {number} targetTranslateY – целевое смещение по Y
	 * @param {number} duration – длительность анимации в мс (по умолчанию 500)
	 */
	animateTo(targetScale, targetTranslateX, targetTranslateY, duration = 500) {
		const startTime = performance.now();
		const startScale = this.scale;
		const startTranslateX = this.translateX;
		const startTranslateY = this.translateY;

		function easeOutCubic(t) {
			return 1 - Math.pow(1 - t, 3);
		}

		const animateStep = (timestamp) => {
			const elapsed = timestamp - startTime;
			const progress = Math.min(elapsed / duration, 1);
			const eased = easeOutCubic(progress);

			this.scale = startScale + (targetScale - startScale) * eased;
			this.translateX = startTranslateX + (targetTranslateX - startTranslateX) * eased;
			this.translateY = startTranslateY + (targetTranslateY - startTranslateY) * eased;

			this.applyTransform();
			if (this.onTransform) this.onTransform();

			if (progress < 1) {
				requestAnimationFrame(animateStep);
			}
		};

		requestAnimationFrame(animateStep);
	}

	/**
	 * Автоадаптация камеры по количеству карточек на поле.
	 * Вычисляет bounding box для всех ячеек с карточками и рассчитывает
	 * новый масштаб и смещение так, чтобы все карточки помещались в видимой области.
	 * Добавляется отступ, который берёт максимум из фиксированного минимума и относительного отступа.
	 *
	 * @param {Array} cells - массив ячеек игрового поля (каждая ячейка имеет { x, y, card })
	 * @param {number} [duration=500] - длительность анимации в мс
	 */
	autoFit(cells, duration = 500) {
		// Отбираем только ячейки с установленными карточками
		const placedCells = cells.filter((cell) => cell.card);
		if (placedCells.length === 0) return;

		const winWidth = window.innerWidth;
		const winHeight = window.innerHeight;

		let minX = Infinity,
			maxX = -Infinity,
			minY = Infinity,
			maxY = -Infinity;

		// Вычисляем bounding box карточек
		placedCells.forEach((cell) => {
			// Вычисляем положение ячейки аналогично отрисовке поля:
			// центр окна + смещение по координатам клетки - половина размера карточки
			const left = winWidth / 2 + cell.x * dimensions.cellSize - dimensions.cardSize / 2;
			const top = winHeight / 2 - cell.y * dimensions.cellSize - dimensions.cardSize / 2;
			const right = left + dimensions.cardSize;
			const bottom = top + dimensions.cardSize;

			if (left < minX) minX = left;
			if (right > maxX) maxX = right;
			if (top < minY) minY = top;
			if (bottom > maxY) maxY = bottom;
		});

		const boundingWidth = maxX - minX;
		const boundingHeight = maxY - minY;

		// Рассчитываем отступы:
		// Фиксированный минимум отступа (например, 200 пикселей)
		const minMargin = 400;
		// Относительный отступ, например 20% от bounding box
		const relativeMarginFactor = 0.2;

		const marginX = Math.max(boundingWidth * relativeMarginFactor, minMargin);
		const marginY = Math.max(boundingHeight * relativeMarginFactor, minMargin);

		// Эффективные размеры bounding box с отступом
		const effectiveWidth = boundingWidth + 2 * marginX;
		const effectiveHeight = boundingHeight + 2 * marginY;

		// Вычисляем новый масштаб так, чтобы effective bounding box помещался в окно
		const scaleX = winWidth / effectiveWidth;
		const scaleY = winHeight / effectiveHeight;
		const newScale = Math.min(scaleX, scaleY);

		// Находим центр bounding box
		const centerX = (minX + maxX) / 2;
		const centerY = (minY + maxY) / 2;

		// Вычисляем смещение, чтобы центр bounding box оказался в центре окна
		const newTranslateX = winWidth / 2 - centerX * newScale;
		const newTranslateY = winHeight / 2 - centerY * newScale;

		this.animateTo(newScale, newTranslateX, newTranslateY, duration);
	}
}
