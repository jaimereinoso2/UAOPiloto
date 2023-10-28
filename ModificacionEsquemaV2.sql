SET SQL_SAFE_UPDATES = 0;
-- LUEGO DE CARGAR LOS DATOS DESDE LOS ARCHIVOS EXCEL 
-- SE DEBE HACER LAS SIGUIENTES MODIFICACIONES EN LA BASE DE DATOS

-- 1. cambiamos la columna CODIGO por ID_ESTUDIANTE
ALTER TABLE `UAOPiloto`.`EstudiantesMatriculas` 
CHANGE COLUMN `CODIGO` `ID_ESTUDIANTE` BIGINT NULL DEFAULT NULL ;

-- 2. creamos la tabla PERIODOS_REGULARES a partir de la informacion 
-- en EstudianteAsignatura
select distinct periodo
from estudiantesmatriculas
where (periodo like '%4' or periodo like '%2');
-- R/ 202104 y 2022-02 y 2023-02.  

-- 2.1. encontré 
select distinct periodo
from estudianteasignatura;

select *
from EstudiantesMatriculas
where (periodo like '%4' or periodo like '%2')
and ACTIVO_FIN != 'N';

-- ENCUENTRO MULTITUD DE ERRORES EN LA TABLA estudiante.   
-- PARA NO ATRASAR MAS ESTO VOY A TRATAR DE RE-CONSTRUIRLA ADECUADAMENTE

-- primero busco si hay repetidos en 'estudiante', y si los hay.
select codigo, count(*)
from estudiante
group by codigo
having count(*) > 1;

-- luego trato de ver si son muchos los repetidos 
-- y cuantas veces se repite, y son un jurgo.  
-- hay casi una fila por cada periodo!!
select id_estudiante, count(*)
from (
	select distinct codigo id_estudiante, FECHA_GRADO
	from estudiante) v
group by id_estudiante
having count(*) > 1;

-- este es un buen ejemplo
select * 
from estudiante
where codigo = 2136684;

-- vamos a armar la cosa de a poco.  
-- creo estudiante_limpio (id_estudiante)
drop table estudiantes_limpio;
create table estudiantes_limpio as
select distinct codigo id_estudiante, null fecha_admitido, null fecha_grado, null fecha_nacimiento, 
                null genero, null colegio, null fecha_grado_colegio, null fecha_icfes, 
                null ciudad_colegio, null direccion_programa, null expediente
from estudiante;

-- la alteramos para que las columnas queden bien definidas
ALTER TABLE `UAOPiloto`.`estudiantes_limpio` 
CHANGE COLUMN `fecha_admitido` `fecha_admitido` DATE NULL DEFAULT NULL ,
CHANGE COLUMN `fecha_grado` `fecha_grado` DATE NULL DEFAULT NULL ,
CHANGE COLUMN `fecha_nacimiento` `fecha_nacimiento` DATE NULL DEFAULT NULL ,
CHANGE COLUMN `genero` `genero` VARCHAR(100) NULL DEFAULT NULL ,
CHANGE COLUMN `colegio` `colegio` VARCHAR(100) NULL DEFAULT NULL ,
CHANGE COLUMN `fecha_grado_colegio` `fecha_grado_colegio` DATE NULL DEFAULT NULL ,
CHANGE COLUMN `fecha_icfes` `fecha_icfes` DATE NULL DEFAULT NULL ,
CHANGE COLUMN `ciudad_colegio` `ciudad_colegio` VARCHAR(100) NULL DEFAULT NULL ,
CHANGE COLUMN `direccion_programa` `direccion_programa` VARCHAR(500) NULL DEFAULT NULL ,
CHANGE COLUMN `expediente` `expediente` VARCHAR(100) NULL DEFAULT NULL ;

-- probemos que no quedó ninguno repetido.  R/. Confirmado.
select id_estudiante, count(*)
from estudiantes_limpio
group by id_estudiante
having count(*) > 1;

