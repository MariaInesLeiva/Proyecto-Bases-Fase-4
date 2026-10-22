-- Persona 1

-- Procedimiento de solicitud de reembolso
create or alter procedure usp_SolicitarReembolso
    @InscripcionID int,
    @Motivo nvarchar(500),
    @ReembolsoID int output
as
begin

    set nocount on;

    declare @EstadoInscripcion varchar(15);
    declare @PoliticaID int;
    declare @FechaInscripcion datetime;
    declare @DiasLimite int;
    declare @PorcentajeMax decimal(5,2);
    declare @TotalModulos int;
    declare @ModulosCompletados int;
    declare @PorcentajeAvance decimal(5,2);

    begin try

        if not exists (
            select 1
            from INSCRIPCION
            where InscripcionID = @InscripcionID
        )
        begin
            throw 51401, 'La inscripcion indicada no existe.', 1;
        end

        select
            @EstadoInscripcion = Estado,
            @PoliticaID = PoliticaID,
            @FechaInscripcion = FechaInscripcion
        from INSCRIPCION
        where InscripcionID = @InscripcionID;

        if @EstadoInscripcion <> 'ACTIVA'
        begin
            throw 51402, 'La inscripcion no se encuentra activa.', 1;
        end

        if @Motivo is null or ltrim(rtrim(@Motivo)) = ''
        begin
            throw 51403, 'Debe indicar el motivo del reembolso.', 1;
        end

        if exists (
            select 1
            from SOLICITUDREEMBOLSO
            where InscripcionID = @InscripcionID
            and Estado in ('SOLICITADO', 'APROBADO', 'EJECUTADO')
        )
        begin
            throw 51404, 'Ya existe una solicitud de reembolso para esta inscripcion.', 1;
        end

        select
            @DiasLimite = DiasLimite,
            @PorcentajeMax = PorcentajeMax
        from POLITICAREEMBOLSO
        where PoliticaID = @PoliticaID;

        if @DiasLimite is null
        begin
            throw 51405, 'No se encontro la politica de reembolso de la inscripcion.', 1;
        end

        if datediff(
            day,
            cast(@FechaInscripcion as date),
            cast(getdate() as date)
        ) > @DiasLimite
        begin
            throw 51406, 'La solicitud se encuentra fuera del plazo permitido.', 1;
        end

        select @TotalModulos = count(*)
        from MODULO
        where CursoID = (
            select CursoID
            from INSCRIPCION
            where InscripcionID = @InscripcionID
        );

        select @ModulosCompletados = count(*)
        from AVANCEMODULO
        where InscripcionID = @InscripcionID;

        if @TotalModulos = 0
            set @PorcentajeAvance = 0;
        else
            set @PorcentajeAvance =
                (@ModulosCompletados * 100.0) / @TotalModulos;

        if @PorcentajeAvance >= @PorcentajeMax
        begin
            throw 51407, 'El progreso supera el limite permitido para reembolso.', 1;
        end

        if exists (
            select 1
            from CERTIFICADO
            where InscripcionID = @InscripcionID
        )
        begin
            throw 51408, 'La inscripcion ya tiene un certificado emitido.', 1;
        end

        insert into SOLICITUDREEMBOLSO
        (
            InscripcionID,
            Motivo,
            PorcentajeAvance,
            Estado
        )
        values
        (
            @InscripcionID,
            @Motivo,
            @PorcentajeAvance,
            'SOLICITADO'
        );

        set @ReembolsoID = scope_identity();

        select
            @ReembolsoID as ReembolsoID,
            @InscripcionID as InscripcionID,
            @PorcentajeAvance as PorcentajeAvance,
            @DiasLimite as DiasLimite,
            @PorcentajeMax as PorcentajeMax,
            'SOLICITADO' as Estado;

    end try

    begin catch

        throw;

    end catch

end;
go



-- Persona 2

