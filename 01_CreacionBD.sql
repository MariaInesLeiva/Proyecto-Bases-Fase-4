--Tabla Usuario
CREATE TABLE USUARIO
(
  UsuarioID INT identity(1,1) NOT NULL primary key,
  Nombre NVARCHAR(80) NOT NULL,
  Apellido NVARCHAR(80) NOT NULL,
  Correo VARCHAR(150) NOT NULL unique,
  FechaRegistro DATETIME NOT NULL default getdate(),
  TipoUsuario VARCHAR(15) NOT NULL check (TipoUsuario in ('ESTUDIANTE', 'TRABAJADOR'))
);

--Tabla Trabajador
CREATE TABLE TRABAJADOR
(
  TrabajadorID INT NOT NULL primary key,
  TipoTrabajador VARCHAR(20) NOT NULL
    check (TipoTrabajador in ('INSTRUCTOR', 'REVISOR', 'ADMINISTRADOR')),
  PorcentajeComisionEsp DECIMAL(5,2) NULL
    check (PorcentajeComisionEsp between 0 and 100),

  FOREIGN KEY (TrabajadorID) REFERENCES USUARIO(UsuarioID),

  check (TipoTrabajador = 'INSTRUCTOR' or PorcentajeComisionEsp is null)
);

--Tabla Billetera
CREATE TABLE BILLETERA
(
  BilleteraID INT identity(1,1) NOT NULL primary key,
  UsuarioID INT NOT NULL unique,
  Saldo DECIMAL(12,2) NOT NULL default 0 check (Saldo >= 0),
  FechaActualizacion DATETIME NOT NULL default getdate(),
  FOREIGN KEY (UsuarioID) REFERENCES USUARIO(UsuarioID)
);

--Tabla Categoria
CREATE TABLE CATEGORIA
(
  CategoriaID INT identity(1,1) NOT NULL primary key,
  NombreCategoria NVARCHAR(100) NOT NULL unique,
  PorcentajeComisionBase DECIMAL(5,2) NOT NULL check (PorcentajeComisionBase between 0 and 100)
);

--Tabla PoliticaReembolso
CREATE TABLE POLITICAREEMBOLSO
(
  PoliticaID INT identity(1,1) NOT NULL primary key,
  DiasLimite INT NOT NULL check (DiasLimite >= 0),
  PorcentajeMax DECIMAL(5,2) NOT NULL check (PorcentajeMax between 0 and 100),
  FechaInicioVigencia DATE NOT NULL,
  FechaFinVigencia DATE NULL,

  check (FechaFinVigencia is null or FechaFinVigencia >= FechaInicioVigencia)
);

--Tabla PeriodoLiquidacion
CREATE TABLE PERIODOLIQUIDACION
(
  PeriodoID INT identity(1,1) NOT NULL primary key,
  Anio INT NOT NULL,
  Mes INT NOT NULL check (Mes between 1 and 12),
  Estado VARCHAR(15) NOT NULL default 'ABIERTO'
    check (Estado in ('ABIERTO', 'EN_PROCESO', 'CERRADO')),
  FechaFinPeriodo DATE NOT NULL,
  unique (Anio, Mes)
);

--Tabla Curso
CREATE TABLE CURSO
(
  CursoID INT identity(1,1) NOT NULL primary key,
  CodigoCurso VARCHAR(25) NOT NULL unique,
  Descripcion NVARCHAR(MAX) NOT NULL,
  CategoriaID INT NOT NULL,
  Precio DECIMAL(10,2) NOT NULL check (Precio > 0),
  ImagenPortada VARCHAR(500) NOT NULL,
  Estado VARCHAR(20) NOT NULL default 'PENDIENTE'
    check (Estado in ('PENDIENTE', 'ENREVISION', 'RECHAZADO', 'DISPONIBLE', 'INACTIVO')),
  FechaCreacion DATETIME NOT NULL default getdate(),
  FechaPublicacion DATETIME NULL,
  Destacado BIT NOT NULL default 0,
  RequiereEval BIT NOT NULL default 0,
  Titulo NVARCHAR(150) NOT NULL,
  FOREIGN KEY (CategoriaID) REFERENCES CATEGORIA(CategoriaID)
);

--Tabla Cohorte
CREATE TABLE COHORTE
(
  CohorteID INT identity(1,1) NOT NULL primary key,
  CursoID INT NOT NULL,
  FechaInicio DATE NOT NULL,
  CupoMax INT NOT NULL check (CupoMax > 0),
  FOREIGN KEY (CursoID) REFERENCES CURSO(CursoID)
);

