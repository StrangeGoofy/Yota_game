toc.dat                                                                                             0000600 0004000 0002000 00000056531 14767070160 0014461 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        PGDMP   4    -                }            yota3 #   16.8 (Ubuntu 16.8-0ubuntu0.24.04.1)    16.4 H    �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false         �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false         �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false         �           1262    17283    yota3    DATABASE     q   CREATE DATABASE yota3 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';
    DROP DATABASE yota3;
                s314500    false                     2615    17396    s314500    SCHEMA        CREATE SCHEMA s314500;
    DROP SCHEMA s314500;
                s314500    false         �            1255    17397 #   auth_create_lobby(uuid, text, text)    FUNCTION     Q  CREATE FUNCTION s314500.auth_create_lobby(p_tk uuid, p_name text DEFAULT 'New Lobby'::text, p_password text DEFAULT ''::text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 

	newLobbyId bigint;

BEGIN 

	IF s314500.auth_current_lobby(p_tk) != -1 THEN 
		RAISE EXCEPTION 'Player trying to create a lobby, while being in one';
	END IF;

	newLobbyId = nextval('s314500.auth_lobbies_id_seq'::regclass);
	INSERT INTO s314500.auth_lobbies(id, name, password) VALUES
	(newLobbyId, p_name, p_password);

	-- s314500.auth_join_lobby(p_tk, newLobbyId, p_password);
	RETURN newLobbyId;

