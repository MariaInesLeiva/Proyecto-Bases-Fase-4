-- Procedimiento para crear un curso
CREATE OR ALTER PROCEDURE usp_CrearCurso

    @InstructorID INT,
    @Titulo NVARCHAR(150),
    @Descripcion NVARCHAR(MAX),
    @CategoriaID INT,
    @Precio DECIMAL(10,2),
    @ImagenPortada VARCHAR(500),
    @RequiereEval BIT = 0,
    @PorcentajePrincipal DECIMAL(5,2),

    @CursoID INT OUTPUT,
    @CodigoCurso VARCHAR(25) OUTPUT

AS
BEGIN

    SET NOCOUNT ON;

    declare @PrecioMinimo DECIMAL(10,2);
    declare @PrecioMaximo DECIMAL(10,2);
    declare @CodigoTemp VARCHAR(8);

    begin try

        if not exists (
            select 1
            from TRABAJADOR
            where TrabajadorID = @InstructorID
            and TipoTrabajador = 'INSTRUCTOR'
        )
        begin
            throw 50001, 'El trabajador no existe o no es instructor.', 1;
        end

        if not exists (
            select 1
            from CATEGORIA
            where CategoriaID = @CategoriaID
        )
        begin
            throw 50002, 'La categoria indicada no existe.', 1;
        end

        if @Titulo is null or len(@Titulo) = 0
        begin
            throw 50003, 'El titulo del curso es obligatorio.', 1;
        end

        if @Descripcion is null or len(@Descripcion) = 0
        begin
            throw 50004, 'La descripcion del curso es obligatoria.', 1;
        end

        if @ImagenPortada is null or len(@ImagenPortada) = 0
        begin
            throw 50005, 'La imagen de portada es obligatoria.', 1;
        end

        select
            @PrecioMinimo = PrecioMinimo,
            @PrecioMaximo = PrecioMaximo
        from CONFIGURACIONPLATAFORMA
        where ConfiguracionID = 1;

        if @PrecioMinimo is null or @PrecioMaximo is null
        begin
            throw 50006, 'No existe una configuracion de precios.', 1;
        end

        if @Precio is null
           or @Precio < @PrecioMinimo
           or @Precio > @PrecioMaximo
        begin
            throw 50007, 'El precio esta fuera del rango permitido.', 1;
        end

        if @PorcentajePrincipal is null
           or @PorcentajePrincipal <= 0
           or @PorcentajePrincipal > 100
        begin
            throw 50008, 'El porcentaje del instructor principal no es valido.', 1;
        end

        begin transaction;

        set @CodigoTemp = left(convert(varchar(36), newid()), 8);

        set @CodigoCurso =
            'EDU-' +
            cast(year(getdate()) as varchar(4)) +
            '-' +
            @CodigoTemp;

        insert into CURSO
        (
            CodigoCurso,
            Descripcion,
            CategoriaID,
            Precio,
            ImagenPortada,
            Estado,
            RequiereEval,
            Titulo
        )
        values
        (
            @CodigoCurso,
            @Descripcion,
            @CategoriaID,
            @Precio,
            @ImagenPortada,
            'PENDIENTE',
            @RequiereEval,
            @Titulo
        );

        set @CursoID = scope_identity();

        insert into EQUIPOCURSO
        (
            CursoID,
            InstructorID,
            PorcentajeParticipacion,
            EsPrincipal
        )
        values
        (
            @CursoID,
            @InstructorID,
            @PorcentajePrincipal,
            1
        );

        insert into NOTIFICACION
        (
            UsuarioID,
            CursoID,
            Tipo,
            Asunto,
            Mensaje
        )
        values
        (
            @InstructorID,
            @CursoID,
            'CURSO_RECIBIDO',
            'Curso recibido',
            'Recibimos tu curso. Nuestro comite academico lo revisara pronto.'
        );

         commit transaction;

    end try

    begin catch

        if XACT_STATE() <> 0
            rollback transaction;

        throw;

    end catch

END;
GO

--Procedimiento para editar un curso
CREATE OR ALTER PROCEDURE usp_EditarCurso

    @CursoID INT,
    @InstructorID INT,
    @Titulo NVARCHAR(150),
    @Descripcion NVARCHAR(MAX),
    @CategoriaID INT,
    @Precio DECIMAL(10,2),
    @ImagenPortada VARCHAR(500),
    @RequiereEval BIT = 0