--  confirmemos que si hay una fecha admitido, es única.  R/ Confirmado.
select id_estudiante, count(*)
from (
	select distinct codigo id_estudiante, fecha_admitido
	from estudiante
    where fecha_admitido is not null
    ) v
group by id_estudiante
having count(*) > 1;

-- la adicionamos FECHA_ADMITIDO a estudiantes_limpio
update estudiantes_limpio el
set el.fecha_admitido = 
   (select distinct e.fecha_admitido
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.fecha_admitido is not null);
commit;

-- la adicionamos FECHA_GRADO a estudiantes_limpio
update estudiantes_limpio el
set el.fecha_grado = 
   (select distinct e.fecha_grado
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.fecha_admitido is not null);
commit;

-- la adicionamos FECHA_NACIMIENTO a estudiantes_limpio
update estudiantes_limpio el
set el.fecha_nacimiento = 
   (select distinct e.fecha_nacimiento
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.fecha_nacimiento is not null);
commit;

-- la adicionamos GENERO a estudiantes_limpio
update estudiantes_limpio el
set el.genero = 
   (select distinct e.genero
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.genero is not null);
commit;

-- la adicionamos COLEGIO a estudiantes_limpio..  
-- OJO SI ENCONTRÓ ESTUDIANTES CON MÁS DE UN COLEGIO
-- ADICIONO LIMIT 1 para resolver el problema facilmente.
update estudiantes_limpio el
set el.colegio = 
   (select distinct e.colegio
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.colegio is not null
    limit 1);
commit;

-- Estos son los estudiantes problema
select id_estudiante, count(*)
from (
	select distinct e.codigo id_estudiante, e.colegio
	from estudiante e
	where e.colegio is not null
    limit 1) v
group by id_estudiante
having count(*) > 1;

-- estos fueron los problematicos
select distinct codigo, colegio
from estudiante
where codigo in (2130302, 2136170, 2136684, 2157176, 
   2167191, 2175869, 2185512, 2185526)
and colegio is not null
order by codigo;

-- la adicionamos FECHA_GRADO_COLEGIO a estudiantes_limpio.  
-- ERROR, fechas erroenas.  convierto a VARCHAR

ALTER TABLE `UAOPiloto`.`estudiantes_limpio` 
CHANGE COLUMN `fecha_grado_colegio` `fecha_grado_colegio` TEXT NULL DEFAULT NULL ;

update estudiantes_limpio el
set el.fecha_grado_colegio = 
   (select distinct e.fecha_grado_colegio
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.fecha_grado_colegio is not null);

commit;

-- la adicionamos FECHA_ICFES a estudiantes_limpio.  
update estudiantes_limpio el
set el.fecha_icfes = 
   (select distinct e.fecha_icfes
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.fecha_icfes is not null);
commit;

-- la adicionamos CIUDAD_COLEGIO a estudiantes_limpio.  
update estudiantes_limpio el
set el.ciudad_colegio = 
   (select distinct e.ciudad_colegio
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.ciudad_colegio is not null);
commit;

-- DIRECCION PROGRAMA NO TRAE NADA
select distinct direccion_programa from estudiante;

-- la adicionamos EXPEDIENTE a estudiantes_limpio.  
-- ERROR:  más de un expediente por estudiante.   se trae solo el primero. lIMIT 1
update estudiantes_limpio el
set el.expediente = 
   (select distinct e.expediente
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.expediente is not null
    limit 1);
commit;

-- confirmemos el resultado final:  337 FILAS
select count(*) 
from estudiantes_limpio;

-- CONFIRMEMOS QUE LA TABLA PERIODOS nos quedó bien
SELECT * FROM periodosRegulares;

-- ICFES
-- procedemos a mirar cómo están las áreas del icfes

select ifnull(biologia,-100), count(*)
from icfes
group by biologia
order by biologia;

-- NOTAS
-- miramos la composicion de las notas, qué valores hay en la base de datos.
select definitiva, definitiva_alf, count(*)
from estudianteasignatura
group by definitiva, definitiva_alf;

