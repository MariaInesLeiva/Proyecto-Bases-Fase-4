/*
EDUGT - DML DE DATOS DE PRUEBA

Este script:
1. Borra todos los datos existentes respetando las FK.
2. Reinicia los IDENTITY para que todos tengan los mismos ID.
3. Inserta datos variados para probar la Fase 2 y dejar base
   suficiente para las siguientes fases.
4. Usa IDs fijos con IDENTITY_INSERT para que funcione igual
   aunque las tablas nunca hayan tenido datos.

*/

SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;

  
    DELETE FROM NOTIFICACION;
    DELETE FROM OPERACIONBILLETERA;
    DELETE FROM DETALLELIQUIDACION;
    DELETE FROM LIQUIDACION;
    DELETE FROM AJUSTECOMISION;
    DELETE FROM SOLICITUDREEMBOLSO;
    DELETE FROM CERTIFICADO;
    DELETE FROM INTENTOEVALUACION;
    DELETE FROM AVANCEMODULO;
    DELETE FROM INSCRIPCION;
    DELETE FROM RECURSOLECCION;
    DELETE FROM LECCION;
    DELETE FROM MODULO;
    DELETE FROM CURSOREQUISITO;
    DELETE FROM REVISIONACADEMICA;
    DELETE FROM EQUIPOCURSO;
    DELETE FROM SUSCRIPCIONCATEGORIA;
    DELETE FROM COHORTE;
    DELETE FROM CURSO;
    DELETE FROM PERIODOLIQUIDACION;
    DELETE FROM POLITICAREEMBOLSO;
    DELETE FROM CONFIGURACIONPLATAFORMA;
    DELETE FROM BILLETERA;
    DELETE FROM TRABAJADOR;
    DELETE FROM CATEGORIA;
    DELETE FROM USUARIO;


    DBCC CHECKIDENT ('NOTIFICACION', RESEED, 0);
    DBCC CHECKIDENT ('OPERACIONBILLETERA', RESEED, 0);
    DBCC CHECKIDENT ('DETALLELIQUIDACION', RESEED, 0);
    DBCC CHECKIDENT ('LIQUIDACION', RESEED, 0);
    DBCC CHECKIDENT ('AJUSTECOMISION', RESEED, 0);
    DBCC CHECKIDENT ('SOLICITUDREEMBOLSO', RESEED, 0);
    DBCC CHECKIDENT ('INTENTOEVALUACION', RESEED, 0);
    DBCC CHECKIDENT ('INSCRIPCION', RESEED, 0);
    DBCC CHECKIDENT ('RECURSOLECCION', RESEED, 0);
    DBCC CHECKIDENT ('LECCION', RESEED, 0);
    DBCC CHECKIDENT ('MODULO', RESEED, 0);
    DBCC CHECKIDENT ('REVISIONACADEMICA', RESEED, 0);
    DBCC CHECKIDENT ('COHORTE', RESEED, 0);
    DBCC CHECKIDENT ('CURSO', RESEED, 0);
    DBCC CHECKIDENT ('PERIODOLIQUIDACION', RESEED, 0);
    DBCC CHECKIDENT ('POLITICAREEMBOLSO', RESEED, 0);
    DBCC CHECKIDENT ('BILLETERA', RESEED, 0);
    DBCC CHECKIDENT ('CATEGORIA', RESEED, 0);
    DBCC CHECKIDENT ('USUARIO', RESEED, 0);