AS
BEGIN

    SET NOCOUNT ON;

    declare @PrecioMinimo DECIMAL(10,2);
    declare @PrecioMaximo DECIMAL(10,2);

    begin try

        if not exists (
            select 1
            from CURSO
            where CursoID = @CursoID
        )
        begin
            throw 50010, 'El curso indicado no existe.', 1;
        end

        if not exists (
            select 1
            from EQUIPOCURSO
            where CursoID = @CursoID
            and InstructorID = @InstructorID
            and EsPrincipal = 1
        )
        begin
            throw 50011, 'Solo el instructor principal puede editar el curso.', 1;
        end

        if not exists (
            select 1
            from CURSO
            where CursoID = @CursoID
            and Estado in ('PENDIENTE', 'RECHAZADO')
        )
        begin
            throw 50012, 'El curso no se puede editar en su estado actual.', 1;
        end

        if not exists (
            select 1
            from CATEGORIA
            where CategoriaID = @CategoriaID
        )
        begin
            throw 50013, 'La categoria indicada no existe.', 1;
        end

        if @Titulo is null or len(@Titulo) = 0
        begin
            throw 50014, 'El titulo del curso es obligatorio.', 1;
        end

        if @Descripcion is null or len(@Descripcion) = 0
        begin
            throw 50015, 'La descripcion del curso es obligatoria.', 1;
        end

        if @ImagenPortada is null or len(@ImagenPortada) = 0
        begin
            throw 50016, 'La imagen de portada es obligatoria.', 1;
        end

        select
            @PrecioMinimo = PrecioMinimo,
            @PrecioMaximo = PrecioMaximo
        from CONFIGURACIONPLATAFORMA
        where ConfiguracionID = 1;

        if @PrecioMinimo is null or @PrecioMaximo is null
        begin
            throw 50017, 'No existe una configuracion de precios.', 1;
        end

        if @Precio is null
           or @Precio < @PrecioMinimo
           or @Precio > @PrecioMaximo
        begin
            throw 50018, 'El precio esta fuera del rango permitido.', 1;
        end

        update CURSO
        set
            Titulo = @Titulo,
            Descripcion = @Descripcion,
            CategoriaID = @CategoriaID,
            Precio = @Precio,
            ImagenPortada = @ImagenPortada,
            RequiereEval = @RequiereEval
        where CursoID = @CursoID;

    end try

    begin catch

        throw;

    end catch

END;
GO

--Procedimiento para agregar coinstructor
CREATE OR ALTER PROCEDURE usp_AgregarCoInstructor

    @CursoID INT,
    @InstructorPrincipalID INT,
    @CoInstructorID INT,
    @PorcentajeParticipacion DECIMAL(5,2)

AS
BEGIN

    SET NOCOUNT ON;

    declare @PorcentajeActual DECIMAL(5,2);

    begin try

        if not exists (
            select 1
            from CURSO
            where CursoID = @CursoID
        )
        begin
            throw 50020, 'El curso indicado no existe.', 1;
        end

        if not exists (
            select 1
            from EQUIPOCURSO
            where CursoID = @CursoID
            and InstructorID = @InstructorPrincipalID
            and EsPrincipal = 1
        )
        begin
            throw 50021, 'Solo el instructor principal puede agregar co-instructores.', 1;
        end

        if not exists (
            select 1
            from CURSO
            where CursoID = @CursoID
            and Estado in ('PENDIENTE', 'RECHAZADO')
        )
        begin
            throw 50022, 'No se pueden agregar co-instructores en el estado actual del curso.', 1;
        end

        if not exists (
            select 1
            from TRABAJADOR
            where TrabajadorID = @CoInstructorID
            and TipoTrabajador = 'INSTRUCTOR'
        )
        begin
            throw 50023, 'El co-instructor indicado no existe o no es instructor.', 1;
        end

        if @InstructorPrincipalID = @CoInstructorID
        begin
            throw 50024, 'El instructor principal no puede agregarse como co-instructor.', 1;
        end

        if exists (
            select 1
            from EQUIPOCURSO
            where CursoID = @CursoID
            and InstructorID = @CoInstructorID
        )
        begin
            throw 50025, 'El instructor ya pertenece al equipo del curso.', 1;
        end

        if @PorcentajeParticipacion is null
           or @PorcentajeParticipacion <= 0
           or @PorcentajeParticipacion > 100
        begin
            throw 50026, 'El porcentaje de participacion no es valido.', 1;
        end

        select @PorcentajeActual = sum(PorcentajeParticipacion)
        from EQUIPOCURSO
        where CursoID = @CursoID;

        if @PorcentajeActual + @PorcentajeParticipacion > 100
        begin
            throw 50027, 'La suma de los porcentajes no puede superar el 100 por ciento.', 1;
        end

        insert into EQUIPOCURSO
        (
            CursoID,
            InstructorID,
            PorcentajeParticipacion,
            EsPrincipal
        )
        values
        (
            @CursoID,
            @CoInstructorID,
            @PorcentajeParticipacion,
            0
        );

    end try

    begin catch

        throw;

    end catch

END;
GO

-- Procedimiento para agregar un requisito curso
CREATE OR ALTER PROCEDURE usp_AgregarRequisitoCurso
	@CursoID INT,
	@CursoRequisitoID INT,
	@InstructorID INT
AS
BEGIN
	IF NOT EXISTS 
	(
		SELECT 1
		FROM CURSO
		WHERE CursoID = @CursoID
	)	
	BEGIN
		THROW 50001, 'El curso no existe', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1
		FROM EQUIPOCURSO
		WHERE CursoID = @CursoID
			AND InstructorID = @InstructorID 
			AND EsPrincipal = 1
	)
	BEGIN
		THROW 50002, 'El instructor no es el instructor principal del curso', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1
		FROM CURSO
		WHERE CursoID = @CursoID
			AND Estado IN ('PENDIENTE', 'RECHAZADO')
	)
	BEGIN
		THROW 50003, 'El curso no se encuentra pendiente o rechazado', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1
		FROM CURSO
		WHERE CursoID = @CursoRequisitoID
	)
	BEGIN
		THROW 50004, 'El curso requisito no existe', 1;
	END;

	IF @CursoID = @CursoRequisitoID
	BEGIN 
		THROW 50005, 'El curso no puede ser requisito de sí mismo', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1
		FROM CURSO
		WHERE CursoID = @CursoRequisitoID 
			AND Estado = 'DISPONIBLE'
	)
	BEGIN
		THROW 50006, 'El curso requisito no está disponible', 1;
	END;

	IF EXISTS
	(
		SELECT 1
		FROM CURSOREQUISITO
		WHERE CursoID = @CursoID
			AND CursoRequisitoID = @CursoRequisitoID
	)
	BEGIN
		THROW 50007, 'El curso requisito ya fue agregado', 1;
	END;

	DECLARE @Ciclo BIT = 0;

	;WITH Requisitos AS
	(
		SELECT CursoRequisitoID
		FROM CURSOREQUISITO
		WHERE CursoID = @CursoRequisitoID

		UNION ALL

		SELECT cr.CursoRequisitoID
		FROM CURSOREQUISITO cr
		INNER JOIN Requisitos r
			ON cr.CursoID = r.CursoRequisitoID
	)
	SELECT @Ciclo = 1
	FROM Requisitos
	WHERE CursoRequisitoID = @CursoID;

	IF @Ciclo = 1
	BEGIN
		THROW 50008, 'No se puede agregar el requisito porque genera una dependencia circular', 1;
	END;

	INSERT INTO CURSOREQUISITO (CursoID, CursoRequisitoID)
	VALUES (@CursoID, @CursoRequisitoID);

