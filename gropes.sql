PGDMP         2                y            gropes    13.2    13.2 )    ?           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            ?           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            ?           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            ?           1262    32768    gropes    DATABASE     f   CREATE DATABASE gropes WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'Portuguese_Brazil.1252';
    DROP DATABASE gropes;
                postgres    false            ?            1255    42854    calcula_deterioracao() 	   PROCEDURE     
  CREATE PROCEDURE public.calcula_deterioracao()
    LANGUAGE plpgsql
    AS $$
DECLARE
    CURSOR_1 CURSOR is
	SELECT EMP.ID_USUARIO AS ID_USER,ITE.TECNOLOGIA_ID AS ID_TECH,
	SUM(CASE WHEN coalesce(ITE.DATA_INI,EMP.DATA_INI) > CURRENT_DATE - INTERVAL '2 YEARS' THEN
			EXTRACT(YEAR FROM age(coalesce(ITE.DATA_INI,EMP.DATA_INI,CURRENT_DATE),
								  coalesce(ITE.DATA_INI,EMP.DATA_INI))) * 12 
			+ EXTRACT(MONTH FROM age(coalesce(ITE.DATA_INI,EMP.DATA_INI,CURRENT_DATE),
								  coalesce(ITE.DATA_INI,EMP.DATA_INI)))
		ELSE
			EXTRACT(YEAR FROM age(coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE),
								  CURRENT_DATE - INTERVAL '2 YEARS')) * 12 
			+ EXTRACT(MONTH FROM age(coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE),
								  CURRENT_DATE - INTERVAL '2 YEARS'))
	    END) AS TEMPO_TRABALHADO,
		MIN(EXTRACT(YEAR FROM AGE((SELECT COALESCE(MIN(AUX.DATA_INI),CURRENT_DATE) FROM EMPRESA_USUARIO AUX,EMPRESA_USUARIO_ITEM AUX2
		   WHERE AUX.DATA_INI > COALESCE(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE) 
			AND AUX.ID = AUX2.EMPUSU_ID AND AUX2.TECNOLOGIA_ID = ITE.TECNOLOGIA_ID AND AUX.ID_USUARIO = EMP.ID_USUARIO)
			,coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE))) * 12 + EXTRACT(MONTH FROM AGE( 
			(SELECT COALESCE(MIN(AUX.DATA_INI),CURRENT_DATE) FROM EMPRESA_USUARIO AUX,EMPRESA_USUARIO_ITEM AUX2
		   WHERE AUX.DATA_INI > COALESCE(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE) 
			AND AUX.ID = AUX2.EMPUSU_ID AND AUX2.TECNOLOGIA_ID = ITE.TECNOLOGIA_ID AND AUX.ID_USUARIO = EMP.ID_USUARIO
			),coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE)))
		)
		AS TEMPO_INATIVO,
		AVG((((CAST((inverte_escala(EMP.DIVERSIDADE)) AS NUMERIC(10,2)) +
			   CAST((inverte_escala(EMP.COMPLEXIDADE)) AS NUMERIC(10,2)) +
			   CAST((inverte_escala(ITE.FREQUENCIA)) AS NUMERIC(10,2)))/3) * 0.00834)) AS CALC
	FROM EMPRESA_USUARIO EMP,EMPRESA_USUARIO_ITEM ITE
	WHERE EMP.ID = ITE.EMPUSU_ID
	AND coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE) >= CURRENT_DATE - INTERVAL '2 YEARS'
	GROUP BY EMP.ID_USUARIO,ITE.TECNOLOGIA_ID;