SET IDENTITY_INSERT USUARIO ON;

    INSERT INTO USUARIO
        (UsuarioID, Nombre, Apellido, Correo, FechaRegistro, TipoUsuario)
    VALUES
    (1, N'Fernanda', N'Turcios', 'fernanda@edugt.com', '2026-01-10T09:00:00', 'TRABAJADOR'),
    (2, N'Andrea', N'Molina', 'andrea@edugt.com', '2026-01-12T10:00:00', 'TRABAJADOR'),
    (3, N'Carlos', N'Ramirez', 'carlos@edugt.com', '2026-01-15T11:00:00', 'TRABAJADOR'),
    (4, N'Diego', N'Lopez', 'diego.revisor@edugt.com', '2026-01-18T08:30:00', 'TRABAJADOR'),
    (5, N'Sofia', N'Mendez', 'sofia.revisor@edugt.com', '2026-01-20T08:45:00', 'TRABAJADOR'),
    (6, N'Laura', N'Castillo', 'laura.admin@edugt.com', '2026-01-05T08:00:00', 'TRABAJADOR'),
    (7, N'Sara', N'Gomez', 'sara@gmail.com', '2026-02-02T14:10:00', 'ESTUDIANTE'),
    (8, N'Kevin', N'Perez', 'kevin@gmail.com', '2026-02-15T16:20:00', 'ESTUDIANTE'),
    (9, N'Maria', N'Lopez', 'maria@gmail.com', '2026-03-01T10:15:00', 'ESTUDIANTE'),
    (10, N'Jose', N'Hernandez', 'jose@gmail.com', '2026-03-12T12:00:00', 'ESTUDIANTE'),
    (11, N'Ana', N'Ruiz', 'ana@gmail.com', '2026-04-05T09:30:00', 'ESTUDIANTE'),
    (12, N'Luis', N'Morales', 'luis@gmail.com', '2026-04-18T13:45:00', 'ESTUDIANTE');

    SET IDENTITY_INSERT USUARIO OFF;


    INSERT INTO TRABAJADOR (TrabajadorID, TipoTrabajador, PorcentajeComisionEsp)
    VALUES
    (1, 'INSTRUCTOR', NULL),
    (2, 'INSTRUCTOR', 18.00),
    (3, 'INSTRUCTOR', NULL),
    (4, 'REVISOR', NULL),
    (5, 'REVISOR', NULL),
    (6, 'ADMINISTRADOR', NULL);


SET IDENTITY_INSERT BILLETERA ON;

    INSERT INTO BILLETERA
        (BilleteraID, UsuarioID, Saldo, FechaActualizacion)
    VALUES
    (1, 1, 1200.00, '2026-09-20T10:00:00'),
    (2, 2, 800.00,  '2026-09-20T10:00:00'),
    (3, 3, 500.00,  '2026-09-20T10:00:00'),
    (4, 7, 450.00,  '2026-09-20T10:00:00'),
    (5, 8, 120.00,  '2026-09-20T10:00:00'),
    (6, 9, 700.00,  '2026-09-20T10:00:00'),
    (7, 10, 50.00,  '2026-09-20T10:00:00'),
    (8, 11, 300.00, '2026-09-20T10:00:00'),
    (9, 12, 900.00, '2026-09-20T10:00:00');

    SET IDENTITY_INSERT BILLETERA OFF;


SET IDENTITY_INSERT CATEGORIA ON;

    INSERT INTO CATEGORIA
        (CategoriaID, NombreCategoria, PorcentajeComisionBase)
    VALUES
    (1, N'Tecnologia', 25.00),
    (2, N'Ofimatica y Datos', 20.00),
    (3, N'Finanzas', 22.00),
    (4, N'Creatividad', 18.00);

    SET IDENTITY_INSERT CATEGORIA OFF;


    INSERT INTO CONFIGURACIONPLATAFORMA
        (ConfiguracionID, PrecioMinimo, PrecioMaximo)
    VALUES
        (1, 50.00, 2000.00);


SET IDENTITY_INSERT POLITICAREEMBOLSO ON;

    INSERT INTO POLITICAREEMBOLSO
        (PoliticaID, DiasLimite, PorcentajeMax, FechaInicioVigencia, FechaFinVigencia)
    VALUES
    (1, 5, 15.00, '2026-01-01', '2026-06-30'),
    (2, 7, 20.00, '2026-07-01', NULL);

    SET IDENTITY_INSERT POLITICAREEMBOLSO OFF;


SET IDENTITY_INSERT PERIODOLIQUIDACION ON;

    INSERT INTO PERIODOLIQUIDACION
        (PeriodoID, Anio, Mes, Estado, FechaFinPeriodo)
    VALUES
    (1, 2026, 7, 'CERRADO', '2026-07-31'),
    (2, 2026, 8, 'CERRADO', '2026-08-31'),
    (3, 2026, 9, 'ABIERTO', '2026-09-30');

    SET IDENTITY_INSERT PERIODOLIQUIDACION OFF;