END;
GO

--Procedimiento para agregar un módulo
CREATE OR ALTER PROCEDURE usp_AgregarModulo
    @CursoID INT,
    @InstructorID INT,
    @NombreModulo NVARCHAR(150),
    @NoOrden INT,
	@ModuloID INT OUTPUT
AS
BEGIN
    IF NOT EXISTS 
	(
		SELECT 1
		FROM CURSO
		WHERE CursoID = @CursoID 
	)
	BEGIN
		THROW 50001, 'El curso no existe', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1 
		FROM EQUIPOCURSO
		WHERE CursoID = @CursoID 
			AND InstructorID = @InstructorID
			AND EsPrincipal = 1
	)
	BEGIN
		THROW 50002, 'El instructor no es el instructor principal del curso', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1
		FROM CURSO
		WHERE CursoID = @CursoID 
			AND Estado in ('PENDIENTE', 'RECHAZADO')
	)
	BEGIN
		THROW 50003, 'El curso no se encuentra pendiente o rechazado', 1;
	END;

	IF @NombreModulo IS NULL 
		OR LTRIM(RTRIM(@NombreModulo)) = ''
	BEGIN
		THROW 50004, 'El módulo no tiene nombre', 1;
	END;

	IF @NoOrden <= 0
	BEGIN
		THROW 50005, 'El número de orden debe ser mayor que cero', 1;
	END;

	IF EXISTS
	(
		SELECT 1
		FROM MODULO
		WHERE CursoID = @CursoID
			AND NoOrden = @NoOrden
	)
	BEGIN
		THROW 50006, 'El número de orden del módulo ya existe en el curso', 1;
	END;

	INSERT INTO MODULO
	(
		CursoID,
		NombreModulo,
		NoOrden
	)
	VALUES
	(
		@CursoID,
		@NombreModulo,
		@NoOrden
	);

	SET @ModuloID = SCOPE_IDENTITY();

END;
GO

-- Procedimiento para agregar una lección
CREATE OR ALTER PROCEDURE usp_AgregarLeccion
	@ModuloID INT,
    @InstructorID INT,
    @NombreLeccion NVARCHAR(150),
    @Contenido NVARCHAR(MAX),
    @NoOrden INT,
    @DuracionMinutos INT,
	@LeccionID INT OUTPUT
AS
BEGIN
    
	IF NOT EXISTS 
	(
		SELECT 1
		FROM MODULO
		WHERE ModuloID = @ModuloID
	)
	BEGIN
		THROW 50001, 'El módulo no existe', 1;
	END;

	DECLARE @CursoID INT;

	SELECT @CursoID = CursoID
	FROM MODULO
	WHERE ModuloID = @ModuloID;

	IF NOT EXISTS 
	(
		SELECT 1 
		FROM EQUIPOCURSO
		WHERE CursoID = @CursoID 
			AND InstructorID = @InstructorID
			AND EsPrincipal = 1
	)
	BEGIN
		THROW 50002, 'El instructor no es el instructor principal del curso', 1;
	END;

	IF NOT EXISTS 
	(
		SELECT 1
		FROM CURSO
		WHERE CursoID = @CursoID 
			AND Estado in ('PENDIENTE', 'RECHAZADO')
	)
	BEGIN
		THROW 50003, 'El curso no se encuentra pendiente o rechazado', 1;
	END;

	IF @NombreLeccion IS NULL 
		OR LTRIM(RTRIM(@NombreLeccion)) = ''
	BEGIN
		THROW 50004, 'La lección no tiene nombre', 1;
	END;

	IF @Contenido IS NULL 
		OR LTRIM(RTRIM(@Contenido)) = ''
	BEGIN
		THROW 50005, 'La lección no tiene contenido', 1;
	END;

	IF @NoOrden <= 0
	BEGIN
		THROW 50006, 'El número de orden debe ser mayor que cero', 1;
	END;

	IF EXISTS
	(
		SELECT 1
		FROM LECCION
		WHERE ModuloID = @ModuloID
			AND NoOrden = @NoOrden
	)
	BEGIN
		THROW 50007, 'El número de orden de la lección ya existe en el módulo', 1;
	END;

	IF @DuracionMinutos <= 0
	BEGIN
		THROW 50008, 'La duración de la lección debe ser mayor que cero', 1;
	END;

	INSERT INTO LECCION
	(
		ModuloID,
		NombreLeccion,
		Contenido,
		NoOrden,
		DuracionMinutos
	)
	VALUES
	(
		@ModuloID,
		@NombreLeccion,
		@Contenido,
		@NoOrden,
		@DuracionMinutos
	);

	SET @LeccionID = SCOPE_IDENTITY();