-- Procedimiento para procesar un reembolso
CREATE OR ALTER PROCEDURE usp_ProcesarReembolso
	@ReembolsoID INT,
	@PersonaAutoriza INT
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @InscripcionID INT;
	DECLARE @Estado VARCHAR(20);
	DECLARE @PoliticaID INT;
	DECLARE @FechaInscripcion DATETIME;
	DECLARE @DiasLimite INT;
	DECLARE @FechaSolicitud DATETIME;
	DECLARE @PorcentajeAvance DECIMAL(5,2);
	DECLARE @PorcentajeMax DECIMAL(5,2);
	DECLARE @MontoReembolso DECIMAL(10,2);
	DECLARE @UsuarioID INT;
	DECLARE @BilleteraID INT;
	DECLARE @Liquidada BIT;
	DECLARE @CohorteID INT;
    DECLARE @CursoID INT;
    DECLARE @TotalModulos INT;
    DECLARE @ModulosCompletados INT;

	BEGIN TRY
    BEGIN TRANSACTION;

	IF NOT EXISTS
    (
        SELECT 1
        FROM TRABAJADOR
        WHERE TrabajadorID = @PersonaAutoriza
    )
    BEGIN
        THROW 51510, 'La persona que autoriza no existe', 1;
    END;

	SELECT @InscripcionID = InscripcionID, 
		@Estado = Estado,
		@FechaSolicitud = FechaSolicitud
	FROM SOLICITUDREEMBOLSO WITH (UPDLOCK)
	WHERE ReembolsoID = @ReembolsoID;

	IF @InscripcionID IS NULL
    BEGIN
        THROW 51501, 'El reembolso no existe', 1;
    END;
	
	IF @Estado <> 'SOLICITADO'
	BEGIN
		THROW 50002, 'El reembolso no ha sido solicitado', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1
		FROM INSCRIPCION WITH (UPDLOCK)
		WHERE InscripcionID = @InscripcionID AND Estado = 'ACTIVA'
	)
	BEGIN
		THROW 50003, 'La inscripción no existe o no está activa', 1;
	END;

	SELECT @PoliticaID = PoliticaID, 
		@FechaInscripcion = FechaInscripcion
	FROM INSCRIPCION
	WHERE InscripcionID = @InscripcionID;

	SELECT @DiasLimite = DiasLimite
	FROM POLITICAREEMBOLSO
	WHERE PoliticaID = @PoliticaID;

	IF DATEDIFF(DAY, @FechaInscripcion, @FechaSolicitud) > @DiasLimite
	BEGIN
		THROW 50004, 'Ya ha vencido el plazo para solicitar el reembolso', 1;
	END;

	SELECT @CursoID = CursoID
	FROM INSCRIPCION
	WHERE InscripcionID = @InscripcionID;

	SELECT @TotalModulos = COUNT(*)
	FROM MODULO
	WHERE CursoID = @CursoID;

	SELECT @ModulosCompletados = COUNT(*)
	FROM AVANCEMODULO A
	INNER JOIN MODULO M
		ON A.ModuloID = M.ModuloID
	WHERE A.InscripcionID = @InscripcionID
		AND M.CursoID = @CursoID;

	SET @PorcentajeAvance =
		CASE
			WHEN @TotalModulos = 0 THEN 0
			ELSE @ModulosCompletados * 100.0 / @TotalModulos
		END;

	SELECT @PorcentajeMax = PorcentajeMax
	FROM POLITICAREEMBOLSO
	WHERE PoliticaID = @PoliticaID;

	IF @PorcentajeAvance >= @PorcentajeMax
	BEGIN
		THROW 50005, 'El avance del estudiante ya superó el porcentaje permitido', 1;
	END;

	IF EXISTS 
	(
		SELECT 1
		FROM CERTIFICADO
		WHERE InscripcionID = @InscripcionID
	)
	BEGIN
		THROW 50006, 'El estudiante ya tiene un certificado emitido', 1;
	END;

		SELECT @MontoReembolso = PrecioPagado, 
			@UsuarioID = UsuarioID,
			@Liquidada = Liquidada,
			@CohorteID =  CohorteID
		FROM INSCRIPCION
		WHERE InscripcionID = @InscripcionID;

		IF @CohorteID IS NOT NULL
		BEGIN
			IF NOT EXISTS
			(
				SELECT 1
				FROM COHORTE WITH (UPDLOCK)
				WHERE CohorteID = @CohorteID
			)
			BEGIN
				THROW 51511, 'La cohorte no existe', 1;
			END;
		END;

		SELECT @BilleteraID = BilleteraID
		FROM BILLETERA
		WHERE UsuarioID = @UsuarioID;

		UPDATE BILLETERA
		SET Saldo = Saldo + @MontoReembolso,
			FechaActualizacion = GETDATE()
		WHERE UsuarioID = @UsuarioID;

		IF @@ROWCOUNT <> 1
		BEGIN
			THROW 50007, 'No se encontró la billetera del estudiante', 1;
		END;

		INSERT INTO OPERACIONBILLETERA
		(
			BilleteraID,
			TipoOperacion,
			Monto,
			ReembolsoID,
			Descripcion
		)
		VALUES
		(
			@BilleteraID,
			'REEMBOLSO',
			@MontoReembolso,
			@ReembolsoID,
			'Devolución por reembolso de inscripción'
		);

		UPDATE INSCRIPCION
		SET Estado = 'REEMBOLSADA'
		WHERE InscripcionID = @InscripcionID
			AND Estado = 'ACTIVA';

		IF @@ROWCOUNT <> 1
		BEGIN
			THROW 50008, 'No se pudo actualizar la inscripción', 1;
		END;

		UPDATE SOLICITUDREEMBOLSO
		SET Estado = 'EJECUTADO',
			FechaDecision = GETDATE(),
			MontoReembolsado = @MontoReembolso,
			PersonaQueAutoriza = @PersonaAutoriza
		WHERE ReembolsoID = @ReembolsoID
			AND Estado = 'SOLICITADO';

		IF @@ROWCOUNT <> 1
		BEGIN
			THROW 50009, 'No se pudo actualizar la solicitud de reembolso', 1;
		END;

		IF @Liquidada = 1
		BEGIN
			INSERT INTO AJUSTECOMISION
			(
				ReembolsoID,
				InstructorID,
				MontoOriginal,
				MontoPendiente
			)
			SELECT
				@ReembolsoID,
				L.InstructorID,
				SUM(D.Monto),
				SUM(D.Monto)
			FROM DETALLELIQUIDACION D
			INNER JOIN LIQUIDACION L
				ON D.LiquidacionID = L.LiquidacionID
			WHERE D.InscripcionID = @InscripcionID
				AND D.TipoDetalle = 'COMISION'
				AND L.Estado = 'PAGADA'
			GROUP BY L.InstructorID;

			INSERT INTO NOTIFICACION
			(
				UsuarioID,
				Tipo,
				Asunto,
				Mensaje
			)
			SELECT
				A.InstructorID,
				'CONTRACARGO',
				'Ajuste de comisión por reembolso',
				'Se registró un ajuste pendiente sobre una comisión previamente pagada'
			FROM AJUSTECOMISION A
			WHERE A.ReembolsoID = @ReembolsoID;
		END;

		INSERT INTO NOTIFICACION
		(
			UsuarioID,
			Tipo,
			Asunto,
			Mensaje
		)
		VALUES
		(
			@UsuarioID,
			'REEMBOLSO',
			'Reembolso procesado',
			'La solicitud de reembolso ha sido aprobada y el dinero se ha devuelto a la billetera'
		);

    COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		IF XACT_STATE() <> 0
		BEGIN
		ROLLBACK TRANSACTION;
	END;

		THROW;
	END CATCH;

END;
GO






-- Persona 3
USE EDUGT;
GO