SET IDENTITY_INSERT CURSO ON;

    INSERT INTO CURSO
    (
        CursoID, CodigoCurso, Descripcion, CategoriaID, Precio,
        ImagenPortada, Estado, FechaCreacion, FechaPublicacion,
        Destacado, RequiereEval, Titulo
    )
    VALUES
    (1, 'EDU-2026-0001', N'Fundamentos de SQL y bases de datos relacionales.', 1, 250.00,
     '/img/sql.jpg', 'DISPONIBLE', '2026-05-20T09:00:00', '2026-06-10T10:00:00',
     1, 1, N'SQL desde Cero'),

    (2, 'EDU-2026-0002', N'Curso práctico de Excel aplicado al análisis de datos.', 2, 300.00,
     '/img/excel.jpg', 'DISPONIBLE', '2026-06-15T09:00:00', '2026-07-05T11:00:00',
     1, 1, N'Excel para Analisis de Datos'),

    (3, 'EDU-2026-0003', N'Desarrollo de servicios web utilizando Node.js y Express.', 1, 400.00,
     '/img/node.jpg', 'PENDIENTE', '2026-09-10T08:00:00', NULL,
     0, 1, N'Desarrollo Web con Node.js'),

    (4, 'EDU-2026-0004', N'Creación de reportes y tableros interactivos con Power BI.', 2, 350.00,
     '/img/powerbi.jpg', 'RECHAZADO', '2026-08-20T14:00:00', NULL,
     0, 0, N'Power BI Intermedio'),

    (5, 'EDU-2026-0005', N'Administración del dinero, ahorro y presupuesto personal.', 3, 180.00,
     '/img/finanzas.jpg', 'ENREVISION', '2026-09-05T10:00:00', NULL,
     0, 0, N'Finanzas Personales'),

    (6, 'EDU-2026-0006', N'Conceptos de composición, exposición y edición fotográfica.', 4, 220.00,
     '/img/fotografia.jpg', 'INACTIVO', '2026-04-15T08:00:00', '2026-05-01T10:00:00',
     0, 0, N'Fotografia Digital'),

    (7, 'EDU-2026-0007', N'Introducción al análisis de datos utilizando Python.', 1, 500.00,
     '/img/python.jpg', 'PENDIENTE', '2026-09-18T12:00:00', NULL,
     0, 1, N'Python para Datos');

    SET IDENTITY_INSERT CURSO OFF;


    INSERT INTO EQUIPOCURSO
        (CursoID, InstructorID, PorcentajeParticipacion, EsPrincipal)
    VALUES
    (1, 1, 80.00, 1),
    (1, 2, 20.00, 0),

    (2, 2, 100.00, 1),

    (3, 1, 80.00, 1),
    (3, 3, 20.00, 0),

    (4, 3, 100.00, 1),

    (5, 2, 70.00, 1),
    (5, 3, 30.00, 0),

    (6, 1, 100.00, 1),

    (7, 3, 70.00, 1);

 
    INSERT INTO CURSOREQUISITO (CursoID, CursoRequisitoID)
    VALUES
    (3, 1),
    (4, 2);


SET IDENTITY_INSERT MODULO ON;

    INSERT INTO MODULO (ModuloID, CursoID, NombreModulo, NoOrden)
    VALUES
    (1, 1, N'Fundamentos de bases de datos', 1),
    (2, 1, N'Consultas SQL', 2),
    (3, 1, N'Joins y agrupaciones', 3),

    (4, 2, N'Introduccion a Excel', 1),
    (5, 2, N'Funciones para analisis', 2),
    (6, 2, N'Tablas dinamicas', 3),

    (7, 3, N'Fundamentos de Node.js', 1),
    (8, 3, N'Express y rutas', 2),
    (9, 3, N'Conexion con base de datos', 3),

    (10, 4, N'Introduccion a Power BI', 1),
    (11, 4, N'Modelado de datos', 2),
    (12, 4, N'Dashboards', 3),

    (13, 5, N'Presupuesto personal', 1),
    (14, 5, N'Ahorro y metas', 2),
    (15, 5, N'Manejo de deudas', 3),

    (16, 6, N'Fundamentos de fotografia', 1),
    (17, 6, N'Composicion', 2),
    (18, 6, N'Edicion basica', 3),

    (19, 7, N'Introduccion a Python', 1),
    (20, 7, N'Estructuras de datos', 2);

    SET IDENTITY_INSERT MODULO OFF;