END;
GO

-- Procedimiento para agregar un recurso a la lección
CREATE OR ALTER PROCEDURE usp_AgregarRecursoLeccion
	@LeccionID INT,
    @InstructorID INT,
    @NombreRecurso NVARCHAR(150),
    @TipoRecurso VARCHAR(20),
    @UbicacionRecurso NVARCHAR(500),
	@RecursoID INT OUTPUT
AS
BEGIN
    
	IF NOT EXISTS
	(
		SELECT 1
		FROM LECCION
		WHERE LeccionID = @LeccionID
	)
	BEGIN
		THROW 50001, 'La lección no existe', 1;
	END;

	DECLARE @CursoID INT;

	SELECT @CursoID = CursoID
	FROM LECCION l
	INNER JOIN MODULO m
		ON l.ModuloID = m.ModuloID
	WHERE l.LeccionID = @LeccionID;

	IF NOT EXISTS
	(
		SELECT 1
		FROM EQUIPOCURSO
		WHERE InstructorID = @InstructorID
			AND CursoID = @CursoID
			AND EsPrincipal = 1
	)
	BEGIN 
		THROW 50002, 'El instructor no es el instructor principal del curso', 1;
	END;

	IF NOT EXISTS
	(
		SELECT 1
		FROM CURSO
		WHERE CursoID = @CursoID
			AND Estado IN ('PENDIENTE', 'RECHAZADO')
	)
	BEGIN
		THROW 50003, 'El curso no se encuentra pendiente o rechazado', 1;
	END;

	IF @NombreRecurso IS NULL 
		OR LTRIM(RTRIM(@NombreRecurso)) = ''
	BEGIN
		THROW 50004,'El recurso no tiene nombre', 1;
	END;

	IF @TipoRecurso IS NULL 
		OR LTRIM(RTRIM(@TipoRecurso)) = ''
	BEGIN
		THROW 50005, 'El recurso no tiene tipo', 1;
	END;

	IF @UbicacionRecurso IS NULL 
		OR LTRIM(RTRIM(@UbicacionRecurso)) = ''
	BEGIN
		THROW 50006, 'El recurso no tiene ubicación', 1;
	END;

	INSERT INTO RECURSOLECCION
	(
		LeccionID,
		NombreRecurso,
		TipoRecurso,
		UbicacionRecurso
	)
	VALUES
	(
		@LeccionID,
		@NombreRecurso,
		@TipoRecurso,
		@UbicacionRecurso
	);

	SET @RecursoID = SCOPE_IDENTITY();

END;
GO