END;
$$;
 R   DROP FUNCTION s314500.auth_create_lobby(p_tk uuid, p_name text, p_password text);
       s314500          s314500    false    6         �            1255    17398    auth_create_token(text)    FUNCTION     �   CREATE FUNCTION s314500.auth_create_token(p_login text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE 
	newTk UUID;
BEGIN 
	newTk = gen_random_uuid();
	INSERT INTO s314500.auth_tokens(login, tk) VALUES 
	(p_login, newTk);

	RETURN newTk;
END;
$$;
 7   DROP FUNCTION s314500.auth_create_token(p_login text);
       s314500          s314500    false    6         �            1255    17399    auth_current_lobby(uuid)    FUNCTION     r  CREATE FUNCTION s314500.auth_current_lobby(p_tk uuid) RETURNS bigint
    LANGUAGE plpgsql
    AS $$DECLARE 

	outLobbyId bigint;

BEGIN
	outLobbyId = -1;

	IF NOT EXISTS (SELECT (1) FROM s314500.auth_players p WHERE p.tk = p_tk) THEN 
		RETURN -1;
	END IF;

	SELECT lobby_id FROM s314500.auth_players p WHERE p.tk = p_tk
	INTO outLobbyId; 

	RETURN outLobbyId;

END;$$;
 5   DROP FUNCTION s314500.auth_current_lobby(p_tk uuid);
       s314500          s314500    false    6         �            1255    17400    auth_current_player(uuid)    FUNCTION     ;  CREATE FUNCTION s314500.auth_current_player(p_tk uuid) RETURNS bigint
    LANGUAGE plpgsql
    AS $$DECLARE
	player_id bigint;
BEGIN

	SELECT p.id FROM s314500.auth_players p WHERE p.tk = p_tk 
	INTO player_id;

	IF player_id = NULL THEN 
		RAISE EXCEPTION 'No curent player';
	END IF;

	return player_id;

END;$$;
 6   DROP FUNCTION s314500.auth_current_player(p_tk uuid);
       s314500          s314500    false    6         �            1255    17401    auth_hash_password(text)    FUNCTION       CREATE FUNCTION s314500.auth_hash_password(p_password text) RETURNS text
    LANGUAGE plpgsql
    AS $$BEGIN
    -- Хэширование пароля с добавлением соли 'megasalt'
    RETURN encode(convert_to(CONCAT(p_password, 'megasalt'), 'UTF8'), 'hex');
END;$$;
 ;   DROP FUNCTION s314500.auth_hash_password(p_password text);
       s314500          s314500    false    6         �            1255    17402 #   auth_join_lobby(uuid, bigint, text)    FUNCTION     �  CREATE FUNCTION s314500.auth_join_lobby(p_tk uuid, p_lobby bigint, p_password text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE 

	lobbyPassword text;

BEGIN 

	IF s314500.auth_current_lobby(p_tk) != -1 THEN
		RAISE EXCEPTION 'Already in lobby';
	END IF;

	IF p_lobby NOT IN (SELECT id FROM s314500.auth_lobbies) THEN 
		RAISE EXCEPTION 'Lobby does not exist';
	END IF;
	
	SELECT password FROM s314500.auth_lobbies l WHERE l.id = p_lobby 
	INTO lobbyPassword;

	IF lobbyPassword != p_password THEN
		RAISE EXCEPTION 'Wrong password for lobby';
	END IF;
	
	INSERT INTO s314500.auth_players (tk, lobby_id) VALUES
	(p_tk, p_lobby);

	RETURN TRUE;
	
END;
$$;
 S   DROP FUNCTION s314500.auth_join_lobby(p_tk uuid, p_lobby bigint, p_password text);
       s314500          s314500    false    6         �            1255    17403    auth_login(text, text)    FUNCTION       CREATE FUNCTION s314500.auth_login(p_username text, p_password text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE 
	tk UUID;
	storedPassword text;
BEGIN
	IF p_username NOT IN (SELECT login from s314500.auth_users) THEN
		RAISE EXCEPTION 'Unknown user';
	END IF;

	SELECT password FROM s314500.auth_users WHERE login = p_username
	INTO storedPassword;

	IF s314500.auth_hash_password(p_password) != storedPassword THEN 
		RAISE EXCEPTION 'Wrong password';
	END IF;

	tk = s314500.auth_create_token(p_username);
	RETURN tk;
END; 
$$;
 D   DROP FUNCTION s314500.auth_login(p_username text, p_password text);
       s314500          s314500    false    6         �            1255    17404    auth_player_count(bigint)    FUNCTION     F  CREATE FUNCTION s314500.auth_player_count(p_lobby bigint) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	out integer;
BEGIN

	IF p_lobby NOT IN (SELECT id FROM s314500.auth_lobbies) THEN
		RETURN 0;
	END IF;

	SELECT COUNT(1) FROM s314500.auth_players p WHERE p.lobby_id = p_lobby 
	INTO out;

	RETURN out;
END;
$$;
 9   DROP FUNCTION s314500.auth_player_count(p_lobby bigint);
       s314500          s314500    false    6         �            1255    17405    auth_register_user(text, text)    FUNCTION     �  CREATE FUNCTION s314500.auth_register_user(p_username text, p_password text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE 
	tk uuid;
	hashedPassword text;
BEGIN 

	IF p_username IN (SELECT login FROM s314500.auth_users) THEN
		RAISE EXCEPTION 'User with this username exists';
	END IF;

	hashedPassword = s314500.auth_hash_password(p_password);

	INSERT INTO s314500.auth_users (login, password) VALUES 
	(p_username, hashedPassword);

	RETURN s314500.auth_create_token(p_username);
END;
$$;
 L   DROP FUNCTION s314500.auth_register_user(p_username text, p_password text);
       s314500          s314500    false    6         �            1255    17406 !   auth_set_player_state(uuid, text)    FUNCTION     _  CREATE FUNCTION s314500.auth_set_player_state(p_tk uuid, p_state text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE

	player_id bigint; 
	_lobby_id bigint; 

BEGIN

	player_id = s314500.auth_current_player(p_tk);
	_lobby_id  = s314500.auth_current_lobby(p_tk);

	UPDATE s314500.auth_players p SET state = p_state 
	WHERE p.id = player_id;

	IF (SELECT COUNT(1) FROM s314500.auth_players p WHERE p.state = 'Ready' AND p.lobby_id = _lobby_id) = s314500.auth_player_count(_lobby_id) 
	AND s314500.auth_player_count(_lobby_id) >= 2 THEN 
		CALL begin_game(_lobby_id);
	END IF;

	RETURN TRUE;
END;
$$;
 F   DROP FUNCTION s314500.auth_set_player_state(p_tk uuid, p_state text);
       s314500          s314500    false    6         �            1255    17407    begin_game(bigint) 	   PROCEDURE     �   CREATE PROCEDURE s314500.begin_game(IN p_lobby bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN


UPDATE s314500.auth_lobbies l SET state = 'Ready' WHERE l.id = p_lobby; 


END;
$$;
 6   DROP PROCEDURE s314500.begin_game(IN p_lobby bigint);
       s314500          s314500    false    6         �            1259    17408    auth_lobbies    TABLE     �   CREATE TABLE s314500.auth_lobbies (
    id bigint NOT NULL,
    password character varying(100),
    turn_time integer,
    state text DEFAULT 'NotReady'::text NOT NULL,
    name text DEFAULT 'New Lobby'::text
);
 !   DROP TABLE s314500.auth_lobbies;
       s314500         heap    s314500    false    6         �            1259    17415    auth_lobbies_id_seq    SEQUENCE     }   CREATE SEQUENCE s314500.auth_lobbies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE s314500.auth_lobbies_id_seq;
       s314500          s314500    false    216    6         �           0    0    auth_lobbies_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE s314500.auth_lobbies_id_seq OWNED BY s314500.auth_lobbies.id;
          s314500          s314500    false    217         �            1259    17416    auth_players    TABLE     �   CREATE TABLE s314500.auth_players (
    id bigint NOT NULL,
    tk uuid NOT NULL,
    state text DEFAULT 'NotReady'::text NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    lobby_id bigint NOT NULL
);
 !   DROP TABLE s314500.auth_players;
       s314500         heap    s314500    false    6         �            1259    17423    auth_players_id_seq    SEQUENCE     }   CREATE SEQUENCE s314500.auth_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE s314500.auth_players_id_seq;
       s314500          s314500    false    6    218         �           0    0    auth_players_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE s314500.auth_players_id_seq OWNED BY s314500.auth_players.id;
          s314500          s314500    false    219         �            1259    17424    auth_tokens    TABLE     �   CREATE TABLE s314500.auth_tokens (
    tk uuid DEFAULT gen_random_uuid() NOT NULL,
    login character varying(100) NOT NULL,
    creation_time timestamp with time zone DEFAULT now() NOT NULL
);
     DROP TABLE s314500.auth_tokens;
       s314500         heap    s314500    false    6         �            1259    17429 
   auth_users    TABLE     ~   CREATE TABLE s314500.auth_users (
    login character varying(100) NOT NULL,
    password character varying(1000) NOT NULL
);
    DROP TABLE s314500.auth_users;
       s314500         heap    s314500    false    6         �            1259    17434    card    TABLE     j   CREATE TABLE s314500.card (
    id integer NOT NULL,
    color text,
    type text,
    number integer
);
    DROP TABLE s314500.card;
       s314500         heap    s314500    false    6         �            1259    17439    card_type_id_seq    SEQUENCE     �   CREATE SEQUENCE s314500.card_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE s314500.card_type_id_seq;
       s314500          s314500    false    6    222         �           0    0    card_type_id_seq    SEQUENCE OWNED BY     B   ALTER SEQUENCE s314500.card_type_id_seq OWNED BY s314500.card.id;
          s314500          s314500    false    223         �            1259    17440    cards_on_table    TABLE     m   CREATE TABLE s314500.cards_on_table (
    x integer NOT NULL,
    y integer NOT NULL,
    card_id integer
);
 #   DROP TABLE s314500.cards_on_table;
       s314500         heap    s314500    false    6         �            1259    17443    template_id    TABLE     =   CREATE TABLE s314500.template_id (
    id bigint NOT NULL
);
     DROP TABLE s314500.template_id;
       s314500         heap    s314500    false    6         �            1259    17446    t_card_color    TABLE     T   CREATE TABLE s314500.t_card_color (
    name text
)
INHERITS (s314500.template_id);
 !   DROP TABLE s314500.t_card_color;
       s314500         heap    s314500    false    6    225         �            1259    17451    t_card_number    TABLE     T   CREATE TABLE s314500.t_card_number (
    id integer NOT NULL,
    number integer
);
 "   DROP TABLE s314500.t_card_number;
       s314500         heap    s314500    false    6         �            1259    17454    t_card_number_id_seq    SEQUENCE     �   CREATE SEQUENCE s314500.t_card_number_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE s314500.t_card_number_id_seq;
       s314500          s314500    false    6    227         �           0    0    t_card_number_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE s314500.t_card_number_id_seq OWNED BY s314500.t_card_number.id;
          s314500          s314500    false    228         �            1259    17455    t_card_type    TABLE     S   CREATE TABLE s314500.t_card_type (
    name text
)
INHERITS (s314500.template_id);
     DROP TABLE s314500.t_card_type;
       s314500         heap    s314500    false    6    225         �            1259    17460    template_id_id_seq    SEQUENCE     |   CREATE SEQUENCE s314500.template_id_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE s314500.template_id_id_seq;
       s314500          s314500    false    6    225         �           0    0    template_id_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE s314500.template_id_id_seq OWNED BY s314500.template_id.id;
          s314500          s314500    false    230                    2604    17461    auth_lobbies id    DEFAULT     t   ALTER TABLE ONLY s314500.auth_lobbies ALTER COLUMN id SET DEFAULT nextval('s314500.auth_lobbies_id_seq'::regclass);
 ?   ALTER TABLE s314500.auth_lobbies ALTER COLUMN id DROP DEFAULT;
       s314500          s314500    false    217    216         
           2604    17462    auth_players id    DEFAULT     t   ALTER TABLE ONLY s314500.auth_players ALTER COLUMN id SET DEFAULT nextval('s314500.auth_players_id_seq'::regclass);
 ?   ALTER TABLE s314500.auth_players ALTER COLUMN id DROP DEFAULT;
       s314500          s314500    false    219    218                    2604    17463    card id    DEFAULT     i   ALTER TABLE ONLY s314500.card ALTER COLUMN id SET DEFAULT nextval('s314500.card_type_id_seq'::regclass);
 7   ALTER TABLE s314500.card ALTER COLUMN id DROP DEFAULT;
       s314500          s314500    false    223    222                    2604    17464    t_card_color id    DEFAULT     s   ALTER TABLE ONLY s314500.t_card_color ALTER COLUMN id SET DEFAULT nextval('s314500.template_id_id_seq'::regclass);
 ?   ALTER TABLE s314500.t_card_color ALTER COLUMN id DROP DEFAULT;
       s314500          s314500    false    230    226                    2604    17465    t_card_number id    DEFAULT     v   ALTER TABLE ONLY s314500.t_card_number ALTER COLUMN id SET DEFAULT nextval('s314500.t_card_number_id_seq'::regclass);
 @   ALTER TABLE s314500.t_card_number ALTER COLUMN id DROP DEFAULT;
       s314500          s314500    false    228    227                    2604    17466    t_card_type id    DEFAULT     r   ALTER TABLE ONLY s314500.t_card_type ALTER COLUMN id SET DEFAULT nextval('s314500.template_id_id_seq'::regclass);
 >   ALTER TABLE s314500.t_card_type ALTER COLUMN id DROP DEFAULT;
       s314500          s314500    false    229    230                    2604    17467    template_id id    DEFAULT     r   ALTER TABLE ONLY s314500.template_id ALTER COLUMN id SET DEFAULT nextval('s314500.template_id_id_seq'::regclass);
 >   ALTER TABLE s314500.template_id ALTER COLUMN id DROP DEFAULT;
       s314500          s314500    false    230    225         �          0    17408    auth_lobbies 
   TABLE DATA           M   COPY s314500.auth_lobbies (id, password, turn_time, state, name) FROM stdin;
    s314500          s314500    false    216       3515.dat �          0    17416    auth_players 
   TABLE DATA           G   COPY s314500.auth_players (id, tk, state, score, lobby_id) FROM stdin;
    s314500          s314500    false    218       3517.dat �          0    17424    auth_tokens 
   TABLE DATA           @   COPY s314500.auth_tokens (tk, login, creation_time) FROM stdin;
    s314500          s314500    false    220       3519.dat �          0    17429 
   auth_users 
   TABLE DATA           6   COPY s314500.auth_users (login, password) FROM stdin;
    s314500          s314500    false    221       3520.dat �          0    17434    card 
   TABLE DATA           8   COPY s314500.card (id, color, type, number) FROM stdin;
    s314500          s314500    false    222       3521.dat �          0    17440    cards_on_table 
   TABLE DATA           8   COPY s314500.cards_on_table (x, y, card_id) FROM stdin;
    s314500          s314500    false    224       3523.dat �          0    17446    t_card_color 
   TABLE DATA           1   COPY s314500.t_card_color (id, name) FROM stdin;
    s314500          s314500    false    226       3525.dat �          0    17451    t_card_number 
   TABLE DATA           4   COPY s314500.t_card_number (id, number) FROM stdin;
    s314500          s314500    false    227       3526.dat �          0    17455    t_card_type 
   TABLE DATA           0   COPY s314500.t_card_type (id, name) FROM stdin;
    s314500          s314500    false    229       3528.dat �          0    17443    template_id 
   TABLE DATA           *   COPY s314500.template_id (id) FROM stdin;
    s314500          s314500    false    225       3524.dat �           0    0    auth_lobbies_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('s314500.auth_lobbies_id_seq', 1, true);
          s314500          s314500    false    217         �           0    0    auth_players_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('s314500.auth_players_id_seq', 4, true);
          s314500          s314500    false    219         �           0    0    card_type_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('s314500.card_type_id_seq', 66, true);
          s314500          s314500    false    223         �           0    0    t_card_number_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('s314500.t_card_number_id_seq', 4, true);
          s314500          s314500    false    228         �           0    0    template_id_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('s314500.template_id_id_seq', 8, true);
          s314500          s314500    false    230                    2606    17477    card card_type_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY s314500.card
    ADD CONSTRAINT card_type_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY s314500.card DROP CONSTRAINT card_type_pkey;
       s314500            s314500    false    222                    2606    17479 "   cards_on_table cards_on_table_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cards_on_table_pkey PRIMARY KEY (x, y);
 M   ALTER TABLE ONLY s314500.cards_on_table DROP CONSTRAINT cards_on_table_pkey;
       s314500            s314500    false    224    224                    2606    17469    auth_lobbies lobbies_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY s314500.auth_lobbies
    ADD CONSTRAINT lobbies_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY s314500.auth_lobbies DROP CONSTRAINT lobbies_pkey;
       s314500            s314500    false    216                    2606    17471    auth_players players_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY s314500.auth_players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY s314500.auth_players DROP CONSTRAINT players_pkey;
       s314500            s314500    false    218         #           2606    17481    t_card_color t_card_color_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY s314500.t_card_color
    ADD CONSTRAINT t_card_color_pkey PRIMARY KEY (id);
 I   ALTER TABLE ONLY s314500.t_card_color DROP CONSTRAINT t_card_color_pkey;
       s314500            s314500    false    226         %           2606    17483     t_card_number t_card_number_pkey 
   CONSTRAINT     _   ALTER TABLE ONLY s314500.t_card_number
    ADD CONSTRAINT t_card_number_pkey PRIMARY KEY (id);
 K   ALTER TABLE ONLY s314500.t_card_number DROP CONSTRAINT t_card_number_pkey;
       s314500            s314500    false    227         '           2606    17485    t_card_type t_card_type_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY s314500.t_card_type
    ADD CONSTRAINT t_card_type_pkey PRIMARY KEY (id);
 G   ALTER TABLE ONLY s314500.t_card_type DROP CONSTRAINT t_card_type_pkey;
       s314500            s314500    false    229         !           2606    17487    template_id template_id_pkey 
   CONSTRAINT     [   ALTER TABLE ONLY s314500.template_id
    ADD CONSTRAINT template_id_pkey PRIMARY KEY (id);
 G   ALTER TABLE ONLY s314500.template_id DROP CONSTRAINT template_id_pkey;
       s314500            s314500    false    225                    2606    17473    auth_tokens tokens_pkey 
   CONSTRAINT     V   ALTER TABLE ONLY s314500.auth_tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (tk);
 B   ALTER TABLE ONLY s314500.auth_tokens DROP CONSTRAINT tokens_pkey;
       s314500            s314500    false    220                    2606    17475    auth_users users_pkey 
   CONSTRAINT     W   ALTER TABLE ONLY s314500.auth_users
    ADD CONSTRAINT users_pkey PRIMARY KEY (login);
 @   ALTER TABLE ONLY s314500.auth_users DROP CONSTRAINT users_pkey;
       s314500            s314500    false    221         +           2606    17503 ,   cards_on_table cards_on_table_card_type_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cards_on_table_card_type_fkey FOREIGN KEY (card_id) REFERENCES s314500.card(id);
 W   ALTER TABLE ONLY s314500.cards_on_table DROP CONSTRAINT cards_on_table_card_type_fkey;
       s314500          s314500    false    222    224    3357         (           2606    17488 "   auth_players players_lobby_id_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.auth_players
    ADD CONSTRAINT players_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.auth_lobbies(id) NOT VALID;
 M   ALTER TABLE ONLY s314500.auth_players DROP CONSTRAINT players_lobby_id_fkey;
       s314500          s314500    false    3349    216    218         )           2606    17493    auth_players players_tk_fkey    FK CONSTRAINT     ~   ALTER TABLE ONLY s314500.auth_players
    ADD CONSTRAINT players_tk_fkey FOREIGN KEY (tk) REFERENCES s314500.auth_tokens(tk);
 G   ALTER TABLE ONLY s314500.auth_players DROP CONSTRAINT players_tk_fkey;
       s314500          s314500    false    218    220    3353         *           2606    17498    auth_tokens tokens_login_fkey    FK CONSTRAINT     �   ALTER TABLE ONLY s314500.auth_tokens
    ADD CONSTRAINT tokens_login_fkey FOREIGN KEY (login) REFERENCES s314500.auth_users(login);
 H   ALTER TABLE ONLY s314500.auth_tokens DROP CONSTRAINT tokens_login_fkey;
       s314500          s314500    false    3355    220    221                                                                                                                                                                               3515.dat                                                                                            0000600 0004000 0002000 00000000045 14767070160 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	123123123	\N	Ready	Test Lobby
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           3517.dat                                                                                            0000600 0004000 0002000 00000000147 14767070160 0014263 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        3	874a3c42-9927-4109-9ed5-95239eddaba7	Ready	0	1
4	e55f27ec-dde6-4d90-a628-c62ec8dcf7a4	Ready	0	1
\.


                                                                                                                                                                                                                                                                                                                                                                                                                         3519.dat                                                                                            0000600 0004000 0002000 00000000562 14767070160 0014266 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        d8ad5f51-f31a-48d6-b394-9efb4a7b0586	nexie	2025-03-17 22:54:54.625892+03
252c4153-30ad-472f-8db4-4d61b7df4f9d	nexie	2025-03-17 23:03:29.056772+03
874a3c42-9927-4109-9ed5-95239eddaba7	nexie	2025-03-17 23:03:31.093586+03
e55f27ec-dde6-4d90-a628-c62ec8dcf7a4	so_0l	2025-03-18 00:35:01.424362+03
52fea865-c57d-4ccb-9e25-565bcbb02bc6	so_0l	2025-03-18 00:35:13.049592+03
\.


                                                                                                                                              3520.dat                                                                                            0000600 0004000 0002000 00000000125 14767070160 0014251 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        nexie	31323334353637386d65676173616c74
so_0l	3132333132333132336d65676173616c74
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                           3521.dat                                                                                            0000600 0004000 0002000 00000002224 14767070160 0014254 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	yellow	square	1
2	yellow	square	2
3	yellow	square	3
4	yellow	square	4
5	yellow	circule	1
6	yellow	circule	2
7	yellow	circule	3
8	yellow	circule	4
9	yellow	triangle	1
10	yellow	triangle	2
11	yellow	triangle	3
12	yellow	triangle	4
13	yellow	cross	1
14	yellow	cross	2
15	yellow	cross	3
16	yellow	cross	4
17	green	square	1
18	green	square	2
19	green	square	3
20	green	square	4
21	green	circule	1
22	green	circule	2
23	green	circule	3
24	green	circule	4
25	green	triangle	1
26	green	triangle	2
27	green	triangle	3
28	green	triangle	4
29	green	cross	1
30	green	cross	2
31	green	cross	3
32	green	cross	4
33	red	square	1
34	red	square	2
35	red	square	3
36	red	square	4
37	red	circule	1
38	red	circule	2
39	red	circule	3
40	red	circule	4
41	red	triangle	1
42	red	triangle	2
43	red	triangle	3
44	red	triangle	4
45	red	cross	1
46	red	cross	2
47	red	cross	3
48	red	cross	4
49	blue	square	1
50	blue	square	2
51	blue	square	3
52	blue	square	4
53	blue	circule	1
54	blue	circule	2
55	blue	circule	3
56	blue	circule	4
57	blue	triangle	1
58	blue	triangle	2
59	blue	triangle	3
60	blue	triangle	4
61	blue	cross	1
62	blue	cross	2
63	blue	cross	3
64	blue	cross	4
65	\N	\N	\N
66	\N	\N	\N
\.


                                                                                                                                                                                                                                                                                                                                                                            3523.dat                                                                                            0000600 0004000 0002000 00000000013 14767070160 0014250 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        0	0	1
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     3525.dat                                                                                            0000600 0004000 0002000 00000000043 14767070160 0014255 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	yellow
2	green
3	red
4	blue
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             3526.dat                                                                                            0000600 0004000 0002000 00000000025 14767070160 0014256 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        1	1
2	2
3	3
4	4
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           3528.dat                                                                                            0000600 0004000 0002000 00000000053 14767070160 0014261 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        5	square
6	circule
7	triangle
8	cross
\.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     3524.dat                                                                                            0000600 0004000 0002000 00000000005 14767070160 0014252 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        \.


                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           restore.sql                                                                                         0000600 0004000 0002000 00000047070 14767070160 0015404 0                                                                                                    ustar 00postgres                        postgres                        0000000 0000000                                                                                                                                                                        --
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

DROP DATABASE yota3;
--
-- Name: yota3; Type: DATABASE; Schema: -; Owner: s314500
--

CREATE DATABASE yota3 WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'en_US.UTF-8';


ALTER DATABASE yota3 OWNER TO s314500;

\connect yota3

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
-- Name: s314500; Type: SCHEMA; Schema: -; Owner: s314500
--

CREATE SCHEMA s314500;


ALTER SCHEMA s314500 OWNER TO s314500;

--
-- Name: auth_create_lobby(uuid, text, text); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_create_lobby(p_tk uuid, p_name text DEFAULT 'New Lobby'::text, p_password text DEFAULT ''::text) RETURNS bigint
    LANGUAGE plpgsql
    AS $$
DECLARE 

	newLobbyId bigint;

BEGIN 

	IF s314500.auth_current_lobby(p_tk) != -1 THEN 
		RAISE EXCEPTION 'Player trying to create a lobby, while being in one';
	END IF;

	newLobbyId = nextval('s314500.auth_lobbies_id_seq'::regclass);
	INSERT INTO s314500.auth_lobbies(id, name, password) VALUES
	(newLobbyId, p_name, p_password);

	-- s314500.auth_join_lobby(p_tk, newLobbyId, p_password);
	RETURN newLobbyId;

END;
$$;


ALTER FUNCTION s314500.auth_create_lobby(p_tk uuid, p_name text, p_password text) OWNER TO s314500;

--
-- Name: auth_create_token(text); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_create_token(p_login text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE 
	newTk UUID;
BEGIN 
	newTk = gen_random_uuid();
	INSERT INTO s314500.auth_tokens(login, tk) VALUES 
	(p_login, newTk);

	RETURN newTk;
END;
$$;


ALTER FUNCTION s314500.auth_create_token(p_login text) OWNER TO s314500;

--
-- Name: auth_current_lobby(uuid); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_current_lobby(p_tk uuid) RETURNS bigint
    LANGUAGE plpgsql
    AS $$DECLARE 

	outLobbyId bigint;

BEGIN
	outLobbyId = -1;

	IF NOT EXISTS (SELECT (1) FROM s314500.auth_players p WHERE p.tk = p_tk) THEN 
		RETURN -1;
	END IF;

	SELECT lobby_id FROM s314500.auth_players p WHERE p.tk = p_tk
	INTO outLobbyId; 

	RETURN outLobbyId;

END;$$;


ALTER FUNCTION s314500.auth_current_lobby(p_tk uuid) OWNER TO s314500;

--
-- Name: auth_current_player(uuid); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_current_player(p_tk uuid) RETURNS bigint
    LANGUAGE plpgsql
    AS $$DECLARE
	player_id bigint;
BEGIN

	SELECT p.id FROM s314500.auth_players p WHERE p.tk = p_tk 
	INTO player_id;

	IF player_id = NULL THEN 
		RAISE EXCEPTION 'No curent player';
	END IF;

	return player_id;

END;$$;


ALTER FUNCTION s314500.auth_current_player(p_tk uuid) OWNER TO s314500;

--
-- Name: auth_hash_password(text); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_hash_password(p_password text) RETURNS text
    LANGUAGE plpgsql
    AS $$BEGIN
    -- Хэширование пароля с добавлением соли 'megasalt'
    RETURN encode(convert_to(CONCAT(p_password, 'megasalt'), 'UTF8'), 'hex');
END;$$;


ALTER FUNCTION s314500.auth_hash_password(p_password text) OWNER TO s314500;

--
-- Name: auth_join_lobby(uuid, bigint, text); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_join_lobby(p_tk uuid, p_lobby bigint, p_password text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE 

	lobbyPassword text;

BEGIN 

	IF s314500.auth_current_lobby(p_tk) != -1 THEN
		RAISE EXCEPTION 'Already in lobby';
	END IF;

	IF p_lobby NOT IN (SELECT id FROM s314500.auth_lobbies) THEN 
		RAISE EXCEPTION 'Lobby does not exist';
	END IF;
	
	SELECT password FROM s314500.auth_lobbies l WHERE l.id = p_lobby 
	INTO lobbyPassword;

	IF lobbyPassword != p_password THEN
		RAISE EXCEPTION 'Wrong password for lobby';
	END IF;
	
	INSERT INTO s314500.auth_players (tk, lobby_id) VALUES
	(p_tk, p_lobby);

	RETURN TRUE;
	
END;
$$;


ALTER FUNCTION s314500.auth_join_lobby(p_tk uuid, p_lobby bigint, p_password text) OWNER TO s314500;

--
-- Name: auth_login(text, text); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_login(p_username text, p_password text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE 
	tk UUID;
	storedPassword text;
BEGIN
	IF p_username NOT IN (SELECT login from s314500.auth_users) THEN
		RAISE EXCEPTION 'Unknown user';
	END IF;

	SELECT password FROM s314500.auth_users WHERE login = p_username
	INTO storedPassword;

	IF s314500.auth_hash_password(p_password) != storedPassword THEN 
		RAISE EXCEPTION 'Wrong password';
	END IF;

	tk = s314500.auth_create_token(p_username);
	RETURN tk;
END; 
$$;


ALTER FUNCTION s314500.auth_login(p_username text, p_password text) OWNER TO s314500;

--
-- Name: auth_player_count(bigint); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_player_count(p_lobby bigint) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE 
	out integer;
BEGIN

	IF p_lobby NOT IN (SELECT id FROM s314500.auth_lobbies) THEN
		RETURN 0;
	END IF;

	SELECT COUNT(1) FROM s314500.auth_players p WHERE p.lobby_id = p_lobby 
	INTO out;

	RETURN out;
END;
$$;


ALTER FUNCTION s314500.auth_player_count(p_lobby bigint) OWNER TO s314500;

--
-- Name: auth_register_user(text, text); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_register_user(p_username text, p_password text) RETURNS uuid
    LANGUAGE plpgsql
    AS $$
DECLARE 
	tk uuid;
	hashedPassword text;
BEGIN 

	IF p_username IN (SELECT login FROM s314500.auth_users) THEN
		RAISE EXCEPTION 'User with this username exists';
	END IF;

	hashedPassword = s314500.auth_hash_password(p_password);

	INSERT INTO s314500.auth_users (login, password) VALUES 
	(p_username, hashedPassword);

	RETURN s314500.auth_create_token(p_username);
END;
$$;


ALTER FUNCTION s314500.auth_register_user(p_username text, p_password text) OWNER TO s314500;

--
-- Name: auth_set_player_state(uuid, text); Type: FUNCTION; Schema: s314500; Owner: s314500
--

CREATE FUNCTION s314500.auth_set_player_state(p_tk uuid, p_state text) RETURNS boolean
    LANGUAGE plpgsql
    AS $$
DECLARE

	player_id bigint; 
	_lobby_id bigint; 

BEGIN

	player_id = s314500.auth_current_player(p_tk);
	_lobby_id  = s314500.auth_current_lobby(p_tk);

	UPDATE s314500.auth_players p SET state = p_state 
	WHERE p.id = player_id;

	IF (SELECT COUNT(1) FROM s314500.auth_players p WHERE p.state = 'Ready' AND p.lobby_id = _lobby_id) = s314500.auth_player_count(_lobby_id) 
	AND s314500.auth_player_count(_lobby_id) >= 2 THEN 
		CALL begin_game(_lobby_id);
	END IF;

	RETURN TRUE;
END;
$$;


ALTER FUNCTION s314500.auth_set_player_state(p_tk uuid, p_state text) OWNER TO s314500;

--
-- Name: begin_game(bigint); Type: PROCEDURE; Schema: s314500; Owner: s314500
--

CREATE PROCEDURE s314500.begin_game(IN p_lobby bigint)
    LANGUAGE plpgsql
    AS $$
BEGIN


UPDATE s314500.auth_lobbies l SET state = 'Ready' WHERE l.id = p_lobby; 


END;
$$;


ALTER PROCEDURE s314500.begin_game(IN p_lobby bigint) OWNER TO s314500;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: auth_lobbies; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.auth_lobbies (
    id bigint NOT NULL,
    password character varying(100),
    turn_time integer,
    state text DEFAULT 'NotReady'::text NOT NULL,
    name text DEFAULT 'New Lobby'::text
);


ALTER TABLE s314500.auth_lobbies OWNER TO s314500;

--
-- Name: auth_lobbies_id_seq; Type: SEQUENCE; Schema: s314500; Owner: s314500
--

CREATE SEQUENCE s314500.auth_lobbies_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.auth_lobbies_id_seq OWNER TO s314500;

--
-- Name: auth_lobbies_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: s314500
--

ALTER SEQUENCE s314500.auth_lobbies_id_seq OWNED BY s314500.auth_lobbies.id;


--
-- Name: auth_players; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.auth_players (
    id bigint NOT NULL,
    tk uuid NOT NULL,
    state text DEFAULT 'NotReady'::text NOT NULL,
    score integer DEFAULT 0 NOT NULL,
    lobby_id bigint NOT NULL
);


ALTER TABLE s314500.auth_players OWNER TO s314500;

--
-- Name: auth_players_id_seq; Type: SEQUENCE; Schema: s314500; Owner: s314500
--

CREATE SEQUENCE s314500.auth_players_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.auth_players_id_seq OWNER TO s314500;

--
-- Name: auth_players_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: s314500
--

ALTER SEQUENCE s314500.auth_players_id_seq OWNED BY s314500.auth_players.id;


--
-- Name: auth_tokens; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.auth_tokens (
    tk uuid DEFAULT gen_random_uuid() NOT NULL,
    login character varying(100) NOT NULL,
    creation_time timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE s314500.auth_tokens OWNER TO s314500;

--
-- Name: auth_users; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.auth_users (
    login character varying(100) NOT NULL,
    password character varying(1000) NOT NULL
);


ALTER TABLE s314500.auth_users OWNER TO s314500;

--
-- Name: card; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.card (
    id integer NOT NULL,
    color text,
    type text,
    number integer
);


ALTER TABLE s314500.card OWNER TO s314500;

--
-- Name: card_type_id_seq; Type: SEQUENCE; Schema: s314500; Owner: s314500
--

CREATE SEQUENCE s314500.card_type_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.card_type_id_seq OWNER TO s314500;

--
-- Name: card_type_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: s314500
--

ALTER SEQUENCE s314500.card_type_id_seq OWNED BY s314500.card.id;


--
-- Name: cards_on_table; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.cards_on_table (
    x integer NOT NULL,
    y integer NOT NULL,
    card_id integer
);


ALTER TABLE s314500.cards_on_table OWNER TO s314500;

--
-- Name: template_id; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.template_id (
    id bigint NOT NULL
);


ALTER TABLE s314500.template_id OWNER TO s314500;

--
-- Name: t_card_color; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.t_card_color (
    name text
)
INHERITS (s314500.template_id);


ALTER TABLE s314500.t_card_color OWNER TO s314500;

--
-- Name: t_card_number; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.t_card_number (
    id integer NOT NULL,
    number integer
);


ALTER TABLE s314500.t_card_number OWNER TO s314500;

--
-- Name: t_card_number_id_seq; Type: SEQUENCE; Schema: s314500; Owner: s314500
--

CREATE SEQUENCE s314500.t_card_number_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.t_card_number_id_seq OWNER TO s314500;

--
-- Name: t_card_number_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: s314500
--

ALTER SEQUENCE s314500.t_card_number_id_seq OWNED BY s314500.t_card_number.id;


--
-- Name: t_card_type; Type: TABLE; Schema: s314500; Owner: s314500
--

CREATE TABLE s314500.t_card_type (
    name text
)
INHERITS (s314500.template_id);


ALTER TABLE s314500.t_card_type OWNER TO s314500;

--
-- Name: template_id_id_seq; Type: SEQUENCE; Schema: s314500; Owner: s314500
--

CREATE SEQUENCE s314500.template_id_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE s314500.template_id_id_seq OWNER TO s314500;

--
-- Name: template_id_id_seq; Type: SEQUENCE OWNED BY; Schema: s314500; Owner: s314500
--

ALTER SEQUENCE s314500.template_id_id_seq OWNED BY s314500.template_id.id;


--
-- Name: auth_lobbies id; Type: DEFAULT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_lobbies ALTER COLUMN id SET DEFAULT nextval('s314500.auth_lobbies_id_seq'::regclass);


--
-- Name: auth_players id; Type: DEFAULT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_players ALTER COLUMN id SET DEFAULT nextval('s314500.auth_players_id_seq'::regclass);


--
-- Name: card id; Type: DEFAULT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.card ALTER COLUMN id SET DEFAULT nextval('s314500.card_type_id_seq'::regclass);


--
-- Name: t_card_color id; Type: DEFAULT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.t_card_color ALTER COLUMN id SET DEFAULT nextval('s314500.template_id_id_seq'::regclass);


--
-- Name: t_card_number id; Type: DEFAULT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.t_card_number ALTER COLUMN id SET DEFAULT nextval('s314500.t_card_number_id_seq'::regclass);


--
-- Name: t_card_type id; Type: DEFAULT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.t_card_type ALTER COLUMN id SET DEFAULT nextval('s314500.template_id_id_seq'::regclass);


--
-- Name: template_id id; Type: DEFAULT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.template_id ALTER COLUMN id SET DEFAULT nextval('s314500.template_id_id_seq'::regclass);


--
-- Data for Name: auth_lobbies; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.auth_lobbies (id, password, turn_time, state, name) FROM stdin;
\.
COPY s314500.auth_lobbies (id, password, turn_time, state, name) FROM '$$PATH$$/3515.dat';

--
-- Data for Name: auth_players; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.auth_players (id, tk, state, score, lobby_id) FROM stdin;
\.
COPY s314500.auth_players (id, tk, state, score, lobby_id) FROM '$$PATH$$/3517.dat';

--
-- Data for Name: auth_tokens; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.auth_tokens (tk, login, creation_time) FROM stdin;
\.
COPY s314500.auth_tokens (tk, login, creation_time) FROM '$$PATH$$/3519.dat';

--
-- Data for Name: auth_users; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.auth_users (login, password) FROM stdin;
\.
COPY s314500.auth_users (login, password) FROM '$$PATH$$/3520.dat';

--
-- Data for Name: card; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.card (id, color, type, number) FROM stdin;
\.
COPY s314500.card (id, color, type, number) FROM '$$PATH$$/3521.dat';

--
-- Data for Name: cards_on_table; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.cards_on_table (x, y, card_id) FROM stdin;
\.
COPY s314500.cards_on_table (x, y, card_id) FROM '$$PATH$$/3523.dat';

--
-- Data for Name: t_card_color; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.t_card_color (id, name) FROM stdin;
\.
COPY s314500.t_card_color (id, name) FROM '$$PATH$$/3525.dat';

--
-- Data for Name: t_card_number; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.t_card_number (id, number) FROM stdin;
\.
COPY s314500.t_card_number (id, number) FROM '$$PATH$$/3526.dat';

--
-- Data for Name: t_card_type; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.t_card_type (id, name) FROM stdin;
\.
COPY s314500.t_card_type (id, name) FROM '$$PATH$$/3528.dat';

--
-- Data for Name: template_id; Type: TABLE DATA; Schema: s314500; Owner: s314500
--

COPY s314500.template_id (id) FROM stdin;
\.
COPY s314500.template_id (id) FROM '$$PATH$$/3524.dat';

--
-- Name: auth_lobbies_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: s314500
--

SELECT pg_catalog.setval('s314500.auth_lobbies_id_seq', 1, true);


--
-- Name: auth_players_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: s314500
--

SELECT pg_catalog.setval('s314500.auth_players_id_seq', 4, true);


--
-- Name: card_type_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: s314500
--

SELECT pg_catalog.setval('s314500.card_type_id_seq', 66, true);


--
-- Name: t_card_number_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: s314500
--

SELECT pg_catalog.setval('s314500.t_card_number_id_seq', 4, true);


--
-- Name: template_id_id_seq; Type: SEQUENCE SET; Schema: s314500; Owner: s314500
--

SELECT pg_catalog.setval('s314500.template_id_id_seq', 8, true);


--
-- Name: card card_type_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.card
    ADD CONSTRAINT card_type_pkey PRIMARY KEY (id);


--
-- Name: cards_on_table cards_on_table_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cards_on_table_pkey PRIMARY KEY (x, y);


--
-- Name: auth_lobbies lobbies_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_lobbies
    ADD CONSTRAINT lobbies_pkey PRIMARY KEY (id);


--
-- Name: auth_players players_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_players
    ADD CONSTRAINT players_pkey PRIMARY KEY (id);


--
-- Name: t_card_color t_card_color_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.t_card_color
    ADD CONSTRAINT t_card_color_pkey PRIMARY KEY (id);


--
-- Name: t_card_number t_card_number_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.t_card_number
    ADD CONSTRAINT t_card_number_pkey PRIMARY KEY (id);


--
-- Name: t_card_type t_card_type_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.t_card_type
    ADD CONSTRAINT t_card_type_pkey PRIMARY KEY (id);


--
-- Name: template_id template_id_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.template_id
    ADD CONSTRAINT template_id_pkey PRIMARY KEY (id);


--
-- Name: auth_tokens tokens_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_tokens
    ADD CONSTRAINT tokens_pkey PRIMARY KEY (tk);


--
-- Name: auth_users users_pkey; Type: CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_users
    ADD CONSTRAINT users_pkey PRIMARY KEY (login);


--
-- Name: cards_on_table cards_on_table_card_type_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.cards_on_table
    ADD CONSTRAINT cards_on_table_card_type_fkey FOREIGN KEY (card_id) REFERENCES s314500.card(id);


--
-- Name: auth_players players_lobby_id_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_players
    ADD CONSTRAINT players_lobby_id_fkey FOREIGN KEY (lobby_id) REFERENCES s314500.auth_lobbies(id) NOT VALID;


--
-- Name: auth_players players_tk_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_players
    ADD CONSTRAINT players_tk_fkey FOREIGN KEY (tk) REFERENCES s314500.auth_tokens(tk);


--
-- Name: auth_tokens tokens_login_fkey; Type: FK CONSTRAINT; Schema: s314500; Owner: s314500
--

ALTER TABLE ONLY s314500.auth_tokens
    ADD CONSTRAINT tokens_login_fkey FOREIGN KEY (login) REFERENCES s314500.auth_users(login);


--
-- PostgreSQL database dump complete
--

                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        