-- confirmemos la estructura de estudianteasignatura y si se repite notas o no
-- sacamos las distintas combinaciones de periodo, id_estudiante, cod_asig, definitiva, definitiva_alf
-- y luego miramos cuales están repetidas más de una vez.

drop table temp;

create table temp as
select periodo, id_estudiante, cod_asig, count(*) cuantos
from (
	select distinct periodo, id_estudiante, cod_asig, definitiva, definitiva_alf
	from EstudianteAsignatura) v
group by periodo, id_estudiante, cod_asig
having count(*) > 1;

-- Resulta que son  43 casos!!!
select * 
from temp
order by id_estudiante, periodo, cod_asig;

-- veamos qué notas traen a ver si es solo problema de nota y nota nula 
-- o si efectivamente vienen con notas distintas por grupo
select id_estudiante, periodo, cod_asig, grupo, definitiva, definitiva_alf
from estudianteasignatura
where (periodo, id_estudiante, cod_asig) in 
(
	select periodo, id_estudiante, cod_asig
	from temp
)
order by periodo, id_estudiante, cod_asig, grupo, definitiva, definitiva_alf;
-- R/ SON 90 CASOS

-- en la mayoría de los casos ocurre que son dos filas identicas, unas con nota y otras nulas.
-- PROCEDEMOS A BORRAR ESAS FILAS
delete from estudianteasignatura
where (periodo, id_estudiante, cod_asig) in 
 (select periodo, id_estudiante, cod_asig
  from temp
  where definitiva is null)
and definitiva is null;
commit;

-- Revisemos cómo vamos con esto de las notas duplicadas.  Ya eliminamos casos en donde aparecen dos filas, una con nota y otra con nota nula.
-- Veamos qué quedó.  VOLVEMOS A CREAR TEMP
drop table temp;

create table temp as
select periodo, id_estudiante, cod_asig, count(*) cuantos
from (
	select distinct periodo, id_estudiante, cod_asig, definitiva, definitiva_alf
	from EstudianteAsignatura) v
group by periodo, id_estudiante, cod_asig
having count(*) > 1;

-- y volvemos a verificar
select id_estudiante, periodo, cod_asig, grupo, definitiva, definitiva_alf
from estudianteasignatura
where (periodo, id_estudiante, cod_asig) in 
(
	select periodo, id_estudiante, cod_asig
	from temp
)
order by periodo, id_estudiante, cod_asig, grupo, definitiva, definitiva_alf;

-- R/ YA NO SALIERON FILAS.  RESUELTO EL LIO.  CADA ASIGNATURA TIENE UNA SOLA NOTA


-- verifiquemos que dad auna fila en estudiante asignatura tomando en cuenta (periodo, id_estudiante, cod_asig, definitiva)
-- NO EXISTA otra fila con igual periodo, id_estudiante, cod_asig y distinta definitiva

select periodo, id_estudiante, cod_asig, definitiva
from estudianteasignatura ea1
where exists (
	select 'x'
    from estudianteasignatura ea2
    where ea2.periodo = ea1.periodo
    and ea2.id_estudiante = ea1.id_estudiante
    and ea2.cod_asig = ea1.cod_asig
    and ifnull(ea2.definitiva, -1) != ifnull(ea1.definitiva,-1)
    );
    
-- R/ NINGUN CASO!!!  ESTO CONFIRMA QUE LA NOTA DE UNA ASIGNATURA ES ÚNICA, ASI TENGA MUCHOS GRUPOS.  
-- NO OCURRE QUE EN UNA ASIGANTURA, CADA GRUPO PUEDA TENER DISTINTA NOTA

-- RENOMBRAMOS estudianteasignatura a estudianteasignatura_old
ALTER TABLE `UAOPiloto`.`EstudianteAsignatura` 
RENAME TO  `UAOPiloto`.`EstudianteAsignatura_old` ;

-- creamos la nueva estudiante asignatura con un distinct
create table estudianteasignatura
select distinct periodo, id_estudiante, cod_dep, cod_asig, creditos, definitiva, definitiva_alf, cancelada_vol, cancelada_UAO, perdida_inasistencia, perdida, ganada
from estudianteasignatura_old;

