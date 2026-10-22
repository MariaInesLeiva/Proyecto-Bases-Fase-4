-- Inscripcion y billetera:

-- Funcion para obtener los cursos pre-requisitos de un curso
CREATE OR ALTER FUNCTION fn_CursoPreRequisito (@CursoID INT, @UsuarioID INT)
RETURNS INT
AS
BEGIN
	IF EXISTS (SELECT 1 
				FROM CURSOREQUISITO CR 
				WHERE (CR.CursoID = @CursoID) AND NOT EXISTS (SELECT 1 
															FROM INSCRIPCION I 
															WHERE (I.UsuarioID = @UsuarioID) AND (I.CursoID = CR.CursoRequisitoID)
																	AND (I.Estado = 'COMPLETADA'))) 
	BEGIN 
		RETURN -1; 
	END;

	RETURN 1;

END;
GO



-- Funcion para obtener la comision indicada de un curso
CREATE OR ALTER FUNCTION fn_Procentaje_Comision (@CursoID INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
	DECLARE @ComisionEspecial DECIMAL(10,2)
	SET @ComisionEspecial = (SELECT PorcentajeComisionEsp
								FROM TRABAJADOR T
									INNER JOIN EQUIPOCURSO EC
										ON T.TrabajadorID = EC.InstructorID
							WHERE (EC.CursoID = @CursoID) AND (EsPrincipal = 1))

	DECLARE @ComisionCategoria DECIMAL(10, 2)
	SET @ComisionCategoria = (SELECT C.PorcentajeComisionBase
								FROM CATEGORIA C
									INNER JOIN CURSO CU
										ON C.CategoriaID = CU.CategoriaID
								WHERE (CU.CursoID = @CursoID))

	IF @ComisionEspecial IS NULL
	BEGIN
		RETURN @ComisionCategoria
	END;

	RETURN @ComisionEspecial;

END;
GO



-- Procedimiento para Incribir a un estudiante 
CREATE OR ALTER PROCEDURE usp_InscribirEstudiante
	@UsuarioID INT,
	@CursoID INT,
	@CohorteID INT = NULL,
	@InscripcionID INT OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;

	BEGIN TRY
		BEGIN TRANSACTION;

			IF NOT EXISTS (SELECT 1
							FROM USUARIO
							WHERE (UsuarioID = @UsuarioID) AND (TipoUsuario = 'ESTUDIANTE'))
			BEGIN
				THROW 51001, 'ERROR: El usuario no existe o no esta asignado como Estudiante.', 1;
			END;

			IF NOT EXISTS (SELECT 1
							FROM CURSO
							WHERE (CursoID = @CursoID) AND (Estado = 'DISPONIBLE'))
			BEGIN
				THROW 51002, 'ERROR: El curso no existe o no esta disponible.', 1;
			END;

			IF EXISTS (SELECT 1
						FROM INSCRIPCION
						WITH (UPDLOCK, HOLDLOCK)
						WHERE (UsuarioID = @UsuarioID) AND (CursoID = @CursoID) AND (Estado = 'ACTIVA'))
			BEGIN
				THROW 51003, 'ERROR: Este usuario ya cuenta con este curso.', 1;
			END;

			IF dbo.fn_CursoPreRequisito(@CursoID, @UsuarioID) = -1
			BEGIN
				THROW 51004, 'ERROR: El estudiante no ha pasado el pre-requisito para este curso.', 1;
			END;

			IF NOT EXISTS (SELECT 1
							FROM POLITICAREEMBOLSO
							WITH (UPDLOCK, HOLDLOCK)
							WHERE ((FechaFinVigencia > GETDATE()) OR (FechaFinVigencia IS NULL)) AND (FechaInicioVigencia <= GETDATE()))
			BEGIN
				THROW 51005, 'ERROR: No existe una politica de reembolso para la fecha actual.', 1;
			END;

			DECLARE @PrecioCurso DECIMAL(10,2)
			SELECT @PrecioCurso = Precio
			FROM CURSO
			WHERE (CursoID = @CursoID)

			DECLARE @BilleteraID INT
			SELECT @BilleteraID = BilleteraID
			FROM BILLETERA
			WITH (UPDLOCK, HOLDLOCK)
			WHERE (UsuarioID = @UsuarioID)
		
			IF @BilleteraID IS NULL 
			BEGIN 
				THROW 51006, 'ERROR: La billetera del estudiante no existe.', 1; 
			END; 
		
			IF EXISTS (SELECT 1 
						FROM BILLETERA 
						WHERE (BilleteraID = @BilleteraID) AND (Saldo < @PrecioCurso)) 
			BEGIN 
				THROW 51007, 'ERROR: La billetera del estudiante tiene saldo insuficiente.', 1; 
			END;


			IF @CohorteID IS NOT NULL
			BEGIN
				IF NOT EXISTS (SELECT 1
								FROM COHORTE
								WITH (UPDLOCK, HOLDLOCK)
								WHERE (CohorteID = @CohorteID) AND (CursoID = @CursoID))
				BEGIN
					THROW 51008, 'ERROR: El cohorte no existe o no pertenece al mismo curso.', 1;
				END;

				DECLARE @CantidadCupos INT
				SET @CantidadCupos = (SELECT COUNT(UsuarioID)
										FROM INSCRIPCION
										WHERE (CursoID = @CursoID) AND (Estado = 'ACTIVA') AND (CohorteID = @CohorteID))

				IF EXISTS (SELECT 1 
							FROM COHORTE 
							WHERE (CohorteID = @CohorteID) AND (CupoMax <= @CantidadCupos)) 
				BEGIN 
					THROW 51009, 'ERROR: El cohorte ya no tiene cupos disponibles.', 1; 
				END;
			END;

		--------------------------------------------------------------------------------------------------------------------

			DECLARE @OperacionID INT

			DECLARE @PiliticaID INT
			SET @PiliticaID = (SELECT PoliticaID
								FROM POLITICAREEMBOLSO
								WHERE ((FechaFinVigencia > GETDATE()) OR (FechaFinVigencia IS NULL)) AND (FechaInicioVigencia <= GETDATE()))
            
            -- Se inscribe al estudiante
			INSERT INTO INSCRIPCION(UsuarioID, CursoID, CohorteID, PoliticaID, FechaInscripcion, PrecioPagado, PorcentajeComiAplicado, Estado, FechaCompletado, Liquidada)
			VALUES (@UsuarioID, @CursoID, @CohorteID, @PiliticaID, DEFAULT, @PrecioCurso, dbo.fn_Procentaje_Comision(@CursoID), 'ACTIVA', DEFAULT, 0)
			SET @InscripcionID = SCOPE_IDENTITY()

            -- Se le resta el costo del curso
			UPDATE BILLETERA
			SET Saldo = Saldo - @PrecioCurso, FechaActualizacion = GETDATE()
			WHERE (UsuarioID = @UsuarioID)

            -- Se agrega la operacion a OPERACIONBILLETERA
			INSERT INTO OPERACIONBILLETERA(BilleteraID, TipoOperacion, Monto, FechaOperacion, InscripcionID, ReembolsoID, LiquidacionID, Descripcion)
			VALUES(@BilleteraID, 'COBRO_INSCRIPCION', @PrecioCurso, GETDATE(), @InscripcionID, NULL, NULL, 'Pago de inscripcion a nuevo curso')
			SET @OperacionID = SCOPE_IDENTITY()

		COMMIT TRANSACTION;
	END TRY

	BEGIN CATCH
		IF XACT_STATE() <> 0
		BEGIN
			ROLLBACK TRANSACTION;
		END;

		THROW;
	END CATCH
END;
GO



-- Index para una Inscripcion Activa
CREATE UNIQUE INDEX UX_Inscripcion_Activa
ON INSCRIPCION (UsuarioID, CursoID)
WHERE Estado = 'ACTIVA';
GO



-- Casos de prueba para Incripcion y Billetera:

-- 1. Inscripcion correcta
DECLARE @ID INT
EXEC usp_InscribirEstudiante 13, 8, @CohorteID = NULL, @InscripcionID = @ID OUTPUT
GO

-- 2. No tiene curso 1 completado
DECLARE @ID INT
EXEC usp_InscribirEstudiante 14, 8, @CohorteID = NULL, @InscripcionID = @ID OUTPUT
GO

-- 3. Falta de saldo
DECLARE @ID INT
EXEC usp_InscribirEstudiante 15, 9, @CohorteID = NULL, @InscripcionID = @ID OUTPUT
GO

-- 4. Ya tiene curso activo
DECLARE @ID INT
EXEC usp_InscribirEstudiante 8, 9, @CohorteID = NULL, @InscripcionID = @ID OUTPUT
GO

-- 5. Estado Pendiente
DECLARE @ID INT
EXEC usp_InscribirEstudiante 13, 3, @CohorteID = NULL, @InscripcionID = @ID OUTPUT
GO

-- 6. Cohorte 4
DECLARE @ID INT
EXEC usp_InscribirEstudiante 17, 9, @CohorteID = 4, @InscripcionID = @ID OUTPUT
GO

-- 7. Cohorte llena
DECLARE @ID INT
EXEC usp_InscribirEstudiante 18, 9, @CohorteID = 4, @InscripcionID = @ID OUTPUT
GO

-- 8. Usuario 16
   -- Saldo Q350.
   -- Curso 9 cuesta Q200 y Curso 10 cuesta Q250.
   -- Dos inscripciones simultaneas no pueden dejar saldo negativo.

-- Certificados

CREATE OR ALTER PROCEDURE usp_EmitirCertificado
    @InscripcionID INT,
    @Anio INT OUTPUT,
    @Correlativo INT OUTPUT,
    @CodigoCertificado VARCHAR(30) OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    DECLARE @UsuarioID INT
    DECLARE @CursoID INT
    DECLARE @EstadoInscripcion VARCHAR(15)
    DECLARE @FechaInscripcion DATETIME
    DECLARE @RequiereEval BIT
    DECLARE @ModulosTotales INT
    DECLARE @ModulosCompletados INT
    DECLARE @DuracionTotal INT
    DECLARE @UltimoAvance DATETIME
    DECLARE @MinutosReales INT
    DECLARE @EstadoCertificado VARCHAR(25)
    DECLARE @MotivoRevision NVARCHAR(500)

    BEGIN TRY
        BEGIN TRANSACTION

        SELECT @UsuarioID = UsuarioID,
               @CursoID = CursoID,
               @EstadoInscripcion = Estado,
               @FechaInscripcion = FechaInscripcion
        FROM INSCRIPCION WITH (UPDLOCK, HOLDLOCK)
        WHERE InscripcionID = @InscripcionID

        IF @UsuarioID IS NULL
            THROW 51301, 'La inscripción no existe.', 1

        IF @EstadoInscripcion IN ('REEMBOLSADA', 'CANCELADA')
            THROW 51302, 'La inscripción está reembolsada o cancelada.', 1

        IF EXISTS (SELECT 1 FROM CERTIFICADO WHERE InscripcionID = @InscripcionID)
            THROW 51303, 'La inscripción ya tiene un certificado emitido.', 1

        SELECT @ModulosTotales = COUNT(*)
        FROM MODULO
        WHERE CursoID = @CursoID

        SELECT @ModulosCompletados = COUNT(*),
               @UltimoAvance = MAX(FechaCompletado)
        FROM AVANCEMODULO
        WHERE InscripcionID = @InscripcionID

        IF @ModulosTotales = 0 OR @ModulosCompletados < @ModulosTotales
            THROW 51304, 'El progreso del curso no está completo.', 1

        SELECT @RequiereEval = RequiereEval
        FROM CURSO
        WHERE CursoID = @CursoID

        IF @RequiereEval = 1 AND NOT EXISTS (
            SELECT 1 FROM INTENTOEVALUACION
            WHERE InscripcionID = @InscripcionID AND Nota >= 70)
            THROW 51305, 'El curso requiere evaluación y no ha sido aprobada.', 1

        SELECT @DuracionTotal = ISNULL(SUM(L.DuracionMinutos), 0)
        FROM LECCION L
        INNER JOIN MODULO M ON M.ModuloID = L.ModuloID
        WHERE M.CursoID = @CursoID

        SET @MinutosReales = DATEDIFF(MINUTE, @FechaInscripcion, @UltimoAvance)

        IF @MinutosReales * 2 < @DuracionTotal
        BEGIN
            SET @EstadoCertificado = 'PENDIENTE_VERIFICACION'
            SET @MotivoRevision = CONCAT(N'Curso completado en ', @MinutosReales,
                N' minutos; duración total de lecciones: ', @DuracionTotal, N' minutos.')
        END
        ELSE
        BEGIN
            SET @EstadoCertificado = 'VALIDO'
            SET @MotivoRevision = NULL
        END

        SET @Anio = YEAR(GETDATE())

        SELECT @Correlativo = ISNULL(MAX(Correlativo), 0) + 1
        FROM CERTIFICADO WITH (UPDLOCK, HOLDLOCK)
        WHERE Anio = @Anio

        SET @CodigoCertificado = CONCAT('CERT-', @Anio, '-',
            RIGHT('0000' + CAST(@Correlativo AS VARCHAR(10)), 4))

        INSERT INTO CERTIFICADO (Anio, Correlativo, InscripcionID, CodigoCertificado,
                                 FechaEmision, Estado, MotivoRevision)
        VALUES (@Anio, @Correlativo, @InscripcionID, @CodigoCertificado,
                GETDATE(), @EstadoCertificado, @MotivoRevision)

        UPDATE INSCRIPCION
        SET Estado = 'COMPLETADA',
            FechaCompletado = GETDATE()
        WHERE InscripcionID = @InscripcionID

        INSERT INTO NOTIFICACION (UsuarioID, CursoID, Tipo, Asunto, Mensaje)
        VALUES (@UsuarioID, @CursoID, 'CERTIFICADO_EMITIDO', N'Certificado emitido',
                CONCAT(N'Tu certificado ', @CodigoCertificado,
                       N' fue emitido con estado ', @EstadoCertificado, N'.'))

        IF @EstadoCertificado = 'PENDIENTE_VERIFICACION'
            INSERT INTO NOTIFICACION (UsuarioID, CursoID, Tipo, Asunto, Mensaje)
            SELECT TrabajadorID, @CursoID, 'CERTIFICADO_REVISION',
                   N'Certificado pendiente de verificación',
                   CONCAT(N'Revisar certificado ', @CodigoCertificado, N'. ', @MotivoRevision)
            FROM TRABAJADOR
            WHERE TipoTrabajador = 'REVISOR'

        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK;
        THROW
    END CATCH
END
GO

-- PRUEBAS
-- Pruebas del procedimiento para emitir certificados

-- 1.1 Certificado correcto en curso sin evaluación (Inscripción 13)
--     Se espera CERT-2026-0005, VALIDO
DECLARE @Anio INT, @Correlativo INT, @Codigo VARCHAR(30);

EXEC usp_EmitirCertificado
    @InscripcionID = 13,
    @Anio = @Anio OUTPUT,
    @Correlativo = @Correlativo OUTPUT,
    @CodigoCertificado = @Codigo OUTPUT;

SELECT @Anio AS Anio, @Correlativo AS Correlativo, @Codigo AS CodigoCertificado;

SELECT * FROM CERTIFICADO WHERE InscripcionID = 13;
SELECT InscripcionID, Estado, FechaCompletado FROM INSCRIPCION WHERE InscripcionID = 13;
SELECT * FROM NOTIFICACION WHERE Tipo LIKE 'CERTIFICADO%';
GO

-- 1.2 Certificado correcto en curso con evaluación aprobada (Inscripción 11)
--     Se espera CERT-2026-0006, VALIDO
DECLARE @Anio INT, @Correlativo INT, @Codigo VARCHAR(30);

EXEC usp_EmitirCertificado
    @InscripcionID = 11,
    @Anio = @Anio OUTPUT,
    @Correlativo = @Correlativo OUTPUT,
    @CodigoCertificado = @Codigo OUTPUT;

SELECT @Anio AS Anio, @Correlativo AS Correlativo, @Codigo AS CodigoCertificado;

SELECT * FROM CERTIFICADO WHERE InscripcionID = 11;
SELECT InscripcionID, Estado, FechaCompletado FROM INSCRIPCION WHERE InscripcionID = 11;
GO

-- 1.3 Error porque el progreso está incompleto (Inscripción 15), se espera mensaje 51304
DECLARE @Anio INT, @Correlativo INT, @Codigo VARCHAR(30);

EXEC usp_EmitirCertificado
    @InscripcionID = 15,
    @Anio = @Anio OUTPUT,
    @Correlativo = @Correlativo OUTPUT,
    @CodigoCertificado = @Codigo OUTPUT;
GO

-- 1.4 Error porque la evaluación no está aprobada (Inscripción 16), se espera mensaje 51305
DECLARE @Anio INT, @Correlativo INT, @Codigo VARCHAR(30);

EXEC usp_EmitirCertificado
    @InscripcionID = 16,
    @Anio = @Anio OUTPUT,
    @Correlativo = @Correlativo OUTPUT,
    @CodigoCertificado = @Codigo OUTPUT;
GO

-- 1.5 Error porque el certificado ya fue emitido (Inscripción 13 otra vez), se espera mensaje 51303
--     Necesita haber ejecutado la prueba 1.1
DECLARE @Anio INT, @Correlativo INT, @Codigo VARCHAR(30);

EXEC usp_EmitirCertificado
    @InscripcionID = 13,
    @Anio = @Anio OUTPUT,
    @Correlativo = @Correlativo OUTPUT,
    @CodigoCertificado = @Codigo OUTPUT;
GO

-- 1.6 Finalización sospechosa (Inscripción 17: Curso 9 de 105 min completado en 15 min)
--     Se espera CERT-2026-0007, PENDIENTE_VERIFICACION y aviso a los revisores 4 y 5
DECLARE @Anio INT, @Correlativo INT, @Codigo VARCHAR(30);

EXEC usp_EmitirCertificado
    @InscripcionID = 17,
    @Anio = @Anio OUTPUT,
    @Correlativo = @Correlativo OUTPUT,
    @CodigoCertificado = @Codigo OUTPUT;

SELECT @Codigo AS CodigoCertificado;

SELECT * FROM CERTIFICADO WHERE InscripcionID = 17;
SELECT * FROM NOTIFICACION WHERE Tipo = 'CERTIFICADO_REVISION';
GO

-- 1.7 Verificación de correlativos: 1 a 7 seguidos, sin huecos pese a los errores
--     Los errores de 1.3, 1.4 y 1.5 hicieron ROLLBACK y no consumieron número
SELECT Anio, Correlativo, CodigoCertificado, InscripcionID, Estado, MotivoRevision
FROM CERTIFICADO
ORDER BY Anio, Correlativo;
GO



-- Progreso e historial 

-- Procedimiento para registrar el avance de un modulo
CREATE OR ALTER PROCEDURE usp_RegistrarAvanceModulo

    @InscripcionID INT,
    @ModuloID INT

AS
BEGIN

    SET NOCOUNT ON;

    declare @CursoID INT;
    declare @TotalModulos INT;
    declare @ModulosCompletados INT;
    declare @PorcentajeProgreso DECIMAL(5,2);
    declare @RequiereEval BIT;

    declare @AnioCertificado INT;
    declare @CorrelativoCertificado INT;
    declare @CodigoCertificado VARCHAR(30);

    begin try

        if not exists (
            select 1
            from INSCRIPCION
            where InscripcionID = @InscripcionID
        )
        begin
            throw 51101, 'La inscripcion indicada no existe.', 1;
        end

        if not exists (
            select 1
            from INSCRIPCION
            where InscripcionID = @InscripcionID
            and Estado = 'ACTIVA'
        )
        begin
            throw 51102, 'La inscripcion no se encuentra activa.', 1;
        end

        select @CursoID = CursoID
        from INSCRIPCION
        where InscripcionID = @InscripcionID;

        if not exists (
            select 1
            from MODULO
            where ModuloID = @ModuloID
        )
        begin
            throw 51103, 'El modulo indicado no existe.', 1;
        end

        if not exists (
            select 1
            from MODULO
            where ModuloID = @ModuloID
            and CursoID = @CursoID
        )
        begin
            throw 51104, 'El modulo no pertenece al curso de la inscripcion.', 1;
        end

        begin transaction;

        if exists (
            select 1
            from AVANCEMODULO with (UPDLOCK, HOLDLOCK)
            where InscripcionID = @InscripcionID
            and ModuloID = @ModuloID
        )
        begin
            throw 51105, 'El modulo ya fue registrado como completado.', 1;
        end

        insert into AVANCEMODULO
        (
            InscripcionID,
            ModuloID
        )
        values
        (
            @InscripcionID,
            @ModuloID
        );

        select @TotalModulos = count(*)
        from MODULO
        where CursoID = @CursoID;

        select @ModulosCompletados = count(*)
        from AVANCEMODULO A
        inner join MODULO M
            on A.ModuloID = M.ModuloID
        where A.InscripcionID = @InscripcionID
        and M.CursoID = @CursoID;

        set @PorcentajeProgreso =
            (@ModulosCompletados * 100.0) / @TotalModulos;

        select @RequiereEval = RequiereEval
        from CURSO
        where CursoID = @CursoID;

        -- Si completo todos los modulos y no requiere evaluacion,
        -- se genera automaticamente el certificado
        if @PorcentajeProgreso = 100
           and @RequiereEval = 0
        begin

            EXEC usp_EmitirCertificado
                @InscripcionID = @InscripcionID,
                @Anio = @AnioCertificado OUTPUT,
                @Correlativo = @CorrelativoCertificado OUTPUT,
                @CodigoCertificado = @CodigoCertificado OUTPUT;

        end

        commit transaction;

        select
            @InscripcionID AS InscripcionID,
            @ModulosCompletados AS ModulosCompletados,
            @TotalModulos AS TotalModulos,
            @PorcentajeProgreso AS PorcentajeProgreso,
            @CodigoCertificado AS CodigoCertificado;

    end try

    begin catch

        if XACT_STATE() <> 0
            rollback transaction;

        throw;

    end catch

END;
GO

-- Vista para consultar el historial y porcentaje de progreso
CREATE OR ALTER VIEW vw_HistorialProgreso
AS

    select
        I.InscripcionID,
        I.UsuarioID,
        U.Nombre,
        U.Apellido,
        I.CursoID,
        C.Titulo,
        I.Estado AS EstadoInscripcion,
        COUNT(M.ModuloID) AS TotalModulos,
        COUNT(A.ModuloID) AS ModulosCompletados,

        CAST(
            CASE
                WHEN COUNT(M.ModuloID) = 0 THEN 0
                ELSE COUNT(A.ModuloID) * 100.0 / COUNT(M.ModuloID)
            END
            AS DECIMAL(5,2)
        ) AS PorcentajeProgreso

    from INSCRIPCION I

    inner join USUARIO U
        on I.UsuarioID = U.UsuarioID

    inner join CURSO C
        on I.CursoID = C.CursoID

    left join MODULO M
        on C.CursoID = M.CursoID

    left join AVANCEMODULO A
        on A.InscripcionID = I.InscripcionID
        and A.ModuloID = M.ModuloID

    group by
        I.InscripcionID,
        I.UsuarioID,
        U.Nombre,
        U.Apellido,
        I.CursoID,
        C.Titulo,
        I.Estado;
GO

--Pruebas de progreso e historial

-- 1.1 Registro correcto de avance
-- Verifica que se registre el modulo y se actualice el progreso.
EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 10,
    @ModuloID = 24;

-- 1.2 Error por inscripcion inexistente
-- Verifica que no se registre avance si la inscripcion no existe.
EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 999,
    @ModuloID = 24;

-- 1.3 Error por inscripcion no activa
-- Verifica que no se registre avance si la inscripcion no esta activa.
EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 1,
    @ModuloID = 1;

-- 1.4 Error por modulo inexistente
-- Verifica que no se registre avance si el modulo no existe.

EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 10,
    @ModuloID = 999;

-- 1.5 Error por modulo de otro curso
-- Verifica que el modulo pertenezca al mismo curso de la inscripcion.
EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 10,
    @ModuloID = 27;

-- 1.6 Error por modulo ya completado
-- Verifica que no se registre dos veces el mismo modulo.
EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 10,
    @ModuloID = 24;

-- 1.7 Registro correcto del segundo modulo
-- Verifica que el progreso aumente al completar otro modulo.
EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 10,
    @ModuloID = 25;

-- 1.8 Registro del ultimo modulo y certificado automatico
-- Verifica que al llegar al 100% se genere el certificado si el curso no requiere evaluacion.
EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 10,
    @ModuloID = 26;

SELECT *
FROM CERTIFICADO
WHERE InscripcionID = 10;

SELECT InscripcionID, Estado, FechaCompletado
FROM INSCRIPCION
WHERE InscripcionID = 10;

SELECT *
FROM NOTIFICACION
WHERE UsuarioID = 8
AND CursoID = 9;

-- 1.9 Error por inscripcion completada
-- Verifica que no se registre avance despues de completar el curso.
EXEC usp_RegistrarAvanceModulo
    @InscripcionID = 10,
    @ModuloID = 24;




-- Evalucion Final

CREATE OR ALTER PROCEDURE usp_RegistrarIntentoEvaluacion
	@InscripcionID INT,
	@Nota DECIMAL(5,2),
	@IntentoID INT OUTPUT,
	@NumeroIntento INT OUTPUT
AS
BEGIN

	DECLARE @RequiereEval BIT;
	DECLARE @CursoID INT;
	DECLARE @CantIntentos INT;
	DECLARE @ModulosTotales INT;
	DECLARE @ModulosCompletados INT;
	DECLARE @Anio INT;
	DECLARE @Correlativo INT;
	DECLARE @CodigoCertificado VARCHAR(30);

	BEGIN TRY

	IF NOT EXISTS 
	(
		SELECT 1
		FROM INSCRIPCION
		WHERE InscripcionID = @InscripcionID
	)
	BEGIN
		THROW 51201, 'La inscripción no existe', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1
		FROM INSCRIPCION
		WHERE InscripcionID = @InscripcionID AND Estado = 'ACTIVA'
	)
	BEGIN
		THROW 51202, 'La inscripción no se encuentra activa',1;
	END;

	SELECT @CursoID = CursoID
	FROM INSCRIPCION
	WHERE InscripcionID = @InscripcionID;

	SELECT @RequiereEval = RequiereEval
	FROM CURSO
	WHERE CursoID = @CursoID;

	IF @RequiereEval <> 1
	BEGIN
		THROW 51203, 'El curso no requiere evaluación', 1;
	END;

	IF @Nota < 0 OR @Nota > 100 OR @Nota IS NULL
	BEGIN
		THROW 51204, 'La nota debe estar entre 0 y 100', 1;
	END;

	SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
	BEGIN TRANSACTION;

	SELECT 
		@CantIntentos = COUNT(InscripcionID),
		@NumeroIntento = ISNULL(MAX(NumeroIntento), 0) + 1
	FROM INTENTOEVALUACION WITH (UPDLOCK)
	WHERE InscripcionID = @InscripcionID;

	IF @CantIntentos >= 3
	BEGIN
		THROW 51205, 'Ya existen 3 intentos realizados para la evaluación', 1;
	END;

	INSERT INTO INTENTOEVALUACION
           (InscripcionID
           ,NumeroIntento
           ,Nota
           ,FechaIntento)
     VALUES
           (@InscripcionID
           ,@NumeroIntento
           ,@Nota
           ,GETDATE() 
		   );

	SET @IntentoID = SCOPE_IDENTITY();
	COMMIT TRANSACTION;

	IF @Nota >= 70
	BEGIN
		SELECT @ModulosTotales = COUNT(*)
		FROM MODULO
		WHERE CursoID = @CursoID;

		SELECT @ModulosCompletados = Count(A.ModuloID)
		FROM AVANCEMODULO A
		INNER JOIN MODULO M
			ON A.ModuloID = M.ModuloID
		WHERE InscripcionID = @InscripcionID
			AND M.CursoID = @CursoID;

		IF @ModulosTotales = @ModulosCompletados
		BEGIN
			EXEC usp_EmitirCertificado
				@InscripcionID = @InscripcionID,
				@Anio = @Anio OUTPUT,
				@Correlativo = @Correlativo OUTPUT,
				@CodigoCertificado = @CodigoCertificado OUTPUT;
		END;
	END;

	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0
		ROLLBACK TRANSACTION;

		THROW;
	END CATCH;