CREATE OR ALTER PROCEDURE usp_LiquidarPeriodo
    @PeriodoID INT,
    @FechaReferencia DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @Anio INT;
    DECLARE @Mes INT;
    DECLARE @Estado VARCHAR(15);
    DECLARE @FechaFin DATE;
    DECLARE @InscripcionID INT;
    DECLARE @UltimaInscripcionID INT;
    DECLARE @CursoID INT;
    DECLARE @PrecioPagado DECIMAL(10,2);
    DECLARE @PorcentajeComision DECIMAL(5,2);
    DECLARE @ComisionPlataforma DECIMAL(10,2);
    DECLARE @NetoInstructores DECIMAL(10,2);
    DECLARE @CantidadIntegrantes INT;
    DECLARE @CantidadPrincipales INT;
    DECLARE @CantidadNoInstructores INT;
    DECLARE @SumaPorcentajes DECIMAL(12,2);
    DECLARE @PrincipalID INT;
    DECLARE @InstructorID INT;
    DECLARE @UltimoInstructorID INT;
    DECLARE @PorcentajeParticipacion DECIMAL(5,2);
    DECLARE @MontoParticipante DECIMAL(10,2);
    DECLARE @SumaOtros DECIMAL(18,2);
    DECLARE @MontoPrincipal DECIMAL(10,2);
    DECLARE @LiquidacionID INT;
    DECLARE @UltimaLiquidacionID INT;
    DECLARE @TotalComisiones DECIMAL(18,2);
    DECLARE @Disponible DECIMAL(18,2);
    DECLARE @AjusteID INT;
    DECLARE @Pendiente DECIMAL(10,2);
    DECLARE @Aplicar DECIMAL(10,2);
    DECLARE @Pago DECIMAL(18,2);
    DECLARE @BilleteraID INT;
    DECLARE @InscripcionesProcesadas INT = 0;
    DECLARE @IngresoBrutoTotal DECIMAL(18,2) = 0;
    DECLARE @ComisionPlataformaTotal DECIMAL(18,2) = 0;
    DECLARE @ComisionesInstructoresTotal DECIMAL(18,2) = 0;
    DECLARE @AjustesTotal DECIMAL(18,2) = 0;
    DECLARE @PagosTotal DECIMAL(18,2) = 0;

    BEGIN TRY
        BEGIN TRANSACTION;

        -- 1. VALIDAR Y BLOQUEAR EL PERIODO.
        -- El bloqueo evita que dos personas lo liquiden a la vez.
        SELECT @Anio = Anio,
               @Mes = Mes,
               @Estado = Estado,
               @FechaFin = FechaFinPeriodo
        FROM PERIODOLIQUIDACION WITH (UPDLOCK, HOLDLOCK)
        WHERE PeriodoID = @PeriodoID;

        IF @Anio IS NULL
            THROW 51601, 'El periodo solicitado no existe.', 1;

        IF @Estado <> 'ABIERTO'
            THROW 51602, 'El periodo ya se cerro o no esta abierto.', 1;

        -- Se utiliza la fecha de referencia si fue proporcionada.
        -- Si es NULL, se utiliza la fecha actual del sistema.
        IF @FechaFin >= ISNULL(@FechaReferencia, CAST(GETDATE() AS DATE))
            THROW 51603, 'El periodo todavia no ha finalizado.', 1;

        IF EXISTS (SELECT 1 FROM LIQUIDACION WHERE PeriodoID = @PeriodoID)
            THROW 51605, 'El periodo ya tiene liquidaciones registradas.', 1;

        UPDATE PERIODOLIQUIDACION
        SET Estado = 'EN_PROCESO'
        WHERE PeriodoID = @PeriodoID AND Estado = 'ABIERTO';

        IF @@ROWCOUNT <> 1
            THROW 51606, 'No se pudo iniciar la liquidacion.', 1;

        -- 2. RECORRER INSCRIPCIONES DEL MES.
        SET @UltimaInscripcionID = 0;

        SELECT @InscripcionID = MIN(InscripcionID)
        FROM INSCRIPCION WITH (UPDLOCK, HOLDLOCK)
        WHERE YEAR(FechaInscripcion) = @Anio
          AND MONTH(FechaInscripcion) = @Mes
          AND Estado IN ('ACTIVA', 'COMPLETADA')
          AND Liquidada = 0
          AND InscripcionID > @UltimaInscripcionID;

        WHILE @InscripcionID IS NOT NULL
        BEGIN
            SELECT @CursoID = CursoID,
                   @PrecioPagado = PrecioPagado,
                   @PorcentajeComision = PorcentajeComiAplicado
            FROM INSCRIPCION WITH (UPDLOCK, HOLDLOCK)
            WHERE InscripcionID = @InscripcionID
              AND Estado IN ('ACTIVA', 'COMPLETADA')
              AND Liquidada = 0;

            IF @@ROWCOUNT <> 1
                THROW 51616, 'La inscripcion cambio durante la liquidacion.', 1;

            -- 3. CALCULAR LA PARTE DE LA PLATAFORMA Y EL NETO.
            -- Se toma la comision historica guardada en INSCRIPCION.
            SET @ComisionPlataforma = ROUND(@PrecioPagado * @PorcentajeComision / 100.00, 2);
            SET @NetoInstructores = @PrecioPagado - @ComisionPlataforma;

            -- 4. VALIDAR QUE EL EQUIPO SUME 100% Y TENGA UN PRINCIPAL.
            SELECT @CantidadIntegrantes = COUNT(*),
                   @SumaPorcentajes = ISNULL(SUM(PorcentajeParticipacion), 0),
                   @CantidadPrincipales = ISNULL(SUM(CASE WHEN EsPrincipal = 1 THEN 1 ELSE 0 END), 0)
            FROM EQUIPOCURSO WITH (UPDLOCK, HOLDLOCK)
            WHERE CursoID = @CursoID;

            SELECT @CantidadNoInstructores = COUNT(*)
            FROM EQUIPOCURSO
            INNER JOIN TRABAJADOR
                ON EQUIPOCURSO.InstructorID = TRABAJADOR.TrabajadorID
            WHERE EQUIPOCURSO.CursoID = @CursoID
              AND TRABAJADOR.TipoTrabajador <> 'INSTRUCTOR';

            IF @CantidadIntegrantes = 0 OR @SumaPorcentajes <> 100
               OR @CantidadPrincipales <> 1 OR @CantidadNoInstructores > 0
                THROW 51607, 'El equipo del curso debe tener un principal y sumar 100 por ciento.', 1;

            SELECT @PrincipalID = InstructorID
            FROM EQUIPOCURSO
            WHERE CursoID = @CursoID AND EsPrincipal = 1;

            -- 5. PAGAR LAS PARTES DE LOS CO-INSTRUCTORES.
            SET @SumaOtros = 0;
            SET @UltimoInstructorID = 0;

            SELECT @InstructorID = MIN(InstructorID)
            FROM EQUIPOCURSO WITH (UPDLOCK, HOLDLOCK)
            WHERE CursoID = @CursoID
              AND EsPrincipal = 0
              AND InstructorID > @UltimoInstructorID;

            WHILE @InstructorID IS NOT NULL
            BEGIN
                SELECT @PorcentajeParticipacion = PorcentajeParticipacion
                FROM EQUIPOCURSO
                WHERE CursoID = @CursoID AND InstructorID = @InstructorID;

                SET @MontoParticipante = ROUND(@NetoInstructores * @PorcentajeParticipacion / 100.00, 2);
                SET @SumaOtros = @SumaOtros + @MontoParticipante;

                IF @MontoParticipante > 0
                BEGIN
                    -- Se crea solo UNA LIQUIDACION por instructor y periodo.
                    SET @LiquidacionID = NULL;
                    SELECT @LiquidacionID = LiquidacionID
                    FROM LIQUIDACION
                    WHERE PeriodoID = @PeriodoID AND InstructorID = @InstructorID;

                    IF @LiquidacionID IS NULL
                    BEGIN
                        INSERT INTO LIQUIDACION (PeriodoID, InstructorID, Estado)
                        VALUES (@PeriodoID, @InstructorID, 'CALCULADA');

                        SET @LiquidacionID = SCOPE_IDENTITY();
                    END;

                    INSERT INTO DETALLELIQUIDACION
                        (LiquidacionID, TipoDetalle, InscripcionID, AjusteID, PorcentajeParticipacion, Monto)
                    VALUES
                        (@LiquidacionID, 'COMISION', @InscripcionID, NULL,
                         @PorcentajeParticipacion, @MontoParticipante);
                END;

                SET @UltimoInstructorID = @InstructorID;
                SET @InstructorID = NULL;

                SELECT @InstructorID = MIN(InstructorID)
                FROM EQUIPOCURSO WITH (UPDLOCK, HOLDLOCK)
                WHERE CursoID = @CursoID
                  AND EsPrincipal = 0
                  AND InstructorID > @UltimoInstructorID;
            END;

            -- El principal recibe lo que queda: incluye centavos de redondeo.
            IF @SumaOtros > @NetoInstructores
                THROW 51608, 'El redondeo de co-instructores supera el neto.', 1;

            SET @MontoPrincipal = @NetoInstructores - @SumaOtros;

            IF @MontoPrincipal > 0
            BEGIN
                SET @LiquidacionID = NULL;
                SELECT @LiquidacionID = LiquidacionID
                FROM LIQUIDACION
                WHERE PeriodoID = @PeriodoID AND InstructorID = @PrincipalID;

                IF @LiquidacionID IS NULL
                BEGIN
                    INSERT INTO LIQUIDACION (PeriodoID, InstructorID, Estado)
                    VALUES (@PeriodoID, @PrincipalID, 'CALCULADA');

                    SET @LiquidacionID = SCOPE_IDENTITY();
                END;

                SELECT @PorcentajeParticipacion = PorcentajeParticipacion
                FROM EQUIPOCURSO
                WHERE CursoID = @CursoID AND InstructorID = @PrincipalID;

                INSERT INTO DETALLELIQUIDACION
                    (LiquidacionID, TipoDetalle, InscripcionID, AjusteID, PorcentajeParticipacion, Monto)
                VALUES
                    (@LiquidacionID, 'COMISION', @InscripcionID, NULL,
                     @PorcentajeParticipacion, @MontoPrincipal);
            END;

            -- Comprobacion del cuadre: plataforma + reparto = precio.
            IF @ComisionPlataforma + @SumaOtros + @MontoPrincipal <> @PrecioPagado
                THROW 51609, 'La distribucion no cuadra con el precio pagado.', 1;

            UPDATE INSCRIPCION
            SET Liquidada = 1
            WHERE InscripcionID = @InscripcionID
              AND Liquidada = 0
              AND Estado IN ('ACTIVA', 'COMPLETADA');

            IF @@ROWCOUNT <> 1
                THROW 51614, 'No se pudo marcar la inscripcion como liquidada.', 1;

            SET @InscripcionesProcesadas = @InscripcionesProcesadas + 1;
            SET @IngresoBrutoTotal = @IngresoBrutoTotal + @PrecioPagado;
            SET @ComisionPlataformaTotal = @ComisionPlataformaTotal + @ComisionPlataforma;
            SET @ComisionesInstructoresTotal = @ComisionesInstructoresTotal + @NetoInstructores;

            SET @UltimaInscripcionID = @InscripcionID;
            SET @InscripcionID = NULL;

            SELECT @InscripcionID = MIN(InscripcionID)
            FROM INSCRIPCION WITH (UPDLOCK, HOLDLOCK)
            WHERE YEAR(FechaInscripcion) = @Anio
              AND MONTH(FechaInscripcion) = @Mes
              AND Estado IN ('ACTIVA', 'COMPLETADA')
              AND Liquidada = 0
              AND InscripcionID > @UltimaInscripcionID;
        END;

        -- 6. RECORRER LAS LIQUIDACIONES DE LOS INSTRUCTORES.
        -- Aqui se aplican los contracargos pendientes y se pagan billeteras.
        SET @UltimaLiquidacionID = 0;

        SELECT @LiquidacionID = MIN(LiquidacionID)
        FROM LIQUIDACION
        WHERE PeriodoID = @PeriodoID
          AND LiquidacionID > @UltimaLiquidacionID;

        WHILE @LiquidacionID IS NOT NULL
        BEGIN
            SELECT @InstructorID = InstructorID
            FROM LIQUIDACION
            WHERE LiquidacionID = @LiquidacionID;

            SELECT @TotalComisiones = ISNULL(SUM(Monto), 0)
            FROM DETALLELIQUIDACION
            WHERE LiquidacionID = @LiquidacionID AND TipoDetalle = 'COMISION';

            SET @Disponible = @TotalComisiones;

            -- 7. DESCONTAR AJUSTES, DEL MAS ANTIGUO AL MAS NUEVO.
            SET @AjusteID = NULL;
            SELECT TOP 1 @AjusteID = AjusteID
            FROM AJUSTECOMISION WITH (UPDLOCK, HOLDLOCK)
            WHERE InstructorID = @InstructorID AND MontoPendiente > 0
            ORDER BY FechaGeneracion, AjusteID;

            WHILE @AjusteID IS NOT NULL AND @Disponible > 0
            BEGIN
                SELECT @Pendiente = MontoPendiente
                FROM AJUSTECOMISION WITH (UPDLOCK, HOLDLOCK)
                WHERE AjusteID = @AjusteID;

                IF @Pendiente <= @Disponible
                    SET @Aplicar = @Pendiente;
                ELSE
                    SET @Aplicar = @Disponible;

                -- Nunca descontar mas de lo ganado en este periodo.
                UPDATE AJUSTECOMISION
                SET MontoPendiente = MontoPendiente - @Aplicar
                WHERE AjusteID = @AjusteID AND MontoPendiente >= @Aplicar;

                IF @@ROWCOUNT <> 1
                    THROW 51612, 'No fue posible actualizar un ajuste de comision.', 1;

                INSERT INTO DETALLELIQUIDACION
                    (LiquidacionID, TipoDetalle, InscripcionID, AjusteID, PorcentajeParticipacion, Monto)
                VALUES
                    (@LiquidacionID, 'AJUSTE', NULL, @AjusteID, NULL, -@Aplicar);

                SET @Disponible = @Disponible - @Aplicar;
                SET @AjustesTotal = @AjustesTotal + @Aplicar;
                SET @AjusteID = NULL;

                SELECT TOP 1 @AjusteID = AjusteID
                FROM AJUSTECOMISION WITH (UPDLOCK, HOLDLOCK)
                WHERE InstructorID = @InstructorID AND MontoPendiente > 0
                ORDER BY FechaGeneracion, AjusteID;
            END;

            SET @Pago = @Disponible;

            IF @Pago < 0
                THROW 51611, 'El pago a un instructor no puede ser negativo.', 1;

            -- 8. TRANSFERIR A BILLETERA (solo si el pago es mayor que Q0).
            SET @BilleteraID = NULL;
            SELECT @BilleteraID = BilleteraID
            FROM BILLETERA WITH (UPDLOCK, HOLDLOCK)
            WHERE UsuarioID = @InstructorID;

            IF @BilleteraID IS NULL
                THROW 51610, 'Un instructor no tiene billetera.', 1;

            IF @Pago > 0
            BEGIN
                UPDATE BILLETERA
                SET Saldo = Saldo + @Pago,
                    FechaActualizacion = GETDATE()
                WHERE BilleteraID = @BilleteraID;

                IF @@ROWCOUNT <> 1
                    THROW 51613, 'No se pudo acreditar la billetera del instructor.', 1;

                INSERT INTO OPERACIONBILLETERA
                    (BilleteraID, TipoOperacion, Monto, LiquidacionID, Descripcion)
                VALUES
                    (@BilleteraID, 'PAGO_COMISION', @Pago, @LiquidacionID,
                     N'Liquidacion de comisiones de periodo');
            END;

            UPDATE LIQUIDACION
            SET Estado = 'PAGADA'
            WHERE LiquidacionID = @LiquidacionID AND Estado = 'CALCULADA';

            IF @@ROWCOUNT <> 1
                THROW 51617, 'No se pudo marcar la liquidacion como pagada.', 1;

            SET @PagosTotal = @PagosTotal + @Pago;
            SET @UltimaLiquidacionID = @LiquidacionID;
            SET @LiquidacionID = NULL;

            SELECT @LiquidacionID = MIN(LiquidacionID)
            FROM LIQUIDACION
            WHERE PeriodoID = @PeriodoID
              AND LiquidacionID > @UltimaLiquidacionID;
        END;

        -- 9. CERRAR EL PERIODO SOLO SI TODO SALIO BIEN.
        UPDATE PERIODOLIQUIDACION
        SET Estado = 'CERRADO'
        WHERE PeriodoID = @PeriodoID AND Estado = 'EN_PROCESO';

        IF @@ROWCOUNT <> 1
            THROW 51615, 'No se pudo cerrar el periodo.', 1;

        COMMIT TRANSACTION;

        -- Resultado resumido de la ejecucion.
        SELECT @PeriodoID AS PeriodoID,
               @Anio AS Anio,
               @Mes AS Mes,
               @InscripcionesProcesadas AS InscripcionesLiquidadas,
               @IngresoBrutoTotal AS IngresoBruto,
               @ComisionPlataformaTotal AS ComisionPlataforma,
               @ComisionesInstructoresTotal AS ComisionesInstructores,
               @AjustesTotal AS AjustesAplicados,
               @PagosTotal AS PagadoInstructores,
               'CERRADO' AS EstadoPeriodo;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;

        THROW;
    END CATCH;
