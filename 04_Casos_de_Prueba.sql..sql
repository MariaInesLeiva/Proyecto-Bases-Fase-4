-- 1. Pruebas del procedimiento para crear un curso
-- 1.1 Curso creado exitosamente
DECLARE @CursoID INT;
DECLARE @CodigoCurso VARCHAR(25);

EXEC usp_CrearCurso
    @InstructorID = 1,
    @Titulo = 'Introduccion a Desarrollo Web',
    @Descripcion = 'Curso introductorio sobre desarrollo web y aplicaciones.',
    @CategoriaID = 1,
    @Precio = 350.00,
    @ImagenPortada = '/img/desarrollo-web.jpg',
    @RequiereEval = 1,
    @PorcentajePrincipal = 100.00,
    @CursoID = @CursoID OUTPUT,
    @CodigoCurso = @CodigoCurso OUTPUT;

SELECT @CursoID AS CursoID,
       @CodigoCurso AS CodigoCurso;

SELECT *
FROM CURSO
WHERE CursoID = @CursoID;
GO

-- 1.2 Error porque el trabajador no es instructor
DECLARE @CursoID INT;
DECLARE @CodigoCurso VARCHAR(25);

EXEC usp_CrearCurso
    @InstructorID = 4,
    @Titulo = 'Curso de prueba',
    @Descripcion = 'Prueba con un trabajador que no es instructor.',
    @CategoriaID = 1,
    @Precio = 300.00,
    @ImagenPortada = '/img/prueba.jpg',
    @RequiereEval = 0,
    @PorcentajePrincipal = 100.00,
    @CursoID = @CursoID OUTPUT,
    @CodigoCurso = @CodigoCurso OUTPUT;
GO

-- 1.3 Error porque la categoría no existe
DECLARE @CursoID INT;
DECLARE @CodigoCurso VARCHAR(25);

EXEC usp_CrearCurso
    @InstructorID = 1,
    @Titulo = 'Curso de prueba',
    @Descripcion = 'Prueba con categoria inexistente.',
    @CategoriaID = 99,
    @Precio = 300.00,
    @ImagenPortada = '/img/prueba.jpg',
    @RequiereEval = 0,
    @PorcentajePrincipal = 100.00,
    @CursoID = @CursoID OUTPUT,
    @CodigoCurso = @CodigoCurso OUTPUT;
GO

-- 1.4 Error porque el titulo esta vacio
DECLARE @CursoID INT;
DECLARE @CodigoCurso VARCHAR(25);

EXEC usp_CrearCurso
    @InstructorID = 1,
    @Titulo = '',
    @Descripcion = 'Curso para probar la validacion del titulo.',
    @CategoriaID = 1,
    @Precio = 300.00,
    @ImagenPortada = '/img/prueba.jpg',
    @RequiereEval = 0,
    @PorcentajePrincipal = 100.00,
    @CursoID = @CursoID OUTPUT,
    @CodigoCurso = @CodigoCurso OUTPUT;
GO

-- 1.5 Error porque la descripcion esta vacia
DECLARE @CursoID INT;
DECLARE @CodigoCurso VARCHAR(25);

EXEC usp_CrearCurso
    @InstructorID = 1,
    @Titulo = 'Curso de prueba',
    @Descripcion = '',
    @CategoriaID = 1,
    @Precio = 300.00,
    @ImagenPortada = '/img/prueba.jpg',
    @RequiereEval = 0,
    @PorcentajePrincipal = 100.00,
    @CursoID = @CursoID OUTPUT,
    @CodigoCurso = @CodigoCurso OUTPUT;
GO

-- 1.6 Error porque la imagen esta vacia
DECLARE @CursoID INT;
DECLARE @CodigoCurso VARCHAR(25);

EXEC usp_CrearCurso
    @InstructorID = 1,
    @Titulo = 'Curso de prueba',
    @Descripcion = 'Prueba para validar la imagen.',
    @CategoriaID = 1,
    @Precio = 300.00,
    @ImagenPortada = '',
    @RequiereEval = 0,
    @PorcentajePrincipal = 100.00,
    @CursoID = @CursoID OUTPUT,
    @CodigoCurso = @CodigoCurso OUTPUT;