--Tabla SuscripcionCategoria
CREATE TABLE SUSCRIPCIONCATEGORIA
(
  UsuarioID INT NOT NULL,
  CategoriaID INT NOT NULL,
  FechaSuscripcion DATETIME NOT NULL default getdate(),
  primary key (UsuarioID, CategoriaID),
  FOREIGN KEY (UsuarioID) REFERENCES USUARIO(UsuarioID),
  FOREIGN KEY (CategoriaID) REFERENCES CATEGORIA(CategoriaID)
);

--Tabla EquipoCurso
CREATE TABLE EQUIPOCURSO
(
  CursoID INT NOT NULL,
  InstructorID INT NOT NULL,
  PorcentajeParticipacion DECIMAL(5,2) NOT NULL
    check (PorcentajeParticipacion > 0 and PorcentajeParticipacion <= 100),
  EsPrincipal BIT NOT NULL default 0,
  primary key (CursoID, InstructorID),
  FOREIGN KEY (CursoID) REFERENCES CURSO(CursoID),
  FOREIGN KEY (InstructorID) REFERENCES TRABAJADOR(TrabajadorID)
);

create unique index UX_EquipoCurso_UnPrincipal
on EQUIPOCURSO (CursoID)
where EsPrincipal = 1;

--Tabla RevisionAcademica
CREATE TABLE REVISIONACADEMICA
(
  RevisionID INT identity(1,1) NOT NULL primary key,
  CursoID INT NOT NULL,
  RevisorID INT NOT NULL,
  NumRevision INT NOT NULL check (NumRevision > 0),
  FechaInicio DATETIME NOT NULL default getdate(),
  FechaFin DATETIME NULL,
  Resultado VARCHAR(15) NOT NULL default 'PENDIENTE'
    check (Resultado in ('PENDIENTE', 'APROBADO', 'RECHAZADO')),
  Comentario NVARCHAR(500) NULL,
  FOREIGN KEY (CursoID) REFERENCES CURSO(CursoID),
  FOREIGN KEY (RevisorID) REFERENCES TRABAJADOR(TrabajadorID),
    unique (CursoID, NumRevision)
);

--Tabla CursoRequisito
CREATE TABLE CURSOREQUISITO
(
  CursoID INT NOT NULL,
  CursoRequisitoID INT NOT NULL,
  FOREIGN KEY (CursoID) REFERENCES CURSO(CursoID),
  FOREIGN KEY (CursoRequisitoID) REFERENCES CURSO(CursoID),
  primary key (CursoID, CursoRequisitoID),
  check (CursoID <> CursoRequisitoID)
);

--Tabla Modulo
CREATE TABLE MODULO
(
  ModuloID INT identity(1,1) NOT NULL primary key,
  CursoID INT NOT NULL,
  NombreModulo NVARCHAR(150) NOT NULL,
  NoOrden INT NOT NULL check (NoOrden > 0),
  FOREIGN KEY (CursoID) REFERENCES CURSO(CursoID),
  unique (CursoID, NoOrden)
);

--Tabla Leccion
CREATE TABLE LECCION
(
  LeccionID INT identity(1,1) NOT NULL primary key,
  ModuloID INT NOT NULL,
  NombreLeccion NVARCHAR(150) NOT NULL,
  Contenido NVARCHAR(MAX) NOT NULL,
  NoOrden INT NOT NULL check (NoOrden > 0),
  DuracionMinutos INT NOT NULL check (DuracionMinutos > 0),
  FOREIGN KEY (ModuloID) REFERENCES MODULO(ModuloID),
  unique (ModuloID, NoOrden)
);

--Tabla RecursoLeccion
CREATE TABLE RECURSOLECCION
(
  RecursoID INT identity(1,1) NOT NULL primary key,
  LeccionID INT NOT NULL,
  NombreRecurso NVARCHAR(150) NOT NULL,
  TipoRecurso VARCHAR(20) NOT NULL,
  UbicacionRecurso NVARCHAR(500) NOT NULL,
  FOREIGN KEY (LeccionID) REFERENCES LECCION(LeccionID)
);