SET IDENTITY_INSERT LECCION ON;

    INSERT INTO LECCION
        (LeccionID, ModuloID, NombreLeccion, Contenido, NoOrden, DuracionMinutos)
    VALUES
    (1, 1, N'Que es una base de datos', N'Conceptos de base de datos y modelo relacional.', 1, 25),
    (2, 1, N'Tablas y relaciones', N'Llaves primarias, foraneas y relaciones.', 2, 30),
    (3, 2, N'SELECT basico', N'Consultas SELECT, WHERE y ORDER BY.', 1, 35),
    (4, 2, N'Funciones agregadas', N'COUNT, SUM, AVG, MIN y MAX.', 2, 30),
    (5, 3, N'INNER JOIN', N'Combinacion de informacion entre tablas.', 1, 40),

    (6, 4, N'Interfaz de Excel', N'Elementos principales de una hoja de calculo.', 1, 20),
    (7, 5, N'Funciones logicas', N'IF, AND y OR aplicadas a datos.', 1, 30),
    (8, 5, N'Funciones de busqueda', N'Funciones de busqueda y referencia.', 2, 35),
    (9, 6, N'Crear tabla dinamica', N'Creacion y configuracion de tablas dinamicas.', 1, 40),

    (10, 7, N'Entorno Node.js', N'Instalacion, npm y estructura de un proyecto.', 1, 30),
    (11, 8, N'Crear rutas', N'Rutas GET, POST, PUT y DELETE con Express.', 1, 45),
    (12, 9, N'Conexion SQL Server', N'Conexion desde Node.js utilizando mssql.', 1, 45),

    (13, 10, N'Entorno Power BI', N'Introduccion a la herramienta y sus componentes.', 1, 25),
    (14, 11, N'Relaciones del modelo', N'Creacion de relaciones entre tablas.', 1, 35),
    (15, 12, N'Visualizaciones', N'Creacion de graficas y paneles.', 1, 40),

    (16, 13, N'Ingresos y gastos', N'Clasificacion de ingresos y gastos mensuales.', 1, 25),
    (17, 14, N'Metas de ahorro', N'Definicion de metas y seguimiento.', 1, 25),
    (18, 15, N'Tipos de deuda', N'Conceptos para administrar deudas.', 1, 30),

    (19, 16, N'Exposicion', N'Apertura, velocidad e ISO.', 1, 35),
    (20, 17, N'Regla de tercios', N'Composicion utilizando regla de tercios.', 1, 30),
    (21, 18, N'Ajustes basicos', N'Brillo, contraste y recorte.', 1, 30),

    (22, 19, N'Variables y tipos', N'Variables, numeros, cadenas y booleanos.', 1, 30),
    (23, 20, N'Listas y diccionarios', N'Estructuras de datos basicas en Python.', 1, 35);

    SET IDENTITY_INSERT LECCION OFF;


SET IDENTITY_INSERT RECURSOLECCION ON;

    INSERT INTO RECURSOLECCION
        (RecursoID, LeccionID, NombreRecurso, TipoRecurso, UbicacionRecurso)
    VALUES
    (1, 1, N'Guia modelo relacional', 'PDF', N'/recursos/sql/modelo-relacional.pdf'),
    (2, 3, N'Ejercicios SELECT', 'PDF', N'/recursos/sql/select-ejercicios.pdf'),
    (3, 6, N'Plantilla de practica', 'XLSX', N'/recursos/excel/plantilla.xlsx'),
    (4, 10, N'Codigo inicial Node', 'ZIP', N'/recursos/node/proyecto-inicial.zip'),
    (5, 13, N'Dataset de ventas', 'CSV', N'/recursos/powerbi/ventas.csv'),
    (6, 16, N'Plantilla de presupuesto', 'XLSX', N'/recursos/finanzas/presupuesto.xlsx'),
    (7, 19, N'Guia de exposicion', 'PDF', N'/recursos/foto/exposicion.pdf'),
    (8, 22, N'Ejercicios Python', 'PDF', N'/recursos/python/ejercicios.pdf');

    SET IDENTITY_INSERT RECURSOLECCION OFF;