GO

-- 1.7 Error porque el precio esta fuera del rango
DECLARE @CursoID INT;
DECLARE @CodigoCurso VARCHAR(25);

EXEC usp_CrearCurso
    @InstructorID = 1,
    @Titulo = 'Curso de prueba',
    @Descripcion = 'Prueba con precio fuera del rango.',
    @CategoriaID = 1,
    @Precio = 20.00,
    @ImagenPortada = '/img/prueba.jpg',
    @RequiereEval = 0,
    @PorcentajePrincipal = 100.00,
    @CursoID = @CursoID OUTPUT,
    @CodigoCurso = @CodigoCurso OUTPUT;
GO

-- 1.8 Error porque el porcentaje del instructor es invalido
DECLARE @CursoID INT;
DECLARE @CodigoCurso VARCHAR(25);

EXEC usp_CrearCurso
    @InstructorID = 1,
    @Titulo = 'Curso de prueba',
    @Descripcion = 'Prueba con porcentaje incorrecto.',
    @CategoriaID = 1,
    @Precio = 300.00,
    @ImagenPortada = '/img/prueba.jpg',
    @RequiereEval = 0,
    @PorcentajePrincipal = 120.00,
    @CursoID = @CursoID OUTPUT,
    @CodigoCurso = @CodigoCurso OUTPUT;
GO

-- 2. Pruebas del procedimiento para editar un curso
-- 2.1 Curso editado correctamente
EXEC usp_EditarCurso
    @CursoID = 4,
    @InstructorID = 3,
    @Titulo = 'Power BI Intermedio Actualizado',
    @Descripcion = 'Curso actualizado de Power BI, modelado de datos y dashboards.',
    @CategoriaID = 2,
    @Precio = 375.00,
    @ImagenPortada = '/img/powerbi-actualizado.jpg',
    @RequiereEval = 1;

SELECT *
FROM CURSO
WHERE CursoID = 4;

-- 2.2 Error porque el curso no existe
EXEC usp_EditarCurso
    @CursoID = 99,
    @InstructorID = 3,
    @Titulo = 'Curso de prueba',
    @Descripcion = 'Prueba con un curso inexistente.',
    @CategoriaID = 2,
    @Precio = 300.00,
    @ImagenPortada = '/img/prueba.jpg',
    @RequiereEval = 0;

-- 2.3 Error porque el instructor no es el principal
EXEC usp_EditarCurso
    @CursoID = 4,
    @InstructorID = 1,
    @Titulo = 'Curso de prueba',
    @Descripcion = 'Intento de edicion por otro instructor.',
    @CategoriaID = 2,
    @Precio = 350.00,
    @ImagenPortada = '/img/prueba.jpg',
    @RequiereEval = 0;

-- 2.4 Error porque el curso esta DISPONIBLE
EXEC usp_EditarCurso
    @CursoID = 1,
    @InstructorID = 1,
    @Titulo = 'SQL actualizado',
    @Descripcion = 'Intento de editar un curso disponible.',
    @CategoriaID = 1,
    @Precio = 280.00,
    @ImagenPortada = '/img/sql-nuevo.jpg',
    @RequiereEval = 1;

-- 2.5 Error porque la categoria no existe
EXEC usp_EditarCurso
    @CursoID = 4,
    @InstructorID = 3,
    @Titulo = 'Power BI Intermedio',
    @Descripcion = 'Prueba con categoria incorrecta.',
    @CategoriaID = 99,
    @Precio = 350.00,
    @ImagenPortada = '/img/powerbi.jpg',
    @RequiereEval = 0;

-- 2.6 Error porque el titulo esta vacio
EXEC usp_EditarCurso
    @CursoID = 4,
    @InstructorID = 3,
    @Titulo = '',
    @Descripcion = 'Prueba para validar titulo.',
    @CategoriaID = 2,
    @Precio = 350.00,
    @ImagenPortada = '/img/powerbi.jpg',
    @RequiereEval = 0;