END;
GO






-- Persona 4
CREATE OR ALTER PROCEDURE usp_ProcesarPeriodosPendientes
    @FechaReferencia DATE = NULL
AS
BEGIN
    SET NOCOUNT ON
 
    DECLARE @PeriodoID INT
    DECLARE @Anio INT
    DECLARE @Mes INT
    DECLARE @InicioMes DATE
    DECLARE @Resumenes INT
    DECLARE @SinVentas INT
    DECLARE @Resultado TABLE
    (
        PeriodoID INT,
        Anio INT,
        Mes INT,
        Resultado VARCHAR(15),
        NotificacionesResumen INT,
        NotificacionesSinVentas INT,
        Detalle NVARCHAR(4000)
    )
 
    IF @FechaReferencia IS NULL
        SET @FechaReferencia = CAST(GETDATE() AS DATE)
 
    DECLARE curPeriodos CURSOR LOCAL FAST_FORWARD FOR
        SELECT PeriodoID, Anio, Mes
        FROM PERIODOLIQUIDACION
        WHERE Estado = 'ABIERTO'
          AND FechaFinPeriodo < @FechaReferencia
        ORDER BY Anio, Mes
 
    OPEN curPeriodos
    FETCH NEXT FROM curPeriodos INTO @PeriodoID, @Anio, @Mes
 
    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRY
            SET @InicioMes = DATEFROMPARTS(@Anio, @Mes, 1)
 
            EXEC usp_LiquidarPeriodo
                @PeriodoID = @PeriodoID,
                @FechaReferencia = @FechaReferencia
 
            INSERT INTO NOTIFICACION (UsuarioID, Tipo, Asunto, Mensaje)
            SELECT L.InstructorID, 'RESUMEN_LIQUIDACION',
                   N'Resumen de liquidacion del periodo',
                   CONCAT(N'Periodo ', @Mes, N'/', @Anio,
                          N'. Inscripciones: ', R.Inscripciones,
                          N'. Ingreso bruto: Q', R.IngresoBruto,
                          N'. Comision plataforma: Q', R.ComisionPlataforma,
                          N'. Tus comisiones: Q', R.Comisiones,
                          N'. Reembolsos aplicados: ', R.Reembolsos,
                          N' por Q', R.Ajustes,
                          N'. Monto neto recibido: Q', R.Comisiones - R.Ajustes, N'.')
            FROM LIQUIDACION L
            CROSS APPLY
            (
                SELECT COUNT(DISTINCT D.InscripcionID) AS Inscripciones,
                       CAST(ISNULL(SUM(I.PrecioPagado), 0) AS DECIMAL(12,2)) AS IngresoBruto,
                       CAST(ISNULL(SUM(ROUND(I.PrecioPagado * I.PorcentajeComiAplicado / 100.00, 2)), 0)
                            AS DECIMAL(12,2)) AS ComisionPlataforma,
                       CAST(ISNULL(SUM(CASE WHEN D.TipoDetalle = 'COMISION' THEN D.Monto END), 0)
                            AS DECIMAL(12,2)) AS Comisiones,
                       COUNT(D.AjusteID) AS Reembolsos,
                       CAST(ISNULL(-SUM(CASE WHEN D.TipoDetalle = 'AJUSTE' THEN D.Monto END), 0)
                            AS DECIMAL(12,2)) AS Ajustes
                FROM DETALLELIQUIDACION D
                LEFT JOIN INSCRIPCION I
                    ON I.InscripcionID = D.InscripcionID
                WHERE D.LiquidacionID = L.LiquidacionID
            ) R
            WHERE L.PeriodoID = @PeriodoID
 
            SET @Resumenes = @@ROWCOUNT
 
            INSERT INTO NOTIFICACION (UsuarioID, CursoID, Tipo, Asunto, Mensaje)
            SELECT EC.InstructorID, C.CursoID, 'CURSO_SIN_COMISIONES',
                   N'Curso sin comisiones en el periodo',
                   CONCAT(N'Tu curso "', C.Titulo, N'" no genero comisiones en el periodo ',
                          @Mes, N'/', @Anio,
                          N'. Te invitamos a revisar el precio o la promocion de tu curso.')
            FROM CURSO C
            INNER JOIN EQUIPOCURSO EC
                ON EC.CursoID = C.CursoID
            WHERE C.Estado = 'DISPONIBLE'
              AND C.FechaPublicacion < DATEADD(MONTH, 1, @InicioMes)
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM INSCRIPCION I
                  WHERE I.CursoID = C.CursoID
                    AND I.Estado <> 'REEMBOLSADA'
                    AND I.FechaInscripcion >= @InicioMes
                    AND I.FechaInscripcion < DATEADD(MONTH, 1, @InicioMes)
              )
 
            SET @SinVentas = @@ROWCOUNT
 
            INSERT INTO @Resultado
            VALUES (@PeriodoID, @Anio, @Mes, 'PROCESADO', @Resumenes, @SinVentas, NULL)
        END TRY
        BEGIN CATCH
            IF XACT_STATE() <> 0
                ROLLBACK
 
            INSERT INTO @Resultado
            VALUES (@PeriodoID, @Anio, @Mes, 'ERROR', NULL, NULL,
                    CONCAT(ERROR_NUMBER(), N': ', ERROR_MESSAGE()))
        END CATCH
 
        FETCH NEXT FROM curPeriodos INTO @PeriodoID, @Anio, @Mes
    END
 
    CLOSE curPeriodos
    DEALLOCATE curPeriodos
 
    SELECT * FROM @Resultado