--Procedimiento para validar y enviar curso a revisión
CREATE OR ALTER PROCEDURE usp_EnviarCursoRevision
(
    @CursoID INT,
    @InstructorID INT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        
        IF NOT EXISTS
        (
            SELECT 1
            FROM CURSO
            WHERE CursoID = @CursoID
              AND Estado IN ('PENDIENTE', 'RECHAZADO')
        )
        BEGIN
            THROW 50001,'El curso no existe o no se encuentra en estado PENDIENTE o RECHAZADO.',1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM EQUIPOCURSO
            WHERE CursoID = @CursoID
              AND InstructorID = @InstructorID
              AND EsPrincipal = 1
        )
        BEGIN
            THROW 50002,'El instructor indicado no es el instructor principal de este curso.',1;
        END;

        DECLARE @CantModulos INT;

        SELECT @CantModulos = COUNT(*)
        FROM MODULO
        WHERE CursoID = @CursoID;

        IF @CantModulos < 3
        BEGIN
            THROW 50003,'El curso debe tener como minimo 3 modulos.',1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM MODULO M
            WHERE M.CursoID = @CursoID
              AND NOT EXISTS
              (
                  SELECT 1
                  FROM LECCION L
                  WHERE L.ModuloID = M.ModuloID
                    AND L.Contenido IS NOT NULL
                    AND LTRIM(RTRIM(L.Contenido)) <> ''
              )
        )
        BEGIN
            THROW 50004,'Cada modulo debe contener al menos una leccion con contenido valido.',1;
        END;

        DECLARE @MinOrdenModulo INT;
        DECLARE @MaxOrdenModulo INT;
        DECLARE @CantOrdenModulo INT;

        SELECT
            @MinOrdenModulo = MIN(NoOrden),
            @MaxOrdenModulo = MAX(NoOrden),
            @CantOrdenModulo = COUNT(*)
        FROM MODULO
        WHERE CursoID = @CursoID;

        IF @MinOrdenModulo <> 1
           OR @MaxOrdenModulo <> @CantOrdenModulo
        BEGIN
            THROW 50005,'Los modulos deben tener un orden secuencial desde 1 sin espacios.',1;
        END;

        IF EXISTS
        (
            SELECT M.ModuloID
            FROM MODULO M

            INNER JOIN LECCION L
                ON L.ModuloID = M.ModuloID

            WHERE M.CursoID = @CursoID

            GROUP BY M.ModuloID

            HAVING MIN(L.NoOrden) <> 1
                OR MAX(L.NoOrden) <> COUNT(*)
        )
        BEGIN
            THROW 50006,'Las lecciones de cada modulo deben tener un orden secuencial desde 1 sin espacios.',1;
        END;

        DECLARE @CantInstructorPrincipal INT;

        SELECT @CantInstructorPrincipal = COUNT(*)
        FROM EQUIPOCURSO
        WHERE CursoID = @CursoID
          AND EsPrincipal = 1;

        IF @CantInstructorPrincipal <> 1
        BEGIN
            THROW 50007,'El curso debe tener exactamente un instructor principal.',1;
        END;

        DECLARE @SumaParticipacion DECIMAL(10,2);

        SELECT @SumaParticipacion =
            COALESCE(SUM(PorcentajeParticipacion), 0)
        FROM EQUIPOCURSO
        WHERE CursoID = @CursoID;

        IF @SumaParticipacion <> 100
        BEGIN
            THROW 50008,'La suma de los porcentajes de participacion debe ser exactamente 100%.',1;
        END;

        IF EXISTS
        (
            SELECT 1
            FROM CURSOREQUISITO CR

            INNER JOIN CURSO C
                ON C.CursoID = CR.CursoRequisitoID

            WHERE CR.CursoID = @CursoID
              AND C.Estado <> 'DISPONIBLE'
        )
        BEGIN
            THROW 50009,'Todos los cursos requisito deben estar disponibles.',1;
        END;

        DECLARE @HayDependenciaCircular BIT = 0;

        ;WITH RutaRequisitos AS
        (
            SELECT
                CR.CursoRequisitoID,
                CAST(
                    '|' +
                    CAST(CR.CursoRequisitoID AS VARCHAR(20)) +
                    '|'
                    AS VARCHAR(MAX)
                ) AS Ruta
            FROM CURSOREQUISITO CR
            WHERE CR.CursoID = @CursoID

            UNION ALL

            SELECT
                CR.CursoRequisitoID,
                CAST(
                    RR.Ruta +
                    CAST(CR.CursoRequisitoID AS VARCHAR(20)) +
                    '|'
                    AS VARCHAR(MAX)
                )
            FROM RutaRequisitos RR

            INNER JOIN CURSOREQUISITO CR
                ON CR.CursoID = RR.CursoRequisitoID

            WHERE RR.Ruta NOT LIKE
                '%|' +
                CAST(CR.CursoRequisitoID AS VARCHAR(20)) +
                '|%'
        )

        SELECT @HayDependenciaCircular =
            CASE
                WHEN EXISTS
                (
                    SELECT 1
                    FROM RutaRequisitos
                    WHERE CursoRequisitoID = @CursoID
                )
                THEN 1
                ELSE 0
            END
        OPTION (MAXRECURSION 32767);


        IF @HayDependenciaCircular = 1
        BEGIN
            THROW 50010,'Se detecto una dependencia circular entre los cursos requisito.',1;
        END;

        DECLARE @PrecioCurso DECIMAL(10,2);
        DECLARE @PrecioMinimo DECIMAL(10,2);
        DECLARE @PrecioMaximo DECIMAL(10,2);

        SELECT @PrecioCurso = Precio
        FROM CURSO
        WHERE CursoID = @CursoID;


        SELECT
            @PrecioMinimo = PrecioMinimo,
            @PrecioMaximo = PrecioMaximo
        FROM CONFIGURACIONPLATAFORMA
        WHERE ConfiguracionID = 1;

        IF @PrecioMinimo IS NULL
           OR @PrecioMaximo IS NULL
           OR @PrecioMinimo > @PrecioMaximo
        BEGIN
            THROW 50011,'No existe una configuracion valida para el rango de precios.',1;
        END;


        IF @PrecioCurso < @PrecioMinimo
           OR @PrecioCurso > @PrecioMaximo
        BEGIN
            THROW 50012,'El precio del curso se encuentra fuera del rango permitido.',1;
        END;

        BEGIN TRANSACTION;

            UPDATE CURSO
            SET Estado = 'ENREVISION'
            WHERE CursoID = @CursoID;

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

--Procedimiento para asignar e iniciar la revision academica de un curso
CREATE OR ALTER PROCEDURE usp_IniciarRevisionAcademica
(
    @CursoID INT,
    @RevisorID INT,
    @RevisionID INT OUTPUT,
    @NumRevision INT OUTPUT
)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF NOT EXISTS(
            
            SELECT 1
            FROM TRABAJADOR
            WHERE (TrabajadorID = @RevisorID) AND (TipoTrabajador = 'REVISOR')
            
        )

        BEGIN
            THROW 50001, 'No es revisor',1;
        END;

        IF NOT EXISTS(
            SELECT 1
            FROM CURSO
            WHERE(CursoID = @CursoID)
        )

        BEGIN
            THROW 50002, 'Curso Inexistente',1;
        END;

        IF NOT EXISTS(
        
            SELECT 1
            FROM CURSO
            WHERE(CursoID = @CursoID) AND (Estado = 'ENREVISION')

        )

        BEGIN
            THROW 50003, 'El estado del curso no se encuentra en revision.',1;
        END;

        IF EXISTS(
        
            SELECT 1
            FROM REVISIONACADEMICA
            WHERE (CursoID = @CursoID) AND (RESULTADO = 'PENDIENTE')

        )

        BEGIN
            THROW 50004, 'Ya existe una revision previa sobre este curso', 1;
        END
        
        BEGIN TRANSACTION;
            DECLARE @Bloqueo INT

            SET @Bloqueo = (SELECT CursoID
            FROM CURSO WITH (UPDLOCK, HOLDLOCK)
            WHERE CursoID = @CursoID)

            IF EXISTS
            (
                SELECT 1
                FROM REVISIONACADEMICA
                WHERE CursoID = @CursoID
                  AND Resultado = 'PENDIENTE'
            )
            BEGIN
                THROW 50005, 'Ya existe una revision PENDIENTE para este curso.', 1;
            END;

            SELECT @NumRevision =
                ISNULL(MAX(NumRevision), 0) + 1
            FROM REVISIONACADEMICA
            WHERE CursoID = @CursoID;

            INSERT INTO REVISIONACADEMICA(CursoID, RevisorID, NumRevision, FechaInicio, FechaFin, Resultado, Comentario)
            VALUES(@CursoID, @RevisorID, @NumRevision, GETDATE(), NULL, 'PENDIENTE', NULL)

            SET @RevisionID = SCOPE_IDENTITY()

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