SET IDENTITY_INSERT REVISIONACADEMICA ON;

    INSERT INTO REVISIONACADEMICA
        (RevisionID, CursoID, RevisorID, NumRevision, FechaInicio, FechaFin, Resultado, Comentario)
    VALUES
    (1, 1, 4, 1, '2026-06-08T09:00:00', '2026-06-10T09:30:00', 'APROBADO',
     N'Contenido claro, completo y bien estructurado.'),

    (2, 2, 5, 1, '2026-07-03T10:00:00', '2026-07-05T10:30:00', 'APROBADO',
     N'Curso aprobado, cumple con la estructura solicitada.'),

    (3, 4, 4, 1, '2026-09-01T08:00:00', '2026-09-02T15:00:00', 'RECHAZADO',
     N'Debe mejorar la explicación del módulo de modelado de datos.');

    SET IDENTITY_INSERT REVISIONACADEMICA OFF;


SET IDENTITY_INSERT COHORTE ON;

    INSERT INTO COHORTE (CohorteID, CursoID, FechaInicio, CupoMax)
    VALUES
    (1, 2, '2026-10-01', 3),
    (2, 1, '2026-10-15', 5),
    (3, 2, '2026-11-01', 8);

    SET IDENTITY_INSERT COHORTE OFF;


    INSERT INTO SUSCRIPCIONCATEGORIA
        (UsuarioID, CategoriaID, FechaSuscripcion)
    VALUES
    (7, 1, '2026-05-01T10:00:00'),
    (7, 2, '2026-05-01T10:05:00'),
    (8, 1, '2026-05-10T11:00:00'),
    (9, 2, '2026-06-01T12:00:00'),
    (9, 3, '2026-06-01T12:05:00'),
    (10, 1, '2026-06-15T09:00:00'),
    (11, 2, '2026-07-01T15:00:00'),
    (12, 1, '2026-07-10T10:00:00'),
    (12, 4, '2026-07-10T10:05:00');


SET IDENTITY_INSERT INSCRIPCION ON;

    INSERT INTO INSCRIPCION
    (
        InscripcionID, UsuarioID, CursoID, CohorteID, PoliticaID, FechaInscripcion,
        PrecioPagado, PorcentajeComiAplicado, Estado,
        FechaCompletado, Liquidada
    )
    VALUES
    (1, 7, 1, NULL, 2, '2026-07-10T10:00:00', 250.00, 25.00, 'COMPLETADA', '2026-07-25T18:00:00', 1),
    (2, 8, 1, NULL, 2, '2026-09-05T11:00:00', 250.00, 25.00, 'ACTIVA', NULL, 0),

    (3, 9, 2, 1, 2, '2026-09-10T09:00:00', 300.00, 20.00, 'ACTIVA', NULL, 0),
    (4, 10, 2, 1, 2, '2026-09-11T10:00:00', 300.00, 20.00, 'ACTIVA', NULL, 0),
    (5, 11, 2, 1, 2, '2026-08-20T12:00:00', 300.00, 20.00, 'REEMBOLSADA', NULL, 1),

    (6, 12, 1, NULL, 2, '2026-08-02T08:30:00', 250.00, 25.00, 'COMPLETADA', '2026-08-18T20:00:00', 0),
    (7, 7, 2, 3, 2, '2026-09-15T14:00:00', 300.00, 20.00, 'ACTIVA', NULL, 0),

    (8, 8, 6, NULL, 1, '2026-05-05T10:00:00', 220.00, 18.00, 'COMPLETADA', '2026-05-22T17:30:00', 1),
    (9, 9, 1, NULL, 2, '2026-08-08T15:00:00', 250.00, 25.00, 'REEMBOLSADA', NULL, 0);

    SET IDENTITY_INSERT INSCRIPCION OFF;


    INSERT INTO AVANCEMODULO
        (InscripcionID, ModuloID, FechaCompletado)
    VALUES
    (1, 1, '2026-07-15T12:00:00'),
    (1, 2, '2026-07-20T12:00:00'),
    (1, 3, '2026-07-25T17:30:00'),

    (2, 1, '2026-09-08T14:00:00'),

    (3, 4, '2026-09-14T16:00:00'),

    (6, 1, '2026-08-10T11:00:00'),
    (6, 2, '2026-08-14T11:00:00'),
    (6, 3, '2026-08-18T19:30:00'),

    (8, 16, '2026-05-10T10:00:00'),
    (8, 17, '2026-05-16T10:00:00'),
    (8, 18, '2026-05-22T17:00:00'),

    (9, 1, '2026-08-10T09:00:00');