BEGIN
	UPDATE EMPRESA_USUARIO_ITEM SET DET= NULL;
	FOR
	RS IN CURSOR_1 LOOP
	IF (RS.TEMPO_TRABALHADO > 24) THEN
		RS.TEMPO_TRABALHADO = 24;
	END IF;
	RS.CALC = 1-((RS.TEMPO_TRABALHADO * RS.CALC) + (5 * 0.00834 * RS.TEMPO_INATIVO));
	UPDATE EMPRESA_USUARIO_ITEM SET DET = RS.CALC
	WHERE TECNOLOGIA_ID = RS.ID_TECH
	AND EXISTS(SELECT EMPRESA_USUARIO.ID FROM EMPRESA_USUARIO 
			   WHERE EMPRESA_USUARIO_ITEM.EMPUSU_ID = EMPRESA_USUARIO.ID
			  AND EMPRESA_USUARIO.ID_USUARIO = RS.ID_USER);
	END LOOP;
	UPDATE EMPRESA_USUARIO_ITEM
	SET DET = COALESCE(DET,0);
END;
$$;
 .   DROP PROCEDURE public.calcula_deterioracao();
       public          postgres    false            ?            1255    42708    calcula_dominio() 	   PROCEDURE     ?  CREATE PROCEDURE public.calcula_dominio()
    LANGUAGE plpgsql
    AS $$
DECLARE
    CURSOR_1 CURSOR is
	SELECT ITE.EMPUSU_ID AS EMPUSU_ID_VAR,ITE.TECNOLOGIA_ID AS TECNOLOGIA_ID_VAR,
	EXTRACT(YEAR FROM age(coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE),
								  coalesce(ITE.DATA_INI,EMP.DATA_INI))) * 12 
	+ EXTRACT(MONTH FROM age(coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE),
								  coalesce(ITE.DATA_INI,EMP.DATA_INI))) AS EXPERIENCIA,
	((CAST(EMP.DIVERSIDADE AS NUMERIC(10,2)) + 
	 CAST(EMP.COMPLEXIDADE AS NUMERIC(10,2)) +
	 CAST(ITE.FREQUENCIA AS NUMERIC(10,2)))/3) *
	(EXTRACT(YEAR FROM age(coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE),
								  coalesce(ITE.DATA_INI,EMP.DATA_INI))) * 12 
	+ EXTRACT(MONTH FROM age(coalesce(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE),
								  coalesce(ITE.DATA_INI,EMP.DATA_INI)))) AS CA 
	 							  FROM EMPRESA_USUARIO EMP,EMPRESA_USUARIO_ITEM ITE
									WHERE EMP.ID = ITE.EMPUSU_ID;
BEGIN
	FOR
	RS IN CURSOR_1 LOOP
	UPDATE EMPRESA_USUARIO_ITEM
			SET CA = RS.CA,
			EXP = RS.EXPERIENCIA			
			WHERE TECNOLOGIA_ID = RS.TECNOLOGIA_ID_VAR
			AND EMPUSU_ID = RS.EMPUSU_ID_VAR;
	END LOOP;
END;
$$;
 )   DROP PROCEDURE public.calcula_dominio();
       public          postgres    false            ?            1255    42122    calcula_inovatividade() 	   PROCEDURE     ?  CREATE PROCEDURE public.calcula_inovatividade()
    LANGUAGE plpgsql
    AS $$
DECLARE
    CURSOR_1 CURSOR is
	SELECT CAST(EXTRACT(YEAR FROM age(CURRENT_DATE,TEC.CONHECE_DESDE)) * 12 
	+ EXTRACT(MONTH FROM age(CURRENT_DATE,TEC.CONHECE_DESDE))
	AS NUMERIC(18,2)) 
	/
	(SELECT EXTRACT(YEAR FROM age(CURRENT_DATE,min(CONHECE_DESDE))) * 12 
	+ EXTRACT(MONTH FROM age(CURRENT_DATE,min(CONHECE_DESDE)))
	from tecnologia_usuario where id_tecnologia = tec.id_tecnologia) as inovatividade,
	tec.id_usuario AS id_user,tec.id_tecnologia as id_tech from tecnologia_usuario tec;
BEGIN
	FOR
	RS IN CURSOR_1 LOOP
	UPDATE TECNOLOGIA_USUARIO
			SET INOVATIVIDADE = RS.inovatividade
			WHERE ID_USUARIO = RS.id_user
			AND ID_TECNOLOGIA = RS.id_tech;
	END LOOP;