-- 2.7 Error porque la descripcion esta vacia
EXEC usp_EditarCurso
    @CursoID = 4,
    @InstructorID = 3,
    @Titulo = 'Power BI Intermedio',
    @Descripcion = '',
    @CategoriaID = 2,
    @Precio = 350.00,
    @ImagenPortada = '/img/powerbi.jpg',
    @RequiereEval = 0;

-- 2.8 Error porque la imagen esta vacia
EXEC usp_EditarCurso
    @CursoID = 4,
    @InstructorID = 3,
    @Titulo = 'Power BI Intermedio',
    @Descripcion = 'Prueba para validar imagen.',
    @CategoriaID = 2,
    @Precio = 350.00,
    @ImagenPortada = '',
    @RequiereEval = 0;

-- 2.9 Error porque el precio esta fuera del rango
EXEC usp_EditarCurso
    @CursoID = 4,
    @InstructorID = 3,
    @Titulo = 'Power BI Intermedio',
    @Descripcion = 'Prueba con precio incorrecto.',
    @CategoriaID = 2,
    @Precio = 20.00,
    @ImagenPortada = '/img/powerbi.jpg',
    @RequiereEval = 0;

-- 3. Pruebas del procedimiento para agregar un co-instructor
-- 3.1 Co-instructor agregado correctamente
EXEC usp_AgregarCoInstructor
    @CursoID = 7,
    @InstructorPrincipalID = 3,
    @CoInstructorID = 2,
    @PorcentajeParticipacion = 30.00;

SELECT *
FROM EQUIPOCURSO
WHERE CursoID = 7;

-- 3.2 Error porque el curso no existe
EXEC usp_AgregarCoInstructor
    @CursoID = 99,
    @InstructorPrincipalID = 3,
    @CoInstructorID = 2,
    @PorcentajeParticipacion = 20.00;

-- 3.3 Error porque no es el instructor principal
EXEC usp_AgregarCoInstructor
    @CursoID = 7,
    @InstructorPrincipalID = 1,
    @CoInstructorID = 2,
    @PorcentajeParticipacion = 20.00;

-- 3.4 Error porque el curso esta DISPONIBLE
EXEC usp_AgregarCoInstructor
    @CursoID = 1,
    @InstructorPrincipalID = 1,
    @CoInstructorID = 3,
    @PorcentajeParticipacion = 10.00;

-- 3.5 Error porque el co-instructor no es instructor
EXEC usp_AgregarCoInstructor
    @CursoID = 4,
    @InstructorPrincipalID = 3,
    @CoInstructorID = 4,
    @PorcentajeParticipacion = 20.00;

-- 3.6 Error porque el principal intenta agregarse como co-instructor
EXEC usp_AgregarCoInstructor
    @CursoID = 4,
    @InstructorPrincipalID = 3,
    @CoInstructorID = 3,
    @PorcentajeParticipacion = 20.00;

-- 3.7 Error porque el instructor ya pertenece al equipo
--para esta prueba se necesita haber hecho la prueba 3.1 que es en donde se agregó un co-instructor
EXEC usp_AgregarCoInstructor
    @CursoID = 7,
    @InstructorPrincipalID = 3,
    @CoInstructorID = 2,
    @PorcentajeParticipacion = 10.00;

-- 3.8 Error porque el porcentaje es invalido
EXEC usp_AgregarCoInstructor
    @CursoID = 4,
    @InstructorPrincipalID = 3,
    @CoInstructorID = 1,
    @PorcentajeParticipacion = 0;

-- 3.9 Error porque la suma supera el 100%
--Esta prueba también necesita ya haber agregado al instructor de la prueba 3.1
EXEC usp_AgregarCoInstructor
    @CursoID = 7,
    @InstructorPrincipalID = 3,
    @CoInstructorID = 1,
    @PorcentajeParticipacion = 10.00;