END;
GO

-- Pruebas de Evalucion Final:

-- Prueba para una nota que no es válida, se espera un mensaje de error
DECLARE @IntentoID INT;
DECLARE @NumeroIntento INT;

EXEC usp_RegistrarIntentoEvaluacion
	@InscripcionID = 14,
	@Nota = 105,
	@IntentoID = @IntentoID OUTPUT,
	@NumeroIntento = @NumeroIntento OUTPUT;

-- Prueba para un curso que no requiere evaluación, se espera un mensaje de error
DECLARE @IntentoID INT;
DECLARE @NumeroIntento INT;

EXEC usp_RegistrarIntentoEvaluacion
	@InscripcionID = 10,
	@Nota = 80,
	@IntentoID = @IntentoID OUTPUT,
	@NumeroIntento = @NumeroIntento OUTPUT;

-- Prueba para permitir el tercer intento
DECLARE @IntentoID INT;
DECLARE @NumeroIntento INT;

EXEC usp_RegistrarIntentoEvaluacion
	@InscripcionID = 12,
	@Nota = 60,
	@IntentoID = @IntentoID OUTPUT,
	@NumeroIntento = @NumeroIntento OUTPUT;

SELECT @IntentoID AS IntentoID,
	   @NumeroIntento AS NumeroIntento;