END;
$$;
 /   DROP PROCEDURE public.calcula_inovatividade();
       public          postgres    false            ?            1255    41829    calcula_relevancia() 	   PROCEDURE     h  CREATE PROCEDURE public.calcula_relevancia()
    LANGUAGE plpgsql
    AS $$
DECLARE
    CURSOR_1 CURSOR is
	SELECT TECNOLOGIA_ID,
		   CAST(COUNT(ID_USUARIO) AS NUMERIC(18,2))/(SELECT COUNT(ID) FROM USUARIO) as RELEVANCIA
	FROM
			(SELECT ITE.TECNOLOGIA_ID, EMP.ID_USUARIO
			FROM EMPRESA_USUARIO EMP,EMPRESA_USUARIO_ITEM ITE
			WHERE EMP.ID = ITE.EMPUSU_ID 
			AND COALESCE(ITE.DATA_FIM,EMP.DATA_FIM,CURRENT_DATE) 
			>= CURRENT_DATE - INTERVAL '2 YEARS'
			UNION 
			SELECT TECUSU.ID_TECNOLOGIA,TECUSU.ID_USUARIO 
			FROM TECNOLOGIA_USUARIO TECUSU
			WHERE TECUSU.ESTUDA_DESDE IS NOT NULL) as subquery
		GROUP BY TECNOLOGIA_ID;
BEGIN
	UPDATE TECNOLOGIA
		SET RELEVANCIA = NULL;
	FOR
	RS IN CURSOR_1 LOOP
	UPDATE TECNOLOGIA
			SET RELEVANCIA = RS.RELEVANCIA
			WHERE ID = RS.TECNOLOGIA_ID;
	END LOOP;
	UPDATE TECNOLOGIA
	SET RELEVANCIA = COALESCE(RELEVANCIA,0);
END;
$$;
 ,   DROP PROCEDURE public.calcula_relevancia();
       public          postgres    false            ?            1255    49169    calcula_score() 	   PROCEDURE     -  CREATE PROCEDURE public.calcula_score()
    LANGUAGE plpgsql
    AS $$
DECLARE CURSOR_1 CURSOR is
SELECT USU_ID , SUM(DOMINIO * (SELECT SUM(INOVATIVIDADE)/COUNT(*) FROM TECNOLOGIA_USUARIO WHERE ID_USUARIO = USU_ID)) AS SCORE
FROM (SELECT USU.ID USU_ID, SUM(((ITE.CA* (case when ITE.DET = 0 then 0.1 else ITE.DET end)) + ITE.EXP)
	 * (case when TEC.RELEVANCIA = 0 then 0.01 else TEC.RELEVANCIA end)) AS DOMINIO FROM 
	 EMPRESA_USUARIO EMP,EMPRESA_USUARIO_ITEM ITE,TECNOLOGIA TEC,USUARIO USU
	 WHERE EMP.ID = ITE.EMPUSU_ID
	 AND TEC.ID = ITE.TECNOLOGIA_ID
	 AND USU.ID = EMP.ID_USUARIO
	 GROUP BY USU.ID
	 UNION ALL
	 SELECT USU.ID USU_ID,
		SUM((
			((SELECT EXTRACT(YEAR FROM age(COALESCE(TEC_USU.ESTUDOU_ATE,CURRENT_DATE),
										   COALESCE(TEC_USU.ESTUDA_DESDE,CURRENT_DATE))) * 12 
	+ EXTRACT(MONTH FROM age(COALESCE(TEC_USU.ESTUDOU_ATE,CURRENT_DATE),
							 COALESCE(TEC_USU.ESTUDA_DESDE,CURRENT_DATE)))) * 2) 
	+ EXTRACT(YEAR FROM age(COALESCE(TEC_USU.ESTUDOU_ATE,CURRENT_DATE),
								   COALESCE(TEC_USU.ESTUDA_DESDE,CURRENT_DATE))) * 12 
	+ EXTRACT(MONTH FROM age(COALESCE(TEC_USU.ESTUDOU_ATE,CURRENT_DATE),COALESCE(TEC_USU.ESTUDA_DESDE,CURRENT_DATE)))
		)
    * (case when TEC.RELEVANCIA = 0 then 0.01 else TEC.RELEVANCIA end))
            FROM USUARIO USU,
                 TECNOLOGIA_USUARIO TEC_USU,
                 TECNOLOGIA TEC       
           WHERE USU.ID = TEC_USU.ID_USUARIO
             AND TEC_USU.ID_TECNOLOGIA = TEC.ID
             AND TEC_USU.ESTUDA_DESDE IS NOT NULL
           GROUP BY USU_ID
	 ) AS SUBQUERY