SET IDENTITY_INSERT INTENTOEVALUACION ON;

    INSERT INTO INTENTOEVALUACION
        (IntentoID, InscripcionID, NumeroIntento, Nota, FechaIntento)
    VALUES
    (1, 1, 1, 65.00, '2026-07-24T16:00:00'),
    (2, 1, 2, 85.00, '2026-07-25T17:00:00'),
    (3, 6, 1, 92.00, '2026-08-18T19:45:00');

    SET IDENTITY_INSERT INTENTOEVALUACION OFF;

 
    INSERT INTO CERTIFICADO
        (Anio, Correlativo, InscripcionID, CodigoCertificado,
         FechaEmision, Estado, MotivoRevision)
    VALUES
    (2026, 1, 1, 'CERT-2026-0001', '2026-07-25T18:05:00', 'VALIDO', NULL),
    (2026, 2, 6, 'CERT-2026-0002', '2026-08-18T20:05:00', 'PENDIENTE_VERIFICACION',
     N'El curso fue completado en un tiempo menor al esperado.'),
    (2026, 3, 8, 'CERT-2026-0003', '2026-05-22T17:35:00', 'VALIDO', NULL);


SET IDENTITY_INSERT SOLICITUDREEMBOLSO ON;

    INSERT INTO SOLICITUDREEMBOLSO
    (
        ReembolsoID, InscripcionID, FechaSolicitud, FechaDecision, Motivo,
        PorcentajeAvance, MontoReembolsado, PersonaQueAutoriza, Estado
    )
    VALUES
    (1, 5, '2026-09-02T09:00:00', '2026-09-02T11:00:00',
     N'El curso no era lo que esperaba.', 0.00, 300.00, 6, 'EJECUTADO'),

    (2, 2, '2026-09-12T10:00:00', '2026-09-12T12:00:00',
     N'Deseo solicitar devolución del curso.', 33.33, NULL, 6, 'RECHAZADO');

    SET IDENTITY_INSERT SOLICITUDREEMBOLSO OFF;


SET IDENTITY_INSERT AJUSTECOMISION ON;

    INSERT INTO AJUSTECOMISION
        (AjusteID, ReembolsoID, InstructorID, MontoOriginal, MontoPendiente, FechaGeneracion)
    VALUES
        (1, 1, 2, 240.00, 240.00, '2026-09-02T11:05:00');

    SET IDENTITY_INSERT AJUSTECOMISION OFF;


SET IDENTITY_INSERT LIQUIDACION ON;

    INSERT INTO LIQUIDACION
        (LiquidacionID, PeriodoID, InstructorID, FechaLiquidacion, Estado)
    VALUES
    (1, 1, 1, '2026-08-01T08:00:00', 'PAGADA'),
    (2, 1, 2, '2026-08-01T08:05:00', 'PAGADA'),
    (3, 2, 2, '2026-09-01T08:00:00', 'PAGADA');

    SET IDENTITY_INSERT LIQUIDACION OFF;


SET IDENTITY_INSERT DETALLELIQUIDACION ON;

    INSERT INTO DETALLELIQUIDACION
        (DetalleLiquidacionID, LiquidacionID, TipoDetalle, InscripcionID, AjusteID,
         PorcentajeParticipacion, Monto)
    VALUES
    (1, 1, 'COMISION', 1, NULL, 80.00, 150.00),
    (2, 2, 'COMISION', 1, NULL, 20.00, 37.50),
    (3, 3, 'COMISION', 5, NULL, 100.00, 240.00);

    SET IDENTITY_INSERT DETALLELIQUIDACION OFF;