END
GO








--------------------------------------------------------------------------------------------------------------------------------------------------------
-- Reportes


-- Vista Persona 4
CREATE OR ALTER VIEW vw_CrecimientoInstructores
AS
WITH InscMes AS
(
    SELECT CursoID,
           DATEFROMPARTS(YEAR(FechaInscripcion), MONTH(FechaInscripcion), 1) AS Mes,
           COUNT(*) AS Cantidad
    FROM INSCRIPCION
    WHERE Estado <> 'REEMBOLSADA'
    GROUP BY CursoID,
             DATEFROMPARTS(YEAR(FechaInscripcion), MONTH(FechaInscripcion), 1)
),
Rango AS
(
    SELECT CursoID,
           MIN(Mes) AS PrimerMes,
           MAX(Mes) AS UltimoMes
    FROM InscMes
    GROUP BY CursoID
),
Meses AS
(
    SELECT CursoID, PrimerMes AS Mes, UltimoMes, 1 AS NumMes
    FROM Rango

    UNION ALL

    SELECT CursoID, DATEADD(MONTH, 1, Mes), UltimoMes, NumMes + 1
    FROM Meses
    WHERE Mes < UltimoMes
),
Serie AS
(
    SELECT M.CursoID,
           CAST(M.NumMes AS FLOAT) AS X,
           CAST(ISNULL(IM.Cantidad, 0) AS FLOAT) AS Y
    FROM Meses M
    LEFT JOIN InscMes IM
        ON IM.CursoID = M.CursoID
       AND IM.Mes = M.Mes
),
Estadisticas AS
(
    SELECT CursoID,
           COUNT(*) AS N,
           SUM(X) AS SX,
           SUM(Y) AS SY,
           SUM(X * Y) AS SXY,
           SUM(X * X) AS SXX,
           SUM(Y * Y) AS SYY,
           STDEV(Y) AS Volatilidad
    FROM Serie
    GROUP BY CursoID
),
CursosPublicados AS
(
    SELECT EC.InstructorID,
           COUNT(*) AS Publicados
    FROM EQUIPOCURSO EC
    INNER JOIN CURSO C
        ON C.CursoID = EC.CursoID
    WHERE C.FechaPublicacion IS NOT NULL
    GROUP BY EC.InstructorID
),
Base AS
(
    SELECT U.Nombre + ' ' + U.Apellido AS Instructor,
           C.Titulo AS Curso,
           CA.NombreCategoria AS Categoria,
           CASE WHEN EC.EsPrincipal = 1 THEN 'Principal' ELSE 'Co-instructor' END AS Rol,
           R.PrimerMes,
           R.UltimoMes,
           P.Cantidad AS InscPrimerMes,
           UM.Cantidad AS InscUltimoMes,
           E.N AS MesesAnalizados,
           E.Volatilidad,
           (E.N * E.SXY - E.SX * E.SY)
             / NULLIF(SQRT((E.N * E.SXX - E.SX * E.SX) * (E.N * E.SYY - E.SY * E.SY)), 0) AS Correlacion,
           ISNULL(CP.Publicados, 0) AS CursosPublicados
    FROM EQUIPOCURSO EC
    INNER JOIN USUARIO U       ON U.UsuarioID = EC.InstructorID
    INNER JOIN CURSO C         ON C.CursoID = EC.CursoID
    INNER JOIN CATEGORIA CA    ON CA.CategoriaID = C.CategoriaID
    INNER JOIN Rango R         ON R.CursoID = EC.CursoID
    INNER JOIN InscMes P       ON P.CursoID = EC.CursoID AND P.Mes = R.PrimerMes
    INNER JOIN InscMes UM      ON UM.CursoID = EC.CursoID AND UM.Mes = R.UltimoMes
    INNER JOIN Estadisticas E  ON E.CursoID = EC.CursoID
    LEFT JOIN CursosPublicados CP ON CP.InstructorID = EC.InstructorID
)
SELECT Instructor,
       Curso,
       Categoria,
       Rol,
       FORMAT(PrimerMes, 'yyyy-MM') AS PrimerMes,
       FORMAT(UltimoMes, 'yyyy-MM') AS UltimoMes,
       InscPrimerMes,
       InscUltimoMes,
       CAST(CASE WHEN MesesAnalizados > 1
                 THEN (InscUltimoMes - InscPrimerMes) * 100.0 / InscPrimerMes
            END AS DECIMAL(10,2)) AS PorcentajeCrecimiento,
       CAST(Correlacion AS DECIMAL(5,4)) AS CorrelacionTiempoPopularidad,
       CASE
           WHEN Correlacion IS NULL THEN 'Datos insuficientes'
           WHEN Correlacion > 0 THEN 'Creciente'
           WHEN Correlacion < 0 THEN 'Decreciente'
           ELSE 'Estable'
       END AS Tendencia,
       CAST(Volatilidad AS DECIMAL(10,2)) AS VolatilidadMensual,
       MesesAnalizados,
       CursosPublicados