-- comparemos resultados
select count(*) 
from estudianteasignatura_old;
-- R/10954

select count(*) 
from estudianteasignatura;
-- 9119.

-- confirmemos que no tengamos duplicados en estudiante asignatura al mirar periodo, id_estudiante, cod_asig.
select periodo, id_estudiante, cod_asig, count(*)
from EstudianteAsignatura
group by periodo, id_estudiante, cod_asig
having count(*) > 1;
-- R/ no hay duplicados en periodo, id_estudiante, cod_asig

-- creamos ahora EA_grupo.  no parece tener información interesante, excepto qué grupos tuvo una asignatura
drop table ea_grupo;
create table ea_grupo as
select distinct periodo, id_estudiante, cod_asig, grupo
from estudianteasignatura_old;
--  R/9837 filas creadas.

-- y ahora creamos EA_docentes
drop table ea_docentes;
create table ea_docentes as
select distinct periodo, id_estudiante, cod_dep, cod_asig, grupo, id_docente
from estudianteasignatura_old;
-- R/ 10954 filas creadas, que corresponde con lo esperado al contar filas en estudianteasignatura_old2.

-- y creemos docentes_grupos que indica qué docente dictó quñe grupo
drop table docentes_grupos;
create table docentes_grupos as
select distinct id_docente, periodo, cod_asig, grupo
from ea_docentes;


-- NIVEL_NOTA
-- si la nota es nula:  NIVEL_NOTA = -1
-- nota < 3.0 :  NIVEL_NOTA = 1
-- 3.0 <= nota < 3.8:  NIVEL_NOTA = 2
-- nota >= 3.8: NIVEL_NOTA = 3

ALTER TABLE `UAOPiloto`.`estudianteasignatura` 
ADD COLUMN `nivel_nota` VARCHAR(45) NULL AFTER `ganada`;

update estudianteasignatura
set nivel_nota = -1
where definitiva is null;
-- R/ 555 notas cambiadas

update estudianteasignatura
set nivel_nota = 1
where definitiva < 3;
-- R/ 344 notas cambiadas

update estudianteasignatura
set nivel_nota = 2
where definitiva >= 3.0
and   definitiva < 3.8;
-- R/ 2054 notas cambiadas

update estudianteasignatura
set nivel_nota = 3
where definitiva >= 3.8;

commit;


-- Al comparar lo que se quiere hacer con lo que hay en definitiva_alf se observa que esta ultima solo detecta el nulo según si fue nula, A, P, y R (preguntar qué es eso).
-- y si sí hay nota, detecta solo si es menor a 3 (NS) o igual o mayor a 3 (SP).
-- NIVEL_NOTA nos permitirá entender mejor si sacó una muy buena nota, regular o malita, o no tuvo nota.
select distinct definitiva, definitiva_alf
from estudianteasignatura
order by definitiva, definitiva_alf;

