USE EDUGT;
GO

-- Datos de prueba de la Fase 4
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM USUARIO WHERE UsuarioID = 18)
       OR NOT EXISTS (SELECT 1 FROM CURSO WHERE CursoID = 10)
       OR NOT EXISTS (SELECT 1 FROM INSCRIPCION WHERE InscripcionID = 18)
        THROW 52010, 'Ejecute primero el DML base y el DML de Fase III.', 1;

    IF EXISTS (SELECT 1 FROM USUARIO WHERE UsuarioID IN (19,20,21,22,23))
       OR EXISTS (SELECT 1 FROM CURSO WHERE CursoID = 11)
       OR EXISTS (SELECT 1 FROM INSCRIPCION WHERE InscripcionID BETWEEN 24 AND 31)
       OR EXISTS (SELECT 1 FROM BILLETERA WHERE BilleteraID BETWEEN 16 AND 20)
       OR EXISTS (SELECT 1 FROM COHORTE WHERE CohorteID = 6)
       OR EXISTS (SELECT 1 FROM PERIODOLIQUIDACION WHERE PeriodoID BETWEEN 4 AND 6)
       OR EXISTS (SELECT 1 FROM LIQUIDACION WHERE LiquidacionID IN (4,5))
       OR EXISTS (SELECT 1 FROM CERTIFICADO WHERE Anio = 2026 AND Correlativo = 5)
        THROW 52011, 'Existen IDs reservados para Fase IV; revise antes de continuar.', 1;

    SET IDENTITY_INSERT USUARIO ON;
    INSERT INTO USUARIO (UsuarioID,Nombre,Apellido,Correo,FechaRegistro,TipoUsuario)
    VALUES
    (19,N'Lucia',N'Mendez','lucia.f4@ejemplo.com','2026-10-01T09:00:00','ESTUDIANTE'),
    (20,N'Pablo',N'Ramos','pablo.f4@ejemplo.com','2026-10-01T09:00:00','ESTUDIANTE'),
    (21,N'Clara',N'Mora','clara.f4@ejemplo.com','2026-10-01T09:00:00','ESTUDIANTE'),
    (22,N'Tomas',N'Vega','tomas.f4@ejemplo.com','2026-10-01T09:00:00','ESTUDIANTE'),
    (23,N'Elisa',N'Paz','elisa.f4@ejemplo.com','2026-10-01T09:00:00','ESTUDIANTE');
    SET IDENTITY_INSERT USUARIO OFF;

    SET IDENTITY_INSERT BILLETERA ON;
    INSERT INTO BILLETERA (BilleteraID,UsuarioID,Saldo,FechaActualizacion)
    VALUES (16,19,500,'2026-10-20T08:00:00'),
           (17,20,500,'2026-10-20T08:00:00'),
           (18,21,500,'2026-10-20T08:00:00'),
           (24,22,500,'2026-10-20T08:00:00'),
           (25,23,500,'2026-10-20T08:00:00');
    SET IDENTITY_INSERT BILLETERA OFF;

    SET IDENTITY_INSERT CURSO ON;
    INSERT INTO CURSO
      (CursoID,CodigoCurso,Descripcion,CategoriaID,Precio,ImagenPortada,
       Estado,FechaCreacion,FechaPublicacion,Destacado,RequiereEval,Titulo)
    VALUES
      (11,'EDU-2026-0011',N'Curso de prueba para repartos de comision.',1,199.99,
       '/img/reparto-f4.jpg','DISPONIBLE','2026-10-01T09:00:00',
       '2026-10-02T09:00:00',0,0,N'Reparto y redondeo Fase IV');
    SET IDENTITY_INSERT CURSO OFF;

    INSERT INTO EQUIPOCURSO (CursoID,InstructorID,PorcentajeParticipacion,EsPrincipal)
    VALUES (11,1,33.33,1),(11,2,33.33,0),(11,3,33.34,0);

    SET IDENTITY_INSERT MODULO ON;
    INSERT INTO MODULO (ModuloID,CursoID,NombreModulo,NoOrden)
    VALUES (30,11,N'Introduccion al reparto',1),
           (31,11,N'Calculo de comisiones',2),
           (32,11,N'Conciliacion',3);
    SET IDENTITY_INSERT MODULO OFF;

    SET IDENTITY_INSERT LECCION ON;
    INSERT INTO LECCION (LeccionID,ModuloID,NombreLeccion,Contenido,NoOrden,DuracionMinutos)
    VALUES (33,30,N'Participaciones',N'Introduccion a porcentajes.',1,30),
           (34,31,N'Calculo',N'Calculo de importes.',1,30),
           (35,32,N'Redondeo',N'Conciliacion de centavos.',1,30);
    SET IDENTITY_INSERT LECCION OFF;

    SET IDENTITY_INSERT COHORTE ON;
    INSERT INTO COHORTE (CohorteID,CursoID,FechaInicio,CupoMax)
    VALUES (6,11,'2026-10-25',1);
    SET IDENTITY_INSERT COHORTE OFF;

    SET IDENTITY_INSERT INSCRIPCION ON;
    INSERT INTO INSCRIPCION
      (InscripcionID,UsuarioID,CursoID,CohorteID,PoliticaID,FechaInscripcion,
       PrecioPagado,PorcentajeComiAplicado,Estado,FechaCompletado,Liquidada)
    VALUES
      (24,19,11,6,2,'2026-10-20T09:00:00',199.99,25.00,'ACTIVA',NULL,0),
      (25,20,11,NULL,2,'2026-10-01T09:00:00',199.99,25.00,'ACTIVA',NULL,0),
      (26,21,11,NULL,2,'2026-10-20T09:00:00',199.99,25.00,'ACTIVA',NULL,0),
      (27,22,11,NULL,2,'2026-10-20T09:00:00',199.99,25.00,'COMPLETADA','2026-10-20T18:00:00',0),
      (28,23,11,NULL,2,'2026-10-20T09:00:00',199.99,25.00,'ACTIVA',NULL,0),
      (29,19,9,NULL,2,'2026-10-10T09:00:00',200.00,25.00,'COMPLETADA','2026-10-15T09:00:00',0),
      (30,20,9,NULL,2,'2026-10-18T09:00:00',200.00,25.00,'COMPLETADA','2026-10-19T09:00:00',1),
      (31,23,1,NULL,2,'2026-10-19T09:00:00',250.00,25.00,'ACTIVA',NULL,1);
    SET IDENTITY_INSERT INSCRIPCION OFF;

    INSERT INTO AVANCEMODULO (InscripcionID,ModuloID,FechaCompletado)
    VALUES (26,30,'2026-10-20T10:00:00'),
           (27,30,'2026-10-20T11:00:00'),
           (27,31,'2026-10-20T12:00:00'),
           (27,32,'2026-10-20T18:00:00'),
           (29,24,'2026-10-11T09:00:00'),
           (29,25,'2026-10-13T09:00:00'),
           (29,26,'2026-10-15T09:00:00'),
           (30,24,'2026-10-18T12:00:00'),
           (30,25,'2026-10-18T14:00:00'),
           (30,26,'2026-10-19T09:00:00');

    INSERT INTO CERTIFICADO
      (Anio,Correlativo,InscripcionID,CodigoCertificado,FechaEmision,Estado,MotivoRevision)
    VALUES (2026,5,27,'CERT-2026-0005','2026-10-20T18:05:00','VALIDO',NULL);

    SET IDENTITY_INSERT PERIODOLIQUIDACION ON;
    INSERT INTO PERIODOLIQUIDACION (PeriodoID,Anio,Mes,Estado,FechaFinPeriodo)
    VALUES (4,2026,10,'CERRADO','2026-10-31'),
           (5,2026,11,'ABIERTO','2026-11-30'),
           (6,2026,12,'ABIERTO','2026-12-31');
    SET IDENTITY_INSERT PERIODOLIQUIDACION OFF;

    SET IDENTITY_INSERT LIQUIDACION ON;
    INSERT INTO LIQUIDACION (LiquidacionID,PeriodoID,InstructorID,FechaLiquidacion,Estado)
    VALUES (4,4,1,'2026-11-01T08:00:00','PAGADA'),
           (5,4,2,'2026-11-01T08:00:00','PAGADA');
    SET IDENTITY_INSERT LIQUIDACION OFF;

    SET IDENTITY_INSERT DETALLELIQUIDACION ON;
    INSERT INTO DETALLELIQUIDACION
      (DetalleLiquidacionID,LiquidacionID,TipoDetalle,InscripcionID,AjusteID,PorcentajeParticipacion,Monto)
    VALUES (4,4,'COMISION',30,NULL,100.00,150.00),
           (5,4,'COMISION',31,NULL,80.00,150.00),
           (6,5,'COMISION',31,NULL,20.00,37.50);
    SET IDENTITY_INSERT DETALLELIQUIDACION OFF;

    COMMIT TRANSACTION;
    PRINT 'Datos adicionales de Fase IV cargados correctamente.';
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

-- Verificación no destructiva
SELECT * FROM CURSO WHERE CursoID = 11;
SELECT * FROM INSCRIPCION WHERE InscripcionID BETWEEN 24 AND 31;
SELECT * FROM COHORTE WHERE CohorteID = 6;