USE EDUGT;
GO
 
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
 
-- Índice para evitar dos inscripciones activas del mismo estudiante en el mismo curso
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE name = 'UX_Inscripcion_Activa'
                 AND object_id = OBJECT_ID('INSCRIPCION'))
    CREATE UNIQUE INDEX UX_Inscripcion_Activa
    ON INSCRIPCION (UsuarioID, CursoID)
    WHERE Estado = 'ACTIVA';
GO
 
-- Procedimiento para emitir un certificado
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
 
-- Procedimiento para registrar un intento de evaluación final
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