--Tabla Inscripcion
CREATE TABLE INSCRIPCION
(
  InscripcionID INT identity(1,1) NOT NULL primary key,
  UsuarioID INT NOT NULL,
  CursoID INT NOT NULL,
  CohorteID INT NULL,
  PoliticaID INT NOT NULL,
  FechaInscripcion DATETIME NOT NULL default getdate(),
  PrecioPagado DECIMAL(10,2) NOT NULL check (PrecioPagado >= 0),
  PorcentajeComiAplicado DECIMAL(5,2) NOT NULL check (PorcentajeComiAplicado between 0 and 100),
  Estado VARCHAR(15) NOT NULL default 'ACTIVA'
    check (Estado in ('ACTIVA', 'COMPLETADA', 'REEMBOLSADA', 'CANCELADA')),
  FechaCompletado DATETIME NULL,
  Liquidada BIT NOT NULL default 0,
  FOREIGN KEY (UsuarioID) REFERENCES USUARIO(UsuarioID),
  FOREIGN KEY (CursoID) REFERENCES CURSO(CursoID),
  FOREIGN KEY (CohorteID) REFERENCES COHORTE(CohorteID),
  FOREIGN KEY (PoliticaID) REFERENCES POLITICAREEMBOLSO(PoliticaID)
);

--Tabla AvanceModulo
CREATE TABLE AVANCEMODULO
(
  InscripcionID INT NOT NULL,
  ModuloID INT NOT NULL,
  FechaCompletado DATETIME NOT NULL default getdate(),
  primary key (InscripcionID, ModuloID),
  FOREIGN KEY (InscripcionID) REFERENCES INSCRIPCION(InscripcionID),
  FOREIGN KEY (ModuloID) REFERENCES MODULO(ModuloID)
);

--Tabla IntentoEvaluacion
CREATE TABLE INTENTOEVALUACION
(
  IntentoID INT identity(1,1) NOT NULL primary key,
  InscripcionID INT NOT NULL,
  NumeroIntento INT NOT NULL check (NumeroIntento between 1 and 3),
  Nota DECIMAL(5,2) NOT NULL check (Nota between 0 and 100),
  FechaIntento DATETIME NOT NULL default getdate(),
  FOREIGN KEY (InscripcionID) REFERENCES INSCRIPCION(InscripcionID),
  unique (InscripcionID, NumeroIntento)
);

--Tabla Certificado
CREATE TABLE CERTIFICADO
(
  Anio INT NOT NULL,
  Correlativo INT NOT NULL check (Correlativo > 0),
  InscripcionID INT NOT NULL unique,
  CodigoCertificado VARCHAR(30) NOT NULL unique,
  FechaEmision DATETIME NOT NULL default getdate(),
  Estado VARCHAR(25) NOT NULL default 'VALIDO'
    check (Estado in ('VALIDO', 'PENDIENTE_VERIFICACION', 'REVOCADO')),
  MotivoRevision NVARCHAR(500) NULL,
  primary key (Anio, Correlativo),
  FOREIGN KEY (InscripcionID) REFERENCES INSCRIPCION(InscripcionID)
);

--SolicitudReembolso
CREATE TABLE SOLICITUDREEMBOLSO
(
  ReembolsoID INT identity(1,1) NOT NULL primary key,
  InscripcionID INT NOT NULL,
  FechaSolicitud DATETIME NOT NULL default getdate(),
  FechaDecision DATETIME NULL,
  Motivo NVARCHAR(500) NOT NULL,
  PorcentajeAvance DECIMAL(5,2) NOT NULL check (PorcentajeAvance between 0 and 100),
  MontoReembolsado DECIMAL(10,2) NULL check (MontoReembolsado >= 0),
  PersonaQueAutoriza INT NULL,
  Estado VARCHAR(15) NOT NULL default 'SOLICITADO'
    check (Estado in ('SOLICITADO', 'APROBADO', 'RECHAZADO', 'EJECUTADO')),
  FOREIGN KEY (InscripcionID) REFERENCES INSCRIPCION(InscripcionID),
  FOREIGN KEY (PersonaQueAutoriza) REFERENCES TRABAJADOR(TrabajadorID)
);

--Tabla AjusteComision
CREATE TABLE AJUSTECOMISION
(
  AjusteID INT identity(1,1) NOT NULL primary key,
  ReembolsoID INT NOT NULL,
  InstructorID INT NOT NULL,
  MontoOriginal DECIMAL(10,2) NOT NULL check (MontoOriginal > 0),
  MontoPendiente DECIMAL(10,2) NOT NULL check (MontoPendiente >= 0),
  FechaGeneracion DATETIME NOT NULL default getdate(),

  FOREIGN KEY (InstructorID) REFERENCES TRABAJADOR(TrabajadorID),
  FOREIGN KEY (ReembolsoID) REFERENCES SOLICITUDREEMBOLSO(ReembolsoID),

  unique (ReembolsoID, InstructorID),

  check (MontoPendiente <= MontoOriginal)
);