FROM Base
GO



------------------------------------------------------------------------------------------------------------------------------------------------------------
--REPORTES

-- Consulta analitica 1: Eficiencia del comite academico
-- Analiza el volumen, tiempo y resultados de las revisiones por revisor.

select
    U.Nombre + ' ' + U.Apellido as Revisor,
    count(R.RevisionID) as CursosRevisados,

    cast(
        avg(
            datediff(minute, R.FechaInicio, R.FechaFin) / 60.0
        )
        as decimal(10,2)
    ) as TiempoPromedioHoras,

    sum(case
        when R.Resultado = 'APROBADO' then 1
        else 0
    end) as CursosAprobados,

    sum(case
        when R.Resultado = 'RECHAZADO' then 1
        else 0
    end) as CursosRechazados,

    cast(
        sum(case
            when R.Resultado = 'RECHAZADO' then 1
            else 0
        end) * 100.0
        / nullif(count(R.RevisionID), 0)
        as decimal(5,2)
    ) as TasaRechazo

from REVISIONACADEMICA R

inner join TRABAJADOR T
    on R.RevisorID = T.TrabajadorID

inner join USUARIO U
    on T.TrabajadorID = U.UsuarioID

where R.Resultado in ('APROBADO', 'RECHAZADO')
and R.FechaFin is not null