--Procedimiento para aprobar o rechazar un curso y generar las notificaciones correspondientes
CREATE OR ALTER PROCEDURE usp_ResolverRevisionAcademica
(
    @RevisionID INT,
    @RevisorID INT,
    @Resultado NVARCHAR(25),
    @Comentario NVARCHAR(500)
)
AS 
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY

        IF NOT EXISTS
        (
            SELECT 1
            FROM REVISIONACADEMICA
            WHERE RevisionID = @RevisionID
        )
        BEGIN
            THROW 50001, 'La revision no existe.', 1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM REVISIONACADEMICA
            WHERE RevisionID = @RevisionID
              AND RevisorID = @RevisorID
        )
        BEGIN
            THROW 50002, 'La revision no pertenece al revisor indicado.', 1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM REVISIONACADEMICA
            WHERE RevisionID = @RevisionID
              AND Resultado = 'PENDIENTE'
        )
        BEGIN
            THROW 50003, 'La revision ya fue resuelta.', 1;
        END;

        IF NOT EXISTS
        (
            SELECT 1
            FROM TRABAJADOR
            WHERE TrabajadorID = @RevisorID
              AND TipoTrabajador = 'REVISOR'
        )
        BEGIN
            THROW 50004, 'El trabajador indicado no tiene rol de REVISOR.', 1;
        END;

        IF @Resultado NOT IN ('APROBADO', 'RECHAZADO')
        BEGIN
            THROW 50005, 'El resultado debe ser APROBADO o RECHAZADO.', 1;
        END;

        IF @Comentario IS NULL OR LEN(@Comentario) = 0
        BEGIN
            THROW 50006, 'Debe ingresar un comentario para resolver la revision.', 1;
        END;

        BEGIN TRANSACTION;
			DECLARE @CursoID INT
			SET @CursoID = (
                SELECT CursoID
				FROM REVISIONACADEMICA
				WHERE (RevisionID = @RevisionID)
            )

			DECLARE @UsuarioID INT
			SET @UsuarioID = (
                SELECT InstructorID
				FROM EQUIPOCURSO
				WHERE (CursoID = @CursoID) AND (EsPrincipal = 1)
            )

			DECLARE @Titulo_Curso NVARCHAR(150)
			SET @Titulo_Curso = (
                SELECT Titulo
				FROM CURSO
				WHERE CursoID = @CursoID
            )

			DECLARE @CategoriaID INT
			SET @CategoriaID = (
                SELECT CategoriaID
				FROM CURSO
				WHERE (CursoID = @CursoID)
            )

			UPDATE REVISIONACADEMICA
			SET Resultado = @Resultado,
				Comentario = @Comentario,
				FechaFin = GETDATE()
			WHERE (RevisionID = @RevisionID)

			IF @Resultado = 'RECHAZADO'
			BEGIN
				UPDATE CURSO
				SET Estado = 'RECHAZADO'
				WHERE (CursoID = @CursoID)

				INSERT INTO NOTIFICACION(UsuarioID, CursoID, Tipo, Asunto, Mensaje, FechaCreacion, Estado)
				VALUES (@UsuarioID, @CursoID, 'CURSO_RECHAZADO', 'Rechazo de curso', 
				CONCAT('Su curso "', @Titulo_Curso, '" fue rechazado por el siguiente motivo: ', @Comentario), GETDATE(), 'ENVIADA')
			END

			IF @Resultado = 'APROBADO'
			BEGIN
				UPDATE CURSO
				SET Estado = 'DISPONIBLE',
					FechaPublicacion = GETDATE()
				WHERE (CursoID = @CursoID)

				INSERT INTO NOTIFICACION(UsuarioID, CursoID, Tipo, Asunto, Mensaje, FechaCreacion, Estado)
				VALUES (@UsuarioID, @CursoID, 'CURSO_PUBLICADO', 'Aprobacion de curso', 
				CONCAT('Su curso "', @Titulo_Curso, '" fue aprobado y publicado de forma correcta'), GETDATE(), 'ENVIADA')

				INSERT INTO NOTIFICACION(UsuarioID, CursoID, Tipo, Asunto, Mensaje, FechaCreacion, Estado)
				SELECT UsuarioID, @CursoID, 'NUEVO_CURSO_CATEGORIA', 'Nuevo curso ya disponible', 
				CONCAT('Se ha creado un nuevo curso llamado "', @Titulo_Curso, '" el cual se encuentra dentro de sus categorias suscritas'),
				GETDATE(), 'ENVIADA'
				FROM SUSCRIPCIONCATEGORIA
				WHERE (CategoriaID = @CategoriaID)
			END

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

