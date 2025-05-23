toc.dat                                                                                             0000600 0004000 0002000 00000163472 14767066671 0014500 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP       "                }            yota2 #   16.8 (Ubuntu 16.8-0ubuntu0.24.04.1)    16.4 s               0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false                    0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false                    0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false                    1262    17081    yota2    DATABASE     q   CREATE DATABASE yota2 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';
    DROP DATABASE yota2;
                postgres    false                     2615    17082    s314500    SCHEMA        CREATE SCHEMA s314500;
    DROP SCHEMA s314500;
                postgres    false                    1255    17083 7   check_card_validity(integer, integer, integer, integer)    FUNCTION     E  CREATE FUNCTION s314500.check_card_validity(p_lobby integer, p_x integer, p_y integer, p_type integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE 
	x_shapes text;
	x_numbers smallint; 
	x_colors text;

	y_shapes text;
	y_numbers smallint; 
	y_colors text;

	x_count integer; 
	y_count integer;

	shape text;
	number smallint;
	color text;
BEGIN

	SELECT t.shape, t.number, t.color from cards c 
	JOIN cards_types t ON c.card_type_id = t.id
	WHERE c.card_id = p_type
	INTO shape, number, color;

	-- Если место уже занято
	IF EXISTS (SELECT 1 FROM get_cards_on_table(p_lobby) WHERE x = p_x AND y = p_y) THEN
		RAISE NOTICE 'Клетка уже занята';
		RETURN FALSE;
	END IF;

	-- Если не найдено соседних клеток
	IF NOT EXISTS (SELECT 1 FROM get_adjacent_cards(p_lobby, p_x, p_y)) THEN 
		RAISE NOTICE 'У клетки должен быть хоть один сосед';
		RETURN FALSE;
	END IF;

	SELECT COUNT (1) FROM get_adjacent_cards(p_lobby, p_x, p_y) a
	WHERE a.x = p_x 
	INTO x_count;

	IF x_count > 3 THEN
		RAISE NOTICE 'Слишком много соседей по горизонтали';
		RETURN FALSE;
	END IF;

	SELECT COUNT (1) FROM get_adjacent_cards(p_lobby, p_x, p_y) a
	WHERE a.y = p_y 
	INTO y_count;
	
	IF y_count > 3 THEN
		RAISE NOTICE 'Слишком много соседей по вертикали';
		RETURN FALSE;
	END IF;

	IF NOT (p_type IN (SELECT id FROM get_possible_cards(p_lobby, p_x, p_y))) THEN 
		RAISE NOTICE 'Карта не подходит';
		RETURN FALSE;
	END IF;

	RETURN TRUE;

END; 
$$;
 f   DROP FUNCTION s314500.check_card_validity(p_lobby integer, p_x integer, p_y integer, p_type integer);
       s314500          postgres    false    6                    1255    17084    checktoken(integer) 	   PROCEDURE     :  CREATE PROCEDURE s314500.checktoken(IN tk integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tokenExists BOOLEAN;
BEGIN
    -- Проверка существования токена
    SELECT EXISTS (SELECT 1 FROM Tokens WHERE token = tk) INTO tokenExists;
    RAISE NOTICE 'isValid: %', tokenExists;
END;
$$;
 2   DROP PROCEDURE s314500.checktoken(IN tk integer);
       s314500          postgres    false    6                    1255    17085    cleartokens() 	   PROCEDURE     �   CREATE PROCEDURE s314500.cleartokens()
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Удаление старых токенов (больше чем 7 дней)
    DELETE FROM Tokens WHERE created < NOW() - INTERVAL '7 days';
END;
$$;
 &   DROP PROCEDURE s314500.cleartokens();
       s314500          postgres    false    6                    1255    17086 0   createlobby(integer, character varying, integer)    FUNCTION     q  CREATE FUNCTION s314500.createlobby(tk integer, pw character varying, turnt integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
    lobbyId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Создаем лобби
    INSERT INTO lobbies (password, turn_time, host_id, state)
    VALUES (pw, turnT, userId, 'Start')
    RETURNING id INTO lobbyId;

    -- Добавляем пользователя в лобби
    INSERT INTO players (id,login, lobby_id, is_ready)
    VALUES (userId, userLogin, lobbyId, true);

    RETURN lobbyId;
END;
$$;
 T   DROP FUNCTION s314500.createlobby(tk integer, pw character varying, turnt integer);
       s314500          postgres    false    6                    1255    17087 C   createlobby(integer, character varying, character varying, integer)    FUNCTION     �  CREATE FUNCTION s314500.createlobby(tk integer, p_nickname character varying, pw character varying, turnt integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
    lobbyId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Создаем лобби
    INSERT INTO lobbies (password, turn_time, host_id, state)
    VALUES (pw, turnT, userId, 'Start')
    RETURNING id INTO lobbyId;

    -- Добавляем пользователя в лобби
    INSERT INTO players (login, nickname, lobby_id, is_ready)
    VALUES (userLogin, p_nickname, lobbyId, true);

    RETURN lobbyId;
END;
$$;
 r   DROP FUNCTION s314500.createlobby(tk integer, p_nickname character varying, pw character varying, turnt integer);
       s314500          postgres    false    6                    1255    17088 /   enterlobby(integer, integer, character varying)    FUNCTION     }  CREATE FUNCTION s314500.enterlobby(tk integer, lobbyid integer, inputpassword character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
    actualPassword VARCHAR(10);
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RETURN 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Проверка, что пользователь не в лобби
    IF EXISTS (SELECT 1 FROM players WHERE user_id = userId AND lobby_id = lobbyId) THEN
        RETURN 'Пользователь уже в лобби';
    END IF;

    -- Проверка на пароль
    SELECT password INTO actualPassword FROM lobbies WHERE id = lobbyId;
    IF actualPassword IS NOT NULL AND inputPassword != actualPassword THEN
        RETURN 'Неверный пароль';
    END IF;

    -- Проверка на максимальное количество игроков
    IF (SELECT COUNT(*) FROM players WHERE lobby_id = lobbyId) = 4 THEN
        RETURN 'Лобби полное';
    END IF;

    -- Вход в лобби
    INSERT INTO players (user_id, lobby_id) VALUES (userId, lobbyId);
    RETURN 'Вход в лобби выполнен';
END;
$$;
 `   DROP FUNCTION s314500.enterlobby(tk integer, lobbyid integer, inputpassword character varying);
       s314500          postgres    false    6         �            1255    17089 -   get_adjacent_cards(integer, integer, integer)    FUNCTION       CREATE FUNCTION s314500.get_adjacent_cards(p_lobby integer, p_x integer, p_y integer) RETURNS TABLE(x smallint, y smallint, shape text, color text, number smallint)
    LANGUAGE plpgsql
    AS $$
BEGIN 

    RETURN QUERY 
    WITH RECURSIVE 
    left_x_neighbors AS (
        -- Находим ближайшее существующее значение x, которое меньше param
        (SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t WHERE t.x = p_x - 1 AND t.y = p_y)
        UNION ALL
        -- Добавляем предыдущее значение, если оно есть
        SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t
        JOIN left_x_neighbors n ON t.x = n.x - 1
        WHERE t.y = p_y
    ),
    
    right_x_neighbors AS (
        -- Находим ближайшее существующее значение x, которое больше param
        (SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t WHERE t.x = p_x + 1 AND t.y = p_y)
        UNION ALL
        -- Добавляем следующее значение, если оно есть
        SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t
        JOIN right_x_neighbors n ON t.x = n.x + 1
        WHERE t.y = p_y
    ),
    
    left_y_neighbors AS (
        -- Находим ближайшее существующее значение y, которое меньше param
        (SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t WHERE t.y = p_y - 1 AND t.x = p_x)
        UNION ALL
        -- Добавляем предыдущее значение, если оно есть
        SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t
        JOIN left_y_neighbors n ON t.y = n.y - 1
        WHERE t.x = p_x
    ),

    right_y_neighbors AS (
        -- Находим ближайшее существующее значение y, которое больше param
        (SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t WHERE t.y = p_y + 1 AND t.x = p_x)
        UNION ALL
        -- Добавляем следующее значение, если оно есть
        SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t
        JOIN right_y_neighbors n ON t.y = n.y + 1
        WHERE t.x = p_x
    )

    SELECT lx.x, lx.y, lx.shape, lx.color, lx.number FROM left_x_neighbors lx
    UNION 
    SELECT rx.x, rx.y, rx.shape, rx.color, rx.number FROM right_x_neighbors rx
    UNION 
    SELECT ly.x, ly.y, ly.shape, ly.color, ly.number FROM left_y_neighbors ly
    UNION 
    SELECT ry.x, ry.y, ry.shape, ry.color, ry.number FROM right_y_neighbors ry;

END 
$$;
 U   DROP FUNCTION s314500.get_adjacent_cards(p_lobby integer, p_x integer, p_y integer);
       s314500          postgres    false    6         �            1255    17090    get_cards_on_table(integer)    FUNCTION     �  CREATE FUNCTION s314500.get_cards_on_table(lobby integer) RETURNS TABLE(x smallint, y smallint, shape text, color text, number smallint)
    LANGUAGE plpgsql
    AS $$BEGIN 

RETURN QUERY
SELECT pos.x, pos.y, c.shape, c.color, c.number FROM cards_on_table pos 
LEFT JOIN cards ON pos.card_id = cards.card_id 
LEFT JOIN cards_types c ON cards.card_id = c.id
WHERE pos.lobby_id = lobby;

END;$$;
 9   DROP FUNCTION s314500.get_cards_on_table(lobby integer);
       s314500          postgres    false    6         �            1255    17091 -   get_possible_cards(integer, integer, integer)    FUNCTION       CREATE FUNCTION s314500.get_possible_cards(p_lobby integer, p_x integer, p_y integer) RETURNS TABLE(id integer, possible_color text, possible_shape text, possible_number smallint)
    LANGUAGE plpgsql
    AS $$
DECLARE 
	
	y_count integer;
	x_count integer;
	
BEGIN

SELECT COUNT(DISTINCT(x)) FROM get_adjacent_cards(p_lobby, p_x, p_y) 
WHERE y = p_y
INTO x_count;

SELECT COUNT(DISTINCT(y)) FROM get_adjacent_cards(p_lobby, p_x, p_y) 
WHERE x = p_x
INTO y_count;

RETURN QUERY
WITH
distinct_color_x AS 
(
	SELECT DISTINCT(c.color) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE y = p_y
),
distinct_color_y AS
(
	SELECT DISTINCT(c.color) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE x = p_x
),
possible_colors AS 
	(
		(
			(
			SELECT c.color FROM distinct_color_x c  
			WHERE (SELECT COUNT(1) FROM distinct_color_x) = 1
			)
			UNION
			(
			SELECT t.name as color FROM t_card_color t
			WHERE (SELECT COUNT(1) FROM distinct_color_x) = x_count
			EXCEPT SELECT color FROM distinct_color_x  
			)
		)
		INTERSECT
		(
			(
			SELECT c.color FROM distinct_color_y c  
			WHERE (SELECT COUNT(1) FROM distinct_color_y) = 1
			)
			UNION
			(
			SELECT t.name as color FROM t_card_color t
			WHERE (SELECT COUNT(1) FROM distinct_color_y) = y_count
			EXCEPT SELECT c.color FROM distinct_color_y c
			)
		)		
	),
distinct_shape_x AS 
	(
	SELECT DISTINCT(c.shape) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE y = p_y
	),
distinct_shape_y AS
(
	SELECT DISTINCT(c.shape) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE x = p_x
),
possible_shapes AS 
	(
		(
			(
			SELECT c.shape FROM distinct_shape_x c  
			WHERE (SELECT COUNT(1) FROM distinct_shape_x) = 1
			)
			UNION
			(
			SELECT t.name as shape FROM t_card_shape t
			WHERE (SELECT COUNT(1) FROM distinct_shape_x) = x_count
			EXCEPT SELECT shape FROM distinct_shape_x  
			)
		)
		INTERSECT
		(
			(
			SELECT c.shape FROM distinct_shape_y c  
			WHERE (SELECT COUNT(1) FROM distinct_shape_y) = 1
			)
			UNION
			(
			SELECT t.name as shape FROM t_card_shape t
			WHERE (SELECT COUNT(1) FROM distinct_shape_y) = y_count
			EXCEPT SELECT c.shape FROM distinct_shape_y c
			)
		)		
	),
distinct_number_x AS 
	(
	SELECT DISTINCT(c.number) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE y = p_y
	),
distinct_number_y AS
(
	SELECT DISTINCT(c.number) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE x = p_x
),
possible_numbers AS 
	(
		(
			(
			SELECT c.number FROM distinct_number_x c  
			WHERE (SELECT COUNT(1) FROM distinct_number_x) = 1
			)
			UNION
			(
			SELECT t.number as number FROM t_card_number t
			WHERE (SELECT COUNT(1) FROM distinct_number_x) = x_count
			EXCEPT SELECT number FROM distinct_number_x  
			)
		)
		INTERSECT
		(
			(
			SELECT c.number FROM distinct_number_y c  
			WHERE (SELECT COUNT(1) FROM distinct_number_y) = 1
			)
			UNION
			(
			SELECT t.number as number FROM t_card_number t
			WHERE (SELECT COUNT(1) FROM distinct_number_y) = y_count
			EXCEPT SELECT c.number FROM distinct_number_y c
			)
		)		
	)

	SELECT t.id, t.color, t.shape, t.number FROM cards_types t
	WHERE 
	t.color IN (SELECT color FROM possible_colors) AND 
	t.shape IN (SELECT shape FROM possible_shapes) AND 
	t.number IN (SELECT number FROM possible_numbers);

	-- SELECT 0, p.color, '', 0::smallint FROM possible_colors p;

END;
$$;
 U   DROP FUNCTION s314500.get_possible_cards(p_lobby integer, p_x integer, p_y integer);
       s314500          postgres    false    6         �            1255    17092    getcurrentgames(integer)    FUNCTION     �  CREATE FUNCTION s314500.getcurrentgames(tk integer) RETURNS TABLE(id integer, usercount integer, hostlogin character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM Tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM Users WHERE login = userLogin;

    -- Запрос
    RETURN QUERY
    SELECT gl.id,
           COUNT(ul2.user_id) AS userCount,
           u.login AS hostLogin
    FROM GameLobbies AS gl
    JOIN UsersInLobby AS ul ON gl.id = ul.lobby_id
    LEFT JOIN UsersInLobby AS ul2 ON gl.id = ul2.lobby_id
    LEFT JOIN Users u ON gl.host_id = u.id
    WHERE ul.user_id = userId
    GROUP BY gl.id, u.login;
END;
$$;
 3   DROP FUNCTION s314500.getcurrentgames(tk integer);
       s314500          postgres    false    6                     1255    17093    gethost(integer)    FUNCTION     �   CREATE FUNCTION s314500.gethost(lobbyid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (SELECT host_id FROM lobbies WHERE id = lobbyid);
END;
$$;
 0   DROP FUNCTION s314500.gethost(lobbyid integer);
       s314500          postgres    false    6         �            1255    17094    getlobbysettings(integer)    FUNCTION     F  CREATE FUNCTION s314500.getlobbysettings(lobbyid integer) RETURNS TABLE(haspassword boolean, turn_time integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE WHEN password IS NOT NULL THEN TRUE ELSE FALSE END AS hasPassword,
        turn_time
    FROM lobbies
    WHERE id = lobbyId;
END;
$$;
 9   DROP FUNCTION s314500.getlobbysettings(lobbyid integer);
       s314500          postgres    false    6         �            1255    17095    getuserid(integer) 	   PROCEDURE       CREATE PROCEDURE s314500.getuserid(IN tk integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64) := getUserLoginByToken(tk);
BEGIN
    -- Получение id пользователя по логину
    SELECT id FROM Users WHERE login = userLogin;
END;
$$;
 1   DROP PROCEDURE s314500.getuserid(IN tk integer);
       s314500          postgres    false    6         �            1255    17096    getuserloginbytoken(integer)    FUNCTION     0  CREATE FUNCTION s314500.getuserloginbytoken(tk integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
BEGIN
    -- Получение логина по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    RETURN userLogin;
END;
$$;
 7   DROP FUNCTION s314500.getuserloginbytoken(tk integer);
       s314500          postgres    false    6                    1255    17097 !   getusersinlobby(integer, integer)    FUNCTION     �  CREATE FUNCTION s314500.getusersinlobby(tk integer, lobbyid integer) RETURNS TABLE(user_id integer, login character varying, win_count integer, is_ready boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM Users WHERE login = userLogin;

    -- Проверка на существование лобби
    IF NOT EXISTS (SELECT 1 FROM lobbies WHERE id = lobbyId) THEN
        RAISE EXCEPTION 'Лобби не существует';
    END IF;

    -- Проверка на то, что пользователь в лобби
    IF NOT EXISTS (SELECT 1 FROM players WHERE user_id = userId AND lobby_id = lobbyId) THEN
        RAISE EXCEPTION 'Пользователь не в лобби';
    END IF;

    -- Запрос
    RETURN QUERY
    SELECT u.id AS user_id, u.login, p.is_ready
    FROM players p
    JOIN users u ON p.user_id = u.id
    WHERE p.lobby_id = lobbyId;
END;
$$;
 D   DROP FUNCTION s314500.getusersinlobby(tk integer, lobbyid integer);
       s314500          postgres    false    6         	           1255    17098    hashpassword(character varying)    FUNCTION     .  CREATE FUNCTION s314500.hashpassword(password character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Хэширование пароля с добавлением соли 'megasalt'
    RETURN encode(convert_to(CONCAT(password, 'megasalt'), 'UTF8'), 'hex');
END;
$$;
 @   DROP FUNCTION s314500.hashpassword(password character varying);
       s314500          postgres    false    6         
           1255    17099    hello_world()    FUNCTION     }   CREATE FUNCTION s314500.hello_world() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN 'Hello, World!';
END;
$$;
 %   DROP FUNCTION s314500.hello_world();
       s314500          postgres    false    6                    1255    17100    initgame(integer) 	   PROCEDURE     5  CREATE PROCEDURE s314500.initgame(IN id_lobby integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    x integer;
BEGIN
    -- Вызов mashup
    CALL mashup(id_lobby);

    -- Получаем card_id
    SELECT card_id INTO x FROM Cards_in_deck LIMIT 1;

    -- Вставляем карту на стол
    INSERT INTO CardsOnTable 
    SELECT * FROM Cards_in_deck WHERE card_id = x;

    -- Удаляем карту из колоды
    DELETE FROM Cards_in_deck WHERE card_id = x;

    -- Создаём места в лобби
    CALL makePlaces(id_lobby, 4);

    -- Определяем случайного игрока, который начнёт ход
    INSERT INTO Current_Turn (player_id)
    SELECT player_id FROM Players 
    WHERE lobby_id = id_lobby 
    ORDER BY RANDOM() 
    LIMIT 1;
END;
$$;
 6   DROP PROCEDURE s314500.initgame(IN id_lobby integer);
       s314500          postgres    false    6                    1255    17101    isgamestarted(integer)    FUNCTION       CREATE FUNCTION s314500.isgamestarted(lobbyid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM CurrentTurn
        WHERE turn_player_id IN (SELECT id FROM Players WHERE lobby_id = lobbyId)
    );
END;
$$;
 6   DROP FUNCTION s314500.isgamestarted(lobbyid integer);
       s314500          postgres    false    6                    1255    17102    leavelobby(integer, integer)    FUNCTION       CREATE FUNCTION s314500.leavelobby(tk integer, lobbyid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
    currentHostId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RETURN 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Проверка, является ли пользователь хостом
    SELECT host_id INTO currentHostId FROM lobbies WHERE id = lobbyId;
    IF currentHostId = userId THEN
        IF (SELECT COUNT(*) FROM players WHERE lobby_id = lobbyId) > 1 THEN
            UPDATE lobbies
            SET host_id = (
                SELECT user_id
                FROM players
                WHERE lobby_id = lobbyId
                AND user_id != userId
                ORDER BY RANDOM()
                LIMIT 1
            )
            WHERE id = lobbyId;
        ELSE
            DELETE FROM lobbies WHERE id = lobbyId;
        END IF;
    END IF;

    DELETE FROM players WHERE user_id = userId AND lobby_id = lobbyId;
    RETURN 'Выход из лобби выполнен';
END;
$$;
 ?   DROP FUNCTION s314500.leavelobby(tk integer, lobbyid integer);
       s314500          postgres    false    6                    1255    17103 +   login(character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE s314500.login(IN lg character varying, IN pw character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tk bigint;
BEGIN
    -- Генерация случайного токена
    tk := floor(random() * 4000000000) + 1;

    -- Проверка пароля
    IF hashPassword(pw) = (SELECT password FROM Users WHERE login = lg LIMIT 1) THEN
        -- Очистка токенов (предполагается, что процедура clearTokens() уже создана)
        CALL clearTokens();

        -- Вставка нового токена
        INSERT INTO Tokens (token, login) VALUES (tk, lg);

        -- Возвращаем id пользователя и токен

        PERFORM
    (SELECT id FROM Users WHERE login = lg LIMIT 1),
    (SELECT tk FROM Users WHERE login = lg LIMIT 1);
    ELSE
        -- Если логин или пароль неверный
        RAISE EXCEPTION 'Пароль или логин неверный';
    END IF;
END;
$$;
 P   DROP PROCEDURE s314500.login(IN lg character varying, IN pw character varying);
       s314500          postgres    false    6                    1255    17104    logout(integer) 	   PROCEDURE       CREATE PROCEDURE s314500.logout(IN tk integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Удаление токена
    DELETE FROM Tokens WHERE token = tk;

    -- Проверка, были ли удалены строки
    IF NOT FOUND THEN
        -- Если токен не был найден
        RAISE EXCEPTION 'Невалидный токен';
    ELSE
        -- Если токен был успешно удален
        RAISE NOTICE 'Вы успешно вышли из аккаунта';
    END IF;
END;
$$;
 .   DROP PROCEDURE s314500.logout(IN tk integer);
       s314500          postgres    false    6                    1255    17105    make_places(integer, integer) 	   PROCEDURE       CREATE PROCEDURE s314500.make_places(IN id_lobby integer, IN count_cards integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_cards INT;
    count_players INT;
BEGIN
    -- Создание временной таблицы для игроков
    CREATE TEMP TABLE tmp (
        n SERIAL PRIMARY KEY,
        id INT
    ) ON COMMIT DROP;

    -- Заполняем временную таблицу случайным порядком игроков из лобби
    INSERT INTO tmp(id)
    SELECT player_id FROM Players WHERE lobby_id = id_lobby ORDER BY RANDOM();

    -- Подсчитываем количество игроков
    SELECT COUNT(*) INTO count_players FROM tmp;

    -- Вычисляем общее количество карт
    total_cards := count_players * count_cards;

    -- Создание временной таблицы для карт
    CREATE TEMP TABLE tmpCards (
        n SERIAL PRIMARY KEY,
        id_card INT
    ) ON COMMIT DROP;

    -- Заполняем временную таблицу случайными картами из колоды, ограничивая по total_cards
    INSERT INTO tmpCards(id_card)
    SELECT card_id FROM Cards_in_Deck WHERE lobby_id = id_lobby ORDER BY RANDOM() LIMIT total_cards;

    -- Распределяем карты между игроками
    INSERT INTO Cards_in_hand (player_id, card_id)
    SELECT tmp.id AS player_id, tmpCards.id_card
    FROM tmpCards
    JOIN tmp ON tmp.n = (tmpCards.n % count_players) + 1;
	
END $$;
 Q   DROP PROCEDURE s314500.make_places(IN id_lobby integer, IN count_cards integer);
       s314500          postgres    false    6                    1255    17106    makeplaces(integer, integer) 	   PROCEDURE     �  CREATE PROCEDURE s314500.makeplaces(IN id_lobby integer, IN count_cards integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_cards integer;
    count_players integer;
BEGIN
    -- Создание временной таблицы для игроков (случайный порядок)
    CREATE TEMP TABLE tmp (
        n SERIAL PRIMARY KEY, 
        id integer
    ) ON COMMIT DROP;

    -- Заполнение временной таблицы случайно отсортированными игроками
    INSERT INTO tmp(id)
    SELECT player_id FROM Players WHERE lobby_id = id_lobby ORDER BY RANDOM();

    -- Подсчёт количества игроков
    SELECT COUNT(*) INTO count_players FROM tmp;
    
    -- Вычисление общего количества карт
    total_cards := count_players * count_cards;

    CREATE TEMP TABLE tmpCards (
        n SERIAL PRIMARY KEY, 
        id_card integer
    ) ON COMMIT DROP;

    -- Заполнение картами (случайный порядок)
    INSERT INTO tmpCards(id_card)
    SELECT card_id FROM Cards_in_Deck WHERE lobby_id = id_lobby ORDER BY RANDOM() LIMIT total_cards;

    -- Раздача карт игрокам
    INSERT INTO Cards_in_hand (player_id, card_id)
    SELECT tmp.id AS player_id, tmpCards.id_card 
    FROM tmpCards 
    JOIN tmp ON tmp.n = (tmpCards.n % count_players) + 1;

END;
$$;
 P   DROP PROCEDURE s314500.makeplaces(IN id_lobby integer, IN count_cards integer);
       s314500          postgres    false    6                    1255    17107    mashup(integer) 	   PROCEDURE     H  CREATE PROCEDURE s314500.mashup(IN id_lobby integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Вставляем случайно отсортированные карты из cards в cards_in_tables
    INSERT INTO cards_on_table (card_id, lobby_id)
    SELECT card_id, lobby_id FROM cards
    ORDER BY RANDOM();
END;
$$;
 4   DROP PROCEDURE s314500.mashup(IN id_lobby integer);
       s314500          postgres    false    6                    1255    17108 .   register(character varying, character varying) 	   PROCEDURE     �  CREATE PROCEDURE s314500.register(IN login character varying, IN password character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Проверка на минимальную длину пароля и наличие как минимум одной буквы и одной цифры
    IF LENGTH(password) < 6 OR password !~ '[0-9]' OR password !~ '[a-zA-Z]' THEN
        RAISE EXCEPTION 'Пароль должен быть длиной не менее 6 символов и содержать как минимум одну букву и одну цифру';
    END IF;

    -- Вставка пользователя, если логин уникален
    BEGIN
        INSERT INTO Users(login, password) VALUES (login, hashPassword(password));
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'Такой логин уже занят';
    END;

    -- Вызов функции для входа пользователя
    CALL login(login, password);
END;
$$;
 \   DROP PROCEDURE s314500.register(IN login character varying, IN password character varying);
       s314500          postgres    false    6                    1255    17109 #   setready(integer, integer, boolean)    FUNCTION     ?  CREATE FUNCTION s314500.setready(tk integer, lobbyid integer, state boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RETURN 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Проверка, находится ли пользователь в лобби
    IF NOT EXISTS (SELECT 1 FROM players WHERE user_id = userId AND lobby_id = lobbyId) THEN
        RETURN 'Пользователь не в лобби';
    END IF;

    -- Обновление статуса готовности
    UPDATE players
    SET is_ready = state
    WHERE user_id = userId AND lobby_id = lobbyId;

    -- Возвращаем обновленную информацию о лобби
    PERFORM getUsersInLobby(tk, lobbyId);
    RETURN 'Готовность обновлена';
END;
$$;
 L   DROP FUNCTION s314500.setready(tk integer, lobbyid integer, state boolean);
       s314500          postgres    false    6                    1255    17110    showavailablegames(integer)    FUNCTION     "  CREATE FUNCTION s314500.showavailablegames(tk integer) RETURNS TABLE(id integer, usercount integer, haspassword boolean, hostlogin character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM Tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM Users WHERE login = userLogin;

    -- Запрос
    RETURN QUERY
    SELECT p.lobby_id AS id,
           COUNT(*) AS userCount,
           CASE WHEN l.password IS NOT NULL THEN TRUE ELSE FALSE END AS hasPassword,
           u.login AS hostLogin
    FROM players p
    LEFT JOIN players p2 ON p2.lobby_id = p.lobby_id AND p2.user_id = userId
    INNER JOIN lobbies l ON p.lobby_id = l.id
    LEFT JOIN users u ON l.host_id = u.id
    WHERE p2.user_id IS NULL
    GROUP BY p.lobby_id, l.password, u.login
    HAVING COUNT(*) < 4;
END;
$$;
 6   DROP FUNCTION s314500.showavailablegames(tk integer);
       s314500          postgres    false    6                    1255    17111    showuserinfo(integer) 	   PROCEDURE     /  CREATE PROCEDURE s314500.showuserinfo(IN tk integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
BEGIN
    -- Проверка на валидность токена
    SELECT login INTO userLogin FROM Tokens WHERE token = tk;

    IF userLogin IS NULL THEN
        -- Если токен не найден
        RAISE EXCEPTION 'Невалидный токен';
    ELSE
        -- Запрос информации о пользователе
        PERFORM (SELECT login FROM Users WHERE login = userLogin);
    END IF;
END;
$$;
 4   DROP PROCEDURE s314500.showuserinfo(IN tk integer);
       s314500          postgres    false    6         �            1255    17112    showuserpl() 	   PROCEDURE     �   CREATE PROCEDURE s314500.showuserpl()
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Запрос информации о всех пользователях
    PERFORM (SELECT login FROM Users);
END;
$$;
 %   DROP PROCEDURE s314500.showuserpl();
       s314500          postgres    false    6         �            1255    17113    startgame(integer)    FUNCTION     t  CREATE FUNCTION s314500.startgame(lobbyid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    currentHostId INT;
BEGIN
    -- Получаем хоста лобби
    SELECT host_id INTO currentHostId FROM lobbies WHERE id = lobbyId;

    -- Проверка, что хост запускает игру
    IF currentHostId != (SELECT id FROM users WHERE login = userLogin) THEN
        RETURN 'Только хост может начать игру';
    END IF;

    -- Запуск игры
    UPDATE lobbies SET state = 'inProgress' WHERE id = lobbyId;
    
    RETURN 'Игра началась';
END;
$$;
 2   DROP FUNCTION s314500.startgame(lobbyid integer);
       s314500          postgres    false    6         �            1255    17114    type_of_card(integer)    FUNCTION     �   CREATE FUNCTION s314500.type_of_card(p_card integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE 

	out integer;

BEGIN 

SELECT card_type_id FROM cards WHERE card_id = p_card 
INTO out;

RETURN out;

END;$$;
 4   DROP FUNCTION s314500.type_of_card(p_card integer);
       s314500          postgres    false    6         �            1259    17115    cards    TABLE     `   CREATE TABLE s314500.cards (
    card_id integer NOT NULL,
    card_type_id integer NOT NULL
);
    DROP TABLE s314500.cards;
       s314500         heap    postgres    false    6         �            1259    17118    cards_card_id_seq    SEQUENCE     �   CREATE SEQUENCE s314500.cards_card_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE s314500.cards_card_id_seq;
       s314500          postgres    false    6    216                    0    0    cards_card_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE s314500.cards_card_id_seq OWNED BY s314500.cards.card_id;
          s314500          postgres    false    217         �            1259    17119    cards_in_deck    TABLE     d   CREATE TABLE s314500.cards_in_deck (
    card_id integer NOT NULL,
    lobby_id integer NOT NULL
);
 "   DROP TABLE s314500.cards_in_deck;
       s314500         heap    postgres    false    6         �            1259    17122    cards_in_hand    TABLE     e   CREATE TABLE s314500.cards_in_hand (
    card_id integer NOT NULL,
    player_id integer NOT NULL
);
 "   DROP TABLE s314500.cards_in_hand;
       s314500         heap    postgres    false    6         �            1259    17125    cards_on_table    TABLE     �   CREATE TABLE s314500.cards_on_table (
    card_id integer NOT NULL,
    lobby_id integer NOT NULL,
    x smallint NOT NULL,
    y smallint NOT NULL
);
 #   DROP TABLE s314500.cards_on_table;
       s314500         heap    postgres    false    6         �            1259    17128    cardstypes_id_seq    SEQUENCE     {   CREATE SEQUENCE s314500.cardstypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 66
    CACHE 1;
 )   DROP SEQUENCE s314500.cardstypes_id_seq;
       s314500          postgres    false    6         �            1259    17129    cards_types    TABLE     �  CREATE TABLE s314500.cards_types (
    id integer DEFAULT nextval('s314500.cardstypes_id_seq'::regclass) NOT NULL,
    shape text,
    number smallint,
    color text,
    CONSTRAINT cardstypes_color_check CHECK ((color = ANY (ARRAY['Blue'::text, 'Yellow'::text, 'Red'::text, 'Green'::text]))),
    CONSTRAINT cardstypes_number_check CHECK ((number >= 0)),
    CONSTRAINT cardstypes_shape_check CHECK ((shape = ANY (ARRAY['Square'::text, 'Triangle'::text, 'Circle'::text, 'Cross'::text])))
);
     DROP TABLE s314500.cards_types;
       s314500         heap    postgres    false    221    6         �            1259    17138    current_turn    TABLE     {   CREATE TABLE s314500.current_turn (
    player_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL
);
 !   DROP TABLE s314500.current_turn;
       s314500         heap    postgres    false    6         �            1259    17141    lobbies    TABLE     �   CREATE TABLE s314500.lobbies (
    id integer NOT NULL,
    password character varying(10),
    turn_time integer DEFAULT 30 NOT NULL,
    host_id integer,
    state character varying DEFAULT 'waiting'::character varying NOT NULL
);
    DROP TABLE s314500.lobbies;
       s314500         heap    postgres    false    6         �            1259    17148    lobbies_id_seq    SEQUENCE     �   CREATE SEQUENCE s314500.lobbies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE s314500.lobbies_id_seq;
       s314500          postgres    false    224    6                    0    0    lobbies_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE s314500.lobbies_id_seq OWNED BY s314500.lobbies.id;
          s314500          postgres    false    225         �            1259    17149    players    TABLE       CREATE TABLE s314500.players (
    id integer NOT NULL,
    lobby_id integer NOT NULL,
    login character varying(20) NOT NULL,
    nickname character varying(15) NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    is_ready boolean DEFAULT false NOT NULL
);
    DROP TABLE s314500.players;
       s314500         heap    postgres    false    6         �            1259    17154    players_id_seq    SEQUENCE     �   CREATE SEQUENCE s314500.players_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE s314500.players_id_seq;
       s314500          postgres    false    6    226                    0    0    players_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE s314500.players_id_seq OWNED BY s314500.players.id;
          s314500          postgres    false    227         �            1259    17155    t_card_color    TABLE     X   CREATE TABLE s314500.t_card_color (
    id smallint NOT NULL,
    name text NOT NULL
);
 !   DROP TABLE s314500.t_card_color;
       s314500         heap    postgres    false    6         �            1259    17160    t_card_number    TABLE     _   CREATE TABLE s314500.t_card_number (
    id smallint NOT NULL,
    number smallint NOT NULL
);
 "   DROP TABLE s314500.t_card_number;
       s314500         heap    postgres    false    6         �            1259    17163    t_card_shape    TABLE     X   CREATE TABLE s314500.t_card_shape (
    id smallint NOT NULL,
    name text NOT NULL
);
 !   DROP TABLE s314500.t_card_shape;
       s314500         heap    postgres    false    6         �            1259    17168 
   test_table    TABLE     <   CREATE TABLE s314500.test_table (
    x integer NOT NULL
);
    DROP TABLE s314500.test_table;
       s314500         heap    postgres    false    6         �            1259    17171    tokens    TABLE     �   CREATE TABLE s314500.tokens (
    login character varying(64) NOT NULL,
    token bigint NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL
);
    DROP TABLE s314500.tokens;
       s314500         heap    postgres    false    6         �            1259    17175    users    TABLE     �   CREATE TABLE s314500.users (
    login character varying(20) NOT NULL,
    password character varying(50) NOT NULL,
    id integer NOT NULL
);
    DROP TABLE s314500.users;
       s314500         heap    postgres    false    6         �            1259    17178    users_id_seq    SEQUENCE     �   CREATE SEQUENCE s314500.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE s314500.users_id_seq;
       s314500          postgres    false    6    233                    0    0    users_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE s314500.users_id_seq OWNED BY s314500.users.id;
          s314500          postgres    false    234         �            1259    17179    users_in_lobby    TABLE     q   CREATE TABLE s314500.users_in_lobby (
    lobby_id integer NOT NULL,
    login character varying(20) NOT NULL
);
 #   DROP TABLE s314500.users_in_lobby;
       s314500         heap    postgres    false    6         0           2604    17182    cards card_id    DEFAULT     p   ALTER TABLE ONLY s314500.cards ALTER COLUMN card_id SET DEFAULT nextval('s314500.cards_card_id_seq'::regclass);
 =   ALTER TABLE s314500.cards ALTER COLUMN card_id DROP DEFAULT;
       s314500          postgres    false    217    216         2           2604    17183 
   lobbies id    DEFAULT     j   ALTER TABLE ONLY s314500.lobbies ALTER COLUMN id SET DEFAULT nextval('s314500.lobbies_id_seq'::regclass);
 :   ALTER TABLE s314500.lobbies ALTER COLUMN id DROP DEFAULT;
       s314500          postgres    false    225    224         5           2604    17184 
   players id    DEFAULT     j   ALTER TABLE ONLY s314500.players ALTER COLUMN id SET DEFAULT nextval('s314500.players_id_seq'::regclass);
 :   ALTER TABLE s314500.players ALTER COLUMN id DROP DEFAULT;
       s314500          postgres    false    227    226         9           2604    17185    users id    DEFAULT     f   ALTER TABLE ONLY s314500.users ALTER COLUMN id SET DEFAULT nextval('s314500.users_id_seq'::regclass);
 8   ALTER TABLE s314500.users ALTER COLUMN id DROP DEFAULT;
       s314500          postgres    false    234    233         �          0    17115    cards 
   TABLE DATA           7   COPY s314500.cards (card_id, card_type_id) FROM stdin;
    s314500          postgres    false    216       3580.dat �          0    17119    cards_in_deck 
   TABLE DATA           ;   COPY s314500.cards_in_deck (card_id, lobby_id) FROM stdin;
    s314500          postgres    false    218       3582.dat �          0    17122    cards_in_hand 
   TABLE DATA           <   COPY s314500.cards_in_hand (card_id, player_id) FROM stdin;
    s314500          postgres    false    219       3583.dat            0    17125    cards_on_table 
   TABLE DATA           B   COPY s314500.cards_on_table (card_id, lobby_id, x, y) FROM stdin;
    s314500          postgres    false    220       3584.dat           0    17129    cards_types 
   TABLE DATA           @   COPY s314500.cards_types (id, shape, number, color) FROM stdin;
    s314500          postgres    false    222       3586.dat           0    17138    current_turn 
   TABLE DATA           >   COPY s314500.current_turn (player_id, start_time) FROM stdin;
    s314500          postgres    false    223       3587.dat           0    17141    lobbies 
   TABLE DATA           K   COPY s314500.lobbies (id, password, turn_time, host_id, state) FROM stdin;
    s314500          postgres    false    224       3588.dat           0    17149    players 
   TABLE DATA           S   COPY s314500.players (id, lobby_id, login, nickname, points, is_ready) FROM stdin;
    s314500          postgres    false    226       3590.dat           0    17155    t_card_color 
   TABLE DATA           1   COPY s314500.t_card_color (id, name) FROM stdin;
    s314500          postgres    false    228       3592.dat 	          0    17160    t_card_number 
   TABLE DATA           4   COPY s314500.t_card_number (id, number) FROM stdin;
    s314500          postgres    false    229       3593.dat 
          0    17163    t_card_shape 
   TABLE DATA           1   COPY s314500.t_card_shape (id, name) FROM stdin;
    s314500          postgres    false    230       3594.dat           0    17168 
   test_table 
   TABLE DATA           (   COPY s314500.test_table (x) FROM stdin;
    s314500          postgres    false    231       3595.dat           0    17171    tokens 
   TABLE DATA           8   COPY s314500.tokens (login, token, created) FROM stdin;
    s314500          postgres    false    232       3596.dat           0    17175    users 
   TABLE DATA           5   COPY s314500.users (login, password, id) FROM stdin;
    s314500          postgres    false    233       3597.dat           0    17179    users_in_lobby 
   TABLE DATA           :   COPY s314500.users_in_lobby (lobby_id, login) FROM stdin;
    s314500          postgres    false    235       3599.dat            0    0    cards_card_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('s314500.cards_card_id_seq', 1, false);
          s314500          postgres    false    217                    0    0    cardstypes_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('s314500.cardstypes_id_seq', 1, false);
          s314500          postgres    false    221                    0    0    lobbies_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('s314500.lobbies_id_seq', 19, true);
          s314500          postgres    false    225                    0    0    players_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('s314500.players_id_seq', 3, true);
          s314500          postgres    false    227                    0    0    users_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('s314500.users_id_seq', 42, true);
          s314500          postgres    false    234         >           2606    17187    cards cards_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY s314500.cards
    ADD CONSTRAINT cards_pkey PRIMARY KEY (card_id);
 ;   ALTER TABLE ONLY s314500.cards DROP CONSTRAINT cards_pkey;
       s314500            postgres    false    216         @           2606    17189    cards_in_deck cardsindeck_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY s314500.cards_in_deck
    ADD CONSTRAINT cardsindeck_pkey PRIMARY KEY (card_id);
 I   ALTER TABLE ONLY s314500.cards_in_deck DROP CONSTRAINT cardsindeck_pkey;
       s314500            postgres    false    218         B           2606    17191    cards_in_hand cardsinhand_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY s314500.cards_in_hand
    ADD CONSTRAINT cardsinhand_pkey PRIMARY KEY (card_id);
 I   ALTER TABLE ONLY s314500.cards_in_hand DROP CONSTRAINT cardsinhand_pkey;
       s314500            postgres    false    219         D           2606    17193     cards_on_table cardsontable_pkey 
   CONSTRAINT     d   ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cardsontable_pkey PRIMARY KEY (card_id);
 K   ALTER TABLE ONLY s314500.cards_on_table DROP CONSTRAINT cardsontable_pkey;
       s314500            postgres    false    220         H           2606    17195    cards_types cardstypes_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY s314500.cards_types
    ADD CONSTRAINT cardstypes_pkey PRIMARY KEY (id);
 F   ALTER TABLE ONLY s314500.cards_types DROP CONSTRAINT cardstypes_pkey;
       s314500            postgres    false    222         L           2606    17197    current_turn currentturn_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY s314500.current_turn
    ADD CONSTRAINT currentturn_pkey PRIMARY KEY (player_id);
 H   ALTER TABLE ONLY s314500.current_turn DROP CONSTRAINT currentturn_pkey;
       s314500            postgres    false    223         N           2606    17199    lobbies lobbies_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY s314500.lobbies
    ADD CONSTRAINT lobbies_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY s314500.lobbies DROP CONSTRAINT lobbies_pkey;
       s314500            postgres    false    224         P           2606    17201    players players_pkey 
   CONSTRAINT     S   ALTER TABLE ONLY s314500.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);
 ?   ALTER TABLE ONLY s314500.players DROP CONSTRAINT players_pkey;
       s314500            postgres    false    226         T           2606    17203    t_card_color t_card_color_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY s314500.t_card_color
    ADD CONSTRAINT t_card_color_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY s314500.t_card_color DROP CONSTRAINT t_card_color_pkey;
       s314500            postgres    false    228         V           2606    17205     t_card_number t_card_number_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY s314500.t_card_number
    ADD CONSTRAINT t_card_number_pkey PRIMARY KEY (id);
 K   ALTER TABLE ONLY s314500.t_card_number DROP CONSTRAINT t_card_number_pkey;
       s314500            postgres    false    229         X           2606    17207    t_card_shape t_card_shape_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY s314500.t_card_shape
    ADD CONSTRAINT t_card_shape_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY s314500.t_card_shape DROP CONSTRAINT t_card_shape_pkey;
       s314500            postgres    false    230         Z           2606    17209    test_table test_table_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY s314500.test_table
    ADD CONSTRAINT test_table_pkey PRIMARY KEY (x);
 E   ALTER TABLE ONLY s314500.test_table DROP CONSTRAINT test_table_pkey;
       s314500            postgres    false    231         \           2606    17211    tokens tokens_pkey 
   CONSTRAINT     T   ALTER TABLE ONLY s314500.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (token);
 =   ALTER TABLE ONLY s314500.tokens DROP CONSTRAINT tokens_pkey;
       s314500            postgres    false    232         F           2606    17213    cards_on_table unique_lobby_xy 
   CONSTRAINT     d   ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT unique_lobby_xy UNIQUE (lobby_id, x, y);
 I   ALTER TABLE ONLY s314500.cards_on_table DROP CONSTRAINT unique_lobby_xy;
       s314500            postgres    false    220    220    220         R           2606    17215    players unique_login_lobby 
   CONSTRAINT     a   ALTER TABLE ONLY s314500.players
    ADD CONSTRAINT unique_login_lobby UNIQUE (login, lobby_id);
 E   ALTER TABLE ONLY s314500.players DROP CONSTRAINT unique_login_lobby;
       s314500            postgres    false    226    226         J           2606    17217 %   cards_types unique_shape_number_color 
   CONSTRAINT     q   ALTER TABLE ONLY s314500.cards_types
    ADD CONSTRAINT unique_shape_number_color UNIQUE (shape, number, color);
 P   ALTER TABLE ONLY s314500.cards_types DROP CONSTRAINT unique_shape_number_color;
       s314500            postgres    false    222    222    222         ^           2606    17219    users users_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY s314500.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (login);
 ;   ALTER TABLE ONLY s314500.users DROP CONSTRAINT users_pkey;
       s314500            postgres    false    233         `           2606    17221     users_in_lobby usersinlobby_pkey 
   CONSTRAINT     l   ALTER TABLE ONLY s314500.users_in_lobby
    ADD CONSTRAINT usersinlobby_pkey PRIMARY KEY (lobby_id, login);
 K   ALTER TABLE ONLY s314500.users_in_lobby DROP CONSTRAINT usersinlobby_pkey;
       s314500            postgres    false    235    235         a           2606    17222 &   cards_in_deck cardsindeck_card_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.cards_in_deck
    ADD CONSTRAINT cardsindeck_card_id_fkey FOREIGN KEY (card_id) REFERENCES s314500.cards(card_id) ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY s314500.cards_in_deck DROP CONSTRAINT cardsindeck_card_id_fkey;
       s314500          postgres    false    216    3390    218         b           2606    17227 '   cards_in_deck cardsindeck_lobby_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.cards_in_deck
    ADD CONSTRAINT cardsindeck_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.lobbies(id) ON DELETE CASCADE;
 R   ALTER TABLE ONLY s314500.cards_in_deck DROP CONSTRAINT cardsindeck_lobby_id_fkey;
       s314500          postgres    false    224    3406    218         c           2606    17232 &   cards_in_hand cardsinhand_card_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.cards_in_hand
    ADD CONSTRAINT cardsinhand_card_id_fkey FOREIGN KEY (card_id) REFERENCES s314500.cards(card_id) ON DELETE RESTRICT;
 Q   ALTER TABLE ONLY s314500.cards_in_hand DROP CONSTRAINT cardsinhand_card_id_fkey;
       s314500          postgres    false    3390    216    219         d           2606    17237 (   cards_in_hand cardsinhand_player_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.cards_in_hand
    ADD CONSTRAINT cardsinhand_player_id_fkey FOREIGN KEY (player_id) REFERENCES s314500.players(id) ON DELETE CASCADE;
 S   ALTER TABLE ONLY s314500.cards_in_hand DROP CONSTRAINT cardsinhand_player_id_fkey;
       s314500          postgres    false    226    3408    219         e           2606    17242 (   cards_on_table cardsontable_card_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cardsontable_card_id_fkey FOREIGN KEY (card_id) REFERENCES s314500.cards(card_id) ON DELETE RESTRICT;
 S   ALTER TABLE ONLY s314500.cards_on_table DROP CONSTRAINT cardsontable_card_id_fkey;
       s314500          postgres    false    216    220    3390         f           2606    17247 )   cards_on_table cardsontable_lobby_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cardsontable_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.lobbies(id) ON DELETE CASCADE;
 T   ALTER TABLE ONLY s314500.cards_on_table DROP CONSTRAINT cardsontable_lobby_id_fkey;
       s314500          postgres    false    224    220    3406         g           2606    17252 '   current_turn currentturn_player_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.current_turn
    ADD CONSTRAINT currentturn_player_id_fkey FOREIGN KEY (player_id) REFERENCES s314500.players(id) ON DELETE CASCADE;
 R   ALTER TABLE ONLY s314500.current_turn DROP CONSTRAINT currentturn_player_id_fkey;
       s314500          postgres    false    223    226    3408         h           2606    17257    players players_lobby_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.players
    ADD CONSTRAINT players_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.lobbies(id) ON DELETE CASCADE;
 H   ALTER TABLE ONLY s314500.players DROP CONSTRAINT players_lobby_id_fkey;
       s314500          postgres    false    226    224    3406         i           2606    17262    players players_login_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.players
    ADD CONSTRAINT players_login_fkey FOREIGN KEY (login) REFERENCES s314500.users(login) ON DELETE RESTRICT;
 E   ALTER TABLE ONLY s314500.players DROP CONSTRAINT players_login_fkey;
       s314500          postgres    false    226    3422    233         j           2606    17267    tokens tokens_login_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.tokens
    ADD CONSTRAINT tokens_login_fkey FOREIGN KEY (login) REFERENCES s314500.users(login) ON DELETE CASCADE;
 C   ALTER TABLE ONLY s314500.tokens DROP CONSTRAINT tokens_login_fkey;
       s314500          postgres    false    3422    232    233         k           2606    17272 )   users_in_lobby usersinlobby_lobby_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.users_in_lobby
    ADD CONSTRAINT usersinlobby_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.lobbies(id) ON DELETE CASCADE;
 T   ALTER TABLE ONLY s314500.users_in_lobby DROP CONSTRAINT usersinlobby_lobby_id_fkey;
       s314500          postgres    false    3406    235    224         l           2606    17277 &   users_in_lobby usersinlobby_login_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.users_in_lobby
    ADD CONSTRAINT usersinlobby_login_fkey FOREIGN KEY (login) REFERENCES s314500.users(login) ON DELETE CASCADE;
 Q   ALTER TABLE ONLY s314500.users_in_lobby DROP CONSTRAINT usersinlobby_login_fkey;
       s314500          postgres    false    233    235    3422                                                                                                                                                                                                              3580.dat                                                                                            0000600 0004000 0002000 00000000577 14767066671 0014306 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	2
3	3
4	4
5	5
6	6
7	7
8	8
9	9
10	10
11	11
12	12
13	13
14	14
15	15
16	16
17	17
18	18
19	19
20	20
21	21
22	22
23	23
24	24
25	25
26	26
27	27
28	28
29	29
30	30
31	31
32	32
33	33
34	34
35	35
36	36
37	37
38	38
39	39
40	40
41	41
42	42
43	43
44	44
45	45
46	46
47	47
48	48
49	49
50	50
51	51
52	52
53	53
54	54
55	55
56	56
57	57
58	58
59	59
60	60
61	61
62	62
63	63
64	64
65	65
66	66
\.


                                                                                                                                 3582.dat                                                                                            0000600 0004000 0002000 00000000005 14767066671 0014272 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           3583.dat                                                                                            0000600 0004000 0002000 00000000005 14767066671 0014273 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           3584.dat                                                                                            0000600 0004000 0002000 00000000055 14767066671 0014301 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1	0	0
2	1	1	0
3	1	2	0
4	1	3	0
5	1	2	1
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   3586.dat                                                                                            0000600 0004000 0002000 00000002204 14767066671 0014301 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	Square	1	Blue
2	Square	1	Yellow
3	Square	1	Red
4	Square	1	Green
5	Square	2	Blue
6	Square	2	Yellow
7	Square	2	Red
8	Square	2	Green
9	Square	3	Blue
10	Square	3	Yellow
11	Square	3	Red
12	Square	3	Green
13	Square	4	Blue
14	Square	4	Yellow
15	Square	4	Red
16	Square	4	Green
17	Triangle	1	Blue
18	Triangle	1	Yellow
19	Triangle	1	Red
20	Triangle	1	Green
21	Triangle	2	Blue
22	Triangle	2	Yellow
23	Triangle	2	Red
24	Triangle	2	Green
25	Triangle	3	Blue
26	Triangle	3	Yellow
27	Triangle	3	Red
28	Triangle	3	Green
29	Triangle	4	Blue
30	Triangle	4	Yellow
31	Triangle	4	Red
32	Triangle	4	Green
33	Circle	1	Blue
34	Circle	1	Yellow
35	Circle	1	Red
36	Circle	1	Green
37	Circle	2	Blue
38	Circle	2	Yellow
39	Circle	2	Red
40	Circle	2	Green
41	Circle	3	Blue
42	Circle	3	Yellow
43	Circle	3	Red
44	Circle	3	Green
45	Circle	4	Blue
46	Circle	4	Yellow
47	Circle	4	Red
48	Circle	4	Green
49	Cross	1	Blue
50	Cross	1	Yellow
51	Cross	1	Red
52	Cross	1	Green
53	Cross	2	Blue
54	Cross	2	Yellow
55	Cross	2	Red
56	Cross	2	Green
57	Cross	3	Blue
58	Cross	3	Yellow
59	Cross	3	Red
60	Cross	3	Green
61	Cross	4	Blue
62	Cross	4	Yellow
63	Cross	4	Red
64	Cross	4	Green
65	\N	\N	\N
66	\N	\N	\N
\.


                                                                                                                                                                                                                                                                                                                                                                                            3587.dat                                                                                            0000600 0004000 0002000 00000000005 14767066671 0014277 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           3588.dat                                                                                            0000600 0004000 0002000 00000000110 14767066671 0014275 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	12345678	60	\N	waiting
11	qwerty	60	8	Start
17	qwerty	60	8	Start
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                        3590.dat                                                                                            0000600 0004000 0002000 00000000067 14767066671 0014301 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        8	11	TestUser	Tester	0	t
1	17	TestUser	Tester	0	t
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                         3592.dat                                                                                            0000600 0004000 0002000 00000000043 14767066671 0014275 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	Yellow
2	Green
3	Red
4	Blue
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             3593.dat                                                                                            0000600 0004000 0002000 00000000025 14767066671 0014276 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	2
3	3
4	4
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           3594.dat                                                                                            0000600 0004000 0002000 00000000052 14767066671 0014277 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	Circle
2	Triangle
3	Square
4	Cross
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      3595.dat                                                                                            0000600 0004000 0002000 00000000047 14767066671 0014304 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1
2
3
4
5
6
8
9
12
13
14
21
22
23
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         3596.dat                                                                                            0000600 0004000 0002000 00000000302 14767066671 0014277 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        TestUser	1076758434	2025-03-16 22:53:09.790649
TestUser2	357352692	2025-03-16 22:54:17.350104
TestUser3	466720616	2025-03-16 22:57:47.070035
TestUser4	1154052900	2025-03-16 23:06:17.176119
\.


                                                                                                                                                                                                                                                                                                                              3597.dat                                                                                            0000600 0004000 0002000 00000000352 14767066671 0014305 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        vasya	7661733132336d65676173616c74	5
TestUser	7177657274793132336d65676173616c74	8
TestUser2	7177657274793132336d65676173616c74	13
TestUser3	7177657274793132336d65676173616c74	21
TestUser4	717765727479313233346d65676173616c74	42
\.


                                                                                                                                                                                                                                                                                      3599.dat                                                                                            0000600 0004000 0002000 00000000005 14767066671 0014302 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           restore.sql                                                                                         0000600 0004000 0002000 00000146500 14767066671 0015416 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
-- NOTE:
--
-- File paths need to be edited. Search for $$PATH$$ and
-- replace it with the path to the directory containing
-- the extracted data files.
--
--
-- PostgreSQL database dump
--

-- Dumped from database version 16.8 (Ubuntu 16.8-0ubuntu0.24.04.1)
-- Dumped by pg_dump version 16.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

DROP DATABASE yota2;
--
-- Name: yota2; Type: DATABASE; Schema: -; Owner: postgres
--

CREATE DATABASE yota2 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE yota2 OWNER TO postgres;

\connect yota2

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: s314500; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA s314500;


ALTER SCHEMA s314500 OWNER TO postgres;

--
-- Name: check_card_validity(integer, integer, integer, integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.check_card_validity(p_lobby integer, p_x integer, p_y integer, p_type integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE 
	x_shapes text;
	x_numbers smallint; 
	x_colors text;

	y_shapes text;
	y_numbers smallint; 
	y_colors text;

	x_count integer; 
	y_count integer;

	shape text;
	number smallint;
	color text;
BEGIN

	SELECT t.shape, t.number, t.color from cards c 
	JOIN cards_types t ON c.card_type_id = t.id
	WHERE c.card_id = p_type
	INTO shape, number, color;

	-- Если место уже занято
	IF EXISTS (SELECT 1 FROM get_cards_on_table(p_lobby) WHERE x = p_x AND y = p_y) THEN
		RAISE NOTICE 'Клетка уже занята';
		RETURN FALSE;
	END IF;

	-- Если не найдено соседних клеток
	IF NOT EXISTS (SELECT 1 FROM get_adjacent_cards(p_lobby, p_x, p_y)) THEN 
		RAISE NOTICE 'У клетки должен быть хоть один сосед';
		RETURN FALSE;
	END IF;

	SELECT COUNT (1) FROM get_adjacent_cards(p_lobby, p_x, p_y) a
	WHERE a.x = p_x 
	INTO x_count;

	IF x_count > 3 THEN
		RAISE NOTICE 'Слишком много соседей по горизонтали';
		RETURN FALSE;
	END IF;

	SELECT COUNT (1) FROM get_adjacent_cards(p_lobby, p_x, p_y) a
	WHERE a.y = p_y 
	INTO y_count;
	
	IF y_count > 3 THEN
		RAISE NOTICE 'Слишком много соседей по вертикали';
		RETURN FALSE;
	END IF;

	IF NOT (p_type IN (SELECT id FROM get_possible_cards(p_lobby, p_x, p_y))) THEN 
		RAISE NOTICE 'Карта не подходит';
		RETURN FALSE;
	END IF;

	RETURN TRUE;

END; 
$$;


ALTER FUNCTION s314500.check_card_validity(p_lobby integer, p_x integer, p_y integer, p_type integer) OWNER TO postgres;

--
-- Name: checktoken(integer); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.checktoken(IN tk integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tokenExists BOOLEAN;
BEGIN
    -- Проверка существования токена
    SELECT EXISTS (SELECT 1 FROM Tokens WHERE token = tk) INTO tokenExists;
    RAISE NOTICE 'isValid: %', tokenExists;
END;
$$;


ALTER PROCEDURE s314500.checktoken(IN tk integer) OWNER TO postgres;

--
-- Name: cleartokens(); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.cleartokens()
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Удаление старых токенов (больше чем 7 дней)
    DELETE FROM Tokens WHERE created < NOW() - INTERVAL '7 days';
END;
$$;


ALTER PROCEDURE s314500.cleartokens() OWNER TO postgres;

--
-- Name: createlobby(integer, character varying, integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.createlobby(tk integer, pw character varying, turnt integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
    lobbyId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Создаем лобби
    INSERT INTO lobbies (password, turn_time, host_id, state)
    VALUES (pw, turnT, userId, 'Start')
    RETURNING id INTO lobbyId;

    -- Добавляем пользователя в лобби
    INSERT INTO players (id,login, lobby_id, is_ready)
    VALUES (userId, userLogin, lobbyId, true);

    RETURN lobbyId;
END;
$$;


ALTER FUNCTION s314500.createlobby(tk integer, pw character varying, turnt integer) OWNER TO postgres;

--
-- Name: createlobby(integer, character varying, character varying, integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.createlobby(tk integer, p_nickname character varying, pw character varying, turnt integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
    lobbyId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Создаем лобби
    INSERT INTO lobbies (password, turn_time, host_id, state)
    VALUES (pw, turnT, userId, 'Start')
    RETURNING id INTO lobbyId;

    -- Добавляем пользователя в лобби
    INSERT INTO players (login, nickname, lobby_id, is_ready)
    VALUES (userLogin, p_nickname, lobbyId, true);

    RETURN lobbyId;
END;
$$;


ALTER FUNCTION s314500.createlobby(tk integer, p_nickname character varying, pw character varying, turnt integer) OWNER TO postgres;

--
-- Name: enterlobby(integer, integer, character varying); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.enterlobby(tk integer, lobbyid integer, inputpassword character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
    actualPassword VARCHAR(10);
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RETURN 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Проверка, что пользователь не в лобби
    IF EXISTS (SELECT 1 FROM players WHERE user_id = userId AND lobby_id = lobbyId) THEN
        RETURN 'Пользователь уже в лобби';
    END IF;

    -- Проверка на пароль
    SELECT password INTO actualPassword FROM lobbies WHERE id = lobbyId;
    IF actualPassword IS NOT NULL AND inputPassword != actualPassword THEN
        RETURN 'Неверный пароль';
    END IF;

    -- Проверка на максимальное количество игроков
    IF (SELECT COUNT(*) FROM players WHERE lobby_id = lobbyId) = 4 THEN
        RETURN 'Лобби полное';
    END IF;

    -- Вход в лобби
    INSERT INTO players (user_id, lobby_id) VALUES (userId, lobbyId);
    RETURN 'Вход в лобби выполнен';
END;
$$;


ALTER FUNCTION s314500.enterlobby(tk integer, lobbyid integer, inputpassword character varying) OWNER TO postgres;

--
-- Name: get_adjacent_cards(integer, integer, integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.get_adjacent_cards(p_lobby integer, p_x integer, p_y integer) RETURNS TABLE(x smallint, y smallint, shape text, color text, number smallint)
    LANGUAGE plpgsql
    AS $$
BEGIN 

    RETURN QUERY 
    WITH RECURSIVE 
    left_x_neighbors AS (
        -- Находим ближайшее существующее значение x, которое меньше param
        (SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t WHERE t.x = p_x - 1 AND t.y = p_y)
        UNION ALL
        -- Добавляем предыдущее значение, если оно есть
        SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t
        JOIN left_x_neighbors n ON t.x = n.x - 1
        WHERE t.y = p_y
    ),
    
    right_x_neighbors AS (
        -- Находим ближайшее существующее значение x, которое больше param
        (SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t WHERE t.x = p_x + 1 AND t.y = p_y)
        UNION ALL
        -- Добавляем следующее значение, если оно есть
        SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t
        JOIN right_x_neighbors n ON t.x = n.x + 1
        WHERE t.y = p_y
    ),
    
    left_y_neighbors AS (
        -- Находим ближайшее существующее значение y, которое меньше param
        (SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t WHERE t.y = p_y - 1 AND t.x = p_x)
        UNION ALL
        -- Добавляем предыдущее значение, если оно есть
        SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t
        JOIN left_y_neighbors n ON t.y = n.y - 1
        WHERE t.x = p_x
    ),

    right_y_neighbors AS (
        -- Находим ближайшее существующее значение y, которое больше param
        (SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t WHERE t.y = p_y + 1 AND t.x = p_x)
        UNION ALL
        -- Добавляем следующее значение, если оно есть
        SELECT t.x, t.y, t.shape, t.color, t.number FROM get_cards_on_table(p_lobby) t
        JOIN right_y_neighbors n ON t.y = n.y + 1
        WHERE t.x = p_x
    )

    SELECT lx.x, lx.y, lx.shape, lx.color, lx.number FROM left_x_neighbors lx
    UNION 
    SELECT rx.x, rx.y, rx.shape, rx.color, rx.number FROM right_x_neighbors rx
    UNION 
    SELECT ly.x, ly.y, ly.shape, ly.color, ly.number FROM left_y_neighbors ly
    UNION 
    SELECT ry.x, ry.y, ry.shape, ry.color, ry.number FROM right_y_neighbors ry;

END 
$$;


ALTER FUNCTION s314500.get_adjacent_cards(p_lobby integer, p_x integer, p_y integer) OWNER TO postgres;

--
-- Name: get_cards_on_table(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.get_cards_on_table(lobby integer) RETURNS TABLE(x smallint, y smallint, shape text, color text, number smallint)
    LANGUAGE plpgsql
    AS $$BEGIN 

RETURN QUERY
SELECT pos.x, pos.y, c.shape, c.color, c.number FROM cards_on_table pos 
LEFT JOIN cards ON pos.card_id = cards.card_id 
LEFT JOIN cards_types c ON cards.card_id = c.id
WHERE pos.lobby_id = lobby;

END;$$;


ALTER FUNCTION s314500.get_cards_on_table(lobby integer) OWNER TO postgres;

--
-- Name: get_possible_cards(integer, integer, integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.get_possible_cards(p_lobby integer, p_x integer, p_y integer) RETURNS TABLE(id integer, possible_color text, possible_shape text, possible_number smallint)
    LANGUAGE plpgsql
    AS $$
DECLARE 
	
	y_count integer;
	x_count integer;
	
BEGIN

SELECT COUNT(DISTINCT(x)) FROM get_adjacent_cards(p_lobby, p_x, p_y) 
WHERE y = p_y
INTO x_count;

SELECT COUNT(DISTINCT(y)) FROM get_adjacent_cards(p_lobby, p_x, p_y) 
WHERE x = p_x
INTO y_count;

RETURN QUERY
WITH
distinct_color_x AS 
(
	SELECT DISTINCT(c.color) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE y = p_y
),
distinct_color_y AS
(
	SELECT DISTINCT(c.color) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE x = p_x
),
possible_colors AS 
	(
		(
			(
			SELECT c.color FROM distinct_color_x c  
			WHERE (SELECT COUNT(1) FROM distinct_color_x) = 1
			)
			UNION
			(
			SELECT t.name as color FROM t_card_color t
			WHERE (SELECT COUNT(1) FROM distinct_color_x) = x_count
			EXCEPT SELECT color FROM distinct_color_x  
			)
		)
		INTERSECT
		(
			(
			SELECT c.color FROM distinct_color_y c  
			WHERE (SELECT COUNT(1) FROM distinct_color_y) = 1
			)
			UNION
			(
			SELECT t.name as color FROM t_card_color t
			WHERE (SELECT COUNT(1) FROM distinct_color_y) = y_count
			EXCEPT SELECT c.color FROM distinct_color_y c
			)
		)		
	),
distinct_shape_x AS 
	(
	SELECT DISTINCT(c.shape) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE y = p_y
	),
distinct_shape_y AS
(
	SELECT DISTINCT(c.shape) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE x = p_x
),
possible_shapes AS 
	(
		(
			(
			SELECT c.shape FROM distinct_shape_x c  
			WHERE (SELECT COUNT(1) FROM distinct_shape_x) = 1
			)
			UNION
			(
			SELECT t.name as shape FROM t_card_shape t
			WHERE (SELECT COUNT(1) FROM distinct_shape_x) = x_count
			EXCEPT SELECT shape FROM distinct_shape_x  
			)
		)
		INTERSECT
		(
			(
			SELECT c.shape FROM distinct_shape_y c  
			WHERE (SELECT COUNT(1) FROM distinct_shape_y) = 1
			)
			UNION
			(
			SELECT t.name as shape FROM t_card_shape t
			WHERE (SELECT COUNT(1) FROM distinct_shape_y) = y_count
			EXCEPT SELECT c.shape FROM distinct_shape_y c
			)
		)		
	),
distinct_number_x AS 
	(
	SELECT DISTINCT(c.number) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE y = p_y
	),
distinct_number_y AS
(
	SELECT DISTINCT(c.number) FROM get_adjacent_cards(p_lobby, p_x, p_y) c 
	WHERE x = p_x
),
possible_numbers AS 
	(
		(
			(
			SELECT c.number FROM distinct_number_x c  
			WHERE (SELECT COUNT(1) FROM distinct_number_x) = 1
			)
			UNION
			(
			SELECT t.number as number FROM t_card_number t
			WHERE (SELECT COUNT(1) FROM distinct_number_x) = x_count
			EXCEPT SELECT number FROM distinct_number_x  
			)
		)
		INTERSECT
		(
			(
			SELECT c.number FROM distinct_number_y c  
			WHERE (SELECT COUNT(1) FROM distinct_number_y) = 1
			)
			UNION
			(
			SELECT t.number as number FROM t_card_number t
			WHERE (SELECT COUNT(1) FROM distinct_number_y) = y_count
			EXCEPT SELECT c.number FROM distinct_number_y c
			)
		)		
	)

	SELECT t.id, t.color, t.shape, t.number FROM cards_types t
	WHERE 
	t.color IN (SELECT color FROM possible_colors) AND 
	t.shape IN (SELECT shape FROM possible_shapes) AND 
	t.number IN (SELECT number FROM possible_numbers);

	-- SELECT 0, p.color, '', 0::smallint FROM possible_colors p;

END;
$$;


ALTER FUNCTION s314500.get_possible_cards(p_lobby integer, p_x integer, p_y integer) OWNER TO postgres;

--
-- Name: getcurrentgames(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.getcurrentgames(tk integer) RETURNS TABLE(id integer, usercount integer, hostlogin character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM Tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM Users WHERE login = userLogin;

    -- Запрос
    RETURN QUERY
    SELECT gl.id,
           COUNT(ul2.user_id) AS userCount,
           u.login AS hostLogin
    FROM GameLobbies AS gl
    JOIN UsersInLobby AS ul ON gl.id = ul.lobby_id
    LEFT JOIN UsersInLobby AS ul2 ON gl.id = ul2.lobby_id
    LEFT JOIN Users u ON gl.host_id = u.id
    WHERE ul.user_id = userId
    GROUP BY gl.id, u.login;
END;
$$;


ALTER FUNCTION s314500.getcurrentgames(tk integer) OWNER TO postgres;

--
-- Name: gethost(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.gethost(lobbyid integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN (SELECT host_id FROM lobbies WHERE id = lobbyid);
END;
$$;


ALTER FUNCTION s314500.gethost(lobbyid integer) OWNER TO postgres;

--
-- Name: getlobbysettings(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.getlobbysettings(lobbyid integer) RETURNS TABLE(haspassword boolean, turn_time integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        CASE WHEN password IS NOT NULL THEN TRUE ELSE FALSE END AS hasPassword,
        turn_time
    FROM lobbies
    WHERE id = lobbyId;
END;
$$;


ALTER FUNCTION s314500.getlobbysettings(lobbyid integer) OWNER TO postgres;

--
-- Name: getuserid(integer); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.getuserid(IN tk integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64) := getUserLoginByToken(tk);
BEGIN
    -- Получение id пользователя по логину
    SELECT id FROM Users WHERE login = userLogin;
END;
$$;


ALTER PROCEDURE s314500.getuserid(IN tk integer) OWNER TO postgres;

--
-- Name: getuserloginbytoken(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.getuserloginbytoken(tk integer) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
BEGIN
    -- Получение логина по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    RETURN userLogin;
END;
$$;


ALTER FUNCTION s314500.getuserloginbytoken(tk integer) OWNER TO postgres;

--
-- Name: getusersinlobby(integer, integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.getusersinlobby(tk integer, lobbyid integer) RETURNS TABLE(user_id integer, login character varying, win_count integer, is_ready boolean)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM Users WHERE login = userLogin;

    -- Проверка на существование лобби
    IF NOT EXISTS (SELECT 1 FROM lobbies WHERE id = lobbyId) THEN
        RAISE EXCEPTION 'Лобби не существует';
    END IF;

    -- Проверка на то, что пользователь в лобби
    IF NOT EXISTS (SELECT 1 FROM players WHERE user_id = userId AND lobby_id = lobbyId) THEN
        RAISE EXCEPTION 'Пользователь не в лобби';
    END IF;

    -- Запрос
    RETURN QUERY
    SELECT u.id AS user_id, u.login, p.is_ready
    FROM players p
    JOIN users u ON p.user_id = u.id
    WHERE p.lobby_id = lobbyId;
END;
$$;


ALTER FUNCTION s314500.getusersinlobby(tk integer, lobbyid integer) OWNER TO postgres;

--
-- Name: hashpassword(character varying); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.hashpassword(password character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Хэширование пароля с добавлением соли 'megasalt'
    RETURN encode(convert_to(CONCAT(password, 'megasalt'), 'UTF8'), 'hex');
END;
$$;


ALTER FUNCTION s314500.hashpassword(password character varying) OWNER TO postgres;

--
-- Name: hello_world(); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.hello_world() RETURNS text
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN 'Hello, World!';
END;
$$;


ALTER FUNCTION s314500.hello_world() OWNER TO postgres;

--
-- Name: initgame(integer); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.initgame(IN id_lobby integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    x integer;
BEGIN
    -- Вызов mashup
    CALL mashup(id_lobby);

    -- Получаем card_id
    SELECT card_id INTO x FROM Cards_in_deck LIMIT 1;

    -- Вставляем карту на стол
    INSERT INTO CardsOnTable 
    SELECT * FROM Cards_in_deck WHERE card_id = x;

    -- Удаляем карту из колоды
    DELETE FROM Cards_in_deck WHERE card_id = x;

    -- Создаём места в лобби
    CALL makePlaces(id_lobby, 4);

    -- Определяем случайного игрока, который начнёт ход
    INSERT INTO Current_Turn (player_id)
    SELECT player_id FROM Players 
    WHERE lobby_id = id_lobby 
    ORDER BY RANDOM() 
    LIMIT 1;
END;
$$;


ALTER PROCEDURE s314500.initgame(IN id_lobby integer) OWNER TO postgres;

--
-- Name: isgamestarted(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.isgamestarted(lobbyid integer) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1
        FROM CurrentTurn
        WHERE turn_player_id IN (SELECT id FROM Players WHERE lobby_id = lobbyId)
    );
END;
$$;


ALTER FUNCTION s314500.isgamestarted(lobbyid integer) OWNER TO postgres;

--
-- Name: leavelobby(integer, integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.leavelobby(tk integer, lobbyid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
    currentHostId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RETURN 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Проверка, является ли пользователь хостом
    SELECT host_id INTO currentHostId FROM lobbies WHERE id = lobbyId;
    IF currentHostId = userId THEN
        IF (SELECT COUNT(*) FROM players WHERE lobby_id = lobbyId) > 1 THEN
            UPDATE lobbies
            SET host_id = (
                SELECT user_id
                FROM players
                WHERE lobby_id = lobbyId
                AND user_id != userId
                ORDER BY RANDOM()
                LIMIT 1
            )
            WHERE id = lobbyId;
        ELSE
            DELETE FROM lobbies WHERE id = lobbyId;
        END IF;
    END IF;

    DELETE FROM players WHERE user_id = userId AND lobby_id = lobbyId;
    RETURN 'Выход из лобби выполнен';
END;
$$;


ALTER FUNCTION s314500.leavelobby(tk integer, lobbyid integer) OWNER TO postgres;

--
-- Name: login(character varying, character varying); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.login(IN lg character varying, IN pw character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    tk bigint;
BEGIN
    -- Генерация случайного токена
    tk := floor(random() * 4000000000) + 1;

    -- Проверка пароля
    IF hashPassword(pw) = (SELECT password FROM Users WHERE login = lg LIMIT 1) THEN
        -- Очистка токенов (предполагается, что процедура clearTokens() уже создана)
        CALL clearTokens();

        -- Вставка нового токена
        INSERT INTO Tokens (token, login) VALUES (tk, lg);

        -- Возвращаем id пользователя и токен

        PERFORM
    (SELECT id FROM Users WHERE login = lg LIMIT 1),
    (SELECT tk FROM Users WHERE login = lg LIMIT 1);
    ELSE
        -- Если логин или пароль неверный
        RAISE EXCEPTION 'Пароль или логин неверный';
    END IF;
END;
$$;


ALTER PROCEDURE s314500.login(IN lg character varying, IN pw character varying) OWNER TO postgres;

--
-- Name: logout(integer); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.logout(IN tk integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Удаление токена
    DELETE FROM Tokens WHERE token = tk;

    -- Проверка, были ли удалены строки
    IF NOT FOUND THEN
        -- Если токен не был найден
        RAISE EXCEPTION 'Невалидный токен';
    ELSE
        -- Если токен был успешно удален
        RAISE NOTICE 'Вы успешно вышли из аккаунта';
    END IF;
END;
$$;


ALTER PROCEDURE s314500.logout(IN tk integer) OWNER TO postgres;

--
-- Name: make_places(integer, integer); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.make_places(IN id_lobby integer, IN count_cards integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_cards INT;
    count_players INT;
BEGIN
    -- Создание временной таблицы для игроков
    CREATE TEMP TABLE tmp (
        n SERIAL PRIMARY KEY,
        id INT
    ) ON COMMIT DROP;

    -- Заполняем временную таблицу случайным порядком игроков из лобби
    INSERT INTO tmp(id)
    SELECT player_id FROM Players WHERE lobby_id = id_lobby ORDER BY RANDOM();

    -- Подсчитываем количество игроков
    SELECT COUNT(*) INTO count_players FROM tmp;

    -- Вычисляем общее количество карт
    total_cards := count_players * count_cards;

    -- Создание временной таблицы для карт
    CREATE TEMP TABLE tmpCards (
        n SERIAL PRIMARY KEY,
        id_card INT
    ) ON COMMIT DROP;

    -- Заполняем временную таблицу случайными картами из колоды, ограничивая по total_cards
    INSERT INTO tmpCards(id_card)
    SELECT card_id FROM Cards_in_Deck WHERE lobby_id = id_lobby ORDER BY RANDOM() LIMIT total_cards;

    -- Распределяем карты между игроками
    INSERT INTO Cards_in_hand (player_id, card_id)
    SELECT tmp.id AS player_id, tmpCards.id_card
    FROM tmpCards
    JOIN tmp ON tmp.n = (tmpCards.n % count_players) + 1;
	
END $$;


ALTER PROCEDURE s314500.make_places(IN id_lobby integer, IN count_cards integer) OWNER TO postgres;

--
-- Name: makeplaces(integer, integer); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.makeplaces(IN id_lobby integer, IN count_cards integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    total_cards integer;
    count_players integer;
BEGIN
    -- Создание временной таблицы для игроков (случайный порядок)
    CREATE TEMP TABLE tmp (
        n SERIAL PRIMARY KEY, 
        id integer
    ) ON COMMIT DROP;

    -- Заполнение временной таблицы случайно отсортированными игроками
    INSERT INTO tmp(id)
    SELECT player_id FROM Players WHERE lobby_id = id_lobby ORDER BY RANDOM();

    -- Подсчёт количества игроков
    SELECT COUNT(*) INTO count_players FROM tmp;
    
    -- Вычисление общего количества карт
    total_cards := count_players * count_cards;

    CREATE TEMP TABLE tmpCards (
        n SERIAL PRIMARY KEY, 
        id_card integer
    ) ON COMMIT DROP;

    -- Заполнение картами (случайный порядок)
    INSERT INTO tmpCards(id_card)
    SELECT card_id FROM Cards_in_Deck WHERE lobby_id = id_lobby ORDER BY RANDOM() LIMIT total_cards;

    -- Раздача карт игрокам
    INSERT INTO Cards_in_hand (player_id, card_id)
    SELECT tmp.id AS player_id, tmpCards.id_card 
    FROM tmpCards 
    JOIN tmp ON tmp.n = (tmpCards.n % count_players) + 1;

END;
$$;


ALTER PROCEDURE s314500.makeplaces(IN id_lobby integer, IN count_cards integer) OWNER TO postgres;

--
-- Name: mashup(integer); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.mashup(IN id_lobby integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Вставляем случайно отсортированные карты из cards в cards_in_tables
    INSERT INTO cards_on_table (card_id, lobby_id)
    SELECT card_id, lobby_id FROM cards
    ORDER BY RANDOM();
END;
$$;


ALTER PROCEDURE s314500.mashup(IN id_lobby integer) OWNER TO postgres;

--
-- Name: register(character varying, character varying); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.register(IN login character varying, IN password character varying)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Проверка на минимальную длину пароля и наличие как минимум одной буквы и одной цифры
    IF LENGTH(password) < 6 OR password !~ '[0-9]' OR password !~ '[a-zA-Z]' THEN
        RAISE EXCEPTION 'Пароль должен быть длиной не менее 6 символов и содержать как минимум одну букву и одну цифру';
    END IF;

    -- Вставка пользователя, если логин уникален
    BEGIN
        INSERT INTO Users(login, password) VALUES (login, hashPassword(password));
    EXCEPTION WHEN unique_violation THEN
        RAISE EXCEPTION 'Такой логин уже занят';
    END;

    -- Вызов функции для входа пользователя
    CALL login(login, password);
END;
$$;


ALTER PROCEDURE s314500.register(IN login character varying, IN password character varying) OWNER TO postgres;

--
-- Name: setready(integer, integer, boolean); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.setready(tk integer, lobbyid integer, state boolean) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RETURN 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM users WHERE login = userLogin;

    -- Проверка, находится ли пользователь в лобби
    IF NOT EXISTS (SELECT 1 FROM players WHERE user_id = userId AND lobby_id = lobbyId) THEN
        RETURN 'Пользователь не в лобби';
    END IF;

    -- Обновление статуса готовности
    UPDATE players
    SET is_ready = state
    WHERE user_id = userId AND lobby_id = lobbyId;

    -- Возвращаем обновленную информацию о лобби
    PERFORM getUsersInLobby(tk, lobbyId);
    RETURN 'Готовность обновлена';
END;
$$;


ALTER FUNCTION s314500.setready(tk integer, lobbyid integer, state boolean) OWNER TO postgres;

--
-- Name: showavailablegames(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.showavailablegames(tk integer) RETURNS TABLE(id integer, usercount integer, haspassword boolean, hostlogin character varying)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
    userId INT;
BEGIN
    -- Получаем логин по токену
    SELECT login INTO userLogin FROM Tokens WHERE token = tk;
    IF userLogin IS NULL THEN
        RAISE EXCEPTION 'Невалидный токен';
    END IF;

    -- Получаем userId
    SELECT id INTO userId FROM Users WHERE login = userLogin;

    -- Запрос
    RETURN QUERY
    SELECT p.lobby_id AS id,
           COUNT(*) AS userCount,
           CASE WHEN l.password IS NOT NULL THEN TRUE ELSE FALSE END AS hasPassword,
           u.login AS hostLogin
    FROM players p
    LEFT JOIN players p2 ON p2.lobby_id = p.lobby_id AND p2.user_id = userId
    INNER JOIN lobbies l ON p.lobby_id = l.id
    LEFT JOIN users u ON l.host_id = u.id
    WHERE p2.user_id IS NULL
    GROUP BY p.lobby_id, l.password, u.login
    HAVING COUNT(*) < 4;
END;
$$;


ALTER FUNCTION s314500.showavailablegames(tk integer) OWNER TO postgres;

--
-- Name: showuserinfo(integer); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.showuserinfo(IN tk integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    userLogin VARCHAR(64);
BEGIN
    -- Проверка на валидность токена
    SELECT login INTO userLogin FROM Tokens WHERE token = tk;

    IF userLogin IS NULL THEN
        -- Если токен не найден
        RAISE EXCEPTION 'Невалидный токен';
    ELSE
        -- Запрос информации о пользователе
        PERFORM (SELECT login FROM Users WHERE login = userLogin);
    END IF;
END;
$$;


ALTER PROCEDURE s314500.showuserinfo(IN tk integer) OWNER TO postgres;

--
-- Name: showuserpl(); Type: PROCEDURE; Schema: s314500; Owner: postgres
--

CREATE PROCEDURE s314500.showuserpl()
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Запрос информации о всех пользователях
    PERFORM (SELECT login FROM Users);
END;
$$;


ALTER PROCEDURE s314500.showuserpl() OWNER TO postgres;

--
-- Name: startgame(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.startgame(lobbyid integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    currentHostId INT;
BEGIN
    -- Получаем хоста лобби
    SELECT host_id INTO currentHostId FROM lobbies WHERE id = lobbyId;

    -- Проверка, что хост запускает игру
    IF currentHostId != (SELECT id FROM users WHERE login = userLogin) THEN
        RETURN 'Только хост может начать игру';
    END IF;

    -- Запуск игры
    UPDATE lobbies SET state = 'inProgress' WHERE id = lobbyId;
    
    RETURN 'Игра началась';
END;
$$;


ALTER FUNCTION s314500.startgame(lobbyid integer) OWNER TO postgres;

--
-- Name: type_of_card(integer); Type: FUNCTION; Schema: s314500; Owner: postgres
--

CREATE FUNCTION s314500.type_of_card(p_card integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$DECLARE 

	out integer;

BEGIN 

SELECT card_type_id FROM cards WHERE card_id = p_card 
INTO out;

RETURN out;

END;$$;


ALTER FUNCTION s314500.type_of_card(p_card integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: cards; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.cards (
    card_id integer NOT NULL,
    card_type_id integer NOT NULL
);


ALTER TABLE s314500.cards OWNER TO postgres;

--
-- Name: cards_card_id_seq; Type: SEQUENCE; Schema: s314500; Owner: postgres
--

CREATE SEQUENCE s314500.cards_card_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.cards_card_id_seq OWNER TO postgres;

--
-- Name: cards_card_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: postgres
--

ALTER SEQUENCE s314500.cards_card_id_seq OWNED BY s314500.cards.card_id;


--
-- Name: cards_in_deck; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.cards_in_deck (
    card_id integer NOT NULL,
    lobby_id integer NOT NULL
);


ALTER TABLE s314500.cards_in_deck OWNER TO postgres;

--
-- Name: cards_in_hand; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.cards_in_hand (
    card_id integer NOT NULL,
    player_id integer NOT NULL
);


ALTER TABLE s314500.cards_in_hand OWNER TO postgres;

--
-- Name: cards_on_table; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.cards_on_table (
    card_id integer NOT NULL,
    lobby_id integer NOT NULL,
    x smallint NOT NULL,
    y smallint NOT NULL
);


ALTER TABLE s314500.cards_on_table OWNER TO postgres;

--
-- Name: cardstypes_id_seq; Type: SEQUENCE; Schema: s314500; Owner: postgres
--

CREATE SEQUENCE s314500.cardstypes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    MAXVALUE 66
    CACHE 1;


ALTER SEQUENCE s314500.cardstypes_id_seq OWNER TO postgres;

--
-- Name: cards_types; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.cards_types (
    id integer DEFAULT nextval('s314500.cardstypes_id_seq'::regclass) NOT NULL,
    shape text,
    number smallint,
    color text,
    CONSTRAINT cardstypes_color_check CHECK ((color = ANY (ARRAY['Blue'::text, 'Yellow'::text, 'Red'::text, 'Green'::text]))),
    CONSTRAINT cardstypes_number_check CHECK ((number >= 0)),
    CONSTRAINT cardstypes_shape_check CHECK ((shape = ANY (ARRAY['Square'::text, 'Triangle'::text, 'Circle'::text, 'Cross'::text])))
);


ALTER TABLE s314500.cards_types OWNER TO postgres;

--
-- Name: current_turn; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.current_turn (
    player_id integer NOT NULL,
    start_time timestamp without time zone NOT NULL
);


ALTER TABLE s314500.current_turn OWNER TO postgres;

--
-- Name: lobbies; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.lobbies (
    id integer NOT NULL,
    password character varying(10),
    turn_time integer DEFAULT 30 NOT NULL,
    host_id integer,
    state character varying DEFAULT 'waiting'::character varying NOT NULL
);


ALTER TABLE s314500.lobbies OWNER TO postgres;

--
-- Name: lobbies_id_seq; Type: SEQUENCE; Schema: s314500; Owner: postgres
--

CREATE SEQUENCE s314500.lobbies_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.lobbies_id_seq OWNER TO postgres;

--
-- Name: lobbies_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: postgres
--

ALTER SEQUENCE s314500.lobbies_id_seq OWNED BY s314500.lobbies.id;


--
-- Name: players; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.players (
    id integer NOT NULL,
    lobby_id integer NOT NULL,
    login character varying(20) NOT NULL,
    nickname character varying(15) NOT NULL,
    points integer DEFAULT 0 NOT NULL,
    is_ready boolean DEFAULT false NOT NULL
);


ALTER TABLE s314500.players OWNER TO postgres;

--
-- Name: players_id_seq; Type: SEQUENCE; Schema: s314500; Owner: postgres
--

CREATE SEQUENCE s314500.players_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.players_id_seq OWNER TO postgres;

--
-- Name: players_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: postgres
--

ALTER SEQUENCE s314500.players_id_seq OWNED BY s314500.players.id;


--
-- Name: t_card_color; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.t_card_color (
    id smallint NOT NULL,
    name text NOT NULL
);


ALTER TABLE s314500.t_card_color OWNER TO postgres;

--
-- Name: t_card_number; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.t_card_number (
    id smallint NOT NULL,
    number smallint NOT NULL
);


ALTER TABLE s314500.t_card_number OWNER TO postgres;

--
-- Name: t_card_shape; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.t_card_shape (
    id smallint NOT NULL,
    name text NOT NULL
);


ALTER TABLE s314500.t_card_shape OWNER TO postgres;

--
-- Name: test_table; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.test_table (
    x integer NOT NULL
);


ALTER TABLE s314500.test_table OWNER TO postgres;

--
-- Name: tokens; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.tokens (
    login character varying(64) NOT NULL,
    token bigint NOT NULL,
    created timestamp without time zone DEFAULT now() NOT NULL
);


ALTER TABLE s314500.tokens OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.users (
    login character varying(20) NOT NULL,
    password character varying(50) NOT NULL,
    id integer NOT NULL
);


ALTER TABLE s314500.users OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE; Schema: s314500; Owner: postgres
--

CREATE SEQUENCE s314500.users_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.users_id_seq OWNER TO postgres;

--
-- Name: users_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: postgres
--

ALTER SEQUENCE s314500.users_id_seq OWNED BY s314500.users.id;


--
-- Name: users_in_lobby; Type: TABLE; Schema: s314500; Owner: postgres
--

CREATE TABLE s314500.users_in_lobby (
    lobby_id integer NOT NULL,
    login character varying(20) NOT NULL
);


ALTER TABLE s314500.users_in_lobby OWNER TO postgres;

--
-- Name: cards card_id; Type: DEFAULT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards ALTER COLUMN card_id SET DEFAULT nextval('s314500.cards_card_id_seq'::regclass);


--
-- Name: lobbies id; Type: DEFAULT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.lobbies ALTER COLUMN id SET DEFAULT nextval('s314500.lobbies_id_seq'::regclass);


--
-- Name: players id; Type: DEFAULT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.players ALTER COLUMN id SET DEFAULT nextval('s314500.players_id_seq'::regclass);


--
-- Name: users id; Type: DEFAULT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.users ALTER COLUMN id SET DEFAULT nextval('s314500.users_id_seq'::regclass);


--
-- Data for Name: cards; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.cards (card_id, card_type_id) FROM stdin;
\.
COPY s314500.cards (card_id, card_type_id) FROM '$$PATH$$/3580.dat';

--
-- Data for Name: cards_in_deck; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.cards_in_deck (card_id, lobby_id) FROM stdin;
\.
COPY s314500.cards_in_deck (card_id, lobby_id) FROM '$$PATH$$/3582.dat';

--
-- Data for Name: cards_in_hand; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.cards_in_hand (card_id, player_id) FROM stdin;
\.
COPY s314500.cards_in_hand (card_id, player_id) FROM '$$PATH$$/3583.dat';

--
-- Data for Name: cards_on_table; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.cards_on_table (card_id, lobby_id, x, y) FROM stdin;
\.
COPY s314500.cards_on_table (card_id, lobby_id, x, y) FROM '$$PATH$$/3584.dat';

--
-- Data for Name: cards_types; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.cards_types (id, shape, number, color) FROM stdin;
\.
COPY s314500.cards_types (id, shape, number, color) FROM '$$PATH$$/3586.dat';

--
-- Data for Name: current_turn; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.current_turn (player_id, start_time) FROM stdin;
\.
COPY s314500.current_turn (player_id, start_time) FROM '$$PATH$$/3587.dat';

--
-- Data for Name: lobbies; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.lobbies (id, password, turn_time, host_id, state) FROM stdin;
\.
COPY s314500.lobbies (id, password, turn_time, host_id, state) FROM '$$PATH$$/3588.dat';

--
-- Data for Name: players; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.players (id, lobby_id, login, nickname, points, is_ready) FROM stdin;
\.
COPY s314500.players (id, lobby_id, login, nickname, points, is_ready) FROM '$$PATH$$/3590.dat';

--
-- Data for Name: t_card_color; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.t_card_color (id, name) FROM stdin;
\.
COPY s314500.t_card_color (id, name) FROM '$$PATH$$/3592.dat';

--
-- Data for Name: t_card_number; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.t_card_number (id, number) FROM stdin;
\.
COPY s314500.t_card_number (id, number) FROM '$$PATH$$/3593.dat';

--
-- Data for Name: t_card_shape; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.t_card_shape (id, name) FROM stdin;
\.
COPY s314500.t_card_shape (id, name) FROM '$$PATH$$/3594.dat';

--
-- Data for Name: test_table; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.test_table (x) FROM stdin;
\.
COPY s314500.test_table (x) FROM '$$PATH$$/3595.dat';

--
-- Data for Name: tokens; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.tokens (login, token, created) FROM stdin;
\.
COPY s314500.tokens (login, token, created) FROM '$$PATH$$/3596.dat';

--
-- Data for Name: users; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.users (login, password, id) FROM stdin;
\.
COPY s314500.users (login, password, id) FROM '$$PATH$$/3597.dat';

--
-- Data for Name: users_in_lobby; Type: TABLE DATA; Schema: s314500; Owner: postgres
--

COPY s314500.users_in_lobby (lobby_id, login) FROM stdin;
\.
COPY s314500.users_in_lobby (lobby_id, login) FROM '$$PATH$$/3599.dat';

--
-- Name: cards_card_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: postgres
--

SELECT pg_catalog.setval('s314500.cards_card_id_seq', 1, false);


--
-- Name: cardstypes_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: postgres
--

SELECT pg_catalog.setval('s314500.cardstypes_id_seq', 1, false);


--
-- Name: lobbies_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: postgres
--

SELECT pg_catalog.setval('s314500.lobbies_id_seq', 19, true);


--
-- Name: players_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: postgres
--

SELECT pg_catalog.setval('s314500.players_id_seq', 3, true);


--
-- Name: users_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: postgres
--

SELECT pg_catalog.setval('s314500.users_id_seq', 42, true);


--
-- Name: cards cards_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards
    ADD CONSTRAINT cards_pkey PRIMARY KEY (card_id);


--
-- Name: cards_in_deck cardsindeck_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_in_deck
    ADD CONSTRAINT cardsindeck_pkey PRIMARY KEY (card_id);


--
-- Name: cards_in_hand cardsinhand_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_in_hand
    ADD CONSTRAINT cardsinhand_pkey PRIMARY KEY (card_id);


--
-- Name: cards_on_table cardsontable_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cardsontable_pkey PRIMARY KEY (card_id);


--
-- Name: cards_types cardstypes_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_types
    ADD CONSTRAINT cardstypes_pkey PRIMARY KEY (id);


--
-- Name: current_turn currentturn_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.current_turn
    ADD CONSTRAINT currentturn_pkey PRIMARY KEY (player_id);


--
-- Name: lobbies lobbies_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.lobbies
    ADD CONSTRAINT lobbies_pkey PRIMARY KEY (id);


--
-- Name: players players_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: t_card_color t_card_color_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.t_card_color
    ADD CONSTRAINT t_card_color_pkey PRIMARY KEY (id);


--
-- Name: t_card_number t_card_number_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.t_card_number
    ADD CONSTRAINT t_card_number_pkey PRIMARY KEY (id);


--
-- Name: t_card_shape t_card_shape_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.t_card_shape
    ADD CONSTRAINT t_card_shape_pkey PRIMARY KEY (id);


--
-- Name: test_table test_table_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.test_table
    ADD CONSTRAINT test_table_pkey PRIMARY KEY (x);


--
-- Name: tokens tokens_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (token);


--
-- Name: cards_on_table unique_lobby_xy; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT unique_lobby_xy UNIQUE (lobby_id, x, y);


--
-- Name: players unique_login_lobby; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.players
    ADD CONSTRAINT unique_login_lobby UNIQUE (login, lobby_id);


--
-- Name: cards_types unique_shape_number_color; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_types
    ADD CONSTRAINT unique_shape_number_color UNIQUE (shape, number, color);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (login);


--
-- Name: users_in_lobby usersinlobby_pkey; Type: CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.users_in_lobby
    ADD CONSTRAINT usersinlobby_pkey PRIMARY KEY (lobby_id, login);


--
-- Name: cards_in_deck cardsindeck_card_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_in_deck
    ADD CONSTRAINT cardsindeck_card_id_fkey FOREIGN KEY (card_id) REFERENCES s314500.cards(card_id) ON DELETE RESTRICT;


--
-- Name: cards_in_deck cardsindeck_lobby_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_in_deck
    ADD CONSTRAINT cardsindeck_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.lobbies(id) ON DELETE CASCADE;


--
-- Name: cards_in_hand cardsinhand_card_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_in_hand
    ADD CONSTRAINT cardsinhand_card_id_fkey FOREIGN KEY (card_id) REFERENCES s314500.cards(card_id) ON DELETE RESTRICT;


--
-- Name: cards_in_hand cardsinhand_player_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_in_hand
    ADD CONSTRAINT cardsinhand_player_id_fkey FOREIGN KEY (player_id) REFERENCES s314500.players(id) ON DELETE CASCADE;


--
-- Name: cards_on_table cardsontable_card_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cardsontable_card_id_fkey FOREIGN KEY (card_id) REFERENCES s314500.cards(card_id) ON DELETE RESTRICT;


--
-- Name: cards_on_table cardsontable_lobby_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cardsontable_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.lobbies(id) ON DELETE CASCADE;


--
-- Name: current_turn currentturn_player_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.current_turn
    ADD CONSTRAINT currentturn_player_id_fkey FOREIGN KEY (player_id) REFERENCES s314500.players(id) ON DELETE CASCADE;


--
-- Name: players players_lobby_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.players
    ADD CONSTRAINT players_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.lobbies(id) ON DELETE CASCADE;


--
-- Name: players players_login_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.players
    ADD CONSTRAINT players_login_fkey FOREIGN KEY (login) REFERENCES s314500.users(login) ON DELETE RESTRICT;


--
-- Name: tokens tokens_login_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.tokens
    ADD CONSTRAINT tokens_login_fkey FOREIGN KEY (login) REFERENCES s314500.users(login) ON DELETE CASCADE;


--
-- Name: users_in_lobby usersinlobby_lobby_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.users_in_lobby
    ADD CONSTRAINT usersinlobby_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.lobbies(id) ON DELETE CASCADE;


--
-- Name: users_in_lobby usersinlobby_login_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: postgres
--

ALTER TABLE ONLY s314500.users_in_lobby
    ADD CONSTRAINT usersinlobby_login_fkey FOREIGN KEY (login) REFERENCES s314500.users(login) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                