--Tabla Liquidacion
CREATE TABLE LIQUIDACION
(
  LiquidacionID INT identity(1,1) NOT NULL primary key,
  PeriodoID INT NOT NULL,
  InstructorID INT NOT NULL,
  FechaLiquidacion DATETIME NOT NULL default getdate(),
  Estado VARCHAR(15) NOT NULL default 'CALCULADA'
    check (Estado in ('CALCULADA', 'PAGADA')),
  FOREIGN KEY (InstructorID) REFERENCES TRABAJADOR(TrabajadorID),
  FOREIGN KEY (PeriodoID) REFERENCES PERIODOLIQUIDACION(PeriodoID),
  unique (PeriodoID, InstructorID)
);

--Tabla DetalleLiquidacion
CREATE TABLE DETALLELIQUIDACION
(
  DetalleLiquidacionID INT identity(1,1) NOT NULL primary key,
  LiquidacionID INT NOT NULL,
  TipoDetalle VARCHAR(15) NOT NULL check (TipoDetalle in ('COMISION', 'AJUSTE')),
  InscripcionID INT NULL,
  AjusteID INT NULL,
  PorcentajeParticipacion DECIMAL(5,2) NULL,
  Monto DECIMAL(10,2) NOT NULL,

  FOREIGN KEY (LiquidacionID) REFERENCES LIQUIDACION(LiquidacionID),
  FOREIGN KEY (InscripcionID) REFERENCES INSCRIPCION(InscripcionID),
  FOREIGN KEY (AjusteID) REFERENCES AJUSTECOMISION(AjusteID),

  check (
    (TipoDetalle = 'COMISION' and InscripcionID is not null and AjusteID is null
      and PorcentajeParticipacion is not null and Monto > 0)
    or
    (TipoDetalle = 'AJUSTE' and InscripcionID is null and AjusteID is not null
      and PorcentajeParticipacion is null and Monto < 0)
  )
);

--Tabla OperacionBilletera
CREATE TABLE OPERACIONBILLETERA
(
  OperacionID INT identity(1,1) NOT NULL primary key,
  BilleteraID INT NOT NULL,
  TipoOperacion VARCHAR(25) NOT NULL
    check (TipoOperacion in ('RECARGA', 'COBRO_INSCRIPCION', 'REEMBOLSO', 'PAGO_COMISION')),
  Monto DECIMAL(12,2) NOT NULL check (Monto > 0),
  FechaOperacion DATETIME NOT NULL default getdate(),
  InscripcionID INT NULL,
  ReembolsoID INT NULL,
  LiquidacionID INT NULL,
  Descripcion NVARCHAR(250) NULL,

  FOREIGN KEY (BilleteraID) REFERENCES BILLETERA(BilleteraID),
  FOREIGN KEY (InscripcionID) REFERENCES INSCRIPCION(InscripcionID),
  FOREIGN KEY (ReembolsoID) REFERENCES SOLICITUDREEMBOLSO(ReembolsoID),
  FOREIGN KEY (LiquidacionID) REFERENCES LIQUIDACION(LiquidacionID),

  check (
    (TipoOperacion = 'RECARGA'
      and InscripcionID is null
      and ReembolsoID is null
      and LiquidacionID is null)

    or

    (TipoOperacion = 'COBRO_INSCRIPCION'
      and InscripcionID is not null
      and ReembolsoID is null
      and LiquidacionID is null)

    or

    (TipoOperacion = 'REEMBOLSO'
      and InscripcionID is null
      and ReembolsoID is not null
      and LiquidacionID is null)

    or

    (TipoOperacion = 'PAGO_COMISION'
      and InscripcionID is null
      and ReembolsoID is null
      and LiquidacionID is not null)
  )
);

--Tabla ConfiguracionPlataforma
create table CONFIGURACIONPLATAFORMA
(
  ConfiguracionID INT NOT NULL primary key
    check (ConfiguracionID = 1),

  PrecioMinimo DECIMAL(10,2) NOT NULL
    check (PrecioMinimo > 0),

  PrecioMaximo DECIMAL(10,2) NOT NULL,

  check (PrecioMaximo >= PrecioMinimo)
);

--Tabla Notificacion
create table NOTIFICACION
(
  NotificacionID INT identity(1,1) NOT NULL primary key,
  UsuarioID INT NOT NULL,
  CursoID INT NULL,
  Tipo VARCHAR(30) NOT NULL,
  Asunto NVARCHAR(150) NOT NULL,
  Mensaje NVARCHAR(500) NOT NULL,
  FechaCreacion DATETIME NOT NULL default getdate(),
  Estado VARCHAR(15) NOT NULL default 'PENDIENTE'
    check (Estado in ('PENDIENTE', 'ENVIADA')),

  FOREIGN KEY (UsuarioID) REFERENCES USUARIO(UsuarioID),
  FOREIGN KEY (CursoID) REFERENCES CURSO(CursoID)
);