SELECT *
FROM INTENTOEVALUACION
WHERE InscripcionID = 12
ORDER BY NumeroIntento;

-- Prueba para impedir un cuarto intento, se espera un mensaje de error
DECLARE @IntentoID INT;
DECLARE @NumeroIntento INT;

EXEC usp_RegistrarIntentoEvaluacion
	@InscripcionID = 12,
	@Nota = 80,
	@IntentoID = @IntentoID OUTPUT,
	@NumeroIntento = @NumeroIntento OUTPUT;

-- Prueba para aprobar un curso y ejecutar el certificado automático
DECLARE @IntentoID INT;
DECLARE @NumeroIntento INT;

EXEC usp_RegistrarIntentoEvaluacion
	@InscripcionID = 14,
	@Nota = 85,
	@IntentoID = @IntentoID OUTPUT,
	@NumeroIntento = @NumeroIntento OUTPUT;

SELECT @IntentoID AS IntentoID,
	   @NumeroIntento AS NumeroIntento;

SELECT *
FROM INTENTOEVALUACION
WHERE InscripcionID = 14;

SELECT *
FROM CERTIFICADO
WHERE InscripcionID = 14;

SELECT InscripcionID, Estado, FechaCompletado
FROM INSCRIPCION
WHERE InscripcionID = 14;

