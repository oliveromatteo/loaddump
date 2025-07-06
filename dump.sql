--
-- PostgreSQL database dump
--

-- Dumped from database version 15.13 (Debian 15.13-1.pgdg120+1)
-- Dumped by pg_dump version 15.13 (Debian 15.13-1.pgdg120+1)

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
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: user
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO "user";

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: booking_participants; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.booking_participants (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    booking_id uuid NOT NULL,
    user_id uuid NOT NULL,
    team character varying(1) NOT NULL,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT booking_participants_team_check CHECK (((team)::text = ANY (ARRAY[('A'::character varying)::text, ('B'::character varying)::text])))
);


ALTER TABLE public.booking_participants OWNER TO "user";

--
-- Name: bookings; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.bookings (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    court_id uuid NOT NULL,
    organizer_id uuid NOT NULL,
    booking_date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    match_type character varying(255) NOT NULL,
    max_players integer NOT NULL,
    current_players integer DEFAULT 1,
    skill_level_min integer,
    skill_level_max integer,
    gender_restriction character varying(255),
    cost_per_player numeric(10,2) NOT NULL,
    total_cost numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'EUR'::character varying,
    status character varying(255) DEFAULT 'pending'::character varying NOT NULL,
    description text,
    payment_status character varying(255) DEFAULT 'pending'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT bookings_gender_restriction_check CHECK (((gender_restriction)::text = ANY (ARRAY[('mixed'::character varying)::text, ('male_only'::character varying)::text, ('female_only'::character varying)::text]))),
    CONSTRAINT bookings_match_type_check CHECK (((match_type)::text = ANY (ARRAY[('private'::character varying)::text, ('open'::character varying)::text, ('tournament'::character varying)::text]))),
    CONSTRAINT bookings_payment_status_check CHECK (((payment_status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'cancelled'::character varying, 'refunded'::character varying])::text[]))),
    CONSTRAINT bookings_skill_level_max_check CHECK (((skill_level_max >= 1) AND (skill_level_max <= 5))),
    CONSTRAINT bookings_skill_level_min_check CHECK (((skill_level_min >= 1) AND (skill_level_min <= 5))),
    CONSTRAINT bookings_status_check CHECK (((status)::text = ANY (ARRAY[('pending'::character varying)::text, ('confirmed'::character varying)::text, ('cancelled'::character varying)::text, ('completed'::character varying)::text])))
);


ALTER TABLE public.bookings OWNER TO "user";

--
-- Name: court_availability; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.court_availability (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    court_id uuid NOT NULL,
    date date NOT NULL,
    start_time time without time zone NOT NULL,
    end_time time without time zone NOT NULL,
    is_available boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.court_availability OWNER TO "user";

--
-- Name: courts; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.courts (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    facility_id uuid NOT NULL,
    name character varying(100) NOT NULL,
    court_type character varying(50) NOT NULL,
    surface_type character varying(50) NOT NULL,
    is_indoor boolean DEFAULT false,
    has_lighting boolean DEFAULT true,
    hourly_rate numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'EUR'::character varying,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT courts_court_type_check CHECK (((court_type)::text = ANY ((ARRAY['football_5'::character varying, 'football_7'::character varying, 'football_11'::character varying])::text[])))
);


ALTER TABLE public.courts OWNER TO "user";

--
-- Name: facilities; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.facilities (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    address character varying(500) NOT NULL,
    city character varying(100) NOT NULL,
    postal_code character varying(20) NOT NULL,
    country character varying(100) DEFAULT 'Italy'::character varying NOT NULL,
    latitude numeric(10,8),
    longitude numeric(10,8),
    phone character varying(20),
    email character varying(255),
    website character varying(500),
    opening_hours jsonb,
    amenities text[],
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.facilities OWNER TO "user";

--
-- Name: payments; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.payments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    booking_id uuid,
    tournament_id uuid,
    amount numeric(10,2) NOT NULL,
    currency character varying(3) DEFAULT 'EUR'::character varying,
    payment_method character varying(50) NOT NULL,
    payment_provider character varying(50) NOT NULL,
    provider_payment_id character varying(255),
    status character varying(50) DEFAULT 'pending'::character varying NOT NULL,
    payment_date timestamp with time zone,
    failure_reason text,
    metadata jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    paypal_capture_id character varying(255),
    paypal_order_id character varying(255),
    CONSTRAINT payments_status_check CHECK (((status)::text = ANY ((ARRAY['pending'::character varying, 'completed'::character varying, 'failed'::character varying, 'cancelled'::character varying, 'refunded'::character varying])::text[])))
);


ALTER TABLE public.payments OWNER TO "user";

--
-- Name: tournament_team_players; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.tournament_team_players (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    team_id uuid NOT NULL,
    player_id uuid NOT NULL,
    is_captain boolean DEFAULT false,
    joined_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.tournament_team_players OWNER TO "user";

--
-- Name: tournament_teams; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.tournament_teams (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    tournament_id uuid NOT NULL,
    team_name character varying(100) NOT NULL,
    captain_id uuid NOT NULL,
    status character varying(50) DEFAULT 'registered'::character varying NOT NULL,
    registration_date timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tournament_teams_status_check CHECK (((status)::text = ANY ((ARRAY['registered'::character varying, 'confirmed'::character varying, 'disqualified'::character varying, 'withdrawn'::character varying])::text[])))
);


ALTER TABLE public.tournament_teams OWNER TO "user";

--
-- Name: tournaments; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.tournaments (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    name character varying(255) NOT NULL,
    description text,
    facility_id uuid NOT NULL,
    organizer_id uuid NOT NULL,
    tournament_type character varying(50) NOT NULL,
    sport_type character varying(50) NOT NULL,
    max_teams integer NOT NULL,
    current_teams integer DEFAULT 0,
    entry_fee numeric(10,2) NOT NULL,
    prize_pool numeric(10,2) DEFAULT 0,
    currency character varying(3) DEFAULT 'EUR'::character varying,
    start_date date NOT NULL,
    end_date date NOT NULL,
    registration_deadline date NOT NULL,
    skill_level_min integer,
    skill_level_max integer,
    age_restriction character varying(50),
    gender_restriction character varying(20),
    status character varying(50) DEFAULT 'open'::character varying NOT NULL,
    rules text,
    prizes jsonb,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tournaments_gender_restriction_check CHECK (((gender_restriction)::text = ANY ((ARRAY['mixed'::character varying, 'male_only'::character varying, 'female_only'::character varying])::text[]))),
    CONSTRAINT tournaments_skill_level_max_check CHECK (((skill_level_max >= 1) AND (skill_level_max <= 5))),
    CONSTRAINT tournaments_skill_level_min_check CHECK (((skill_level_min >= 1) AND (skill_level_min <= 5))),
    CONSTRAINT tournaments_sport_type_check CHECK (((sport_type)::text = ANY ((ARRAY['football_5'::character varying, 'football_7'::character varying])::text[]))),
    CONSTRAINT tournaments_status_check CHECK (((status)::text = ANY ((ARRAY['open'::character varying, 'full'::character varying, 'in_progress'::character varying, 'completed'::character varying, 'cancelled'::character varying])::text[]))),
    CONSTRAINT tournaments_tournament_type_check CHECK (((tournament_type)::text = ANY ((ARRAY['knockout'::character varying, 'round_robin'::character varying, 'league'::character varying])::text[])))
);


ALTER TABLE public.tournaments OWNER TO "user";

--
-- Name: user_tokens; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.user_tokens (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    token_type character varying(50) NOT NULL,
    token_hash character varying(500) NOT NULL,
    expires_at timestamp with time zone NOT NULL,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_tokens OWNER TO "user";

--
-- Name: user_wallets; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.user_wallets (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    user_id uuid NOT NULL,
    balance numeric(10,2) DEFAULT 0.00,
    currency character varying(3) DEFAULT 'EUR'::character varying,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.user_wallets OWNER TO "user";

--
-- Name: users; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    is_active boolean,
    avatar_url character varying(500),
    bio text,
    created_at timestamp(6) with time zone,
    date_of_birth date,
    email character varying(255) NOT NULL,
    email_verified boolean,
    first_name character varying(255) NOT NULL,
    gender character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    password_hash character varying(255) NOT NULL,
    phone character varying(255),
    preferred_position character varying(255),
    skill_level integer,
    updated_at timestamp(6) with time zone
);


ALTER TABLE public.users OWNER TO "user";

--
-- Name: wallet_transactions; Type: TABLE; Schema: public; Owner: user
--

CREATE TABLE public.wallet_transactions (
    id uuid DEFAULT public.uuid_generate_v4() NOT NULL,
    wallet_id uuid NOT NULL,
    transaction_type character varying(50) NOT NULL,
    amount numeric(10,2) NOT NULL,
    balance_after numeric(10,2) NOT NULL,
    reference_id uuid,
    description text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT wallet_transactions_transaction_type_check CHECK (((transaction_type)::text = ANY ((ARRAY['deposit'::character varying, 'withdrawal'::character varying, 'payment'::character varying, 'refund'::character varying])::text[])))
);


ALTER TABLE public.wallet_transactions OWNER TO "user";

--
-- Data for Name: booking_participants; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.booking_participants (id, booking_id, user_id, team, joined_at) FROM stdin;
50e974f6-c58f-4605-90aa-764f225de4b3	98b5b250-24a5-4c08-aea2-5f32cf5be25b	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-04 08:14:35.046551+00
43f8f2bd-4162-43fb-907d-4183f6c461e0	72292d77-4447-40ed-b3f8-0a49403ff205	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-04 08:15:38.828882+00
7ea89f7c-f02f-43a5-b7c2-9a58bd4b5dc4	2371a550-f9c8-4ef8-9d83-57c76fa8f043	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-04 08:30:18.851647+00
553c0f5b-9441-4245-9245-adc4d1ea7e7b	ec262b03-2cdd-4f82-b1a9-b811e7e88523	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-04 08:37:38.230873+00
ce4c398c-35e6-4c82-834a-b49acb6e79f5	1bce3c01-9a2a-4827-8e52-a5fde29be513	c53a09b8-7418-4c76-8aa9-a2466b2da02d	A	2025-07-04 08:44:51.296558+00
1a8f1b00-a557-46b4-9233-1dcc025b0311	e09b953e-d4e6-458d-9b07-e364ab3d9f64	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-04 08:45:23.750418+00
88ef0ab6-663d-4b2e-bf25-5770f64514fd	0e44c16c-fff0-45cb-ab0f-737452b1e7bd	c53a09b8-7418-4c76-8aa9-a2466b2da02d	A	2025-07-04 08:46:01.152785+00
57877d75-a9b7-4c5c-b456-a5217e7f5519	71fa6780-854c-4a9a-ae09-3f5112e9a852	b876d41f-203b-48bb-8bfb-a2e47b380e28	A	2025-07-04 09:01:38.687028+00
d5137f1b-537b-4430-8919-10e353791634	71fa6780-854c-4a9a-ae09-3f5112e9a852	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-04 09:01:38.720937+00
13ea144d-4927-454f-adaf-fd5cd60b3376	8b3bd501-a0d2-4a8f-8a9e-e372cf80a103	b876d41f-203b-48bb-8bfb-a2e47b380e28	A	2025-07-04 09:02:03.442581+00
0eaee793-b0a7-4074-b9e0-89a27a609ada	8b3bd501-a0d2-4a8f-8a9e-e372cf80a103	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-04 09:02:03.470559+00
6f9f135e-39db-46fd-a11f-7672a8472f33	10746554-2cc7-46d6-8862-730d5b425408	c53a09b8-7418-4c76-8aa9-a2466b2da02d	A	2025-07-04 09:58:05.954985+00
b592e3ce-1dba-44ce-8724-c5382079686f	10746554-2cc7-46d6-8862-730d5b425408	b876d41f-203b-48bb-8bfb-a2e47b380e28	A	2025-07-04 10:05:34.595092+00
e0ead67e-3555-46e6-99d6-063aba27bb19	c69dfe4b-05e9-486b-8592-8c5c0c0f0476	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-04 20:32:25.57506+00
caa21188-153a-4bca-937c-d2bfc49928c0	c69dfe4b-05e9-486b-8592-8c5c0c0f0476	b876d41f-203b-48bb-8bfb-a2e47b380e28	B	2025-07-04 20:32:25.612455+00
e8b14b10-0b7a-49b9-b3a1-57199328cfdf	58d210d9-9946-458c-82d4-c29527db5102	b876d41f-203b-48bb-8bfb-a2e47b380e28	A	2025-07-05 09:20:21.187482+00
aed0b8a7-39f8-40da-aac3-1a51585a9d08	58d210d9-9946-458c-82d4-c29527db5102	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-05 09:20:21.21338+00
4fd6856f-b698-4de1-98fc-83fd39c1ea58	f5631bfa-2b42-4acb-b127-4d7752350734	c53a09b8-7418-4c76-8aa9-a2466b2da02d	B	2025-07-06 10:15:00.909041+00
e23277a9-8b41-4a1a-a560-f04eec2d5df2	f5631bfa-2b42-4acb-b127-4d7752350734	b876d41f-203b-48bb-8bfb-a2e47b380e28	B	2025-07-06 10:15:00.939471+00
\.


--
-- Data for Name: bookings; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.bookings (id, court_id, organizer_id, booking_date, start_time, end_time, match_type, max_players, current_players, skill_level_min, skill_level_max, gender_restriction, cost_per_player, total_cost, currency, status, description, payment_status, created_at, updated_at) FROM stdin;
807a9f6f-bdad-47fe-a078-c0d160f4eebd	704cb674-174e-40d4-b5df-d1cc1d17637c	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-06-30	14:00:00	15:30:00	open	4	1	\N	\N	mixed	25.00	100.00	EUR	pending	\N	pending	2025-06-29 08:14:25.417821+00	2025-06-29 08:14:25.417851+00
f390b25a-1e35-4443-bc41-c1fe760ab367	704cb674-174e-40d4-b5df-d1cc1d17637c	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-06-30	15:30:00	16:30:00	open	4	1	\N	\N	mixed	25.00	100.00	EUR	pending	\N	pending	2025-06-29 08:16:44.059488+00	2025-06-29 08:16:44.059506+00
344f6a3f-86c6-433b-a377-0b805cf4e18a	704cb674-174e-40d4-b5df-d1cc1d17637c	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-06-30	12:00:00	13:00:00	open	4	1	\N	\N	mixed	25.00	100.00	EUR	pending	\N	pending	2025-06-29 11:31:51.467439+00	2025-06-29 11:31:51.467607+00
5f8fef2c-d5bc-4600-8008-fe8fac534d0f	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-10-02	08:00:00	09:00:00	open	4	1	\N	\N	mixed	25.00	100.00	EUR	pending	\N	pending	2025-06-29 12:32:18.021674+00	2025-06-29 12:32:18.021709+00
296ec9a2-bdb8-4ae5-884a-143e0a0d6544	4a7b67e3-714c-4077-a691-ca8df3866262	6a0bb94a-b5c8-4476-bec7-4147b7c76a2a	2025-06-28	20:00:00	21:00:00	open	10	1	\N	\N	\N	7.00	35.00	EUR	cancelled	Partita serale, tutti i livelli benvenuti!	pending	2025-06-26 16:04:19.533609+00	2025-06-29 13:22:11.065911+00
70d3ed92-23d3-4c0d-80e5-c73bff19e1c8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	3cc44dfa-accc-4234-a041-541802b62cae	2025-06-29	19:00:00	20:00:00	open	10	2	\N	\N	\N	8.00	40.00	EUR	cancelled	Match femminile, unite a noi!	pending	2025-06-26 16:04:19.533609+00	2025-06-29 13:23:42.65443+00
ee1190a6-6cec-410f-8034-edc8760a1d74	1bc0139e-a4d7-49de-95e8-4fad10a7e871	3864dda6-7a52-4d2e-a697-3b21f3f53763	2025-06-27	18:30:00	19:30:00	private	10	10	\N	\N	mixed	6.00	30.00	EUR	completed	Partita privata tra amici	pending	2025-06-26 16:04:19.533609+00	2025-06-29 13:35:54.439744+00
05ce7e3c-1d93-4c2c-bcc7-95aad39d7fc5	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	18:00:00	19:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 07:29:10.117177+00	2025-07-04 07:29:10.117212+00
959a3e5a-b2b4-4ed5-a002-3e1240e9a5ea	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	20:00:00	21:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 07:37:02.175846+00	2025-07-04 07:37:02.17588+00
8a5ed8fb-1f00-4961-b9c4-fe414452476f	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	21:00:00	22:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 07:39:56.348442+00	2025-07-04 07:39:56.348459+00
1534da65-e6d7-42b2-be20-0df2ad7189ae	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	e19ea95d-e249-40a9-a3e5-9f76038aba4e	2025-07-01	15:00:00	16:00:00	open	14	8	\N	\N	mixed	6.43	45.00	EUR	confirmed	Calcio a 7 domenicale	pending	2025-06-26 16:04:19.533609+00	2025-06-29 14:13:14.528952+00
c334f22c-2c21-4a68-84bc-ed39fce1f299	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	08:00:00	09:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 13:51:41.497854+00	2025-07-03 13:51:41.497987+00
f554028d-df02-4f0a-bac6-939f1f718c3f	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	09:00:00	10:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 13:52:09.721122+00	2025-07-03 13:52:09.72124+00
82e61d01-abd7-4d5d-9cc5-e21a1ae3cf7a	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	10:00:00	11:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 13:52:32.485675+00	2025-07-03 13:52:32.485685+00
5b91bf1a-195a-4c8d-98a3-aedb6650e41f	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	11:00:00	12:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 13:53:23.287112+00	2025-07-03 13:53:23.287141+00
671c4378-44d9-4567-addb-7fe0372d6cc0	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	12:00:00	13:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 13:57:12.817024+00	2025-07-03 13:57:12.817103+00
df43d377-fa7b-46c3-bc48-05750b71d6b2	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	13:00:00	14:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 14:00:00.970706+00	2025-07-03 14:00:00.970723+00
48af58b2-ce0e-430c-af44-9fab45df00f7	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	14:00:00	15:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 14:04:28.566403+00	2025-07-03 14:04:28.566422+00
941a8338-b505-4bc5-9b16-6777e627cc3a	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	15:00:00	16:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 14:05:10.282913+00	2025-07-03 14:05:10.283033+00
04a77446-5361-45d3-ba4e-44a8cb1bb9f0	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	16:00:00	17:00:00	open	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match aperto	pending	2025-07-03 14:11:38.602755+00	2025-07-03 14:11:38.602782+00
3252a8a8-ef29-4d1b-970e-05db82be6d97	5a80fd92-a468-49a4-b0cf-9c20b149c341	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-25	08:00:00	09:00:00	private	14	1	1	5	mixed	50.00	700.00	EUR	pending	Match privato	pending	2025-07-03 14:22:31.543533+00	2025-07-03 14:22:31.543544+00
c0b18ba9-e608-462a-ac76-4659fe51d4fa	5a80fd92-a468-49a4-b0cf-9c20b149c341	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-03	17:00:00	18:00:00	private	14	1	1	5	mixed	50.00	700.00	EUR	pending	Match privato	pending	2025-07-03 14:27:57.917908+00	2025-07-03 14:27:57.91793+00
de1b296d-1f2c-4e22-9f9c-6027b1f8950a	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-03	19:00:00	20:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 16:06:40.745916+00	2025-07-03 16:06:40.745984+00
c718a880-31d3-419e-aee1-bf5faf3cc2d6	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-03	20:00:00	21:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 16:16:21.535414+00	2025-07-03 16:16:21.535463+00
bf2e506c-c166-4c70-8c21-f804b9a7a15d	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	17:00:00	18:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 16:20:06.258812+00	2025-07-03 16:20:06.258848+00
b5a33041-6ce3-4b3d-9495-61453922c697	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	19:00:00	20:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-03 17:11:31.273797+00	2025-07-03 17:11:31.273832+00
c0452578-76e4-4673-84ef-11184790285e	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	10:00:00	11:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 07:43:06.109981+00	2025-07-04 07:43:06.109995+00
dd796a95-c6ce-44d0-a6cb-36caa56fbffa	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	08:00:00	09:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 07:48:52.058492+00	2025-07-04 07:48:52.058512+00
fa560a9a-8181-43cc-ba25-4e62eb2c3c5b	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	09:00:00	10:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:02:30.931066+00	2025-07-04 08:02:30.931103+00
a2db8bc8-ab46-418e-8245-5adb1d58611d	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	11:00:00	12:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:07:01.51894+00	2025-07-04 08:07:01.51898+00
98b5b250-24a5-4c08-aea2-5f32cf5be25b	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	12:00:00	13:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:14:34.98355+00	2025-07-04 08:14:35.03178+00
72292d77-4447-40ed-b3f8-0a49403ff205	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	13:00:00	14:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:15:38.789507+00	2025-07-04 08:15:38.813577+00
2371a550-f9c8-4ef8-9d83-57c76fa8f043	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	14:00:00	15:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:30:18.762472+00	2025-07-04 08:30:18.814948+00
ec262b03-2cdd-4f82-b1a9-b811e7e88523	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	15:00:00	16:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:37:38.169933+00	2025-07-04 08:37:38.219885+00
35e26a49-fe70-4299-a01d-084b63434403	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	16:00:00	17:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:44:14.892674+00	2025-07-04 08:44:14.892715+00
1bce3c01-9a2a-4827-8e52-a5fde29be513	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	17:00:00	18:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:44:51.25329+00	2025-07-04 08:44:51.281708+00
e09b953e-d4e6-458d-9b07-e364ab3d9f64	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	18:00:00	19:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:45:23.708168+00	2025-07-04 08:45:23.732348+00
0e44c16c-fff0-45cb-ab0f-737452b1e7bd	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	19:00:00	20:00:00	private	10	2	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 08:46:01.109005+00	2025-07-04 08:46:01.13652+00
71fa6780-854c-4a9a-ae09-3f5112e9a852	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	20:00:00	21:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 09:01:38.608084+00	2025-07-04 09:01:38.712481+00
10746554-2cc7-46d6-8862-730d5b425408	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-10-02	09:00:00	10:00:00	open	4	3	\N	\N	mixed	25.00	100.00	EUR	confirmed	\N	pending	2025-06-29 13:40:43.556948+00	2025-07-04 10:05:34.532287+00
8b3bd501-a0d2-4a8f-8a9e-e372cf80a103	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	21:00:00	22:00:00	open	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match aperto	pending	2025-07-04 09:02:03.385381+00	2025-07-04 09:02:03.45851+00
24671ed5-12cb-4f90-aeae-cf70c1839977	bcdf768c-979e-4c97-b5ba-9d4eacbac182	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	08:00:00	09:00:00	private	10	1	1	5	mixed	40.00	400.00	EUR	pending	Match privato	pending	2025-07-04 13:24:48.43996+00	2025-07-04 13:24:48.440011+00
60ae3da2-1501-451d-b5be-9568225f65e4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	c53a09b8-7418-4c76-8aa9-a2466b2da02d	2025-07-05	10:00:00	11:00:00	open	10	1	1	5	mixed	40.00	400.00	EUR	pending	Match aperto	pending	2025-07-04 13:27:39.311685+00	2025-07-04 13:27:39.311716+00
cd13cee9-c084-435a-98a7-a9ee6ec0d250	bcdf768c-979e-4c97-b5ba-9d4eacbac182	c53a09b8-7418-4c76-8aa9-a2466b2da02d	2025-07-05	09:00:00	10:00:00	open	10	1	1	5	mixed	40.00	400.00	EUR	confirmed	Match aperto	completed	2025-07-04 13:25:51.496371+00	2025-07-04 13:51:48.195772+00
c407dc4c-abe4-4b9a-aeba-c511e4d851e2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-04	17:00:00	18:00:00	open	10	1	1	5	mixed	40.00	400.00	EUR	pending	Match aperto	pending	2025-07-04 14:42:19.215687+00	2025-07-04 14:42:19.215732+00
6f412276-7639-4b20-af2c-39d304629aa5	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	08:00:00	09:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:22:27.99506+00	2025-07-04 15:22:27.995103+00
15d31543-c352-415d-866b-7cd4a0b6d2f0	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	09:00:00	10:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:24:32.045583+00	2025-07-04 15:24:32.045605+00
fcbbbb04-9c36-4535-96e8-bf8a72c90538	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	12:00:00	13:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:25:14.161062+00	2025-07-04 15:25:14.161086+00
7a939421-3967-45d3-a3c0-ce4ece0f9c90	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	10:00:00	11:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:27:00.938979+00	2025-07-04 15:27:00.939017+00
beb42db0-68df-4954-82b7-a6aa444b042d	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	11:00:00	12:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:28:42.222802+00	2025-07-04 15:28:42.22282+00
9a85a14b-d31e-4468-a1c5-579a628cb64b	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	08:00:00	09:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:30:52.062351+00	2025-07-04 15:30:52.062418+00
22c24de8-394b-45a1-a25e-ac340a589536	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-08	08:00:00	09:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-04 15:37:09.404457+00	2025-07-04 15:37:57.35875+00
a9477aec-86e4-4bb1-9bc3-6189b969f60e	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	09:00:00	10:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-04 15:39:33.22555+00	2025-07-04 15:40:27.466492+00
0b6451f2-0f17-46e0-be9e-044e51af28f0	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	10:00:00	11:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:43:33.619905+00	2025-07-04 15:43:33.619926+00
70a9f953-5a6f-42f8-9b8f-2bc0620f058e	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	11:00:00	12:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:44:42.485461+00	2025-07-04 15:44:42.485484+00
d19b6482-6e54-4209-8a99-64b44e903dc5	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-12	08:00:00	09:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:55:05.901499+00	2025-07-04 15:55:05.901514+00
4773ca39-7521-44a0-9fe1-2fd563d49b98	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-12	09:00:00	10:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 15:55:28.412283+00	2025-07-04 15:55:28.412297+00
d37c0273-6179-4cb5-bb58-84cf287a5bbd	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-26	21:00:00	22:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 19:50:10.876753+00	2025-07-04 19:50:10.876795+00
2771db94-668a-4985-87de-b86d89def82d	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-26	21:00:00	22:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 19:52:05.96287+00	2025-07-04 19:52:05.962901+00
4ea5f54b-2f23-4372-a748-9f0fbff303f6	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-26	21:00:00	22:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-04 19:52:25.106657+00	2025-07-04 19:55:06.199752+00
ccc348c2-16a5-45af-a393-f334b514add5	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-26	20:00:00	21:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 19:57:31.986028+00	2025-07-04 19:57:31.986046+00
eda75ea0-a42a-4373-aecd-0e80e62842ec	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-26	20:00:00	21:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 19:58:50.940134+00	2025-07-04 19:58:50.940219+00
4e1d7839-c26a-4dca-99f8-4d92768d08a8	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-26	20:00:00	21:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-04 19:59:54.228159+00	2025-07-04 20:01:03.853002+00
fecb785e-99ae-4f13-8ef7-6d160e75e273	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-26	19:00:00	20:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-04 20:02:38.551267+00	2025-07-04 20:04:19.178277+00
72bfdd0b-183a-4b03-8e86-697a8ea43812	1bc0139e-a4d7-49de-95e8-4fad10a7e871	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	08:00:00	09:00:00	private	10	1	1	5	mixed	30.00	300.00	EUR	pending	Match privato	pending	2025-07-04 20:13:07.945771+00	2025-07-04 20:13:07.945792+00
9a3b03b5-a0ec-45d7-9876-e63e2ea27e3e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	08:00:00	09:00:00	private	10	1	1	5	mixed	30.00	300.00	EUR	pending	Match privato	pending	2025-07-04 20:15:01.744172+00	2025-07-04 20:15:01.744191+00
e1c5b332-5b72-4637-86c3-41c04359ad83	1bc0139e-a4d7-49de-95e8-4fad10a7e871	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-05	08:00:00	09:00:00	private	10	1	1	5	mixed	30.00	300.00	EUR	confirmed	Match privato	completed	2025-07-04 20:17:30.954273+00	2025-07-04 20:18:30.393078+00
eeab50ab-dcaa-49f9-ac92-ff3319a3067d	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-25	08:00:00	09:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 20:31:56.778226+00	2025-07-04 20:31:56.778259+00
1986eeae-a649-4ea9-8da3-6d4c8600df9f	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	15:00:00	16:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-05 08:54:52.957721+00	2025-07-05 08:56:16.510934+00
c69dfe4b-05e9-486b-8592-8c5c0c0f0476	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-25	13:00:00	14:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-04 20:32:25.510745+00	2025-07-04 20:32:25.604185+00
88598c35-18d0-4c6f-aa9b-514bb897572c	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-26	18:00:00	19:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	cancelled	Match privato	failed	2025-07-04 20:07:49.844994+00	2025-07-05 08:29:49.521627+00
5bfd064f-b8fa-4485-9a27-f605ae6f9816	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	12:00:00	13:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-05 08:49:21.86924+00	2025-07-05 08:49:21.869276+00
d3635010-eccb-4ab3-a27d-31aad9be7492	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	13:00:00	14:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-05 08:51:55.747947+00	2025-07-05 08:51:55.747966+00
6abbd7c0-df73-4240-be1b-2a8d8f695b9e	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	13:00:00	14:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-05 08:53:45.662368+00	2025-07-05 08:53:45.662384+00
6a350882-43fb-4883-813a-1714359a893c	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	14:00:00	15:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-05 08:54:16.455669+00	2025-07-05 08:54:16.455717+00
ba2a0ed5-eb87-441d-a03c-1285724082f1	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	17:00:00	18:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-05 09:04:21.775657+00	2025-07-05 09:05:25.355563+00
b4ca9d4f-1c1c-41cb-82f6-94777b252ab2	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	18:00:00	19:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-05 09:14:33.564184+00	2025-07-05 09:15:36.046044+00
356383b0-ba03-4f4f-b24f-68ea53a8b91b	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	20:00:00	21:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-05 09:22:17.881523+00	2025-07-05 09:22:17.881544+00
58d210d9-9946-458c-82d4-c29527db5102	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	19:00:00	20:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-05 09:19:23.062898+00	2025-07-05 09:20:21.203803+00
4c4b0dce-b128-4aef-a127-f944f48c8939	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	21:00:00	22:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-05 09:23:39.381158+00	2025-07-05 09:23:39.381222+00
b65535cf-e14b-47b6-8785-0e3cf6e0013c	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	14:00:00	15:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	pending	Match privato	pending	2025-07-05 09:30:33.110644+00	2025-07-05 09:30:33.110684+00
dba23b11-1060-4c81-8c38-f8a4b968329e	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-07	16:00:00	17:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	cancelled	Match privato	failed	2025-07-05 09:02:57.296803+00	2025-07-05 09:33:30.67585+00
19dd0bc3-84a9-425f-ae85-27bbacde7e7f	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	15:00:00	16:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	cancelled	Match privato	cancelled	2025-07-05 09:38:48.727789+00	2025-07-05 09:38:58.911695+00
815b483a-18c3-4185-bf6a-f0db5a4dca60	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	16:00:00	17:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	cancelled	Match privato	cancelled	2025-07-05 09:40:06.651364+00	2025-07-05 09:40:13.594003+00
ed3165d6-9484-433b-80da-50c2a84fae8c	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	17:00:00	18:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-05 09:40:33.400374+00	2025-07-05 09:41:25.693217+00
ef719d20-d2e0-437b-bedf-0397978c59b5	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	18:00:00	19:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	cancelled	Match privato	cancelled	2025-07-06 09:58:31.235507+00	2025-07-06 09:58:40.164376+00
03603cf6-ecda-4356-8940-76840ac668de	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	18:00:00	19:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-06 09:58:51.757528+00	2025-07-06 09:59:59.112183+00
b341b1cb-5f9a-476f-9ac5-d69eaaf8608c	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	19:00:00	20:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	cancelled	Match privato	cancelled	2025-07-06 10:10:23.99759+00	2025-07-06 10:10:29.985457+00
0026c3d5-e018-4a66-a7d2-1fd56a5384d3	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	19:00:00	20:00:00	private	10	1	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-06 10:10:48.573323+00	2025-07-06 10:11:43.517559+00
f5631bfa-2b42-4acb-b127-4d7752350734	4a7b67e3-714c-4077-a691-ca8df3866262	60d0c593-d79a-4039-a69d-bed35c055e0f	2025-07-06	20:00:00	21:00:00	private	10	3	1	5	mixed	35.00	350.00	EUR	confirmed	Match privato	completed	2025-07-06 10:14:04.193894+00	2025-07-06 10:15:00.925094+00
\.


--
-- Data for Name: court_availability; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.court_availability (id, court_id, date, start_time, end_time, is_available, created_at) FROM stdin;
530f1a00-8b03-4402-b47b-ba9bb256354b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
09987c31-5cb9-4ac2-b18f-0edbd415064a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e049e159-12f8-4e12-9368-03aa73a47add	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
cd9d579e-a6c8-4c67-9c47-ea5dc4f39e4f	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
539beb31-c303-4cd3-89e5-fef0e5f60203	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
8c3d786c-5a78-42e5-9dd2-45346a15d49a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
db6a580d-8eb9-4241-baf0-f0b8e3354124	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
4845bccf-4620-47fd-9370-e2aa963219fc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
25613e13-8041-44a8-8e9c-d9cb251d14c2	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
eaed24fb-6483-4334-800a-4089e9621ec7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a0482139-5efa-44c8-bd18-9b4463e1b7cf	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
83c70784-150d-41ac-943c-245f419688b3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b5043d8a-8de5-424b-8a26-61bf8b12e271	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a51b290c-a7de-44e1-8d21-7772d630ecfa	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
367d868d-d154-40b6-9330-dd0d02b4842d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7d4b8a77-903b-4421-84cb-e6fbe1f6dec3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ec1297e9-61b1-4778-b470-d2374fd11d08	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5f85917d-f0bd-4800-9a13-fab0e6664fc3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d7cd9d5a-afe3-4239-98a4-5845b733e090	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
780bf59d-a71f-474d-a2a5-2bbdb80d3ecc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5d4643cd-7276-4f64-b7ba-9d5d6938e614	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
50c4b9b9-c703-44e6-8688-d5bcdc71f58e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4f39e2cf-1d10-444a-be2a-67bc4dbc1da3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
92208b50-b625-443b-81ea-691ec1513ff2	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4cbdf322-d245-44e8-aed4-3b1e2a67e8d1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3325dc44-72c6-4a0a-bd4d-793a2aa4f03e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ff1b8e9e-a357-42aa-86a6-bb98f042b635	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
199c206c-f190-47f2-9de5-1cd4c29f43ec	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f0552dcf-1b0e-4120-b507-ef942c3e1fa8	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
75f1f423-f02d-4b5f-ac90-68a716cc42be	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
fa6906d2-9c40-4e9f-bc86-4df10d1e4b13	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6c43faa9-b9d6-4eba-be4b-a525a8c640a7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8c35405e-2081-4863-935e-8e743102704f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
fe715c48-b4bd-4ff8-932c-cffb0d123a4f	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c8c991e3-4eca-4714-be35-f292f45c2fdc	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
67f8ca54-1491-4aa4-8cca-d52b639803a8	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
17cb6c51-80ab-4b5c-9d92-1e1db12b4e5b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
82b5476c-163f-4c8d-a787-22fae7292ddc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8b2cb1e1-22b7-465a-8cb0-576255b1c848	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f8607d35-9343-440a-a256-88fa39d8ef81	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d4307357-20f1-480b-84c7-b6af03f6484c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d8f144ed-301e-46dd-919b-ce7604b61502	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
76630f8e-c5a8-43c9-8c95-7c8fcf9d276b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a2aeec94-450c-4314-8128-5d3a1945b4c1	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
03c14885-8138-4942-84b2-7b4908cac171	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
fcacb57b-1002-4b0f-b85c-ce3feba7f200	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
e560abe2-ec12-4344-b95b-5908b6cc4510	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
55669e9b-8d8e-4492-bc39-b7341b9a5a1e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
9c18aae9-5c14-4f15-9aa6-5edd5fcb3773	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
489e8c6e-4592-46d8-ae1e-20cc407741a1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
bdcdc7f7-56ac-43b2-ab25-3f319e639b8a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
812a22a0-32ad-46af-998d-13afaaa5f1a0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b6173a9e-ce86-4fdd-b574-93f9fd18f4a8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6bda80f2-ae50-4b37-b9ba-50392ef2b2e8	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6ecc7182-2969-44d5-b13b-0de67399d6ab	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9ae4f871-90f7-45cf-ab1e-69d9b0fc8fd4	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b04c2386-50cd-4b8b-891d-33569dd1c3e0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
919047a7-6ba9-4dc2-996c-bc73ba362518	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c1c5b429-b867-4dbb-9ccc-38362ed3275e	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e8737d1f-7881-4b98-af74-3db589857a34	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
42e2eb08-58b7-4e71-b1e0-8ab4816e0b2a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
23366a9b-8ae6-491e-b1ac-b15fec7ab945	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
19a15d7a-a60f-44bf-8829-7dc4aae2230f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ac5f3076-590d-48a8-bbe1-153b9c8bc7d3	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
6b9c7fd5-60f6-4b9c-922e-405895a38d8e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
db238c78-0212-4247-a5ce-111db9d6478b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
69886c1f-9ba7-47c2-a643-25188011faee	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
42b8db3d-bb80-4dea-a5e2-b1e6b1d69115	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9fa8255c-4196-4c96-afe7-eeb8a10dc91a	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3e38e4e8-a9bb-4cb7-8b8d-7a73ef698164	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
dc78c67a-5881-492a-ac4c-5d8b96fd3b03	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e843e3cd-0eee-491e-8222-9c4f3b6e09a9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
66b78b69-c8b1-4be8-b7c6-039f5d493f51	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8ae3c4f5-f8e3-46bb-ac76-7e346f416fcb	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
12aa18f7-cbb3-4e86-98fd-1465b69948f4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
697a11ec-fea4-4c66-9c33-7b7f78f17287	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
175358b4-0767-49a7-94a6-ebb1b19be5b9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9da59ae3-f653-4e75-961c-a9ee15f0ac6f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
1c643a79-b489-4146-8284-58c1ebc6faf9	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
cd506fb3-f347-449f-81ed-b43c0d2b5ab0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f7ca1eb9-9a1f-4b19-8309-e05ac1771e73	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d2d3a649-7391-44f5-94d7-b3bef02fe30f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4757aed2-ae2a-470d-a2a9-7dcf7cc32562	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c358a989-89e0-4af6-9e33-c07172a28478	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1d57aca9-84b1-4a11-b2a3-d45bbfb21eec	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1b800952-c951-4698-9c1b-a056a7571315	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
962eb8ad-cfd0-413c-9812-bac1477cdeb8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
50a62021-ca2a-4176-8400-92b90df4ed1c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
46ec2576-4bdd-4357-95b5-40518337bd5f	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
9fbfb44c-9f1c-4608-97d1-e6ec2d9396c5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
50f9600f-b66b-4ba7-878d-cb2da0a300b3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7036ca17-cf75-4aa1-b55a-57d629d2c00f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8956888e-69cc-4586-bc40-8940d709d197	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5c37ce59-7a96-4c21-aba4-f397f6a03bf5	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
069e4468-3bc4-41ac-be67-c4ba1350f970	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
de5bcad9-5b28-402a-9214-20c9ec2f7bc7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
fe9fdcd4-4671-458c-9049-c8d2fe5af59f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d9f814d4-e9c2-432a-a626-48e4b125f8e0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
16c0036b-2d2a-4a20-81ea-359cbd8cb0a3	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
0ff115b4-609a-40af-bcc7-c6eb525bbfa9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
824d9787-5900-4a03-8b8f-4bbe37ff01c5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
7276c76c-de8f-404f-9e1a-f69823cdde86	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
42aa75bd-bf0d-4183-8887-34d4074b4e5b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3af8093a-6758-470c-b377-29a6bdad79d1	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c111f509-9abc-4740-8a4c-0a4099a1f120	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5eeca622-a6c2-44ea-ae56-ec0596d9c5c0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2ea3d5b4-717a-4486-bbe0-f7d5edbc6135	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
54316820-78db-40ab-b39e-8704a09e7bed	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
da574482-87b8-4a1a-86e0-eb0c3ff61e80	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
fdc24047-4432-4c64-9b18-006375f733ee	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3fb50ff5-37a6-4ad6-a52c-d2e20988cde3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0bfddca7-f47d-40c9-92cf-5e265850fa11	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0e7281a1-cccd-452e-afb5-2470d7997523	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
305af49a-dd03-426d-8a27-878a1230e297	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a35ac713-76a5-4835-83de-9cd7db399355	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5f03569e-8860-4a52-a4b2-e01c5224f15d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d73fffa1-f558-4def-8fc8-06fae7ccfd93	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d08e9f2e-7f2d-4693-8ead-2779f4fea465	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
597c4d78-cf69-4da5-a44c-316723f5f52a	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ea8b6f77-d907-4952-b040-ce269d46575c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
42cc1088-903b-492c-a5e8-6709b8d48125	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bf70179d-45f5-48e6-ba6e-5deb8645dc80	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
083b93b8-43ee-4569-8900-6b9a7cb0c402	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e656453f-045d-4a35-af40-9bd78104bc15	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8668e54d-5059-47d6-9db2-484159fcbe85	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0981f4e0-3a0d-4a4f-9cc6-7a0f4cab508e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
accc5386-8a33-4cf3-8e7d-7fdce2c404d8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
100d1f73-9a7f-4b5c-8dfe-c9dcb8dcf642	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e969e585-8781-4d50-88cb-84af56905fee	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
056fcb92-6474-4bf4-b10e-efb66ed3e2f0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6b89a009-5e45-4251-9d8a-41b9f77712de	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
acc75f20-4ff5-4a9b-8a69-5eb901990318	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
5911773a-20b9-47c5-83fe-07a23c5e7f3a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7f3aa43d-e8f4-48ac-8f2a-dec849e227d4	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c0f336fc-2a7d-4fe8-b8bc-8153cbf42f67	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
80d42dcf-5efc-46c8-b87a-f09f61b7e19f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
5eb8cece-2032-4fd4-b937-d502d6e82418	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e9774097-77df-4390-9451-6ad3bb513638	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b3dba0dc-4f14-4c2e-b36d-859b7c6f5d75	07771505-6c48-4181-a94a-80816e093af6	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
59a5f4c3-9ff0-4e65-812e-492796c6bd41	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e87f1bf7-70ea-4ea9-81c1-3f9bcb5ea0cd	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
edac7673-f297-4f15-8f63-63dd07fa439c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ab4b3b96-eea2-4750-a602-d397cc516eab	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
93b65141-0377-4fe8-98d6-386b3433ce47	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7e2d0456-d9fe-4453-9017-10dd0884816f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a8f218e3-ac4f-4e81-901d-8327dd2fa267	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
21605d46-b2c8-4a6a-a9d8-97289fb16f88	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
46b8def2-cdbb-4e04-8a39-8970cf7e5d3a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7602e6b0-5c54-4ca6-bdd4-e449b3de33b9	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0f7e099b-23c9-40bf-a550-5895d0807431	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0e7df6fd-120b-46eb-a8a0-ec91f0cad973	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7de68e04-ff7c-49f0-a3d8-3ae0386ce3cf	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
48a92418-a259-49dd-b514-104ca0fa10dc	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f5da4a4e-7f03-49de-898a-de390323ff31	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
52876bfc-6ab2-4630-a7bb-f70f81ff52c4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
bff89249-bb7a-44e5-b56e-747c109e2694	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
740d2d10-0d4b-4751-b771-34ffdf5cabe2	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
2935c42d-3b79-4948-b015-335da3c458cc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8b64b18b-d187-41bf-824e-cdb877fe6e4a	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3128c92c-1ba3-4dfc-92b8-0e085dd895ce	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ddb8bb31-7a81-41c1-b4ff-ee3aec3379c1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c5d4a47b-af76-48ba-b6a0-1afeaafce8b8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
22516231-416e-4bdf-a344-0100daf1c487	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
1d03ad01-07be-4251-ace6-2447f53bdec4	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3d14eded-5791-4bf3-b3c7-03f3eb22a0ba	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
939dc59d-b385-43bf-adf3-e6feabb11257	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4d196956-c455-48c1-8955-2fd647cc95b8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
56ecb429-7bb1-4315-9314-765f1cf40ade	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
766c7f85-49c7-4962-8f7c-5f57b29db051	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
657f62c4-be68-422e-bcca-8574cfe457fc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
eb6694b8-d94a-40a0-8691-dedd7479e8bc	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
ad6adb74-d81d-467d-b04b-ea423b3fcc87	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6f305c83-78f0-46b2-917a-f370e9a68976	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2b99a134-a12b-4543-b990-66fac99feb0d	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
84764413-6637-4db7-bf1e-778e5aed3275	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
65252d44-ae29-4472-8b20-11a2515a4aac	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7245ee85-082b-4737-9e75-19b52ffed595	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b92ec1bb-1967-42a7-8e61-8fbf14c1d7a9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9d7773e1-ea86-4fad-b6fa-960654128cb7	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b760d62e-ef2b-4762-b605-3a725247e404	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
67f199d8-830d-446e-8b54-c767b1fcea1e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d5327260-0aa1-48f7-ba4f-175c283761a8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d77b4ca4-62bc-43a5-a587-7e2ea1c53187	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
be173d88-bcbe-4be5-aed4-19c4273918a9	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3e06d802-69a8-492c-8d55-6df7e299d6f6	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
229fa074-5aae-412a-b700-fc705144649e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b7a0aa1b-3ba6-4312-a89b-e9208eadb34b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f830719c-74a8-46a5-a1ee-c786ef83fc89	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
67309909-7262-4bb4-ace7-49f2f20493ed	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3e606e4a-1fdf-4892-a4d2-0a60f3fc7b0b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
62f28d36-80aa-4f08-b6f5-5388c3b4fbd5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
06634545-9ca7-46cf-9062-df379f4a953d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7196a742-19e2-412b-8d52-418b02e6fb6c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
994537ff-1861-4f66-9624-90c11e6ece91	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9aca64c5-d76d-41dc-bd98-a28261d7a15d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1b1179e8-9fdb-410f-b021-5431f3e47e89	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
48c87734-80a6-4e38-a587-b0880169eff2	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
77345fd6-89af-4e44-823d-e5e64950bf0e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
4d8c5f93-4ea2-44de-9f73-811f169943fa	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
f3a63eba-6735-4d1c-85d1-c8d3dfdf97d2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
36ef6d16-5bfb-4c6a-9667-72087967a899	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
0834d7a4-0247-448e-b54c-787ff3f081f7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e980ad30-55ac-4ea3-bd20-f036441d215d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
953413b1-c915-4fb7-8811-2e20c6dbefbe	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
677b9bb0-e1e7-485c-892f-11d7b47b4e9c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
8ea1e8a3-84a4-4fa9-961f-6bca3f9237ca	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
cbbf95a7-0148-4673-ab3e-06beaadee8d4	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c7ced3d9-82dc-4b13-ba95-5bf5553c602d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
dd72acaa-d454-41dc-8625-3997c9a3df5e	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c3a35428-2362-464d-b240-5d2c760a2973	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a1a6fb19-6521-427d-86f3-1e3ef3111141	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f684efd1-834e-44a3-a817-a9df7435370e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
07309e2b-b512-4749-8959-b9d20f435564	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f95d5445-4481-41db-bd28-45290a318263	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
fd3521e8-bb13-46c9-912e-e45f46587c5e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c90f4966-1445-4999-a3ba-7bafeb6c065f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
48776a9b-7369-4426-b2eb-1263ddd504ab	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8513da78-4294-4ae6-aae1-fb48734b8cfe	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
1c854b72-d007-45fe-87d8-fec3971162c1	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
d3ec12b9-2bb5-46d8-896d-7da5d940a5b3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
1d3004db-2ac4-45ec-b09c-b5060f9d2689	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
317000a4-8fd2-487d-849d-0e74a7dac95f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0af8cea9-03d0-4fa5-ae30-36b88e281fa9	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c758391a-ccfc-4315-a747-90d51ca5e152	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1b7cb8ea-9835-498f-b7fe-968d78093156	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ae1fd022-a926-4db4-80fb-54291c3ca805	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b43f0e98-6f33-4329-9c1c-9a7802803a0d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
11f7bb75-41f1-4a42-9ff3-051b4c8121e3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
76c7d0e8-0914-462b-a264-5a64947e3c6d	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
54d5a0e5-66de-4e8b-9dbe-c550201ea69e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
52b142d8-5bc1-4824-8ad2-7225e2fea095	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
de3792d8-4068-47fd-907d-65097ca9e0cc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
bb23e5a6-7d31-4ac8-baee-0f8922165fde	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f9e2b602-db29-4651-9ea5-b5c8097aac73	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4da34274-d96a-4a9a-8de1-98043a06e755	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
aeff0d29-63af-4419-9f1d-2879581221c4	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d191f939-b295-469c-a86b-e898a9c4a8d1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9c0956af-1e1e-4f43-b797-683346adfbc6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
bcdbd460-db67-4bb0-91f9-af0484313d40	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a1a5c670-a1e0-4b84-9389-c4541c382004	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b6ed76c0-90ee-4ae3-8904-3903328d1dfe	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
01d681e7-bc60-4b23-b3d6-a4601ef2c551	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f5c9a824-5bb1-4bcf-91f9-0cf343921d35	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
843ab02b-d9ae-4fd8-ae99-cb5f2312444a	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
527248a5-e9b0-41e9-9217-7bf74c39cbd1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c9678c04-96c0-4f4f-8955-8dfab0591c48	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
276e816a-29d3-44f0-bed6-aaae2f304263	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
af82e235-578c-4394-9725-492a049dbc83	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
4e8b0263-09a3-4044-b4ca-610f635a6e68	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
dd636863-4398-4aa4-a8ee-198272664f4f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
118deb4b-eae6-4210-9a67-82bd948022c5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
119f180e-71b8-4662-9eb0-4c8cfe416d4f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a936ea51-6bd7-4a68-b31c-24c7010f8aab	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a2caeaa6-6fee-4d7a-87a1-9f522c6783d4	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d302bb51-931e-4467-a170-f39627956f8e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
df252586-dd35-499b-87bc-beb3991692c8	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ce5a2090-7fa2-4bc6-b9c6-1c351d1d5a69	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
8a1bc278-2f13-4d42-8413-b669f3e9f41e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7a21576c-9ffa-49cc-8bc9-77ec019e0da5	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
dfdf5d57-6f2b-4516-98d7-8862c1b208e2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
714ae2cf-1c98-4e4f-a74c-8d2ed05c13ba	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e3817e92-2c7c-41eb-960d-bf0e4cdd3897	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
c5c11766-06d3-4e2b-a012-2e227fd9d37d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ceb13bda-07c7-4bf2-8682-3d2c3c805224	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
edafe02f-1a4e-4303-9735-09309d0ae515	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9ffd5753-f9a2-4132-931c-0928f2006ac1	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
d03156df-9e56-4ebf-acc0-591df4f77be7	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
57444274-f465-4d40-9a51-e5bc84ede67b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b53e709b-8cfc-46d2-b2e1-a0ecffd4479c	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
c7a6844a-a185-4bb7-a912-0262d589e059	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
232805c4-9335-4f13-8416-a2454824d311	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6e93f29c-046a-4157-9e82-44305ac2c88a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
068b61a5-d584-4246-bd32-8bfa57f85d09	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
1b679e22-47d6-40a0-8c9c-5427e302c87b	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
9fc57263-bf2b-4658-a87f-eec8d907e5b1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
96a979a1-8f30-4b21-a58b-70da026ea7b3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
5569cef5-a7bd-4770-9fd9-8932e0a2b851	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e48f0b15-13ab-44de-a63a-487c726065af	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
81b49e05-d9a0-447c-a157-8ef98d7a00ce	07771505-6c48-4181-a94a-80816e093af6	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
28bc742b-341a-47fa-aea0-db05dc119411	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-27	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
73213ef2-e076-4a9c-9b99-7ecbe00ca670	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ba1f24bb-4fe6-4cda-9a00-fd92bdcb28b2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
792148ce-3e83-46cc-a5f2-5a9be8cb613d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
05833838-443b-473c-a3da-0d5c1697f173	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f7efc333-7f36-4e1b-aaf8-755c326f0c17	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ffce19d0-005a-48dd-af3a-7a2c151252de	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f2297f17-d5f8-4dc5-8c20-4ff105fb2b71	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d18a050e-3eef-4209-8a1c-152788e4c168	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
fdf14c22-389e-41fe-bbb8-97dae5d2a42b	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
de413f09-4426-4a22-a85a-1424e95ed67e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
50c829a4-119c-4e2b-93f5-27f50e282d46	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a4e1e90b-d71a-449f-80ad-03861f809b61	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
68f18546-8436-43db-90fe-c227e1b1a2c0	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
352417c5-8b25-4e88-9c9c-a2bd0eb775f7	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
57bdcb32-0da3-4cb7-b9ec-8ae5206a864b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c3654160-cd39-40e5-92ea-e5df42cfbfb6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
37a482e2-7ae4-4fb0-affb-5288ec891e6e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c472e97b-2bb4-4740-ba5d-c2a2b541370c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ee7b5989-f998-44d3-b650-318cab4f7892	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
0b6ef2bb-0186-4d7e-9b9c-0ed1e134daa4	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5a77223d-a1a9-4a9d-b147-b09d1ac8c7ce	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
759b259b-d05d-4a66-ae8e-9e124d9766a2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9a41f826-e300-4439-b8a8-5fe234101d47	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
35db862f-bd1d-4c23-902c-c15c145da245	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
158611cf-c9c1-458e-be1e-29fba90f4903	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2eceb0e4-da84-44f3-bbc9-ff5d6778adf3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8cdec364-a24d-4dec-a826-1a74a8174216	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
fdff11ad-4cf6-4c32-937a-d58fb9746e41	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
bdf099d2-113d-4e0c-ae72-38a6f2073d01	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0ab6711a-7e97-4c7b-b535-48ba9adefa02	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3c2c1926-2cb7-4807-ad34-1acd626c96e3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e54093ea-e737-4d15-bb20-3e533aa951a0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f64dd9dc-5aa8-4886-93ff-02aad9690d66	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
612a781d-dc24-4414-90e9-b298c1c44ca1	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1500b71a-3396-40c5-8853-54083228d6a0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0ada4b52-a116-4bf0-acf3-109ffcba6b66	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
dd24d7e3-a375-45e5-89f3-b4aa21a9011a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2c4fdb6d-ca2c-44fa-89c4-3c01a95e2de7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
ddb34d6f-8cc8-4642-b8e8-87b4120c1db5	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
967bf9de-8344-40a1-b17a-a4b4eaeccfcd	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
5b93c962-2b7f-46b9-b182-75dcee90248c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6c2ab762-4dc3-4c45-b9a5-aed74b8eeba9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6b298a69-eaf2-4657-ac8c-acd06f5642f7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b9216992-dc65-4294-aed1-d77a6277250a	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
e913d62e-f724-456d-873b-d77942fbe5e9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c5910791-a480-44f2-a943-6ab5ab0ee265	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
78b40133-befc-4ce2-90c8-97a9002bdb21	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
bb408b1c-da7a-4da9-a90c-60665e2853a4	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
93cb9e76-a5df-4d86-ab3a-9870436a247a	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d141ee78-d740-4b59-a67e-1830f327c528	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b54761a5-84a5-4c38-b03f-257d575fced1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
34bc13f4-fda7-4f82-bf21-faec493493c2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e46e73c0-8c7f-4f15-963c-b6c77060a188	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1c15f02a-fe12-400d-a366-fad852670066	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
33fcf470-f5b9-45af-a1c0-2957e9114cd1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
10b29b70-5c65-4075-8793-a02c85affb7b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b5f45e64-4345-44af-8df7-5c67732e1539	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2bb3bd15-26a5-4797-b7b7-b66af67df37a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7f6f0c20-4d96-4a6c-9153-a30407126294	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8f6c4f27-12fa-425e-90f3-3e18c27c3457	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1e371f08-e337-4fc3-b2de-2ae0bdc129b7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
bde714d2-0d5e-4a6f-b3e3-3f19ae68a0a8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b4be5c2a-641c-48a9-80a1-d8e02edcc371	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
51be44d4-c147-43e1-aee5-83a3dbeb53c7	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
fe2ad477-25b1-4cab-9a33-69bc4919cf41	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
911cc23f-ebdd-4db0-bd13-20cfb12bc655	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
34c1eb75-3f0c-4ce2-af52-561a26c40299	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
61c28d50-b4de-4eb7-8ee4-ba60035cd83f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a15d914d-9ba2-4454-8c31-2bbbd06ebfdf	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
87cea911-59f3-4757-9c1a-0413eda32c2f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9c11648a-ea3e-488c-ba88-cb5713b1b0b6	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
0b4366ac-4d96-4e8f-9ff8-eec5c794c574	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f42892c6-be51-41ad-85a2-5cfa43c9b788	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
fce7900d-4e50-48bf-8ee9-91cab5a0bb67	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6c9983a2-f5c8-4f90-8ef6-349e641a8735	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
b2c7d266-24e9-47ee-a3a8-03bdad711081	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
d9017315-4ec6-4abf-b880-86815aabeeb7	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
15831381-4f3c-4325-b7ae-e32a00e8224a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
14dda247-5c83-4b0c-a030-b544836776ed	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7db04ab1-fc9d-4182-be5b-97f69c7cddc7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
547571e4-b9b8-4d6b-8b65-8b7f8b2cedf2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a8ad1356-3112-4fc3-b29c-ebafdb6961ac	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
325bfbef-95f0-4c89-b854-55b0d0d6ca13	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
2589b36c-2afc-46db-a320-034881e3b0d9	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
cfe2e119-8973-47ab-aad9-8a08a781ef89	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
43e0bdbe-72a0-41d0-82b2-4ee6fdaa5df3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1e305092-6061-43ec-abb5-8374a56e7b0c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0f609b0b-4182-4c8c-82fd-4d08985044e2	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
343f303f-bbeb-46ed-a8e7-818856913d36	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
9c916372-1bb4-441c-9fef-d4d7855027cc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
41e63597-3550-46fa-a859-078580d3609b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c0b5e622-df6f-4dae-830a-4777ca793fde	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ea0be201-07b5-4a17-b0b3-fc9a36d1ebe6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
558347a7-3edd-4edc-9a97-813920bb59ac	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8ec2f7e6-5a6c-41b2-a3a7-ebaff936c981	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
0a201f58-6893-4e40-9600-53fe8d0c787d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3afcd6ea-cccd-40b2-b44c-ef373f9b94ed	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f931c4f6-2765-4501-ac66-4d458345c8fe	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9b78fc8d-744c-4407-a085-894f6bbc7e75	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a72085fd-833a-43b1-82dc-12044478cb71	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4991d82c-5f58-46b4-bb81-9d0c1ab06706	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
8e3e96b0-4183-4a78-8fba-7892d82862de	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b95e9df1-80bb-4334-9e98-3921c82cfe22	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f38fd7e9-1bd7-49d8-99ae-df7675cd5e42	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
1124cda0-95a7-4b22-816b-7bbc7437b54f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
48ea4432-3386-4e54-b452-6b1247c73476	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
8737b531-beb5-4884-b78c-08b38919050b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a49effff-a2ab-47be-82ed-2643d26333f5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
97020116-ff76-477a-b604-d8afd3ae1561	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
524920f1-187d-4185-833e-e3dab4700d96	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c3e66212-30ed-4dca-b849-1f47c44def57	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d81c07fe-dd93-4f0f-9949-6b4202bfb512	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e1a83b02-8902-418c-8488-fe3c98ea9060	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
971db74d-ed2b-474f-997d-8f3f0898f43b	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
501008d4-87cb-417f-9e64-dab0dfad9114	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ca63ab50-5154-4454-ae3a-32aba9e92ffa	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
c3c7ef35-9a47-40b3-b273-301dae3f1e48	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7f73f4c3-0455-419d-b6bd-77a212c28e69	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4732f4ff-4059-4322-ab05-24944d697da5	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
35906998-3725-4e12-8f0d-b9c6def40197	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9d7c7463-69de-40ca-96cc-3be1f726cdbf	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
1689bb95-2176-4a88-a105-1c0e5b95a340	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b05ac29c-c5aa-4874-bd3e-03591e1c5162	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a843f0ef-9496-46ad-81f6-175d21de886c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b1eeceb2-852d-454f-9e0a-ed89f75aca1b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4a92e772-fe10-406d-8378-6b73592c40c8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f48715a0-4819-4005-a9c3-e8b5d601a939	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6b98b23f-8b13-444a-b30a-f3e8ffe6352d	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
197bf0ad-882f-41d0-aa8f-b3ec1cec0f67	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0443dbef-b097-4291-9716-02a7b7cd0ca7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
1585a7eb-f1f4-43e0-b10c-873b8f55943e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
618b63a8-f7d9-4ca3-b23f-c6c7f23f54cd	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b656bdf8-b48a-41c8-a3c9-e8bb0f6c3a23	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ac103299-ef11-4fc0-ab9a-da70c22f6d52	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
01effff1-c971-4471-a1ec-9d6ad6338436	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
68b9c30d-416a-4fd6-861b-355e6c6808e1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c4659b18-a839-4a71-ba28-5831365d3c1b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
9d81a657-9a16-409c-983d-235cf2bf4c57	07771505-6c48-4181-a94a-80816e093af6	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0bdbdaa3-135b-4c3f-a6ae-6d9c887d21b4	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-28	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a88c7dbe-f3b6-494b-9dce-cae8c54e273e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
05f07bb4-6e06-4884-a82c-3cafcbef62a5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
474f3381-695b-4e3e-b976-4d24632d3629	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
efc6c8bc-7f57-4c71-b8fe-04b64af5397c	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
062f807b-0077-4507-9777-a9c05d5d2fdb	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c0aa63cf-671e-42a0-8e9c-4ea8431499db	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
42382744-eb2c-451d-bc07-1206236457ae	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c4354b77-1f98-4459-b0b0-1de15af5104b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
3adecfac-d5e9-4314-9c58-1506ad7ecdb7	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d51fa8b5-630f-4567-8de4-3fcd4fd7a798	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
8126d621-e4a0-47c6-9557-fdc5905817ae	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
657750c3-a879-49b0-853a-ed6594f66ed1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
757caae7-49d7-4d17-aa68-64c40654e13e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5e611e9a-1f28-487c-bcea-f7ee0df94f0d	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
fcd800c0-9260-4bf8-b142-3ef14abd766a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3650d3cb-eb19-43b1-89be-72727b91293b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3fecbfe7-0d79-4125-868a-6b7dad1a971c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
6a089192-2d6e-4ac4-8b08-fcf126820626	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a46f242c-b973-478e-9ed9-609ff70b12bd	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
93da45a7-12d9-41c6-8609-63de0aace37a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d00070a3-5531-4f79-a2ca-3a6504692ab5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9bc7a5f6-7a1d-4fdd-aecd-762ce44317a2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
fe5ffb3e-d3cd-457a-9b2e-8d1aedda8735	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
34cb5870-174a-4d4d-abf2-4cf69e327236	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
79adb84b-43a6-48b9-b647-23211b4f5b7b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
20438876-fdd2-4039-a213-b1eb8bcbe3f2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a4e8a61e-e942-4aab-8a27-8e280715757d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9fad00e0-2f22-46af-a43c-f007c4510a90	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ff95057d-eeb4-4391-9403-5a83bc85edfe	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9bf82bc1-0a1d-4901-bbf1-20a969973159	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
82e73233-06c5-4283-9ab5-7525969c07da	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9afd800e-afd2-4709-b56e-2f0e3a649985	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b6c6e708-12d5-4a7c-9c34-b05cc2962425	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
298c87ac-d00f-4e9a-918a-9006cae9f062	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
a673fd1e-f555-4b19-8a54-9107f3fed65d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c4ddf7ca-056f-450e-95e7-ae72b4b00498	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
12b44637-c5c3-41d7-80b2-e487a81ecc4f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
ced0e5b2-b383-4d3e-be09-415a154475cd	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
86d390f6-82c8-4198-95a3-836126545288	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f1082621-cefe-4b03-9283-044f5d3873ba	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6d59bd19-08ea-442c-a178-c28f7d735ec7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3522338f-c4d3-4f3c-a6fb-60b10e04c11d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7600d0b0-e180-4c25-8ba1-75be77fc981c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7286e895-5585-40c0-8d33-d051dd9d0423	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ee62394a-f4c7-43dd-b180-88fd695421d3	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
eca3651a-1067-46fc-93f8-c88f6fbba334	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b19bc456-278c-4cb6-88d8-16d05da03665	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
de894b28-a4cf-427e-8239-d459e6e64871	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a1e864b7-d572-4f1c-a17f-d7d59d28d12c	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
43be0dd1-a2e9-4a19-8cbc-874f43d2653a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
084d86a0-c9c2-47a8-8111-28125a0b3846	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
fac5eb01-932f-414d-a729-36eae55db2fd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c493a67b-2f27-4201-a18c-bd636928a8a2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e479ea3a-fc17-4b98-ae0e-a930177dee3e	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
14d9a5f5-dc12-4e61-a79b-6e3ea639083e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8055ebc8-1cc0-41af-a542-517e000dd9c0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
22c1a43b-bee7-4461-8c29-45e981779414	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
afec9c7b-3c0d-4c70-920e-0d4fb5ebdbd6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b9361299-f3d1-42e7-b12e-c7a6a97bb58b	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2c80f02b-2a09-4974-9ca9-a2843d6a7f05	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0bd93b54-5b09-44b9-862b-e82e306352e3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a6699c3c-feeb-4601-b3f3-884e7db4faae	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e1d492cd-1e56-4dcc-875c-db973ae870b0	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b8532cf1-8064-47b5-8245-2eea6d4ae767	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
37703c03-0c5a-4351-bf6c-c75e79ef445d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3a3f3bd8-824a-4fd6-83e6-89475db9cdab	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5263f015-f803-4e24-be77-1dc2fc105f41	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
38a44b70-a072-408c-be74-ced8e4f92ed1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
068b0d9f-bfbf-4f2e-905b-989ba761f8e0	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
91deb31c-1c4e-4385-b781-24dab011eef1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
804f940f-7391-4217-98c6-ba455c296d48	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4f87d1ad-32f1-42af-a742-64d56621e084	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
b381f8c6-fe65-487f-969d-84b8019646b2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
edbcbd37-e74c-471d-b597-e4f8bc39ae94	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e9d07e23-be21-4001-b631-dcf09d14acd3	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
cabc502c-b45a-401d-8226-deb06d2e283d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a0087405-cb7b-4bbd-a674-471b6cd1909a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ae1a174a-b887-4988-a0d2-bc6a7bd950dc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6d566cea-8786-42a2-a459-3183cb2e0069	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
abd809c6-a44a-4f74-8e14-e9bf398f145f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2b1fd4fb-855c-4e10-a795-671550221fe8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
05df26d3-aab6-4825-994c-a81f899e6f51	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
30f57d60-7d32-45c9-a6b7-3d3d8ac0701b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f4cb9a63-95f1-4bba-9d87-147a76167519	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
54595b03-291b-4f62-8afd-5926658f445f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
5ec99c2b-179c-4b0c-89f2-facf5db73fdf	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a309501a-c9d4-4242-bdbe-e380efc24bba	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
de1670fc-b4c5-4cd8-a428-681ef203adea	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
648f2741-773e-4956-a9df-cd4ee5b59cc6	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ac0bf694-6a4d-4823-a11a-189799c41457	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
9ceee3f1-3e73-48df-8a3f-538ae2e4bfbc	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9d7d92ae-47ac-4b5c-8fca-7ff9d1b83e48	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
641324bf-4b74-4df1-ae08-ed08f9434a14	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
fdc23a4a-c474-4897-98c6-f4b50a38abfa	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9bc00b5d-4a84-40df-aa04-70c39c8981ba	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
148c7804-3c38-47c5-9b13-a765d0450eaa	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a5c1f9fa-e4f0-4935-8b05-7d58f38a3a28	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
0616102f-65ca-4efc-831f-1545f86e68be	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
254e3e7c-5f57-4965-bead-59c0e0e4a216	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e2d43651-0e0f-4375-9e3d-d7713f404b4f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
170c8845-e97c-4e99-b7a3-6e0ccf18104e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
8c2c4d7e-3894-4a05-aae0-985e0f0a37c2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5b07ee89-c499-435f-a372-87870181642b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c823982a-543a-44f9-8797-1f8cfe6c62e7	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5ad55200-b4a3-4b62-bc0d-270f6a7dc3a4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
dd583697-3206-43ab-b4e4-b06bbac88385	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
150262e3-43ac-4dd6-ad5e-998caa6d1ff0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e5996513-23bc-499c-a57a-02e0bd40c4bf	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
59464b03-33ab-41d9-b2a3-40032d9e2f3a	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2085c30c-0954-4e1a-a826-0dd5ac87a1a7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c413013a-5a7c-4ac6-a113-2875e316ccf7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0c510c6b-b85c-4129-b485-df0536d4601a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
30e72353-7f9e-43d1-83d8-1e7ff3716bde	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ac2eb20a-3161-4ad7-9c1f-b827edfe0df9	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
fdf2ea2d-8c36-4f89-ade6-94090b033502	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
6311e66b-6822-47fd-a5e9-33e735ca0206	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
683326e1-532a-4881-a14c-a8d4b153c877	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
f9d74a5a-094e-4ad3-b72a-7e92ae7810ce	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
47668e86-b8f3-4422-a833-3b49f71701ff	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e3e2f1bd-0824-49e4-9889-85ae391eaa1c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
10d795fc-3009-4488-b997-2ef2781c94f2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a4ad8418-2f6b-455c-8d6b-4a6bcfa591ee	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ebb9dc56-e005-453c-8a76-256ffcd91bea	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8caf4f66-a7b4-46ce-a749-b593864b0c0d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8074ac0a-57d7-4428-8ec9-8a0d80af70b3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e4a6e6c4-4e81-4923-83ec-d2f5626a2edb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
68bf4e31-05d3-49d0-97f5-26bea80dfa20	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
81b912ad-993e-410c-86af-619b91edd140	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
79f513cd-6d2d-468b-be99-c23f08d219b4	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0f7af6de-cd0e-4e85-b2af-1142c5363131	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
01e8950c-0b3d-42ff-8734-9a5740f6411c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
884c76ee-8395-48dd-83ef-4d848c8b5297	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
65bdc252-60c7-4b93-9e90-8ba455042657	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6c2dbd00-5381-40fa-ba06-c33cefb6fa50	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
561b49db-bfd8-44f3-ad45-fe897ccc32d1	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d313b75a-383a-4689-9bcc-b0f1be726bc5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a5776d43-0c3a-4bfe-97cf-0d1259916863	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
5d7f55e1-9b9e-4e72-a710-5a6a8eb51bf4	07771505-6c48-4181-a94a-80816e093af6	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
aa33ff96-08ab-4647-bd54-95188ffe3538	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-29	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
abdf9aef-0e5f-471b-9f00-23f8c9be4e48	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b544e0b7-a9ae-43bc-b464-6e3be75d66e4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
48332587-3871-46b6-bb0e-d7c168c74e27	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
43336be9-5e6e-42fc-b7a6-9b1c52eba3fb	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
54387869-5824-49bc-aae5-376048dedda2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
9664d1cc-d512-4061-8760-86b25b6d40d8	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
06ad4837-1cc7-461d-a319-8b91468a64d9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1d2f93c2-fedb-49ec-9781-0d5d74437d8d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0cbd69c2-c86a-4b74-aa81-fbe10ed37199	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
4aad2eaa-40a8-4ac5-9944-2b800122f2f4	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
98285327-9d48-48b5-8d67-6275693d62f2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7364bdd0-2c1f-40c6-8052-78034da46cad	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d7065f50-26cc-4898-aa09-c355198e60ae	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d880cafc-1c56-49a7-b519-19b59888bf3d	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8cd939d2-007e-4d5f-94c3-61bc4724cb2d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
472fdddc-79d1-4eab-825e-e9533d5d4248	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
856532ba-c693-44d7-b3ae-c7f7fee9c51f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
391a5276-f8ea-41e5-8368-966f667e06dd	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
218fadc1-a2e1-4af5-bf3b-74f0df038b38	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
aa1a78ac-68bf-4802-a8b2-8b377a757dca	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
1cb534a7-2a61-40a9-af25-da6356545e72	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
118327b5-464c-4507-9c4a-e380adb540a0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6a6944b8-ed6f-498a-b7ed-382ee2dd5858	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
bd69b1f1-45fd-41ce-a447-b1e3fa5c07e4	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
7a6c075b-8e88-40ad-979e-34c2afe8f819	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
90bb356d-2be7-47aa-943a-06078a1cdd24	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
1cfe6cfa-2259-488a-8e6f-85981416d475	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e86a0f6d-1532-44af-93f5-53300ec2b879	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2f8a89c4-74e1-454b-ae8e-6ec39d817bc3	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
95114b8e-f2d5-4085-bdc5-3e001358dcaf	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0d96d08e-9313-49eb-83e5-ed3cdbccf9f2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7dea1986-83fd-48cd-a692-cd1fa8be5537	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
512bd346-4248-41c7-9694-cbf7b5d16656	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
cd045834-01c8-4afc-8988-d46c7d8fa44b	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
23e36c4d-bdfc-437d-a865-c0e3d8987295	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
029dcb8e-f37a-4094-acfd-6aa21585b1bd	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
bbe8ece1-3a80-47fc-9689-c3f606c607d7	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c7187810-1211-4653-8add-176c7a937278	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d4ba36d8-dd92-438a-b7f4-47c3d060bbdf	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f51c2edc-bbeb-40d5-9de9-7823df22b51d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
deef780e-620f-440c-a3f4-bf3b40d92909	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0d1ab850-41b4-4a25-9102-62307dd7946b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
e7cd2611-9369-4c42-af0b-67bd0ff3e982	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
db1e3873-4642-40ac-b881-e52894a46d75	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7408f9a1-371b-4798-9860-d0d132c64d3e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f95778da-5915-4bb0-bf1d-103c62680a44	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
93eb409b-76bb-43ab-9079-885610a29a85	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
540a9e89-284a-4457-9a12-4610b310f7d8	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7b2c2bee-9fcb-46a4-8b45-b3ae8f9eb4fe	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ffb27b61-03bc-417a-9133-1d67e4a4530f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3f659a5b-b14c-4315-9918-7760d2fca8ef	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6f03af27-8cb5-4fc4-992a-744cd43108c1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
5b34237b-f115-4997-8af6-9efbeb50c5a6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
3527a7b3-6255-4e7c-a542-1686401634fe	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0c03ec30-2a1a-4dda-b9bd-1cf9828e4c0d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
4aab559c-0167-4474-9c1a-c6ae6c070601	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
54b6e3e1-e736-431a-b21c-df0ef6f7a82a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9f460d16-e4ba-4271-ac8f-efd0b18a5eb7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6209e144-7e8a-4cb6-980d-1bcfe31cc902	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
4f95e3f7-cad0-4647-a73b-e67f5362a32f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6577b5e1-f070-43ba-b682-0de06dfae9e2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
135b1329-84ba-41b0-a9c1-5a9a50b9808e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e7e5a0b0-bcd2-46c9-ac78-b6fd1f69d6d2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
39ca5dc9-8ef0-4e5e-b88e-b15df95cd86c	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e4c05b56-71be-4823-9473-484ab949b7a1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2064b40a-53d6-4cfe-8c29-327ef62d5155	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
fcff041b-22b4-427c-b2bd-65d68906688f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
945619e8-5f99-4c9c-a941-236ee8bad1b2	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
35ead23f-3bcd-468d-b627-66f3ab736c05	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5539ca31-8bcc-4fcc-8d0e-178176cde088	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
703ab00c-d3fc-4b75-b1e1-97cc1832a39a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
04d0b6bf-8921-482f-bca4-40df473f13ad	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c18fdb31-b0e3-48ea-9ac0-dcd1af03ecc7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
41995c7c-309b-4b7b-9d58-64b5fd98c668	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8c5d3bb3-9e34-45c0-92cc-7d8c5957318b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
19e17b55-37e7-4e07-ac89-2a7a0e387b1a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
075c81a1-4703-4419-a8c6-df7954105f74	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
1c7a4aca-8438-4d96-b040-5fb7a1c738e0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
469d8b64-3275-496f-b886-84c2b0a9f3b4	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
3453d7ae-6493-4767-a4b7-aac3db2955d6	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
97cd65ac-845e-48e0-8cd8-56c4e9011d61	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
2535b4cf-7eea-4ce0-b9a7-02ab51b22282	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a0125bc6-28a5-4ca4-ba9f-0d773a25bcfb	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
6957e94f-0913-42d4-bac6-b87390f91759	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
cf47e25c-6d76-4484-951b-2053e2ffcbf9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
444b21f1-0352-486b-9762-47639cf0b639	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e4026fc7-2780-4f2b-8935-270f02e30222	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
06f1b035-f624-470e-b463-43b23e63a945	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
3de366a2-2d59-499b-add8-b2585a0ffa39	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
16d86314-622c-4269-8a94-75b5b39743ea	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
945b616c-3d64-4839-8446-802fd82a9fd2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
693ed814-8563-495c-92b0-ff362b3db2fd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1d11f9c3-a0e0-4554-9083-8a6e26cc0b18	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
21e8bcd2-86c2-45e2-9b5d-d66d3076a9f7	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
53e58e4b-1019-41a4-8dbd-be951733350f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
dfe711ef-53f5-49ba-af87-73c861f37e7e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7567014f-84ef-4f39-9787-c3f96cf79fdd	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
de0d8fb3-60d7-4078-bc59-7b7752f56de6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9f6626f9-1ccf-4be9-9d7c-3c55c15c817e	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
0d4a292b-4cf6-4e0c-8c9b-9e42d135c436	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
13166c7f-21dd-406b-8ebd-6ca5e5507b98	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
de42ca8b-e622-4529-b07c-3152126a7123	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a44c868c-df10-49d5-af98-8fffd6ac089b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a26dd60b-3e07-4569-9083-2469599ddbe7	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3ee1b686-6747-4727-bbc8-3d33d93ca8f2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c1b28e42-f29f-44b4-b8ce-51d9f9ed2967	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
09eeed5b-2ef3-4106-aadf-c63477e259b5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
bf63e310-43ac-4c8f-8b14-e205deca1167	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c0c3e78b-7a8b-4e7d-851b-3f140f90e8e8	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
88c8c684-2017-4f24-884e-5690d5e628f8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
99899477-8035-453a-88d8-57cc66160d42	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9679ee24-2d21-4b60-bc5c-0f1562e27012	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
27e015f0-481a-4e7d-af2b-5fb16d476ea6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ad8f91a8-5daf-47c3-8fdb-0c9ee1064b9e	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b6a41a34-d9f1-4ac1-a4d8-84f7f126ac59	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
8ff546d5-bee0-40d1-a7a1-67c5e959d811	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4ad41ead-7e9d-4853-8dc7-3b3a948abcf5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
38a5cd88-7aa4-46a4-a54a-29f49b7bd79d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
117ce81f-2564-4d06-b0ab-529b07eb32ce	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
09d9e9dd-909c-4608-a547-0f7fe48e23dc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e22aafef-a22c-42c2-a9d2-2fbc7b3ccb25	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b8a83e6b-3a45-452b-bf07-ad6f15d681dc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b2cabf40-e31a-4236-8741-16ddc3dea515	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f8b0afb4-9fa2-460d-871b-b9051222e33a	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9f361a50-9cc6-4867-b68f-c421167b9370	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a8c2a4c1-7594-4f55-a188-58466af18368	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
452dd72f-10e3-40b1-bf66-def4b15a8a44	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f69ea7dc-83d5-470c-ad5b-25a4c865bb2b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4b07af82-3532-4cbf-ab01-9b2e6ba7282e	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
eeb896b7-925d-4256-91a5-c83beb99cf44	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3a1ed5f1-791e-4980-9b47-0ffea8c25417	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d58a9663-6f4a-44ea-a276-9c91c2a1bb89	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4ff2bc73-3cae-4f09-964b-8c4b3229a5ae	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
054c7766-0ffc-4ea7-b9f0-be69237a1c15	02b71f3b-f509-45df-9766-27674e3d1848	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
3cfe3d40-d9cb-44cc-9207-7ac889131d35	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
96ea14fe-29f9-40cc-8be5-f947b8519879	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
29e065bf-6549-4bce-a80c-df22b06f05d1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
58bbc207-410c-4bd3-aed0-fb21f7a60633	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0d6058c6-bb1b-4b80-abb4-860b43ff47c4	07771505-6c48-4181-a94a-80816e093af6	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
67feb74c-7c79-4546-85de-9b9ff19799ff	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-06-30	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
5ef7f18b-2fca-47ca-bd0d-f2627a0dd20d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
335ffb60-dc9d-4776-bcef-4289bb4eba74	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7a845069-f947-460a-ad7c-e7a930e6d7bb	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
76aa7fc1-8c2a-4b44-904c-e353a5d56feb	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
44381a60-8f73-4311-b184-216953bb5e8e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a065fd2b-f2da-439f-9e3a-8aa10bc6a028	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
6c492b14-ba77-4ed2-9c93-f43d4f014997	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f2f189f6-024a-4e22-8142-57c106db543f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
587727e7-7363-4ea9-87a5-04a1135f3b10	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0e3efdba-66f4-46ad-bd1a-b6c334acf0a9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
cb3778c1-2b43-401e-98f3-f158aa41017e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
978b4e10-5c80-45a6-a797-42f6d31b3b48	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e5213c98-13c2-43bd-889a-04dfe1b9127d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
6730e36b-4adc-4717-8f0b-9879ea9d184c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
42dc6254-5ba1-4a11-84f1-eae572b76e54	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
abe1fc74-bc39-42b3-9a14-329cf14dd61d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ad199b4d-90ec-4eb8-aa88-bef1b83b526e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
83fde2c7-0d67-41c5-a97a-729d13bdd5af	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
46de8d9d-24d8-4315-a72a-baaa9a0df1a6	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d7d96ddf-5bdf-4bd4-803f-9b908ca9ae5d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3c39ad36-32ce-493e-9c2a-5b14de83b02c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
00acfe4e-4ed6-4e75-8bad-0c6b97badb1a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
68807c2b-d4c0-4907-90f6-e0a5688fc306	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f3cd974f-bca4-4e02-91ca-0734352e9846	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8e14c4e4-68a9-4464-880c-b58d17970f69	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ce849ea3-ab14-4592-b004-2f7f9f5de78c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
1b2d00ca-9b8d-4358-9f9f-c4c96900eb55	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3a703939-fb8c-4e3e-ac31-239b540f20c5	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
83b73ac6-9ffb-4df6-bb72-9388deec6156	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
26376bb0-f7a6-4710-80d6-f9080db5c517	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
077db905-f2c7-445a-a5b8-650c1e0ba2fc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c9a6c53a-f850-4683-91d5-020a773aaf1a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
a7bd7d58-deb7-4845-a643-c64a6a1b6e02	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6d2f5ec0-3de3-47de-87ae-f64f8e8911ba	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
12745258-be66-45d7-9998-309577fadb4f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9a048882-7cae-468f-bab5-1db67a96bea0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c150796c-de10-4fd9-960e-bb2ef08fce69	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c30c0585-0d37-4ba6-99ab-8b4c98b250ef	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e79e52ee-dd8f-494c-a621-61f9c0425ffa	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1eb5afad-f456-4215-a5c6-a1fdd09d9b07	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
de5b21c8-f14d-4199-96db-029e8a32a41a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
4ddf145d-50d8-4845-aec5-da348f83464d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
341e9246-76d2-4d8d-849a-59a1371f0e05	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6459a4f9-9ad7-4cc8-9e16-3e68134ce3d0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c1025525-2ac1-4016-ae23-5fe32ad9ecc0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8af3e483-6679-4087-a2fa-32b8f749178a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
44db9a79-726e-4b29-882e-376ca6849583	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3855ebae-9a47-447f-b708-242682a79214	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
9831d8be-8794-439f-a43e-0f82bbbaddd8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
5f912afb-5183-419c-89dc-530dd527fa04	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
933b2eed-047c-44f2-b4ae-12d35dfbf233	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
d9d097f7-7189-412a-ad9f-eaf16a7e908d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
ef766cd5-aa72-4f08-98aa-7fc2dcd9b532	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1cceb68b-96e7-4a3f-88a1-940e88fbaa1f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
fb246847-b69f-4eb2-9dfa-fc8862625bbe	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7c481c3f-cc79-4786-bd30-29c16d1dfd7e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a33c64af-04db-4967-870d-670800e08f34	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6c7b6163-fccd-4ef5-8888-bdf7f7911ad8	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
cc57708a-25db-4ecb-b445-927540210625	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
24813507-5b88-4a1c-be68-50a1cfa9494b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2f1f6fba-8be1-4d47-991f-ef67b7f20208	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
eaae4c59-e366-4f25-ba04-3f675fb093e7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
33b08218-c218-4745-a65c-9e89ae669ee4	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b1ffe95b-db5d-41b6-a42f-87d05590acb0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
06b4c329-b793-47d0-a9e1-111429def95f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
16d7ba20-1a35-4b65-bd64-5c71cabbe79a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d7279c48-a50f-4667-821b-d035f8d95658	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
af8d703f-e427-4a72-87ed-8dfdd1ffcce8	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3332315f-f5c0-4141-93e5-0ee27d36f9ae	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b8158c47-eca1-46df-b9da-3817371ee4d8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
036a66a3-8c7b-4b7e-9922-5d37a3e1b10c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
72c39466-ce03-46c6-96b0-b1e7707d1f2b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6d787e68-b434-47bf-8e92-ad26496eca04	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
874afde3-90fa-4624-8a12-a31ed6b4ed1b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7af6e9a5-4dae-4071-8a7e-aa984828639b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
417b178e-fd55-4f30-8f05-ed2ddfcffab3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
237e5419-805b-462d-80ff-e296b9595a82	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f2f2051f-1f6c-428c-9174-0bb3672dc9e9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4ed40722-f0b7-4f5c-9501-be07009719b5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a8c3639c-7549-4301-82b2-0eacff9d5758	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
3efc3787-1c33-476f-ab0c-c1394df8262b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4c71ebc6-55a3-4365-9803-39010ee07147	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
fe08ed60-4bcf-4cac-b6c0-a17ceba34ac7	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
046dafef-e34f-48e3-b101-3dc8006095ce	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8c054683-c1c4-4066-8b53-1c4dfbc12b1b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
5465a2d1-3055-4c29-a804-b6c27d8c4447	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
6935f09e-7b0a-4c4d-b8d2-8dfe1bfa166e	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
de60e0c3-294c-4bfa-995c-914c8b0bcaf9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4b252da5-e9b6-4f6f-83a8-38ab80213563	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7bda8c5d-105e-40eb-b61e-4cfdd25b94cb	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
776794ec-3d32-48d9-9321-283487e59546	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
613b51a1-e702-4621-9824-da13107c9485	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3e6b9661-3520-4ac7-94c5-15e2d4443f6a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1856f276-d80d-4453-b4ed-7b9dd8bb219e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
baf59905-6509-4825-9edd-d6b5aa47df1d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9bba30f1-c4de-4019-97bb-42b29d35d90d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8452fadc-a736-4c76-9efe-769371643a60	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d320e273-2c70-46b3-a908-c4cc49cdf57e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
fb3e7969-b3cc-4338-88ea-637823f70761	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
15042994-a060-4b06-b270-38aa15970451	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
636e1531-36ef-4db8-8122-7110bf24edc7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
fb9f3704-1d08-4a30-9980-37ec134f1d2d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
de6def51-a6cb-4f2b-8a49-c67a7603e7a6	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
fd35dcd0-8011-422f-8a4a-fa8f4c686443	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
9b3bb853-9386-4260-90c9-d96f59dba9ac	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
85686fe0-7176-4a87-9f53-f657d5217f61	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
71e0f42a-8e09-4116-94b5-e1573d8068e7	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3ceded42-62bc-4d17-b142-df281576c27f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
04a6a4d8-64bc-4fbc-a7ac-4f4ea5f4c29a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
f88cb71b-6815-4806-9c6f-49ae9fe29daa	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4823926a-8c9b-4a38-b8a2-8abe20019742	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
19dc2559-67bf-4c12-bbfd-73f9c104616a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d12af046-54a3-4895-a102-fc68ab81aee8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ed7e4a27-d3f3-438a-93c9-146385c6670c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
f93ee26d-4133-477c-a1ca-4c7c581683a8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e407ad57-2bdb-4beb-bba3-4fbafad693be	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
59435f73-e9c0-4aef-a445-fb418bec8fd5	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e3745558-2339-4095-87f0-fe8f1a4095d2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a868a38d-02ad-4381-af77-45bc15f409fe	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
c6206fa9-4e27-4518-8353-a0b00f51efd2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
db680b92-cee5-4b66-abeb-97c8b3e61574	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
62a11e60-8622-41c8-bb20-5d662807ed51	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a3c15def-1bf3-411a-8f1a-9f70d29d200a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f6446974-b347-43da-9bd6-c5c5f286d09a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
641fc8df-12d7-406e-a8cb-aef1c235c22b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8923a91e-91cf-4cb5-9890-7fc088164181	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
18d4b078-3c42-4ae1-830a-0e348c403b74	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ee81754f-1c29-4a74-bebd-fbe92dba3a91	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
7cd874d5-bb29-4800-823d-0f155cbdd9f7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
fa8272a4-3833-42db-8d41-6a81351bc3ac	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
df78b163-67c5-438e-8af6-822ef13412e2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6829e1d1-0bb3-46ae-b7cd-8fbc78d5bc7a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c75a8677-13d3-4db6-8ac0-20c0691ad27c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b3087d75-4311-4d91-8472-f31e17e26740	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
9c97adae-d621-4aa3-87ef-4afd65dc8aff	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
cade6c8d-a4d1-45b2-b749-b9390d9162da	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0d122f2e-c695-4e1f-b6e5-c086564cdd4d	07771505-6c48-4181-a94a-80816e093af6	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ede553ca-71a9-4d95-824a-6065c28ab326	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-01	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0d7a649d-27f6-494f-a152-0b101e37614a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
07ee1353-314c-4c42-8f64-bf4d4ac435d9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
564f776d-c510-4f9c-8df9-c0d99dc98c7a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f338ff85-9250-4691-8edc-94baf2ddbbbd	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
333eff44-865f-4083-bbf7-3e957dade18c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
83773495-7dfc-4c23-9507-4870aae698a0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a8abf8a0-b03b-49ca-b43f-f00d29f1d556	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ea8227a8-b1cf-456d-8c14-8aec11ba535e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
8c1b59f7-572d-41f5-812b-9a43cdf28533	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
bff7b909-ce15-42d5-8538-07f395329e00	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
4449138b-06f3-4687-b439-8f032c38e6d5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d368e4a9-1724-42b8-9c4c-12fa3a09b6e2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a6f04d4f-eb64-470d-85ae-d84e8a955ecf	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
79671016-dc8b-428a-8fb8-4a754af80084	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b735fee3-4b98-4555-9c68-7c58d4193949	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d0f7c81a-cbaf-4d13-85e6-da40a79e2d2f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7b88ab7a-bba8-450d-8947-0e366fb85624	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
96db8457-9292-4f89-af8e-c972e01056b2	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3124a33f-a292-4da7-9e70-100a7f7bec1b	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
0171a032-cd9e-4c40-afd1-5036a399562e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3ae2acc2-5781-4f85-9d10-fd1f49071006	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
63863ab2-1ede-4a10-a1b2-79a0ee4b0682	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2f680567-534f-462f-bcf7-5bab77d66a5a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
43e6d064-a630-43f4-a42d-c9ce93496e20	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
16a00e4c-760b-49dd-bd19-89000766b7f1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e20d5304-7e6d-48a0-90fc-7093079b1fc3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e94ee131-1447-474d-8e6e-7c0681755d24	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6cbb8845-c6fb-4bc6-adfa-ec00bad084d9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
592979c1-e1c4-4e0d-8be6-bd0dacc25d81	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
11697c80-3679-4177-bec7-e97352863a66	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
36de9df5-b20b-406f-b7a5-3387716effcb	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2f5083db-4e66-47ca-ba8a-b95e6482b8b2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0e274f31-bc18-4011-b333-6f2b27504b02	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c380649a-01d4-456c-9fd7-17b3514bc8e2	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
76410814-f709-42bb-83d7-d66fcc359bd1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
a9fb4840-01e9-43fb-8140-0fddfc12cde2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8d424808-72f6-46c1-b432-510599dd16ae	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
fa77b774-ebf2-4314-8f38-9716413533d9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
db906580-99f4-4994-8418-bd1f45be7346	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9e1c993d-19ca-4895-b662-00d587975e04	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
05fd3e1b-baef-46d6-b411-67ceb45e8a1e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
baab3ebe-654d-401c-9fe2-afd690046571	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8ae8ac35-d1ad-44c0-8c8c-7dfa6c8727fe	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
431ed7e1-c3ce-4550-8c9a-7768b4b93ae3	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8b9e1f41-cc98-4efe-93b7-20a5786d4e6a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c94f37cc-d424-49ce-8bd4-f49e556a6bc2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
017a06f9-fe36-4088-8a58-64123c491285	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
67433d99-b441-4fbe-8611-83c6f7a1d5ba	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3e5e729f-8d40-4713-840a-c6098349932a	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
603b1673-77d6-40d4-be36-5f9c39087ac0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7cbe76f4-ecb9-4888-b5fd-fa3f09fd1948	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c9c4e95a-b8c3-4add-9069-7c0cc65553a8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b86e32ca-9c72-45c6-8942-3653abd53c3c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
487d2b34-233e-4c94-ae3f-f49046e6e1e5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
707a589f-778a-4812-b743-4fda564ea93d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e0e8fcf4-4708-4336-b389-4f60c0c3e001	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
052e48fc-e0af-4980-9b01-0827b0b8a045	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8a2dd813-5159-406e-a031-9b4cbf6fa6ec	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
89c1db46-18cb-4f45-b6cf-a732559cd11e	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
11e69f97-e8a2-456e-b741-bbea4614ba96	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a10598b3-61d7-45a2-96c4-db19af832eca	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
71bbdde3-842f-4b44-a77e-9868d4c1cc12	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
45756402-ead7-46a3-9e04-886830f7271f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
7591ef18-a83b-41c6-8bd9-363fb40750ba	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
7687b5ae-436e-4231-a9bd-30ea02de2f99	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
04d6feb7-a834-485e-a7c7-85c88818fe6a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
dbd75ad9-2f25-420f-8a27-97f6ba0a6b2b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
25f370fa-8ec0-4a24-8f6c-c29758ab865e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
50db767f-00b0-4108-8367-4d3423476deb	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
aa007c45-d950-47b2-9879-3ce2a7988a04	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
198ba77d-d41b-4f8c-a46e-ee2bea3d4558	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4bf53493-4757-420d-8fbb-8bffa85e4562	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f180912c-7ef1-4a6d-816c-f2d5f492e83b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7b1dd16c-3481-48e0-b96c-47e03a67fb72	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
37bffa7c-2b96-4d09-9d18-6cac46839f87	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9f0ea579-9280-4d1b-b962-03a25a1479a3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
72868134-4943-402c-8e2f-c41612f1d401	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
31218029-f53d-4fd8-827b-92ed02c83fc8	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4057799f-ce7e-4aff-8c1d-d9b3ad4d37ec	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
48723992-456a-4f89-8f45-b25e12b1567d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
d6a3ea79-fd66-47ca-9968-743d5fab91cd	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b168f534-a467-4edb-9086-a63dbe619abf	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8ddb875f-de4a-4a56-9098-7a2f4bddb78f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
bcbab390-d6b3-4fea-8773-4d64157b41ba	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
097d205d-983c-4afd-b562-1a840e753739	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1929eac5-aceb-471a-ba3b-fc9fac8cef07	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e7b346b0-9659-463a-9e8b-3be6f1bb0eb8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a9cbf71a-0099-4a71-ab6c-e5bf2e1faff0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
af61cbb1-a484-42e4-97ca-b4dba3beb97c	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
20b84d66-95ca-4db5-9255-9ed84a467a66	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7e7fa71d-203d-4ba5-9fce-bf500b70b53f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ee6f3460-ad30-45ae-9c0d-c83bdf7e6ac0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4f9871e0-7a77-45d1-84f2-ef338e7d2908	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b63d8d7a-915b-4d08-8e23-c258bc391d59	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a79f05c1-c06d-4a7c-8764-096ae434668b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
daa8e049-3e07-4a5b-a94e-e156e11ff042	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d15ffba7-af72-4a95-8678-92e3b2084be5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
265c52a0-2271-4063-ace2-f692551babb1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3c3599ff-df5f-4424-bdeb-86a95d8f36e0	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
eff04559-6294-4693-b3ef-53dbd4af27b0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
dc72ec59-9284-45ff-9c54-b69cfa3e5f1c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
4319d202-37e4-4655-86e5-f046640028d3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
6994153f-fdee-42c4-9348-c81ab721c564	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
88ad6bf9-4fde-426c-9e1f-603c97065de5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e6347748-446b-4341-8e58-c2e9e9a25c81	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a021986e-b341-4c01-a7b7-ca7f8888968c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
0e3a2353-e330-479e-a4ad-b9e29c8ddab5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
1d2940c1-bc55-44b1-aa3c-94c3b773a4eb	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
ca6a8138-de8e-4947-bb9c-0411e29454a7	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a69bc022-cf1c-4da3-ba21-928d09314530	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f4ba936d-dd78-476a-ab51-c60617ba4b98	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
cc3971a9-e693-4ab7-bb8c-e9e8d257fb0a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
21267627-74f2-4a12-8982-108bed573fec	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
17399298-b477-4433-834d-9aec144dd00d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
96a64c5b-b1d5-48b0-85fa-13b447b9dccf	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
17268d5d-2c07-4cac-9fcf-abf352ccc6ae	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
09a8e057-eeac-4e9a-a93c-048539f495e9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
6b8360fb-8963-4aec-92dd-bff322245e2c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
3045f202-7c0c-4b69-8529-ef4bf9b96ebd	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
12830d18-90d8-47ff-9c92-ad7eab936cce	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b4e1fe64-2d29-4773-883a-a58ad5488680	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
d15d2206-861a-4cfa-b393-7f169f140802	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e226d692-353b-4491-b38c-8a971d7813be	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4b1b0fd3-99ff-4db6-8a22-5843d43e0a8c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
918b858d-5dd7-4571-b3d2-fa27eaa8e506	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bd4610be-8308-404c-9a06-b5db47e3dd8a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6a97faa9-dfcc-4912-a262-a28cb6844074	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
403ad34c-0471-4808-ad74-7a43c9506a5b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ac27342f-e720-43bc-ae0f-11eaad26762f	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b0e1913d-4cf2-4c5f-b403-40803b587ad5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6c18f619-780b-4b63-84ab-cb25fcba1b9c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a21c3634-35af-47fb-b9fe-4b053b62a1bb	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0d564a39-8d49-4bb9-973f-3a5e211e3500	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
65385ef2-4e1c-4d48-b5b7-de8bf8df9a04	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f2cc1671-4ed7-4fba-9d83-84c1658f411d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e4c5c39e-da99-4037-9145-871cad484fa3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
caf09071-de55-4c83-8b29-2660860c2c7f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
94406f35-5461-4fc1-bbf2-1b4ad3437ff6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
3ffce941-3151-4973-b5a5-d9b4a5c6d11a	07771505-6c48-4181-a94a-80816e093af6	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
438a4c5e-9518-4fb8-b1f6-c642031bcbdb	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-02	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
57f1880f-b190-4819-9ed6-3ff9a96fde12	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
30e55fc0-297c-4bb3-9af0-dae72e780148	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
5bbbc277-c98b-48d6-af90-9afcb2676906	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
9f661552-72a8-4a4c-a05b-626c6d7f3e39	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
695f0f2c-1110-411d-8fad-113f82911651	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
73b78f12-64ab-47de-917b-24d5781065a9	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c0912485-e3ea-4a1c-b638-9a643b7bb711	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
5f46030b-3324-45a3-a751-bc030ad8cb0b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
793a2a09-9e6a-4bb0-8797-2d766f76c9d9	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e85ccab3-b801-4e73-96d5-ea3059ceb43b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c2ffe558-7dfa-4ea4-a1bc-979414104938	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
fceff277-497b-477d-bf2a-d74ef8df7205	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
13ec36d8-dbad-4494-a1a9-a03e777e6e10	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
6926f6e9-0461-4c67-a23d-9aaa06a3902d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
0ccfc5b7-8803-421b-935a-f64aef9d65e0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
bd08065c-4c9f-4372-8b29-26b66e7209f1	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
856b59a5-2b3d-4506-9e8c-402290052731	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
18c88f91-6298-4dcf-85a5-036b2e50e590	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8eac07f6-3263-416f-a0f6-a671b42c805b	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
cc4144cc-0371-4e94-a250-01c760093dfc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
1e0fd9ea-fcdc-4b84-a484-ab51c2648205	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
1bb26254-43d7-4886-a059-ccfbb773ff0b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ff7e199a-4792-4269-8af8-273b3e877cfc	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ec48f06f-801c-4732-964a-696aef1fcbb8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5d1bfa69-78fd-48e1-b2a7-97c3e6c7f8eb	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6e9afe8b-ccb7-4865-826f-4deac1570d37	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f8a8b780-2778-4bb7-be62-300396721d6c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6a00434a-eb35-41e9-a54e-d64f3db03cc5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
fc116df1-8ce3-4e9b-a614-cffd9f75c05f	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9548e029-bee0-440e-8990-a1b0a5303608	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f12686f5-6d34-4689-bfb0-76b0519d5a21	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3073e4a2-658e-4eec-9feb-ba0134c7617f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7c4e80d8-eaa5-48ab-bbb2-1955ac902565	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
bbbf5903-f38e-427c-a372-2410996720b8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f6e71c36-70b7-4467-a9f0-dfc2dd9f2669	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7f9bef9d-4495-4c91-9745-2fd755ba291f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7826fc56-95e7-4cd5-93cd-451abe88b9ac	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1e94aca4-37d3-449c-9eda-1292f7e0b2da	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
db2ce0da-9579-4863-838d-a8e234f28337	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e7213689-2fb6-4079-8e12-f5f27ae22a7b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6b0c6c0b-804f-44f3-9ea5-34c0d4b6fed5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
cbfe61db-9ca5-4ae1-a733-d82f200e6307	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b55f0611-0015-4941-ac84-2732f581d086	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a5a8c4a5-3037-4ea8-a568-c71866fe7d8c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
dacca356-9212-44f7-acc6-304aa073fc52	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
61544ccc-4a97-4483-92ec-b1f21d929bac	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
21161786-0b55-4cb1-954c-ee4ac59c8ce0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
72229591-a58f-4d7d-a27e-3245f0314a2c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c3f28030-f166-4212-a772-c04db3d85ac6	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3cfef4eb-0925-4eed-834c-24b9d2625e16	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
57335bc7-2181-434b-8877-f07df527a43c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9b127525-3bd0-40f1-b45d-913acfb0f881	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7d222ce9-0039-4815-b2e1-90d0c157c1d3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
f22ec42b-e225-4fec-8167-8db5f8db0f73	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
825107f1-b38c-49c7-a94b-5f1a347406d9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
153a680b-896d-4f32-9008-a71b511db366	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0215c2d2-f1d2-4ee6-a810-d12aabe6e605	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2460ab13-89e0-4d1f-b7d7-777adad9b62a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b10a4be2-3d90-4a56-8cc9-4fcbd6df3550	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
3a08d605-ab05-4b45-8245-c619e278be0c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0edda960-fc8b-4a54-a148-573140ea8a5e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3b573e6f-b43d-4214-b2ca-20fa2f17afcd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d4452f54-6756-428e-afd1-96e274e5ab6b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
119302fd-26fa-4d03-8991-cbab8d8b2500	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ae077930-94e7-49b2-9109-884e7f125bf0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
914ebe6f-4266-42ce-accd-672654b6fc61	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3d819084-504c-484b-b3f1-aae16fe06f00	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4127cc22-a223-405a-be11-6187271c3392	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4ea5a840-bc6c-4c0f-bec6-52f3df05dead	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
46fe740a-c6e0-4f45-acb8-a8f75c865b34	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
0fa97685-6d94-45fd-aff4-788bd54b6a44	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c655b64b-1bcc-4646-a1de-ff55278a081f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
b25a482e-2b2a-4297-b089-7043d83d2c53	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a083d00d-b255-4405-9d06-6529c39d9455	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
40f2c374-377a-40e8-8d3f-bc8bb9fa6263	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f32981cc-15e8-464e-bfcc-f6012b8aa326	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f368e598-9312-4f0a-a5cb-f8b5cd95226e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
75289fd0-83c9-4213-95b8-6a0f8292a66b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
78dc3271-26ee-4c81-a13e-f5d08047ab00	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ffb06761-f295-4ce8-b551-e1c2bac7f0c3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
dec500b4-8239-48e9-9fcd-3e20a3dbfe55	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
df4acf74-c1b8-45d2-884d-3bc78119c1da	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0b08c84d-472b-4fed-9c8b-dc2ae2e60aac	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b10ab80b-5813-4b13-ab09-86a4c3987904	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
531ddf1c-7223-414e-9a29-1b329d844457	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ea47a6d0-7e0c-4f4b-b8e6-21decb64ebea	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ee0982df-927e-47ed-b937-a78196b65b66	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
eb351b77-4514-4a79-8a42-fde04e9757eb	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
673762d4-8834-45eb-9dfe-de34388a3b4f	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
36f69c79-382f-460a-b22b-1edae5484201	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
60b735e3-3c72-45a8-9204-5b28c50ed83c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
805b8c96-3cb4-4c5b-bbbc-1050bc41f1f8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e80b50ec-72a9-452d-9170-a80b4da89a55	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e4509cb5-9bdf-4936-9ed5-0e4bb8b98406	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
654271cc-b6a2-4927-b39d-1e21fd20642c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
bf1a3ed5-3c9b-45ef-a30a-d1d02166a0de	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3856b4e6-b54c-4b96-8e1a-21a1c02ac23d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7286203f-745d-4883-85f4-b9ae41a93287	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8592b3ec-2245-49ca-bbf1-e71b6a7331cd	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8799c496-04eb-41b2-a0f2-8091724148d7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
1b931406-1b6c-43ac-92ea-ab942dd666b7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a5d2a611-5b0c-48ea-9ee2-7506ed163acb	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2a06b214-11c8-442f-b0de-d6f47eaff526	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
85195f64-d461-49b4-9043-137af93223be	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
eef42f79-f386-43cf-b411-3360ca061dac	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2401f07f-24aa-4a7b-96e0-993bc4e0c762	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
045445bb-d07d-4f48-aa98-7f0bbfa20a8f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
27fd58e7-4de8-47a3-923d-7b970bab0f30	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
bdaffad1-4dcd-4f21-9c87-aaceb297a120	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
cd3f6497-18ec-42b0-aeb5-bd85ed638f1d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e2322965-844d-439f-8efd-82a616e161de	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0d8bca47-fb8d-41af-b21f-d621881a93fb	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
aacc4836-08fd-48a7-a274-00f967f1bfd6	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
300cbe97-b46f-4799-895a-c5883900015c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
772002b9-2932-4a48-8376-f8352c0c796c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a232d978-ed5f-41da-8d8a-f3d61502faef	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
285e1a8a-0d2c-4ac8-afe6-c1c9ef08e0c7	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5f4655d3-1e9a-4c10-9c21-8377a22bd02a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4da0ff45-8176-4f08-b4f4-191ed918f644	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e8cfbca2-0762-4662-93b5-d90302bd9d11	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
2dca8539-dbc5-4361-914e-97d9c33c4f1f	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b1bd459c-7e76-4ebb-9574-ae7fbc479c4a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9531a5bb-2988-48bd-99f0-03212f40ddfb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
31f89278-1147-4da7-a428-1492c15830d5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
c8e562e7-b0bd-4205-bd83-1e81d34839a3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
95821618-a4fa-4885-b0f9-24897c896bc4	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
81aba258-5bbc-4165-bce2-7759ae62262e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ccf0478f-0050-47e5-955a-8246c25a28f3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
1d4e992a-5505-40b3-bf94-6cc99887ae11	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7c055c02-7979-4532-877c-2a5344a6e658	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
9e5db0ef-d9f6-479d-95c7-763eabf1a2fd	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ce9360a8-1923-4a6f-a950-fb08b3e89349	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
17e3ff50-e58b-4175-8232-874e5dc5d63b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
057de455-b4e7-442d-b3b0-a15fbb1f0dd9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
fc608e1d-22a4-4743-a05d-f9f6f46a8475	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e0524a53-428c-4131-b9c1-4a60ee5e748a	07771505-6c48-4181-a94a-80816e093af6	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b8eb17a6-4135-4bc3-babe-de9152e8a9d7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-03	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
bc6feef4-4a34-4d1f-a90f-91bc5015fcfb	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
cfdf90fc-f192-45fd-b188-94f7d06640f2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0b52892e-0f5f-44ae-9fa2-a38327d337b7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c734f2b5-cd19-4980-bb16-57944c7e9698	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
64b7b656-8e2b-4875-b428-af7559823604	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
83329e76-bde2-4b02-950f-e2a06235b241	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f79e50d8-aa04-4efc-bb09-2246e39462a2	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
03a53139-2d69-486e-bcfa-9c8449a7c322	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
2ab2cbed-e1d9-4af4-b409-c347e984a901	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
00bb9d31-4cb3-4a5e-a306-7262d853b02f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
1c5bde72-8166-46f1-a8d4-7b11d332dd8a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e793a868-0841-456c-beeb-07992dcdb97c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8953c999-ed56-4b40-8853-e80ba0fb5b77	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	09:00:00	10:00:00	f	2025-06-26 16:04:19.537149+00
1dac802a-14aa-424f-a3d1-9c77fcf0a14a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-03	17:00:00	18:00:00	f	2025-06-26 16:04:19.537149+00
343ef307-319c-4a63-8743-656003fe31c4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	19:00:00	20:00:00	f	2025-06-26 16:04:19.537149+00
e56ccbff-24db-4910-ba9a-923ff6aafadb	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-03	20:00:00	21:00:00	f	2025-06-26 16:04:19.537149+00
44332535-5ce9-46bd-991e-3ca08bf6ecfe	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d5f138a9-defe-4247-9afe-e34b43adfb43	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b25fc6a3-a2b3-4f7b-885e-b5c9da6e7632	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3b369315-b8e4-408a-8bf5-1d5feed550ee	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
9affe5ab-74d1-46bc-b774-bf4177647ae5	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
be6a70c7-e3eb-4c50-87f6-fb9a7f15cb91	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
6917cbbe-fba1-46a4-ac99-66d7b36a4ca5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8d24ea74-d9b4-46b1-9555-7b7a691738fe	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
1d493b1b-6290-42ca-8877-cbaabffd6e84	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
da9dd69a-e17e-41ae-bfab-0dd1c55ad578	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3d021c2a-8be8-4e61-915b-f5e2f8b6d0a7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2fc87c2b-8ff3-4a68-a742-1d14302a252c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
47cf2910-3a41-4e54-8809-c180ae26f285	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8fdbe0e1-cd5d-4b41-b194-ec8b65a9a814	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4aca4538-4a77-4114-abbf-84e32deaee24	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
54862ad2-407b-4f7c-90df-5a4ac320fe10	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9c254725-9ce8-40fa-ad36-ceb3b811cb48	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d4995106-10da-4e92-86aa-23305d97dce1	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
17b2b18e-8a3a-4dd8-8ac2-1f6a8e02ec99	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e9906fe5-e79f-4602-85a6-9184c23b8347	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
a00c986b-0a76-4d7c-a3b2-a7afc61b11b7	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e1ae695a-bbf7-4c00-8d0b-6cdf2c10b2dc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6cd62a76-ef97-4959-91ad-42bb741ee3f0	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2a94a8c2-e2ad-4e7e-90ec-6223971fbe96	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
241a7b69-5868-44ba-be78-61d654a46db5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
54795844-f1b4-46de-80b6-1679bca3bbb8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
5f07f14b-2ae6-4756-8df0-1781bee2c145	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
132ad9c5-e259-4221-b12f-7e3d1fbf6450	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f8e31a9d-69d8-4e1f-8035-f76b772ec067	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d7b58c43-e450-425b-a5fa-8c0f2fac38ee	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6b15d72c-069b-4bf5-8151-8ef98d81f899	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c2138639-2653-499b-8a27-44383e399451	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c6f5a1d6-9f0c-4f35-8709-4fd24cf88cfd	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ef3e25ea-c80a-4cfa-b8e0-a529e262c672	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c69c88b0-c87e-4217-96fe-f538d2b3e3c2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
65430004-c68b-4c4a-b992-aa3b4ec70ef9	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8f61d502-0235-4eee-b43d-c635a035de3d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
5ec99740-37ef-44db-a566-ec02cc694cbb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
ac2e6450-b7f4-4b1d-8056-e5100a9a4ad4	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8db5d936-5630-4d2b-b40c-2140438ad8d0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
efc2bcf9-7347-46d5-9a47-814ee0faedcc	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
26da9995-12e9-4d05-b119-913d2ed53a1e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c03903c9-8bcc-4ad0-ac9b-8b00c214a600	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d327fe6d-b689-4055-a62d-d4bbcf440591	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a09b7baa-45fe-48f9-b26f-e045e4868073	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
876553f2-57e3-4e25-b4b9-b0fe1a64626c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
f777f19c-e07d-481f-b7f8-6356febc22e6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3b07b3c7-4c65-4e92-a605-00223876fcaf	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
1c8fef2e-7200-4d73-b5d7-f181b7739507	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a2cb94a2-5a31-40e3-83a5-ca26e6bc92f3	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
dc764fb7-6fe2-4279-8afb-2004b63bf6e3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4b45c0ed-2a99-4144-b2a6-c79e0c856283	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a371be1b-b502-4a25-9a57-1f46258874a9	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
5e20dfe1-4c12-42eb-9113-23884b8e77a1	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
33fd7aa3-0511-48bf-a957-f2ffb9859bbd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e0c1bbe0-6413-4e98-986b-665cb5431e56	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
14cd3017-2f23-4460-bf84-209daf2b47f3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
fff00a2e-bc4e-47d2-9843-e884e29bb01b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6cc3b16e-b06b-4e59-a9bd-5c0d0143ad65	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9c9346d8-1109-433c-a297-1b95792f201b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f88dee83-15e6-4a67-b428-1d4d8bd3934a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b4442e47-59a2-42d5-b7c5-5e1179b41079	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
663f9d1b-eabd-49fd-aa27-1f99ff58f53f	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
553c28ea-debd-42e2-86c6-47f0bd73f7ee	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
991ba809-8643-434e-ac34-b4f76585a0ee	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
cbcc5b32-201a-4a5c-968c-5b25961a4e78	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
19631a40-73a5-4e24-bd40-96b7c504d871	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
fce6d9ea-c425-4de0-b4d3-1cfe8fd18236	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
58ef9941-514d-42e1-8455-54bfe47bc405	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
666fdc16-3c61-4e34-ae5e-f6b565dc82e4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
900b2f00-3c2a-4ac6-bcca-58f6ef04f11c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e924b90c-2117-4c56-8a8a-94727328e3a8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
0b702462-3dee-40a6-9eeb-94708694837e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	11:00:00	12:00:00	f	2025-06-26 16:04:19.537149+00
133cff69-c2c7-4ece-93a4-bc24c2142f2c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	12:00:00	13:00:00	f	2025-06-26 16:04:19.537149+00
376f28f2-0dee-485b-bd52-3bf75995c11d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	13:00:00	14:00:00	f	2025-06-26 16:04:19.537149+00
548a0903-c2be-48ec-8cba-25479e384b32	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	14:00:00	15:00:00	f	2025-06-26 16:04:19.537149+00
c1db0ac0-99bb-4417-bd57-11e8ddf8c136	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	15:00:00	16:00:00	f	2025-06-26 16:04:19.537149+00
cc672feb-a7d0-4f8b-aa2f-b81ccefaab6b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	16:00:00	17:00:00	f	2025-06-26 16:04:19.537149+00
09370e49-0a7e-4463-bdc0-e90b53bceb8c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	17:00:00	18:00:00	f	2025-06-26 16:04:19.537149+00
645e6482-b9dd-4feb-a860-5a67cbd2dcc5	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	17:00:00	18:00:00	f	2025-06-26 16:04:19.537149+00
fce52a37-510c-4741-9c3a-99e27b222bf9	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f66b3ede-a781-4a39-96df-8af350ba23f3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
fbf941cd-c5c1-4691-97cc-fab9bdb7ab05	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
35ad1ec9-8abc-426b-94f9-0738a284fd71	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
48549955-7e8e-41bb-b87a-1394e202fb08	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
fdbe0fc8-8bdf-4aee-aefa-ae42234a806d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
1aa91236-2c39-47a5-aeb3-82e1cb3959b8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
36ba8729-fd80-46f0-b626-47ac0ebb2856	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
31e69d27-5195-4ba7-9c21-3b95621f3bae	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b0410718-b812-4e27-ae5b-ecefa3233ae5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
1ae1f27a-9b07-4bb4-a3bf-086b75975b6d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
7652bdc8-ea30-46c4-8dea-f72c5467c254	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
86622cc1-8fe2-4ba7-8944-5d0062060308	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2a3aa4be-e704-4295-82db-6b6d81c9d241	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
cccf8481-4e16-4036-866c-da7c946595fd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9dfc024b-9c3a-45c3-a99d-03f8b9f5cf36	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
92d44eb7-d7b5-4e7e-a9d5-5126ddb69240	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7f2e8266-ba28-40da-8196-86dcd5e177dd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ef16b9e3-5b14-4f50-acc6-48aed02a82d0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ebc1851b-9b99-4deb-aa4d-1f88e1141b44	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9ddc0fdf-80af-415a-83b9-0bb8e53f05a1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
8380febd-1f73-40c0-bc6f-62cf3548e2ed	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b8fb44d0-f38d-46c5-974a-d3aef57c9950	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e7ae3f9c-d61e-4760-a5bd-4018651bbddf	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
561cdd80-aa0b-42d6-84e7-6bf82575f0f8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
fdd30c93-d1af-4e01-91c7-0182a3794844	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ccfaa75b-de4a-4f0e-90a9-535985ee5a6f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
85d40cc6-3849-4478-9426-3ad8a2aa516a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
cb9309b5-5cd4-440e-9a6d-c45de3f01c14	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
7ee35624-a32f-43fc-ba1a-c57be754e1b2	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bbc15110-4125-40a9-8859-7b61647f012e	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4b719509-9d72-48c9-849c-90e271150697	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
140441db-c557-4227-9bd1-33eda32933d0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a9a07848-12b5-4b58-99fe-b3542a9c7204	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c6cba96f-3e4c-40a8-ad0e-a641d3630f15	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b25504fb-a0ff-4935-bf1a-8f4e99544b11	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f49b77fe-6766-4098-97e9-b6a8603e03b7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
eb6f9051-2901-4cbd-90a5-e7cddf059d05	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4306c5a3-cebd-4344-9b34-3a26236dd465	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
cb99f638-b48f-401f-a54c-311e40cf38bb	07771505-6c48-4181-a94a-80816e093af6	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
cec99fea-7a8b-49fc-a632-61e3f0ac8a8d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-04	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0785d285-2e17-436e-ba32-d67700420fca	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
234e3295-e8d8-47be-91c0-78ad8eca7e94	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
3ab430bf-0e27-45a3-9c82-cb357cfbd0ca	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b7cff85e-0a44-42b3-a117-47d7c8448429	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
487aa415-2613-425e-94cf-9e4a0b22bc05	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c4ff74de-6c8e-446e-9172-cfb0838e4eb1	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0ad97484-be0e-4edf-980c-fdfd044a1811	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b7dd2f3c-7c94-4463-810b-acca3fe6c922	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ee7465d7-65a3-418d-b200-3afc48324de9	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
654b94b7-840c-4d4c-8bd3-756b96834a78	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
0a9360ec-c5b3-4f55-b657-b3bd1d813c85	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b4f2a21a-0c09-43b1-b3cc-2fdbb5b56918	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
aefe5d46-28ce-499a-894d-554384fc75cd	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
48c097e3-bb14-479a-8e53-e29dbce73abb	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
4f3975ab-4b31-44f0-bbf6-208491f8b621	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
03d49209-94cb-429c-952a-1205fc10132f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
44e3d8c1-7c82-457a-a26c-199cdcf19e8f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
18d34cdd-86ed-4af9-b0d1-fd1e9f79b782	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3a2948ea-bf1e-4d92-affc-4c51e3aa35ea	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d12ae000-4e8c-4157-a8d2-a915e9e557d5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
dcefd277-4c17-4ebb-a9a2-f1859d9dc523	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4ba2c149-9edc-414a-9706-c5b2209d6ad5	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f272e6be-a3a5-4ba1-b657-f3819f4cdf05	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6fc1a3d6-c091-4d96-a8f2-8b6d05406168	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b6fb672a-7023-446c-a09f-b59b02d9bd7b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9b1b301b-10e4-4d72-b81d-7453ef5c4682	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e5ca306d-7d0a-4f57-bda8-7393d0af9ba3	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d940e083-d0a8-4843-8481-fae774225972	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b82de7cc-4257-452d-973e-3dd29df7fcc4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	18:00:00	19:00:00	f	2025-06-26 16:04:19.537149+00
4d7ccd7d-d6d0-4438-a7ee-e81dade317b6	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	20:00:00	21:00:00	f	2025-06-26 16:04:19.537149+00
d49ef667-957a-41bd-9919-f51244b165e5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	21:00:00	22:00:00	f	2025-06-26 16:04:19.537149+00
675de7c1-debd-419e-9b5f-38127fcbce7f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	10:00:00	11:00:00	f	2025-06-26 16:04:19.537149+00
2e597da0-a529-4222-9452-c674c35977f8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
8ab45b76-792b-4cd7-8bbb-ee9e98e27f8f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	09:00:00	10:00:00	f	2025-06-26 16:04:19.537149+00
11aebaab-67a3-41fe-ae3c-daaebbae17e8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	11:00:00	12:00:00	f	2025-06-26 16:04:19.537149+00
839013cb-6b48-4763-98d2-42d9a64de520	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
98d8bda3-2f9a-4c53-95d1-d9b5894a2d5c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	09:00:00	10:00:00	f	2025-06-26 16:04:19.537149+00
7db7255e-c421-43d5-a691-c63f9c6ed875	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	10:00:00	11:00:00	f	2025-06-26 16:04:19.537149+00
84371555-a449-40ad-b28b-14f33a51a704	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
ca73bef9-d734-4685-bb4a-e391fc492693	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
24596ce5-e697-42c5-ae17-8d45ea9b812c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1cb58ae7-face-49df-a391-0a0c1719605c	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
33ea3b49-0e7e-462a-9dba-cf6bddfb8e91	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c845ca84-ced9-416e-8f7b-c4e55a323bc8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
90f83722-769f-4cea-afda-6efdbcdd973b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
72e82a08-4b8f-45e3-832d-252f4fd6cd77	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b1aeb01f-eacf-4f05-a6d6-e4ea0ae4fa2f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7db39fb6-4bcb-4f9c-bd7f-f957c6c246eb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
55651fd9-c626-4b65-93d9-2124d48d255f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ccc533ae-c1f0-43ba-9232-76cd5c9db06a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
44f9f0b8-ded1-4744-b36f-1404fc51bbbe	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c1b91d47-a057-4523-848a-1d52fcc4fa41	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
9b98b193-24a2-4963-afc4-5a3f296b4afc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9665d814-f31d-41b4-a57b-cf2188c3914e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a94c1b65-23f7-420a-a68a-b4293d3204c3	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
bd0fce0c-a864-481f-9350-f9b21974e737	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2e3328c8-0e43-44c5-b576-6cfa9062f86b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7bff437a-ebfb-487a-919a-f895d6bf803d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
d801ceed-62e0-4838-98b6-e52e1a321dae	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
54401d19-7b06-4d7f-96c3-fba977257395	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8426cd5e-43d2-412b-ad62-2671e0e314d9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a23c7bcd-6671-4d47-8ef4-dca7c412122e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
78bd03a9-8040-4e31-be48-9633134e8a1d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
bff972a6-c0f0-4c01-ba34-7cd14589a801	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c840bc6c-cd8c-4ea3-ac8a-3c858a04f641	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
fc573698-0f42-4ee0-82af-211732fa6fbe	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4fb9a0e4-5bda-4a24-af75-8680319fc469	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5369c8d7-5ae2-4c30-a9f5-28a0305fd06a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e7c4f6a5-2fb2-4697-a79e-1f2e0b4090c5	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
f0d2bcca-c831-4149-812e-6f180bbc2e83	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4d0666b6-21ac-4db1-a7d7-295dc70b4dfa	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
3a9aa649-6b9d-4d0f-95e3-86b6a4d3efa7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
466acf2a-0c6d-4df2-9534-b03ace0cf4a0	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
80e67a13-fdef-450e-838b-0ac1cd494922	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
0da94353-da75-475d-85ff-9d41324b6721	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
5f713ac2-892e-4e07-8d3f-148b4b3081d0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9658d9b8-0775-44e9-8b6c-1256f8bbe64b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4e345776-57e5-4b34-9066-af69b45200ec	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2b4963c4-7dea-4c97-9a89-488589ee41d2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
572546c2-a420-4856-a0e1-d57e3e4666e9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
66f77746-bd10-49f4-9f61-7420b92424a3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
3a40014d-03d8-49ff-bd40-d63c059d9a62	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
5fd759c7-0375-4f20-856c-5511217e7069	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7691656c-0411-40e6-ac2b-af65301ea1d3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d4ec4a2a-b196-455c-b4c8-f34cde21af26	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d6ece5a0-0e9f-4606-a69f-b8ced3b50d7f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
11cad481-3696-47d6-9005-cf89fe4615b8	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
84ad5a6f-f573-4d11-a4fe-5e5fc6ec28ce	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
76a26545-61f1-4e0b-8a4f-497dbe4e3d8c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
05d8a90d-df08-4b50-ac6b-d25d87a7ca55	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
30c9306e-0391-41ba-9a44-01298807d7aa	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
68f386ab-118c-4619-a459-cf2c2ffcc08b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
396bf302-f604-47f0-b191-304a17c5c2ed	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
95e797cb-4c56-4dfa-a9b9-57d64d28527d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8acfc850-a3f5-4f01-a770-abebfa9aa79f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
03c4daa9-d1a7-44f5-8069-4197a3c44b18	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
55c10f0e-7b40-42cc-bf97-fa3837d88b19	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
600d7208-610d-4c3d-86c7-7f892ce63f98	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
9882a593-e1c9-4ce9-b7b0-0fa801d11247	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3d82c460-370f-419a-9c6f-6a757962f135	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
75ec1197-b6a3-44f4-9d79-0a5b701d02ec	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f3a91a0d-8085-47c8-9a59-181be86ca640	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
9af4ded6-b808-4d79-972d-8a85201861d1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
eb05d5be-0c92-4c3c-a029-163519663dc0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
32ae7485-b628-4b75-bb4e-a490f9b4632e	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
8a1a98f4-4004-4c4f-982a-9e17599330eb	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
85855182-2693-4e7d-997f-27f626ad43ee	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a1113aa4-56ec-4efe-9d55-e4dbdacbe4dc	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
17004354-be03-4677-8c75-5e2e9b4b9346	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0199e1f4-2f93-497e-8ab5-a2c364fcaa45	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
244e8bd7-edc5-4085-ba70-ff14e0327f98	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
c515eb62-d272-481e-b901-3230fa95ce67	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
40f737a6-fada-4d20-a3d2-fe99119495f0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	13:00:00	14:00:00	f	2025-06-26 16:04:19.537149+00
8382ff95-07db-4b6c-85da-03a5ef51c8a5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	14:00:00	15:00:00	f	2025-06-26 16:04:19.537149+00
265108b0-8a78-4ce5-a11d-a009174dfeed	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	15:00:00	16:00:00	f	2025-06-26 16:04:19.537149+00
5ee29b8b-d432-4dbe-8f11-303ba433e79b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	16:00:00	17:00:00	f	2025-06-26 16:04:19.537149+00
ded93158-38cb-462f-9e68-0af966cae111	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	17:00:00	18:00:00	f	2025-06-26 16:04:19.537149+00
b8c6ce2b-4c2f-4856-aa5d-5392d501f14c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	18:00:00	19:00:00	f	2025-06-26 16:04:19.537149+00
cf089630-9db9-4634-88f1-7aa68fe92f7b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	19:00:00	20:00:00	f	2025-06-26 16:04:19.537149+00
5919883e-09a1-4613-9ff9-0b07feb6a298	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
bd1c6947-81e6-4c0a-87fd-d3e13ece6ad4	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
fd894c21-4015-4240-9ce8-6e14ea507206	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
f903e6f4-0ac0-49c8-b725-00bd704e0759	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
d11b659f-1897-4114-9b6e-54dd51771e8a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
25423936-ea5c-4452-a149-392322dee146	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
67ed9f75-19c9-4d4e-a87b-e17010a862ee	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
eaeac97b-617a-4118-9f0f-817a448a94b9	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
aa3b99d0-34ad-4a6f-9398-f5b9aa383656	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
7bd4b65c-2e43-4e01-a1ad-9873cd4e3595	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6dc7f70a-c629-4c59-b28d-56ca1d0bb927	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0a55cab1-1f52-49c4-8184-420f64feffa3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
89584777-2a1c-417a-abe3-aad5aad7075e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ef82a972-defc-4467-b654-cd37d2859808	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
bce616da-ca50-4477-973c-306e05607d84	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d8c934eb-de47-4f5a-9789-520bcffafe26	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
79cd45c8-69a0-4c64-9396-7e9a2798def2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
9b7f97ae-c1ae-4c0d-a7c7-bf28aa42d5cd	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
3203c852-7b2a-4984-b87f-be6eb0ad0ea6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
581b71bd-9d11-4008-a7c5-f555ebac7a32	07771505-6c48-4181-a94a-80816e093af6	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e4fd27c2-9728-4cf1-83b5-e33e8e62f27d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-05	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
569c474d-a7c8-4cf0-956d-2a52b995c6ec	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
453af433-6953-46ac-ad48-5a6f5ec6188c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1a40943c-572a-4911-8a00-265c57e17c78	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
3b5e8a0c-2d22-42aa-b700-67c152159592	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7be9d1f7-70db-4bd5-bbcf-dcd05f7c826a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
22607d1c-2529-4114-b433-149c4b3adada	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
02d558fe-52a9-44d9-be6d-bc2509af752c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
81ea4bf7-38d1-4aab-9aa8-564bb41ec601	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a52051ea-584c-4e6d-8873-05c4baf7453d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
fb257e85-5ae1-4610-837b-a352b82fd0b0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
9eb87bc7-0db8-448d-b10d-8bcff1152c54	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f0adf112-3b6b-46c7-8f05-1c71a2b1c8a1	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d4d7b51b-c60a-48f3-bfd5-d82d08ed7d15	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ff2e132e-6d2f-47dc-a6d9-f853a54fa1a6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
bf9617c0-a291-4de7-bcde-d736923a14d9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
494e6d33-f939-4e7a-aa96-b8a325050829	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d0ab7485-3e88-427a-a6b9-42aa2d1fe11c	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
edde2f5f-fa7b-46dc-bcf6-02f4616199af	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
04495c12-91f2-4060-a9a2-1931571e53c0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4e79ae59-488c-4041-b9c2-d4653737d6ce	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d31f15e6-44e9-46d8-8cc2-b0e6127555df	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3e283d79-cce1-4019-9b4c-bb7efeca5e55	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c6520a25-9687-4d3c-92cd-6a2c3a42f61d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d9a2a36d-c977-4d7d-8359-03c7e8d71c99	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
64f0216d-e570-4893-bab8-1009a8d67be0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9fd8f336-f71e-4b50-95a8-60eac6863d7f	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
b399131f-7605-4243-b63b-ea405ee0b54c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
45fa5d9c-d2e1-49a4-9a55-4490a591b3f4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
28886b0d-99a8-47d2-8513-d71500e51d57	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
68a5de1f-7c84-4afc-a549-a07be3a2a2cd	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
57b2e93b-9b9e-425b-ae00-f765ad7ed0eb	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2d5291c6-1583-4b75-8a56-96e9181536d7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f92e4fa0-141f-4e37-9abf-05ebe28715d5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
4d52683b-4cbe-415e-ab57-637ed85f030a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8ea8940a-3a72-45db-82a5-ce42492fb69c	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2f070344-10f9-469f-8992-30eaf496ac6e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0be67a42-ddf0-488b-9b1e-a02176aa2518	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7dbfaee0-76f8-46d2-a3ad-74018709d0a4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
e3f164b8-daaf-44b7-a150-382dcd633e75	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
66688cd2-6ffb-420d-b3e0-5985ab9a6eb9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
4a36db1b-6a23-4d2a-a131-d19841c86ee9	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
94213443-72a9-4302-963f-8d82383b1da1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6579242c-3a0d-4284-b629-ff896842642f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d28ece80-2654-42d7-891d-8bfa3aaaa900	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d3d300e9-d437-4c6e-bc25-254ffdf6a72d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
9eabce3a-d834-4900-af42-0dfb0edb5400	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8c943521-dcbf-4b7f-a460-87622609c140	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b191fb7c-008e-4d4d-914d-6d7eca535f1d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b6900369-ae45-4614-b5af-af766464f970	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
cf3f15ff-61f5-4607-9105-dd3de5d8c7fc	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8288883d-0d4e-4e7c-aa27-81c6907d15cd	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0a2f7cce-db4a-4203-af37-1bf5bd2e60f7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b1dd7b08-b916-4b3c-8968-8e702b4a28b3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	21:00:00	22:00:00	f	2025-06-26 16:04:19.537149+00
0868295e-69e4-4c78-a56d-bf632dbe0c8d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
e1aff903-fff5-4dcd-adb9-468fc257d478	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	09:00:00	10:00:00	f	2025-06-26 16:04:19.537149+00
9c496a77-c072-46b0-a931-7c5e1077d9c8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	12:00:00	13:00:00	f	2025-06-26 16:04:19.537149+00
7efd2be1-2910-4dec-b1c4-82d0c25f9d5b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	10:00:00	11:00:00	f	2025-06-26 16:04:19.537149+00
1568c6aa-ff9e-4c91-af9b-53835a38e262	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	11:00:00	12:00:00	f	2025-06-26 16:04:19.537149+00
4250887d-e578-4e65-88b4-30e46f2de311	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	13:00:00	14:00:00	f	2025-06-26 16:04:19.537149+00
9c08f043-b061-4ca7-a5ee-77dc7157f4ce	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
da27b6fd-d407-4155-8b83-404c49f836eb	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
41e0e3d6-b9c9-4b87-b533-8cc0a3a78005	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
6ef7fb9a-439c-4792-b920-25948294925b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
af659ac4-a144-4301-ae63-15983af78b78	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e8e97b4a-6f34-439d-987d-1371d4349530	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
755bb39d-4512-4653-be40-e261d0bd8360	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
06fe6358-9027-48d6-b9d6-a9aeea51047f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
bbbbeaa1-2c6c-4ee3-a6af-bea0f743f94a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d40e7e6e-833b-4921-97a2-59ff6c058fb2	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
50d2f4ab-a74d-46ee-81bd-18d0b36847f8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
80b9332e-0e21-4369-a473-3a86da7c6717	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
cff37c4b-e65c-47fe-8816-b195bc515ab8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a6566a31-1efb-4098-b66b-d3a82abea163	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8c8800ad-ea48-4fa5-85c2-f9e8e6fb66fb	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
56888d3f-d6c4-4539-9f16-749ca4596b2b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ee4fce10-dafd-4744-8da9-02704846f0c9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
42a28744-a8e8-4476-a069-7833e087bf10	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f8300181-3bac-43a8-9892-49bd513b2ae6	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
82b53593-c7f9-431a-b24b-b581a79493f0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6dcdc1a8-bc8d-4964-9ddd-977a583798ec	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1a39e814-bdd5-4226-9008-ac029c370f53	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0acb0186-c75e-4849-a1e4-c66aee5d4439	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c223beab-5a05-4f76-b049-849468c0a595	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0817f013-494e-49e0-b6f5-f0dbb499622e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
061d029c-ad24-43ee-bdb3-cedf8275b86b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f2d07c02-4f24-4b68-8101-7508f2b75626	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
086a6518-3ec2-46db-b484-a4f4d590b04d	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d4d43243-9e47-4a75-860f-5576e251ffb9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
be9d31de-da36-4df1-bd61-c0b96a84c6dd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ed0c82ce-b60c-428f-b297-a56d5137fc9b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c1d69036-fe9b-4982-a639-a16ad3946a72	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4cfe7da0-92bd-4ac0-a2be-e64b807fe333	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
6a980ba5-dcab-4a8c-bacb-46c986b6f8e3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
af551302-4af2-4880-a4db-0d34aa55813f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
285a1a81-b1c3-4674-b89f-95c53d353a1f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a53bd5be-d67b-42ee-8d09-24459c616be5	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
6595dfab-2fc4-4d39-9101-02a90e9356e7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
856759d1-e328-4c78-a04d-99be9282c630	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
53b1ad0d-d673-4bdb-8f6a-f6f44aa7040b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
606e845c-0d15-4636-b644-cdb723bf0915	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d6556dd3-212e-4b32-8d9e-4f1c3ad62192	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
60872a82-81b6-429f-badd-94f4e6851612	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
70fee14a-6f0a-4088-a677-a816de09d953	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b09abcb7-432e-4aee-bb29-42f0daaeee3f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e474e3d8-ed21-426b-94ab-f012435b60bc	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d31aa977-da07-4736-b568-73b1f49ee677	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3f828422-850d-4baa-805b-1f4ef374318d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ff0d557a-5d00-416f-b144-1710ed288d77	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
8153ac52-319d-47c7-8cdd-b88bbd977d23	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
1786e183-8faa-4179-a1dd-e1979ab764c5	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
616cb7b3-f372-47f1-9c0b-466e7e67276d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
c1dd141f-cd99-4974-905d-188b11663343	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e43381ee-4ca8-4ab6-b634-00a773fb9c4f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
aefd851d-3798-4302-b904-fef101e8be56	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
eca9ac62-a318-472b-9db9-f723bbe96999	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
51581a43-9bb6-4608-893b-91fd646db2c1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4327a4ac-38a7-4bb4-834f-6111fa70ab90	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3c84986f-fa60-44b3-96c7-7100fb81bfce	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
52ed0833-7d1b-4b51-aa78-d76ca401593b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0c7df340-6697-427d-b014-992d065999d3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3b46d327-5d4b-42a7-aa14-f0172e093f29	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
799386ef-d9c0-4d78-8d92-fb6e0e4b83f7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
7e933688-0b9e-490d-95d7-3fdfb0d6c038	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
07e454ac-402e-4aaf-87a3-c82d2ec39b2b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
578fc99c-68c0-4575-8bcc-cd2f262eda44	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
32057a33-a27c-4533-955e-5b9ed8ada87c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2ffe28c4-e401-430a-bd33-9b148f983a3f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
26e51ab2-7c7d-4ee8-a448-cd99c31b5335	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
34495b03-8d31-4dae-ab4c-456013f8e93d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
9fc89c1d-40af-4c02-b279-8790b3ade8af	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2590275a-df4e-441a-b5d9-7f763ed6b403	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7df5876e-88ae-41a0-bf49-2eb02f6e3a7f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
195713e4-891f-45f8-8ae4-05eb96b5187f	07771505-6c48-4181-a94a-80816e093af6	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f6e4d02f-5f08-48f9-b440-3e65c6a628e8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	15:00:00	16:00:00	f	2025-06-26 16:04:19.537149+00
497f49ea-89e3-4906-b722-3e19db8e37ea	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	16:00:00	17:00:00	f	2025-06-26 16:04:19.537149+00
395a132a-3d85-4651-be7a-a327a2d7ce75	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	17:00:00	18:00:00	f	2025-06-26 16:04:19.537149+00
c8808fe1-c518-411b-912c-2e55c6c3d413	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	18:00:00	19:00:00	f	2025-06-26 16:04:19.537149+00
c3806abf-8cc1-4725-8bf0-1784cc7f0abc	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	19:00:00	20:00:00	f	2025-06-26 16:04:19.537149+00
f829043e-24d7-4f48-9ce8-a0e7f3f2340e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	20:00:00	21:00:00	f	2025-06-26 16:04:19.537149+00
ab67cde8-b516-41e6-a942-f30e3d288f14	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-06	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
73d5c007-f0a7-4e48-805f-895748afeb9a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
99f2f63a-b427-42ad-8f34-a4d57537c914	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a1db3a4f-e650-4a97-9bd8-85f4fbecab53	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
2169a5dd-cab7-41ed-b261-b8c0fe5c099a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e51e3e89-afc7-41a8-9f46-0cdac6826324	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
eb2267a0-2b2d-4449-a1b6-65a040fcfecb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
10e427cb-8a5b-408a-ab14-9cf91262e8d4	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0c8674ec-c825-45b8-bd24-4c3cfb25dfd7	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a2060cb8-0027-4d84-9efd-b9755a9919c8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e75ac805-a3a5-41a1-a413-fe28df9111bb	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
899c37c2-5723-49f7-9424-f4708607cf50	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e422026e-9e80-44c1-bd41-14b359ddd134	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
83bccb37-71bc-4f9d-97e6-32259727d664	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
2a91e3ca-a961-4602-bd55-4a91a47622db	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
810d67b3-3e7b-48da-8a90-84c11bce8c49	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
23466265-4c80-4cbd-aaeb-8f611dfa0846	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3e4f3264-de19-4fa2-987b-f73f6eafa45d	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
4a19fcca-68fe-4f84-a12b-548300d7c4bd	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
61a8dfb7-656d-4ce3-93f9-60f9d6dcc81e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e6daf31b-850b-4ae8-bb51-21e355126cec	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
194e2e7c-8b27-4a16-8833-2d309a42e565	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a9a64ae3-b2b8-41aa-bf19-796000c0fa6f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d971616f-b77e-4225-9484-b10c28f49856	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e8ddc07c-3133-4d46-9c40-7aa26013ab00	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a7cd80ab-af03-4e94-be6d-31c97e16838b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
90e54af5-7ec1-496e-b7e5-ebbe2b1a8fa2	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
dd6dedd5-2326-4a8b-af47-999949fd5e76	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0ba414f6-72f6-4606-8900-5817e654c38e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
4b460e81-fc46-430a-be7f-ad542595ca46	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d880fb1a-688e-4ae5-9f41-06045693effc	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
89b352da-7a92-45e5-a015-3d4e39cc0f7c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3993ee16-01e6-4bb6-b2c8-874fe7f47064	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
008fc0a0-3b8a-4a57-837a-6ea1fe3cc2ed	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f10c22e3-255d-4a17-8468-0e190f3a848f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3b3502c7-f08e-4d6d-9ef7-fecb54a79e29	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e0b40b23-374b-4727-b7c2-585efbf5e467	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
fc5dbdbf-b9a2-4994-8f51-8411d6a838fd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
9c7d1f51-3180-40ed-9e7b-52eb894f6d10	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
26dfdcbb-203a-41e2-828b-64c65f16eaac	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
eddab213-2fac-4a57-a8cc-872dcdf17178	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0f2e83f2-b04b-4793-bf22-e304ee300403	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c7c12e30-d63f-4d17-9c66-fd914fb1eb1c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8c8cd094-737f-4703-a478-109c68ff8554	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
94a1f381-790e-490b-bec7-6a4f12dd7849	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6f67f317-9e8d-4c10-83bb-86ac6fd43ea8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
608f25f6-3907-408a-8399-ae40aa69a907	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
44be7e4a-6e2b-4706-a347-49ef6fcd355d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
208bf370-abb8-4bbb-9f0c-6a2a0bdf2c04	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e9252a22-b4fa-45b0-80c1-f744ebb3a7a8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b5e2a861-0009-453e-bdba-54d8cfb1656b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
632b8802-9090-40a4-aaa1-8d0af3012cc8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
5f1e120e-53f3-4418-8401-7bda5a4d6c1e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b4c8de68-3e33-45bb-87a4-12c6c759eea1	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0ed2c987-49bc-4768-bc69-8ca2817a4945	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2226e824-1281-4be3-9bc5-61524e6c5866	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
376a3904-8e82-4814-9ac0-9b87f44f1029	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
583c1885-f08a-454e-8dd7-df954cb088c5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2ba82213-80b5-4017-8da1-f500fc07bd82	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e5413021-7f56-44dc-b7d3-6566fa212091	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b8839af4-839b-4fc2-9de1-ced188a60117	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ea48a65d-945c-449b-8b0e-3fd33eb87870	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
f8c68b53-05f0-4cfe-b9e8-38d94535edf5	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
14103579-db11-4b40-891a-62b7724fd138	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
0d6b7dc9-95a0-4e98-b16d-a3922329b05b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ba25e1c8-5582-4ef0-8ac8-e3756af7e531	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c881b60b-f1aa-4d6a-a216-624d518e5a40	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c412233a-6926-4bda-b52a-05efa88d0902	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
27c582c7-6420-4549-80e9-8d88437a8b2f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
057b7c0f-4e9f-4763-bc4b-41dc279c6ddf	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ef86fa1e-4835-46af-8b3e-fb63873aa546	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
11b33c38-2250-41ca-8c1f-37feb8f491d2	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
aae1b9ef-aeb2-4453-be5d-b40c59ad03f8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7a4895e0-bfa1-471d-912d-aa9f966030af	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	09:00:00	10:00:00	f	2025-06-26 16:04:19.537149+00
70b29353-e393-4303-af6b-9b53aaf502c2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	10:00:00	11:00:00	f	2025-06-26 16:04:19.537149+00
9625d60e-8a35-47c2-9795-d4a4e5f5013f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	11:00:00	12:00:00	f	2025-06-26 16:04:19.537149+00
40157ee5-aa2e-4735-9c35-d45f670775fc	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	12:00:00	13:00:00	f	2025-06-26 16:04:19.537149+00
8512a512-39bc-43a9-97cd-44d6197d18b7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	13:00:00	14:00:00	f	2025-06-26 16:04:19.537149+00
7829420b-6fe7-4cd4-b64d-370416ab1895	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	14:00:00	15:00:00	f	2025-06-26 16:04:19.537149+00
e56be7b2-cf9b-4af0-a03f-14ec8dcebe21	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	15:00:00	16:00:00	f	2025-06-26 16:04:19.537149+00
0eae118b-ecdc-4175-a89a-88544615f1c5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4ac0a4ba-78d3-467d-9670-57e3ecb49812	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c9403eb6-82d7-4daf-8cfa-08d3a8e2bee5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7b65c098-b046-4515-aa1d-c2ba66e18b5f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
229c552d-6957-4ee5-b630-1cd8e4097f01	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1cce6bca-418d-41fe-8c93-412b615abc92	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
20b4099c-7316-46b3-9168-578c36851886	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b9bd50ee-f94a-4279-aa97-1b1b9d92f591	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
be3fc834-884e-4358-9947-f4ce0a71860d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
276b9870-6ee6-46a7-8a31-373cbf972439	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f644210f-ed7e-4444-bf3b-6e4db3176754	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c4c78251-0d78-4a6f-9bc4-22e2a76f67a7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
248f471d-4318-4d4f-b431-05b78ad1c22b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
25f34b98-d724-4dac-a662-03782182d8eb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e00d4c50-17d5-47de-beac-97300be771ca	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5dce848a-18c2-4cdb-bb35-07cd1822081e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
0f930895-465a-4932-bec7-ef0cd5bd0b58	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
cd4576e1-ac11-40de-b476-afc222a8faf5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c9d3e8af-cd27-4250-9825-23b74e0e020e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
29842b5a-0dfc-4ea9-b328-992b7f95aca4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
db2f0191-7948-4a0f-8150-ea77ad296697	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
678d398b-01f5-485e-b75a-b113dae83211	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
9615cb6b-afdc-46ed-9be5-048b0a345ccb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
77cbcf33-d430-45c7-b180-b7bde3098c25	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
10cb1ce3-0aba-40a7-a2eb-35dd6f0c8569	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f3ed3244-9cc9-497d-8886-6b6fcdda9c03	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c21a8e90-4c3e-43f9-9310-a932098d1642	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
92f530ae-593d-4e02-b68c-6881a4af72be	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4637eb02-8f93-46e2-8fb2-c69ee30d1957	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5d4070de-8748-4571-bc4d-5a6733161126	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
cd1edd54-0acf-4bb6-9b1d-c19f29ced845	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
2ec019fb-1335-4fe0-8d01-5a4fbc22714f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ec5a848b-8d08-44a2-b580-14ee64867078	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
acd3ff7a-7a48-48d2-94f6-b38fc28e2c74	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7b84af40-a40f-48e2-9928-6ed6d5a92443	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
830b1140-7d68-4be4-9847-7dbebe269f7e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
c9deff03-befc-48e5-950e-232eded68809	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ec46bbb4-2e9f-4488-bd75-d9b1fe5b3de4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
5ab98aad-8612-4692-a55e-84e8db87d6bd	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0f38c738-5637-4465-a802-82d80a53d894	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
23db4285-d6de-46e8-a724-267163a37989	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9ed5f609-acb5-4aaa-ba0b-09227e61691b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8407c459-ab96-4333-ab91-332a05b09b1d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
1c8ff9ce-005b-4dab-87fb-99bdec9eb9ae	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
cf036e8d-1da2-4d9f-83d6-8934aecaeae8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
1b88dcb4-07d0-418e-b07a-bee3569390ce	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
51839a8b-6cbf-4c98-8713-68f0dc77510e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a69eede5-f590-4e22-961f-af13b0afc47d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
97f898e9-3403-483e-b23f-673225d7742a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
46e7d1e7-edc3-4706-9441-aebde5bb8473	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2772922e-1c3f-45cb-af13-0e4affa90eeb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a665bd51-3e66-4db1-a9c5-77a86e9137e9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
8021ba16-69f9-4c46-a085-e5bce6097802	07771505-6c48-4181-a94a-80816e093af6	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
01a0297f-ed7f-4612-95ee-147f8ea67b16	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-07	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
dc3cd743-27f4-49ac-90e6-70fb6118a02f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0fc80624-a2bf-4288-b6dc-93fee5e9ad3d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
74b4d5fb-7917-49b2-bb8e-c0e1eac72f54	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
dce4f3b5-e1cf-4593-ac35-089ed28fb865	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e705a6d2-d17c-46b3-ba0f-45c4e6a7dbb1	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b8db83b6-bff5-418c-a4d2-3b578cdde4ca	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
8af54b03-1c8d-44ef-a0e1-4e7e339de6ec	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1e734162-48d9-49cf-b8a3-f5aeb7ac60d9	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
07ad339b-9428-437b-92a5-1e2ffbfc4b9f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
78a0e6fa-2b62-46e9-bbba-4416d37caea1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
386b9764-ec7c-424c-8d6e-e78bcdd5cc83	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
6dc7fdf9-d0d1-465d-b297-aa0cd280d0d5	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
9fb9c97e-79bc-45df-9bb1-801928af802a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
2bd8e10a-f391-44c5-8f11-1ffca1604257	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
97646b22-d551-47eb-947c-f5121d25e730	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b99c0b4b-d6d2-44f5-8b9f-87c84e08666b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
96ff3466-894f-4fca-b6d6-78d987f8a0d5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
553e2998-7788-4a74-843f-6d4af597ad74	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ced67a4b-7fe8-4633-a212-66cf1ce54091	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d02559e6-7b26-4925-965f-eb1c4ed7970f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
211461c9-8e44-43df-a92d-fdc311d37a1a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	16:00:00	17:00:00	f	2025-06-26 16:04:19.537149+00
3e38702b-2782-45c0-82e8-a489d485bebb	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	17:00:00	18:00:00	f	2025-06-26 16:04:19.537149+00
36eb1b96-7067-4cf1-82da-125cfa53ae43	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	18:00:00	19:00:00	f	2025-06-26 16:04:19.537149+00
1cc6194d-0b7d-4ffe-a7a0-afc8d8c3bc01	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	19:00:00	20:00:00	f	2025-06-26 16:04:19.537149+00
65d8a620-a382-4a42-bac8-a9899653e3d4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	20:00:00	21:00:00	f	2025-06-26 16:04:19.537149+00
4263f1f8-d01d-4762-89d5-bd5eaba75ecd	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	21:00:00	22:00:00	f	2025-06-26 16:04:19.537149+00
0ae499df-6065-4ffd-b1ee-781017323843	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f56a5239-575f-4f89-a5cf-3401105cf90e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e7c72fe9-fa37-4858-b35c-0ee05c0c9fbc	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0c345a43-0764-4add-9163-063b1ed84930	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
14eb2900-061d-4cf2-b11d-da0064df153e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
482c534f-8697-4b70-ba3a-14568e017179	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
33017801-0b6d-45a5-8175-897e58404e04	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
b219e6ca-c066-492f-9cbf-e6c382ad5605	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ab4b1a8f-f565-4929-b920-f50942631d01	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
1fb436a3-3d08-4cd6-bb07-67863da60dc6	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
62e5952b-c335-49dd-85f5-5924ee50e796	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
fb1ddbe7-c63c-4f10-9f40-f77c9177c302	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
bd162a90-d12b-45eb-b469-af72bb762dfb	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d40ec5fc-cf4c-4995-993a-2eaff5cc07e2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
54fb848b-3de5-428b-9ae9-873aed9ff2ca	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
94710b64-1b39-4406-9c9d-70d485a39210	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f3630a43-e018-4801-a0e3-e49d31b6d6fc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
cae2f2f1-8b62-471c-b731-b8bed39986f8	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f4e0e6e5-4f87-4a4c-bd61-998f7875f429	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
55462181-b2be-4a90-8112-ebce00c44520	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3113b429-3f5b-4f1c-b53f-f38627641b0e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
68bad003-6bd1-4a08-80bc-e924bef9011b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7253e0f5-c5f1-4ead-b1ce-62046ce22784	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f8b1db43-91bd-4802-a594-9de73d460177	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8a7f6ecf-c36c-48d9-836a-0849fbe0f049	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
13492592-90d3-483f-83fb-d85bc55a9157	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
546339e2-9830-4aca-be4c-23e90ac05f53	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
be7674f6-30e9-407a-ab24-82678194af10	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
e5acdbf1-c79d-4d3d-a313-19192cd901cc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
00128573-f126-4891-aeee-a35523fbd395	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
ef3f2e4a-f6aa-4c09-977f-9b19fe1f3dc2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
d8eb60d2-bbe1-4e09-a425-c3efe6b246af	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b1371517-345d-46cf-a3b5-634f3fcd52c5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
aa377738-5a61-4035-b3d5-21f4e1c61d79	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6252a6ef-8f55-41bb-a69b-2e0bf1e0b573	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2657b12e-eee1-4170-97b1-969364fa474b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
99cd8ab5-2293-4aad-b60b-95ac85c90473	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e378868c-fdbc-406a-9b8c-dc86143a0993	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
38513f6c-7877-4d02-930f-d8fa1235186e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b53ad28e-64de-4ab9-ac7b-703c97980d03	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
466de7b6-16c7-43c4-8295-470226c63f54	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d4c9d9f6-10c1-4e2e-8a36-a8dbb76d1ed5	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
6af836cb-4ae6-4ed5-b7ba-fcd35c8513a4	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9efdc5c1-dc47-42a5-a906-7dca86799af5	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
8849b2a3-c644-48cd-9897-544c237c181b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4423de9c-759f-43cd-bcec-2cccbf40ec99	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
03d25676-8162-48ee-b676-2f016db1f295	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
cc8a5df4-2dc3-4fba-91b9-7808ab4f9aaa	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3bf9bbe4-e4ac-402a-870b-ecac1dc6160b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
65a8e4c3-67ab-41dd-9cd6-184e9249f332	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2e264eb0-a7c1-4245-a717-a1562caae11d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6ffb213e-6b27-4049-857e-2f6c237efa0f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
58e8b618-b3a2-46ce-b5c1-c7f27d9aed51	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9fa29312-f76d-496d-9e7b-8260cdb91ff8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ef27a35a-c8b1-427b-94a4-4fd5c416ca56	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7f112f41-fa7d-4151-81ef-dc31eb4ff995	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
de1910da-0fea-4abb-a6d6-1e75c5926d28	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
5da1937d-3575-45d4-942b-bfeb02fdf281	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
eb170120-b1a8-4e42-8999-baa395fefcfb	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
0ff2058c-f333-4c3b-9444-925de3ed2e74	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
23cc6e1c-b481-498a-a8b2-6bd5be763842	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c3934e95-57eb-431b-ac8b-85ca8b3743ff	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
382b0627-d821-49fb-a5ee-75728cd6467d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
093653b2-1573-488a-aabd-1a0db8d421af	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d7854c2a-0213-42fd-8965-862f383c92de	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
87eb6199-ea9d-4b55-8fb8-ff07d1e5af6b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
6ce3dec4-fded-4f7c-a617-16f8ffde22b7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f6df9e90-7434-42f2-8dcd-4b6b99a84c2c	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ebfb2deb-5a18-4c90-9423-264e97642406	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b65f9e49-7c0c-4bf6-bf2e-8288444cbe86	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
59aee0fb-c064-4067-90ae-fa52be578b84	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
09350ab7-247d-45ea-b60e-283c9d696a2f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5f53eb14-5eab-4b91-8999-48a43695fca1	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
98b847e7-b6ff-41f8-b37b-e6465859fe82	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b69938e5-537d-48f3-b95a-e6706d695923	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1c6a22ed-066a-4922-aa2c-9ba3bee25355	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
6e47364e-c723-41af-9c52-2f62a7e798c5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d91f2160-7ac2-45c3-9a7a-149495442277	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a88d9066-b25e-4ea3-9a86-0524749fbd5d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
92f69cda-4af0-403c-b4b2-2a10fc2afc10	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
0f791c01-3bf3-4b6c-b8e3-b07938547358	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
65ec64a5-0397-4c9f-a28e-a4aaacbb4db4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c184ba29-d3e9-4ca9-ad6b-98a41e644548	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3ab8d3bd-0b8b-41dc-a471-73bcf016433a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
0a41834f-6656-4d77-a71c-0869b132e8d2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b13a4d11-8140-4f35-9747-f1be33bb5227	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
02697c1f-2218-4e42-9054-494284d746ed	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
6f7fdd5e-d667-4771-aa12-d67da203ed30	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d45967ca-502c-4830-89ba-54864ed98a90	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a7c2947d-42fc-45c0-88d3-2adec8963bdf	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
deb5d5df-8126-4cc3-b6c2-b799ff99712e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
38be5364-5814-42ef-bda4-845a52f8ffe6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4f549cca-7cb8-446c-b40e-4999b5278502	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a3e8f6e2-2dea-47fa-a827-cc59e0c9b32a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b97da405-8ae6-4af4-b168-5861a28d6e1a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
1a4d9f06-301a-4ad8-973e-61b9f9891e98	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
34240ef8-4793-4d09-bda3-d64c85bc6420	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
425934f3-9d9d-4c24-a1d9-15f8bcb43755	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
31df05df-efed-4324-a128-ba91f3d99b68	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5c8100e8-792c-4f98-b023-617c451afcff	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
57cfc401-1d8c-4fa9-ba35-a7c227e85fac	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e4fb9fe4-b67a-407b-aa95-6173abe93890	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
febf11cf-f436-43ad-8fa6-cee5ad010990	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6f2c4699-9074-4cdc-ae2e-f6732b22b494	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4cad6196-f0b8-49b4-a948-630d874294a2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
48b3ecd7-eae8-44b6-b5c1-288354af7408	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
36735e39-0006-4e03-87f4-0afa7fedafda	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
141144eb-e628-4b11-b4bb-341a385cb239	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0bcba261-d42c-43bb-9b0d-c26464c4bb70	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4311d30a-f2f7-45b9-8a76-1738a8f59fc9	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7a183663-139c-421f-846b-60c473bb32da	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b3ab0e70-97aa-4181-b161-dd58e00f98bf	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
1e2e75b1-b829-47d2-bcdc-3e333d9fb418	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
5196936c-6c8a-4f25-be56-441a0f73ab72	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4b0ec3e7-d7e3-4ce5-b995-80e6ee64df02	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2ee5175e-3538-441d-99a9-88bbefa36a2a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
36afbfbe-1eb5-4f6b-90b5-0b2035280a3e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c0d0a4c4-d4b0-4905-bf5d-4348aa694863	07771505-6c48-4181-a94a-80816e093af6	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
943d3207-7dc4-4285-b506-0a1f703c96d1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-08	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ec2331c7-5a67-494c-98ab-400bad6dee0e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
43132f2c-1e89-4f52-a2a3-faa2063a11c6	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
8edb9632-0c6b-4351-a827-13624dee8179	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
fd1ee95c-9369-4bfe-8c9e-7b4454a40ca1	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ab53a2ab-b822-481c-ba6b-97891ef833a7	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
fa108c39-20a7-40da-980e-d35a3ed241f3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d83da76e-d9f1-4683-9653-e0d429a10b94	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
67a9a58b-ffab-4e81-8018-108220806c30	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
13b6893a-57ba-46a6-8370-2351ee868c23	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d149e542-78dc-4e9e-8627-1150da2a1154	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
99850b07-175f-4659-9e1f-6bd3740bcdcb	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
fc07a9eb-05e4-416e-a243-c7412a6bafb6	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d24e2848-81f5-49e3-b716-6264211a1aaa	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e2cd2f16-7cc8-491c-9895-8dbfcf3064f2	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8e654ba2-fe72-45f0-8f1f-157d662b6fe0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8f39b3ec-8e3a-4b4b-8b0d-765d4482ddf2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d8b3371f-38de-4216-af20-d7f66416e8c1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7d109a1d-111e-4306-8a11-f58112cf7ad5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
17afb36f-d57f-4414-9c75-e984af202554	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f01d7ebe-5cbe-46cd-b46e-db5e79f3fb58	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b13fc53f-f12e-4cff-bd19-d16335177927	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d9e2eb8d-9b24-44b6-bb51-4e7c35ad715b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
bb9c0f74-7c3a-42c2-9bb1-cc85ccaf10e3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ad563830-43a8-4cae-911d-147cfeeba5c0	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0b9da22c-61a7-4894-aec6-c2102c752760	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
cf486ddf-1600-4bfd-8455-7100686bbfd6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
70db07e3-9839-47d9-a55a-4828528496fb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
898109d0-252b-40b4-a58f-e67045143351	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0189800e-4d1f-4875-bd54-370ef44418ad	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2a6834b4-399c-4fb8-94fb-06c01ee92d13	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6abf79d1-8768-4e04-addf-437cb2176d9d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6c8df3c4-3078-4fec-8832-45c111529539	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e2eec7f8-7e14-4f0b-b7c6-91451630a6bf	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d463702f-a24e-47b4-88b7-5e0170a87eb3	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
804980b8-73aa-49a8-ac06-3c64b98f24c7	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6f1e1904-ef4f-415b-bc7a-02093c268dda	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f09b9ac5-139e-405b-b1c4-95e262d7d757	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8a3aeda7-b4fd-40cb-b208-557daa1fb400	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c9e75750-7e7d-49d8-aa38-7c036a02a1b7	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
eb2ccdd0-3597-42f1-bd05-e911aedeb736	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e98dae28-72b3-4e58-931f-3209afacf981	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a36acd39-7410-4d24-bcc6-851cca42746d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a9fcd6bd-3932-4dbe-a64a-7997df632588	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
01b4ec72-9e92-42d7-a095-19d1749098d2	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7b4d6697-e217-4724-8aec-12b38355a047	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7a4ce55d-a87d-4434-b726-ad000927a088	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
91aa25c2-d156-4d22-8b6e-c23541f41231	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
add0717c-5c3a-45e2-9c52-80c6bb828f14	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
97a873b2-7e6c-4678-ad8a-e831d775a5ca	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
bda313c4-8d07-4455-ace5-07c520010cee	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
54d6fe28-c479-4e72-833f-da831ed94b4d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a8210722-707a-4c14-9767-0092644bbf2c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
efbf57f4-1180-4f1f-8c3f-34fff158cbba	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
59ae466a-0ecd-4586-9f62-c8d46114d028	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
00b7d630-b4b1-4c5f-998e-187f988fb858	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
99235281-7faa-4441-94a8-06aea67b8adb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6ae58bbd-0253-4cac-8198-0ea5c2fe294a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0a319cfb-8813-476e-9004-731c1afeacab	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
16a9eb9c-cf1b-41db-99ef-29093e6d23be	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2197aa61-5d2e-41da-b934-7f1143349af9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
dbfa5869-693c-4c81-8499-97518861d651	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b8668e26-7119-43ed-90b5-f9e3e4badaf7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
21a7982b-93a9-4edc-b846-577bab8137c1	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a661d7f4-fca7-45b4-946c-80195fd2ac10	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
246fdb97-873b-4f62-91b1-a15c888cd64f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
27672132-d587-4b23-b0b9-467a4fff8668	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
6bacaeb9-20e4-4550-b3d4-6ae640f91c06	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
daf1f7c6-c251-4896-97c1-4d35cac6163c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a1acb035-d686-4095-8051-6dd77b12aefd	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
902d7114-f464-4fff-83e7-713181392986	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
da7e095e-b0f9-4c80-9e17-d3ad82730733	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
d15fe33e-9786-4296-b231-b9be2b8cb015	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e617d192-cbdb-4ee8-907f-b1baaa37cfc6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2f4c1a51-669b-4963-8e97-4ea70d5dea58	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
05069961-c2a7-49cb-9d75-448721196b54	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
89a64534-2124-4fc4-939d-fd99e4db945d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
29a73508-1a92-4cea-b108-1bbe8ced7c16	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ab0aa1f5-7cb2-44ce-9511-fe3b80709690	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
1c2b41a1-f066-467a-a6b8-d5833e97ed81	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
898a8217-b772-42f2-a3f0-1d6469450174	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a820f102-996b-4d09-9443-643b0f89e770	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d7ddbb7e-ec5f-4632-b75f-3798b64a9f70	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a0ee6234-8e6b-48b6-bcb3-3bc1f7d0a252	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0e3d389d-d09c-484c-bde3-2321f3394983	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d18ee8b0-3f7e-4c1d-a9dc-5d64dee1997d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7aa3497f-b037-45ec-a1c3-8b993915356c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4e788c38-0de4-49ab-9dca-2fd5de0478ab	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
76275342-83e0-4e12-b942-8b22d5da50b8	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f825e4ca-0378-40c3-95d4-08d6246c478b	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ee304249-cd7d-4762-8142-248165718cbc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
81ff3a8c-1342-4ddd-af7d-1d2d3ab9c33a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ac9be292-55fa-416a-a488-ef0342b3c3b4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9b165ada-af81-4a3e-8da7-e8819eeca918	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a4cc9fc1-3c61-4cde-a9b2-690adf7b66c7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
be887d43-f722-449d-9f68-1da24b1f3a5e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a624b14f-ecdf-4445-97de-4b170f9bccfe	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
18466d0c-4cf5-420b-91be-507a2b4863cf	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
928f17f8-6cce-4f8f-a064-d0e89815d64f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
02bcd38d-f7f1-44e7-bc62-b4d5de488772	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
2f6a6ba0-b75e-401f-aad7-61dba7a83275	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
99fea04b-f1a8-49d4-a805-2a5610078bdb	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d971806d-7010-4e41-b3bc-34aea3f28e12	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
92ecad4b-a862-489d-869c-d67cdbe4e2b9	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5b1a1926-7b9d-4aec-b9bc-8cd51163ba96	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
01bdd283-9e54-49f3-b074-3847402be206	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
bcf19065-528b-4c3e-bfdf-a33af23b9b18	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e4e0fe51-a53f-418f-91e5-4a2981564a4a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3c4f783c-e440-4ab8-90ac-f51148dc96fe	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
01413b16-eb34-4587-9270-28b8804aa804	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
1f2b2301-8a0f-44c7-b4be-c721634766d6	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
02c1440c-52db-454a-a6f1-378bce4a4ea9	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7e97e3c1-f394-4697-8a12-6afb992f35c0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
792fd31b-e294-48b4-8194-eb166ac1c079	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
89ca75f0-bc33-4111-9904-967134f3f846	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
36510973-6148-4c0f-bdba-212e1ae9cc7b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
fb8fa32a-4a0e-4016-b4cc-a35da2ae2b09	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
76eb3426-b2f9-4be5-8662-fafb473833e2	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
6bdb1de9-3e6a-470f-a001-d9f1e551fd10	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
f48f3972-8a46-4e77-8fa1-384cfd8501ec	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
8047b2ac-dd6b-4142-81e0-81209f027e47	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
763e82ae-0c64-4d97-80b3-4823dfb50ca7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
431ac8d2-f009-4cf4-b9d0-9259a08905ae	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
72edf7b3-2574-4e4f-9043-2588d3ea83fc	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
88483374-a770-4e9d-bd05-5f451f43a0a3	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ef774f3a-b011-4f7d-a6a6-b7c27dbc215b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
23527b85-1cc8-4a70-89a9-06e9973383c7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
5c35a2a9-c0cf-4a92-8de0-9b91e6c822cb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ff5f6c01-27c8-4f8e-a6b6-a48e79a44334	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a68dc169-6c39-4436-a71f-1029daea203b	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
465a649b-207d-4ea6-ae15-4b3bc0037a3c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
df237f7d-baa3-445f-9f51-ce572182eadf	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6ca5b6e4-d3da-45cb-9228-0e24916a6b01	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f92262a3-a9bc-4688-a69b-55f606cb25ab	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
5e920480-6b39-4e4e-b1b7-35ed25abd6b8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ddfacc49-e2d8-4e43-b038-797f8181c48d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e7d72fed-8cf7-472c-b5d1-1136236918da	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d91a46c8-8483-42c5-a7bc-544419bb2096	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
bf672ef9-9674-40ee-801d-f8ddf4b6f269	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
3cbefef2-43a2-4e29-8cd5-3dfa174d95ec	07771505-6c48-4181-a94a-80816e093af6	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
3039e7bc-3f3d-4678-b3ca-60bc67876517	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-09	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ab8199df-c0ff-4702-beab-dd0c9980bd7c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1992552c-af89-4906-a2ab-b30166418b52	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
bce7eb54-e4a8-4f6e-bc11-05e1e55c6291	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e9e74df5-a433-4a1f-9dc9-4ed5d299e373	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
511a723e-95ca-463f-8250-f8b8011bd818	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
cbc9deff-dde5-4f0e-8450-454ff4c45efe	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
8b2bd9fd-b50f-4a5c-bc3d-860eb4278570	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
4b188a84-f482-489e-83dd-1956c464773c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b22088ce-5919-4ec4-b913-2629b094b184	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
5f2d28b3-111c-48e9-b345-cbfb4ed2428b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7cad5cf0-f2b0-44bd-b796-57a12b6a7d21	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3ce7a1e3-e76d-4a21-991d-1d81e660f1e4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5dac137f-0613-4a5a-97e0-fe429943d3bb	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c8cdf135-2ba7-47be-a062-e59cbd7ca18b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
55bf38d1-e48b-4060-9b27-0b5e010d76b0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
607e5a74-3ad9-45be-a42e-396117854075	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
91850ab7-e9c9-4b78-84df-89fed74cd216	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d734b71b-86fb-489b-a4b6-113a1cf0e6f4	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
fc38452b-43c7-403f-92a1-dbd48069ecb1	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
bbbb94d2-f148-4b85-bd44-4f3b1b980ea3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8a697bad-3f0b-4eb8-83ec-d1ac007aaf09	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3b680fa2-77ee-4cd2-bd1c-9418d284b428	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
21b1ecda-b19a-4a4f-bd51-1533fa1bf461	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6571ca1b-b3da-496c-a850-7343371c584b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
427ad2e9-4394-4356-a147-94858a95d688	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
598a1c90-51b0-411c-ba06-327ee28fd193	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
386466d1-38a3-4b64-b59c-1561870b02ac	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
183bbe3d-431a-4553-8edf-3c5329f98e86	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9392511d-28fc-4768-848d-b1c3a445dc17	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
99285b40-ea23-4cec-9f9d-7400b1c8a513	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2796f4fd-a3b5-4cf2-b74d-9e2bef786f03	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
30ca9567-6193-47fe-aa01-e676594bedfa	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8d8eefa5-1eed-4d1c-88db-013f48a102c2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7189af95-f32c-4e5a-a401-911500940b10	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3b8f4641-2219-4635-bb5e-94abbba3f599	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9451e41f-ed61-466d-a601-c9c61f62308a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b1e8a984-86b1-4df5-a2cf-09bdc441b30d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3894cb6a-c6a0-42e9-9eda-7da5f5008f8c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d47cd61d-4319-4685-ac14-96c231dbfc0b	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0409261e-e2da-49fb-8fab-c9b3f238cea4	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
a6993528-509b-4f23-9b75-83f3af47fbba	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8bc8639e-5af7-4189-b08b-3a02c81ced71	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
127cba14-b642-4a86-addb-b492dcc476e5	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
fad80f34-350c-4ec5-b1cc-1ec5f08aa233	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
cecef130-4911-4e1e-94ba-c4bd10ea2f71	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
58bd6ecc-b60d-47e0-b31f-b711da78e458	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
cb01838d-bf4f-4b25-883f-1d22012af361	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
43b5dc7b-5f09-449f-a33a-d2344a918432	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
cfc1efdb-e00e-4646-b070-7da38529e15b	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
5b2608a1-e1b8-447a-8a99-4666d22741f7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
34585c40-8b8a-4224-ba06-8cfa3f8ef7fd	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
74f3ac03-4463-413d-8b53-6d003f1bb3b0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2d1e3bea-16ea-465a-b769-9c490b36d8be	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
5ccdc555-394d-499d-a4dc-405fb64b8305	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
50a6219d-a60f-4b7d-b5b6-0b4da34ab61e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
5a1c0336-5f78-4886-aceb-c9e2c0829803	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a802a5be-d020-49aa-a80c-47dd4a35cb6d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
427f78bd-187c-4d0b-9d05-6e6398a6f789	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
33eb0d39-abb0-4db3-afe2-2e756e2c951f	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
915ce921-72c0-4fc8-baef-bb727bc2be40	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
4f43ab83-37dc-42cc-81aa-db45ab5139ec	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
697cd41d-6e29-4900-8001-9c3dc6590acd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
fd30e5b1-6902-4145-b372-e3170ce9783b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
31216a1a-03a6-40e8-bed2-4b140fc3f7ab	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
de45750e-b4df-40cd-b7f9-9be810843cd5	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9518ac64-7b2b-41df-b87c-4f438d3d9533	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
8b90a974-4832-4a56-9be3-6f53ed6ed542	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
11cd6bb0-10a2-45ed-a7c8-78e1c1ece425	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
344babb4-102d-4468-a40c-e8deab57b51d	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
dcde3843-84f7-4b66-a169-50398ab91298	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
433c532a-fbe9-468a-a552-2db25d8d91cb	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
599956da-d679-4413-8f82-34ed4e0f78fc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
dd6112fe-e736-442d-90c3-a3f813b89d37	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
3408a7a7-c05e-49cb-a8d2-f53c3f284217	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7574aada-8b1a-4fc4-a040-eff02dfd1fcd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
3603e0de-a9b5-48cf-b3de-74d05620fbf5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
71b575d2-b61c-40a8-a6a5-6727b07e2749	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9b3df5c5-eae6-45ba-b301-b0f90d8734f8	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7d743076-47c8-48db-acfe-966fc0eaa9a1	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
28c1cb25-c081-4f45-92b2-38c830c9fd13	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
b19d0770-8c77-4677-a3d4-ed1c68a99735	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
6aa9d876-8d50-4a23-a62c-a2e2fc4aa2d2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7c156c5d-331c-4184-8d08-2265faee3283	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
20f4c3cf-6411-44ae-8863-290828bd04c9	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
09b2a309-f381-466c-b58f-7e039927701a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
883e9a5a-05d3-4cea-9c46-be14a06d7abe	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0f579ce0-0709-4a7a-9821-fac5ab6e9cbc	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
164db5c1-d13f-4ac1-a379-e76d14b728e0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
88bc4e6e-83f7-433b-99c9-60f627e3bc49	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
cb45876f-585c-499c-a129-1204ba684b89	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
175fed58-c1f6-45d2-9e56-6162911bba11	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f6af4e0e-155e-4db3-b1bb-ee266921c056	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
68d3e75b-2ebc-46b0-818f-68fe34707282	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
70021515-9464-4f5a-a35e-81d987f3b092	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
38974471-eec8-4ff3-94b1-5ff94f8e567a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3e81bcbf-fc61-42d2-bf3f-b7fc87ad3f9a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3a5c185c-9f91-40b5-85d0-4b185287da88	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b030c373-4735-4e86-808f-afb0dc79a277	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
72ce24d4-9eba-4b31-a8db-ddd6d2d95ddf	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5fe70a18-33ea-40d9-a117-e6d35b3d0586	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
43461f05-3d62-4e9b-a7d2-78f53a53e974	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a33d5391-4879-417e-97cc-a192fe20b402	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d041c9e7-7b03-4dc7-a255-b7d0f1480a84	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
6995bdd9-452e-4deb-ae06-081250f7ddc1	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f64c35b4-8ff7-4b70-a58e-a03d27abde30	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
264a0322-3e0a-46fa-8202-73e9adf39859	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
6f81cb7e-b953-4eae-8683-20450f08c390	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
28fcbe21-b0f8-4f9f-992e-1d44ef7ea6cf	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5b636943-64f4-4695-8227-62931bad6ed3	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2a90d64a-f0b0-4673-9c88-f89a2603a082	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
63ad82d2-6284-4d5e-82b5-c4ae8f5e9100	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e8208a19-bd44-4d92-9eab-a52b4eb1b666	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ece4378d-06a1-493f-acd9-fbb2f594cc00	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b7bb94eb-dfcd-4a2d-a592-fcac62e8dbbd	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
6a65a9b8-74f6-45af-b2e5-e4c2ee462043	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
bcb76033-0dbc-4162-8b18-d49c75996b20	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d7104cf9-aa6a-4809-9991-99cf07f43405	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
938f529e-0f23-49e6-a29c-1b448324dfa5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
51b7b387-a2ea-4248-8058-bfd63f9687f7	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b27587b3-8dbf-4698-954b-55723ff26d2c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d7d2a313-8ae1-45e2-9395-66a1c96b9222	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
086912ca-3c6a-4f60-a650-76b36e96810d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
228500f8-50c4-4e21-963e-91da8b40be7f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
cd400b18-daa5-49a7-8489-d76ee0969219	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3cacb510-4e75-4f72-a875-3d0055c572fe	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
555e7f1e-d85b-4e75-9098-f1914aa6a94b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
7b35e168-3e81-4471-9738-7181ad1fd6b8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
824ac89c-3d34-408f-ab48-4a2061e56608	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a62c29c7-1cce-4d39-97a5-09839e3244b4	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f299cf2e-6a02-4dbd-9a1d-45a787b463b0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
d3ca4bdd-1243-4a2c-8c22-5fc209b2940a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
8f2a7184-9522-4a1d-9b3f-ac629590225c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
68792410-730c-4a28-ac47-e738a4bfd23a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2fd832f8-1079-4d2c-a97e-b95cb6a93951	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
1e02b088-be7c-4789-85ba-2cb8a28319dd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c12e9895-c9ec-4eb1-b1b6-822c26cd0106	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4f9cbfa5-7d3c-47d8-9ca7-57e2bf2556b3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
abaa2a60-9e9b-4049-a0b8-548a8b633951	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2d532838-cc09-4d9b-8893-34f92cf8054e	07771505-6c48-4181-a94a-80816e093af6	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6532df0c-1b34-4523-a95e-508d3957f9d2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-10	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ef3e9986-1d17-422d-8b46-9efada2163a4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1b4080ba-6f61-452f-ac87-c1c080fca9d3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
faaba138-4040-4e53-91b8-2fa6f7730e8c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
3d0062d4-bb1e-4ac9-a285-463a45a17116	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c6dc2b0c-646e-45a8-9431-69d094981078	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
688d892d-7cfd-4e86-83dc-7cd4e5700671	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0148c364-fd13-416c-bedc-ccef8f59a10c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
716e2140-b8da-431d-9d7c-176ecea84890	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
94adedef-1739-40ee-bd6e-cf53c817d7eb	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d76848d7-203a-44be-be2c-d8706d20a14c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b5e35c6b-0d58-4415-b94f-c041a2fe57dc	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ed7e9ecc-21f7-4b98-b1a1-4b9e8118e8bd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
417f5c1a-e1c2-4232-9eb3-8f1783242bc1	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b783471d-5895-4105-b68b-e28817619e17	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
fea3a10c-f9aa-4629-ab37-9359afcbcc08	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a0bc6bd4-56e8-4a65-b970-a4f6eb55c830	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a82fb42a-ebfa-42a4-858d-650208051288	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
4035672e-e6d2-4a13-b490-48181bab8733	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
01e469a0-70f1-46ed-a7d8-d74c64cfb3d9	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e2ed51ed-e2dd-4895-b148-b4f7175e73a1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
13e643dc-048f-4100-81d9-81c544160442	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a0aedc48-ab2f-4679-8abd-8c9650bebf6c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8a89b9a6-4378-48c4-a7e0-31de8c3c2929	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
133f2e99-aeb6-43d6-adbb-f83a3cfe4da3	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
75f852d9-cab1-42d8-b001-a58ace520c1b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
68b28487-8d78-46a0-bab7-1442ac0e6401	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
b77e7951-792c-4c54-a0d7-721e16819f07	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9ab88b4d-a143-483f-8cab-d24d371faafc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9e6f2483-6904-4b74-9d94-0f27a7380017	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3fb9b27c-6ff7-4402-b591-434b1cf21dec	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
823abac0-3fac-430f-85a3-8673b0ccf95e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7cda1015-08b3-4a9d-af08-232abfa570a2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c4cd22d0-3660-46c2-9e7e-dc894cec43d2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7a57e789-0405-4cdc-a2a7-f47f4b1e9521	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
76096313-47b0-4fe2-ab76-fd7737d56cd4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1ab76781-f59e-4bac-9f4c-6d8109b0491f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f4741cf4-2d67-4b1d-86e4-fbb107a835ba	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
ab3b360b-516a-4fc8-b279-3c5f94f79dcb	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6bb9304b-ca65-4324-800e-c48f0b519507	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
14834e92-68ce-4fe9-83d4-254a308459a7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
70af626a-18af-44af-b03a-50090309da1e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
1b49f765-3768-4a9b-9af7-0e0e0c799471	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a5c87851-3dc3-476a-b78c-57f99e223d98	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
284cbc95-9068-4ee9-9932-b01cb352eaa6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
df31937c-2a8f-46d0-8066-1d1778ce0154	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ed48938b-f1b1-4d6c-aa52-9512ee024dc9	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
bc39703e-457a-4902-8580-37cff1ed4f7d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a48db262-5cf9-437f-b9a3-f20323397033	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d9877c8b-2937-4d23-a325-20924cf81a55	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
768a261b-e369-4bb4-beb4-30d9f830a484	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
2438910c-5050-48ef-8da5-89d8a9405bc9	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2f9e32c2-0656-4f29-b79c-691b2f353c2f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
f3653bf3-96e7-4b7d-b966-7ca78bc15546	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
262a04c6-75e6-448f-8ef5-ddd79d19f98d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
046bafdf-8549-41a1-8f08-0ad57b36738b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1de1c595-df39-4d36-b679-271440d6995d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
bc1098bc-2d9c-4d2a-a066-bdbe34686ba3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
21a7e231-35f0-476c-b311-c11c10accf8e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
5c845551-dcfa-453f-919c-a4a37f88f5a6	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e082aa49-460d-43c4-885e-06d439e7a8f2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
587fd0ca-f92b-45ec-9550-05b744da878d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
13c9b801-0f1d-4f95-8e7a-6b389f27a75f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a860f25a-74bf-49f0-861b-482a8fe1737c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c5284050-49fd-4396-bbb6-e1761c531f8e	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b92c05f7-c4b6-457c-8d58-b95971efcbad	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
67bf7438-8781-46aa-a378-e1b46a2e9a06	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a4b6050c-8ff4-423c-b6e4-145fa356fb46	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
0b9464ef-a49d-49c7-b615-29a645d39cf0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
806febff-b2aa-414b-9099-f21942ec308e	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a782ad6d-492b-4db1-ba26-d18fb89e12ef	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
8899d666-c8ae-4a25-9fec-d035646170e5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9b1aa74b-e35e-4302-987c-5ec07178429e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
569c1beb-0ac3-4a40-b74b-17cf2eb8e0b0	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ed0eacc8-75c4-480a-b065-de3dc9a0de5f	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
360e97f9-4261-4db5-9ebe-72f3bc71b0e0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6c638a1b-6893-4aa7-8d22-5ad6780d1e80	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
b04e3cb1-1019-4bda-ab57-abc85a374200	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
50f69f6d-ef75-47f9-8f57-2504fc9cfe7a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4f841e04-e82a-49d5-8064-fa17a6ea1808	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ac529f2c-1d02-43a8-9486-ee3a94275ad1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e2376bff-8a22-4150-8b9a-1b3e2428fda5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
34142644-1e39-4fab-a766-52b7fa0b9be4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c8bc7a8d-4df2-4bd1-99b6-7a26c5118123	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f7749e11-825f-4bad-8118-71e38b6d5654	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
5b3722c9-abe1-4004-a900-8a78f9ca7d03	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e52e5fce-4759-4a1b-b1e2-0bea33d36213	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8589d7e6-0ab9-40c7-940a-62c73f3e8a38	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
028df4d6-8eab-44de-ae3a-5de774669e38	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
81df0690-fe3c-4b22-ab74-877d3e39a255	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
2d1be3e5-d557-4773-a91d-1f28e9e31c84	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
53814e24-fc05-4a2e-a110-9ca5258e017c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d710b3ea-3a3c-473b-84e1-83873c473b77	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
504a94d2-02a9-46d9-8b8d-552da195171b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
353be483-621a-4616-ad70-30290373db42	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1f91ca5c-5527-4e60-9166-25271ac8e7f7	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
938364b1-861c-458c-a370-61ed22946983	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
86c9583c-795d-4885-a2ee-f44e7d23a1de	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
266dfd78-6032-4f7f-b38d-879e6ffc7914	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c943b688-eb09-401b-a3d5-8efa0acadc8f	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
955f5b53-22ed-4e0d-8ec4-dc4ce1ab695c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
46afc72e-5d37-4b92-b969-d596addbf43e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
4dba286d-ee29-4e65-a908-2a64aa365004	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
7db68eea-b002-4006-995b-eebe6770c268	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3d787b01-9970-4774-a9b5-99d4a8ac5bb7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3407427e-1a20-45b3-bc91-88b35679a725	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
4762700c-6c14-408a-84d1-f17d461f9963	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
35f5640a-a886-40fc-902a-c73a15427a34	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c776bf1b-2d96-4e6e-84a2-566765b8d1a0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f87270e8-761c-49dc-a518-07e0d00cf69a	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
cfcc7259-0ebd-469a-bf41-97b1bc34dc30	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
29655569-2c0c-459e-8d10-1d5201f5c1a6	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7a7853d6-a96e-4374-9568-73a2d7f6479a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
006e9a52-c62b-465c-8c47-65513b58a0e9	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b9852cce-65b4-4229-afac-cc43d4e8b375	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
521b321d-dfc8-4f9c-883a-8ae01bc9f94e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9fcda957-497f-4a83-93ff-16f32765c9dd	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
27f8a089-22f3-44e1-b6e2-5cd23dd0d28e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
fd6ed91d-61c1-4b6e-815a-3bc129eee043	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
6ecc0930-5d44-47b1-b41c-92f1cd2b0807	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b58986ac-e758-43a4-8c74-8a2b0486dd4b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
2cb7aba2-363c-4aa6-8d57-99a7a34dc5b9	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
01517384-fbc9-4673-b37d-7fe69d5c82fe	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
fb516600-1ccc-47e6-8c3c-6b035858ad30	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4e6d2f50-b3ff-4530-8a0d-a3f9c0aa6c3d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
542f32c6-aae7-4870-b88d-17c42d4cb0ca	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
d227e4e5-7738-4008-8918-dd4849184943	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
7e4586bb-6fad-4f07-a01b-0bb8d2a2c486	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9be706b7-e652-46bb-869f-8a15fba63db1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
87ce0a28-7652-4c92-a9d6-bd1b7a8e8c23	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6271d86c-0158-4a98-b251-19c1891bf559	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9a64c21c-bcf0-4741-8a24-87d67c7b1e55	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
04b95c7c-98ac-454e-83dd-bf1d271d280b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0dc68abf-fa40-44af-98b1-5aacc4a7f999	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
40989707-b648-4e4a-928d-741aacf1eff3	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
16c986d7-02f8-49b4-b6a6-32dfe6da95c8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
bc711ec1-743c-4cf2-baa1-74928c413139	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
1ab817dc-b376-4aaf-8c28-52d34a764562	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
88004c42-c7fe-4849-986b-1e0fb0124a70	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6709e27f-dbb7-4fd4-b2de-5e4c70258daa	07771505-6c48-4181-a94a-80816e093af6	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
1ed6bc11-7cf7-4ea5-ae30-5d28e0f76cbf	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-11	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
adfc3f7a-ec31-4194-aa67-8913e9131db4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
2a5815eb-7723-4c20-99b6-1ce9b9f2b99f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
9657d216-7f0b-499d-9ca8-32317dce93ee	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7b456ddb-39b2-4a3e-802f-f6ae8b10e028	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7c58cc1b-3024-4aeb-a364-ecc500465ce8	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
6f259dc8-f2bc-4bb3-8d80-47a4c253c178	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f50a94d6-a1c4-440a-a017-aea95a1e984d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
dbcb9f54-8ade-4716-9fe6-282a5adb319a	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
cfee2e17-1989-4036-a7eb-6847668809c6	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
cc1c9ece-0a48-4342-b4c1-63c9e8b05fdc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b6c246c4-942e-4638-849c-5866f23ac4fe	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
18df9725-9a3c-4a85-bf71-7a93f37d9f31	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
2dbc8836-ca64-4828-82c6-f2e4a55611f4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
4222ad0e-2dd5-4d58-8632-c7f280df998b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3fd9468a-1db4-4caa-b198-f3b3fa8a56e4	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5548408d-7e76-4eb7-be6e-ef0d67054675	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
182be9ac-a8db-4f33-b596-039ece8e4cbc	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
38db5c69-9f6c-46ef-a7f5-bc3bc1b05c91	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b1685a13-3567-4722-8461-c6c9fdf3b21e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0f87fbec-3548-44e6-ad11-01766d0d1b13	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0e3977dd-6ab2-4ce7-8231-5837e7e7d799	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2f84e609-180a-44f8-b546-e4f1d66d71db	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
7de6fc75-4858-402b-8b2c-2e415ad548dd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
05fd631f-654a-41ba-a375-72b68661343d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
899d738d-075b-4a88-8266-6998de89b768	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c6afc559-de29-4b47-b903-0711888e3d7e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a6c19aea-db4f-4086-8667-6412039a0451	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	09:00:00	10:00:00	f	2025-06-26 16:04:19.537149+00
d7bd6ccc-b97c-473e-9169-8f6b76ceb491	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
69cb3e52-62ea-4c20-b506-aa4da84cba50	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4db85ed6-d179-4572-a067-15e87a933223	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f9a430e2-e154-427a-9a17-54dacbee2986	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
cd8af6ec-95cf-494a-a75c-d4c082429e95	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9850154b-fe50-40aa-9344-95f8daa3beec	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b33375e2-56cb-42d9-bbdb-ec39194d5653	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
494aeb4f-6db7-4fac-a90b-c28bd6e885bb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8c4a5b15-9426-4088-930b-fba2c6ed8b31	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6c12446e-496d-4885-9cce-3080e51ca34e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f95c7eee-3b05-4316-a536-ae006a4e7b06	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8a53e3fc-de1f-487b-84d0-f932738227d8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
20059eec-f393-498a-9679-4aeaafb078e0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
2b7a3d56-6edd-4759-99d8-3f851eb4e086	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
09fe31b2-ac2d-4def-94a9-659d79af1a54	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8f84e62b-4554-45ce-9224-8f76b30fd09d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
26b7651f-ba2f-4d34-a84a-b8a4c12c3418	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
da26b06f-0e38-4791-bfc5-349c315fef03	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
fa741a61-3c4a-4a27-a39f-8497dd86bb75	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
2374c65a-3e4f-49e0-af58-154a24bd4598	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
814f6e23-dc06-46b2-91a6-de12d78e868f	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0c7380e0-91e4-4c9d-b794-ce531c04e1d5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
da2ef6b0-2d95-41a7-8042-bd2ac6379b92	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
632c8132-9e5a-49c3-acc1-08511b33196f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
10e3f714-9b38-4964-a065-c72ed51c6d58	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
467436c4-6703-4b52-9f86-80aafad51b90	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
fdf99f22-0475-4454-ad36-a5e8248f5908	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
03596303-c126-4086-a0c2-7bfb5e4f772f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
22d2943d-c3d3-49d2-830b-b284a5116368	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
68e345e5-d5df-4c52-baa0-8b0fc3abeb49	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6755fca1-024e-47b8-ba3a-5e53fffe4127	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
f6d74c08-9ef3-4bcc-9218-98665822ad85	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
48281833-c897-4ac5-a62b-d0025a389c91	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9bde95a1-d424-4d37-a978-ebf3aade70d1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
f723eaf4-5201-49cd-9d63-3f0394b74d52	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e31049f3-9db4-4fff-b9c6-7fcb84d24f59	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ff115d06-52ee-4dfa-b7f3-9bfe852d8500	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2cbea4b7-870e-4802-b079-1101a90c3c67	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d9926319-f1f4-42a6-a5f9-75bf53b6654f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e47e0460-3c09-4857-a669-86417f850575	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
dc75ceed-8f98-48b8-bbb4-2fc3dd0b175d	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
1e728a8d-8fe8-4752-9dbc-6bb119fb25ba	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a476bc5e-9fcb-46f7-86cf-2f4e0e12723c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
349f7e17-e559-4ff4-a74b-f859330a1188	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a2743ffe-fea0-453d-b043-27ab4eab3477	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8773e111-66b5-4d17-bc6e-26165bcac170	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a3e1e4c3-ad75-4e41-b548-cc4103409de9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
06f7ec1a-a612-4292-bf7b-fdc9c1e5f6f9	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
badaa349-1aae-4def-be72-97c84e8e3fb4	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2e00ae7f-dc4d-4a64-a37a-66bb48de3b0e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f12fcdb6-7284-4b31-8e14-95c7cd3183c1	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
00a0d3da-c010-46c8-930e-30262ff79196	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9eabc350-915a-4761-b3ed-0949ee6979f0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
935865cc-4656-4771-a17f-c510be637ec2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
73a53ce4-4234-4593-8992-382730b969db	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a28a348f-c15c-41b6-b4a4-8a6e735e2695	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4c9d7064-81de-449d-9739-9ab32d77d267	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
92a5a560-6603-47b5-b8a3-053c16f20926	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4f56fae2-53f0-4900-bfbf-b0c12115c554	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b658c412-6225-4e99-bd70-3dda7fa50551	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8421dedf-ff9e-4835-bce7-2156b764ba76	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
11c4b8ce-19bc-4275-9afe-ada1d78a0b73	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b71bd440-df01-4e2f-89e8-5f1dde592c03	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8ce65953-f8f8-4b21-a464-a39a2a1aabbc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d03f5e52-fa76-48d5-9622-b98037ca6cb7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
6171c6be-7d19-4d81-901b-087389954344	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
bd86e5f6-5c21-4684-a91a-66ecccc6b8e0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
243ac436-24b2-4b8a-b9a0-e91f624ddb2d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
67a62541-b507-4124-b3d1-925c548fe777	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c87faa7a-8201-4dd5-a85c-66f6943dbfe0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
84476db2-5874-4e1b-9d73-002772297e93	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ba789b09-736c-47b5-b2fa-d549c164741a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
947978f3-bfcc-40eb-a6ba-62f71acbcfd4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
38b014dd-23f0-412a-8496-c958607074d6	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
fb2be2f3-bfa8-4a1f-8491-6475f289146e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
6ac2eb82-a8ce-4162-aedb-a32b3b04c633	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
4d53405f-1c5b-4e89-a6b9-2dca614b386c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
6a946f67-a054-4ecc-a070-0127831bc685	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
83ee06f6-3e4d-44e5-80e2-0132484882a1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f5da806f-be71-422a-94fe-8f328b8ff12d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2d067f7d-4fac-4517-b7fb-a919f80875bb	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
cef71473-e029-4741-b635-e67b13e5881d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
ee093a2c-a922-48a8-adb2-211d74dc9955	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
41ff2172-69e5-469d-a3a0-9bd78862a57d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
2ad11273-3dd8-4658-bf61-ae5874c145ce	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
940af6bf-8bf4-4f66-ab1a-5414891adc22	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
25d04a80-75ea-4df6-ac08-0b645059b541	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
2aa092fb-cab3-4915-9996-d7243e2133b5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
fb6cb8f0-0c96-4be1-b866-c8178c4fd64a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5c07d39b-e42c-4093-847c-474f7f5bc0d7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a8dadef6-f9eb-4420-b20a-1b3aab1a34d3	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
092d23d9-44e1-43da-b112-6a2d7a510c24	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
1476e10b-c4b5-4220-9350-f9014c670c21	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b7652a4d-8e6e-4e00-b0d8-53741f9951c1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b104e68b-f1de-487f-b23a-70f43d77fcb3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ce11593b-12f2-4333-8674-420325571240	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ef07d0bd-eeeb-4696-84b9-c0d70f9db4e5	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a0300c16-1fee-4c22-8a8c-5f90fed41502	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3eb13379-5028-47dc-97ee-e6702d177a63	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
41e1dbf3-863a-49fa-8cc9-335057373f4b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
206908f0-18a3-4682-b17e-1cd37c954585	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0f903c07-3b1a-4b79-8c8e-5a061baddf4f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
92c2236a-74fc-410c-9ac2-cdff0d6a3506	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f9862523-f0eb-4865-8b43-a5aad9e39dcc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
5d512910-d78c-4150-853d-7d9697a7e3dd	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
83f4e7ae-8b60-4729-adba-e24489e0308c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
554564f5-b92c-4409-9048-bed978e57b4c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7fd1e21b-9e46-4086-81cc-91e91074d756	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
21ee3e4a-142a-4f77-9d48-1a03435af266	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
bc25e35d-c331-46e1-924c-cbb7d029fef0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2d71b0f9-5cab-47c6-ae91-1504eae878b0	07771505-6c48-4181-a94a-80816e093af6	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
42c23157-91c3-4f5a-b199-7e3d166f9026	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-12	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7c9ad8ec-f443-4de3-82a7-9f18f3aac048	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1b59c9f9-bd81-4e7e-8e4e-0d88e999729c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
2560c1dc-5382-4354-b0dd-7f71302b1692	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
86eed8af-894d-4181-b4b9-47ef190bcbac	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
33a9ed9c-3068-4459-9005-0d00b061b685	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
86c1cd62-9810-403e-879c-c6e979fb69ec	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b0ef3487-c839-42aa-a641-fe1a56ea8bfb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
6c219b95-d42b-40ac-9642-a5da2c198b71	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
dc3ecc7d-5076-4192-a4d9-dfc382230e8b	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
80f1425b-318a-4b78-8f2d-6555f4d08f6c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
9b31b08d-22e8-4751-863a-75dcec842ac6	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
0758379e-7641-4e70-bc87-c36c1dde0376	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
02993b9a-e8b2-4f53-885e-924b7a87f4d7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7cdf4a54-53f3-4919-a5ac-bc655624d6bf	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
28ea6df2-98e4-4228-8cb1-b807662bd744	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e88ab53b-6fe0-4f46-b0eb-41b8430b13cf	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
bd9584d2-ff8f-4eee-bcfd-f03c19d41844	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
72c55152-fcd1-4872-a3af-ee3a1ae2df77	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
60bdacac-7819-4a4d-b8fd-1566a7a74489	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
af439793-3552-41e4-a2b7-a646a7107283	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
21de0efa-08e9-498a-8337-fb137a3afa17	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c5cce1fd-77ed-424d-aa86-3f60a4f21ab3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
25133188-6230-43f4-9792-935c484e9c62	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f1f3d176-0cfc-4097-8493-198c6e8a5611	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
06f75f7b-216d-45bd-9484-1c9b162f3e4b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4d6e2fd2-e2e8-44e3-b139-ca723fad0c6a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a1abf951-93e5-4562-99c0-e6b3eeedab89	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a429423e-e183-42ce-b90e-22a43a4c7d2e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ab67f285-86e8-43b2-86dc-172fe3d2867c	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0af9801e-a74c-4ad4-beac-9c723937b059	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
62321b70-ca25-4632-86be-505625f99b35	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e8257b5e-7478-4c16-b344-0dd0b3595352	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0a8b9f00-7d36-49b9-997c-455d7dfba2e3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c38c7a08-c52f-4d02-a00c-c7e9d029f1e7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b6db13cf-c30a-4914-a39b-6c799bfd5cc2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
75e53198-3644-4362-9bd2-320d2d36adef	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d83ef968-90e3-4d85-bbd0-48eddf60ece0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
01733436-f3b0-459b-be33-f87075dcf291	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
fbbc5b5b-370e-478a-95c2-cb9109c7231c	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
88a2614c-fbaa-412f-a0c2-99449fb98db3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0edb072f-b764-47f2-a0f0-1ff5899de7cc	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
3463b3d7-4bce-4b4c-ba28-17a609486846	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ab0e3ce3-1f38-4cea-9752-3b178b1ded2d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
bbdb17c7-16f4-4afc-b70c-f0d65df4a15c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
5f563ca4-acce-40f2-bf7e-0da18053407a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
2a01280c-1126-4149-818e-816f4efe40e2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8a9d1908-b52e-4b95-a79d-e931020bc0a3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
fe637802-2fc0-435d-8947-abb830f70977	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
37b21312-0271-4c17-ae97-bd763cccf02a	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d0cf769a-aaec-4656-b9e8-ec772940890e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d51871bf-4a5f-4481-9dfc-5e020d9236af	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0e6da131-a8f0-4abb-b7a3-b76877d9e206	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2129162b-fea4-4816-a088-f5dd6dd48951	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e3c074cb-a5de-4bc5-ab18-4a4d9bacca8f	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
308ca63c-0d58-4f20-be82-d08984181b4c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
fc5288cf-e657-4494-9c8b-9ff8ac6e2b83	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
de874159-5e4e-42ab-84de-0f5b6ff34f45	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8827bcfc-cff4-406f-b260-ecaf877a507c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
65ab7571-7e11-4fd1-a7f7-4571237f439e	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
fdb2235d-a9d1-43eb-9388-3d0a649defc7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
488ffb88-a554-4b44-bea7-bd09ec9821d9	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
cf548940-9793-4e44-b74d-cbab4fd3891e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
0825aa6c-3a8b-4d6c-8f96-1413db30a56b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ca4ca709-84e2-4cbb-a55e-390794569a5a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
51528729-0102-4496-a672-c56de9b368bc	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
15f6ca61-30d1-4cc1-86a2-8d63e9397ac0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2e3df217-f186-430a-97de-2b8169d93cdc	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a1bb418b-b66c-4378-a709-8973c970de56	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
33451f35-9986-440b-8c0c-3b9b2e172a29	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9b24e073-180e-48bd-8312-2c0796315d42	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
69a43748-ad08-4297-93a9-0140a4eabc98	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8027084b-1b4e-4bd1-9550-6b712b848eb0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4b5b8028-b446-4dbb-8f90-e999554b8d5a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
af3c79ae-20df-47db-b406-bf218986794c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6a3bc240-bab0-4a43-b4d4-74e675d904b5	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a113909a-a030-456a-9382-532c0998f8f7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
686e537d-04ba-4571-9100-da0d2ce8be2d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
368df1fd-50af-4ad5-b74e-5788070864b7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e28bc180-97f6-47da-a3e9-48b0d58c0df0	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f81a4134-b13e-45c2-be5c-63769fb406f5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2d05dc99-74f4-451d-96e8-74d5fcd1aa96	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d0b791d1-0d0a-4fa3-a642-809c6c127efe	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
cbcfcd5c-6b3c-4f5b-9024-3f01e129f021	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f9451451-26fd-4c24-a24f-be1a3e2ee6e5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a2131ba7-a420-4cf5-be34-6af5ff070c4c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8f1b01d2-5fcb-418f-8260-314941064955	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
91cfbf4b-f721-4e61-a381-b9f165fd7894	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e87327a9-55e3-4996-a8cd-d6f6d0cee70d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
fa6c44ec-45d8-4448-af5e-22b2e35cbaf2	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
cd38a121-c737-4f37-989c-bfa56d6b5fc5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e812ee6a-fd47-4a04-b777-7e0c6ac53349	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7b48f56c-a1b2-4281-b577-dc5d946a0723	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e629cba2-ff6c-4088-907d-faceb6d4978d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e31072f7-cf3f-40c2-a9cc-10914b49537c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
eedce5ad-b68f-4dda-aa62-fd71ac935f92	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
67d4ba73-b8b4-4554-99b7-269c52809cb5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
83cb0a45-a362-4ca3-953a-56eadc658a0e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5a057f94-4fbc-44ff-9e95-57c5e95841d5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
bbee21e3-800c-4ff9-a249-ac837c6027c1	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4bfb7724-ca41-49d3-a8d2-d9757527eaf1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
33870117-ea94-45a0-b07e-b5a152689b64	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5d17d811-ba9a-436e-9935-e09ab74549a5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
46eca957-b4c2-48c9-843f-4bbb8d5e280e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5d7b310f-3d7d-4238-80a5-b4054a71e76d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d53841d4-ef22-4891-88f7-16233ab26788	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
49b10294-3fe8-4fab-8a56-9c47c5930944	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
7a72643a-54c2-44e0-ae66-f20c1002aa45	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
18f3d06a-5406-4a66-a2be-2aea0188225c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
0159c9b9-25ac-4a47-9294-2e6a5b154454	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
dae783bc-3dd5-48fe-a81a-6bf66e768ce5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d630c7a5-8464-4c45-b032-5562ff5ddaea	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e34d67e8-29a2-469c-9aef-2f77ba4d6c5b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7633307b-2bb5-48b7-ae81-06aa262cb075	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ce9bea33-40fe-4735-9cb3-a5266627dbf2	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
84395bbf-ac92-4c75-bdc8-3868e29a4316	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9d1023a8-4109-44ae-ba45-0dbb9391b42a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
390d7c2f-9e6d-4a9f-8fdf-ce63c1f76427	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
37a4a0cc-a595-4adc-9d1b-e34f30ca7877	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5fca22bc-ab1d-452b-affa-e171c4858567	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
47030f52-dbe1-4062-bd4f-b703eb9f62a7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
94384d3a-3e71-4350-93bf-c64fdfa021eb	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ef3f8735-59dc-4487-b08a-7afd0ff6307b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
eb81ab93-5741-449f-a4a7-cbb170f7f702	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6726f4b9-f8b5-4cb3-9a5d-bead07e12ae6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b9b6cc39-5b65-4b28-b72b-7493330622d8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
767361b4-5fd7-4373-9c42-317ded48a931	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
40db94d3-7038-4782-8e58-1a3d0967d366	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a5ad369f-71b0-44e3-8c11-bcd119c8ef6f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
08ed7c18-c05d-4604-92e5-68b13610dc81	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bda8e9bf-16a6-48e9-a9f0-d27e4b62ea1b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
568cffb7-4053-4175-9448-3388d6437dc6	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
9d1b6854-b1c2-45c7-bdb4-3875407e8f44	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a115b26b-1e59-492d-b036-a7f1b05f6b3c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
32cd279d-2c38-465d-b4c7-c6fffa8029a9	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7c84362c-0769-46e4-9e3e-40ad8b85d19a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e375958a-fd13-4fd5-9caa-7664060872b6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d36e6ed7-1ba9-4962-afa5-1a6d22f5d25a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0e695435-d87f-4ac9-ad10-b7fbc155ba3f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
63953ae1-9ac2-45a0-b73d-20c2a5afd42e	07771505-6c48-4181-a94a-80816e093af6	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6945d27d-d9a9-4cfc-a0b7-cbcbca94fd9c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-13	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0da41dd9-3ac0-4e26-8ae0-fcd1e4f1ae11	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c9c7ec53-7419-4829-b19e-fafe9831d785	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
23b681ea-47e3-41ba-b829-b2c77d2b32d4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
506bdadd-be50-4ec5-9b19-1e60bd6ddaf2	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
27d7c785-9827-45e8-b0eb-d59104988051	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d88dc388-e65a-4cdc-bd05-05f99ab18e8e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ab26459d-dc0e-4952-96b8-78902f4680e8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c692262d-5925-40e6-a2f1-6cbc9ea4820c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
8d2fef2f-283f-4e0d-875b-6f3db1d0a873	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
951d5902-692c-40ee-8d7c-88952785446a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1e64d218-cc61-4ba0-9784-0abb147e2f89	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
948529ca-3f3e-4c01-976d-ffa525e909f6	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b769e921-ceee-4d1b-9b0e-4d8486e3581e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
72208741-0505-4bba-af7f-cc753c289119	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
9ff84a02-6515-4b89-a1c0-b2f01c1c325a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
22eb4a45-14e4-4a6f-8b49-58e7bfb53ed0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
4d54c33d-9975-4ebb-a500-fdcf82f74d4d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
78084888-0d66-43a7-a506-ff42fe60b521	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e40b9a31-31ab-457e-b99d-0299e7d783c4	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c71d1964-d39a-4cc9-88ac-dc4b50f37149	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
4ee8e773-6487-4d79-81f7-542d995a99f8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
807307fa-524f-409a-a172-964e8c409616	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
32dd9fda-5e77-4f05-b888-0da360d85286	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
557b7648-88a6-4a37-a92e-63b860c09409	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e9b8a0f6-4683-4521-b52b-9111de0887a2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4ff8ab55-16a7-4ebf-9015-11b081f71dfb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
7345ab73-f651-4570-91ba-0bde3b95c9c8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
fdbaeb69-6c1d-4a6a-8f85-c88817eaab1c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
7908f19f-5179-4a3c-a5dc-717f80443d39	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d15b83db-9f97-4c69-bee7-f499011e07e4	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f6ff5ad4-3473-4f0b-92f8-d66db6bfefcf	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
45c1cedc-cbe5-4087-a473-3de1157616f8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
71d4ff2e-f906-4ed8-a3de-b944a2a273bd	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
43fd6381-52fb-4dc4-96a7-c856a5390217	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
13b30849-a546-423f-a794-8793157aac7e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
4b7dce73-7a56-4533-bb55-48c2e18b263b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
29b50827-3d0f-4933-affa-0be6897872d9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9c3ae495-1db5-48b0-9b11-e35d5ad6be2c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
418fc3fa-88a9-446d-8cdb-af5ee5db2248	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1ea30d2e-f7d9-4e1f-9b10-928b0818248f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c32b0089-6b48-4c52-88eb-86cc30b13ebf	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0d5c1444-fc09-46b3-b02f-98ac53a535cc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
4340effd-e1a8-4c64-82d8-9689166784ab	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
43b8cb59-e81e-4051-b96b-037093eede4a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
560ab8ab-03e5-4865-a982-ca03e47b2039	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
685e5e1c-471b-4996-b20a-c166373812fc	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0a1bcc00-6808-42df-be99-de94bded8239	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c180dcbd-5b7a-4955-87fa-20eba7cc2adc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
db067bec-cc10-434a-9f94-eccbe3a4eedc	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
5872cf58-cbb8-413b-9a2d-24bd53b596d1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ffefe35c-05b4-40bb-8300-abcd7e5bb387	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
72104355-97c2-45bc-b586-04c102dff971	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e7f48415-9450-4fed-8456-570983514b6f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b9f8f73d-2777-4255-8a59-4a8efdb5c214	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
3f993b9b-b4bd-41fe-b33f-526aa4427496	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9cf65e88-bf50-4df9-ae91-cfd5e4a797b2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
5450a65d-16ec-4a5e-bc39-620ae33736da	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9b051169-6513-4ec4-a08d-4a0aff7ef961	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2825a1d2-151e-41aa-b170-55b444cf5149	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0118093a-0ac0-4380-856b-990e8dd0e88b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
548d34d2-5715-4621-85b1-37c9fd23cb94	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b9d43ae4-ecb2-4e9d-a7b9-b168b2c7018d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
0392f174-7785-4fd4-bf82-d8990d17f6b4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
91a21e00-4c16-4c1a-bc30-d8d2f11804c8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
61102bc6-2fc5-4e1e-9983-54f4b684977c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ae055d5d-5db8-480e-9e9a-cd8e35aa5f6a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b655434c-ad1e-486c-9f84-a650afe26c37	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ab635001-9bc7-40c8-8b1c-57f50525a5be	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
787ea772-7ba8-4c5b-9299-86b981878c9b	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3e633da2-1794-4988-a53b-de9d1ba69427	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
88f3d4e8-37f3-4924-a735-fcf1841b74f2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
0a01327e-d244-4606-9265-190ff03213c7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
b3646cb1-7bf7-4af3-8b6b-6b61b56a79d9	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ba152ece-bccc-48ce-9ee7-e24364e80835	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c6319597-6e31-4134-91e3-ebab6c9f3e0d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
011bc5fd-a3a1-4c6b-b9d6-bfe3650a5eff	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
52064d3e-3415-44a1-8a0c-df6c83af9578	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
04c7f785-2b3f-4b9d-9a84-504c92e0e83d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
cf288924-a8b5-4a33-bce6-8d02245e56f9	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
5f16298a-c57c-4602-b86c-30b323bd67c1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
0cd5bf3a-5c38-401c-b935-f4927988323a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
9133d8e2-0b87-4259-b243-4fa0b0af33b0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0740e4b3-a2e1-4b5b-8ec6-a4296d38ea8c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
bed09e14-85a0-4e1d-8c71-866e1b3d683c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
2930ccfd-b142-4e8f-8f34-c2e1d7a5bd7d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
93b13a4f-97c7-460e-8c01-15bf9e279c36	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
18d18a97-ed13-468b-a42f-9553bbcf0dbc	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0564356d-f5e2-418a-845f-b10914d955f6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a12d6de1-d3c7-4413-85a1-45b6ac20dcae	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
5e57c41f-acf8-4e75-a92f-0d8da3f2628c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
3a659d68-266b-454d-93d9-bd630287db32	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
cedd787b-7794-4874-a174-0c919f331df6	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
60ad8c18-71b4-489b-9124-50fc0950f610	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5831efb7-b812-42f0-bd8f-e8f2f6006ee7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e429a647-af99-4cb8-940c-26ba60bb2658	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ed455999-7647-4b35-a031-abcc378b1ca5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
cd6fc57c-dc12-4c1c-b973-bd262c09bace	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3e5b116b-86fa-4c7e-a961-dd2bbc5a4fca	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
32a09602-307f-4128-9bea-cb73760b11ea	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d13ee255-8aaa-4b57-a636-6e195555fdfc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
09e52eed-c87a-473e-9e82-b4c60d64be3f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
62911331-fa54-45e8-9aed-fe28aae42a88	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
223f18cc-0b83-4c4f-8c3d-b835c3f1ed6f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
691d3dd8-c731-4d87-83bd-c4a0a2f78971	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
50d953b5-8925-40ec-8f7a-50fb7600913c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
fb68ec02-60d9-4659-974e-182e26126feb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
cf77226b-684f-4a5b-bb0d-23bf92dbb630	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e1f657d5-28cd-4de1-a978-c7f476d0ce21	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
29e791ca-7a72-4f70-b42e-2ab43912568a	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5ecd5936-230a-498b-ba3f-1361465a98ef	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
59e112fb-1faf-415c-bbaa-602da3551a83	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a1f17af7-f06a-4f93-80a6-0c436812f280	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e710220c-b143-4eda-97b9-613c2db53e8c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9ee7b1ad-b85e-4a74-b6eb-8d1bc9b47693	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b222b817-de64-499b-91d9-34d7c9d1b7ab	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
8f16cfb1-45fb-4056-b04a-076b082a11f8	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e8635968-5512-4056-a9d1-80b20f2813cc	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
6c525a8f-8581-4f7b-a72c-a38597b52edf	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d9ed7b5a-53c1-4948-bcb4-2c8f19dd970d	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a7879c89-db7e-44c9-b0f8-75f5d6f759e2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
019541e6-9800-4c53-89fd-10a5c37a4f56	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
2db16aaf-0911-4d0d-bf60-95a7a2fd5283	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
d8a07b8c-9a6c-4f98-a5de-94f6a394c0dd	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f81a78c1-5e51-439e-99a7-06b863685824	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bbe5dc8c-3cb9-42b0-abe6-3ba15197e568	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ce346c56-fc53-4f1b-b22c-8973c90e2257	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3f2ecada-b847-4f09-bd00-e2c32d3a9915	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
cffbebd3-ac64-431a-b910-9988aa5afcf3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
82b38593-f747-489f-9f03-d4707c1f060f	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
04d1ad70-7d62-4d10-839e-8dcb3d6ebfff	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bdadb24b-072a-4f21-a6b2-a663e7c2ca32	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e4df435f-12f9-48b9-92e0-aec16ed32895	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
63bdcf2f-d19f-4470-b5ad-6c00eb73ae88	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ed896fef-e8d2-4549-809f-c4d47a9e805a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
84a16c1a-4e87-4871-a463-f83009e4d6ab	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
8db8c358-f8ba-476c-a71e-462bb6b982ac	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7aef5a91-73d4-434b-88a1-925e0521e950	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
acd72b39-cfc1-42e8-b2ef-3c2c54314c38	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b7bb8194-8c79-4356-bad6-be47b4aef705	07771505-6c48-4181-a94a-80816e093af6	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
91a0c48a-b7ef-4970-bb75-b24eb572e0aa	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-14	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c6491357-baf3-4954-96eb-e81e721d2bc1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e49b999a-8059-4c16-bcb3-2217dfb86ede	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e3c0e0ef-f0e2-4712-a8c8-29658b3d9d00	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
8f435d4a-ea8f-4516-b9bc-1ccdbc0c46bd	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
44a6d609-2494-4da5-885a-cdb4fd5c9bce	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d95a368c-bfe0-4134-bbd8-c4d5ed1d81f0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c0ba947d-3f5a-4cf8-9aef-1efa73a3bce3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
26cc1e8a-9b85-493a-87f9-f2c8b47993ef	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
6ab4fa80-94ec-459f-9f4a-99252607fec9	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ddbbc846-cef9-4e17-9bcd-353bd037cc0f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
508dddac-6a7f-4ebd-8bd4-edfe01b81a30	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7c7f4691-4501-4042-8c5a-a363f62db3fc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
699150a3-7c9d-4353-8a7d-1666b77478ec	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
530acbf3-b348-48a4-87f9-255615419e25	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
192efea1-311b-4c47-8c36-2ac55e58442f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5d99087b-af4c-4a77-a5ef-621d3d022622	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
174847c4-1bf8-42fa-9603-f07a2754b6b6	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
4630748d-fb05-4d3a-9094-5d7e3f94c605	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5ecd2b74-16d6-4c74-8ef5-db22c8a3423f	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f68e7f21-8b63-4aa1-9138-f011ce3645b0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
98a7cb2e-c42e-45f1-9e45-2a582172e2b6	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
aa8cbb8d-517d-4fc1-9d40-8b6e51ab3b1b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6c8114f7-1eb0-4e99-95ed-8ec094b69157	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
276fb4c2-4f7f-4683-accc-93fa62ddea5c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2dace9ad-9c06-4cca-b405-8044a89309ba	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5fa5f9b4-9e29-4c93-ad2f-85a4b6871db1	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
91e921e7-bae1-48ac-a8cc-34b779a549de	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c39d7e1b-6c8a-42ea-90f8-ccdad0308ff7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5dee099b-1441-4763-ba86-36970fe086cb	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9fb10371-3811-4e5d-9dd6-efb39b3a2ef4	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2130fb76-31ab-452f-9dec-8b118e5faabe	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f711741a-f94c-4443-b5c7-d4a6b3bba5b1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
18270f13-e4ec-42ba-9bc1-f057ed357360	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1277d520-f1b9-4fd8-9181-b00f1cc12255	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
43aeec8f-9f28-4b1a-85ea-fe299a268586	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
7890a74b-2320-48ce-92a9-56880c0b483f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
41ba6747-92d6-4236-9f53-5995752fdf95	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b96e117e-45d7-4914-8553-326f4da58a89	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
5fc9694b-8282-423e-a98d-00b5362a39ee	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
06b49759-2d92-4eae-a5f8-b3708d7a5035	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
4313a766-1bc7-4b90-9490-4cc7a269c192	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
de55b64c-eee2-4290-87c2-13ccf720da21	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c258898b-8a7d-4abf-98ec-b41c30543dbe	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b2018535-f551-462e-bbf4-52c0868ab7a0	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
938048a4-8959-4630-aad1-da3b937fa2e2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
42087981-1457-4ad8-aefe-66a99dd72f56	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d19d184a-47e7-422c-9a7c-d2e26f02f438	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c54ad9d3-247e-4a27-9f86-fc9247e71eac	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
af27c9a1-bda6-4bef-a761-409be6d2da77	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
76ed81a2-577b-4f99-8d17-f03422bf445e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
5b57f2fb-e154-42f0-83f5-dbe7a1c5abad	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6d80df12-b63c-4bfd-9dca-d07f28dc8123	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
de84b03f-4fe3-43fb-a727-4d35c4cde8d9	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
eaa0f34c-2b9a-491c-9b16-765dddd402ce	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
71e33c97-5275-46ee-abbb-b4c9fd8bd04f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
4fe21f59-aa16-4517-a496-ab9df1b1c80d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c424469f-fbd3-4c8f-8c5c-e783c8e5f8b0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c8676001-afcd-427f-9e5d-14b17ec0bbd9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
221fd31d-17bb-4c08-a815-f83a981cc803	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
831ff7ff-0882-4679-815e-ffa46fec9be7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
3db151fd-56d5-44b2-974d-2303ccd510d8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
8d0454b3-34c5-4a78-8f01-526c149c3485	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4f777300-3b4a-4c70-8b75-e01c6d72d238	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3678356b-0d03-4b51-bd26-49ee76daf5d8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
06a1d13d-a55a-4de8-939a-463d328f856b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
623c2e38-9e07-414e-991e-d71720891f2a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
141a1dba-c90e-46ea-86c9-42bef7843c0a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
fe49d3cc-8ded-4cd4-8861-2675398d04a9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b8c16490-c7eb-46ed-8d3b-1d90934e41a2	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4d1aa35c-fb9d-4382-819c-df1e7d652618	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9c0862b5-97b7-410b-89d9-5f67cbbc9821	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
fc6f45fd-aee3-45fb-8858-8f9547fe2750	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
83478656-53fc-49ae-b4dc-59001a5378ac	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
40030567-af31-4a17-84a9-675c51aa09e6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ba1677fa-17b8-40ac-b11d-c19ce9aa472f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
eeabd381-5af9-4db0-8da4-498e258d9516	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f90d9684-8ec3-40eb-885f-1d01aa9cb860	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9bd6d253-1289-42f9-89bf-b49a5ac818ba	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
857aa74f-d0a3-48db-9444-dbcba58898d1	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6e6ff9f2-42dd-49de-bc11-a060c749fa6c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2076bebe-280b-4a64-83d0-fd6bf319e856	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f4663cfc-ba39-488e-9fcb-8127538ea77c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c93aec56-66fd-4bd3-b1f1-960845b66578	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
9d80298c-538e-4669-ba61-1fa20a37074d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
391d3fab-6885-45d3-a012-b354e1d6d4ac	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b9781d34-5deb-40a8-bc4f-1adca21d7f37	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b95302c5-e8df-41e4-beeb-ea03a375f981	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
68a16c71-450b-4426-b1ee-0143248ea8ab	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ed896e42-086c-4912-8bc3-cf0184b70df6	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
82d2f3d6-6e2f-44bd-9173-0c83ea535950	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
13edc0a8-f256-4b68-a45e-67e2e415e8d0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c640337f-1881-4d1f-9799-a84f34410536	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
448e300a-35d0-4ef3-b5b9-4719158f62e9	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
29423a68-1314-4082-9002-dbdae5101880	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e7031710-80ed-446f-85c7-7a28ff002161	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9b2c2556-774d-43a8-a755-f04069e6e054	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7fbca583-cad7-4fa3-913e-8f987a036663	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e16f35d5-a5d1-40a7-9bfa-d9872a4802c8	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
76c19d0a-4ca7-4500-9b32-12dd6e15da10	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c9435e97-9a19-4508-b0a8-2635ea45abb3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a9088bd4-fe38-452f-8fa7-f7262555abb8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b8027893-0240-47bc-8e21-d5975a5f6511	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
22ffe863-0fb7-4ccb-909c-5db7ca8ec786	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
611ee8c2-d68a-43fe-bf0f-963703c4942a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
32f4d83c-d775-438a-988b-2ece82f800a4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
14c6fa38-16c7-44a3-8f54-d0933a676fe5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
ef338b7b-fe47-4715-a6bd-aa047374fbfb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
1a0adef5-539d-4219-8595-496d81a06363	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d77bc6a4-4447-4af2-8b07-044aad85bc45	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d38d42ae-d76c-49a4-81d6-ac8915f94fa5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
126f9da6-44ca-4a99-9dc1-2ca6d0438cbe	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ce7c52fe-bfe3-4711-b570-2fd19838e12d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
eb2b06b4-9c5e-4eb8-9feb-fa27e187f74c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
13d2ead8-1e48-49e5-a0a6-72b8efb6d501	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
80f03ba1-8bda-4da6-ad88-595ede64d5ad	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b647cab9-3b85-45e7-b428-b8f42371eea2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
f8c6fccb-110e-4a8c-a1fd-98db045049ae	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7f261bf8-aa2c-400e-993f-dba0a781d448	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4eb362db-1ea7-4d6c-86a9-ba9d312a1fcf	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e072041b-564c-411a-a03a-0554c9d6ba2d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
5e33171e-3d2d-46e6-a23c-c9bb51925fbe	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
45bec1f6-a7ae-4c2d-ae0f-a7de8784c80c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
52166b36-6869-4d1d-b029-0b9165148884	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a9b80a62-b46f-478e-b0fc-c30166e41582	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
161a0c0b-f1da-482b-a9fc-7a5400c4c019	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
694b0729-72c4-46b5-84ce-0ca08a3f9260	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
07cccc2e-a500-4798-8050-05e022de7510	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
46caf8ed-c86b-49fa-90ab-07087d4bc041	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
2c69c8ed-361c-4fbb-b9de-4828e855844d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
52ed9e31-66df-41de-b667-f04623f47e0d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b344a006-16ff-4524-9e3c-45d625d2ecb0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
cf22d421-7a50-4b00-a4e7-d96c489af37a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6f53e220-ce5b-41e4-87b7-d4b0688e8cdb	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
efeb78d3-7c6c-435a-9995-040aa762658b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
8e6816aa-436a-459d-a471-e5702ebdae71	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
175219a9-ac7d-4877-99c0-6d10f56c9276	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
cd1b980b-65ec-4fe8-8f4c-5e519304956f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
92f82b87-b0db-4531-a4a0-50827fbe6cbe	07771505-6c48-4181-a94a-80816e093af6	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
760f11a4-eb2e-47f9-8a54-67652e869429	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-15	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e1e7901c-f41f-4063-812b-2e8f115a649b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f1321263-cbf4-4881-8056-c4172610d0e4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
9a751f96-50e6-4859-9b44-190129e1a429	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
12360b47-2632-417d-8212-c0aae2a468b9	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
6a3b9d66-e831-4757-8f05-9ba4f52323c4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
16f7e484-61d8-416c-9be5-8676d8a626fe	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
36a42e74-09ec-4120-af6f-44b4a150163c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
86703c7e-0fc1-44f2-b3f5-f9aae8e797c5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c5dbc0f2-4756-47f4-80ef-d2d61f6a7276	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
4e9e0d52-78ef-4947-b401-5a19d1021418	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
6bd39ca5-9260-43ca-b68b-8e748b52c335	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
20375fa2-4896-4055-a5c7-43b0b2721c00	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
987e8d66-c667-425c-860d-0966434691c4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8b90a7c0-188b-4b3e-8222-748565505565	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f174f71b-7930-4b04-9aac-6499b9e11bfd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
0f7c8ba4-b25e-4857-abaf-6bb29d6dbc8e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
1de5a2aa-37df-4955-9771-34033f3edfa2	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
35d62d13-46c6-4d3b-bb49-440c3b8e4eec	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5e065494-fef7-482f-b975-ffbc4525dc3b	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e2710ffd-650a-476f-a4cc-be7f4fa4f41d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
fd5230fa-bed9-4def-892b-f7e9ffc90068	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
417005dc-20ca-4843-99f7-ff81b0b3a375	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
cb5e515f-1e80-4199-9e92-b6498a78aca3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9e037ae6-52a6-479b-8542-d9574774c7e1	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
54876b96-da38-47f8-9215-b4f3e122d2f9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
bd8a9835-6b4b-47e8-b92d-127b68279edc	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f986c017-1a84-40a0-b0a3-0663b53d5316	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4734c190-dc4f-456f-8090-eb69faaf6aee	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9c12fbd5-69cc-4a2f-9706-38377446ce80	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5b1eae4f-65ac-4d8b-989a-45be3911a4e6	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
7e892750-df9e-4d02-aa70-da26ec58b9cc	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d13bb722-2127-4df5-ba78-c010bd549041	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f7b58584-51b7-4805-a3bb-821b1334fa37	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
74180046-2020-4569-86cc-5c3e004bfdbf	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
06e5bde0-d97e-40d8-ac05-91104997765b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
67eb2671-9d3e-49c4-bd65-3a3e87ccd5e3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
162ab435-2f64-474f-90c6-a4021fbe4216	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f4334572-48da-4438-bd97-157bc9a01d0c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
beb21139-4a6b-478a-9e89-31c28171d260	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
fe19fde5-36c7-4b42-aaa9-ff64dc7f6834	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
874b985c-1974-4e7e-9837-4c10a080cdc1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
69ab518d-e791-4051-955c-25d7cc5f40ea	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
90e24c69-2c96-4210-996a-a85df53472ec	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
4206d00a-a318-432c-8a2a-0889b1a7c554	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f7bf18ee-f3e9-4481-b3ac-9bef896ecd20	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
9fcd1c75-f37d-4428-8c15-f12ffb627415	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f9ded821-7c64-4970-bb0b-49d6cb3b1ded	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ff6e53d4-faa9-44ec-8842-da4d38900b81	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ce885275-4450-40ca-a0a1-eea1a5a34baa	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ca37b8ed-8dbe-41a2-a583-74e2bf8a45c7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
20700627-db5d-4ca0-af1f-c9d677d34161	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
20c07269-9942-4db1-8259-22eaf63a0884	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a0e40e14-ecee-4a9c-81e1-b828fcd3d974	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
645f50f0-be6a-4681-bb05-9a3ff3d81504	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2f852978-46fa-4e74-8c64-818b72d80efa	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b892f4a5-dd58-4fd0-b24d-9b526bc53ca6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e7806400-80b6-4a71-a245-5bd8b593d4b6	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
80946267-0cf9-41f3-9790-3c530c4c54e1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
082cf0e5-b1ba-4c0e-afa2-61f2273f435a	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
f88caabf-72b4-4261-8ab5-12332a29ec3c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6a72ef13-e68c-474e-acb8-550f5b79b399	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c2b9c168-cc47-4cf6-9fef-2008b1d2acea	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d35741d0-009d-49ea-a8e5-29cbe66e14d7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
319e1e2b-6348-48bb-8f72-1cead406c5d7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a4f1a917-75cc-4f89-91c6-fc260eb12bb0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
32cef9d4-93cd-4b9b-a85f-6fbbecc44632	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c6646c29-dd22-4638-8570-0be24c819783	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
1b4d78c9-aea2-428e-bd56-747d1a7bc957	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2f48b0a8-852d-469e-a1e7-530f609befbe	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
8d21fd71-4f36-487c-8b66-3415b4adcf0e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
7cc73931-154b-441b-ba41-686599c337af	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
1b7768d7-db99-44ee-940c-c29b0df7ac85	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8f25587c-bfc9-43d7-b145-92607aff454d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
641819a5-4779-4b06-8105-3bde8bc60e75	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
96c4a647-89e5-469c-9947-832a4ff7fa20	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f4bd99e9-d155-4ce4-b70e-51521bc78b1e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8b24cbb2-7089-4a15-a25f-aafae0f15523	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
34067727-7854-4358-b0cb-8aa4ee506fc7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
22b0079a-0973-4e88-9148-370c6144be55	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f3646098-691b-444e-bc81-d0bdbe61a710	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
124b2817-33dc-41e8-9053-d7ca8e0b5dc3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b35e51ec-6fbd-41da-9867-59e0b6a6c6e7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
75997d63-9882-4f00-b2a4-fa3931491500	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c9773062-af8a-4c84-960d-b0c342ce9c17	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0f434ec1-7ab9-4cb2-a8ac-7cbcae0a6b95	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0fb9912e-c524-42a2-98f0-3203a6afd1d4	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a6802394-e297-4b33-ada2-371954987d45	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
25cfe8f6-ef2b-4d4c-a8fd-e113b7b84d1d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7c415ff8-3d8e-4546-baf1-525deaae36d8	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ac2d6326-c4a0-47f5-aa23-91d9911c95a1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e3270c56-356e-4a30-a816-7196a32de9c9	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
630885d2-b2b3-48cf-b539-e9459cb7949d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b36662a9-f4d8-49a7-9549-813110b781e6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7359fd55-8169-4abc-99b0-41e4fa71e2cc	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
251f2acb-6837-4d4a-b394-2bf12289eb3a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ee0ba92c-4731-47f1-bd26-7f767cef6398	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1edeb201-070f-416e-b2f2-7e02bacf13f4	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
922c029a-9260-4353-b6f4-a310da8affd4	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d0045e4b-02ba-4f88-9f67-e1d034462e64	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7d8a1dd3-f012-4f8c-8bf5-f92efb524812	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e192f4f3-0ce1-4fff-bade-bf24fbb39b07	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
43c3d841-611c-4d32-aa5f-52a77766cb54	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a989df8d-1482-4e44-8413-c8ba2c48de85	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f268e5be-ff1c-4d58-9e77-5f5d2d23a200	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
bca74e4c-6ce6-44e3-9c9a-1dc528a065d1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b2fe9a2b-c873-4eae-bcb7-0d343184bb7d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5e2dee44-9492-471c-a28b-84470106c1ce	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b736e016-3c2e-4af6-9e0c-f4f8338060da	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b791e3ae-ca2c-4808-816f-9401f0f514b7	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
20118b74-23da-49db-bb24-b3266af1fe80	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
898b6d4d-4c57-49dc-a6e7-21e347cf3321	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
3afae6f8-8577-4d58-9ea7-bc463f0dba02	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
23562c3b-46cd-4e1f-945c-518cc04b6e34	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b98c9a40-3071-4f92-b85f-49a9f1d22fc8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
195f2a5b-5eb8-4c62-a25c-cd3f6e8a58f6	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0f71ca32-da61-4cfb-afca-802700dcaa65	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ea263848-195e-459c-8997-e5ce9ce9d916	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
159e574e-89a6-45b3-8e7c-8d550e56de00	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ec393b31-ef75-4647-9217-2951bdd9034f	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
3384dceb-5ac5-4e7c-90c9-afeef1e1f82e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
02731bc1-3c34-4ee4-a6a5-25e650224c46	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
60bf0b20-ac5a-46d7-ac95-21c41148972e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
5f661a9a-4fb8-4e29-aa3f-59f465ac2da3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
fb896b2b-c80f-4098-8c03-c7b0bc134f6b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4bbe26bc-5d72-4c0e-8272-08be34ee951f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e0c9d064-d582-420c-9201-cb02d54a2300	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e80ee893-c844-412a-9564-c7a813f00e72	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
316704b8-3f0e-409c-9f7a-c8b4f8d62d87	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
c320acff-adb4-4b9f-86fc-0ef148919443	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
7600b7a6-7d08-44ee-a0a5-a8cb9657476d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b17a18c8-040a-4a62-a915-b2ff4aa7c722	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f18a704d-ac1b-45f4-9fe7-c022d8f7fc46	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f2c59fe2-c45f-4b5f-9656-f088fee62a5a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
95000226-e065-4a6f-94e2-0eb070c81113	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
81020732-ee88-4a37-8472-aead1249bfda	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2329087d-2299-4212-b319-f3418437e988	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4162df94-45c1-467b-a859-6558fb8f2255	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
3001fefb-1ff6-4f97-b86b-6c68ebf55d21	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
06431713-2171-47c1-a8cb-83543bd17769	07771505-6c48-4181-a94a-80816e093af6	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
248c1360-0a9a-4948-a98f-a8026343cf19	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-16	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0132d518-b3cd-412a-83fe-043a2be3fada	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c3198a0b-befc-421c-9761-6aecceca32c0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
db1cff7c-8d02-453a-b2a6-774ad7c410b7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
9c26365c-15c6-4997-aa34-00be8b5295ea	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
2d381441-09a4-4759-9de1-8675fff65f65	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1436d17e-a2fc-4688-95ac-c10461170995	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
3198eefd-8d90-4a4d-a804-c7d3f8278873	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
254c7871-2023-4889-866f-d4324d19919d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c3bbf113-6435-4868-8a01-b53ff7562e6b	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
61b330ab-a702-47ec-b3c3-0e78ee0010c0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
06dd4ec4-844e-48e6-b7cb-39de0cb2ad0d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
cc8165b0-bf76-4397-9bf6-19488c30b9e3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e0bdc85c-a18f-49e6-8ecb-1e48fd81356d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e5047429-a013-4578-a2df-2cc2095a982b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
fc8512fe-5b97-4a4f-aebe-147eff31ea11	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b31913ca-f4ef-42c9-8df9-28be855724d7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c49d50ec-8915-4460-9b5f-edf7556fcaa8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
14830a0d-ee61-4f0e-9115-b09b1e1c1493	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
6125da40-1ac8-4ee4-90bc-78f8d9d879ce	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f8133bb3-1687-43aa-a14f-9dfde0a60786	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7fdf809c-7c21-46d1-aa94-e7c77cb433f4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a42299b5-ca81-4522-8cec-063ffb8be323	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3fa33c82-8d34-406e-9239-4b4ccc13389d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e01721cd-a520-45ab-ae8d-db3ff368a10f	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3ae984db-5b87-4279-ba9a-14bf975ced41	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
400ef4b9-c8f4-473c-a5bf-40e89475cb53	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
389e2413-f654-407c-9591-38ae04ecd133	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9fa24b1a-f93d-4f16-a613-84030fe85762	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e3e41bb8-0de3-4637-ae00-f9b35409e339	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f8bc9f13-8151-479f-a155-2c0f192902c5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
7909bece-9551-443b-bec7-dd214aa5295c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e8baffbd-5c55-40a0-b29b-bf13e62f7e61	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
de4748bf-05d4-4c69-a903-98ba2e5fb806	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
37ceb0c2-f2b7-47e7-befe-e26cca8b795e	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d7c88957-e3ca-4d4b-bb83-8e6e6fe1aae4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
178b96bb-12a4-4bc8-ae41-6b828cd0aa39	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1c73edf7-f379-4cd1-88bb-d97aa930dbc9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9d792d7f-6059-476c-9032-a1c59c0915aa	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
95cb88aa-40d4-4cdf-9c0e-d2a99ce08c9d	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
080f74c8-b991-41a8-95a0-e9210f7c49d0	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
78d2d65a-3927-442f-8833-35a5be5d15e8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
76b7bf34-4902-4955-966f-df9415cec6f7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
af6bde11-742d-4e23-b2f9-b5c781290995	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
617ea2e1-6d05-4293-870e-2c32ff903d67	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
601c65bd-09f2-449a-90ad-6c05abb94cd9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
e01ba3b3-0d94-4b64-bf0f-42d19d2485d0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8381e73f-0721-4740-ba90-2a45d7fb6398	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
2219ec90-9581-4c5a-b790-f648ead46220	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0f9f699e-88f3-425e-91f0-319793db277e	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
95cd4b08-72c2-4846-882e-b12fc5be97bf	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
af527fb0-fc81-4206-8e0c-5bad2110b992	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7ae4dc70-b55b-4295-918b-dd95d984403f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b514cab7-0a30-40a2-816b-088105bec1b6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a8d1b2f7-3e01-4c4c-b67d-d585a8fcdba0	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
644e5530-fcc1-43bd-b0bf-ffb05521a6d8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
42047df1-44fc-4f2c-ba96-b3f2577d2bfe	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1d448d83-6dbe-48be-a452-4a7fde91e6b6	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1339c33d-993b-48b7-b449-41b20770bdb3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
59ea50bb-c05b-4b81-953c-db8e48430af8	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
856f9a7a-7825-405f-a08f-d239744b3e80	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7554abf7-f70d-4587-88e3-5a4abacbecf2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
fc1b4e6f-5e24-4fcb-9a87-eccaf07b0c7f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
70f792ca-0658-4632-9500-a28df776370f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
34677cfc-fbb2-4f7c-b021-71e7ee4159c6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
cf7cb08c-c148-4fb1-88ca-ff8efd6ec72c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5626f5e4-1608-459e-88f3-a41f76043a5c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
bad8b05f-8c4c-47af-a774-087ae5abeeff	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b6b980a8-19f4-4c6a-af75-d44afb23eb18	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
36e51f4f-8b17-49c7-ab64-4832c639b693	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e223d8c1-ce7a-4b5f-bc9b-035f55e66fd9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
6c02a5a6-dcad-40ff-a89f-09280e7ae9bd	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
442c3e64-a5c3-4372-9868-343607bfde86	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
df933225-37ea-4f91-9f94-29a9675c8087	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
01575296-9ab9-4717-9530-11ce75041c36	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f646712d-de31-43bd-8e6e-b2b221ff2d50	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
bdd93aee-a462-4ce3-bc78-2167ea0f2ce3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ea513dd4-d4e1-4480-8a6f-479d76f12d77	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
5ea4e0b0-61ef-43e1-9f5a-8d591e9bf8a7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8bade3b7-a46e-49d0-8c83-092f6abfeaa1	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
98f46ba4-3826-43d4-8977-c58a012e73b3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
31a13eda-2bbc-4fd5-91cb-efa7237266bf	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f1090a8e-d416-4802-a103-53e8dc274733	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
beda00f8-8feb-4b4b-8dcd-1969685e9fd0	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
67ad348d-6c27-47c6-8938-415f21722e8c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e654d4d3-9a8c-4aaa-a91f-1beabc778880	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
dae50ac9-a002-4674-8bec-1a20fe8c1126	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c9e4dc44-af35-4fdf-8193-231882eb00c1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4c620404-d09d-45a9-b764-da2d700c3c73	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
613b262e-66c9-4a02-b5d3-c05362bd7c4c	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ab4b621d-f33b-4ea7-92c8-28b544a9a30e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
915b4940-89b6-4520-8adf-3720b2d937cf	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
302ec13e-0cde-4f8e-a5ba-5497e450a131	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b6865ab9-928a-492c-a689-c1313756914a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
08265f3b-320c-44db-b035-01381c292eea	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
83a086c1-c674-42fe-a3ec-60364bc7f1b8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3df7acb3-466d-4e49-b76d-909e0a01ad0f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
6c9f9da5-06dc-41f6-af8b-d105f3803d77	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
35d365d0-827a-476b-a695-81f6fd6e98ab	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3dbbc54c-d196-4a3c-9692-e85f88958a9a	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
be057200-a646-4b63-b234-4b2499074774	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b40df1c7-8b7a-4be3-b7a5-e8647048d920	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
76319ec3-f335-41c3-8a2f-ca89ce3d263c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f1d56a99-f50a-4ef7-8ba0-b6da3ffd0e10	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3ff38bb9-42d0-483e-a9cd-00a9381ec725	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
ed1cb6f3-b003-437e-bd22-7ba944bc4c2a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
665f5d09-23f5-4dbe-9833-e95e9b5f0e06	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
35658ed6-3d1d-44dd-90df-f7eab61f3898	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
59dfbf81-8700-402f-a079-231c746abb52	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3a172066-56d6-4b7a-85f0-f5ae74334691	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
eae1faad-8deb-44f6-bc22-a357fd80e0b3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a0d53f18-dcfe-4345-835b-9150059fcdda	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
46f41179-c1b2-4677-9db5-073fd1fb5863	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9e56ff5e-f9ac-4e02-b743-af8f8c93a138	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
71236b0f-36c5-47fb-8886-2c71c9dbf197	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
848ef40c-2536-45ff-95b7-6531eaf38466	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e8a302b0-3057-4240-901a-469fbe07ba32	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
cf1368a4-aefa-44cc-8340-15129dcbdffc	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
37155c36-d649-4f4d-a854-2a28509a2c23	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
8faf0937-d46e-4311-804b-054e0e369a27	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
2737c338-2e3d-4e22-9bad-d2dfc83b5314	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4bc213ed-c663-4826-9056-df3b9da56446	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a89caba9-3efa-4761-ad5c-cbaecf1a5fd8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
11830510-9e59-4acc-9d4a-08c2e2fb0841	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
11c40d4c-75fb-41cb-859c-7ee6726c4667	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
057a8ca5-26d7-417e-adaa-7c991b9de187	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9ffcad5d-569a-4641-901d-33c167c685ea	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bdd2fdae-40ee-406e-8237-2662ba60c57d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4955d8f3-4c27-4dfa-a54e-7b16f81277e0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e64479f7-7982-4d8c-8678-23dbf0a82d39	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
dd0e32f2-f896-4464-9934-d39a8972d192	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
1d98de4c-0b27-4200-9f11-71bef32ccab8	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
828c4505-dcab-4348-95a9-3bc3858724b7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6590d2a7-fb2e-46a8-8be3-8becf0300ee6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6591af89-7021-4f44-8f1a-aeb1f6724cb8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
053bcf87-33e5-49b9-82c9-18125918fcbb	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
62c3176f-91e0-44ef-b424-fe86cebaa5d2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
67124c7e-2ef2-4ee7-a430-c75206f37b96	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
3447f005-453a-4f86-a9d3-3ce7d3e353ae	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
06d4a092-ff14-4c6d-be86-884a79db2e84	07771505-6c48-4181-a94a-80816e093af6	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
cfa5408b-690c-4dcc-98b5-29d8bae427c2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-17	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e5cae1aa-b2ae-4e71-842d-7858b218329c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b9c80fd5-5c08-4259-bfa3-f7f6f1f2f48f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
67a727b7-4cd9-4ff1-ab6c-2410d0687203	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1f965362-fb38-4735-b00e-25f5e52681f6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b69f1ddb-13be-4872-b391-ac347d5cb589	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c92c4831-81ec-42c5-b496-a703cc871f52	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a51d2361-7f84-4d09-896e-c77569d4a044	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
79a51493-21af-4b3c-82e1-4de8d02ed303	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c88f435f-4a43-4894-ad75-7048c7b6c199	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e55a197a-527d-4f7e-af65-376be99fc760	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1966732d-cb33-45e9-b9ff-d83af7bca21f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c2fc0154-623f-4e02-a923-50e20b1316a2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
42963f87-ecc4-4ee2-a73e-9cc00cdfee4f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ee4ac9dd-f7ee-45a3-93ad-e21ea0bce2ea	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e908de98-8970-4ba7-92c2-e74335a38104	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
44892bbb-b2ae-4373-bfeb-bf38e56f5ad7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
99f1f016-3ab0-45c8-ad9f-df27f470229f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b9b0edc7-e574-468c-b0c2-bfa3c58732b3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
6d460f0b-2bbe-4c7e-b205-7895e06252c0	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a474662d-5c9a-4dbf-ab29-4ac2a2eb9a80	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a8fb76d4-3526-4e9a-aa0c-84b28c6cd7ab	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c3faf8ee-a962-4101-8bd2-1a33a0511158	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d9c16505-1ac4-496f-9963-56a19d9248c4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
af518893-e547-46ff-aa15-8a39d9d7bfef	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f7271bb4-780e-4c43-b86c-e4f65c9970a1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f20e3fe9-7f92-477b-8512-9512fbe4345b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
e98513dd-9309-4db4-be62-3bdabcb67471	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
57403256-5212-4ac7-882d-12cc49e3442d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
88f87bcb-70f3-4cc3-adde-d04208349df5	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9c66bbc8-59e5-4f85-a967-631733f206ad	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
019be4cf-ef06-4c90-bc3b-11153a54cae0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
49b81deb-ef31-4565-85e4-db46f75a9f8f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f2b8e0af-cc86-4660-afd8-8db4a4006cdb	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3de363d2-4d2f-4233-97a6-1d1cc10dfc20	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
a59ad9b0-6ffe-4ddf-8318-de6449d70b66	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
786a7b38-833b-490e-822a-f395c9783600	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
11a3b965-8ea2-40c0-8efb-2abdf0686561	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
5c526e99-0145-4c02-9c63-c969ec34bd26	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9312cde7-fe97-4d84-9847-dceaf61cd9bf	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e2d0fe10-2422-400e-aaca-b8ef145cb16f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
29babf6e-b3f8-42f8-821c-cfdd827f670c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
48fa22ca-6db6-4553-adf1-29f9ba0b6c32	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a3f8318f-6718-4baa-942f-c1b565f1834a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
1a81e3ca-3370-49c5-ba4a-92be4621680b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a0a84ee7-ada2-4b84-8dd1-d87350076902	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
78f92450-a56e-49b0-a392-60bb878ba604	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f45aff05-ffc0-443e-9127-f8b48be96a5a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
395be5ec-6abc-4b3c-8e49-df64a73fcff2	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
71381987-1f3f-4b8b-84be-ccf7f60e5f28	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8412c452-30e7-41c6-afaf-e744d2c83313	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7bea9326-fd0b-4d18-bb42-989bef5b60a3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
71569a85-3b66-4c8a-a198-5f5f29c5512b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
ad8bca50-0a4b-4975-ad70-76ff43c279dc	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
31f49c92-d87c-4a76-a8e1-a88d16da31d7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
940455de-0c3a-4878-bc65-e56c4514baa9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
83466312-8352-4a31-ab1a-0a791aacbdb5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
57451cc0-6cc4-4076-b1d2-2c81dcc8efdf	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
da084d46-a948-4ff1-b95d-e55f810d0a9c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e7bead7e-7d0a-49ee-b863-dcf4358eb4f9	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
59951687-2dee-4839-9349-af372199c9d5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
614d200f-fbb1-4fda-aeaa-67e01a423954	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c5430eb6-0e26-4a52-bebd-5c5710fd5c50	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
df334702-88ce-46d4-9a77-6e6d180eb4ab	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3687cc3d-36fa-435b-984f-f09d57a8d245	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
968ec90e-a977-45ea-b716-82fc455c7409	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3ec39d9d-97f8-4fdf-a022-d794c1d55094	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5f89375f-6973-4110-a7eb-17bba42f3846	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
8f7c2e87-4401-4586-a97f-cf5453ae315b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9aed8256-e20e-4257-9573-5703ef8b0cb2	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
9f13f46f-3391-4682-9d7d-83fff2ae5d11	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c4490928-d388-492a-b6f6-1b318ec1ae37	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a427dbec-a18e-46e2-978a-0172f7bc31f4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
61a44e64-c132-4601-8d3f-aed1f6693709	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2bc82593-a291-4e4a-a06b-c96a3955b12e	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2b8d32e3-77a2-4bbe-9903-8a62b097b2d5	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8048b471-fab4-4dc1-8688-6bb8472c0a20	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a7102717-06a8-40f5-a4b1-48cf9258ba6e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
dc94b85a-36bb-4768-817b-b9cf075a2aea	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
395c0884-f815-459b-9516-ab037b2281ad	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
b96787dc-f025-47f9-9edf-1c7c0ca7899d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c8b6caf3-101e-4e55-870c-090e277711e2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
939c22df-dfbc-4812-ac2c-2fdffea798c2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8023a340-7ac1-41d9-adf4-3e0662521160	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d68a2c8d-2957-4646-ba0a-33da2dfd6477	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f643a830-6cc2-4bae-9959-d3028a88fda0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7a719e84-f00a-4dc1-b4d7-b6ee63a24cdf	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7c7e3b23-0b48-49ce-9915-cc30f2461b45	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
132b8575-a758-421d-9b24-e8da2125ab4d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
56662dbf-2168-48ab-9ac9-c43a03c1007b	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c7dc172c-2070-417e-a4c5-6c2ac5e661f9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
83d9710a-0a53-438e-8eb1-f0dd62e8a1ec	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
36e074d2-a790-4e3f-8bb8-c85bb1f81479	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f9733845-4e62-46e9-a75e-95204483a99e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
21ff46e7-e58c-45bf-987d-52d5a0d86675	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
2f94158f-9ab2-49d7-a9fe-9911e2956654	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
67d8b17e-2032-4b2e-b060-96031b5a3233	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
78cfa89f-7d6d-4bef-b616-0bbde6abfa8f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c781eb8e-9db5-4d8f-bf99-d93712499982	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
100c3fdc-d009-4283-9f86-ec0c96c30029	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1ca639e6-5cd6-4825-bbdf-7cf42e70ed72	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d53c92ad-ff9e-4575-9bbc-bd7cbf01a0ef	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
fa4e8de8-7de9-4a18-9a33-d2859e7e5c51	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
027d7da8-71ad-4e70-ba9d-b266775c4542	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
806d5af0-ee75-4986-b503-701698b9f3da	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3e2e82a2-cfe1-4f27-a001-93f66184f076	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
458b3dff-b4f9-4118-adea-cebfc49a2b3e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5c416f43-37ca-4c97-b1c8-61ba22e82708	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
be83449f-f3c1-454e-a565-e805814ccf0a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
ab383035-cbf8-4152-be7e-d13c197ced5c	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f285be72-91ac-4c03-ad96-c732ad1d6fcf	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
0d49cb4c-72a6-4e1b-92fe-175cb4db678a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
2ed6b37d-f929-44c5-bad0-3db3f2ff92ad	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
26c80498-570a-4215-b2ca-c9a2625db6c4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
357bad69-2dfe-46a2-a8cc-b40e45095b9e	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
f0151c63-7df7-4a59-b62c-e7ad108718b0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
651c5637-8398-41d4-981a-085b7391a0fd	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b60631bb-d37c-465e-80d0-fe67fd213a4e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
1b97571a-b9f5-4225-b5e8-edccaab04baf	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
fa0301d8-41d8-4740-ab5d-85d95048ec27	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
c8cc3ec6-c7a8-4e67-a3e3-2e8ee839d734	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e2e338a4-6a51-4177-949e-d029a3409a52	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
30e233bb-5b37-4319-b87a-0e13f24d38d3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bf703105-f4d1-43e6-9d51-c9c18dc35891	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bf06fe32-6568-4b93-bafc-d857e20b24c1	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
ad7a5b8b-34f2-41db-9d2c-85c7954f11ba	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
508b97b4-993e-40c8-b4bb-7bec61cd320f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
dace5bda-a1e0-4690-8990-7724d5246168	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8fbedd7a-4231-48f5-af50-e731f9ee3699	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f9b78742-6a93-4515-896f-8a1f59a878f4	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
44dc2eb3-1f8e-4691-82fb-35c48a8398e7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8b497908-3b55-4136-9a96-52f5d9a78272	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
42720fbc-4601-4a89-bde4-4dd7db6eb200	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
95d84330-2c70-48d5-aee8-98a4d470854f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
53243c7b-f178-4193-a634-ca468e43f6b2	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
600a3ed1-7c06-4207-80cb-9b8a7363a122	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a683899e-ce3b-4bd3-acdb-b332087cdc0c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f41fea2f-b094-4439-96a9-bc49c7001422	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0238dda5-e11e-4bcf-81a5-7c1f54f8079a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4b32d340-6092-47f3-a2f7-56f480d487f6	07771505-6c48-4181-a94a-80816e093af6	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6de660ec-eafb-4833-a2b8-68ed04d730ad	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-18	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
eb0825e5-4a49-49c4-b40c-d4708b903845	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
3e5d68ef-4c46-4c3c-9cd3-e9503181005e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0765691b-7949-40ff-b5d5-76e6a23d9b6b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
9a4fed60-1b3e-440c-8957-a4c8432709d9	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
db0fe971-b56f-45ff-932c-f963c92b867f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
66ab8022-2d3b-4cd1-a12b-f10f7a7d26cc	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
181325a1-481e-422a-b4dc-5e0e0dd4a999	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
eeba39ec-2c6c-4d80-ac55-9ffe769ef189	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
afb9466a-3cc4-4ef0-bd9e-ae9a24771d7f	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
49c3f135-b8ca-4360-906f-6cfd0e29fc30	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
336f14fc-539e-4f13-8160-4a9ece2cde9e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8701d47d-6f5c-4f1a-a251-4941a2cb57e9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
106453a3-7cf9-413c-bd8c-13bde0a0c0b7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
88d5608d-f42b-44d9-accd-0e44c8247cc6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8f1232e8-52a2-47d2-9b16-3414bc9661ee	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
825e86a2-a884-4cf7-98ee-72e9a3d16f17	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
cb865cb2-2112-4766-a28c-808b9cfc26de	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
d94356ba-745d-4e29-baae-586d796dfac8	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c9574a25-8253-40fb-88fb-1fc46a2fa71e	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8d4c789a-db83-413f-aabb-9d16d940cdea	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
9ad3674e-c705-4e53-9539-93d44f588451	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8388d8f0-8b24-4730-b42f-17fa48eb24b8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
afd94700-5c79-4cea-9c98-0094f05675ca	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
77ac4862-7f9d-444a-9c17-e0f1ee0d27a8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
cbfbb33d-a772-4492-a7c8-eeff9f4b3b3f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8a8a8749-7cba-4ff5-aa84-8ffeaece1431	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5de803a8-1a27-42a3-842a-912cbfa8944a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
db07f7c7-8ab2-45d1-8729-3210acd3c8ee	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c3f40198-2b0b-4034-8a53-8663571b53e7	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5742741d-0ec7-4e66-a20c-f11c49e3d413	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
88a960af-3cf7-491d-a996-bfec5b3504fb	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6f1259ff-edb6-4952-81ba-f9b773c15d45	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f49d04e4-5dc3-4007-925e-51021bd94e5c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0a7d5b63-1e1c-42d4-92ef-034b9a49d998	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8b811c6c-4f72-453a-afe9-0bd08b61743a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f67766b7-6bb8-4769-9693-96c535f263fc	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
478d15ad-6084-4eed-9109-6c42f378842f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
5e8b9830-32cc-4a9e-a365-18ca4706b181	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
28b04990-3940-48b9-8d23-be7b08a2adb5	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
758db206-9663-4dc9-af5b-c14ebaea83dc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8de34cc7-456b-4e6a-a691-b272211c4a88	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a8b6feb1-8340-4da0-9405-d5be7f302e6d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a418f6d0-f760-4ee0-874d-3ef4e11e544b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f729ea3a-c7f3-452f-82b1-db3f57bedc67	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
96c402cf-c87d-43d5-b18d-d26525b6db3d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d65416cc-8bef-4a00-98db-9df2f4b8236d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
2108f179-92da-41b2-847f-c9ed8b86866f	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
82fac36a-2ca6-414c-9700-963a8e72e099	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c3add729-1407-4867-aabe-e1798b0e8c67	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
74af7770-aab8-469e-85c8-b75c016e8d92	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f2702193-79dc-4178-80fe-e94f0d5065f2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9adc30b7-7d82-4f1c-942c-3fe9fafb14ed	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1c95afe6-f6ed-49a9-8c7a-62fb92a88f14	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e277cccb-c380-43ff-bef2-30ea2d6f1859	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a640c7dc-f809-4a9d-aa11-d240d25d64fb	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
70478dda-f870-4be1-931d-335945aebdb9	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7e24a3b3-1259-4a83-9032-b4c921be57bc	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b8b3df79-6875-4e90-88bb-e3f0ab4c69b5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
25e7fd41-b602-4dc2-ae7a-f27a07f0b2da	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0753c1ef-6af3-4dce-86c7-dde7dd084557	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6ab7b13e-2850-4196-b61f-4e678c8c483d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
0df8ead3-52b2-477f-98b2-538155d60ad1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
78520afa-d1ee-4461-bf39-0daa5e4cdf94	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
67ae4ece-de01-4394-98b3-b1a4196cd519	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ed8a0ab8-6cf1-4316-8fc4-03141a8aac18	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a71b3491-ed19-4b4b-9381-75f5f378a31e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2fc71781-f343-41fb-81f5-f50d74c84de6	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4dd1fd30-1773-4c50-9b06-9d9c1702aa80	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
604094c7-837e-4693-8cd8-93d76e050ba7	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
81353d3e-590d-4858-9e16-725161a1cda1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a937c7e6-354b-4ef0-9fed-e93615087574	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
95f603ea-d68d-4de8-a9cd-87489fabc542	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
b067a510-4e05-4f50-9818-1b3164bc0452	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
fa89db74-5e87-456b-bb10-85a9e47ffcc0	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2c357bb0-596d-433c-a795-b757f9e469b9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
59b19210-e62c-483c-9fdf-6846dd21d033	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
5265b5a3-5d91-459c-87c9-46c411880787	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8adad84d-7755-4a5a-a4ce-b57988a5a2d1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a963a7a3-fbdf-4063-ae87-9f6676d2f640	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7c78b08e-eb90-423a-8fb1-5e31669aca35	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
324c8939-616c-4dad-9dce-608a8e26d863	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
6b5de152-55ca-42c8-966a-c182019156a0	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
2b77d3f6-127c-4d96-ab3d-d0ed196899a0	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c4c21ea7-b76c-4f4a-bbf5-b1200bdccfc2	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
26109db0-019b-45c2-bfe0-33e6267b2db6	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
420b6b00-6bf2-45c1-b68d-50e695018044	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
111f5598-207f-4076-8bf3-8e92754608e7	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e559c7d7-057d-4d77-aa79-7570d93158a9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e7d905eb-4b5e-411d-b72d-7d0dd23e14ab	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
41e971de-f059-475c-8a55-4794b07afc7f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
75a281a9-3149-43c6-8c4f-c53492774420	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
096246e4-2c61-49a7-98b0-c274fa607caf	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
33b8195e-d43b-49d2-b8f2-00b82d5e8ce4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5517cc67-e1e7-4472-b6f5-c966922b58a7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
563f6c23-4850-4ddd-827a-82abbf77f861	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
267fddaf-ab84-485d-b0cc-ac0f4963ea06	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d166aac0-916a-472a-8ed0-d8c0722a7333	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
0dc8919c-b624-4fa0-8845-bc86601e28f5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9bcd6194-9372-4b2f-b82f-2296235770c4	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5a0a2ec7-c5e1-45c6-9fe3-32c322033300	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5afb72f6-1f30-44e1-9326-c126a28a4495	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2d138617-38b9-4e2f-ab14-28179119a17c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
aefd1e82-83da-406e-aea7-2bae83f94154	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
11d62ed7-64b3-491b-b9e9-03212c77be83	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
12360b64-7cb8-48d0-a098-03b7ed3ece7c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
9a0c4574-b9e6-44a0-9754-4d0045204d1c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e21d5c2e-e4d5-442d-8bc0-889166b36c2b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
1dc258a4-b23d-4693-a4ef-de4d4660852e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
82751d69-ef5a-4abb-a268-32180468b54e	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
ba35dae4-ea60-4404-a73b-3616f46b80e3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a9135895-46c6-4e4e-a7ad-f6cf009f1395	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d20eeee2-96d1-4150-93ff-88f2b9271e06	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ad471d39-f350-4c06-9db3-6865741b4174	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
46fe2381-3d9f-4ca2-bb48-59904c0ec282	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5858d3d0-7c20-4a16-b6da-dc564f8ee0a1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d4939d24-1c92-4eff-9e34-b636b0798c54	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d4be14c4-ba61-40f4-9623-8b4a6219c339	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9699a47f-7b0c-4f4c-8b2e-7f59db43bacc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
dfa2eaac-adf0-48e2-b34b-9488dafc3bde	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
02ce8e3a-dfce-4bc5-9e0e-c3b5b1334ad2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
adf9d274-68ca-4298-b0d8-69c6eeb44fd3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
26ec76be-2637-4f34-9666-f3aa0fc5b508	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
d7a3654c-20ad-46c3-a017-35afa11ef31a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0b0d7512-532f-4591-b7d5-1d3007b9b027	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0ccd272b-f199-4fca-9654-abc7f121f489	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
be4f2042-58b9-42ca-b6c4-f35389d4c6f2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
7c19ca2a-4d59-4d02-8506-4b8a5cb3c0f4	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
89989161-9ff8-42a6-9aad-9edd8d9fd750	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
71dae331-7f64-4886-b334-e2594ba827af	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4cf67bb1-a732-4247-99d5-d9c9d45e6890	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
2451cdbf-993f-4816-8c12-11e35cba25ee	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
fac9e28b-d4d7-4a22-bc52-b9cf92d9f369	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
bf3b4468-9f33-4a2a-88fd-f608396222c6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a9577198-8563-450e-9b36-dfd597f2fa80	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a74f735c-6143-45f7-a2cf-a185758078bf	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c5e24ec6-5905-4f59-97aa-3eb6e13a6685	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
1ad5943e-9d99-4839-8352-4da5e59a99c3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
87a884c1-6bdc-4f09-9fde-3adee409c782	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
08ee0721-936b-43bf-a775-930de9f2c6c9	07771505-6c48-4181-a94a-80816e093af6	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
875a82d4-4c91-45c5-a303-5af3ece07524	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-19	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d4d86e6b-ed21-4d47-82e2-2be88374e382	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
4781b797-ea64-4f2b-b23e-c75aa9f7a8b5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7dca33ab-3337-4320-9967-1c32b0480d5b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
b7b36234-ee17-48b9-beac-643e0763cca6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
5d029b2b-8141-43a6-8877-1ddfaf46bc5d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
def2f1c9-991b-43ee-9a48-ae80037a789d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f66a8e47-1150-4ef5-8bff-ebc9ab70988e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7b623091-a324-4628-ba15-c621b28c0ce6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
fd74ba79-9b36-410c-9ca2-ba36f90adf01	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
89c42aac-c490-4964-8f6c-c914a95c04b1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
94b969b7-d0dc-432f-89e8-fdf0f13c7532	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
035f936a-7b36-4911-9e0f-dc918013e78f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
2b14f349-4fc0-43ba-828e-707dd5836b44	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f49e460d-d539-4e5a-833a-dc9047f6b2ba	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
68821262-8a9c-4909-be21-60a57e1b2fca	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f4d9f6a8-5d15-4b0b-9733-358baf143ffd	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
42b90b62-f9e5-4f11-a189-4f2ed32fd916	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b6e04220-70fb-4511-b2fe-b726f7b682a3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8a635b1a-9dee-4628-bf86-cf0733aae785	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
05a8f2b7-d5eb-4e70-a269-10d86af7d668	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ac40bb7a-3987-447c-b24a-4fe2b08b9751	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9ff42cba-285c-48d7-a9c3-a43606d38fcd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ae45aeb1-6767-41d9-a030-d6bcb051e451	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
173df5f2-3811-4d3d-b072-6b7f55cfd5ff	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
fa1d08f3-7180-4535-b56c-ecbaa201a5a6	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
59b6dbb1-b61a-4b90-b2ac-0f4b9e6a7abf	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
da2f6041-b00c-4bb4-91d0-7c91cd985e2b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
a29ccbfe-76d4-4cfe-9d31-413fe9f4b895	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
382aef03-7d03-4bd0-bb96-9e136616b052	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c0636eae-1331-4467-810a-6f85fa05f5e1	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
7f2c8bf7-974b-4747-8288-3d1b82488e5b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2121f734-b185-4cff-8795-e9a535af46f2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0e6987cf-85f5-4ab3-88a2-d2f743a7bfa8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
85299bdd-e542-4f03-b365-7c54d9772ebc	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
be87c856-095a-438e-b577-babb93dabf4b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9de51d0f-446e-4016-9e58-74bc9b7c958d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
16dd56a2-be2e-4b41-8dd3-a005832cc051	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
ed59dff8-2502-43b2-83ce-9275ead199a2	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1c190f72-03df-4f96-b5c7-2668db41cf1e	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
5f34c093-5542-40a3-80f6-594a176bd4ee	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2efb2d92-6d0d-4114-9d69-556431b6a07e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
93410399-fcdc-4480-8f32-d596af3830b3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
94e520f5-f903-492a-82d1-9b0d0d3ecedd	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
056c4f74-7df0-487a-b5e9-8f90fc8cc3c0	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
97684cbe-82ed-4de9-ad1e-792caaa4dba1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
7d0d2742-fd85-49ec-ba8c-e096698159a8	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
bddec921-2285-4a87-8273-6f79588a5788	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
9814d625-a151-4804-9b7f-6aa86b1745a5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
cfebe9af-bd66-45e1-aab0-36efa63181e4	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8cd57078-83d4-4d21-b5b5-60151548dcf8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8cf51c00-a66d-486c-b439-ced79d36e79a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
d77a0103-518e-4765-9091-91c491cfb99c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
062d84c5-db5d-4c64-b7b2-a76a8fab2add	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
dcfd72f9-8a4b-48d1-b8f7-60ea88ac21dc	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b3b532fe-d7b9-4fb6-81f1-41c6e98039ee	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
7eacbcd6-c052-4a43-9e85-947f15ee520a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
65c9e3a2-220d-4620-91e9-44a5d5df8c3e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
837ee998-7531-40ce-a0be-686561e4bc5e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
dc04d67d-8031-416d-9189-fd7ec9f3d9b4	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
4ba3b25d-d6a6-4ee6-b883-c93d4881ab36	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
3b0c1ff0-d0e6-40df-b872-d3a45aa00c4c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4522d003-0f6c-47b9-985c-b006fd283f04	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
6345d418-fd71-4806-8f07-40e085a8d084	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5b71e938-e74b-433c-abb5-1a2100fe355f	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
86f3fb01-490c-4d29-860b-b18e6e42129b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5414fbc5-cb85-4375-9fd3-8084654f533f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
f0b254b9-3f06-4a6b-8b45-612da5e09446	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
794a757f-a1a7-40d5-81a4-1a4b7319f18b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a2569633-2684-44c7-8948-593f658dcbae	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
f06a5477-22e6-4313-821b-5a3c279bca07	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
742927b4-933a-4f8c-9c7d-8abc12de67da	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2e61fc50-7a5c-47de-8ae5-672ced81817d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c22e3048-405f-48c4-afbe-fa65a1ef72b8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6771a543-6ab9-4f8b-a148-41bc313f5ef4	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
bca11ed4-7d57-494e-9fc6-69dc3db33cdd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
179eb443-8748-4583-9225-69090449c49b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ca7c9e4d-3d3a-40c8-912a-e360409fff7b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9c1b1e1b-68db-4c59-a5ee-5a6d48a88e1d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
5a18ccc3-4087-410c-b9a9-98f99717caf5	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e3ec58e8-dfee-4ea9-aafd-fd347e9ee92a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
df5cbef4-ec17-48a4-9c96-a1c7bef62bf2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
3f6a8eaa-1d39-4f69-9b11-fc253787e7bd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7e1d9442-a9b6-40c3-bac8-e61357ecb230	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b74ec97f-7216-4e88-9138-99e6082de94d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
812ea8a3-22e5-41e8-8146-142556838ea3	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
66d20f79-438d-4422-b8e5-7d86b73871aa	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8e1c6dce-dd09-4786-bfb1-979876cbc612	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8c4d25de-ab04-42cb-a58c-f1ec4175f4cb	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
257b335c-787f-4be7-98b0-cb335764c0aa	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ed5d5d90-794f-4ae2-8e6a-3723ef6d8705	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d0618fb6-051f-45f3-8cae-994497684675	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
2eade3e1-aec3-4bf9-9a6c-b3d5ed4535ba	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5e61cd3f-53bc-4673-836f-ef882a00257b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f2bd6037-cce4-463a-a04a-ac70a40c7afc	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
581a9618-292d-4876-9796-35b686586554	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8c9a8dec-bd41-4a8f-ae5a-128be53c2979	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7e7a33cf-2038-4494-850f-8bae659d3431	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
393b569b-32b7-471c-93c7-2a95ddc22ead	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a8b6f2b3-3afe-4a6c-b863-56e3eea4bfb9	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e3832709-c1e6-415a-8631-4f9a4776ff2d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1ecfba93-287a-4fbf-9a71-1041a0038ec9	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
9057b51f-3a78-4c1b-b7c7-f8f39e1952b7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b63acb6a-77b4-4813-902f-ff419001f388	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
222fa1ab-7c99-4b9b-b7ed-0286071a03c4	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
6e321f4e-d3e2-4dc8-8a4b-0de9263af752	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e8258ed8-206d-47dc-87b4-61d1aadfd99c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b9d78666-74c4-40b9-84c4-d5b63a238147	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c755b970-bf91-4c3e-aa7d-e4f2a8195c92	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b89448b1-b69a-4fb5-a46b-1b2a5713fe78	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a5479597-bd34-469f-888c-55253b974076	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
8e82e881-ce7c-48e1-bf7e-b5f340848192	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
95afad69-9f46-4189-8179-d973ac23f649	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
08ca140a-fda7-47a1-9419-230217b2fe06	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7a7fb92d-e55e-423a-bc5b-b708853df2be	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
3c88c112-bde4-48eb-8d77-c76564568f5d	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0e14d258-344c-4ade-9f1a-6cdfdca08cdd	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ec71a447-39ef-433e-a6c9-cb72393cdd78	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
982da4ce-31a6-47eb-9e46-e9876b766697	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
3998779c-5aee-4e9f-961a-4380cf8991ed	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ce6b4f7e-700e-46ce-be19-7a3750045426	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
351fab73-54a1-4638-aa8c-c0fdc4c4247c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8e1f33b0-58bc-4def-ab69-38a1e66cb666	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
95d81e3f-7a71-40fc-a188-2f6a3215c7ed	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8b9a93e4-79bc-4a0a-9b09-f651b686050a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
00aa9b3a-04f4-419f-94ea-0608d61295da	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
44c4aca9-1258-4a0d-a1f7-a945a679ccb2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6553572c-f77b-4c3c-a923-74f776a77915	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f308fb6b-bca4-49e1-9a26-205510a28e33	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4b8b1448-aa37-4b95-aea8-c8337b41a849	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
42b989c9-295e-4aef-9fcc-8d265a85c461	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
02a3e44e-af7a-4557-9b5d-1c02fb4dcb80	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4df2254d-3392-4097-9f43-c3c30d3d0ffd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b8029511-a996-4b0c-b71f-0820767ad132	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
449c80de-3ad6-40c3-9d0d-1eb8fb4ae713	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d91cba7f-04b9-4b1b-9b2f-8d3d108bbd40	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
8e313b8b-6089-448c-9e91-2988a71c1b7b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2d944fdc-9b3d-466b-b350-50beeed5682e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
58bb4cec-b2df-4322-ba31-88f82e48ab2b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
fd905935-05a7-45bb-b939-7d1a8fb7440c	07771505-6c48-4181-a94a-80816e093af6	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2c625a62-c2e4-43fb-8ad8-ddf1d0f887e2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-20	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c0fe0d23-fcc0-4166-90dc-e615b7d84063	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7748dade-e9dc-4227-a5c7-1387a6815608	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
df2d6593-456a-4592-8ed9-abfd17c0981b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f330b92a-90a5-4889-ae57-7c1e21a324b5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d750d42d-9366-41d6-91e0-301d2b8bd426	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ed658009-45b0-41b9-b962-8d05a198daf4	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
4ca45239-8865-4761-b63d-175c42ccaf5d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
5d81ecd9-cab9-4d84-9ce4-fa9c2955e155	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
abd6a270-0f62-44b1-9d17-abf85087d08c	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
867c2540-1836-473a-ada9-0c91e61e4830	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7e5aea93-3174-4451-903e-6c3b0993bfa3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
96fa9702-2353-43be-af95-e7407c4e7ec7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
039d98f1-c2f3-4d34-9248-1dc75f6afc9b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
06f79b1f-4ba1-480a-b1ac-20ca86649100	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ff002a91-f8e3-4743-a64c-05b9f5d59885	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f6723d73-17c1-423e-abac-e3abbcb0f362	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
44b0650c-179d-43fb-b887-82245b4fc219	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c98b3cfa-018e-45ce-98f4-bdec76a364e3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
7753c4f2-2229-4102-9dec-d6c3365c6f85	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
25c059e9-585e-43be-9d42-0a3bef3b5698	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a2dea26e-060d-494e-a7de-487b848ce805	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ab2a2271-95a4-4320-a4d5-69382a4077fd	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
021eec7a-50dd-4270-a226-4dcdff003ed1	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
210b605d-260a-43a4-acfd-eacc03dfcbb4	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d72a598b-5cf7-4a06-9b49-203bbe572bc4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0db6855d-cbf7-440c-9f32-cfe9edd8c8e6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5bd820a0-dc3f-4429-820f-8b579e1beb6a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6521a64d-36dd-40b6-8c08-60a43f79b8b3	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8a86e36b-5142-4fd7-b742-2c0d5945d6e2	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4242312e-50c2-4a95-9de1-01e17fd46623	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4b90e3fb-80c2-4cc3-9ffe-24200fcabc16	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
5b009413-3855-4878-8e1d-91909b49b790	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b4a79c3f-6297-41d5-9f43-c925f75a783c	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
bb3696bc-bb52-4775-b45e-f4b3f6ac8b1c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d54c0673-93f9-4812-94c7-48850dd9efe3	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b19cd531-f6da-47c3-9110-95edc58228a6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
05202bf9-166e-42ea-9ddc-e57a95c51ace	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
356df825-9f94-400d-b5d9-01ded8871752	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
af0e6fb2-ca88-4943-b966-63c039ff6d39	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
09098d84-c7ac-42fe-b6df-36fd6e49d38f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
60096875-1326-458b-b8b4-23a8e10ad0a0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6e8a8dd0-d1bc-4c12-a5fd-309b84d18d43	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
76503571-6103-40fa-907e-15c25fc7e2d4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f54967ab-3e56-4a80-b006-ad322b7a3b49	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8672872b-9206-4933-b13f-946ed81d78e1	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
931404e1-d246-4204-9bc7-fcc68034d01d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d70087cf-c628-4a5b-b511-ff02c308fd8b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c54d079b-6ab0-442a-bc26-d3ccdd9d0552	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
e1803624-df43-46a3-9a8e-f417077d7608	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
4a9419db-fe86-4a3d-a58b-9bef75e531ae	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
42e3f45f-f5c1-4cef-873c-936cf6ec12e6	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
76106f3f-ca56-43f5-93ff-fe24b517d593	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b3cc4047-1919-4304-b2af-fc9ee30c0978	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
311b6a37-00ca-427f-90cf-9138a6b93a42	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
d460f740-7ae3-4bf6-a036-f61a4fa0b418	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
10bb7aa4-e0d4-4654-944b-2c0013cca0b9	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
ad5ea635-5a91-4c53-b63d-0f7d0fe751a0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1be10278-9aa5-4725-b536-323a085b3b79	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1f641470-88f4-485f-94f1-a5541bc2a419	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
66683d21-745d-4b83-a664-50819b09244c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
40b46ef2-f2a1-440f-9193-8aa871716d74	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
7d9c763a-6951-4edd-957f-2ffcef326d66	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e18fc45b-c0d6-4e41-ab88-f7fad9f56f83	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
05208ea1-3678-4262-9d9c-d3001043348e	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5151b862-ea52-4129-a877-2a1136dee20f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d3591eb6-5b74-4d87-a385-88c77c0a1681	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
350806fa-5abc-468d-a322-6858594f5344	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
61f0e857-f5ef-4196-80aa-8efc876f1a12	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2cd273b4-f946-4670-8550-9712bd1cdfc9	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
8b440859-830f-4f24-a2e1-2755b8868540	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ff649a3d-64d8-43df-9111-282665e505f1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ed242429-1fc4-4c33-ac4a-867e16951c10	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9bfa4c42-933e-406c-b587-82f91fbe190a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2a6f382b-0254-47fe-bd77-e8d74eb585d2	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
eacc5919-7e16-4370-9518-62c6f5e5b9e7	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
63c0f8ec-8c59-4528-bcb3-ea45bba7ca4c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ffd08ada-87dd-423d-8b18-cadb2cecd15b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
51039640-c309-4059-a979-2dedf664b66b	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f7cbcef9-56e3-490c-8001-d25770b9d29c	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f0cae6f2-3905-4208-b50e-96d9a15dfec8	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2dc7413c-958f-4b35-b795-caf6ada09ae3	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
59f6eb15-29ae-434e-9cd2-282c490aa065	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f0e47343-7f50-4b14-b2d5-cbed51c7eeef	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
074d9675-68d1-46e5-8ed2-1d69ae80bf00	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
d21d754d-a6ac-4b9d-93aa-634ba4fa6298	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ec9677b7-88f3-4b24-a00d-f997f26bbf96	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e6925236-ca4c-4e54-9672-ae9e632a59e8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
5e66e4b4-5d04-4e1b-990d-80621e5d1df5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ec208ce1-7a4d-4eb5-ab96-bb0a76c55ec3	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
216a0076-6f0c-460b-9b98-7bece5ab985f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ccc553cf-201a-49fb-bb0e-5e535bf91f50	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d47d3f98-31b9-414c-a07d-3b559fe9fa85	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
8661b14c-6cab-45c1-9963-3e3051374c0a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b4ebc398-3ac0-4cf8-8594-fcbcce0c155f	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e4f8d9b7-f008-4b7f-828e-989d2232dbbf	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1317f63c-e709-4c2a-8027-7331d69f9f46	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7b191356-73b2-4ee7-827c-11dc1a219d27	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
55e83f67-4703-44a5-8ec3-cf713b8a7841	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
b141fbce-5c06-4b54-9225-c839d37e79d8	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
fd78e941-e94d-4331-855b-43fad17fa2bc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f8b8f6b7-1575-44da-b7e2-ed102f909295	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
922bb1c7-d79b-4136-8296-ecc044bfcb29	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a3114b5e-c8f6-4861-81ce-0d7de917c478	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
58ebb7c4-96d0-4ce0-bf9a-014f5bf05031	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3e01818e-2743-41d9-b16d-a5f3dc3e959e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
9cb88604-776d-400b-a025-492dee25dae2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
35a60b52-6a7e-4ed3-b643-0600d4294ebd	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
96e89655-b288-4b56-9624-d608e2bb9b14	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
73a30d3d-0bfa-43bb-b56a-44a9f1bc6704	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
3ad19c95-7eff-400b-95a7-380d0d965df2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
d8a23305-0150-43ea-917e-146e7242b79f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e4ce7f6a-0a42-4b5f-9c62-d55e050b8bd9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
c7ee9ca1-da28-4f8f-8373-7bdb56a5ae61	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
218f913a-f3bb-4ce6-8063-97610b3b5e50	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
fbe4acdc-7bd1-4da2-a911-36ca841d3f3a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
96505594-e669-4d7d-a1ce-5fb4e95be483	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
30192d3f-4493-4b8a-b65f-c066af49dab3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
3a24b77f-f55c-4b3d-819a-021bff4fe6fb	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
40085b5d-acf1-4cc7-9ac7-baae8a5a1421	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
411b576b-585e-4ec6-b091-ecce76440c1f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
79903072-0ac4-48be-80e2-d35439d0f7c7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0099f1e4-062a-4249-9f2e-81f2bfc2393f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
274d50d7-d02c-4614-9fa1-5aaa1cced8f2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
0c9f0b8a-dc6d-48e4-ab22-dfbfbbc82573	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
64a32b10-eee1-41c7-a244-ef1290c822fa	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
328081db-095d-4f18-8b6c-f4b60d29bbf6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9c4a9f9b-7b81-4168-aad9-8ced688fa8a1	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
51f1ab19-ca39-4766-a075-3e4a373d2cac	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6570c1f7-cb55-4e20-8b68-85d8d3b623ec	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6776b967-e2aa-4750-a869-c208ade650b3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
6355b482-27df-48c3-b89a-fd39ac4a1d23	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f307180b-0fa0-4b2f-b50c-6e2cb02ea9cc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d8270cc2-51d9-4757-9f2f-a0ebd07c6916	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
020b5ef3-ab28-4972-b023-0bebd8328bb6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
975f128f-d751-4b9e-b608-bad07553dc31	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
373e17d3-1dda-425d-8883-41910348a630	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a7e32440-ff54-4e27-a96e-0c1db8175bff	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b8f56369-011c-43c4-a51d-efc167151434	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c90efad5-6b2b-4fdf-810a-788068e08835	07771505-6c48-4181-a94a-80816e093af6	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
de2d99ae-1f40-4428-b528-a66965825ff5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-21	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ca21321b-9b4d-46c2-8de4-7d7508b06096	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d807e5c4-3fb2-4b3f-91a1-4ef2f9cbfea7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
4cab2e1f-0a04-41ba-9e39-0ed2ef9ae5b6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
6094d053-3ae7-439e-abe7-93642d3f8573	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
77833250-c596-4e3a-b708-dfa407992021	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
72e751c0-165a-4340-bfe6-65d9c2f4d163	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
9f21820c-76d9-4120-8e5c-f8654b17abe4	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
3f6a6af4-678e-434b-8c38-8bee7efe660e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a52106f4-d7f5-4968-a1e0-ee51ab1ca242	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
a2f5c3b8-ba3c-4183-ba20-9727806d4183	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d7a28f72-edbf-4ba3-b1f4-8ab0371a0c74	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
f3803b86-71e8-49dd-a7c4-901e53a1b00a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c045800c-ac82-4cea-86f6-13d51f81aa8a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
8bedf2f5-61d3-46d8-ba7a-f3b0fdf4980e	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e79a7d5f-2bfb-4eea-9b28-70ce01a341fd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
227f6d30-310a-47db-9ec5-3e6bac6ea358	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
19b14326-18bf-4622-9e9b-88cf39575e0b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5cc3317e-54c2-4d57-b6ba-531f01341042	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
bcfcffc2-4baa-4efc-a90a-ffa9b9b06881	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
19048997-d34a-4716-bd7f-3abfa1434092	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
c4038e74-5cde-4f40-abc6-17fac7976325	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
017e4f19-e806-4540-8080-deff6ad01022	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ead86e6c-afe0-4bf4-8cec-06bceb76a48d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
35ab4c11-e316-43c0-990b-19c18fbb3012	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
497e2a52-559c-4ec0-bf80-abcd1ef4bb84	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
98c062a5-5906-479b-b56f-6b917bbae51f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6336200f-5318-4289-bd93-2bb029af9e88	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
feb86533-58f6-45ad-a36c-b66e03c66ca6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
eb5c13a5-331d-4712-ac8d-b59b0267ad14	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3a17a9fb-39d6-4635-b4d4-d0149a194bda	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
47732c5d-e4f3-408a-9c20-ca6cc1ef83a0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c4c49657-31d0-4de5-bd72-169324c835f3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
779d08e5-98aa-417a-82b8-955edcec975d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
4d94288b-55ce-450b-af96-0a76da64e2a5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2a2b40df-be01-4f0b-ba9f-9f651b146217	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8203f6ee-b002-4e31-b955-ccda2e4db85a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
78cda0dc-d18c-4861-9bb5-5a8ffff6fd42	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
43f3e862-4eec-43cb-a4fc-0eac01f17560	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3837b0c1-5192-466f-a241-4fb2f6595ce0	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
abcdbc92-0877-4875-8517-4ffc10cfa464	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
4e5733de-cf27-4a93-87b5-333164857d6e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d2ce7cc7-757b-4999-8997-35b996d468ec	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
702be57e-9ad4-4042-b693-d2f4044e2f18	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d6114930-bae9-4c2e-93a9-bda5639398ae	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
742f652a-1d00-4bd5-84df-5b95acdbdf4f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
61e14a50-071f-413f-9c15-abf21c3d1bfb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
bebdda02-bc2e-4220-bf01-acc1f7465dd9	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
5e0aca1b-d4c6-4d7d-b0d0-88a8fb4c77f1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
98f70fb2-5099-42ac-872b-25177f63d50e	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a3c9a46d-e922-4131-88e2-bc43fc383c11	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0ef07fc6-b12d-4822-b343-5e02b933e57f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
425d562f-4c00-4a41-9f5a-9491c56f8916	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
f3ccb57c-a5cb-4a31-b47c-aa090cf23602	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
e0662dcc-6d44-49c9-b90f-715e75a07c67	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6d83efef-92c8-4208-b70e-faf6bbd96857	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
559684a6-3370-4aa6-9574-bcd377ed5d7b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
a70c6837-1a49-4e21-872f-ec5400e1e44d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
045e67e5-4352-439f-aa97-ea7fb90d24cd	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
0ebbb67d-7617-471e-87eb-e3eee87273aa	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
ff392718-1134-45c9-a7f3-89e3744e1184	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
61575d23-079a-4f68-9b19-3cddf82e4366	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d5a72385-69a8-4889-9a80-c6715dba84e9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c2177510-f9fa-4b96-a228-28f7a81923e5	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
77d81452-36b5-4cf6-ade0-93bfb5bcb20d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4f721c6f-5454-407e-af55-ffbbf02beb43	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
427721b0-7414-4b4f-b6bc-c1c46e4118bb	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5746946b-14c5-445d-959b-7f8231c8bc58	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
03c4ff00-fdb3-4269-b5dc-d18144803a79	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ed97c79e-3f3e-438f-90ac-6ef2de0c7a64	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
39e514d6-d660-47be-bd78-9adcd75ff27e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
624bc20b-203a-4ea1-9a67-ca1985b1e82c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a2f4d4c6-cb43-468a-baa9-f76b650965af	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8b69e85f-474f-4460-92e8-0d1b0e192e45	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
6c2624b5-bca0-4308-a956-12d82b8f836b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
afea01f0-f041-49b9-8fa2-dcff910aae03	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
302e3e0a-c6d7-48b5-a3c7-b729d9c4231a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
2dc49e72-3352-459a-b085-e2e461ec64ff	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
ed06eb49-99b5-4e6a-b67f-5a02e69589b0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a4738bbe-91e9-4a9f-b3f2-fdc5c13d1bf9	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f2484830-4b89-49ef-bc6e-3a060e3859a4	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
508d38e7-6f5f-412d-b67d-0a6ae6421e4f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
360f0fdd-8a2e-4422-898f-5b2da257042d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f06817a8-0d9f-475c-aa8f-5b6d923182d0	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
69054197-3051-4ce2-986f-70bfc13fe3d5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7d6e77cc-141b-4230-a258-78f9e49d8bcd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
3a2bea72-a822-45f2-ab49-57c68cbdda1c	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8726bd46-ed97-4674-97bb-ed46ad5bba94	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1c8fec2d-cb67-45d6-aab3-c5ab47499b20	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8657a2a9-76e5-4ee8-97c8-b80529f2a00f	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
42dd9f79-47e8-4b0d-b4e0-9dad8d458f89	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7b84c6e0-511c-4b73-9ab0-bea28bb24626	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
3fca9674-4c5d-4108-924e-e984d75ce890	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
fc9679a7-a9f5-4a9c-bd4c-21b9813c50b6	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
789cedb9-7940-4c6b-b3d2-6ab9f275e349	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
fe6796db-41d9-48f1-81dc-a18ca215f5bc	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5483290d-9c26-4fc8-87ab-ccd573455508	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
bdd1f567-3696-4044-9e1f-38b00b33f0e8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
552c87aa-3059-4efc-8fe0-38e8454cc80c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4d418298-9ca4-491d-a174-7ec4fc053036	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4d80ed49-a04e-47c1-90a2-ca3d427cd258	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c5275d45-3c07-4dee-a266-7baf26c809d1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
58a9ec4d-9110-4e3d-90fd-f115722440d9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f0f0c18a-9a00-441c-a005-061c07bffd7a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c44282e3-c2d2-4bf3-945b-d8744b8f5a59	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b9fe64eb-f4bd-48e3-8206-86d84dde31cd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
24418b5f-b1e9-4563-8eae-7bef2c56af07	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
7c6fbaaa-a8c8-472c-8099-bbe6493d51eb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
061fd298-e90f-4213-bc0f-0ad2ac186aaf	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
060731d4-bb03-4df3-a417-dd036c7f9607	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f4a7a5f2-be79-436a-aeba-6bb745f2b403	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
52b645d0-02b5-45ce-a0fa-f205c5f87932	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
1c8d35e0-fdf1-480a-bd42-396062572f49	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
dcbde537-dc74-400b-a390-5a323cf83baa	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
3e19a374-f540-4a5f-ab70-c1b85b4a6ae9	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9e01026e-0e01-4c93-b7a3-3aa6809b4ad3	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
70b165ca-9320-4b65-855f-c526289e88f5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
de504c42-9d4d-4dea-a014-9aaa577be984	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
53f5b2fd-ef3c-4219-8d84-07e997484dc9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d96b53b7-d0ad-4135-8f02-175b0b314653	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
f32652d8-12cd-42a2-bf79-cb35f51fa99f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
89ab23f6-2469-405d-9670-3cb6d8f7a3f5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b5a6dfe4-82bd-4375-b9d5-a77123cb59df	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
41a15537-1d13-47ba-b8fc-9d73457ec770	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e20ecc4b-c9d8-4610-8ffd-180f60669dce	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b3e10153-3f74-4e4d-b3bc-54f4860b7ce0	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
129c92ef-ed36-415c-968b-269092e65a64	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b6a33388-ecb3-4ce3-bcb1-21482276e5aa	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
50db5ed1-fe5d-426c-8a0d-b46ffb949ead	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
838ab52f-862f-46c2-8c1a-bb5014e5836b	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3dd6ccff-e987-493f-8067-72c62bdf239a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
07760870-36c8-47b0-ac47-d698947f5938	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ae8a84c8-40eb-4090-a78f-11924c79eabc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
629443a8-0379-4610-b1cf-76734e110bb1	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
23de0517-7df4-463f-a871-ed9af1569486	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4b4501ec-d394-498f-a16c-b6e3e03894b4	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
a4861a30-c9d5-4760-9dcb-edce574d7890	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
e79acc21-349c-424d-bd19-7e1546c57a33	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b2122829-859a-426a-8acc-d74b66ba6acd	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7fd1f4ea-b9d1-41a4-9a9a-fce46a9a19eb	07771505-6c48-4181-a94a-80816e093af6	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c2ef9325-eab1-4e57-8d2a-0414976e1c6f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-22	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
7c036cb9-0a72-40f2-91b4-3e774b3e65e7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
244a2d60-5d7a-4098-9ea9-2c2f9066758b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
060915a7-24ed-4629-a9ea-b965abd8be9d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
aabe84de-3103-41af-a774-ea5385c682f8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ab65efe9-ac3f-4dca-93e2-dbd4d1d0e252	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
929d928a-2dca-414e-bb3d-e6d01b35fc1b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1bdaafeb-ef43-46c8-9752-42137971605c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
78068db2-7115-49ad-8a04-d6d3e4f86b4e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
e0bd203b-bff0-462b-b70f-6318765202da	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
2dbf2c70-5976-4a56-a56e-66c7e258ad98	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
7a8934eb-44bb-4526-85f6-b80fd36529e0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
4b1c934e-9362-4d23-9a43-4ec9ae8dd7fb	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
dc62f234-5dfe-4cab-9871-998b3d9a410b	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5cb01192-3164-447e-a721-97a7885e5c97	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
58c0d658-0eb4-436a-9c4e-68e4ed7c183c	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
123c601c-3959-49cd-832e-6ae19b44b956	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a3c2e1e7-2928-4c34-b65f-29d65907ad33	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a937e610-7553-4d57-94e4-6606c86cc076	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b40d5a61-1446-4cc9-8dbc-9e3adea0a9b2	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e071372f-a475-42b2-93e6-3738c4aa188d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
b67ddeae-954c-4d99-a3ef-c0b9bca9364e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
528b801a-9ffe-45c0-88ea-d10eb0df2a2b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9b1c5914-f5e4-4277-9dfa-cea94b7db035	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
58d93a7e-87d0-424b-89b4-33415773cfff	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
76f7bc17-f1e1-49be-b714-0a55d3e91408	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4c793ac2-d60f-4ba2-b3ca-1c59e646fb37	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
714566c8-e220-4bc2-ac27-8a5c50e7e9b3	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
14a97019-a2aa-4acf-9651-408776afdd57	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f125631c-f2d2-47b3-8049-f48f0ed3e8c8	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5b30f2ce-4860-4e72-a7a7-d061b2a0fd4f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ef790dcf-e0a7-4895-9d38-c3df255e1928	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3a383682-1242-44cb-8a41-bdd6ff009cdb	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
a567cdce-ff2d-413e-a8a0-52eedc150491	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8efbde57-db91-48c3-9525-2a24ce0d504c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
d7e7e62b-e907-4fb6-b872-b579ade0de40	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e7a274f8-296c-4ff4-b7b0-dcc32aa5515f	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
35b100b2-6341-407c-a399-c232a20a6dec	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e92bcd00-d5db-4335-9695-d43c85c84b4d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
70a99766-a50a-4a1e-ad7e-65e079584238	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9b3758ff-729f-49c0-8b9a-8a868b32e6b7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
cb5ad41e-a123-4719-be31-4ecbff0be169	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c666214a-525c-491a-90aa-8b4bcc32ad8f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6b56635e-169e-4918-92cc-98f7c7d436f4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
02c0c9fc-bd10-4108-b654-7ee75107e9b6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
2554dc77-1f03-423f-a4f6-851698e869ca	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0e8e96cc-bd1a-45a9-831e-3c28f512e990	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
5bcd0f44-47d8-4b68-b32c-8d7740441c1a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ef629c84-84f4-4ab5-a57b-c3b02d1334d9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
100fdf09-b65c-4b48-8942-f0a2f1e9adbe	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8a37a587-c9fa-468d-86e4-bab96a6ddf95	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b3bde45f-8a69-4f38-a809-2835fdcf366f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c8f4c626-cc8f-4ce1-8265-0b3d0c231fc8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
d6f17df0-96c2-4123-9b9b-29b70825b952	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
dc43c550-2280-4f13-bb0d-7d7130c7be6c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c6a94282-d36b-4907-8fc2-4ffeb93536d2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c783ab10-b42b-4348-90a0-303b8979bbc6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
ceb3c409-8fcc-431f-8b6c-2adcbb1af990	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
79ed3627-5192-49df-8309-d7377adf2321	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
aa20445e-a248-4e5d-ba03-0414075ac80b	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
93bed036-f9b9-4d2a-8d69-159ae4dd4e2e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
4188f0be-c4c9-416b-8bf5-1979a0702d81	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
731d9bdf-3646-4e76-a2f5-69d1116ee36c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
bed41341-9829-4521-a35f-cc08709ba993	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
1a3b7c54-41ee-4ddd-88f9-c3d90687fdad	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
abf6cf72-a472-455a-a5d9-416f96fd095b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
5ce6470f-8202-4dd4-856d-f31af97b04f2	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
6a78e892-cfc7-4b8d-a8cf-a5367024b8bf	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b20b0683-1080-4c94-a7fe-9dbc4f4b7326	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
6706fc2d-2c89-499b-ab81-d92b81856403	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2cefb6b8-874c-4c5a-8e57-0f8de29d1609	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
c852a487-6333-4376-87de-6339a791970d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c2947338-f0ec-42b6-94c3-ab6eb9c8adf5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e07336f1-8dfd-452a-88a3-a5d1b778a030	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
308bc084-b187-4974-9bb0-94c8f94b0748	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e36857d3-0e18-44ea-86ae-13c772dfff3a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
0f03f184-c48b-406b-bc90-7068baa5bc4e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a81d6a98-0337-44bb-aec4-46f29f14fe75	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
a3224784-8346-4e1c-a4e0-0b1cde00a113	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7f8b9ff4-22fd-4c6a-a3c0-6afca3303a38	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7611313d-cd6f-44c2-b065-ec68c051d8e3	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
cff2cd51-4ae8-404b-99e3-5f92592b8705	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
bb534337-9faf-4a53-902d-dd98e18865c8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b33830ef-8d04-42f6-9181-73ad545c4b57	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
0c27d63c-e1c0-45da-90ca-340a4a861992	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7f7e8f08-e40c-45b2-9f9b-7b2a47a05534	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4ea5a7d6-90e3-4e48-be93-b668b5484431	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
733838fd-fb5c-4bcc-89a3-f7f31a1540bb	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1e8989e2-74ee-40eb-8af1-0ed569b7a078	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
27e531e1-a2b7-49cc-8966-e17358561477	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
68f8576e-3204-46c7-aa28-db06d7cf8136	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
82075f68-fd2f-4a2f-947a-7c30330cb5b7	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
6b177a46-b744-41a8-ab75-996f42bacf82	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e5493e41-7b48-4afd-9103-5bcc53b522f0	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
19faab29-9a19-4523-bb2b-9c1c60a7adcf	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
dc816079-8e78-4c08-ab8b-bdca4073e115	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
30f3c078-0947-4c94-b4a5-8e1aed5d18f3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
10a383c2-2fb0-436a-8015-6d86eb739194	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
24012493-3de7-4c64-b457-f7bde81c0c69	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9d3fb7a8-1be6-4f79-8d81-271d797d491c	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
170db68d-3dd8-4747-8033-3b9c80b2a746	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
94aa1be8-9fbe-4222-91f7-fc4138ebd73b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f0e9d91b-6c5b-4df2-8628-d23250e36d1c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e9ed1543-b906-44fc-8e54-4837ee6d2ee8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
c85de6b5-9db5-4c7f-9248-bc2bd09fa0e4	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
983b7378-7fd3-4c70-bdc7-64bf23a52bee	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
67b3741c-5e4a-46e6-9d25-3cd720933ef5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
794f0fe5-c959-4379-bc6c-d830c2be294c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b0f8a9af-4b6d-4777-88eb-a8dd59ef5db5	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
fa85267c-9d42-4c5b-8613-3495401f41a5	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
be23f3e9-4bb9-4301-a02d-e07a12561c4b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
12f3dd41-a5b4-4ee8-a9d2-ea2586eb6124	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
65a8d547-3ecd-4dbd-b2cd-aa606b431da2	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
c7586a72-a4c8-4267-ab6e-d51f8fb722fd	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
bd306e52-55e2-42e8-8304-a6d9e3f41e31	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
64510876-ed74-49a3-89f1-6f29b20c2a8b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a63dd1ed-7a5a-4387-9beb-528133c07e35	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5ca3d439-3f26-402d-8721-eff07d841242	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e7918544-cab9-4806-ba65-20ad478c219e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
21f2874a-0181-4131-aa0d-7ac812ec53cc	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
11060f44-31cd-400b-933a-6766cecde496	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d4231eaf-c5c9-4f74-90c1-676c087f1b59	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
8b816ddf-2565-4041-afab-3ea7d4d7a17c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a2b822b0-198f-4c77-8bc1-8e964baea17d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
838610e0-350a-45b6-8a28-17d82d2d3260	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
c7f22367-9566-4b56-832d-8985a5d3fcde	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
63141e51-a267-468a-b7d9-3f571612b960	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f9803d1b-b010-430c-9747-c2ae77be1a52	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
acf504b7-87c8-4d49-b812-1789653cd0fb	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
9dc8a039-2c39-4f3f-a38f-17f0f5370c3d	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
68b1c39c-94dd-4b21-a7a5-20299bd39ec6	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
31e65da5-9148-4517-8e42-392450cd1aec	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
80354320-1df8-407f-8d15-3a0c64f1ebfb	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
24bf7116-9393-493c-85d5-2bc0730ee3d3	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
fd3aad36-b63f-4751-9c04-fcf3296b46e9	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
38e549fb-0cba-4928-bd0d-12a4805ea136	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ed962d93-1ad3-4e79-aca5-5aa6ee7339ba	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
59e2a322-15db-4017-a7af-28bf37e94b57	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4727682f-4c58-46af-9d88-53d641b1283e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
be771ca7-c82f-4a96-aaf4-fdf6e04fa58f	07771505-6c48-4181-a94a-80816e093af6	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
cb46f772-c23d-49ae-a547-86e40d3b61fe	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-23	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4680ac5d-5704-4ade-b4fa-eb910e2dd86a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1d4d444e-eee3-410e-b411-22d7014ebe2f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
df09accb-7bd9-4978-baa5-c1639de16d73	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
99097c25-3c79-4ced-b73b-481673d79d97	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
40dc1ce8-4949-451f-990a-5629bfd2dbcd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ed894f24-93cb-4e51-aee1-bc2a6a03c2ca	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
6506daba-d240-41a3-a1c4-ae52cf45a73c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
40c48e9d-1d8c-4f97-9e15-eba86236c91e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
5f0b1edf-3d84-427e-944c-35d018f68e25	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
280bed37-f564-49b5-8511-2857cc339a60	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
2af6c62c-697f-4d76-a4b5-c272ae09eb3c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
2d49e91b-feeb-43f9-b85c-8928a691296a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
6529f011-f5dd-4949-aa7e-6eae3559c57d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
666b2703-2069-4766-8b99-87a3fe19623b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
824eab33-03c7-4187-9ad2-8a19d2b2b31b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5e8cc45e-36bb-4c0e-8832-8cda90851bc6	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
82149c55-c717-47ce-be31-5e027aab5999	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
83b0b543-b6d9-422a-98f8-9030007248fd	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
3ea08c5e-d1a9-457d-b6cf-8a1c7e9497f0	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
a569cc0c-18b2-4764-83af-cadea05c066d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
52ba9722-2678-413f-b4b9-28ad367a00c2	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
8b5df4cf-295a-49db-8d04-2ecc7b392b48	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
dff9dd22-f6af-4016-8577-e55f93b2eec8	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
3fafe86d-9d53-4cea-b6c8-df8d97f42ea3	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d77ec3a9-5ea2-4060-b3f7-17672ecc7f45	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
42a355c1-1cb4-4eab-b70d-15fad02320f1	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
60ee5b78-ce0b-4754-8a57-cf65bb6d2c50	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0ad3c891-96f4-4dba-8aee-4051794900d1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
37ce11f6-e9c4-402e-b992-b9ad58987a11	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
f16b7ac6-3d45-4adc-9d8c-a876060a8909	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
289d10e9-f637-4225-8688-e47cc2ba8f3b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
08b6f3ce-e8e4-4a04-9ac7-45b98733a435	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
fdfdcf58-eecd-4c35-8325-7189ddaa5ce2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
bcb8970f-a26b-4073-8519-f35768ee3f71	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3cc88e74-0650-4094-bb37-9161989e05b8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
85cd6ced-3229-4805-8edc-be0aba4214b5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
af6dfd26-fe86-4859-b650-b51fbef6de7a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
495659c7-7776-4f2f-b6bd-8ef45e81ad1d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e55a8092-4153-4950-82fb-03e89f63df9a	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8dd7350d-ece9-400d-826c-57b028d945de	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
e09a85af-1061-4175-a40a-c1fb95bff829	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
fdabe3ea-a69c-4411-ad5d-e385c3b48ad4	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8a635628-1b33-49a1-802c-67247c0a5af1	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8be90da5-a7ef-47e8-b562-26c55fee97fc	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
330d3c16-312a-4a82-aeca-74390a393136	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d64d8455-2ce4-4df9-969b-27134e099b30	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
4468ef78-306d-46aa-bd89-3f3cdf62b3a8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
c8eb8d0b-f52b-40f4-8fb5-e5cb828165f7	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
09c9c4d2-8493-4bb0-9322-7541f5199160	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
476c9e0e-31a7-4253-834d-77441c7c10d9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
59846c45-71fb-4e61-bca5-ee1aa4068404	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
f69ed6a9-ef10-4ace-ae58-eb8dbcedb681	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2fcdd5d1-1904-49a1-837f-1da8c9019301	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6cb2e78c-6682-4967-96ee-6bab5eb07a24	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1a0e1807-ebb2-45a9-a8e0-0a6486336c2a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8ce9e6fd-c0e7-46c5-aa32-86f85fd76789	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
6c6095c9-d155-417c-ac01-907a9e915252	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
1c6cef61-f7bb-4b50-b13c-939cfc3df566	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
f10e0e1d-563e-4127-be84-c7437b348adc	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
999efad0-cbd3-4341-910b-776492388494	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
be337a24-6711-4ad2-b779-ca81e6b3c4f5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
57daea47-15a2-4424-a4c7-7fecfeec951d	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
36a5149c-d621-4571-9397-ffeb0a449de2	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
bca8feb0-cb79-4e44-afbb-4ce76843d4e5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2a5f8bd5-0630-48ee-ac5b-84d07e92154a	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2dcb4d79-e4f4-45c5-ae5c-00e4d13cd921	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
00bb18d5-366d-489f-972d-53902873aa09	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
06841653-a887-4d7c-9a64-15fddc1b86bb	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
fe392d43-e75a-43ba-8502-d4911185bd29	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
35103782-b634-40e0-8b15-72c0de0109fa	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
84c08775-e686-474f-9d31-f09c6946b5a1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
dd441179-b759-4aa4-a3ae-ab0b6ae2fd46	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
97c5a275-f690-457d-85aa-724a0f92548e	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9c24cf04-0a88-495c-97db-5574ec036cbe	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
97fbeede-8095-46f8-a260-f756910fda5f	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
88ac927a-a0d3-4344-b589-bf8264ebc4b1	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
657010d5-46fa-44e7-b51b-fa2f02884e12	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f9377cd5-d340-4bf1-988c-ca2219cfbec0	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
d8714440-5b36-43ae-bcf8-527b86e0eaed	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
d2ea5f74-4599-4bf7-8ba2-dbfd9d666ab9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f4156974-531d-4087-8645-cdee86a57b21	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
9d847605-7344-4f31-b16a-4a5376fccf6a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b8888cda-65b1-4408-8cea-eee9673df979	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
30a397c8-16da-497d-9ac9-34abfc0196b9	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a7ea42e1-8630-4246-b9b6-b12805bb4a43	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e9fed9ea-c1e1-49fb-8d12-6403d30d9159	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
f452194a-1e2f-48c2-8aa9-8de5774d2989	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
02df86a3-632e-46b1-9a09-6f57e6e5615f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
6b72ce6d-5ef4-4684-b3af-81a668fa1590	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
dd09e604-db46-425b-972f-950397a9de43	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ea9fc852-1111-4229-b5c4-05b4527fa76a	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
9d7b5c76-9dd8-4d85-b769-e1c696ab98d3	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
5bf1877a-c960-4363-afc9-721c00b2f7c7	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d91de032-fc9c-4c5f-bfbc-084d755188ba	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
6fca67e8-4840-4aac-8f6e-7cbcf5cdeb81	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
7f84642b-9dbd-43b2-9637-1bd5b0356b19	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4e4700bf-79b7-40b8-bc52-7f76fa19ea7e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ae41ac33-0112-4c75-9edb-022a881b1fe9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d862f26a-0e34-4362-b48c-a286d6cb0e38	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
34b58a01-763e-4b07-9c93-74d550ddfa78	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
c8534769-3220-48c1-9e69-5bddef52c1ab	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
b279c7a9-d752-4337-bcf5-2dccde0ca601	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
90aed5ad-9dde-4962-a05b-cdbc37ba78bd	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e21e5f7f-d800-4c14-af7b-e921c9009c4c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
da17ab7a-2638-47db-97f0-0254bcaf201e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
36584c97-1369-4ff6-b089-9226ad0161ba	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e4ecedf7-fc78-4076-963a-90e6f28a9bb2	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
15cb808f-99f4-45b2-89e2-64f082900e1c	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2befcbd2-601d-4ba3-bc4a-c66cdab555b7	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
10d259e9-ffe8-4ad1-a603-5c87b8d0555b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
ad80a65f-d892-4c64-937d-6caa979f1887	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
11c71b87-c1b7-41c9-84d8-71de951d9e28	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
38c417c4-c27f-4402-9814-866d315e04f4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b02a8aa3-0bee-4c94-82a6-7df7ae5a6289	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
15c61853-9300-4218-9128-94744828efa8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e413250e-c25a-4cad-96f8-f235380ac715	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
5f516917-3e26-44cd-a02e-cb204c4d30da	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d748083d-2efc-4deb-b1fe-67539d881d6f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
dd444862-599a-4747-94f1-70b8fa7b8d04	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
dcf5b7fb-301f-4bb3-b20d-d49685566035	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
931f2b6c-b697-476b-9ff5-aa93aee79c5e	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
dfb1f8b2-58e2-4d59-b036-5f6604a27544	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
794d25a7-cd7a-4bfe-ab19-1fe0796247be	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
5c7cc463-332c-4357-81ac-17fbac5ea542	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3e6bf8ba-14b3-45ad-9805-feddea557ae5	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
dd77aa33-d266-45c6-b79b-4f97b9fa8926	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4b8ffa05-7a6e-463e-861c-5afe5c4c8f0a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
2ac294c0-6a1d-4911-818b-50ca3df078d9	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
2e3112a3-653f-4ae3-830b-006853faa7ad	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a7ef454c-b79f-4f7f-88d2-f4e303cdf97e	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f4423f5d-51c4-455b-b8a4-2cba5932a112	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
94f0ea5d-4511-494b-81b0-42c16e768cc1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
eb8ee31a-6115-476b-bd55-210aa7b89cff	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
da0611bc-5b6f-465f-b07c-f67557d5b1e5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
fb985705-4de1-4de0-81b8-c87f5dadef5b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
4c12871c-7dcb-42cf-88fd-1c321bab78c1	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
8d01149d-25f0-47f1-aee2-7435e903c5c8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
64746407-32e6-41aa-8d2c-aef244fb4303	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f1b9a2a9-76b0-4ace-98c6-8b9714cdf582	07771505-6c48-4181-a94a-80816e093af6	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
2e1895a3-3292-4bd7-8263-14d7652d1688	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-24	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
90512e7b-1a61-4cb4-894a-54849dd9a163	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
c66918ab-bb8f-4034-aea4-ad3665436611	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
61607b1f-61c0-4ac5-b60a-68817e048b79	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
629b5f14-847a-4a27-87ac-dd0ffadaf660	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
f13bae02-7354-46a3-a7e2-515d0d50b50b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
40f9e186-c584-481a-a2af-f4b83168b8aa	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
0d8da302-7785-49c1-bf40-a945ab213a27	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
1a80dd2f-32c2-4fb0-a9c0-0045df2350a7	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
fe7e357e-1180-4120-860d-db3fbb9280a1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
60d26bb9-df6b-4fa2-b473-fd555072c0da	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
506be0ac-b536-4841-bcca-d2b01c820935	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
06d0f1a2-cadf-4f0e-aada-a3decbd940c6	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
35102c53-43ea-44ef-833b-496beb4fe585	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
2326845f-3fc9-412f-9612-ddaf9d21413d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
95c9a942-ea38-4bdd-a771-ee9905c6242d	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
80e42a20-c623-4cf1-9698-cc16a1a76900	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
ec411c67-db86-486c-add3-5f81557b99dd	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
08eeb9f7-2597-4084-b58f-f25e4f760c82	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
bf486ddd-593a-4cdc-a115-f70bb5715e40	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
ff65190c-6e92-46b6-b1a2-11383fff4bea	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
300e0fe1-bcab-48a2-bb33-9dd3a6db64e1	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0ae53aa0-de18-4fdd-bf9f-a357b4a9672e	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
68939d77-2726-49b8-b1c4-77deb4743ac9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
9ef39c71-465d-4ad3-803f-0ea099170dab	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5a059328-f420-48bc-9dc1-870f691beb3a	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
08c9c91d-817c-4b98-bc22-e14fbba2c729	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
6548cc6c-510f-4c78-96a4-9024c79e44af	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
c1194281-ca6f-4395-9b50-fd7f3d0a809c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
d8bf2962-98c8-47ba-bd52-85ec2fc35b9b	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
9673fe82-d4fe-4dc6-9a82-70c5900127b8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
4d50c3aa-48a3-42ef-b090-9a1d1f27700d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
8d65608b-59df-4417-9821-9957ff1854e0	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f381e32f-494d-457a-a5fa-87a210c68319	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b9ecf11d-5347-4bb7-8651-2836cefc3773	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
1d697592-7395-431d-be9f-26f31aa9cec8	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
64fd5f42-725f-4596-bf64-5596c709e953	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2482e1c0-6314-412b-b886-b26ee5a6ccd8	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
c8f25f72-4e70-49a9-af31-474646e337e2	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
f3dd7a97-e28a-4af2-9a54-eb2f632fd551	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
1e6af486-5cf8-4801-91f8-ffea60a0ae6b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d268f4fd-cbaa-42f5-8011-e2f59769eb0a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
702dae09-26ad-47e6-b0b9-913241813c84	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
e3005f33-6967-4d0b-a57e-2c1880d68cee	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b9f23844-c895-42ad-bbaa-4e56621e80f5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a360545d-b9f4-4e42-8f9c-8a0e1b235b66	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
8871c497-ea84-444b-aab5-27a4390d7a14	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
881a4858-7636-4e77-97bb-5fc139aefc65	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d7ecf8d9-c1a6-41b2-a346-a44d66d99d9d	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
f27c0b54-72b5-4afb-8f6d-12aab2295218	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
cdf4c0d8-fad7-4312-8690-12f054d77336	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
b5529155-c7b1-43d2-b1b2-ce4b7a4f346b	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
c215f7f9-7f6d-47a9-b351-7531d4efffb6	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
d864e175-7e34-483b-8024-dbc74e1aaff5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
ee2d38c0-4d49-4b17-908d-ccaf079a0c24	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
69d75426-71a3-402d-b820-4ecdc059e259	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
fd740de5-2fea-461e-b14d-f082e55c482a	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
9641c60d-555c-4407-aa82-e872297d7a1a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8567ae48-289f-4374-be01-b9a652f3b86d	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
24c39a02-2963-4d62-9a50-4589716f8501	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b237c43e-c73e-4b4a-b5d4-f33a3e9c2127	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4faa74a1-0844-4b71-954d-4db2be8c57b4	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a071fe6c-94df-4e55-a1da-f14236b559c2	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
b717f5a5-63a3-4628-96ab-6a00c38a28d7	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
473e6a5d-5336-4ff0-9b7e-18a763769267	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
bb4c5539-ac34-48e1-872c-d323d7051a90	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
ea4e8e92-07f8-416d-990b-ebc50a0dedb1	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
61b76377-863e-4074-a11f-baa7e990ab06	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
e5e83f21-ecb5-4b6c-9e38-4922181606f9	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
9b2ef7ac-10a8-448f-a909-5e6e04259854	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
a279fcf1-b270-44c2-a1f0-87d2e41bc603	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	13:00:00	14:00:00	f	2025-06-26 16:04:19.537149+00
7bb1b207-0d97-4808-880e-3f9a154d937f	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
573f278c-70a9-4537-ab4e-cbc65f7b8723	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
7edde5f4-7cc4-43fa-91b8-43f3b6cfdfc7	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
31c65a73-c451-4d42-8046-0f147ac99088	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e08e42c0-b80a-4090-80d9-8b75f5f7fd31	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4e520428-2958-45a6-aba9-54cd85c50651	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
4d21d042-e4ba-4f1e-a5f4-b664d9b8b939	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
d62618c3-b7d5-45a9-a809-af8c559fc2ee	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
e74e35e3-6f39-4473-9991-239fe00b1c9f	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
f5690423-d1b5-4489-8112-8785eb9f2500	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
8109740b-b379-4ee9-aaaf-6e763423ac59	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ad7adee8-a2f8-4aaf-9a95-8c7fc4628e09	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e89a5539-5458-4fb0-a45c-bf05b2cce57d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
3ae2bc9c-5a3c-42b0-a53b-a1772e4af449	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
906a2e4b-a184-4ef9-a018-2a207571ea42	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
a36db89d-44d3-4809-a48e-a40ca2e8f2b0	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
acd6924c-5321-4870-8d2b-bc2936839355	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ba3336ab-3dd4-444d-a7a9-a3597a527474	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
e3fac3e2-c478-420b-84b9-bc8440f41aab	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
c4af10ca-d240-4d58-bf4e-1d84740cdc93	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
1e762c92-b59f-441f-a686-60904eb5603c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
37a49061-c7ae-4536-a6a7-3824e58a0a14	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
53f06de5-ca16-42a1-a8ed-cf39b47af519	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
2d1176c2-4126-4523-b0a0-af55cbc9dea9	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
4d27f419-67be-4926-ba97-11ad4d7f6515	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
f0e5602a-1770-4405-86f2-917e9030ce41	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e2224838-eb32-4e08-85b6-14dbcb1af51e	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
bdc0fd10-634e-419a-9283-0dcbe4589fdd	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
382240c0-0e27-40a8-ad16-eb920f995650	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
660ab128-dd84-4a4b-bc37-29b48923d185	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e57032b9-93ee-440a-8499-6468dae932f1	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
72c8bd27-40b6-4508-8fb7-aff63a27057f	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
be0cfb92-5d03-4345-acc0-755dd44c5c4d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
5442e41c-dfc4-40cc-aaaa-c011136ff5bd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
82784f98-fe5b-4144-b3b0-b87af961c6fe	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
42b48b94-cdc7-47c0-9e60-b87428875331	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
f666105c-29c0-4674-98d7-7e73d59e9eb4	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
69b55e1d-128e-4d68-b774-313a8c32dbd1	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
de4e3d6c-3296-4f76-9905-415662b3d2c9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e64adc12-b0a0-4b28-9878-57094943368c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
fe7318dc-0684-4cd1-8acf-f4e4823ed14a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
d32d1530-08d5-45e3-8a02-63508b882caf	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
8aaef0ce-4a8f-4a87-a273-41d7d4a9e754	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
e49c0dd0-603d-482e-a37a-2b809dfc2436	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
31f20371-d442-42d2-b5e1-0a2804b7c04b	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
a8c356a2-1612-464f-8d51-78afe7e7c989	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b55299dc-2220-47b3-8107-e595b19fc889	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
7c5159f7-798c-4c72-a38b-8346014e0909	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0f66354a-4e34-4ce9-8fd1-73ae7a3d1a53	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
c237a66c-e179-403a-8f28-a02ac2b45785	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
176f3d3c-f3b4-4e06-a6b3-d282e1f545c8	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
32964abf-e025-4c06-9337-7590b0a56d19	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
fcb1c19a-83a4-44a1-b9f0-8c9d79436dfb	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
d798f2b2-0f99-4bfe-b0c3-0cc06ccb5b4e	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
77343c14-4d52-4240-bdcc-0ab5ff4c24ea	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
15b21028-320f-413f-91e5-29b655ed96a5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
bad58297-a004-43fc-bb43-2748302e86f6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
f5caaa66-395f-4f3a-a308-1267d9306e91	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
e5994563-c7c5-4aaf-93df-f6d5f26926b9	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
3f791fd6-8ef8-4ba9-8aac-185b4852823f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
99bfa1ad-3674-49e6-84a3-40ad41d0a14c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6dbb777c-3f3b-4d41-8551-105d1b8d70d5	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
09c30be1-f859-4ae1-95ac-6bacd1fd904d	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
f97ab864-9e4a-4c6a-a610-ed73d5858610	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c709a9be-a2dd-4feb-b3d2-0ff86f88144a	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
ff8a9a89-c7a4-4533-a089-9d51e101af61	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
889c56f3-513e-4ddd-96b3-4a0d42f3bc22	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
00a15a53-abdc-4f2d-8a35-86338107b8d4	07771505-6c48-4181-a94a-80816e093af6	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
78a01c11-5c71-4d2b-99c9-1da1b4ddadae	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-25	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
3a083844-32b6-4dfb-b6c5-7b82467fef1c	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
cb038fd3-3ad2-4d45-a2d4-9b2eeccef0c5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
34969098-f464-4809-9bcd-e3d71b5dad95	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
62832704-aa68-4725-b946-f188d1774c39	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
704bcb35-e5d8-495f-8b37-47c5f1d3dbdc	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
5621c14d-e134-4101-8eda-f0790603ea01	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
910fba19-ad3a-4738-8999-a07a8edbafcd	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
d0f738bc-24a7-4193-8da2-056681a00c5a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
2c347da6-3f18-46ac-ac7c-3ff2c7e5a2a0	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
aeba2db8-5746-4e08-b4f7-c675cd2cdb36	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	08:00:00	09:00:00	t	2025-06-26 16:04:19.537149+00
ef62c446-a78d-4dc0-97ee-f40e797c2c84	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
94a974ac-acb7-4659-9a00-d5fbab9e97e9	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
19a028c3-d6d6-432a-aeb2-541653a86f31	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
5ac02ed1-3328-4ca8-99b1-1375380845f5	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
db3124b9-1cba-4873-889f-33830d29a252	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
79c8acb8-19fb-4fcf-832b-6f868b3e713e	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
26289efc-fa39-4dc4-806e-6defb244c397	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
53563a39-f9f5-4a86-b5de-aef03c31d22a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
bc8a5f0a-722d-47f2-965f-69bdee1a02c9	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
e63ec01f-6372-4fca-b482-d8789326b4d5	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
52410e29-678f-4bf5-a88a-7f215077930f	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
4f837f29-b113-4fbd-8237-2495e9cb4459	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
98e6f3c7-38e5-407b-a7fa-d681ca03be43	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
49fa1d36-668f-401c-939e-a5687d50f1ef	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
65931066-17c4-4df8-8e7f-24925022296b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
1ec3a13c-5b87-43ce-b5f2-a43e5d8ed4d3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
7a5a58d3-5ae3-40c0-82f8-9ceec644d50b	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
81cb2c66-c56f-4a1e-b9c4-466da9dbeb41	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
2a1509e2-176e-46ed-aaf2-08e374ed41c4	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
0d8ea8ca-0f86-40dd-84eb-3bd934811f6b	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	10:00:00	11:00:00	t	2025-06-26 16:04:19.537149+00
5f9d8895-fdd2-4142-8849-39c5b514f8c0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
a2de78e8-0f1b-4b3f-938e-ecf2afb514fa	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
27891f93-7906-49bf-8d37-cbe6a0cd4657	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
12530894-772e-47d8-80a2-6d95349dfc03	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
2da01e20-3256-4ee2-899f-6b070670dbec	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
de382180-9ff5-426e-88c0-6333ddd79923	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
3a9567a3-df32-4f97-80b4-f16ead07ef5c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
4430ff30-d3df-459e-9f8f-c6d8927128be	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
0f1c6483-8602-4097-ab7f-ccf7de87917a	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
6db65d28-b94c-495e-9f2a-4eb17d6a5786	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	11:00:00	12:00:00	t	2025-06-26 16:04:19.537149+00
b4ec67df-5966-4df4-83e0-d13373d17dd5	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
04b4428f-3244-4eee-8ca3-bfd07fe1653e	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
490f535f-23c8-44c0-8b50-dd2a9791e7ef	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
ec06ab6f-cfab-454d-9b40-cb26ee84bf91	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
6a122c92-1010-4843-8fc4-f338cc7e4a24	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
333aa1c6-f5e1-47fc-8cd4-e01446a053e3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
a24a1230-541f-4062-8977-6938845b8720	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
b61623cc-10b1-405f-9c19-08115e9b43cc	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
0a76277d-0bf3-4863-9a8f-72080257d63d	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
cd38ed5f-5c0c-4bbc-a396-d3f746f33071	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	12:00:00	13:00:00	t	2025-06-26 16:04:19.537149+00
d264f3fa-a73c-4e06-b7d0-0beb61eb0430	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
28662c0c-4815-4ae2-8c18-af97f5a8f6bc	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
8a9d60fa-18fe-4545-bb15-74cf07ae8348	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
53019812-c47a-4ae2-a06c-a525087f194c	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
87333453-8b88-4c6b-bccd-ce870d0910c7	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
3151d0b6-f91e-4ffa-bcfe-bf6a475dc868	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
d71f4143-f89c-40f6-8b53-f611fa0c55e4	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
5ee49e3d-1b98-4d05-9e27-700611449c1f	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
79953366-985f-4148-ae8b-041825eea227	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
2349ba1a-69eb-46a5-b953-58b258c6cd18	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	13:00:00	14:00:00	t	2025-06-26 16:04:19.537149+00
77dd9123-fb29-4b88-a68b-25f52ba84715	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
74289904-69fa-4338-a5af-e17fda47340b	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
d5e43e33-4ee5-4bc4-8196-f777150b9f3a	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4e9d42a0-8a5a-46db-b926-2d1fce2331e8	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
20bb4613-f871-434e-8796-9630f6f1c72b	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
a0e13e0b-8b90-49d5-9cfc-6578b0abd4ac	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
2ff32f19-cf7b-4bde-b837-a0888327ae66	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
1243b47b-4281-40bb-8cd5-851152817729	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
daeaa033-297e-473c-b5bc-d722d7b96ddc	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
3478fc17-49c0-4ed4-9a61-fa00952f2e94	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	14:00:00	15:00:00	t	2025-06-26 16:04:19.537149+00
4467e93f-dd7c-41f2-bc9a-516e4ac989c4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
185c82a2-de0a-4ee0-a040-e68cd923788a	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
bc5f87b0-4bc7-4e02-bf45-ec18138c1eac	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
835f7754-b119-408d-b0e9-c7ecbf3fdf33	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
c9d310ff-b08e-4124-ba35-3c57a6c433d8	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
58448559-1caf-4384-b714-e714c13b4ad0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
24588c80-73cd-4ef0-8fb9-6194cd538d3c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
8de67287-3498-4965-ae64-e70f4692000d	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
3d9f8d1a-4369-4fe2-9f3c-953550ff8861	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
d4fa6263-ae7c-41c4-8163-595d2df0c575	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	15:00:00	16:00:00	t	2025-06-26 16:04:19.537149+00
5e56929e-314d-44c0-ac86-e538f55673d0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ce1b473f-f40f-4556-bb5b-e9258f657cb5	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
bba73860-004b-4313-87de-94060a8b5847	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
1c199ee0-e30a-40cf-baf1-3c821579986e	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
6ad09950-340d-4cfe-9d53-9235def97095	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
ccd5fedb-d259-49f9-b417-b26efd5c5dc5	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
4de785b9-057a-4eeb-926e-36856f369c4c	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
acb3ee3a-c85c-415e-a336-285697a348b4	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
b7120fae-5645-4de5-adf5-382fc3e3aaf6	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
cd03d204-bc77-4699-85a0-4ef2e24ed396	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	16:00:00	17:00:00	t	2025-06-26 16:04:19.537149+00
7e86d472-ec17-4b86-93a7-26fd490ca495	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
338f5a2e-8cf0-4bee-8603-9d1767a90733	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
a1a7cc83-3fbd-41e3-9b86-e4faf2691ad4	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d269ac71-eeac-4ae0-b050-80d0f1da8147	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ab9bc72d-8869-4d46-9c7c-1e4bc0711f19	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
ff628b29-6024-4acc-9377-e59e4474f2c0	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
e61c379e-bb33-4a87-8e30-9c1cb89f0848	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
82f96d73-0527-4f75-955b-73481151533a	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
25884c3a-98ae-4f72-b4e7-205259fb0027	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
871db80b-17e7-466a-9263-24c16d40c554	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	17:00:00	18:00:00	t	2025-06-26 16:04:19.537149+00
d69f1851-ac99-4ec7-8a06-53606794e6fd	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
95e45230-a308-4767-9628-2cea7bcf017c	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
a9a8d169-656a-4671-ae49-d39e27aed705	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
125f3f54-75e3-48d4-b7ca-0ccf6d207438	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
8820348b-24c3-4543-b48e-6be316681b54	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e8d2170f-643b-413e-adf3-935340ca6668	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
0d8c6a68-d053-41b3-a245-dde422eaf48e	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
e7ae8860-05c5-4719-af5b-ea7419d04a98	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
29476e40-aee6-4932-bb5a-214c51504aaf	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
7289cc84-f909-4a75-9b6e-153ebf87627a	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	18:00:00	19:00:00	t	2025-06-26 16:04:19.537149+00
2c22de79-5e85-4b5d-bc7c-d1c22b635eb7	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
74644d15-5039-4a90-81b0-a492b7c79d09	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
0531bd18-4540-4e12-8461-4e0ff18fc857	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
317af29a-c8b0-44e3-a54b-e9b0d8b4dd73	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
ff389da3-4b5d-4cc4-bf64-6850685af728	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
3f76d57b-8e1d-4361-8605-5351cb4cd971	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
586e990c-cbaf-4038-8730-587d9196d7f6	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
b2902401-05e6-4640-98d5-2eaf9ed623b1	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
4a60f566-8d5c-429d-9353-68c0b5f1cc4c	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	19:00:00	20:00:00	t	2025-06-26 16:04:19.537149+00
9c7df04c-1fec-427b-9d9b-4065b26363de	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
52fb8a57-864f-4f75-9fc3-0bf7e885ad3d	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
a3ea6134-b387-45f3-8f32-5891b7ab206a	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
b84118b4-0442-4d30-8b6e-d8c270508cfd	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
5c8bdbbf-479e-4168-9f47-095389f0ef1d	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
14fba48e-ed3d-4e28-bcda-08a034ff45dc	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
db12e6e5-9dc8-4d42-a980-8d74207936e1	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
5393dcc1-c84b-4aa7-addb-d28886e3ca35	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
4f519b81-6f98-418b-a6d0-2ac72a447f19	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	20:00:00	21:00:00	t	2025-06-26 16:04:19.537149+00
906b9461-61ad-4b3d-b3f3-6c5b43fed1ac	9ce8da43-86ee-4276-b3f3-6189b91452b5	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
204a7c31-6a35-4f43-895e-3b2adfa10b95	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
0de60337-db19-4d05-8362-b106e51c1941	02b71f3b-f509-45df-9766-27674e3d1848	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c82b312e-bffe-4901-bb9a-fc2b35cbbf85	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
d20d75f1-8742-4623-990b-9246b44f0ef3	53f561ef-40d5-4c5c-918f-eddb188869f6	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
957bfe35-8cfe-4f45-a128-68f3535ce7e5	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
67bd3f68-6983-4809-b554-28090588c123	1bc0139e-a4d7-49de-95e8-4fad10a7e871	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
6da56ecb-cceb-4495-91c7-cdb09f6d5180	07771505-6c48-4181-a94a-80816e093af6	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
c92d8fae-9c47-4cf5-b71b-a18c6146e2dc	1fa337df-f5d4-4886-a59a-8ac043048ef1	2025-07-26	21:00:00	22:00:00	t	2025-06-26 16:04:19.537149+00
b3a4d5b6-579b-4318-bd71-105135b810ea	0cc8c1bf-72fc-4a49-9e6a-42d17798c243	2025-07-01	15:00:00	16:00:00	f	2025-06-26 16:04:19.537149+00
ac503582-621c-42c6-90de-5f4d68d392ae	4a7b67e3-714c-4077-a691-ca8df3866262	2025-06-28	20:00:00	21:00:00	f	2025-06-26 16:04:19.537149+00
6232f68d-9b8b-4fc0-94bc-9fc961e84216	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-06-29	19:00:00	20:00:00	f	2025-06-26 16:04:19.537149+00
000fe202-6dbd-4bd6-9934-18e7067002ef	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-01	09:00:00	10:00:00	t	2025-06-26 16:04:19.537149+00
72d6f4d2-86ed-4ef5-a856-abf3741881ac	704cb674-174e-40d4-b5df-d1cc1d17637c	2025-06-30	12:00:00	13:00:00	t	2025-06-28 13:33:27.953582+00
ee47c1b6-1640-4065-954e-2352466b73af	704cb674-174e-40d4-b5df-d1cc1d17637c	2025-06-30	13:30:00	14:30:00	t	2025-06-28 13:39:45.209448+00
01c46398-5792-4cf1-b08f-fb76a648d543	bcdf768c-979e-4c97-b5ba-9d4eacbac182	2025-10-02	20:00:00	21:00:00	t	2025-06-28 13:47:54.27958+00
3b430ee2-6640-44ef-a0e1-a989377799cd	4a7b67e3-714c-4077-a691-ca8df3866262	2025-10-02	08:00:00	09:00:00	f	2025-06-29 12:29:28.041705+00
041e0870-dbe4-4480-8da8-837d08a162e4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	20:00:00	21:00:00	f	2025-06-26 16:04:19.537149+00
70a8320f-797c-489c-a79b-14e527f34090	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-07	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
6f9ebf89-6371-46f2-a72b-ac68821f0440	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-08	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
5d3d5cdf-0d4e-4aa8-992e-73cb58d211e4	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-12	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
ab3d7d86-b793-46a8-9959-4e8401469399	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	21:00:00	22:00:00	f	2025-06-26 16:04:19.537149+00
3b4a3c16-3e67-4e3e-a684-2ab9deff4c55	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	20:00:00	21:00:00	f	2025-06-26 16:04:19.537149+00
c5a83aaa-0ab6-4b50-ac4d-75965dd23b42	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-26	19:00:00	20:00:00	f	2025-06-26 16:04:19.537149+00
55545731-f14e-4b03-9b7b-a4ff48f215ea	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-06	14:00:00	15:00:00	f	2025-06-26 16:04:19.537149+00
39726bf3-ebe5-4615-b4cb-246fe6c28ec1	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
235f51e4-2099-4fd1-95f7-b0171ce3b292	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	10:00:00	11:00:00	f	2025-06-26 16:04:19.537149+00
109b7f45-af8d-4f69-9006-b9cfffae1428	5a80fd92-a468-49a4-b0cf-9c20b149c341	2025-07-25	08:00:00	09:00:00	f	2025-06-26 16:04:19.537149+00
28995222-47e5-4af0-9233-24e70b03b6d0	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-04	19:00:00	20:00:00	f	2025-06-26 16:04:19.537149+00
62756d4a-d6d4-47f0-aa57-02743a452ede	4a7b67e3-714c-4077-a691-ca8df3866262	2025-07-05	12:00:00	13:00:00	f	2025-06-26 16:04:19.537149+00
\.


--
-- Data for Name: courts; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.courts (id, facility_id, name, court_type, surface_type, is_indoor, has_lighting, hourly_rate, currency, is_active, created_at, updated_at) FROM stdin;
4a7b67e3-714c-4077-a691-ca8df3866262	181e34eb-50b3-45d7-9a9c-9b52fd024a70	Campo A	football_5	artificial_grass	t	t	35.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
9ce8da43-86ee-4276-b3f3-6189b91452b5	181e34eb-50b3-45d7-9a9c-9b52fd024a70	Campo B	football_5	artificial_grass	t	t	35.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
0cc8c1bf-72fc-4a49-9e6a-42d17798c243	181e34eb-50b3-45d7-9a9c-9b52fd024a70	Campo C	football_7	artificial_grass	f	t	45.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
02b71f3b-f509-45df-9766-27674e3d1848	181e34eb-50b3-45d7-9a9c-9b52fd024a70	Campo D	football_7	artificial_grass	f	t	45.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
bcdf768c-979e-4c97-b5ba-9d4eacbac182	accee755-3e2a-46c7-9a44-f40e8444bd62	Campo Centrale	football_5	artificial_grass	t	t	40.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
53f561ef-40d5-4c5c-918f-eddb188869f6	accee755-3e2a-46c7-9a44-f40e8444bd62	Campo Est	football_5	artificial_grass	t	t	40.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
5a80fd92-a468-49a4-b0cf-9c20b149c341	accee755-3e2a-46c7-9a44-f40e8444bd62	Campo Ovest	football_7	artificial_grass	t	t	50.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
1bc0139e-a4d7-49de-95e8-4fad10a7e871	8ac6c5a3-dd22-4f4f-8dde-03b6dd788eaa	Campo 1	football_5	artificial_grass	f	t	30.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
07771505-6c48-4181-a94a-80816e093af6	8ac6c5a3-dd22-4f4f-8dde-03b6dd788eaa	Campo 2	football_5	artificial_grass	f	t	30.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
1fa337df-f5d4-4886-a59a-8ac043048ef1	8ac6c5a3-dd22-4f4f-8dde-03b6dd788eaa	Campo Grande	football_7	natural_grass	f	t	40.00	EUR	t	2025-06-26 16:04:19.530715+00	2025-06-26 16:04:19.530715+00
704cb674-174e-40d4-b5df-d1cc1d17637c	8ac6c5a3-dd22-4f4f-8dde-03b6dd788eaa	Campo 3	football_5	artificial_grass	\N	\N	45.00	\N	t	2025-06-28 13:26:01.333988+00	2025-06-28 13:26:01.334007+00
\.


--
-- Data for Name: facilities; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.facilities (id, name, description, address, city, postal_code, country, latitude, longitude, phone, email, website, opening_hours, amenities, is_active, created_at, updated_at) FROM stdin;
181e34eb-50b3-45d7-9a9c-9b52fd024a70	Centro Sportivo Milano Nord	Moderno centro sportivo con 6 campi da calcetto	Via dello Sport 15	Milano	20100	Italy	45.47730000	9.18150000	+39 02 1234567	info@milanonord.it	\N	{"friday": {"open": "08:00", "close": "23:00"}, "monday": {"open": "08:00", "close": "23:00"}, "sunday": {"open": "09:00", "close": "22:00"}, "tuesday": {"open": "08:00", "close": "23:00"}, "saturday": {"open": "09:00", "close": "22:00"}, "thursday": {"open": "08:00", "close": "23:00"}, "wednesday": {"open": "08:00", "close": "23:00"}}	{parking,changing_rooms,bar,equipment_rental,showers,wifi}	t	2025-06-26 16:04:19.52944+00	2025-06-26 16:04:19.52944+00
accee755-3e2a-46c7-9a44-f40e8444bd62	Sporting Club Brera	Centro sportivo nel cuore di Milano	Corso Brera 42	Milano	20121	Italy	45.47220000	9.18890000	+39 02 7654321	booking@sportingbrera.it	\N	{"friday": {"open": "07:00", "close": "24:00"}, "monday": {"open": "07:00", "close": "24:00"}, "sunday": {"open": "08:00", "close": "23:00"}, "tuesday": {"open": "07:00", "close": "24:00"}, "saturday": {"open": "08:00", "close": "24:00"}, "thursday": {"open": "07:00", "close": "24:00"}, "wednesday": {"open": "07:00", "close": "24:00"}}	{parking,changing_rooms,bar,equipment_rental,showers,sauna,fitness_center}	t	2025-06-26 16:04:19.530012+00	2025-06-26 16:04:19.530012+00
8ac6c5a3-dd22-4f4f-8dde-03b6dd788eaa	Football Park Navigli	Campi all'aperto vicino ai Navigli	Via Naviglio Grande 88	Milano	20144	Italy	45.45150000	9.17030000	+39 02 9876543	info@footballnavigili.it	\N	{"friday": {"open": "09:00", "close": "23:00"}, "monday": {"open": "09:00", "close": "22:00"}, "sunday": {"open": "08:00", "close": "22:00"}, "tuesday": {"open": "09:00", "close": "22:00"}, "saturday": {"open": "08:00", "close": "23:00"}, "thursday": {"open": "09:00", "close": "22:00"}, "wednesday": {"open": "09:00", "close": "22:00"}}	{parking,changing_rooms,bar,equipment_rental}	t	2025-06-26 16:04:19.530309+00	2025-06-26 16:04:19.530309+00
d29cf027-5bc8-44d4-8472-c40f5c68149a	PlayFutMilano1	\N	Via dalla strada	Milano	12069	Italy	\N	\N	\N	\N	\N	\N	\N	t	2025-06-28 13:16:59.236864+00	2025-06-28 13:16:59.236899+00
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.payments (id, user_id, booking_id, tournament_id, amount, currency, payment_method, payment_provider, provider_payment_id, status, payment_date, failure_reason, metadata, created_at, updated_at, paypal_capture_id, paypal_order_id) FROM stdin;
03c5bd29-c2e4-4c98-b219-c22dd1cfdd32	c53a09b8-7418-4c76-8aa9-a2466b2da02d	cd13cee9-c084-435a-98a7-a9ee6ec0d250	\N	400.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-04 13:50:41.22263+00	2025-07-04 13:51:46.453375+00	3GP31718F5216362A	57385283WS882954D
2aacc286-ee1a-483b-92af-bcf4acb8272e	60d0c593-d79a-4039-a69d-bed35c055e0f	9a85a14b-d31e-4468-a1c5-579a628cb64b	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-04 15:30:54.972376+00	2025-07-04 15:32:20.880231+00	5Y9988104A716950E	2AU88437B6171170B
15d99cb2-ca9d-4066-943b-87ff16eb860c	60d0c593-d79a-4039-a69d-bed35c055e0f	22c24de8-394b-45a1-a25e-ac340a589536	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-04 15:37:11.44649+00	2025-07-04 15:37:55.372103+00	9RJ383800V952581R	76L30215TG337445E
34a3a725-f4c2-46f7-9e47-c4ef30c99c6c	60d0c593-d79a-4039-a69d-bed35c055e0f	a9477aec-86e4-4bb1-9bc3-6189b969f60e	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-04 15:39:34.479037+00	2025-07-04 15:40:25.768279+00	9YC64076W3713163V	0XH87923LX551594M
5bd5b564-c118-467d-9344-3af054a47f74	60d0c593-d79a-4039-a69d-bed35c055e0f	0b6451f2-0f17-46e0-be9e-044e51af28f0	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 15:43:35.225991+00	2025-07-04 15:43:47.491618+00	\N	9246250164451151P
a0b482b5-5bfb-4014-8eaf-3544e8ccaeeb	60d0c593-d79a-4039-a69d-bed35c055e0f	70a9f953-5a6f-42f8-9b8f-2bc0620f058e	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 15:44:43.667042+00	2025-07-04 15:44:48.032443+00	\N	39271085XC6652257
c7175e15-af7c-4fb3-9768-415acc3beac8	60d0c593-d79a-4039-a69d-bed35c055e0f	d19b6482-6e54-4209-8a99-64b44e903dc5	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 15:55:07.159888+00	2025-07-04 15:55:12.777176+00	\N	5VM32897EJ7122938
514418b0-2cdd-40ed-9250-d93cf60b9727	60d0c593-d79a-4039-a69d-bed35c055e0f	4773ca39-7521-44a0-9fe1-2fd563d49b98	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 15:55:30.029569+00	2025-07-04 15:55:37.073985+00	\N	0W89541399702364J
2ab18a28-28ef-420e-8d64-75f62edbb603	60d0c593-d79a-4039-a69d-bed35c055e0f	d37c0273-6179-4cb5-bb58-84cf287a5bbd	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 19:50:13.396306+00	2025-07-04 19:50:17.076611+00	\N	0J051871SR8879148
bd0a0105-2f8e-4d04-87fb-04de8ec78516	60d0c593-d79a-4039-a69d-bed35c055e0f	2771db94-668a-4985-87de-b86d89def82d	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 19:52:07.208337+00	2025-07-04 19:52:10.47537+00	\N	7N7259577V957543D
ce96ddca-3c28-45c4-b357-707c1101523b	60d0c593-d79a-4039-a69d-bed35c055e0f	4ea5f54b-2f23-4372-a748-9f0fbff303f6	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-04 19:52:26.298214+00	2025-07-04 19:55:04.473348+00	1LT44717E64275234	3HL8524822940061F
7f71ed5e-b157-400b-ac11-3923ff659b35	60d0c593-d79a-4039-a69d-bed35c055e0f	ccc348c2-16a5-45af-a393-f334b514add5	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 19:57:33.270969+00	2025-07-04 19:57:37.011093+00	\N	0NK62683HG7787403
6d1d2d02-fea4-411b-9525-b5024f10d0f2	60d0c593-d79a-4039-a69d-bed35c055e0f	eda75ea0-a42a-4373-aecd-0e80e62842ec	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 19:58:52.216468+00	2025-07-04 19:58:55.563052+00	\N	5W426924WB739844N
f086ed6d-70d9-46e5-8af9-5d8ba269ad1b	60d0c593-d79a-4039-a69d-bed35c055e0f	4e1d7839-c26a-4dca-99f8-4d92768d08a8	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-04 19:59:55.503261+00	2025-07-04 20:01:02.19395+00	3JJ36142BY665844G	7HE9903410147343B
2a3f67fd-6773-4df7-9e92-3cc307e4bf2a	60d0c593-d79a-4039-a69d-bed35c055e0f	fecb785e-99ae-4f13-8ef7-6d160e75e273	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-04 20:02:39.86388+00	2025-07-04 20:04:17.402278+00	7BX55840000889735	76W176434E834760F
e34dafb8-e9b9-4fb4-9ded-85d160992da3	60d0c593-d79a-4039-a69d-bed35c055e0f	72bfdd0b-183a-4b03-8e86-697a8ea43812	\N	300.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 20:13:09.31441+00	2025-07-04 20:13:13.380133+00	\N	4CM93429EG469115H
bdc73613-a9c5-496e-9e48-652174f5ea5b	60d0c593-d79a-4039-a69d-bed35c055e0f	9a3b03b5-a0ec-45d7-9876-e63e2ea27e3e	\N	300.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-04 20:15:03.034295+00	2025-07-04 20:15:07.054549+00	\N	18989189CE101781M
e9313d18-399b-47ea-8e22-3140563f7be5	60d0c593-d79a-4039-a69d-bed35c055e0f	e1c5b332-5b72-4637-86c3-41c04359ad83	\N	300.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-04 20:17:32.37588+00	2025-07-04 20:18:28.685024+00	0W164064KY668174J	9XL73130XA5116742
27764251-581e-4ceb-97ea-8782532422e8	60d0c593-d79a-4039-a69d-bed35c055e0f	88598c35-18d0-4c6f-aa9b-514bb897572c	\N	350.00	EUR	PAYPAL	PAYPAL	\N	failed	\N	Payment timeout - not completed within 30 minutes	\N	2025-07-04 20:07:51.361161+00	2025-07-05 08:29:47.414709+00	\N	30N68235HT269454G
db2f512b-3e89-44ed-a985-7ca842eb77c1	60d0c593-d79a-4039-a69d-bed35c055e0f	1986eeae-a649-4ea9-8da3-6d4c8600df9f	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-05 08:54:55.256548+00	2025-07-05 08:56:14.528963+00	13V22076SY782405R	73G259451R025051Y
da88a8cd-4fbe-4c7d-8d3e-1badf45f69f4	60d0c593-d79a-4039-a69d-bed35c055e0f	ba2a0ed5-eb87-441d-a03c-1285724082f1	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-05 09:04:24.589405+00	2025-07-05 09:05:23.392884+00	3D632637LN0067136	4L753184KW570690S
159d11d7-acf7-4bfb-a144-fb294d46bfed	60d0c593-d79a-4039-a69d-bed35c055e0f	b4ca9d4f-1c1c-41cb-82f6-94777b252ab2	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-05 09:14:35.630476+00	2025-07-05 09:15:34.13241+00	76A95417BC152310F	1RH24047NA499443S
8141cbd3-e55b-4ef9-8016-c222d6cff3c7	60d0c593-d79a-4039-a69d-bed35c055e0f	58d210d9-9946-458c-82d4-c29527db5102	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-05 09:19:25.349205+00	2025-07-05 09:20:17.732589+00	4RG301834H2795129	3MB682521A966145G
841b73fb-8746-4a2b-955c-7085d520c5f8	60d0c593-d79a-4039-a69d-bed35c055e0f	356383b0-ba03-4f4f-b24f-68ea53a8b91b	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-05 09:22:19.131793+00	2025-07-05 09:22:23.094967+00	\N	05X744463C646661C
9bf15b93-40c5-4a4a-84a9-65043db49288	60d0c593-d79a-4039-a69d-bed35c055e0f	4c4b0dce-b128-4aef-a127-f944f48c8939	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-05 09:23:40.626408+00	2025-07-05 09:25:48.868081+00	\N	80A51463KU994282U
c7e18d1e-ff5a-4ecf-ad1b-64e16c371cf2	60d0c593-d79a-4039-a69d-bed35c055e0f	b65535cf-e14b-47b6-8785-0e3cf6e0013c	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-05 09:30:35.193098+00	2025-07-05 09:30:41.504392+00	\N	2D631246L1345683X
565f077d-927a-4b81-a7a9-5b39ad821097	60d0c593-d79a-4039-a69d-bed35c055e0f	dba23b11-1060-4c81-8c38-f8a4b968329e	\N	350.00	EUR	PAYPAL	PAYPAL	\N	failed	\N	Payment timeout - not completed within 30 minutes	\N	2025-07-05 09:02:59.303498+00	2025-07-05 09:33:30.577296+00	\N	1F559740TW834902K
f49baa5a-03f3-4b6c-8b11-077f4ba67b41	60d0c593-d79a-4039-a69d-bed35c055e0f	19dd0bc3-84a9-425f-ae85-27bbacde7e7f	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-05 09:38:50.956188+00	2025-07-05 09:38:58.55739+00	\N	9GF4121060522324T
4c6f464e-7193-469e-8bde-220cf5551b2c	60d0c593-d79a-4039-a69d-bed35c055e0f	815b483a-18c3-4185-bf6a-f0db5a4dca60	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-05 09:40:07.96373+00	2025-07-05 09:40:13.520117+00	\N	1W711957SW605603B
8a834e79-12de-4495-9df6-528b95f50535	60d0c593-d79a-4039-a69d-bed35c055e0f	ed3165d6-9484-433b-80da-50c2a84fae8c	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-05 09:40:35.357555+00	2025-07-05 09:41:23.889891+00	00U350864E516074A	33N83728R3255271S
f126e7f2-f1f6-496e-b8ba-89ebb8ef899f	60d0c593-d79a-4039-a69d-bed35c055e0f	ef719d20-d2e0-437b-bedf-0397978c59b5	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-06 09:58:33.624018+00	2025-07-06 09:58:39.844062+00	\N	3T490577D7419020A
9a261265-af65-47ed-b75a-31c0cfec2c7b	60d0c593-d79a-4039-a69d-bed35c055e0f	03603cf6-ecda-4356-8940-76840ac668de	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-06 09:58:52.970667+00	2025-07-06 09:59:57.374841+00	2F6678922B749981R	13M29445B0669820J
058fedaf-2a1d-4a94-90cf-844f4d555dea	60d0c593-d79a-4039-a69d-bed35c055e0f	b341b1cb-5f9a-476f-9ac5-d69eaaf8608c	\N	350.00	EUR	PAYPAL	PAYPAL	\N	cancelled	\N	User cancelled payment on PayPal	\N	2025-07-06 10:10:26.233781+00	2025-07-06 10:10:29.793515+00	\N	2XX532281Y770414T
62feda0f-de62-4de1-bbcd-0eca3dfd03f2	60d0c593-d79a-4039-a69d-bed35c055e0f	0026c3d5-e018-4a66-a7d2-1fd56a5384d3	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-06 10:10:49.764605+00	2025-07-06 10:11:41.769675+00	67G23919GJ405462G	4D686699C68978746
cf09d726-7112-4c7a-bc80-e41b0874f926	60d0c593-d79a-4039-a69d-bed35c055e0f	f5631bfa-2b42-4acb-b127-4d7752350734	\N	350.00	EUR	PAYPAL	PAYPAL	\N	completed	\N	\N	\N	2025-07-06 10:14:05.559078+00	2025-07-06 10:14:58.746748+00	97614327V25702421	31J82909NR389623W
\.


--
-- Data for Name: tournament_team_players; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.tournament_team_players (id, team_id, player_id, is_captain, joined_at) FROM stdin;
9cbceafb-70ad-45a2-a803-3c64b6ea6ba5	59e55e95-c3cc-47c6-8fe9-f7bbf4e14e96	6a0bb94a-b5c8-4476-bec7-4147b7c76a2a	t	2025-06-26 16:04:19.590427+00
7e2c09b8-9ea7-4fe3-b3d3-6b8107aa6ad1	59e55e95-c3cc-47c6-8fe9-f7bbf4e14e96	ce03abd5-aeb2-4b56-b53d-47c582c3f0d9	f	2025-06-26 16:04:19.590427+00
301fe7b8-5f0a-4382-86fd-c21553f43ddd	59e55e95-c3cc-47c6-8fe9-f7bbf4e14e96	e19ea95d-e249-40a9-a3e5-9f76038aba4e	f	2025-06-26 16:04:19.590427+00
7f2a86f5-d97b-4e73-b74b-2a8ed1eff7d1	2b78dc83-18bc-4305-88d3-d1310c779958	3cc44dfa-accc-4234-a041-541802b62cae	t	2025-06-26 16:04:19.590427+00
f73253f0-4eee-4709-9150-f8a242eb5c02	2b78dc83-18bc-4305-88d3-d1310c779958	b6716094-59bd-4f9b-b71e-2f23e7ec79cc	f	2025-06-26 16:04:19.590427+00
592db6c6-b38d-45ca-b328-3c9a4ab32136	2b78dc83-18bc-4305-88d3-d1310c779958	91db9a44-e047-4af4-a0e1-b3618a5c9a7e	f	2025-06-26 16:04:19.590427+00
61008887-0d81-498a-aab2-c0ba93dd04dd	2c2e0e62-4347-4284-81f0-78761545bf16	e19ea95d-e249-40a9-a3e5-9f76038aba4e	t	2025-06-26 16:04:19.590427+00
3a39ebae-5559-474d-856d-53da309abc9f	2c2e0e62-4347-4284-81f0-78761545bf16	ce03abd5-aeb2-4b56-b53d-47c582c3f0d9	f	2025-06-26 16:04:19.590427+00
ea2db3ce-c7b9-4333-a067-2e61f548094e	86c74c31-6b7e-47fe-996b-c2a72abf74af	3864dda6-7a52-4d2e-a697-3b21f3f53763	t	2025-06-26 16:04:19.590427+00
02abc7d8-42e7-4d2c-a7ed-90fb7dc06c5a	86c74c31-6b7e-47fe-996b-c2a72abf74af	627400f7-6840-4363-a090-1e23b7b271a2	f	2025-06-26 16:04:19.590427+00
\.


--
-- Data for Name: tournament_teams; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.tournament_teams (id, tournament_id, team_name, captain_id, status, registration_date) FROM stdin;
59e55e95-c3cc-47c6-8fe9-f7bbf4e14e96	dad98a8d-c5f5-48f7-82ea-a83b4394ffa3	Gli Invincibili	6a0bb94a-b5c8-4476-bec7-4147b7c76a2a	confirmed	2025-06-26 16:04:19.590427+00
2b78dc83-18bc-4305-88d3-d1310c779958	dad98a8d-c5f5-48f7-82ea-a83b4394ffa3	FC Naviglio	3cc44dfa-accc-4234-a041-541802b62cae	confirmed	2025-06-26 16:04:19.590427+00
2c2e0e62-4347-4284-81f0-78761545bf16	dbbdaf05-a828-427e-9f80-70273707644a	Milano Centrale	e19ea95d-e249-40a9-a3e5-9f76038aba4e	confirmed	2025-06-26 16:04:19.590427+00
86c74c31-6b7e-47fe-996b-c2a72abf74af	dbbdaf05-a828-427e-9f80-70273707644a	I Leoni	3864dda6-7a52-4d2e-a697-3b21f3f53763	confirmed	2025-06-26 16:04:19.590427+00
\.


--
-- Data for Name: tournaments; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.tournaments (id, name, description, facility_id, organizer_id, tournament_type, sport_type, max_teams, current_teams, entry_fee, prize_pool, currency, start_date, end_date, registration_deadline, skill_level_min, skill_level_max, age_restriction, gender_restriction, status, rules, prizes, created_at, updated_at) FROM stdin;
dad98a8d-c5f5-48f7-82ea-a83b4394ffa3	Torneo Estivo Milano 2025	Il grande torneo estivo di calcio a 5	181e34eb-50b3-45d7-9a9c-9b52fd024a70	6a0bb94a-b5c8-4476-bec7-4147b7c76a2a	knockout	football_5	16	2	100.00	0.00	EUR	2025-07-26	2025-08-25	2025-07-16	\N	\N	\N	\N	open	\N	\N	2025-06-26 16:04:19.590427+00	2025-06-26 16:04:19.597515+00
dbbdaf05-a828-427e-9f80-70273707644a	Brera Champions Cup	Torneo amichevole di calcio a 7	accee755-3e2a-46c7-9a44-f40e8444bd62	e19ea95d-e249-40a9-a3e5-9f76038aba4e	round_robin	football_7	8	2	80.00	0.00	EUR	2025-08-05	2025-08-15	2025-07-26	\N	\N	\N	\N	open	\N	\N	2025-06-26 16:04:19.590427+00	2025-06-26 16:04:19.597515+00
\.


--
-- Data for Name: user_tokens; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.user_tokens (id, user_id, token_type, token_hash, expires_at, created_at) FROM stdin;
e9528920-a64e-4bc1-8bf3-7f2b642899fb	6a0bb94a-b5c8-4476-bec7-4147b7c76a2a	refresh_token	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.sample.token	2025-07-26 16:04:19.598523+00	2025-06-26 16:04:19.598523+00
97827758-15ae-4717-a734-9a77b0f91006	3cc44dfa-accc-4234-a041-541802b62cae	refresh_token	eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.another.token	2025-07-26 16:04:19.598523+00	2025-06-26 16:04:19.598523+00
\.


--
-- Data for Name: user_wallets; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.user_wallets (id, user_id, balance, currency, created_at, updated_at) FROM stdin;
271b5340-bfd7-4df1-9ec9-340bbbbe4080	b6716094-59bd-4f9b-b71e-2f23e7ec79cc	50.00	EUR	2025-06-26 16:04:19.528191+00	2025-06-26 16:04:19.528191+00
7ab570e5-72de-41bc-a918-305bd06061fa	627400f7-6840-4363-a090-1e23b7b271a2	50.00	EUR	2025-06-26 16:04:19.528191+00	2025-06-26 16:04:19.528191+00
20ef5060-d08f-414d-baae-e6f23dddf705	ce03abd5-aeb2-4b56-b53d-47c582c3f0d9	50.00	EUR	2025-06-26 16:04:19.528191+00	2025-06-26 16:04:19.528191+00
59a36a99-9cd6-4eeb-a7d4-31c59120f3c7	91db9a44-e047-4af4-a0e1-b3618a5c9a7e	50.00	EUR	2025-06-26 16:04:19.528191+00	2025-06-26 16:04:19.528191+00
7cdf4510-e0d1-45f2-8a85-d1a103433fe6	6a0bb94a-b5c8-4476-bec7-4147b7c76a2a	115.00	EUR	2025-06-26 16:04:19.528191+00	2025-06-26 16:04:19.600228+00
ffb28f2e-d545-4c44-8599-64259dddafd0	3cc44dfa-accc-4234-a041-541802b62cae	90.00	EUR	2025-06-26 16:04:19.528191+00	2025-06-26 16:04:19.600228+00
0f17b4b9-a85e-4ace-a3bc-ef99e74c6c9f	e19ea95d-e249-40a9-a3e5-9f76038aba4e	100.00	EUR	2025-06-26 16:04:19.528191+00	2025-06-26 16:04:19.600228+00
6792dc25-9794-48e6-a620-458310c51bea	3864dda6-7a52-4d2e-a697-3b21f3f53763	95.00	EUR	2025-06-26 16:04:19.528191+00	2025-06-26 16:04:19.600228+00
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.users (id, is_active, avatar_url, bio, created_at, date_of_birth, email, email_verified, first_name, gender, last_name, password_hash, phone, preferred_position, skill_level, updated_at) FROM stdin;
60d0c593-d79a-4039-a69d-bed35c055e0f	t	\N	\N	2025-06-27 15:40:29.393436+00	\N	matteomirty20@gmail.com	f	Matteo	male	Olivero	$2a$10$nKflZeXSOTlFdlu55ura..J/5ew9gWw26Rh70sd/1s9xbmNoQJ6TW	\N	\N	\N	2025-06-27 15:40:29.393461+00
c53a09b8-7418-4c76-8aa9-a2466b2da02d	t	\N	\N	2025-07-03 14:09:46.936814+00	\N	malpe@gmail.com	f	Jacopo	male	Malpe	$2a$10$cA..ZOc9S1F3b9A3CSVj9ujOuo/XDtQe4inTpZdyNe.bMPuKY.Gma	\N	\N	\N	2025-07-03 14:09:46.936837+00
b876d41f-203b-48bb-8bfb-a2e47b380e28	t	\N	\N	2025-07-03 14:10:07.657577+00	\N	jaki@gmail.com	f	Jaki	male	Malpesi	$2a$10$CdI15TIfQPLFc9xoFaaO4uEjXWMrUqjD6aNUyT1wxo/ewOUoB90fC	\N	\N	\N	2025-07-03 14:10:07.657595+00
b211255d-6dfc-4c91-bfd7-3927e15a1835	t	\N		2025-07-05 14:18:24.171842+00	\N	fanaramariarosa@gmail.com	f	Maria Rosa	other	Fa	$2a$10$GaMgnbxY9oKf40QMe8gq8.J75Mf4t7BKMxMkQHkb36Nh8S4YLSD9y	3383796625		\N	2025-07-05 14:18:24.171864+00
cbbcb4d0-050e-452a-8df7-5cc5ab8d1ef9	t	https://lh3.googleusercontent.com/a/ACg8ocLnlq2RcvpcvhuaqfJfIbNn2528BMKMi233BI8LTz1vCpSp7Q=s96-c	\N	2025-07-06 08:54:53.92419+00	\N	malpesi.jacopo@gmail.com	t	Jacopo	other	Malpesi		\N	\N	\N	2025-07-06 08:54:53.924285+00
b9fa5a8c-ca17-4239-b0c2-4864df3445a7	t	https://lh3.googleusercontent.com/a/ACg8ocKlP95TzWYtSyZT9bIG2JdWFSHsazTNcmX5RfL41YNSxmns4Q=s96-c	\N	2025-07-06 08:56:58.631608+00	\N	malpesi.maurizio@gmail.com	t	Maurizio	other	Malpesi		\N	\N	\N	2025-07-06 08:56:58.631619+00
\.


--
-- Data for Name: wallet_transactions; Type: TABLE DATA; Schema: public; Owner: user
--

COPY public.wallet_transactions (id, wallet_id, transaction_type, amount, balance_after, reference_id, description, created_at) FROM stdin;
1d6b4aa9-2481-4544-9a54-b4ea998399ee	7cdf4510-e0d1-45f2-8a85-d1a103433fe6	deposit	100.00	150.00	\N	Ricarica iniziale	2025-06-26 16:04:19.600228+00
7fc0015c-ee15-4111-a280-824597364856	7cdf4510-e0d1-45f2-8a85-d1a103433fe6	withdrawal	35.00	115.00	\N	Pagamento prenotazione Campo A	2025-06-26 16:04:19.600228+00
5e17b18b-08a9-49d2-b4b3-17c8727b86b2	ffb28f2e-d545-4c44-8599-64259dddafd0	deposit	80.00	130.00	\N	Ricarica wallet	2025-06-26 16:04:19.600228+00
86103baf-451a-4c00-b7a9-08dffa02177f	ffb28f2e-d545-4c44-8599-64259dddafd0	withdrawal	40.00	90.00	\N	Pagamento prenotazione Campo Centrale	2025-06-26 16:04:19.600228+00
fe00e7fb-7a66-4197-b843-4cd838c59945	0f17b4b9-a85e-4ace-a3bc-ef99e74c6c9f	deposit	50.00	100.00	\N	Ricarica wallet	2025-06-26 16:04:19.600228+00
f751ddc8-0c91-42ce-859e-234c4bcfe4e8	6792dc25-9794-48e6-a620-458310c51bea	deposit	75.00	125.00	\N	Ricarica wallet	2025-06-26 16:04:19.600228+00
1ecc4488-c33b-4591-b611-3c36a82aa774	6792dc25-9794-48e6-a620-458310c51bea	withdrawal	30.00	95.00	\N	Pagamento prenotazione Campo 1	2025-06-26 16:04:19.600228+00
\.


--
-- Name: booking_participants booking_participants_booking_id_user_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.booking_participants
    ADD CONSTRAINT booking_participants_booking_id_user_id_key UNIQUE (booking_id, user_id);


--
-- Name: booking_participants booking_participants_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.booking_participants
    ADD CONSTRAINT booking_participants_pkey PRIMARY KEY (id);


--
-- Name: bookings bookings_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_pkey PRIMARY KEY (id);


--
-- Name: court_availability court_availability_court_id_date_start_time_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.court_availability
    ADD CONSTRAINT court_availability_court_id_date_start_time_key UNIQUE (court_id, date, start_time);


--
-- Name: court_availability court_availability_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.court_availability
    ADD CONSTRAINT court_availability_pkey PRIMARY KEY (id);


--
-- Name: courts courts_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.courts
    ADD CONSTRAINT courts_pkey PRIMARY KEY (id);


--
-- Name: facilities facilities_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.facilities
    ADD CONSTRAINT facilities_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: tournament_team_players tournament_team_players_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.tournament_team_players
    ADD CONSTRAINT tournament_team_players_pkey PRIMARY KEY (id);


--
-- Name: tournament_team_players tournament_team_players_team_id_player_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.tournament_team_players
    ADD CONSTRAINT tournament_team_players_team_id_player_id_key UNIQUE (team_id, player_id);


--
-- Name: tournament_teams tournament_teams_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.tournament_teams
    ADD CONSTRAINT tournament_teams_pkey PRIMARY KEY (id);


--
-- Name: tournament_teams tournament_teams_tournament_id_team_name_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.tournament_teams
    ADD CONSTRAINT tournament_teams_tournament_id_team_name_key UNIQUE (tournament_id, team_name);


--
-- Name: tournaments tournaments_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.tournaments
    ADD CONSTRAINT tournaments_pkey PRIMARY KEY (id);


--
-- Name: users uk6dotkott2kjsp8vw4d0m25fb7; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT uk6dotkott2kjsp8vw4d0m25fb7 UNIQUE (email);


--
-- Name: booking_participants ukllgh8wfd7cxam1iw4y0ww3acg; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.booking_participants
    ADD CONSTRAINT ukllgh8wfd7cxam1iw4y0ww3acg UNIQUE (booking_id, user_id);


--
-- Name: court_availability uklsu1e6sf1fbgyoal72rspsgdp; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.court_availability
    ADD CONSTRAINT uklsu1e6sf1fbgyoal72rspsgdp UNIQUE (court_id, date, start_time);


--
-- Name: user_tokens user_tokens_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.user_tokens
    ADD CONSTRAINT user_tokens_pkey PRIMARY KEY (id);


--
-- Name: user_wallets user_wallets_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.user_wallets
    ADD CONSTRAINT user_wallets_pkey PRIMARY KEY (id);


--
-- Name: user_wallets user_wallets_user_id_key; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.user_wallets
    ADD CONSTRAINT user_wallets_user_id_key UNIQUE (user_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: wallet_transactions wallet_transactions_pkey; Type: CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_pkey PRIMARY KEY (id);


--
-- Name: idx_booking_participants_booking_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_booking_participants_booking_id ON public.booking_participants USING btree (booking_id);


--
-- Name: idx_booking_participants_team; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_booking_participants_team ON public.booking_participants USING btree (booking_id, team);


--
-- Name: idx_booking_participants_user_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_booking_participants_user_id ON public.booking_participants USING btree (user_id);


--
-- Name: idx_bookings_court_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_bookings_court_id ON public.bookings USING btree (court_id);


--
-- Name: idx_bookings_date; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_bookings_date ON public.bookings USING btree (booking_date);


--
-- Name: idx_bookings_organizer_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_bookings_organizer_id ON public.bookings USING btree (organizer_id);


--
-- Name: idx_bookings_status; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_bookings_status ON public.bookings USING btree (status);


--
-- Name: idx_court_availability_court_date; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_court_availability_court_date ON public.court_availability USING btree (court_id, date);


--
-- Name: idx_court_availability_date; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_court_availability_date ON public.court_availability USING btree (date);


--
-- Name: idx_courts_facility_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_courts_facility_id ON public.courts USING btree (facility_id);


--
-- Name: idx_courts_type; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_courts_type ON public.courts USING btree (court_type);


--
-- Name: idx_facilities_active; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_facilities_active ON public.facilities USING btree (is_active);


--
-- Name: idx_facilities_city; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_facilities_city ON public.facilities USING btree (city);


--
-- Name: idx_payments_booking_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_payments_booking_id ON public.payments USING btree (booking_id);


--
-- Name: idx_payments_date; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_payments_date ON public.payments USING btree (payment_date);


--
-- Name: idx_payments_status; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_payments_status ON public.payments USING btree (status);


--
-- Name: idx_payments_user_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_payments_user_id ON public.payments USING btree (user_id);


--
-- Name: idx_tournament_teams_captain_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_tournament_teams_captain_id ON public.tournament_teams USING btree (captain_id);


--
-- Name: idx_tournament_teams_tournament_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_tournament_teams_tournament_id ON public.tournament_teams USING btree (tournament_id);


--
-- Name: idx_tournaments_dates; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_tournaments_dates ON public.tournaments USING btree (start_date, end_date);


--
-- Name: idx_tournaments_facility_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_tournaments_facility_id ON public.tournaments USING btree (facility_id);


--
-- Name: idx_tournaments_organizer_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_tournaments_organizer_id ON public.tournaments USING btree (organizer_id);


--
-- Name: idx_tournaments_status; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_tournaments_status ON public.tournaments USING btree (status);


--
-- Name: idx_user_tokens_expires; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_user_tokens_expires ON public.user_tokens USING btree (expires_at);


--
-- Name: idx_user_tokens_user_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_user_tokens_user_id ON public.user_tokens USING btree (user_id);


--
-- Name: idx_wallet_transactions_date; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_wallet_transactions_date ON public.wallet_transactions USING btree (created_at);


--
-- Name: idx_wallet_transactions_wallet_id; Type: INDEX; Schema: public; Owner: user
--

CREATE INDEX idx_wallet_transactions_wallet_id ON public.wallet_transactions USING btree (wallet_id);


--
-- Name: bookings update_bookings_updated_at; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER update_bookings_updated_at BEFORE UPDATE ON public.bookings FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: courts update_courts_updated_at; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER update_courts_updated_at BEFORE UPDATE ON public.courts FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: facilities update_facilities_updated_at; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER update_facilities_updated_at BEFORE UPDATE ON public.facilities FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: payments update_payments_updated_at; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER update_payments_updated_at BEFORE UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: tournaments update_tournaments_updated_at; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER update_tournaments_updated_at BEFORE UPDATE ON public.tournaments FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: user_wallets update_user_wallets_updated_at; Type: TRIGGER; Schema: public; Owner: user
--

CREATE TRIGGER update_user_wallets_updated_at BEFORE UPDATE ON public.user_wallets FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: booking_participants booking_participants_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.booking_participants
    ADD CONSTRAINT booking_participants_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id) ON DELETE CASCADE;


--
-- Name: bookings bookings_court_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.bookings
    ADD CONSTRAINT bookings_court_id_fkey FOREIGN KEY (court_id) REFERENCES public.courts(id);


--
-- Name: court_availability court_availability_court_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.court_availability
    ADD CONSTRAINT court_availability_court_id_fkey FOREIGN KEY (court_id) REFERENCES public.courts(id) ON DELETE CASCADE;


--
-- Name: courts courts_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.courts
    ADD CONSTRAINT courts_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id) ON DELETE CASCADE;


--
-- Name: payments payments_booking_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_booking_id_fkey FOREIGN KEY (booking_id) REFERENCES public.bookings(id);


--
-- Name: tournament_team_players tournament_team_players_team_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.tournament_team_players
    ADD CONSTRAINT tournament_team_players_team_id_fkey FOREIGN KEY (team_id) REFERENCES public.tournament_teams(id) ON DELETE CASCADE;


--
-- Name: tournament_teams tournament_teams_tournament_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.tournament_teams
    ADD CONSTRAINT tournament_teams_tournament_id_fkey FOREIGN KEY (tournament_id) REFERENCES public.tournaments(id) ON DELETE CASCADE;


--
-- Name: tournaments tournaments_facility_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.tournaments
    ADD CONSTRAINT tournaments_facility_id_fkey FOREIGN KEY (facility_id) REFERENCES public.facilities(id);


--
-- Name: wallet_transactions wallet_transactions_wallet_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: user
--

ALTER TABLE ONLY public.wallet_transactions
    ADD CONSTRAINT wallet_transactions_wallet_id_fkey FOREIGN KEY (wallet_id) REFERENCES public.user_wallets(id) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--