-- 4 Pruebas para agregar un requisito a un curso
-- 4.1 Agregar un requisito correctamente
EXEC usp_AgregarRequisitoCurso 7, 1, 3;
	-- @CursoID = 7,
	-- @CursoRequisitoID = 1,
	-- @InstructorID = 3;

SELECT *
FROM CURSOREQUISITO;

-- 4.2 Intentar agregar un requisito repetido, se espera un mensaje de error
EXEC usp_AgregarRequisitoCurso
	@CursoID = 7,
	@CursoRequisitoID = 1,
	@InstructorID = 3;

SELECT *
FROM CURSOREQUISITO;

-- 4.3 Intentar agregar el mismo curso como su propio requisito, se espera un mensaje de error
EXEC usp_AgregarRequisitoCurso 
    @CursoID = 7,
	@CursoRequisitoID = 7,
	@InstructorID = 3;

-- 8.4 Error porque el curso no tiene el mínimo de 3 módulos
EXEC usp_EnviarCursoRevision
	@CursoID = 7,
	@InstructorID = 3;

-- 5 Pruebas para agregar un módulo
-- 5.1 Agregar un módulo correctamente
DECLARE @ModuloID INT;
EXEC usp_AgregarModulo
	@CursoID = 7,
	@InstructorID = 3,
	@NombreModulo = 'Funciones en Python',
	@NoOrden = 3,
	@ModuloID = @ModuloID OUTPUT;

	SELECT @ModuloID AS ModuloIDCreado;

SELECT *
FROM MODULO;
GO

-- 5.2 Intenar agregar un módulo con un número de orden repetido, se espera un mensaje de error
DECLARE @ModuloID INT;

EXEC usp_AgregarModulo
	@CursoID = 7,
	@InstructorID = 3,
	@NombreModulo = 'Programación Orientada a Objetos',
	@NoOrden = 3,
	@ModuloID = @ModuloID OUTPUT;
GO

-- 5.3 Intentar agregar un módulo con el nombre vacío, se espera un mensaje de error
DECLARE @ModuloID INT;
	
EXEC usp_AgregarModulo 
	@CursoID = 7,
	@InstructorID = 3,
	@NombreModulo = '',
	@NoOrden = 4,
	@ModuloID = @ModuloID OUTPUT;
GO

-- 5.4 Intentar agregar un módulo con número de orden inválido, se espera un mensaje de error
DECLARE @ModuloID INT;

EXEC usp_AgregarModulo 
	@CursoID = 7,
	@InstructorID = 3,
	@NombreModulo = 'Manejo de archivos',
	@NoOrden = 0,
	@ModuloID = @ModuloID OUTPUT;
GO

-- 6 Pruebas para agregar una laección
-- 6.1 Agregar una lección correctamente
DECLARE @LeccionID INT;
EXEC usp_AgregarLeccion
	@ModuloID = 21,
	@InstructorID = 3,
	@NombreLeccion = 'Creación de funciones',
	@Contenido = 'Introducción a la creación de funciones en Python',
	@NoOrden = 1,
	@DuracionMinutos = 30,
	@LeccionID = @LeccionID OUTPUT;

SELECT @LeccionID AS LeccionIDCreada

SELECT *
FROM LECCION
WHERE ModuloID = 21;
GO

-- 6.2 Intentar agregar una lección con un número de orden repetido, se espera un mensaje de error
DECLARE @LeccionID INT;

EXEC usp_AgregarLeccion
	@ModuloID = 21,
	@InstructorID = 3,
	@NombreLeccion = 'Parámetros y argumentos',
	@Contenido = 'Uso de parámetros y argumentos en funciones de Python',
	@NoOrden = 1,
	@DuracionMinutos = 25,
	@LeccionID = @LeccionID OUTPUT;
GO

-- 6.3 Intentar agregar un lección con el nombre vacío, se espera un mensaje de error
DECLARE @LeccionID INT;

EXEC usp_AgregarLeccion
	@ModuloID = 21,
	@InstructorID = 3,
	@NombreLeccion = '',
	@Contenido = 'Contenido de prueba para la lección',
	@NoOrden = 2,
	@DuracionMinutos = 25,
	@LeccionID = @LeccionID OUTPUT;