-- Prueba de concurrencia
-- Ventana 1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

SELECT 
	COUNT(InscripcionID) AS CantIntentos,
	ISNULL(MAX(NumeroIntento), 0) + 1 AS SiguienteIntento
FROM INTENTOEVALUACION WITH (UPDLOCK)
WHERE InscripcionID = 15;

WAITFOR DELAY '00:00:20';

COMMIT TRANSACTION;

-- Ventana 2
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
BEGIN TRANSACTION;

SELECT 
	COUNT(InscripcionID) AS CantIntentos,
	ISNULL(MAX(NumeroIntento), 0) + 1 AS SiguienteIntento
FROM INTENTOEVALUACION WITH (UPDLOCK)
WHERE InscripcionID = 15;

COMMIT TRANSACTION;





-- Concurrencia e integracion

/* ============================================================
   0. VERIFICACION DE OBJETOS DE FASE 3
   ============================================================ */

IF OBJECT_ID('dbo.usp_InscribirEstudiante', 'P') IS NULL
    THROW 51401, 'Falta usp_InscribirEstudiante.', 1;

IF OBJECT_ID('dbo.usp_RegistrarAvanceModulo', 'P') IS NULL
    THROW 51402, 'Falta usp_RegistrarAvanceModulo.', 1;

IF OBJECT_ID('dbo.usp_RegistrarIntentoEvaluacion', 'P') IS NULL
    THROW 51403, 'Falta usp_RegistrarIntentoEvaluacion.', 1;