GROUP BY USU_ID ORDER BY 2 DESC;	 
BEGIN
	call public.calcula_inovatividade();
	call public.calcula_relevancia();
	call public.calcula_dominio();
	call public.calcula_deterioracao();
	FOR
	RS IN CURSOR_1 LOOP
	UPDATE USUARIO
			SET SCORE = RS.SCORE
			WHERE ID = RS.USU_ID;
	END LOOP;
END;
$$;
 '   DROP PROCEDURE public.calcula_score();
       public          postgres    false            ?            1255    49168    inverte_escala(integer)    FUNCTION     ^  CREATE FUNCTION public.inverte_escala(nval_in integer) RETURNS integer
    LANGUAGE plpgsql
    AS $$ 
BEGIN
  IF (nVAL_IN = 1) THEN
    RETURN 5;
  ELSIF (nVAL_IN = 2) THEN
    RETURN  4;
  ELSIF (nVAL_IN = 3) THEN
    RETURN 3;
  ELSIF (nVAL_IN = 4) THEN
    RETURN 2;
  ELSIF (nVAL_IN = 5) THEN
    RETURN 1;
  ELSE
   RETURN 0;
  END IF;
END
$$;
 6   DROP FUNCTION public.inverte_escala(nval_in integer);
       public          postgres    false            ?            1259    42857    empresa    TABLE     ?   CREATE TABLE public.empresa (
    id bigint NOT NULL,
    autonomo character(1),
    descricao character varying(255) NOT NULL
);
    DROP TABLE public.empresa;
       public         heap    postgres    false            ?            1259    42855    empresa_id_seq    SEQUENCE     w   CREATE SEQUENCE public.empresa_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.empresa_id_seq;
       public          postgres    false    201            ?           0    0    empresa_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.empresa_id_seq OWNED BY public.empresa.id;
          public          postgres    false    200            ?            1259    42865    empresa_usuario    TABLE     I  CREATE TABLE public.empresa_usuario (
    id bigint NOT NULL,
    complexidade integer,
    data_fim timestamp without time zone,
    data_ini timestamp without time zone,
    diversidade integer,
    id_empresa bigint NOT NULL,
    id_usuario bigint NOT NULL,
    descricao character varying(255),
    trabalho_atual boolean
);
 #   DROP TABLE public.empresa_usuario;
       public         heap    postgres    false            ?            1259    42863    empresa_usuario_id_seq    SEQUENCE        CREATE SEQUENCE public.empresa_usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.empresa_usuario_id_seq;
       public          postgres    false    203            ?           0    0    empresa_usuario_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.empresa_usuario_id_seq OWNED BY public.empresa_usuario.id;
          public          postgres    false    202            ?            1259    42871    empresa_usuario_item    TABLE     ?  CREATE TABLE public.empresa_usuario_item (
    ca double precision,
    data_fim timestamp without time zone,
    data_ini timestamp without time zone,
    det double precision,
    exp integer,
    frequencia integer,
    tecnologia_id bigint NOT NULL,
    empusu_id bigint NOT NULL,
    utiliza_atual character(1)
);
 (   DROP TABLE public.empresa_usuario_item;
       public         heap    postgres    false            ?            1259    42878 
   tecnologia    TABLE     ?   CREATE TABLE public.tecnologia (
    id bigint NOT NULL,
    descricao character varying(255) NOT NULL,
    relevancia double precision
);
    DROP TABLE public.tecnologia;
       public         heap    postgres    false            ?            1259    42876    tecnologia_id_seq    SEQUENCE     z   CREATE SEQUENCE public.tecnologia_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.tecnologia_id_seq;
       public          postgres    false    206            ?           0    0    tecnologia_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.tecnologia_id_seq OWNED BY public.tecnologia.id;
          public          postgres    false    205            ?            1259    42884    tecnologia_usuario    TABLE     \  CREATE TABLE public.tecnologia_usuario (
    conhece_desde timestamp without time zone,
    estuda_desde timestamp without time zone,
    estudou_ate timestamp without time zone,
    inovatividade double precision,
    id_usuario bigint NOT NULL,
    id_tecnologia bigint NOT NULL,
    mais_de24meses character(1),
    aplicacao_pratica integer
);
 &   DROP TABLE public.tecnologia_usuario;
       public         heap    postgres    false            ?            1259    42891    usuario    TABLE     y  CREATE TABLE public.usuario (
    id bigint NOT NULL,
    nascimento timestamp without time zone,
    nome character varying(100) NOT NULL,
    score double precision,
    senha character varying(255),
    email character varying(255),
    cep character varying(255),
    complemento character varying(255),
    numero character varying(255),
    rua character varying(255)
);
    DROP TABLE public.usuario;
       public         heap    postgres    false            ?            1259    42889    usuario_id_seq    SEQUENCE     w   CREATE SEQUENCE public.usuario_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.usuario_id_seq;
       public          postgres    false    209            ?           0    0    usuario_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.usuario_id_seq OWNED BY public.usuario.id;
          public          postgres    false    208            C           2604    42860 
   empresa id    DEFAULT     h   ALTER TABLE ONLY public.empresa ALTER COLUMN id SET DEFAULT nextval('public.empresa_id_seq'::regclass);
 9   ALTER TABLE public.empresa ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    201    200    201            D           2604    42868    empresa_usuario id    DEFAULT     x   ALTER TABLE ONLY public.empresa_usuario ALTER COLUMN id SET DEFAULT nextval('public.empresa_usuario_id_seq'::regclass);
 A   ALTER TABLE public.empresa_usuario ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    202    203    203            E           2604    42881    tecnologia id    DEFAULT     n   ALTER TABLE ONLY public.tecnologia ALTER COLUMN id SET DEFAULT nextval('public.tecnologia_id_seq'::regclass);
 <   ALTER TABLE public.tecnologia ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    206    205    206            F           2604    42894 
   usuario id    DEFAULT     h   ALTER TABLE ONLY public.usuario ALTER COLUMN id SET DEFAULT nextval('public.usuario_id_seq'::regclass);
 9   ALTER TABLE public.usuario ALTER COLUMN id DROP DEFAULT;
       public          postgres    false    208    209    209            H           2606    42862    empresa empresa_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.empresa
    ADD CONSTRAINT empresa_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.empresa DROP CONSTRAINT empresa_pkey;
       public            postgres    false    201            L           2606    42875 .   empresa_usuario_item empresa_usuario_item_pkey 
   CONSTRAINT     ?   ALTER TABLE ONLY public.empresa_usuario_item
    ADD CONSTRAINT empresa_usuario_item_pkey PRIMARY KEY (empusu_id, tecnologia_id);
 X   ALTER TABLE ONLY public.empresa_usuario_item DROP CONSTRAINT empresa_usuario_item_pkey;
       public            postgres    false    204    204            J           2606    42870 $   empresa_usuario empresa_usuario_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.empresa_usuario
    ADD CONSTRAINT empresa_usuario_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.empresa_usuario DROP CONSTRAINT empresa_usuario_pkey;
       public            postgres    false    203            N           2606    42883    tecnologia tecnologia_pkey 
   CONSTRAINT     X   ALTER TABLE ONLY public.tecnologia
    ADD CONSTRAINT tecnologia_pkey PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.tecnologia DROP CONSTRAINT tecnologia_pkey;
       public            postgres    false    206            P           2606    42888 *   tecnologia_usuario tecnologia_usuario_pkey 
   CONSTRAINT        ALTER TABLE ONLY public.tecnologia_usuario
    ADD CONSTRAINT tecnologia_usuario_pkey PRIMARY KEY (id_tecnologia, id_usuario);
 T   ALTER TABLE ONLY public.tecnologia_usuario DROP CONSTRAINT tecnologia_usuario_pkey;
       public            postgres    false    207    207            R           2606    73730 $   usuario uk_5171l57faosmj8myawaucatdw 
   CONSTRAINT     `   ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT uk_5171l57faosmj8myawaucatdw UNIQUE (email);
 N   ALTER TABLE ONLY public.usuario DROP CONSTRAINT uk_5171l57faosmj8myawaucatdw;
       public            postgres    false    209            T           2606    42896    usuario usuario_pkey 
   CONSTRAINT     R   ALTER TABLE ONLY public.usuario
    ADD CONSTRAINT usuario_pkey PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.usuario DROP CONSTRAINT usuario_pkey;
       public            postgres    false    209            X           2606    42912 0   empresa_usuario_item fk4fu0o6wgk9drf2nhk84y8bksc    FK CONSTRAINT     ?   ALTER TABLE ONLY public.empresa_usuario_item
    ADD CONSTRAINT fk4fu0o6wgk9drf2nhk84y8bksc FOREIGN KEY (empusu_id) REFERENCES public.empresa_usuario(id) ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.empresa_usuario_item DROP CONSTRAINT fk4fu0o6wgk9drf2nhk84y8bksc;
       public          postgres    false    204    203    2890            W           2606    42907 0   empresa_usuario_item fk6qwdnf1aun57rf29jw7q9lde2    FK CONSTRAINT     ?   ALTER TABLE ONLY public.empresa_usuario_item
    ADD CONSTRAINT fk6qwdnf1aun57rf29jw7q9lde2 FOREIGN KEY (tecnologia_id) REFERENCES public.tecnologia(id) ON DELETE CASCADE;
 Z   ALTER TABLE ONLY public.empresa_usuario_item DROP CONSTRAINT fk6qwdnf1aun57rf29jw7q9lde2;
       public          postgres    false    204    2894    206            U           2606    42897 +   empresa_usuario fkas3d10m31o6nm9s3lphkl61o0    FK CONSTRAINT     ?   ALTER TABLE ONLY public.empresa_usuario
    ADD CONSTRAINT fkas3d10m31o6nm9s3lphkl61o0 FOREIGN KEY (id_empresa) REFERENCES public.empresa(id) ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.empresa_usuario DROP CONSTRAINT fkas3d10m31o6nm9s3lphkl61o0;
       public          postgres    false    201    2888    203            Y           2606    42917 .   tecnologia_usuario fkhdas3asico50h6rcmdmpxu5oa    FK CONSTRAINT     ?   ALTER TABLE ONLY public.tecnologia_usuario
    ADD CONSTRAINT fkhdas3asico50h6rcmdmpxu5oa FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.tecnologia_usuario DROP CONSTRAINT fkhdas3asico50h6rcmdmpxu5oa;
       public          postgres    false    209    2900    207            Z           2606    42922 .   tecnologia_usuario fkl8wq3rnt4y44l7kafwgnggi60    FK CONSTRAINT     ?   ALTER TABLE ONLY public.tecnologia_usuario
    ADD CONSTRAINT fkl8wq3rnt4y44l7kafwgnggi60 FOREIGN KEY (id_tecnologia) REFERENCES public.tecnologia(id) ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.tecnologia_usuario DROP CONSTRAINT fkl8wq3rnt4y44l7kafwgnggi60;
       public          postgres    false    206    207    2894            V           2606    42902 +   empresa_usuario fktrmuk4jbp4yuirc5ullsub2yk    FK CONSTRAINT     ?   ALTER TABLE ONLY public.empresa_usuario
    ADD CONSTRAINT fktrmuk4jbp4yuirc5ullsub2yk FOREIGN KEY (id_usuario) REFERENCES public.usuario(id) ON DELETE CASCADE;
 U   ALTER TABLE ONLY public.empresa_usuario DROP CONSTRAINT fktrmuk4jbp4yuirc5ullsub2yk;
       public          postgres    false    2900    209    203           