GO

-- 6.4 Intentar agregar una lección con contenido vacío, se espera un mensaje de error
DECLARE @LeccionID INT;

EXEC usp_AgregarLeccion
	@ModuloID = 21,
	@InstructorID = 3,
	@NombreLeccion = 'Retorno de valores',
	@Contenido = '',
	@NoOrden = 2,
	@DuracionMinutos = 25,
	@LeccionID = @LeccionID OUTPUT;
GO

-- 6.5 Intentar agregar una lección con una duración inválida, se espera un mensaje de error
DECLARE @LeccionID INT;

EXEC usp_AgregarLeccion
	@ModuloID = 21,
	@InstructorID = 3,
	@NombreLeccion = 'Retorno de valores',
	@Contenido = 'Uso de return para devolver valores desde una función',
	@NoOrden = 2,
	@DuracionMinutos = 0,
	@LeccionID = @LeccionID OUTPUT;
GO

-- 7 Pruebas para agregar un recurso a una lección
-- 7.1 Agregar un recurso correctamente
DECLARE @RecursoID INT;

EXEC usp_AgregarRecursoLeccion 
	@LeccionID = 24,
	@InstructorID = 3,
	@NombreRecurso = 'Guía de funciones',
	@TipoRecurso = 'PDF',
	@UbicacionRecurso = 'materiales/guia_funciones.pdf',
	@RecursoID = @RecursoID OUTPUT;

SELECT @RecursoID AS RecursoIDCreado;

SELECT *
FROM RECURSOLECCION
WHERE LeccionID = 24;
GO

-- 7.2 Intentar agregar un recurso con el nombre vacío, se espera un mensaje de error
DECLARE @RecursoID INT;

EXEC usp_AgregarRecursoLeccion
	@LeccionID = 24,
	@InstructorID = 3, 
	@NombreRecurso = '',
	@TipoRecurso = 'PDF',
	@UbicacionRecurso = 'materiales/funciones.pdf',
	@RecursoID = @RecursoID OUTPUT;
GO

-- 7.3 Intentar agregar un recurso con el tipo vacío, se espera un mensaje de error
DECLARE @RecursoID INT;

EXEC usp_AgregarRecursoLeccion
	@LeccionID = 24,
	@InstructorID = 3,
	@NombreRecurso = 'Ejercicios de funciones',
	@TipoRecurso = '',
	@UbicacionRecurso = 'materiales/ejercicios_funciones.pdf',
	@RecursoID = @RecursoID OUTPUT;
GO

-- 7.4 Intentar agregar un recurso con la ubicación vacía, se espera un mensaje de error
DECLARE @RecursoID INT;

EXEC usp_AgregarRecursoLeccion
	@LeccionID = 24,
	@InstructorID = 3,
	@NombreRecurso = 'Ejercicios de funciones',
	@TipoRecurso = 'PDF',
	@UbicacionRecurso = '',
	@RecursoID = @RecursoID OUTPUT;
GO

-- 8. Pruebas del procedimiento para enviar un curso a revisión
-- 8.1 Curso enviado a revisión correctamente
EXEC usp_EnviarCursoRevision
	@CursoID = 3,
	@InstructorID = 1;

SELECT CursoID, Titulo, Estado
FROM CURSO
WHERE CursoID = 3;

-- 8.2 Error porque el curso no existe
EXEC usp_EnviarCursoRevision
	@CursoID = 999,
	@InstructorID = 1;

-- 8.3 Error porque el instructor no es el principal
EXEC usp_EnviarCursoRevision
	@CursoID = 4,
	@InstructorID = 1;

-- 9. Pruebas del procedimiento para iniciar una revisión académica
-- 9.1 Revisión académica iniciada correctamente
DECLARE @RevisionID1 INT;
DECLARE @NumRevision1 INT;
EXEC usp_IniciarRevisionAcademica
	@CursoID = 5,
	@RevisorID = 4,
	@RevisionID = @RevisionID1 OUTPUT,
	@NumRevision = @NumRevision1 OUTPUT;

