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
update estudiantes_limpio el
set el.fecha_grado_colegio = 
   (select distinct e.fecha_grado_colegio
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.fecha_grado_colegio is not null);
commit;

-- vienen errores de fechas.  convierto la columna a VARCHAR
ALTER TABLE `UAOPiloto`.`estudiantes_limpio` 
CHANGE COLUMN `fecha_grado_colegio` `fecha_grado_colegio` VARCHAR(100) NULL DEFAULT NULL ;


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

create table temp as
select periodo, id_estudiante, cod_asig, count(*) cuantos
from (
select distinct periodo, id_estudiante, cod_asig, definitiva, definitiva_alf
from EstudianteAsignatura) v
group by periodo, id_estudiante, cod_asig
having count(*) > 1;

-- Resulta que son muy pocas!!!   solo 8 casos!!!

-- asegurémonos que son detectables.
select *
from estudianteasignatura
where (periodo, id_estudiante, cod_asig) in 
(
	select periodo, id_estudiante, cod_asig
	from temp
)
order by periodo, id_estudiante, cod_asig, definitiva;

-- PROCEDEMOS A BORRAR ESAS FILAS
-- nota:  envío email a erik con la informacion anterior pues los casos de error 
-- es porque aparece el mismo estudiante, asignatura y periodo cancelada y no cancelada con nota.
delete from estudianteasignatura
where (periodo, id_estudiante, cod_asig) in 
 (select periodo, id_estudiante, cod_asig
  from temp
  where definitiva is null)
and definitiva is null;
commit;

-- -- verifiquemos que la combinación periodo, estudiante, cod_asig no aparecen con distinta nota, incluso si la nota es nula.
select periodo, id_estudiante, cod_asig, ifnull(definitiva,-1), count(*)
from estudianteasignatura
group by periodo, id_estudiante, cod_asig, ifnull(definitiva,-1)
having count(*) > 1;
-- R/ ENCONTRAMOS QUE SOLO OCURRE NULL EN EL 202303 que es el período actual, lo cual es correcto.

-- veamos un caso particular.
select * from EstudianteAsignatura
where periodo = 201801 
and id_estudiante = 2147567
and cod_asig = 211287;
-- R/ efectivamente, aparece la misma nota, con 3 profesores distintos
--  IDEA, estudianteasignatura debería transformarse en 3 tablas: 
-- 		estudianteasignatura: una concentrada en periodo, id_estudiante, cod_asig como pk
--      EA_grupo:   periodo, id_estudiante, cod_asig, grupo como pk
--      EA_grupo:  periodo, id_estudiante, cod_asig, grupo, cedula;

-- verifiquemos que la combinación periodo, estudiante, cod_asig no aparecen con distinta nota, incluso si la nota es nula.
select periodo, id_estudiante, cod_asig, count(*)
from (
select periodo, id_estudiante, cod_asig, ifnull(definitiva,-1), count(*)
from estudianteasignatura
group by periodo, id_estudiante, cod_asig, ifnull(definitiva,-1)
having count(*) > 1) v
group by periodo, id_estudiante, cod_asig
having count(*) > 1;
-- R/ efectivamente, este query NO RETORNA FILAS, o sea, no tenemos inconsistencias en las notas para periodo, id_estudiante, cod_asig

-- RENOMBRAMOS estudianteasignatura a estudianteasignatura_old2
ALTER TABLE `UAOPiloto`.`EstudianteAsignatura` 
RENAME TO  `UAOPiloto`.`EstudianteAsignatura_old2` ;

-- creamos la nueva estudiante asignatura con un distinct
create table estudianteasignatura
select distinct periodo, id_estudiante, cod_dep, cod_asig, creditos, definitiva, definitiva_alf, cancelada_vol, cancelada_UAO, perdida_inasistencia, perdida, ganada
from estudianteasignatura_old2;

-- comparemos resultados
select count(*) 
from estudianteasignatura_old2;
-- R/7288

select count(*) 
from estudianteasignatura;
-- 5607.

-- confirmemos que no tengamos duplicados en estudiante asignatura al mirar periodo, id_estudiante, cod_asig.
select periodo, id_estudiante, cod_asig, count(*)
from EstudianteAsignatura
group by periodo, id_estudiante, cod_asig
having count(*) > 1;
-- R/ no hay duplicados en periodo, id_estudiante, cod_asig

-- creamos ahora EA_grupo.  no parece tener información interesante, excepto qué grupos tuvo una asignatura
create table ea_grupo as
select distinct periodo, id_estudiante, cod_asig, grupo
from estudianteasignatura_old2;
--  R/6324 filas creadas.

-- y ahora creamos EA_docentes
create table ea_docentes as
select distinct periodo, id_estudiante, cod_asig, grupo, cedula
from estudianteasignatura_old2;
-- R/ 7288 filas creadas, que corresponde con lo esperado al contar filas en estudianteasignatura_old2.

select count(*)
from estudianteasignatura_old2;

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
-- R/ 588 notas cambiadas

update estudianteasignatura
set nivel_nota = 1
where definitiva < 3;
-- R/ 129 notas cambiadas

update estudianteasignatura
set nivel_nota = 2
where definitiva >= 3.0
and   definitiva < 3.8;
-- R/ 1103 notas cambiadas

update estudianteasignatura
set nivel_nota = 3
where definitiva >= 3.8;

commit;


-- Al comparar lo que se quiere hacer con lo que hay en definitiva_alf se observa que esta ultima solo detecta el nulo según si fue nula, A, P, y R (preguntar qué es eso).
-- y si sí hay nota, detecta solo si es menor a 3 o mayor a 3.
-- NIVEL_NOTA nos permitirá entender mejor si sacó una muy buena nota, regular o malita, o no tuvo nota.
select distinct definitiva, definitiva_alf
from estudianteasignatura
order by definitiva, definitiva_alf;


 SELECT  id_estudiante, IFNULL(icfes_antiguo,-100) icfes_antiguo, IFNULL(biologia,-100) biologia, IFNULL(matematica,-100) matematica, 
			IFNULL(filosofia,-100) filosofia, 
            IFNULL(fisica,-100) fisica, IFNULL(historia,-100) historia, IFNULL(quimica,-100) quimica, IFNULL(lenguaje,-100) lenguaje, 
            IFNULL(geografia,-100) geografia, IFNULL(idioma,-100) idioma, IFNULL(interdisciplinar,-100) interdisciplinar
 FROM icfes;
 
 -- CURSOS EXTRACURRICULARES (EstudiantesActividadeS=
 -- esa tabla usa es la identificación del estudiante y no su codigo, parece.
 -- Antes de iniciar, creé la tabla actividades con el nobmre de la actividad y su tipo: deporte, cultura, ...

select * from actividades;

select * 
from EstudiantesActividades;
-- R/ 2684 filas unicamente.alter



    
    



 
    


