IF OBJECT_ID('dbo.usp_EmitirCertificado', 'P') IS NULL
    THROW 51404, 'Falta usp_EmitirCertificado.', 1;

IF OBJECT_ID('dbo.vw_HistorialProgreso', 'V') IS NULL
    THROW 51405, 'Falta vw_HistorialProgreso.', 1;

PRINT 'Todos los objetos de Fase 3 existen correctamente.';
GO



/* ============================================================
   1. INDICE DE APOYO
   UX_Inscripcion_Activa
   ============================================================ */

IF EXISTS
(
    SELECT
        UsuarioID,
        CursoID
    FROM INSCRIPCION
    WHERE Estado = 'ACTIVA'
    GROUP BY UsuarioID, CursoID
    HAVING COUNT(*) > 1
)
BEGIN
    THROW 51490,
          'Existen inscripciones activas duplicadas. No se puede crear el indice.',
          1;
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.indexes
    WHERE name = 'UX_Inscripcion_Activa'
      AND object_id = OBJECT_ID('INSCRIPCION')
)
BEGIN

    CREATE UNIQUE INDEX UX_Inscripcion_Activa
    ON INSCRIPCION (UsuarioID, CursoID)
    WHERE Estado = 'ACTIVA';

    PRINT 'UX_Inscripcion_Activa creado correctamente.';