SELECT @RevisionID1 AS RevisionCreada,
	   @NumRevision1 AS NumeroRevision;

SELECT *
FROM REVISIONACADEMICA
WHERE RevisionID = @RevisionID1;
GO

-- 9.2 Error porque el trabajador no es revisor
DECLARE @RevisionID2 INT;
DECLARE @NumRevision2 INT;
EXEC usp_IniciarRevisionAcademica
	@CursoID = 5,
	@RevisorID = 1,
	@RevisionID = @RevisionID2 OUTPUT,
	@NumRevision = @NumRevision2 OUTPUT;
GO

-- 9.3 Error porque el curso no existe
DECLARE @RevisionID3 INT;
DECLARE @NumRevision3 INT;
EXEC usp_IniciarRevisionAcademica
	@CursoID = 999,
	@RevisorID = 4,
	@RevisionID = @RevisionID3 OUTPUT,
	@NumRevision = @NumRevision3 OUTPUT;
GO

-- 9.4 Error porque el curso no está en revisión
DECLARE @RevisionID4 INT;
DECLARE @NumRevision4 INT;
EXEC usp_IniciarRevisionAcademica
	@CursoID = 1,
	@RevisorID = 4,
	@RevisionID = @RevisionID4 OUTPUT,
	@NumRevision = @NumRevision4 OUTPUT;
GO

-- 9.5 Error porque ya existe una revisión pendiente
DECLARE @RevisionID5 INT;
DECLARE @NumRevision5 INT;
EXEC usp_IniciarRevisionAcademica
	@CursoID = 5,
	@RevisorID = 5,
	@RevisionID = @RevisionID5 OUTPUT,
	@NumRevision = @NumRevision5 OUTPUT;
GO

-- 10. Pruebas del procedimiento para resolver una revisión académica
-- 10.1 Error porque el resultado de la revisión es inválido
EXEC usp_ResolverRevisionAcademica
	@RevisionID = 4,
	@RevisorID = 4,
	@Resultado = 'PENDIENTE',
	@Comentario = N'Prueba de resultado invalido.';

-- 10.2 Error porque el comentario está vacío
EXEC usp_ResolverRevisionAcademica
	@RevisionID = 4,
	@RevisorID = 4,
	@Resultado = 'APROBADO',
	@Comentario = N'';

-- 10.3 Revisión rechazada correctamente
EXEC usp_ResolverRevisionAcademica
	@RevisionID = 4,
	@RevisorID = 4,
	@Resultado = 'RECHAZADO',
	@Comentario = N'El curso debe mejorar la estructura y el contenido de los modulos.';

SELECT *
FROM REVISIONACADEMICA
WHERE RevisionID = 4;

SELECT CursoID, Titulo, Estado
FROM CURSO
WHERE CursoID = 5;

SELECT *
FROM NOTIFICACION
WHERE CursoID = 5;

-- 10.4 Error porque la revisión ya fue resuelta
EXEC usp_ResolverRevisionAcademica
	@RevisionID = 4,
	@RevisorID = 4,
	@Resultado = 'APROBADO',
	@Comentario = N'Intento de modificar una revision ya resuelta.';

-- 8.5 Curso rechazado enviado nuevamente a revisión
EXEC usp_EnviarCursoRevision
	@CursoID = 5,
	@InstructorID = 2;

SELECT CursoID, Titulo, Estado
FROM CURSO
WHERE CursoID = 5;

-- 9.6 Segunda revisión académica iniciada correctamente
DECLARE @RevisionID6 INT;
DECLARE @NumRevision6 INT;
EXEC usp_IniciarRevisionAcademica
	@CursoID = 5,
	@RevisorID = 5,
	@RevisionID = @RevisionID6 OUTPUT,
	@NumRevision = @NumRevision6 OUTPUT;

SELECT @RevisionID6 AS RevisionCreada,
	   @NumRevision6 AS NumeroRevision;

