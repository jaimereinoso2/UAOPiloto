SET SQL_SAFE_UPDATES = 0;
-- LUEGO DE CARGAR LOS DATOS DESDE LOS ARCHIVOS EXCEL SE DEBE HACER LAS SIGUIENTES MODIFICACIONES EN LA BASE DE DATOS

-- 1. cambiamos la columna CODIGO por ID_ESTUDIANTE
ALTER TABLE `UAOPiloto`.`EstudiantesMatriculas` 
CHANGE COLUMN `CODIGO` `ID_ESTUDIANTE` BIGINT NULL DEFAULT NULL ;

-- 2. creamos la tabla PERIODOS_REGULARES a partir de la informacion en EstudianteAsignatura
select distinct periodo
from estudiantesmatriculas
where periodo like '%4';

select *
from EstudiantesMatriculas
where (periodo like '%4' or periodo like '%2')
and ACTIVO_FIN != 'N';

-- ENCUENTRO MULTITUD DE ERRORES EN LA TABLA estudiante.   PARA NO ATRASAR MAS ESTO VOY A TRATAR DE RE-CONSTRUIRLA ADECUADAMENTE

-- primero busco si hay repetidos en 'estudiante', y si los hay.
select codigo, count(*)
from estudiante
group by codigo
having count(*) > 1;

-- luego trato de ver si son muchos los repetidos y cuantas veces se repite, y son un jurgo.  hay casi una fila por cada periodo!!
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

-- vamos a armar la cosa de a poco.  creo estudiante_limpio (id_estudiante)
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

-- la adicionamos COLEGIO a estudiantes_limpio..  OJO ENCONTRÓ ESTUDIANTES CON MÁS DE UN COLEGIO
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
where codigo in (2130302, 2136170, 2136684, 2157176, 2167191, 2175869, 2185512, 2185526)
and colegio is not null
order by codigo;

-- la adicionamos FECHA_GRADO_COLEGIO a estudiantes_limpio.  ERROR, fechas erroenas.  convierto a VARCHAR
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

-- la adicionamos EXPEDIENTE a estudiantes_limpio.  ERROR:  más de un expediente por estudiante.   se trae solo el primero. lIMIT 1
update estudiantes_limpio el
set el.expediente = 
   (select distinct e.expediente
    from estudiante e
    where e.codigo = el.id_estudiante
    and e.expediente is not null
    limit 1);
commit;
