END
ELSE
BEGIN

    PRINT 'UX_Inscripcion_Activa ya existe.';

END;
GO


-- Verificacion del indice
SELECT
    name AS NombreIndice,
    type_desc AS TipoIndice,
    is_unique AS EsUnico,
    filter_definition AS Filtro
FROM sys.indexes
WHERE object_id = OBJECT_ID('INSCRIPCION')
  AND name = 'UX_Inscripcion_Activa';
GO



/* ========================================================================================================================
   ESCENARIO 1
   ULTIMO CUPO

   Usuario 17 vs Usuario 18
   Curso 9
   Cohorte 4
   CupoMax = 1

   RESULTADO ESPERADO:
   Solo uno debe quedar inscrito en la Cohorte 4.
   ======================================================================================================================== */


/* ============================================================
   ESCENARIO 1 - VENTANA 1
   Usuario 17
   ============================================================ */

DECLARE @InscripcionID_V1 INT;

BEGIN TRY

    BEGIN TRANSACTION;

    EXEC usp_InscribirEstudiante
        @UsuarioID = 17,
        @CursoID = 9,
        @CohorteID = 4,
        @InscripcionID = @InscripcionID_V1 OUTPUT;

    SELECT
        @InscripcionID_V1 AS InscripcionID_Ventana1;

    PRINT 'VENTANA 1: Usuario 17 obtuvo el ultimo cupo.';
    PRINT 'VENTANA 1: Manteniendo la transaccion abierta 10 segundos...';

    WAITFOR DELAY '00:00:10';

    COMMIT TRANSACTION;

    PRINT 'VENTANA 1: COMMIT realizado.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 1 - VENTANA 2
   Usuario 18

   Ejecutar inmediatamente despues de iniciar Ventana 1.
   ============================================================ */

WAITFOR DELAY '00:00:02';

DECLARE @InscripcionID_V2 INT;

BEGIN TRY

    EXEC usp_InscribirEstudiante
        @UsuarioID = 18,
        @CursoID = 9,
        @CohorteID = 4,
        @InscripcionID = @InscripcionID_V2 OUTPUT;

    SELECT
        @InscripcionID_V2 AS InscripcionID_Ventana2;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 1 - VERIFICACION FINAL

   Debe existir exactamente UNA inscripcion activa
   para la Cohorte 4.
   ============================================================ */

SELECT
    I.InscripcionID,
    I.UsuarioID,
    I.CursoID,
    I.CohorteID,
    I.Estado
FROM INSCRIPCION I
WHERE I.CohorteID = 4;
GO


SELECT
    C.CohorteID,
    C.CupoMax,
    COUNT(I.InscripcionID) AS CuposOcupados
FROM COHORTE C
LEFT JOIN INSCRIPCION I
    ON I.CohorteID = C.CohorteID
   AND I.Estado = 'ACTIVA'
WHERE C.CohorteID = 4
GROUP BY
    C.CohorteID,
    C.CupoMax;
GO



/* ========================================================================================================================
   ESCENARIO 2
   MISMA BILLETERA

   Usuario 16
   Saldo inicial = Q350

   Ventana 1: Curso 9  = Q200
   Ventana 2: Curso 10 = Q250

   Q350 NO alcanza para ambas compras.

   RESULTADO ESPERADO:
   Solo una compra debe confirmarse.
   El saldo nunca puede quedar negativo.
   ======================================================================================================================== */


/* ============================================================
   ESCENARIO 2 - VENTANA 1
   Usuario 16 intenta Curso 9
   ============================================================ */

DECLARE @InscripcionID_V1 INT;

BEGIN TRY

    BEGIN TRANSACTION;

    EXEC usp_InscribirEstudiante
        @UsuarioID = 16,
        @CursoID = 9,
        @CohorteID = NULL,
        @InscripcionID = @InscripcionID_V1 OUTPUT;

    SELECT
        @InscripcionID_V1 AS InscripcionID_Ventana1;

    PRINT 'VENTANA 1: Compra del Curso 9 registrada.';
    PRINT 'VENTANA 1: Manteniendo la transaccion abierta 10 segundos...';

    WAITFOR DELAY '00:00:10';

    COMMIT TRANSACTION;

    PRINT 'VENTANA 1: COMMIT realizado.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 2 - VENTANA 2
   Usuario 16 intenta Curso 10
   ============================================================ */

WAITFOR DELAY '00:00:02';

DECLARE @InscripcionID_V2 INT;

BEGIN TRY

    EXEC usp_InscribirEstudiante
        @UsuarioID = 16,
        @CursoID = 10,
        @CohorteID = NULL,
        @InscripcionID = @InscripcionID_V2 OUTPUT;

    SELECT
        @InscripcionID_V2 AS InscripcionID_Ventana2;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 2 - VERIFICACION FINAL

   Si Ventana 1 gana:
       Saldo esperado = Q150

   Debe existir solamente una compra confirmada.
   ============================================================ */

SELECT
    B.BilleteraID,
    B.UsuarioID,
    B.Saldo,
    B.FechaActualizacion
FROM BILLETERA B
WHERE B.UsuarioID = 16;
GO


SELECT
    InscripcionID,
    UsuarioID,
    CursoID,
    Estado,
    PrecioPagado
FROM INSCRIPCION
WHERE UsuarioID = 16
ORDER BY InscripcionID;
GO


SELECT
    O.OperacionID,
    O.BilleteraID,
    O.TipoOperacion,
    O.Monto,
    O.InscripcionID
FROM OPERACIONBILLETERA O
INNER JOIN BILLETERA B
    ON B.BilleteraID = O.BilleteraID
WHERE B.UsuarioID = 16
ORDER BY O.OperacionID;
GO



/* ========================================================================================================================
   ESCENARIO 3
   MISMO MODULO

   InscripcionID = 10
   ModuloID      = 24

   Dos dispositivos intentan registrar el mismo modulo.

   RESULTADO ESPERADO:
   Solo debe existir un registro en AVANCEMODULO.
   ======================================================================================================================== */


/* ============================================================
   ESCENARIO 3 - VENTANA 1
   ============================================================ */

BEGIN TRY

    BEGIN TRANSACTION;

    EXEC usp_RegistrarAvanceModulo
        @InscripcionID = 10,
        @ModuloID = 24;

    PRINT 'VENTANA 1: Modulo 24 registrado.';
    PRINT 'VENTANA 1: Manteniendo la transaccion abierta 10 segundos...';

    WAITFOR DELAY '00:00:10';

    COMMIT TRANSACTION;

    PRINT 'VENTANA 1: COMMIT realizado.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 3 - VENTANA 2
   ============================================================ */