SELECT *
FROM REVISIONACADEMICA
WHERE CursoID = 5;
GO

-- 10.5 Segunda revisión aprobada correctamente
EXEC usp_ResolverRevisionAcademica
	@RevisionID = 5,
	@RevisorID = 5,
	@Resultado = 'APROBADO',
	@Comentario = N'El curso cumple con los requisitos academicos y puede publicarse.';

SELECT *
FROM REVISIONACADEMICA
WHERE CursoID = 5;

SELECT CursoID, Titulo, Estado, FechaPublicacion
FROM CURSO
WHERE CursoID = 5;

SELECT *
FROM NOTIFICACION
WHERE CursoID = 5;
GO

-- 11. Pruebas para configurar el rango de precios
-- 11.1 Configurar el rango correctamente
EXEC usp_ConfigurarRangoPrecios
    @AdministradorID = 6,
    @PrecioMinimo = 50.00,
    @PrecioMaximo = 2000.00;

SELECT *
FROM CONFIGURACIONPLATAFORMA;
GO

-- 11.2 Intentar un precio maximo menor que el minimo, se espera un mensaje de error
EXEC usp_ConfigurarRangoPrecios
    @AdministradorID = 6,
    @PrecioMinimo = 500.00,
    @PrecioMaximo = 100.00;
GO

-- 11.3 Intentar configurar con un usuario que no es administrador, se espera un mensaje de error
EXEC usp_ConfigurarRangoPrecios
    @AdministradorID = 2,
    @PrecioMinimo = 50.00,
    @PrecioMaximo = 2000.00;
GO


-- 12. Pruebas para configurar la comision por categoria
-- 12.1 Actualizar la comision correctamente
EXEC usp_ConfigurarComisionCategoria
    @AdministradorID = 6,
    @CategoriaID = 1,
    @PorcentajeComision = 30.00;

SELECT *
FROM CATEGORIA
WHERE CategoriaID = 1;
GO

-- 12.2 Intentar un porcentaje mayor a 100, se espera un mensaje de error
EXEC usp_ConfigurarComisionCategoria
    @AdministradorID = 6,
    @CategoriaID = 1,
    @PorcentajeComision = 150.00;
GO

-- 12.3 Intentar actualizar una categoria que no existe, se espera un mensaje de error
EXEC usp_ConfigurarComisionCategoria
    @AdministradorID = 6,
    @CategoriaID = 9999,
    @PorcentajeComision = 30.00;
GO

-- 13. Pruebas para configurar la comision especial de un instructor
-- 13.1 Asignar una comision especial correctamente
EXEC usp_ConfigurarComisionInstructor
    @AdministradorID = 6,
    @InstructorID = 3,
    @PorcentajeComisionEsp = 18.00;

SELECT *
FROM TRABAJADOR
WHERE TrabajadorID = 3;
GO

-- 13.2 Eliminar la comision especial enviando NULL, debe quedar en NULL
EXEC usp_ConfigurarComisionInstructor
    @AdministradorID = 6,
    @InstructorID = 3,
    @PorcentajeComisionEsp = NULL;

SELECT *
FROM TRABAJADOR
WHERE TrabajadorID = 3;
GO

-- 13.3 Intentar asignar comision a un revisor, se espera un mensaje de error
EXEC usp_ConfigurarComisionInstructor
    @AdministradorID = 6,
    @InstructorID = 4,
    @PorcentajeComisionEsp = 18.00;
GO

-- 13.4 Intentar un porcentaje mayor a 100, se espera un mensaje de error
EXEC usp_ConfigurarComisionInstructor
    @AdministradorID = 6,
    @InstructorID = 3,
    @PorcentajeComisionEsp = 150.00;
GO

-- 14. Pruebas para crear una cohorte
-- 14.1 Crear una cohorte correctamente
DECLARE @CohorteID INT;

EXEC usp_CrearCohorte
    @AdministradorID = 6,
    @CursoID = 1,
    @FechaInicio = '2026-12-01',
    @CupoMax = 50,
    @CohorteID = @CohorteID OUTPUT;