-- Ahora verifiquemos la información del icfes

 SELECT  id_estudiante, IFNULL(icfes_antiguo,-100) icfes_antiguo, IFNULL(biologia,-100) biologia, IFNULL(matematica,-100) matematica, 
			IFNULL(filosofia,-100) filosofia, 
            IFNULL(fisica,-100) fisica, IFNULL(historia,-100) historia, IFNULL(quimica,-100) quimica, IFNULL(lenguaje,-100) lenguaje, 
            IFNULL(geografia,-100) geografia, IFNULL(idioma,-100) idioma, IFNULL(interdisciplinar,-100) interdisciplinar
 FROM icfes;
 
 -- CURSOS EXTRACURRICULARES (EstudiantesActividadeS=
 -- esa tabla usa es la identificación del estudiante y no su codigo, parece.
 -- Antes de iniciar, creé la tabla actividades con el nobmre de la actividad y su tipo: deporte, cultura, ...
 -- Esta la hice a mano verificando la información que había en EsudiantesActividades y creando un tipo que premite saber si hizo deporte, cultura u otro.

select * from actividades;
-- R/ 88 filas.   

-- EstudiantesActividades son las actividades que los estudiantes realmente tomaron
select * 
from EstudiantesActividades;
-- R/ 3283 filas unicamente.

-- la fecha viene en formato TEXT y hay que convertirla a DATE
-- los primeros 8 caracteres son dd/mm/yy

select distinct str_to_date(substring(fecha_asistencia, 1,8),'%d/%m/%y')
from estudiantesactividades
order by 1;

--   EDAD DOCENTES
-- en DocentesEstudios está la fecha de nacimiento del docente.  veamos si existe solo una fila por cada docente

-- veamos cuántas filas hay 
select count(*)
from docentesestudios;
-- R/ 121.  Es muy poca infomración.

-- veamos si hay repetidos por cédula
select emp_cedula, count(*)
from docentesestudios
group by emp_cedula
having count(*) > 1;
-- R/ hay dos casos con 2 filas unicamente.  16692463 y 80200393

-- creamos la tabla docentes (cedula, fecha_nacimiento, genero)
drop table docentes;

create table docentes as
select distinct emp_cedula cedula, naci fecha_nacimiento, emp_sexo genero
from docentesestudios;

select * from docentes;
-- R/ 119 filas creadas

-- ESTUDIANTES:  Confirmemos que tenemos la info completa de todos los estudiantes
select distinct fecha_admitido
from estudiante;

-- AHORA VAMOS A TRABAJAR CON NOTA por asignatura (como lo hice en javeriana)
select distinct cod_dep
from estudianteasignatura;
-- son en total 23 departamentos y un NULO.

-- confirmemos ese NULO.
select *
from estudianteasignatura
where cod_dep is null;
-- R/ son 9 filas únicamente, y corresponden al codÑasig 212221.
-- Veamos qué departamento aparece para ese codigo de asignatura en otras filas.

select distinct cod_dep
from estudianteasignatura
where cod_asig = 212221;
-- R/ DDA.

-- vamos a hacer un update para corregir esto
UPDATE estudianteasignatura
set cod_dep = 'DDA'
where cod_dep is null;
-- se actualizaron las 9 filas.

commit;

-- encuentro de todas formas definitiva NULA.  
-- Veamos si lo que pasa es que hay otra fila de la misma asig con nota distinta a nula

select id_estudiante, periodo, cod_asig, definitiva
from estudianteasignatura ea1
where exists (
   select 'x'
   from estudianteasignatura ea2
   where ea2.id_estudiante = ea1.id_estudiante
   and ea2.periodo = ea1.periodo
   and ea2.cod_asig = ea1.cod_asig
   and ea2.definitiva is null);
   
-- R/ hay 555 casos..  veamos cuantos tienen que ver con que se canceló la asigantura
select id_estudiante, periodo, cod_asig, definitiva
from estudianteasignatura ea1
where definitiva is null
and (cancelada_vol = 'S' or cancelada_UAO = 'S');
-- R/ 37 casos corresponden a que la asignatura fue cancelada de forma voluntaria o por la UAO.  ¿y el resto?

-- para evitar problemas, voy a quitar las notas nulas, excepto si fueron canceladas.
delete from estudianteasignatura 
where definitiva is null
and (cancelada_vol != 'S' and cancelada_UAO != 'S');
-- 518 borradas
commit;

-- verifiquemos qué fue lo que quedó con nulo en definitiva
select id_estudiante, periodo, cod_asig, definitiva, cancelada_vol, cancelada_UAO
from estudianteasignatura ea1
where definitiva is null;

-- R/ efectivamente, son 37 casos en que o el estudiante canceló o fue la UAO.   ahi si es consistente nota nula con eso.



-- YA NO HAY NULOS EN COD_DEP.
-- Miremos si aún hay casos de nulos.
SELECT ea.id_estudiante, ea.periodo, ea2.cod_dep, min(ea2.definitiva) min_definitiva, 
                                                  max(ea2.definitiva) max_definitiva, 
                                                  avg(ea2.definitiva) avg_definitiva,
                                                  count(ea2.definitiva) cnt_definitiva
FROM estudianteasignatura ea, estudianteasignatura ea2
WHERE ea.id_estudiante = ea2.id_estudiante
AND   ea.periodo > ea2.periodo
AND (ea2.cancelada_vol = 'N' and ea2.cancelada_UAO = 'N')  -- sin tomar en cuenta canceladas
GROUP BY ea.id_estudiante, ea.periodo, ea2.cod_dep
having min_definitiva is null;
-- R/ CERO!!!..  muy bien.


--  VUELVO A REVISAR ESTUDIANTEASIGNATURA_OLD porque ERIK sostiene que la nota va por grupo
    
-- debido a ERIK dice que la nota es por grupo, hago un query en estudianteAsignatura_old 
-- buscando que exista otra fila en esa misma tabla para el mismo estudiante, periodo y asigantura
-- con diferente código.    No retorna filas
select * 
from estudianteasignatura_old eao
where exists 
   (select 'x'
    from estudianteasignatura_old eao2
    where eao2.id_estudiante = eao.id_estudiante
    and   eao2.periodo = eao.periodo
    and   eao2.cod_asig = eao.cod_asig
    and   eao2.definitiva != eao.definitiva);
-- R/ NO filas.


 -- 3.6 EXPERIENCIA DOCENTE EN LA MISMA ASIGNATURA
 --  definimos la experiencia docente de un docente en una asignatura y periodo, 
 --  como el número de grupos que había dictado en períodos anteriores de esa misma asignatura
 -- ENTONCES:  dado un estudiante y un periodo, 
--     se obtiene la experiencia docente de todos los docentes de las asignaturas que ese estudiante tomó en períodos anteriores

select id_estudiante, periodo, cod_dep,  avg(experiencia) avg_experiencia
from (
	select ed.id_estudiante, ed.periodo, ed.cod_asig, ed.cedula, ed.cod_dep, count(*) experiencia
	from ea_docentes ed, docentes_grupos dg
	where dg.cedula = ed.cedula
	and   dg.periodo < ed.periodo
	and   dg.cod_asig = ed.cod_asig
	group by ed.id_estudiante, ed.periodo, ed.cod_asig, ed.cedula, ed.cod_dep
) v
group by id_estudiante, periodo, cod_dep
order by avg_experiencia desc;
 
 
 select datos.id_estudiante, datos.periodo
 from estudianteasignatura datos, ea_docentes aed, docentes_grupos dg
 where ead.id_estudiante = datos.id_estudiante
 and   ead.periodo < datos.periodo
 and   dg.periodo = ead.periodo
 and   dg.cod_asig = ead.cod_asig;
 
 -- 3.8 PROMEDIOS ANTERIORES
 
 select em1.id_estudiante, em1.periodo, em2.prom_ponderado_sem, pr1.orden - pr2.orden distancia
    from estudiantesmatriculas em1, periodosregulares pr1, estudiantesmatriculas em2, periodosregulares pr2
    where pr1.periodo = em1.periodo
    and   em2.id_estudiante = em1.id_estudiante
    and   pr2.periodo = em2.periodo
    and   pr1.orden > pr2.orden;
 
 
 




select periodo, cod_asig, grupo, id_estudiante, count(*)
from estudianteasignatura_old
group by periodo, cod_asig, grupo, id_estudiante
having count(*) > 2;

select * 
from estudianteasignatura_old
where id_estudiante = 2205090
and periodo = 202003
and cod_asig = 421288;

select *
from estudianteasignatura ea1
where exists (
   select 'x'
   from estudianteasignatura ea2
   where ea2.id_estudiante = ea1.id_estudiante
   and   ea2.periodo = ea1.periodo
   and   ea2.cod_asig = ea1.cod_asig
   and   ea2.definitiva != ea1.definitiva);
   

select distinct fecha_admitido
from estudiante;

select count(*) 
from estudianteasignatura;

select count(*)
from estudiantesactividades;
-- R/ 2684

select count(*)
from estudiantesmatriculas;
-- R/ 1253
   
   
   






