group by
    U.Nombre,
    U.Apellido

order by
    CursosRevisados desc;

--Indice sugerido
/*
create index IX_RevisionAcademica_RevisorResultado
on REVISIONACADEMICA (RevisorID, Resultado)
include (FechaInicio, FechaFin);
*/



-- Reporte Persona 2
SELECT
    U.UsuarioID,
    U.Nombre,
    U.Apellido,
    U.Correo,
    U.FechaRegistro,
    COUNT(DISTINCT I.InscripcionID) AS Inscritos,
    COUNT(DISTINCT CASE
        WHEN I.Estado = 'COMPLETADA'
        THEN I.InscripcionID
    END) AS Completados,
    COUNT(DISTINCT C.CodigoCertificado) AS Certificados,
    ISNULL((
        SELECT SUM(L.DuracionMinutos) / 60.0
        FROM INSCRIPCION I2
        INNER JOIN AVANCEMODULO A
            ON I2.InscripcionID = A.InscripcionID
        INNER JOIN LECCION L
            ON A.ModuloID = L.ModuloID
        WHERE I2.UsuarioID = U.UsuarioID
    ), 0) AS HorasEstudio,

    CASE
        WHEN COUNT(DISTINCT I.InscripcionID) = 0 THEN 0
        ELSE
            COUNT(DISTINCT CASE
                WHEN I.Estado = 'COMPLETADA'
                THEN I.InscripcionID
            END) * 100.0
            / COUNT(DISTINCT I.InscripcionID)
    END AS TasaFinalizacion