WAITFOR DELAY '00:00:02';

BEGIN TRY

    EXEC usp_RegistrarAvanceModulo
        @InscripcionID = 10,
        @ModuloID = 24;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 3 - VERIFICACION FINAL

   CantidadRegistros debe ser 1.
   Progreso debe ser aproximadamente 33.33%.
   ============================================================ */

SELECT
    InscripcionID,
    ModuloID,
    FechaCompletado
FROM AVANCEMODULO
WHERE InscripcionID = 10
  AND ModuloID = 24;
GO


SELECT
    COUNT(*) AS CantidadRegistros
FROM AVANCEMODULO
WHERE InscripcionID = 10
  AND ModuloID = 24;
GO


SELECT *
FROM vw_HistorialProgreso
WHERE InscripcionID = 10;
GO



/* ========================================================================================================================
   ESCENARIO 4
   SIGUIENTE INTENTO

   InscripcionID = 14

   Estado base:
   - Curso 10
   - 100% de progreso
   - 0 intentos

   Se utilizan notas reprobadas para evitar que durante
   esta prueba se emita automaticamente el certificado.

   Ventana 1 = Nota 50
   Ventana 2 = Nota 60

   RESULTADO ESPERADO:
   NumeroIntento 1 y NumeroIntento 2.
   Nunca dos NumeroIntento iguales.
   ======================================================================================================================== */


/* ============================================================
   ESCENARIO 4 - VENTANA 1
   ============================================================ */

DECLARE @IntentoID_V1 INT;
DECLARE @NumeroIntento_V1 INT;

BEGIN TRY

    BEGIN TRANSACTION;

    EXEC usp_RegistrarIntentoEvaluacion
        @InscripcionID = 14,
        @Nota = 50,
        @IntentoID = @IntentoID_V1 OUTPUT,
        @NumeroIntento = @NumeroIntento_V1 OUTPUT;

    SELECT
        @IntentoID_V1 AS IntentoID_Ventana1,
        @NumeroIntento_V1 AS NumeroIntento_Ventana1;

    PRINT 'VENTANA 1: Intento registrado.';
    PRINT 'VENTANA 1: Manteniendo la transaccion abierta 10 segundos...';

    WAITFOR DELAY '00:00:10';

    COMMIT TRANSACTION;

    PRINT 'VENTANA 1: COMMIT realizado.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 4 - VENTANA 2
   ============================================================ */

WAITFOR DELAY '00:00:02';

DECLARE @IntentoID_V2 INT;
DECLARE @NumeroIntento_V2 INT;

BEGIN TRY

    EXEC usp_RegistrarIntentoEvaluacion
        @InscripcionID = 14,
        @Nota = 60,
        @IntentoID = @IntentoID_V2 OUTPUT,
        @NumeroIntento = @NumeroIntento_V2 OUTPUT;

    SELECT
        @IntentoID_V2 AS IntentoID_Ventana2,
        @NumeroIntento_V2 AS NumeroIntento_Ventana2;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 4 - VERIFICACION FINAL

   Deben existir:
       NumeroIntento = 1
       NumeroIntento = 2
   ============================================================ */

SELECT
    IntentoID,
    InscripcionID,
    NumeroIntento,
    Nota,
    FechaIntento
FROM INTENTOEVALUACION
WHERE InscripcionID = 14
ORDER BY NumeroIntento;
GO


SELECT
    COUNT(*) AS CantidadIntentos,
    MIN(NumeroIntento) AS PrimerIntento,
    MAX(NumeroIntento) AS UltimoIntento
FROM INTENTOEVALUACION
WHERE InscripcionID = 14;
GO



/* ========================================================================================================================
   ESCENARIO 5
   CERTIFICADOS SIMULTANEOS

   Inscripcion 11:
       Curso 8
       100% progreso
       Evaluacion aprobada

   Inscripcion 13:
       Curso 9
       100% progreso
       No requiere evaluacion

   En estado base ya existen correlativos:
       1, 2, 3 y 4

   RESULTADO ESPERADO:
       Una sesion obtiene correlativo 5
       La otra obtiene correlativo 6
   ======================================================================================================================== */


/* ============================================================
   ESCENARIO 5 - VENTANA 1
   Inscripcion 11
   ============================================================ */

DECLARE @Anio_V1 INT;
DECLARE @Correlativo_V1 INT;
DECLARE @Codigo_V1 VARCHAR(30);

BEGIN TRY

    BEGIN TRANSACTION;

    EXEC usp_EmitirCertificado
        @InscripcionID = 11,
        @Anio = @Anio_V1 OUTPUT,
        @Correlativo = @Correlativo_V1 OUTPUT,
        @CodigoCertificado = @Codigo_V1 OUTPUT;

    SELECT
        @Anio_V1 AS Anio_Ventana1,
        @Correlativo_V1 AS Correlativo_Ventana1,
        @Codigo_V1 AS Codigo_Ventana1;

    PRINT 'VENTANA 1: Certificado generado.';
    PRINT 'VENTANA 1: Manteniendo la transaccion abierta 10 segundos...';

    WAITFOR DELAY '00:00:10';

    COMMIT TRANSACTION;

    PRINT 'VENTANA 1: COMMIT realizado.';

END TRY
BEGIN CATCH

    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 5 - VENTANA 2
   Inscripcion 13
   ============================================================ */

WAITFOR DELAY '00:00:02';

DECLARE @Anio_V2 INT;
DECLARE @Correlativo_V2 INT;
DECLARE @Codigo_V2 VARCHAR(30);

BEGIN TRY

    EXEC usp_EmitirCertificado
        @InscripcionID = 13,
        @Anio = @Anio_V2 OUTPUT,
        @Correlativo = @Correlativo_V2 OUTPUT,
        @CodigoCertificado = @Codigo_V2 OUTPUT;

    SELECT
        @Anio_V2 AS Anio_Ventana2,
        @Correlativo_V2 AS Correlativo_Ventana2,
        @Codigo_V2 AS Codigo_Ventana2;

END TRY
BEGIN CATCH

    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;

END CATCH;
GO



/* ============================================================
   ESCENARIO 5 - VERIFICACION FINAL

   Deben aparecer correlativos 5 y 6 para
   Inscripciones 11 y 13.
   ============================================================ */

SELECT
    Anio,
    Correlativo,
    InscripcionID,
    CodigoCertificado,
    Estado,
    FechaEmision
FROM CERTIFICADO
WHERE InscripcionID IN (11, 13)
ORDER BY Anio, Correlativo;
GO


SELECT
    Anio,
    Correlativo,
    CodigoCertificado,
    InscripcionID
FROM CERTIFICADO
WHERE Anio = YEAR(GETDATE())
ORDER BY Correlativo;
GO