SELECT @CohorteID AS CohorteIDCreada;

SELECT *
FROM COHORTE
WHERE CohorteID = @CohorteID;
GO

-- 14.2 Intentar crear una cohorte con fecha en el pasado, se espera un mensaje de error
DECLARE @CohortePasadaID INT;

EXEC usp_CrearCohorte
    @AdministradorID = 6,
    @CursoID = 1,
    @FechaInicio = '2020-01-01',
    @CupoMax = 50,
    @CohorteID = @CohortePasadaID OUTPUT;
GO

-- 14.3 Intentar crear una cohorte para un curso pendiente, se espera un mensaje de error
DECLARE @CohortePendienteID INT;

EXEC usp_CrearCohorte
    @AdministradorID = 6,
    @CursoID = 7,
    @FechaInicio = '2026-12-01',
    @CupoMax = 50,
    @CohorteID = @CohortePendienteID OUTPUT;
GO

-- 14.4 Intentar crear una cohorte con cupo cero, se espera un mensaje de error
DECLARE @CohorteSinCupoID INT;

EXEC usp_CrearCohorte
    @AdministradorID = 6,
    @CursoID = 1,
    @FechaInicio = '2026-12-01',
    @CupoMax = 0,
    @CohorteID = @CohorteSinCupoID OUTPUT;
GO

-- 15. Pruebas para configurar la politica de reembolso
-- 15.1 Crear una politica correctamente, la vigente (2026-07-01) debe quedar cerrada el 2026-09-30
DECLARE @PoliticaOctubreID INT;

EXEC usp_ConfigurarPoliticaReembolso
    @AdministradorID = 6,
    @DiasLimite = 7,
    @PorcentajeMax = 20.00,
    @FechaInicioVigencia = '2026-10-01',
    @PoliticaID = @PoliticaOctubreID OUTPUT;

SELECT @PoliticaOctubreID AS PoliticaIDCreada;

SELECT *
FROM POLITICAREEMBOLSO
ORDER BY FechaInicioVigencia;
GO

-- 15.2 Crear una segunda politica, la anterior debe quedar cerrada el 2026-10-31
DECLARE @PoliticaNoviembreID INT;

EXEC usp_ConfigurarPoliticaReembolso
    @AdministradorID = 6,
    @DiasLimite = 10,
    @PorcentajeMax = 25.00,
    @FechaInicioVigencia = '2026-11-01',
    @PoliticaID = @PoliticaNoviembreID OUTPUT;

SELECT @PoliticaNoviembreID AS PoliticaIDCreada;

SELECT *
FROM POLITICAREEMBOLSO
ORDER BY FechaInicioVigencia;
GO

-- 15.3 Intentar una politica que inicia antes que la vigente, se espera un mensaje de error
DECLARE @PoliticaInvalidaID INT;

EXEC usp_ConfigurarPoliticaReembolso
    @AdministradorID = 6,
    @DiasLimite = 5,
    @PorcentajeMax = 15.00,
    @FechaInicioVigencia = '2026-10-15',
    @PoliticaID = @PoliticaInvalidaID OUTPUT;
GO

-- 16. Pruebas para configurar un curso destacado
-- 16.1 Quitar un curso de destacados correctamente (el curso 1 inicia con Destacado = 1)
EXEC usp_ConfigurarCursoDestacado
    @AdministradorID = 6,
    @CursoID = 1,
    @Destacado = 0;

SELECT CursoID, Titulo, Estado, Destacado
FROM CURSO
WHERE CursoID = 1;
GO

-- 16.2 Intentar destacar un curso pendiente, se espera un mensaje de error
EXEC usp_ConfigurarCursoDestacado
    @AdministradorID = 6,
    @CursoID = 7,
    @Destacado = 1;
GO

-- 16.3 Intentar destacar un curso que no existe, se espera un mensaje de error
EXEC usp_ConfigurarCursoDestacado
    @AdministradorID = 6,
    @CursoID = 9999,
    @Destacado = 1;
GO