FROM USUARIO U

LEFT JOIN INSCRIPCION I
    ON U.UsuarioID = I.UsuarioID

LEFT JOIN CERTIFICADO C
    ON I.InscripcionID = C.InscripcionID

WHERE U.TipoUsuario = 'ESTUDIANTE'

GROUP BY
    U.UsuarioID,
    U.Nombre,
    U.Apellido,
    U.Correo,
    U.FechaRegistro

ORDER BY U.Nombre, U.Apellido;

-- Indice sugerido
/*

CREATE OR ALTER INDEX ix_Inscripcion_Usuario_Estado
ON INSCRIPCION (UsuarioID, Estado)

*/ 



-- Reporte 4 / Persona 5
;WITH Meses AS (
    SELECT DATEFROMPARTS(YEAR(FechaPublicacion), MONTH(FechaPublicacion), 1) AS Mes
    FROM CURSO 
    WHERE FechaPublicacion IS NOT NULL
    UNION
    SELECT DATEFROMPARTS(YEAR(FechaInscripcion), MONTH(FechaInscripcion), 1)
    FROM INSCRIPCION
    UNION
    SELECT DATEFROMPARTS(YEAR(FechaEmision), MONTH(FechaEmision), 1)
    FROM CERTIFICADO),

CursosPublicados AS (
    SELECT DATEFROMPARTS(YEAR(FechaPublicacion), MONTH(FechaPublicacion), 1) AS Mes, COUNT(*) AS CursosPublicados
    FROM CURSO
    WHERE FechaPublicacion IS NOT NULL
    GROUP BY YEAR(FechaPublicacion), MONTH(FechaPublicacion)),

InstructoresPublicados AS (
    SELECT DATEFROMPARTS(YEAR(C.FechaPublicacion), MONTH(C.FechaPublicacion), 1) AS Mes, COUNT(DISTINCT EC.InstructorID) AS InstructoresUnicos
    FROM CURSO C
        INNER JOIN EQUIPOCURSO EC 
            ON EC.CursoID = C.CursoID
    WHERE C.FechaPublicacion IS NOT NULL
    GROUP BY YEAR(C.FechaPublicacion), MONTH(C.FechaPublicacion)),

InscripcionesMes AS (
    SELECT DATEFROMPARTS(YEAR(FechaInscripcion), MONTH(FechaInscripcion), 1) AS Mes, COUNT(*) AS TotalInscripciones,
           SUM(CASE WHEN Estado = 'COMPLETADA' THEN 1 ELSE 0 END) AS Completadas, SUM(CASE WHEN Estado <> 'REEMBOLSADA'
    THEN CAST(ROUND(PrecioPagado * PorcentajeComiAplicado / 100.0, 2) AS DECIMAL(18,2))
    ELSE CAST(0 AS DECIMAL(18,2)) END) AS ComisionPlataforma
    FROM INSCRIPCION
    GROUP BY YEAR(FechaInscripcion), MONTH(FechaInscripcion)),

CertificadosMes AS (
    SELECT DATEFROMPARTS(YEAR(FechaEmision), MONTH(FechaEmision), 1) AS Mes, COUNT(*) AS CertificadosEmitidos
    FROM CERTIFICADO
    GROUP BY YEAR(FechaEmision), MONTH(FechaEmision))



SELECT YEAR(M.Mes) AS Anio, MONTH(M.Mes) AS Mes,
       COALESCE(CP.CursosPublicados, 0) AS CursosPublicados,
       COALESCE(IP.InstructoresUnicos, 0) AS InstructoresUnicos,
       COALESCE(IM.TotalInscripciones, 0) AS TotalInscripciones,
       COALESCE(IM.ComisionPlataforma, 0) AS ComisionPlataforma,
       CAST(1.0 * IM.TotalInscripciones / NULLIF(CP.CursosPublicados, 0) AS DECIMAL(12,2)) AS PromedioInscripcionesPorCursoPublicado,
       COALESCE(CM.CertificadosEmitidos, 0) AS CertificadosEmitidos,
       CAST(100.0 * IM.Completadas / NULLIF(IM.TotalInscripciones, 0) AS DECIMAL(7,2)) AS TasaFinalizacionPorcentaje
FROM Meses M
    LEFT JOIN CursosPublicados CP 
        ON CP.Mes = M.Mes
    LEFT JOIN InstructoresPublicados IP 
        ON IP.Mes = M.Mes
    LEFT JOIN InscripcionesMes IM 
        ON IM.Mes = M.Mes
    LEFT JOIN CertificadosMes CM 
        ON CM.Mes = M.Mes
ORDER BY M.Mes
GO




----------------------------------------------------------------------------------------------------------------------------------------------------------
-- Index Elegido
-- PERSONA 4
CREATE INDEX IX_Inscripcion_Curso_Fecha
ON INSCRIPCION (CursoID, FechaInscripcion)
INCLUDE (Estado);
GO
/* 
Se verificó mediante el plan de ejecución real que SQL Server utiliza el índice IX_Inscripcion_Curso_Fecha en el reporte 
de crecimiento de instructores. Esto demuestra que el índice es aprovechado por el optimizador, 
aunque no necesariamente representa una reducción del tiempo de ejecución.
*/