/* ============================================================
   ============================================================
   7. PRUEBA FINAL DE INTEGRACION

   IMPORTANTE:
   Antes de ejecutar ESTA seccion volver a ejecutar:

       03_EduGT_Datos_Prueba.sql
       05_Datos_Prueba_Fase3.sql

   No ejecutar las pruebas de los otros integrantes despues.

   Flujo:
       Usuario 13
       Curso 8
       Inscripcion
       Modulos 21,22,23
       Evaluacion
       Certificado
   ============================================================
   ============================================================ */


/* ============================================================
   PASO 1
   Verificar datos iniciales
   ============================================================ */

SELECT
    U.UsuarioID,
    U.Nombre,
    U.TipoUsuario,
    B.Saldo
FROM USUARIO U
INNER JOIN BILLETERA B
    ON B.UsuarioID = U.UsuarioID
WHERE U.UsuarioID = 13;
GO


SELECT
    CursoID,
    Titulo,
    Precio,
    Estado,
    RequiereEval
FROM CURSO
WHERE CursoID = 8;
GO



/* ============================================================
   PASO 2
   Inscribir al estudiante
   ============================================================ */

DECLARE @InscripcionIntegracion INT;

EXEC usp_InscribirEstudiante
    @UsuarioID = 13,
    @CursoID = 8,
    @CohorteID = NULL,
    @InscripcionID = @InscripcionIntegracion OUTPUT;

SELECT
    @InscripcionIntegracion AS NuevaInscripcionID;
GO



/* ============================================================
   PASO 3
   Verificar inscripcion, cobro y billetera

   El ID nuevo normalmente sera 19 despues de cargar
   los datos base de Fase 3.
   ============================================================ */

DECLARE @InscripcionIntegracion INT;

SELECT
    @InscripcionIntegracion = MAX(InscripcionID)
FROM INSCRIPCION
WHERE UsuarioID = 13
  AND CursoID = 8;

SELECT *
FROM INSCRIPCION
WHERE InscripcionID = @InscripcionIntegracion;

SELECT
    B.UsuarioID,
    B.Saldo,
    B.FechaActualizacion
FROM BILLETERA B
WHERE B.UsuarioID = 13;

SELECT O.*
FROM OPERACIONBILLETERA O
INNER JOIN BILLETERA B
    ON B.BilleteraID = O.BilleteraID
WHERE B.UsuarioID = 13
  AND O.InscripcionID = @InscripcionIntegracion;
GO



/* ============================================================
   PASO 4
   Registrar los tres modulos del Curso 8
   ============================================================ */

DECLARE @InscripcionIntegracion INT;

SELECT
    @InscripcionIntegracion = MAX(InscripcionID)
FROM INSCRIPCION
WHERE UsuarioID = 13
  AND CursoID = 8;

EXEC usp_RegistrarAvanceModulo
    @InscripcionID = @InscripcionIntegracion,
    @ModuloID = 21;

EXEC usp_RegistrarAvanceModulo
    @InscripcionID = @InscripcionIntegracion,
    @ModuloID = 22;

EXEC usp_RegistrarAvanceModulo
    @InscripcionID = @InscripcionIntegracion,
    @ModuloID = 23;
GO



/* ============================================================
   PASO 5
   Verificar progreso al 100%
   ============================================================ */

DECLARE @InscripcionIntegracion INT;

SELECT
    @InscripcionIntegracion = MAX(InscripcionID)
FROM INSCRIPCION
WHERE UsuarioID = 13
  AND CursoID = 8;

SELECT *
FROM vw_HistorialProgreso
WHERE InscripcionID = @InscripcionIntegracion;
GO



/* ============================================================
   PASO 6
   Registrar evaluacion aprobada

   Nota 85 >= 70.

   Como ya existe 100% de progreso,
   usp_RegistrarIntentoEvaluacion debe llamar
   automaticamente a usp_EmitirCertificado.
   ============================================================ */

DECLARE @InscripcionIntegracion INT;
DECLARE @IntentoIDIntegracion INT;
DECLARE @NumeroIntentoIntegracion INT;

SELECT
    @InscripcionIntegracion = MAX(InscripcionID)
FROM INSCRIPCION
WHERE UsuarioID = 13
  AND CursoID = 8;

EXEC usp_RegistrarIntentoEvaluacion
    @InscripcionID = @InscripcionIntegracion,
    @Nota = 85,
    @IntentoID = @IntentoIDIntegracion OUTPUT,
    @NumeroIntento = @NumeroIntentoIntegracion OUTPUT;

SELECT
    @IntentoIDIntegracion AS IntentoID,
    @NumeroIntentoIntegracion AS NumeroIntento;
GO



/* ============================================================
   PASO 7
   VERIFICACION FINAL DE INTEGRACION
   ============================================================ */

DECLARE @InscripcionIntegracion INT;

SELECT
    @InscripcionIntegracion = MAX(InscripcionID)
FROM INSCRIPCION
WHERE UsuarioID = 13
  AND CursoID = 8;


-- Inscripcion debe estar COMPLETADA
SELECT
    InscripcionID,
    UsuarioID,
    CursoID,
    Estado,
    FechaInscripcion,
    FechaCompletado,
    PrecioPagado,
    PorcentajeComiAplicado,
    Liquidada
FROM INSCRIPCION
WHERE InscripcionID = @InscripcionIntegracion;


-- Progreso debe ser 100%
SELECT *
FROM vw_HistorialProgreso
WHERE InscripcionID = @InscripcionIntegracion;


-- Evaluacion
SELECT
    IntentoID,
    InscripcionID,
    NumeroIntento,
    Nota,
    FechaIntento
FROM INTENTOEVALUACION
WHERE InscripcionID = @InscripcionIntegracion
ORDER BY NumeroIntento;


-- Certificado generado automaticamente
SELECT
    Anio,
    Correlativo,
    InscripcionID,
    CodigoCertificado,
    Estado,
    MotivoRevision,
    FechaEmision
FROM CERTIFICADO
WHERE InscripcionID = @InscripcionIntegracion;


-- Notificacion del certificado
SELECT
    NotificacionID,
    UsuarioID,
    CursoID,
    Tipo,
    Asunto,
    Mensaje,
    FechaCreacion,
    Estado
FROM NOTIFICACION
WHERE UsuarioID = 13
  AND CursoID = 8
  AND Tipo = 'CERTIFICADO_EMITIDO';


-- Billetera final
SELECT
    BilleteraID,
    UsuarioID,
    Saldo,
    FechaActualizacion
FROM BILLETERA
WHERE UsuarioID = 13;


-- Trazabilidad del cobro
SELECT O.*
FROM OPERACIONBILLETERA O
INNER JOIN BILLETERA B
    ON B.BilleteraID = O.BilleteraID
WHERE B.UsuarioID = 13
  AND O.InscripcionID = @InscripcionIntegracion;
GO