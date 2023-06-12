/* 
Primer empezamos creando la base de datos y luego creamos una tabla a la cual vamos a importar la tabla que da el gobierno 
sobre los datos de dengue
*/
SET SQL_SAFE_UPDATES = 0;


create database dengue;

use dengue;

create table dengue(
	Fecha_Actualizacion date,
    ID_Registro int,
    Sexo int,
    Edad int,
    Entidad int,
    Municipio int,
    Habla_Lengua_Indigena int,
    Indigena int, 
    Entidad_Notif int,
    Municipio_Notif int,
    Institucion_Notif int,
    Fecha_sintomas date,
    Tipo_Paciente int,
    Hemorragicos int,
    Diabetes int,
    Hipertension int,
    ENFERMEDAD_ULC_PEPTICA int,
    ENFERMEDAD_RENAL int,
    INMUNOSUPR int,
    CIRROSIS_HEPATICA int,
    EMBARAZO int,
    DEFUNCION int,
    DICTAMEN int,
    TOMA_MUESTRA int,
    RESULTADO_PCR int,
    ESTATUS_CASO int,
    ENTIDAD_ASIG int,
    MUNICIPIO_ASIG int
);

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dengue_abierto.csv'
into table dengue
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows; 


/* Una vez hecho esto, hacemos más tablas para complementar y alimentar nuestra base de datos*/
/*Comenzamos creando la table que contiene a los estados o entidades para luego agregar más información*/

create table entidades (
	Clave_Entidad int,
    Nombre_Entidad VARCHAR(32),
    Abreviatura VARCHAR(5),
    Poblacion int
);

/*Cargamos la información del catalogo de entidades (que ya da el gobierno),
en el cual viene la relación de la clave (de tabla dengue) 
junto con el nombre de la entidad y su  abreviatura */

load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Catalogo_entidades.csv'
into table entidades
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows; 

/*Ahora agregamos información a la tabla de entidades, primero el numero de casos por clasificacion de Resultado CPR */

/* agregamos numero de datos por entidad para saber cuantos datos tenemos por entidad */
/*agregamos la columna*/

alter table entidades
add Numero_De_Datos int; 

create table temp as
SELECT COUNT(sexo) as datos, entidad
FROM dengue
GROUP BY entidad
order by entidad;

/*agregamos los datos*/
UPDATE entidades, temp
SET entidades.Numero_De_Datos = temp.datos
where entidades.Clave_Entidad=temp.entidad;

 drop table temp;
 
 /* ahora agregamos una columna que cuenta el numero de datos que entran en la categoria problable*/
create table temp as
SELECT COUNT(sexo) as probable, entidad
FROM dengue
where ESTATUS_CASO=1
GROUP BY entidad
order by entidad;

alter table entidades
add probable int;

UPDATE entidades, temp
SET entidades.probable = temp.probable
where entidades.Clave_Entidad=temp.entidad;


drop table temp;

  /* ahora agregamos una columna que cuenta el numero de datos que entran en la categoria confirmado*/
create table temp as
SELECT COUNT(sexo) as confirmado, entidad
FROM dengue
where ESTATUS_CASO=2
GROUP BY entidad
order by entidad;

alter table entidades
add confirmado int;

UPDATE entidades, temp
SET entidades.confirmado = temp.confirmado
where entidades.Clave_Entidad=temp.entidad;

drop table temp;

/* ahora agregamos una columna que cuenta el numero de datos que entran en la categoria descartado*/
create table temp as
SELECT COUNT(sexo) as descartado, entidad
FROM dengue
where ESTATUS_CASO=3
GROUP BY entidad
order by entidad;

alter table entidades
add descartado int;

UPDATE entidades, temp
SET entidades.descartado = temp.descartado
where entidades.Clave_Entidad=temp.entidad;


drop table temp;

/* remplazamos datos nulos con ceros*/

update entidades
set numero_de_datos=0
where numero_de_datos is null;

update entidades
set probable=0
where probable is null;

update entidades
set confirmado=0
where confirmado is null;

update entidades
set descartado=0
where descartado is null;

/*Ahora agregamos dos indicadores, el primero es el % de confirmados con respecto a la poblacion total y el segundo el % 
de confirmados+probables con respectoa  la pob total*/
alter table entidades
add confirmado_cada_diezmil_habitantes float,
add confirmado_y_probable_cada_diezmil_habitantes float;


update entidades
set confirmado_cada_diezmil_habitantes=confirmado/(poblacion/1000000)
where poblacion>0;

update entidades
set confirmado_y_probable_cada_diezmil_habitantes=(confirmado+probable)/(poblacion/1000000)
where poblacion>0;

select * from entidades;


/*Ahora creo una nueva tabla para ver ahora informacion acerca de las diferentes institucion que trataron a pasientes
*/

create table institucion(
	Clave int,
    Nombre varchar(50)
);

/* importamos el catalogo*/
load data infile 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/Catalogos_institucion.csv'
into table institucion
fields terminated by ','
enclosed by '"'
lines terminated by '\n'
ignore 1 rows; 


/*Agregamos el numero de defunciones por institucion*/

alter table institucion
add defunciones int;

create table temp as
SELECT count(sexo) as defunciones, Institucion_Notif
FROM dengue
WHERE DEFUNCION=1
GROUP BY Institucion_Notif
ORDER BY Institucion_Notif;

/*aqui muestro que puedo usar el join*/
create table temp2 as
SELECT institucion.Clave, institucion.Nombre, temp.defunciones
FROM temp
INNER JOIN institucion ON institucion.Clave=Institucion_Notif;


update institucion, temp2
set institucion.defunciones=temp2.defunciones
where institucion.nombre=temp2.nombre;

drop table temp, temp2;

update institucion
set defunciones=0
where defunciones is null;

select * from institucion;

/*Agregamos el numero de personas atendidas por institucion */
alter table institucion
add numero_atendidos int;

create table temp as
SELECT COUNT(sexo) as datos, Institucion_Notif
FROM dengue
GROUP BY Institucion_Notif
order by Institucion_Notif;

UPDATE institucion, temp
SET institucion.numero_atendidos = temp.datos
where institucion.Clave=temp.Institucion_Notif;

drop table temp;

update institucion
set numero_atendidos=0
where numero_atendidos is null;

alter table institucion
add muertos_cada_mil_atendidos float;

update institucion
set muertos_cada_mil_atendidos=defunciones/(numero_atendidos/1000)
where numero_atendidos>0;

/*correcion en nombre de columnas finales, si esto se corre afecta todo lo anterior por eso esta al final*/
alter table entidades
rename column Numero_De_Datos to atendidos;