--Procedimiento para configurar el rango de los precios
CREATE OR ALTER PROCEDURE usp_ConfigurarRangoPrecios
	@AdministradorID INT,
	@PrecioMinimo DECIMAL(10,2),
	@PrecioMaximo DECIMAL(10,2)
	AS
	BEGIN
	SET NOCOUNT ON;
		BEGIN TRY

			IF NOT EXISTS (
				SELECT 1
				FROM TRABAJADOR
				WHERE TrabajadorID = @AdministradorID AND TipoTrabajador = 'ADMINISTRADOR'
							)
			THROW 50001, 'El usuario indicado no es un administrador.', 1;

			IF @PrecioMinimo IS NULL OR @PrecioMaximo IS NULL
			THROW 50002, 'El precio mínimo y el precio máximo son obligatorios.', 1;

			IF @PrecioMinimo <= 0
			THROW 50003, 'El precio mínimo debe de ser mayor a 0.', 1;

			IF @PrecioMaximo < @PrecioMinimo
			THROW 50004, 'El precio máximo no puede ser menor que el precio mínimo.', 1;

			IF EXISTS (
				SELECT 1
				FROM CONFIGURACIONPLATAFORMA
				WHERE ConfiguracionID = 1
						)
				UPDATE CONFIGURACIONPLATAFORMA
				SET PrecioMaximo = @PrecioMaximo,
					PrecioMinimo = @PrecioMinimo
				WHERE ConfiguracionID = 1
			ELSE
				INSERT INTO CONFIGURACIONPLATAFORMA (ConfiguracionID, PrecioMinimo, PrecioMaximo)
				VALUES (1, @PrecioMinimo, @PrecioMaximo)
			END TRY
		BEGIN CATCH
		THROW;
		END CATCH
	END
	GO

--Procedimiento para configurar la comision de una categoria
CREATE OR ALTER PROCEDURE usp_ConfigurarComisionCategoria
	@AdministradorID INT,
	@CategoriaID INT,
	@PorcentajeComision DECIMAL(5,2)
	AS
	BEGIN
	SET NOCOUNT ON;
		BEGIN TRY 

			IF NOT EXISTS(
				SELECT 1
				FROM TRABAJADOR
				WHERE TrabajadorID = @AdministradorID AND TipoTrabajador = 'ADMINISTRADOR'
							)
			THROW 50001, 'El usuario indicado no es un administrador.', 1;

			IF @PorcentajeComision IS NULL
			THROW 50002, 'El porcentaje de comisión no puede ser nulo.', 1;

			IF @PorcentajeComision > 100 OR @PorcentajeComision < 0
			THROW 50003, 'El porcentaje de comisión debe de estar entre 0 y 100.', 1;

			IF NOT EXISTS(
				SELECT 1
				FROM CATEGORIA
				WHERE @CategoriaID = CategoriaID
							)
			THROW 50004, 'La categoría ingresada no existe.', 1;

			UPDATE CATEGORIA
			SET PorcentajeComisionBase = @PorcentajeComision
			WHERE @CategoriaID = CategoriaID

		END TRY
		BEGIN CATCH
		THROW;
		END CATCH
	END
	GO

--Procedimiento para configurar la comision de un instructor
CREATE OR ALTER PROCEDURE usp_ConfigurarComisionInstructor
	@AdministradorID INT,
	@InstructorID INT,
	@PorcentajeComisionEsp DECIMAL(5,2) = NULL
	AS
	BEGIN
	SET NOCOUNT ON;
		BEGIN TRY

			IF NOT EXISTS(
				SELECT 1
				FROM TRABAJADOR
				WHERE TrabajadorID = @AdministradorID AND TipoTrabajador = 'ADMINISTRADOR'
							)
			THROW 50001, 'El usuario indicado no es un administrador.', 1;

			IF NOT EXISTS(
				SELECT 1
				FROM TRABAJADOR
				WHERE @InstructorID = TrabajadorID
						)
			THROW 50002, 'El trabajador indicado no existe.', 1;

			IF NOT EXISTS(
			SELECT 1
			FROM TRABAJADOR
			WHERE TrabajadorID = @InstructorID AND TipoTrabajador = 'INSTRUCTOR'
							)
			THROW 50003, 'Solo un instructor puede tener comision especial.', 1;

			IF @PorcentajeComisionEsp IS NOT NULL
				AND (@PorcentajeComisionEsp > 100 OR @PorcentajeComisionEsp < 0)
			THROW 50004, 'El porcentaje de comision especial debe estar entre 0 y 100.', 1;

			UPDATE TRABAJADOR
			SET PorcentajeComisionEsp = @PorcentajeComisionEsp
			WHERE TrabajadorID = @InstructorID
			
		END TRY 
		BEGIN CATCH
		THROW;
		END CATCH
	END
	GO