SET IDENTITY_INSERT OPERACIONBILLETERA ON;

    INSERT INTO OPERACIONBILLETERA
    (
        OperacionID, BilleteraID, TipoOperacion, Monto, FechaOperacion,
        InscripcionID, ReembolsoID, LiquidacionID, Descripcion
    )
    VALUES
    (1, 4, 'RECARGA', 700.00, '2026-07-09T18:00:00',
     NULL, NULL, NULL, N'Recarga de saldo'),

    (2, 4, 'COBRO_INSCRIPCION', 250.00, '2026-07-10T10:00:00',
     1, NULL, NULL, N'Pago de inscripción a SQL desde Cero'),

    (3, 6, 'RECARGA', 1000.00, '2026-09-09T18:00:00',
     NULL, NULL, NULL, N'Recarga de saldo'),

    (4, 6, 'COBRO_INSCRIPCION', 300.00, '2026-09-10T09:00:00',
     3, NULL, NULL, N'Pago de inscripción a Excel para Analisis de Datos'),

    (5, 8, 'REEMBOLSO', 300.00, '2026-09-02T11:00:00',
     NULL, 1, NULL, N'Reembolso de inscripción'),

    (6, 1, 'PAGO_COMISION', 150.00, '2026-08-01T08:10:00',
     NULL, NULL, 1, N'Pago de comisión del periodo julio'),

    (7, 2, 'PAGO_COMISION', 37.50, '2026-08-01T08:15:00',
     NULL, NULL, 2, N'Pago de comisión del periodo julio'),

    (8, 2, 'PAGO_COMISION', 240.00, '2026-09-01T08:10:00',
     NULL, NULL, 3, N'Pago de comisión del periodo agosto');

    SET IDENTITY_INSERT OPERACIONBILLETERA OFF;


SET IDENTITY_INSERT NOTIFICACION ON;

    INSERT INTO NOTIFICACION
        (NotificacionID, UsuarioID, CursoID, Tipo, Asunto, Mensaje, FechaCreacion, Estado)
    VALUES
    (1, 1, 1, 'CURSO_PUBLICADO', N'Curso publicado',
     N'Tu curso SQL desde Cero fue aprobado y ya está disponible.', '2026-06-10T10:05:00', 'ENVIADA'),

    (2, 2, 2, 'CURSO_PUBLICADO', N'Curso publicado',
     N'Tu curso Excel para Analisis de Datos fue aprobado y ya está disponible.', '2026-07-05T11:05:00', 'ENVIADA'),

    (3, 3, 4, 'CURSO_RECHAZADO', N'Curso rechazado',
     N'Tu curso Power BI Intermedio requiere correcciones.', '2026-09-02T15:05:00', 'ENVIADA'),

    (4, 7, 2, 'NUEVO_CURSO_CATEGORIA', N'Nuevo curso disponible',
     N'Hay un nuevo curso disponible en una categoría que sigues.', '2026-07-05T11:10:00', 'ENVIADA'),

    (5, 9, 2, 'NUEVO_CURSO_CATEGORIA', N'Nuevo curso disponible',
     N'Hay un nuevo curso disponible en Ofimatica y Datos.', '2026-07-05T11:10:00', 'ENVIADA'),

    (6, 1, 3, 'CURSO_RECIBIDO', N'Curso recibido',
     N'Recibimos tu curso Desarrollo Web con Node.js.', '2026-09-10T08:05:00', 'ENVIADA'),

    (7, 3, 7, 'CURSO_RECIBIDO', N'Curso recibido',
     N'Recibimos tu curso Python para Datos.', '2026-09-18T12:05:00', 'PENDIENTE'),

    (8, 11, 2, 'REEMBOLSO', N'Reembolso procesado',
     N'Tu reembolso fue procesado correctamente.', '2026-09-02T11:10:00', 'ENVIADA');

    SET IDENTITY_INSERT NOTIFICACION OFF;

    COMMIT TRANSACTION;

    PRINT 'Datos de prueba cargados correctamente.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO

