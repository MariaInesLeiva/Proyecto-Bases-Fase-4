/*
EDUGT - DATOS DE PRUEBA ESPECIFICOS PARA FASE 3
Inscripcion, progreso, evaluacion y certificados

1. Primero ejecutar el DDL entregado en Fase 2.
2. Luego ejecutar 03_EduGT_Datos_Prueba.sql de Fase 2.
3. Despues ejecutar ESTE archivo.
*/

SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;


    IF NOT EXISTS (SELECT 1 FROM USUARIO WHERE UsuarioID = 12)
       OR NOT EXISTS (SELECT 1 FROM CURSO WHERE CursoID = 7)
       OR NOT EXISTS (SELECT 1 FROM INSCRIPCION WHERE InscripcionID = 9)
    BEGIN
        THROW 52000, 'Primero debe ejecutar el DML base entregado en Fase 2.', 1;
    END;

    IF EXISTS (SELECT 1 FROM CURSO WHERE CursoID IN (8, 9, 10))
       OR EXISTS (SELECT 1 FROM USUARIO WHERE UsuarioID BETWEEN 13 AND 18)
    BEGIN
        THROW 52001, 'Los datos de Fase 3 ya existen. Reejecute primero el DML base de Fase 2 para reiniciar.', 1;
    END;


    SET IDENTITY_INSERT USUARIO ON;

    INSERT INTO USUARIO
        (UsuarioID, Nombre, Apellido, Correo, FechaRegistro, TipoUsuario)
    VALUES
    (13, N'Paula', N'Vasquez', 'paula@gmail.com', '2026-09-01T09:00:00', 'ESTUDIANTE'),
    (14, N'Mario', N'Juarez', 'mario@gmail.com', '2026-09-02T09:00:00', 'ESTUDIANTE'),
    (15, N'Elena', N'Flores', 'elena@gmail.com', '2026-09-03T09:00:00', 'ESTUDIANTE'),
    (16, N'Gabriela', N'Ortiz', 'gabriela@gmail.com', '2026-09-04T09:00:00', 'ESTUDIANTE'),
    (17, N'Ricardo', N'Soto', 'ricardo@gmail.com', '2026-09-05T09:00:00', 'ESTUDIANTE'),
    (18, N'Valeria', N'Campos', 'valeria@gmail.com', '2026-09-06T09:00:00', 'ESTUDIANTE');

    SET IDENTITY_INSERT USUARIO OFF;


    SET IDENTITY_INSERT BILLETERA ON;

    INSERT INTO BILLETERA
        (BilleteraID, UsuarioID, Saldo, FechaActualizacion)
    VALUES
    (10, 13, 750.00, '2026-10-01T08:00:00'),
    (11, 14, 1000.00, '2026-10-01T08:00:00'),
    (12, 15, 30.00, '2026-10-01T08:00:00'),
    (13, 16, 350.00, '2026-10-01T08:00:00'),
    (14, 17, 1000.00, '2026-10-01T08:00:00'),
    (15, 18, 1000.00, '2026-10-01T08:00:00');

    SET IDENTITY_INSERT BILLETERA OFF;


    SET IDENTITY_INSERT CURSO ON;

    INSERT INTO CURSO
    (
        CursoID, CodigoCurso, Descripcion, CategoriaID, Precio,
        ImagenPortada, Estado, FechaCreacion, FechaPublicacion,
        Destacado, RequiereEval, Titulo
    )
    VALUES
    (8, 'EDU-2026-0008',
     N'Integracion de aplicaciones Node.js con SQL Server y consultas parametrizadas.',
     1, 300.00, '/img/node-sql.jpg', 'DISPONIBLE',
     '2026-09-10T09:00:00', '2026-09-15T10:00:00',
     0, 1, N'Node.js con SQL Server'),

    (9, 'EDU-2026-0009',
     N'Control de versiones con Git y trabajo colaborativo con repositorios.',
     1, 200.00, '/img/git.jpg', 'DISPONIBLE',
     '2026-09-12T09:00:00', '2026-09-18T10:00:00',
     0, 0, N'Git y GitHub desde Cero'),

    (10, 'EDU-2026-0010',
     N'Fundamentos de seguridad para aplicaciones web y buenas practicas.',
     1, 250.00, '/img/seguridad-web.jpg', 'DISPONIBLE',
     '2026-09-14T09:00:00', '2026-09-20T10:00:00',
     0, 1, N'Seguridad Web');

    SET IDENTITY_INSERT CURSO OFF;


    -- ============================================================
    -- 4. EQUIPOS DE CURSO
    -- ============================================================

    INSERT INTO EQUIPOCURSO
        (CursoID, InstructorID, PorcentajeParticipacion, EsPrincipal)
    VALUES
    (8, 2, 100.00, 1),
    (9, 1, 100.00, 1),
    (10, 3, 100.00, 1);


    -- ============================================================
    -- 5. REQUISITO DEL CURSO 8
    -- ============================================================

    INSERT INTO CURSOREQUISITO (CursoID, CursoRequisitoID)
    VALUES (8, 1);


    SET IDENTITY_INSERT MODULO ON;

    INSERT INTO MODULO (ModuloID, CursoID, NombreModulo, NoOrden)
    VALUES
    (21, 8, N'Conexion de Node.js con SQL Server', 1),
    (22, 8, N'Consultas y parametros', 2),
    (23, 8, N'API y persistencia', 3),

    (24, 9, N'Fundamentos de Git', 1),
    (25, 9, N'Ramas y cambios', 2),
    (26, 9, N'Trabajo colaborativo', 3),

    (27, 10, N'Principios de seguridad web', 1),
    (28, 10, N'Autenticacion y autorizacion', 2),
    (29, 10, N'Proteccion de datos', 3);

    SET IDENTITY_INSERT MODULO OFF;

    SET IDENTITY_INSERT LECCION ON;

    INSERT INTO LECCION
        (LeccionID, ModuloID, NombreLeccion, Contenido, NoOrden, DuracionMinutos)
    VALUES
    (24, 21, N'Configuracion de mssql',
     N'Conexion de Node.js con SQL Server utilizando una configuracion segura.', 1, 40),

    (25, 22, N'Consultas parametrizadas',
     N'Uso de parametros para ejecutar consultas y evitar concatenacion insegura.', 1, 45),

    (26, 23, N'Persistencia desde una API',
     N'Lectura y escritura de datos desde servicios REST.', 1, 50),

    (27, 24, N'Repositorios y commits',
     N'Conceptos basicos de repositorios, commits y seguimiento de cambios.', 1, 30),

    (28, 25, N'Ramas',
     N'Creacion, cambio y combinacion de ramas de trabajo.', 1, 35),

    (29, 26, N'Pull requests',
     N'Flujo de colaboracion y revision de cambios.', 1, 40),

    (30, 27, N'Riesgos comunes',
     N'Principales riesgos en aplicaciones web y formas de mitigarlos.', 1, 50),

    (31, 28, N'Control de acceso',
     N'Autenticacion, autorizacion y manejo de sesiones.', 1, 50),

    (32, 29, N'Proteccion de informacion',
     N'Buenas practicas para proteger datos sensibles en una aplicacion.', 1, 60);

    SET IDENTITY_INSERT LECCION OFF;


    SET IDENTITY_INSERT COHORTE ON;

    INSERT INTO COHORTE (CohorteID, CursoID, FechaInicio, CupoMax)
    VALUES
    (4, 9, '2026-10-20', 1),
    (5, 9, '2026-10-25', 1);

    SET IDENTITY_INSERT COHORTE OFF;

    SET IDENTITY_INSERT INSCRIPCION ON;

    INSERT INTO INSCRIPCION
    (
        InscripcionID, UsuarioID, CursoID, CohorteID, PoliticaID,
        FechaInscripcion, PrecioPagado, PorcentajeComiAplicado,
        Estado, FechaCompletado, Liquidada
    )
    VALUES
    (10, 8, 9, 5, 2,
     '2026-10-01T09:00:00', 200.00, 25.00,
     'ACTIVA', NULL, 0),

    (11, 12, 8, NULL, 2,
     '2026-09-20T09:00:00', 300.00, 18.00,
     'ACTIVA', NULL, 0),

    (12, 10, 10, NULL, 2,
     '2026-09-20T09:00:00', 250.00, 25.00,
     'ACTIVA', NULL, 0),

    (13, 11, 9, NULL, 2,
     '2026-09-20T09:00:00', 200.00, 25.00,
     'ACTIVA', NULL, 0),

    (14, 9, 10, NULL, 2,
     '2026-09-20T09:00:00', 250.00, 25.00,
     'ACTIVA', NULL, 0),

    (15, 7, 10, NULL, 2,
     '2026-09-20T09:00:00', 250.00, 25.00,
     'ACTIVA', NULL, 0),

    (16, 12, 10, NULL, 2,
     '2026-09-20T09:00:00', 250.00, 25.00,
     'ACTIVA', NULL, 0),

    (17, 10, 9, NULL, 2,
     '2026-10-01T10:00:00', 200.00, 25.00,
     'ACTIVA', NULL, 0),

    (18, 13, 1, NULL, 2,
     '2026-08-15T09:00:00', 250.00, 25.00,
     'COMPLETADA', '2026-08-20T18:00:00', 0);

    SET IDENTITY_INSERT INSCRIPCION OFF;

    INSERT INTO AVANCEMODULO
        (InscripcionID, ModuloID, FechaCompletado)
    VALUES
    
    (11, 21, '2026-09-23T18:00:00'),
    (11, 22, '2026-09-25T18:00:00'),
    (11, 23, '2026-09-27T18:00:00'),

    (12, 27, '2026-09-23T18:00:00'),
    (12, 28, '2026-09-25T18:00:00'),
    (12, 29, '2026-09-28T18:00:00'),

    (13, 24, '2026-09-23T18:00:00'),
    (13, 25, '2026-09-25T18:00:00'),
    (13, 26, '2026-09-27T18:00:00'),

    (14, 27, '2026-09-24T18:00:00'),
    (14, 28, '2026-09-27T18:00:00'),
    (14, 29, '2026-10-01T18:00:00'),

    (15, 27, '2026-09-25T18:00:00'),

    (16, 27, '2026-09-23T18:00:00'),
    (16, 28, '2026-09-25T18:00:00'),
    (16, 29, '2026-09-28T18:00:00'),

    (17, 24, '2026-10-01T10:05:00'),
    (17, 25, '2026-10-01T10:10:00'),
    (17, 26, '2026-10-01T10:15:00'),

    (18, 1, '2026-08-17T18:00:00'),
    (18, 2, '2026-08-19T18:00:00'),
    (18, 3, '2026-08-20T17:00:00');

    SET IDENTITY_INSERT INTENTOEVALUACION ON;

    INSERT INTO INTENTOEVALUACION
        (IntentoID, InscripcionID, NumeroIntento, Nota, FechaIntento)
    VALUES

    (4, 11, 1, 85.00, '2026-09-27T18:30:00'),

    (5, 12, 1, 55.00, '2026-09-29T18:00:00'),
    (6, 12, 2, 65.00, '2026-09-30T18:00:00'),

    (7, 16, 1, 60.00, '2026-09-29T18:00:00'),

    (8, 18, 1, 80.00, '2026-08-20T17:30:00');

    SET IDENTITY_INSERT INTENTOEVALUACION OFF;


    INSERT INTO CERTIFICADO
        (Anio, Correlativo, InscripcionID, CodigoCertificado,
         FechaEmision, Estado, MotivoRevision)
    VALUES
    (2026, 4, 18, 'CERT-2026-0004',
     '2026-08-20T18:05:00', 'VALIDO', NULL);


    COMMIT TRANSACTION;

    PRINT 'Datos especificos de Fase 3 cargados correctamente.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    THROW;

END CATCH;
GO


SELECT * FROM USUARIO WHERE UsuarioID BETWEEN 13 AND 18;
SELECT * FROM BILLETERA WHERE UsuarioID BETWEEN 13 AND 18;
SELECT * FROM CURSO WHERE CursoID BETWEEN 8 AND 10;
SELECT * FROM COHORTE WHERE CohorteID IN (4, 5);
SELECT * FROM INSCRIPCION WHERE InscripcionID BETWEEN 10 AND 18;
SELECT * FROM AVANCEMODULO WHERE InscripcionID BETWEEN 10 AND 18;
SELECT * FROM INTENTOEVALUACION WHERE InscripcionID BETWEEN 10 AND 18;
SELECT * FROM CERTIFICADO WHERE InscripcionID = 18;
GO