--Procedimiento para crear una cohorte de un curso disponible
CREATE OR ALTER PROCEDURE usp_CrearCohorte
	@AdministradorID INT,
	@CursoID INT,
	@FechaInicio DATE,
	@CupoMax INT,
	@CohorteID INT OUTPUT
	AS
	BEGIN
	SET NOCOUNT ON;
		BEGIN TRY

			IF NOT EXISTS(
				SELECT 1
				FROM TRABAJADOR
				WHERE TrabajadorID = @AdministradorID AND TipoTrabajador = 'ADMINISTRADOR'
							)
			THROW 50001, 'El usuario indicado no es un administrador.', 1;

			IF @FechaInicio IS NULL
			THROW 50002, 'La fecha de inicio de la cohorte es obligatoria.', 1;

			IF @FechaInicio < CAST(GETDATE() AS DATE)
			THROW 50003, 'La fecha de inicio no puede ser anterior a hoy.', 1;

			IF @CupoMax IS NULL OR @CupoMax <= 0
			THROW 50004, 'El cupo maximo debe ser mayor que cero.', 1;

			IF NOT EXISTS(
				SELECT 1
				FROM CURSO
				WHERE CursoID = @CursoID
							)
			THROW 50005, 'El curso indicado no existe.', 1;

			INSERT INTO COHORTE (CursoID, FechaInicio, CupoMax)
			SELECT @CursoID, @FechaInicio, @CupoMax
			FROM CURSO
			WHERE CursoID = @CursoID AND Estado = 'DISPONIBLE'

			IF @@ROWCOUNT = 0
			THROW 50006, 'Solo se pueden crear cohortes para cursos en estado DISPONIBLE.', 1;

			SET @CohorteID = SCOPE_IDENTITY()

		END TRY
		BEGIN CATCH
		THROW;
		END CATCH
	END
	GO

--Procedimiento para configurar una nueva politica de reembolso
CREATE OR ALTER PROCEDURE usp_ConfigurarPoliticaReembolso
	@AdministradorID INT,
	@DiasLimite INT,
	@PorcentajeMax DECIMAL(5,2),
	@FechaInicioVigencia DATE,
	@PoliticaID INT OUTPUT
	AS
	BEGIN
	SET NOCOUNT ON;
	SET XACT_ABORT ON;
		BEGIN TRY

			IF NOT EXISTS(
				SELECT 1
				FROM TRABAJADOR
				WHERE TrabajadorID = @AdministradorID AND TipoTrabajador = 'ADMINISTRADOR'
							)
			THROW 50001, 'El usuario indicado no es un administrador.', 1;

			IF @DiasLimite IS NULL OR @DiasLimite < 0
			THROW 50002, 'Los dias limite deben ser mayores o iguales a cero.', 1;

			IF @PorcentajeMax IS NULL OR @PorcentajeMax < 0 OR @PorcentajeMax > 100
			THROW 50003, 'El porcentaje maximo de avance debe estar entre 0 y 100.', 1;

			IF @FechaInicioVigencia IS NULL
			THROW 50004, 'La fecha de inicio de vigencia es obligatoria.', 1;

			BEGIN TRANSACTION;

				DECLARE @PoliticaVigenteID INT,
						@InicioVigente DATE

				SELECT @PoliticaVigenteID = PoliticaID,
					   @InicioVigente = FechaInicioVigencia
				FROM POLITICAREEMBOLSO WITH (UPDLOCK, HOLDLOCK)
				WHERE FechaFinVigencia IS NULL

				IF @PoliticaVigenteID IS NOT NULL AND @FechaInicioVigencia <= @InicioVigente
				THROW 50005, 'La nueva politica debe iniciar despues de la politica vigente.', 1;

				IF @PoliticaVigenteID IS NOT NULL
					UPDATE POLITICAREEMBOLSO
					SET FechaFinVigencia = DATEADD(DAY, -1, @FechaInicioVigencia)
					WHERE PoliticaID = @PoliticaVigenteID

				INSERT INTO POLITICAREEMBOLSO (DiasLimite, PorcentajeMax, FechaInicioVigencia, FechaFinVigencia)
				VALUES (@DiasLimite, @PorcentajeMax, @FechaInicioVigencia, NULL)

				SET @PoliticaID = SCOPE_IDENTITY()

			COMMIT TRANSACTION;

		END TRY
		BEGIN CATCH
			IF @@TRANCOUNT > 0
				ROLLBACK TRANSACTION;
			THROW;
		END CATCH
	END
	GO

--Procedimiento para configurar un curso como destacado
CREATE OR ALTER PROCEDURE usp_ConfigurarCursoDestacado
	@AdministradorID INT,
	@CursoID INT,
	@Destacado BIT
	AS
	BEGIN
	SET NOCOUNT ON;
		BEGIN TRY

			IF NOT EXISTS(
				SELECT 1
				FROM TRABAJADOR
				WHERE TrabajadorID = @AdministradorID AND TipoTrabajador = 'ADMINISTRADOR'
							)
			THROW 50001, 'El usuario indicado no es un administrador.', 1;

			IF @Destacado IS NULL
			THROW 50002, 'Debe indicarse si el curso se destaca (1) o no (0).', 1;

			IF NOT EXISTS(
				SELECT 1
				FROM CURSO
				WHERE CursoID = @CursoID
							)
			THROW 50003, 'El curso indicado no existe.', 1;

			UPDATE CURSO
			SET Destacado = @Destacado
			WHERE CursoID = @CursoID AND Estado = 'DISPONIBLE'

			IF @@ROWCOUNT = 0
			THROW 50004, 'Solo se pueden destacar cursos en estado DISPONIBLE.', 1;

		END TRY
		BEGIN CATCH
		THROW;
		END CATCH
	END
	GO

-- Vista para mostrar los cursos disponibles en el catalogo
CREATE OR ALTER VIEW vw_CatalogoCursos
AS
    select
        c.CursoID,
        c.CodigoCurso,
        c.Titulo,
        c.Descripcion,
        c.CategoriaID,
        ca.NombreCategoria,
        c.Precio,
        c.ImagenPortada,
        c.FechaPublicacion,
        c.Destacado,
        c.RequiereEval
    from CURSO c
    inner join CATEGORIA ca
        on c.CategoriaID = ca.CategoriaID
    where c.Estado = 'DISPONIBLE';
GO