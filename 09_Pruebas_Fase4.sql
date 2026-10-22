USE EDUGT;
GO
 
-- Pruebas para solicitar un reembolso
-- 1.1 Solicitud de reembolso correcta
-- Verifica que una inscripcion valida pueda generar la solicitud.
 
declare @ReembolsoID int;
 
exec usp_SolicitarReembolso
    @InscripcionID = 24,
    @Motivo = N'El curso no cumplio mis expectativas.',
    @ReembolsoID = @ReembolsoID output;
 
select @ReembolsoID as ReembolsoID;
 
select *
from SOLICITUDREEMBOLSO
where ReembolsoID = @ReembolsoID;
 
GO
 
-- 1.2 Error por inscripcion inexistente
-- Verifica que no se acepte una inscripcion que no existe.
 
declare @ReembolsoID int;
 
exec usp_SolicitarReembolso
    @InscripcionID = 999,
    @Motivo = N'Solicitud de reembolso.',
    @ReembolsoID = @ReembolsoID output;
 
GO
 
-- 1.3 Error por inscripcion no activa
-- Verifica que solo se permitan solicitudes de inscripciones activas.
 
declare @ReembolsoID int;
 
exec usp_SolicitarReembolso
    @InscripcionID = 27,
    @Motivo = N'Solicitud de reembolso.',
    @ReembolsoID = @ReembolsoID output;
 
GO
 
-- 1.4 Error por motivo vacio
-- Verifica que se indique un motivo para solicitar el reembolso.
 
declare @ReembolsoID int;
 
exec usp_SolicitarReembolso
    @InscripcionID = 24,
    @Motivo = N'',
    @ReembolsoID = @ReembolsoID output;
 
GO
 
-- 1.5 Error por solicitud duplicada
-- Verifica que no se creen dos solicitudes activas para la misma inscripcion.
 
declare @ReembolsoID int;
 
exec usp_SolicitarReembolso
    @InscripcionID = 24,
    @Motivo = N'Solicito nuevamente el reembolso.',
    @ReembolsoID = @ReembolsoID output;
 
GO
 
-- 1.6 Error por plazo vencido
-- Verifica que la solicitud se realice dentro del tiempo permitido.
 
declare @ReembolsoID int;
 
exec usp_SolicitarReembolso
    @InscripcionID = 25,
    @Motivo = N'El curso no cumplio mis expectativas.',
    @ReembolsoID = @ReembolsoID output;
 
GO
 
-- 1.7 Error por avance superior al permitido
-- Verifica que el progreso sea menor al limite de la politica.
 
declare @ReembolsoID int;
 
exec usp_SolicitarReembolso
    @InscripcionID = 26,
    @Motivo = N'El curso no cumplio mis expectativas.',
    @ReembolsoID = @ReembolsoID output;
 
GO
 
-- 1.8 Error por certificado emitido
-- Verifica que no se permita reembolso si la inscripcion ya tiene certificado.
 
begin transaction;
 
delete from AVANCEMODULO
where InscripcionID = 27;
 
update INSCRIPCION
set Estado = 'ACTIVA',
    FechaCompletado = null
where InscripcionID = 27;
 
begin try
 
    declare @ReembolsoID int;
 
    exec usp_SolicitarReembolso
        @InscripcionID = 27,
        @Motivo = N'Solicitud de reembolso.',
        @ReembolsoID = @ReembolsoID output;
 
end try
 
begin catch
 
    select
        error_number() as NumeroError,
        error_message() as Mensaje;
 
end catch;
 
rollback transaction;
GO
 
-- Pruebas para procesar un reembolso
 
-- Prueba 2.1 procesar un reembolso exitoso
-- Se procesa la solicitud creada en la prueba 1.1 (inscripcion 24)
DECLARE @ReembolsoID INT;
 
SELECT @ReembolsoID = ReembolsoID
FROM SOLICITUDREEMBOLSO
WHERE InscripcionID = 24 AND Estado = 'SOLICITADO';
 
EXEC usp_ProcesarReembolso
	@ReembolsoID = @ReembolsoID,
	@PersonaAutoriza = 1;
 
-- Para comprobar que si se realizó el reembolso
SELECT S.ReembolsoID, S.Estado AS EstadoReembolso,
	S.MontoReembolsado,
	I.Estado AS EstadoInscripcion,
	B.Saldo
FROM SOLICITUDREEMBOLSO S
INNER JOIN INSCRIPCION I
	ON S.InscripcionID = I.InscripcionID
INNER JOIN BILLETERA B
	ON I.UsuarioID = B.UsuarioID
WHERE S.InscripcionID = 24;
GO
 
-- Prueba 2.2 reembolso de una inscripción que ya fue liquidada
-- Se crea una solicitud
DECLARE @ReembolsoID INT;
 
EXEC usp_SolicitarReembolso
	@InscripcionID = 31,
	@Motivo= 'El curso no cumplió con mis expectativas',
	@ReembolsoID = @ReembolsoID OUTPUT;
 
SELECT @ReembolsoID AS ReembolsoID;
 
-- Se procesa el reembolso con las comisiones liquidadas
EXEC usp_ProcesarReembolso
	@ReembolsoID = @ReembolsoID,
	@PersonaAutoriza = 1;
 
SELECT ReembolsoID, InstructorID, MontoOriginal, MontoPendiente
FROM AJUSTECOMISION
WHERE ReembolsoID = @ReembolsoID;
GO
 
--Prueba 2.3 intentar procesar un reembolso que ya se ejecutó, se espera un mensaje de error
DECLARE @ReembolsoID INT;
 
SELECT @ReembolsoID = ReembolsoID
FROM SOLICITUDREEMBOLSO
WHERE InscripcionID = 31;
 
EXEC usp_ProcesarReembolso
	@ReembolsoID = @ReembolsoID,
	@PersonaAutoriza = 1;
GO
 
-- Prueba 2.4 procesar un reembolso inexistente, se espera un mensaje de error
EXEC usp_ProcesarReembolso
	@ReembolsoID = 1000,
	@PersonaAutoriza = 1;
GO
 
-- Prueba 2.5 intentar procesar un reembolso rechazado, se espera un mensaje de error
EXEC usp_ProcesarReembolso
	@ReembolsoID = 2,
	@PersonaAutoriza = 1;
GO
 
-- Prueba 2.6 verificar las operaciones de billetera y notificaciones
-- Verificar las operaciones que hay en billetera
SELECT ReembolsoID,
	TipoOperacion,
	Monto,
	Descripcion
FROM OPERACIONBILLETERA
WHERE ReembolsoID IN (SELECT ReembolsoID
                      FROM SOLICITUDREEMBOLSO
                      WHERE InscripcionID IN (24, 31));
 
-- Verificar las notificaciones de los estudiantes
SELECT UsuarioID,
	Tipo,
	Asunto,
	Mensaje,
	Estado
FROM NOTIFICACION
WHERE UsuarioID IN (19, 23)
	AND Tipo = 'REEMBOLSO';
GO
 
-- Prueba 2.7 verificar notificaciones de contracargo
SELECT UsuarioID,
	Tipo,
	Asunto,
	Estado
FROM NOTIFICACION
WHERE UsuarioID IN (1, 2)
	AND Tipo = 'CONTRACARGO';
GO
 
-- Las pruebas 1 y 2 guardan sus cambios. Restaurar 03, 05 y 07 antes de continuar
 
-- Pruebas de liquidación financiera
 
-- PRUEBA 3.1: estado inicial de septiembre 2026.
SELECT PeriodoID, Anio, Mes, Estado, FechaFinPeriodo
FROM PERIODOLIQUIDACION
WHERE PeriodoID = 3;
GO
 
-- PRUEBA 3.2: ejecutar, comprobar y revertir.
BEGIN TRY
    BEGIN TRANSACTION;
 
    DECLARE @SaldoAntes DECIMAL(18,2);
    DECLARE @SaldoDespues DECIMAL(18,2);
    DECLARE @TotalPagos DECIMAL(18,2);
 
    SELECT @SaldoAntes = ISNULL(SUM(BILLETERA.Saldo), 0)
    FROM BILLETERA
    INNER JOIN TRABAJADOR
      ON BILLETERA.UsuarioID = TRABAJADOR.TrabajadorID
    WHERE TRABAJADOR.TipoTrabajador = 'INSTRUCTOR';
 
    EXEC usp_LiquidarPeriodo @PeriodoID = 3;
 
    -- 3.2.1: el periodo debe quedar CERRADO.
    SELECT PeriodoID, Anio, Mes, Estado
    FROM PERIODOLIQUIDACION
    WHERE PeriodoID = 3;
 
    IF (SELECT Estado FROM PERIODOLIQUIDACION WHERE PeriodoID = 3) <> 'CERRADO'
        THROW 51801, 'Prueba fallida: periodo no cerrado.', 1;
 
    -- 3.2.2: cada inscripcion liquidada de septiembre.
    SELECT InscripcionID, CursoID, PrecioPagado, Estado, Liquidada
    FROM INSCRIPCION
    WHERE YEAR(FechaInscripcion) = 2026 AND MONTH(FechaInscripcion) = 9
    ORDER BY InscripcionID;
 
    -- 3.2.3: la plataforma + los instructores deben sumar PrecioPagado.
    -- La columna Diferencia debe ser 0.00 para cada inscripcion valida.
    SELECT INSCRIPCION.InscripcionID,
           INSCRIPCION.PrecioPagado,
           ROUND(INSCRIPCION.PrecioPagado * INSCRIPCION.PorcentajeComiAplicado / 100.00, 2)
              AS ComisionPlataforma,
           ISNULL((
               SELECT SUM(DETALLELIQUIDACION.Monto)
               FROM DETALLELIQUIDACION
               INNER JOIN LIQUIDACION
                  ON DETALLELIQUIDACION.LiquidacionID = LIQUIDACION.LiquidacionID
               WHERE LIQUIDACION.PeriodoID = 3
                 AND DETALLELIQUIDACION.TipoDetalle = 'COMISION'
                 AND DETALLELIQUIDACION.InscripcionID = INSCRIPCION.InscripcionID
           ), 0) AS ComisionesInstructores,
           INSCRIPCION.PrecioPagado
             - ROUND(INSCRIPCION.PrecioPagado * INSCRIPCION.PorcentajeComiAplicado / 100.00, 2)
             - ISNULL((
                 SELECT SUM(DETALLELIQUIDACION.Monto)
                 FROM DETALLELIQUIDACION
                 INNER JOIN LIQUIDACION
                    ON DETALLELIQUIDACION.LiquidacionID = LIQUIDACION.LiquidacionID
                 WHERE LIQUIDACION.PeriodoID = 3
                   AND DETALLELIQUIDACION.TipoDetalle = 'COMISION'
                   AND DETALLELIQUIDACION.InscripcionID = INSCRIPCION.InscripcionID
             ), 0) AS Diferencia
    FROM INSCRIPCION
    WHERE YEAR(INSCRIPCION.FechaInscripcion) = 2026
      AND MONTH(INSCRIPCION.FechaInscripcion) = 9
      AND INSCRIPCION.Estado IN ('ACTIVA', 'COMPLETADA')
      AND INSCRIPCION.Liquidada = 1
    ORDER BY INSCRIPCION.InscripcionID;
 
    IF EXISTS (
        SELECT 1
        FROM INSCRIPCION
        WHERE YEAR(INSCRIPCION.FechaInscripcion) = 2026
          AND MONTH(INSCRIPCION.FechaInscripcion) = 9
          AND INSCRIPCION.Estado IN ('ACTIVA', 'COMPLETADA')
          AND INSCRIPCION.Liquidada = 1
          AND INSCRIPCION.PrecioPagado
            - ROUND(INSCRIPCION.PrecioPagado * INSCRIPCION.PorcentajeComiAplicado / 100.00, 2)
            - ISNULL((
                SELECT SUM(DETALLELIQUIDACION.Monto)
                FROM DETALLELIQUIDACION
                INNER JOIN LIQUIDACION
                    ON DETALLELIQUIDACION.LiquidacionID = LIQUIDACION.LiquidacionID
                WHERE LIQUIDACION.PeriodoID = 3
                  AND DETALLELIQUIDACION.TipoDetalle = 'COMISION'
                  AND DETALLELIQUIDACION.InscripcionID = INSCRIPCION.InscripcionID
            ), 0) <> 0
    )
        THROW 51802, 'Prueba fallida: el reparto no cuadra.', 1;
 
    -- 3.2.4: ver comisiones, ajustes y pagos sin tablas auxiliares.
    SELECT LIQUIDACION.InstructorID,
           LIQUIDACION.Estado,
           DETALLELIQUIDACION.TipoDetalle,
           DETALLELIQUIDACION.InscripcionID,
           DETALLELIQUIDACION.AjusteID,
           DETALLELIQUIDACION.Monto
    FROM LIQUIDACION
    INNER JOIN DETALLELIQUIDACION
       ON LIQUIDACION.LiquidacionID = DETALLELIQUIDACION.LiquidacionID
    WHERE LIQUIDACION.PeriodoID = 3
    ORDER BY LIQUIDACION.InstructorID, DETALLELIQUIDACION.DetalleLiquidacionID;
 
    -- 3.2.5: las operaciones registradas deben igualar el cambio de saldo.
    SELECT @SaldoDespues = ISNULL(SUM(BILLETERA.Saldo), 0)
    FROM BILLETERA
    INNER JOIN TRABAJADOR
      ON BILLETERA.UsuarioID = TRABAJADOR.TrabajadorID
    WHERE TRABAJADOR.TipoTrabajador = 'INSTRUCTOR';
 
    SELECT @TotalPagos = ISNULL(SUM(OPERACIONBILLETERA.Monto), 0)
    FROM OPERACIONBILLETERA
    INNER JOIN LIQUIDACION
      ON OPERACIONBILLETERA.LiquidacionID = LIQUIDACION.LiquidacionID
    WHERE LIQUIDACION.PeriodoID = 3
      AND OPERACIONBILLETERA.TipoOperacion = 'PAGO_COMISION';
 
    SELECT @SaldoAntes AS SaldoTotalAntes,
           @SaldoDespues AS SaldoTotalDespues,
           @SaldoDespues - @SaldoAntes AS CambioTotal,
           @TotalPagos AS PagosRegistrados;
 
    IF @SaldoDespues - @SaldoAntes <> @TotalPagos
        THROW 51803, 'Prueba fallida: billeteras no coinciden con pagos.', 1;
 
    -- 3.2.6: verificar si se consumio el ajuste pendiente de muestra.
    SELECT AjusteID, InstructorID, MontoOriginal, MontoPendiente
    FROM AJUSTECOMISION
    WHERE AjusteID = 1;
 
    PRINT 'PRUEBA SUPERADA. Se revierten los datos con ROLLBACK.';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
-- PRUEBA 3.3: impedir liquidar un periodo ya cerrado.
BEGIN TRY
    EXEC usp_LiquidarPeriodo @PeriodoID = 1;
    PRINT 'ERROR EN PRUEBA: se acepto un periodo cerrado.';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
    -- Se espera el numero 51602.
END CATCH;
GO
 
-- PRUEBA 3.4: rechazar un periodo inexistente.
BEGIN TRY
    EXEC usp_LiquidarPeriodo @PeriodoID = -999;
    PRINT 'ERROR EN PRUEBA: se acepto un periodo inexistente.';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
    -- Se espera el numero 51601.
END CATCH;
GO
 
-- Prueba 3.5: Contracargo mayor que las comisiones
 
BEGIN TRY
    BEGIN TRANSACTION;
 
    DECLARE @ComisionesInstructor2 DECIMAL(18,2);
    DECLARE @AjustesInstructor2 DECIMAL(18,2);
    DECLARE @PagoInstructor2 DECIMAL(18,2);
    DECLARE @PendienteFinal DECIMAL(18,2);
    DECLARE @SaldoAntes DECIMAL(18,2);
    DECLARE @SaldoDespues DECIMAL(18,2);
 
    IF NOT EXISTS (
        SELECT 1 FROM PERIODOLIQUIDACION
        WHERE PeriodoID = 3 AND Estado = 'ABIERTO'
    )
        THROW 51811, 'Prueba E: el periodo 3 debe estar ABIERTO.', 1;
 
    IF EXISTS (SELECT 1 FROM LIQUIDACION WHERE PeriodoID = 3)
        THROW 51812, 'Prueba E: el periodo 3 ya tiene liquidaciones.', 1;
 
    SELECT @SaldoAntes = Saldo
    FROM BILLETERA WHERE UsuarioID = 2;
 
    IF @SaldoAntes IS NULL
        THROW 51813, 'Prueba E: falta la billetera del instructor 2.', 1;
 
    -- Solo para la prueba: deuda mayor que su comision de septiembre.
    UPDATE AJUSTECOMISION
    SET MontoOriginal = 1000.00,
        MontoPendiente = 1000.00
    WHERE AjusteID = 1 AND InstructorID = 2;
 
    IF @@ROWCOUNT <> 1
        THROW 51814, 'Prueba E: no se encontro el ajuste 1 del instructor 2.', 1;
 
    EXEC usp_LiquidarPeriodo @PeriodoID = 3;
 
    SELECT @ComisionesInstructor2 = ISNULL(SUM(DETALLELIQUIDACION.Monto), 0)
    FROM DETALLELIQUIDACION
    INNER JOIN LIQUIDACION
       ON DETALLELIQUIDACION.LiquidacionID = LIQUIDACION.LiquidacionID
    WHERE LIQUIDACION.PeriodoID = 3
      AND LIQUIDACION.InstructorID = 2
      AND DETALLELIQUIDACION.TipoDetalle = 'COMISION';
 
    SELECT @AjustesInstructor2 = ISNULL(SUM(DETALLELIQUIDACION.Monto), 0)
    FROM DETALLELIQUIDACION
    INNER JOIN LIQUIDACION
       ON DETALLELIQUIDACION.LiquidacionID = LIQUIDACION.LiquidacionID
    WHERE LIQUIDACION.PeriodoID = 3
      AND LIQUIDACION.InstructorID = 2
      AND DETALLELIQUIDACION.TipoDetalle = 'AJUSTE';
 
    SELECT @PagoInstructor2 = ISNULL(SUM(OPERACIONBILLETERA.Monto), 0)
    FROM OPERACIONBILLETERA
    INNER JOIN LIQUIDACION
       ON OPERACIONBILLETERA.LiquidacionID = LIQUIDACION.LiquidacionID
    WHERE LIQUIDACION.PeriodoID = 3
      AND LIQUIDACION.InstructorID = 2
      AND OPERACIONBILLETERA.TipoOperacion = 'PAGO_COMISION';
 
    SELECT @PendienteFinal = MontoPendiente
    FROM AJUSTECOMISION WHERE AjusteID = 1;
 
    SELECT @SaldoDespues = Saldo
    FROM BILLETERA WHERE UsuarioID = 2;
 
    SELECT @ComisionesInstructor2 AS ComisionesNuevas,
           @AjustesInstructor2 AS AjusteAplicado,
           @PagoInstructor2 AS PagoInstructor2,
           @PendienteFinal AS DeudaParaProximoPeriodo,
           @SaldoAntes AS BilleteraAntes,
           @SaldoDespues AS BilleteraDespues;
 
    IF @ComisionesInstructor2 <= 0 OR @ComisionesInstructor2 >= 1000
        THROW 51815, 'Prueba E: las comisiones no son menores que Q1000.', 1;
 
    IF @AjustesInstructor2 <> -@ComisionesInstructor2
        THROW 51816, 'Prueba E: no se desconto toda la comision disponible.', 1;
 
    IF @PendienteFinal <> 1000.00 - @ComisionesInstructor2
        THROW 51817, 'Prueba E: el remanente de la deuda es incorrecto.', 1;
 
    IF @PagoInstructor2 <> 0 OR @SaldoDespues <> @SaldoAntes
        THROW 51818, 'Prueba E: el instructor recibio un pago indebido.', 1;
 
    IF NOT EXISTS (
        SELECT 1 FROM LIQUIDACION
        WHERE PeriodoID = 3 AND InstructorID = 2 AND Estado = 'PAGADA'
    )
        THROW 51819, 'Prueba E: falta la liquidacion PAGADA del instructor 2.', 1;
 
    PRINT 'PRUEBA E SUPERADA. Pago Q0, deuda restante conservada.';
    PRINT 'Se revierte todo con ROLLBACK.';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
    PRINT 'PRUEBA E NO SUPERADA.';
END CATCH;
GO
 
-- Verificacion DESPUES del rollback (en datos base: Q240).
SELECT AjusteID, InstructorID, MontoOriginal, MontoPendiente
FROM AJUSTECOMISION WHERE AjusteID = 1;
SELECT PeriodoID, Estado FROM PERIODOLIQUIDACION WHERE PeriodoID = 3;
GO
 
--PRUEBA 3.6: error DURANTE el pago y rollback de todos los cambios.
 
DECLARE @Saldo1Antes DECIMAL(18,2);
DECLARE @Saldo2Antes DECIMAL(18,2);
DECLARE @Saldo1Despues DECIMAL(18,2);
DECLARE @Saldo2Despues DECIMAL(18,2);
DECLARE @OperacionesAntes INT;
DECLARE @OperacionesDespues INT;
DECLARE @UsuarioPruebaID INT;
DECLARE @ErrorProducido INT = 0;
 
SELECT @Saldo1Antes = Saldo FROM BILLETERA WHERE UsuarioID = 1;
SELECT @Saldo2Antes = Saldo FROM BILLETERA WHERE UsuarioID = 2;
SELECT @OperacionesAntes = COUNT(*) FROM OPERACIONBILLETERA;
 
BEGIN TRY
    IF @Saldo1Antes IS NULL OR @Saldo2Antes IS NULL
        THROW 51821, 'Prueba F: faltan billeteras iniciales.', 1;
 
    IF NOT EXISTS (
        SELECT 1 FROM PERIODOLIQUIDACION
        WHERE PeriodoID = 3 AND Estado = 'ABIERTO'
    )
        THROW 51822, 'Prueba F: el periodo 3 debe estar ABIERTO.', 1;
 
    IF EXISTS (SELECT 1 FROM LIQUIDACION WHERE PeriodoID = 3)
        THROW 51823, 'Prueba F: el periodo 3 tiene liquidaciones previas.', 1;
 
    BEGIN TRANSACTION;
 
    INSERT INTO USUARIO (Nombre, Apellido, Correo, TipoUsuario)
    VALUES (N'Usuario', N'TemporalRollback',
            'prueba.rollback.liquidacion@edugt.test', 'ESTUDIANTE');
 
    SET @UsuarioPruebaID = SCOPE_IDENTITY();
 
    -- Se conserva la billetera; solo se cambia TEMPORALMENTE su titular.
    UPDATE BILLETERA
    SET UsuarioID = @UsuarioPruebaID
    WHERE UsuarioID = 1;
 
    IF @@ROWCOUNT <> 1
        THROW 51824, 'Prueba F: no se pudo preparar el error.', 1;
 
    -- Debe fallar con 51610 al buscar la billetera del instructor 1.
    EXEC usp_LiquidarPeriodo @PeriodoID = 3;
 
    -- Si se llegara aqui, seria un fallo de la prueba.
    THROW 51825, 'Prueba F: el procedimiento acepto instructor sin billetera.', 1;
END TRY
BEGIN CATCH
    SET @ErrorProducido = ERROR_NUMBER();
 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
 
    SELECT @Saldo1Despues = Saldo FROM BILLETERA WHERE UsuarioID = 1;
    SELECT @Saldo2Despues = Saldo FROM BILLETERA WHERE UsuarioID = 2;
    SELECT @OperacionesDespues = COUNT(*) FROM OPERACIONBILLETERA;
 
    SELECT @ErrorProducido AS NumeroError,
           ERROR_MESSAGE() AS MensajeError,
           @Saldo1Antes AS Saldo1Antes,
           @Saldo1Despues AS Saldo1Despues,
           @Saldo2Antes AS Saldo2Antes,
           @Saldo2Despues AS Saldo2Despues,
           @OperacionesAntes AS OperacionesAntes,
           @OperacionesDespues AS OperacionesDespues;
 
    IF @ErrorProducido = 51610
       AND @Saldo1Antes = @Saldo1Despues
       AND @Saldo2Antes = @Saldo2Despues
       AND @OperacionesAntes = @OperacionesDespues
       AND NOT EXISTS (SELECT 1 FROM LIQUIDACION WHERE PeriodoID = 3)
       AND EXISTS (SELECT 1 FROM PERIODOLIQUIDACION
                   WHERE PeriodoID = 3 AND Estado = 'ABIERTO')
       AND NOT EXISTS (SELECT 1 FROM INSCRIPCION
                       WHERE InscripcionID IN (2,3,4,7) AND Liquidada = 1)
       AND EXISTS (SELECT 1 FROM AJUSTECOMISION
                   WHERE AjusteID = 1 AND MontoPendiente = 240.00)
       AND NOT EXISTS (SELECT 1 FROM USUARIO
                       WHERE Correo = 'prueba.rollback.liquidacion@edugt.test')
        PRINT 'PRUEBA F SUPERADA: hubo error durante pagos y ROLLBACK total.';
    ELSE
        PRINT 'PRUEBA F NO SUPERADA: revisar error y valores posteriores.';
END CATCH;
GO
 
--PRUEBA 3.7: Ventana A de SSMS.
BEGIN TRY
    BEGIN TRANSACTION;
 
    IF NOT EXISTS (
        SELECT 1 FROM PERIODOLIQUIDACION
        WHERE PeriodoID = 3 AND Estado = 'ABIERTO'
    )
        THROW 51841, 'Ventana A: periodo 3 no esta ABIERTO.', 1;
 
    IF EXISTS (SELECT 1 FROM LIQUIDACION WHERE PeriodoID = 3)
        THROW 51842, 'Ventana A: el periodo ya tiene liquidaciones.', 1;
 
    EXEC usp_LiquidarPeriodo @PeriodoID = 3;
 
    PRINT 'VENTANA A: periodo procesado. Mantengo la transaccion 25 segundos.';
    PRINT 'EJECUTA AHORA la Ventana B (antes de que terminen los 25 segundos).';
    WAITFOR DELAY '00:00:25';
 
    PRINT 'VENTANA A: ROLLBACK. No quedaran pagos definitivos.';
    ROLLBACK TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
SELECT PeriodoID, Estado FROM PERIODOLIQUIDACION WHERE PeriodoID = 3;
GO
 
--PRUEBA 3.8: Ventana B de SSMS.
 
SET LOCK_TIMEOUT 5000; -- Esperar maximo 5 segundos por un bloqueo.
 
BEGIN TRY
    EXEC usp_LiquidarPeriodo @PeriodoID = 3;
    PRINT 'PRUEBA G NO SUPERADA: la segunda ventana no quedo bloqueada.';
END TRY
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
    IF ERROR_NUMBER() = 1222
        PRINT 'PRUEBA G SUPERADA: la segunda sesion fue bloqueada.';
    ELSE
        PRINT 'PRUEBA G: error distinto; revisar si A seguia ejecutandose.';
END CATCH;
GO
 
SET LOCK_TIMEOUT -1; -- Restaurar la espera normal de SQL Server.
GO
 
-- Pruebas para procesar periodos pendientes
 
-- 4.1 a 4.3 Periodo vencido vs no vencido, curso sin ventas y sin periodos pendientes
-- Las tres pruebas se ejecutan en secuencia dentro de una transaccion que se revierte al final
BEGIN TRANSACTION;
BEGIN TRY
 
    -- 1. Procesar con referencia 21/10/2026. Solo septiembre se procesa, con 3 resúmenes
    EXEC usp_ProcesarPeriodosPendientes @FechaReferencia = '2026-10-21';
 
    SELECT PeriodoID, Anio, Mes, Estado FROM PERIODOLIQUIDACION ORDER BY Anio, Mes;
    SELECT UsuarioID, Mensaje FROM NOTIFICACION WHERE Tipo = 'RESUMEN_LIQUIDACION';
 
    -- 2. Procesar con referencia 05/12/2026. Noviembre se procesa con 0 resúmenes y 9 avisos sin ventas
    EXEC usp_ProcesarPeriodosPendientes @FechaReferencia = '2026-12-05';
 
    SELECT UsuarioID, CursoID, Mensaje
    FROM NOTIFICACION
    WHERE Tipo = 'CURSO_SIN_COMISIONES' AND Mensaje LIKE N'%11/2026%';
 
    -- 3. Procesar otra vez con la misma fecha. El resultado sale vacío
    EXEC usp_ProcesarPeriodosPendientes @FechaReferencia = '2026-12-05';
 
    -- 4. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'PRUEBAS 1 A 3 FINALIZADAS: cambios revertidos.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
-- 4.4 Varios periodos vencidos en un solo lote
BEGIN TRANSACTION;
BEGIN TRY
 
    -- 1. Procesar con referencia 05/01/2027. Septiembre, noviembre y diciembre se procesan en orden
    EXEC usp_ProcesarPeriodosPendientes @FechaReferencia = '2027-01-05';
 
    SELECT PeriodoID, Anio, Mes, Estado FROM PERIODOLIQUIDACION ORDER BY Anio, Mes;
 
    -- 2. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'PRUEBA 4 FINALIZADA: cambios revertidos.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
-- Pruebas de integracion y concurrencia
 
-- 5.1 Liquidacion de un periodo
BEGIN TRANSACTION;
BEGIN TRY
 
    -- 1. Liquidar septiembre
    EXEC usp_LiquidarPeriodo @PeriodoID = 3, @FechaReferencia = '2026-10-22';
 
    -- 2. Verificar el estado del periodo
    SELECT PeriodoID, Estado
    FROM PERIODOLIQUIDACION
    WHERE PeriodoID = 3;
 
    -- 3. Verificar las liquidaciones generadas
    SELECT *
    FROM LIQUIDACION
    WHERE PeriodoID = 3;
 
    -- 4. Verificar los saldos de los instructores
    SELECT UsuarioID, Saldo
    FROM BILLETERA
    WHERE UsuarioID IN (1, 2, 3);
 
    -- 5. Verificar el ajuste aplicado
    SELECT AjusteID, MontoPendiente
    FROM AJUSTECOMISION
    WHERE AjusteID = 1;
 
    -- 6. Revertir los cambios
    ROLLBACK TRANSACTION;
    PRINT 'PRUEBA FINALIZADA: cambios revertidos.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
 
END CATCH;
GO
 
-- 5.2 Prueba de procesamiento de periodos pendientes con fecha 22/10/2026
BEGIN TRANSACTION;
BEGIN TRY
 
    -- 1. Procesar los periodos pendientes
    EXEC usp_ProcesarPeriodosPendientes @FechaReferencia = '2026-10-22';
 
    -- 2. Verificar el estado de septiembre
    SELECT PeriodoID, Estado
    FROM PERIODOLIQUIDACION
    WHERE PeriodoID = 3;
 
    -- 3. Verificar las liquidaciones generadas
    SELECT *
    FROM LIQUIDACION
    WHERE PeriodoID = 3;
 
    -- 4. Verificar las notificaciones generadas
    SELECT NotificacionID, UsuarioID, CursoID, Tipo, Asunto, Mensaje
    FROM NOTIFICACION
    WHERE Tipo IN ('RESUMEN_LIQUIDACION', 'CURSO_SIN_COMISIONES')
    ORDER BY NotificacionID DESC;
 
    -- 5. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'PRUEBA DE PERIODOS PENDIENTES FINALIZADA: cambios revertidos.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
-- 5.3 Prueba de concurrencia 1: dos sesiones intentan bloquear el mismo periodo
 
-- Ventana 1
BEGIN TRANSACTION;
 
SELECT PeriodoID, Estado
FROM PERIODOLIQUIDACION WITH (UPDLOCK, HOLDLOCK)
WHERE PeriodoID = 3;
 
PRINT 'Periodo 3 bloqueado. No ejecutar COMMIT todavía.';
 
ROLLBACK TRANSACTION; -- Ejecutar después de la Ventana 2
 
-- Ventana 2
SET LOCK_TIMEOUT 5000;
 
BEGIN TRY
    BEGIN TRANSACTION;
 
    SELECT PeriodoID, Estado
    FROM PERIODOLIQUIDACION WITH (UPDLOCK, HOLDLOCK)
    WHERE PeriodoID = 3;
 
    COMMIT TRANSACTION;
 
    PRINT 'La segunda sesion obtuvo el bloqueo.';
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
 
SET LOCK_TIMEOUT -1;
 
-- 5.4 Prueba de concurrencia 2: liquidar un periodo mientras otra sesión lo mantiene bloqueado
 
-- Ventana 1
BEGIN TRANSACTION;
 
SELECT PeriodoID, Estado
FROM PERIODOLIQUIDACION WITH (UPDLOCK, HOLDLOCK)
WHERE PeriodoID = 3;
 
PRINT 'Periodo bloqueado por la Ventana 1.';
 
ROLLBACK TRANSACTION; -- Ejecutar después de la Ventana 2
 
-- Ventana 2
SET LOCK_TIMEOUT 5000;
 
BEGIN TRY
    BEGIN TRANSACTION;
 
    EXEC usp_LiquidarPeriodo @PeriodoID = 3, @FechaReferencia = '2026-10-22';
 
    -- Si llegara a ejecutarse, revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'Prueba finalizada: cambios revertidos.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
 
SET LOCK_TIMEOUT -1;
GO
 
-- 5.5 Prueba de concurrencia 3: prevención de liquidaciones duplicadas
-- Se ejecuta sin transacción externa para que la primera liquidación quede registrada
 
-- 1. Ejecutar la primera liquidación
EXEC usp_LiquidarPeriodo @PeriodoID = 3, @FechaReferencia = '2026-10-22';
GO
 
-- 2. Intentar liquidar el mismo periodo otra vez. Se espera el error 51602
BEGIN TRY
    EXEC usp_LiquidarPeriodo @PeriodoID = 3, @FechaReferencia = '2026-10-22';
    PRINT 'ERROR: Se permitio una segunda liquidacion.';
END TRY
 
BEGIN CATCH
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
-- 3. Verificar que exista una sola liquidación por instructor
SELECT PeriodoID, InstructorID, COUNT(*) AS CantidadLiquidaciones
FROM LIQUIDACION
WHERE PeriodoID = 3
GROUP BY PeriodoID, InstructorID;
GO
 
-- Restaurar 03, 05 y 07 antes de continuar, de lo contrario la verificación mostrará septiembre cerrado
 
-- Verificación del estado después de las pruebas de concurrencia
 
-- 1. Verificar las transacciones abiertas
SELECT @@TRANCOUNT AS TransaccionesAbiertas;
 
-- 2. Verificar el estado del periodo
SELECT PeriodoID, Estado
FROM PERIODOLIQUIDACION
WHERE PeriodoID = 3;
 
-- 3. Verificar las liquidaciones
SELECT COUNT(*) AS LiquidacionesRegistradas
FROM LIQUIDACION
WHERE PeriodoID = 3;
 
-- 4. Verificar los saldos
SELECT UsuarioID, Saldo
FROM BILLETERA
WHERE UsuarioID IN (1, 2, 3)
ORDER BY UsuarioID;
 
-- 5. Verificar el ajuste pendiente
SELECT AjusteID, MontoPendiente
FROM AJUSTECOMISION
WHERE AjusteID = 1;
 
-- 5.6 Prueba de concurrencia 4: una liquidación abierta bloquea a otra sesión
 
-- Ventana 1
BEGIN TRANSACTION;
 
-- 1. Liquidar septiembre
EXEC usp_LiquidarPeriodo @PeriodoID = 3, @FechaReferencia = '2026-10-22';
 
-- 2. Mantener la transacción abierta 30 segundos
WAITFOR DELAY '00:00:30';
 
-- 3. Revertir la liquidación de prueba
IF @@TRANCOUNT > 0
    ROLLBACK TRANSACTION;
 
PRINT 'VENTANA 1: prueba revertida.';
GO
 
-- Ventana 2
SET LOCK_TIMEOUT 5000;
 
BEGIN TRY
    BEGIN TRANSACTION;
 
    EXEC usp_LiquidarPeriodo @PeriodoID = 3, @FechaReferencia = '2026-10-22';
 
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'VENTANA 2: prueba revertida.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
 
SET LOCK_TIMEOUT -1;
GO
 
-- 5.7 Prueba de concurrencia 5: reembolso y nueva inscripción por el último cupo
 
-- Ventana 1: reembolso de Ricardo
SET LOCK_TIMEOUT 10000;
GO
 
DECLARE @ReembolsoID INT;
 
BEGIN TRY
    BEGIN TRANSACTION;
 
    -- 1. Ajustar la fecha solo para esta prueba
    UPDATE INSCRIPCION
    SET FechaInscripcion = GETDATE()
    WHERE InscripcionID = 21;
 
    -- 2. Crear la solicitud de reembolso
    EXEC usp_SolicitarReembolso
        @InscripcionID = 21,
        @Motivo = N'Prueba de concurrencia del último cupo',
        @ReembolsoID = @ReembolsoID OUTPUT;
 
    -- 3. Procesar el reembolso y liberar el cupo
    EXEC usp_ProcesarReembolso
        @ReembolsoID = @ReembolsoID,
        @PersonaAutoriza = 6;
 
    SELECT @ReembolsoID AS ReembolsoProcesado;
 
    -- 4. Mantener la transacción abierta
    WAITFOR DELAY '00:00:30';
 
    -- 5. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'VENTANA 1: prueba revertida.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError,
           ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
SET LOCK_TIMEOUT -1;
GO
 
-- Ventana 2: inscripción en el cupo liberado
SET LOCK_TIMEOUT 5000;
GO
 
DECLARE @NuevaInscripcionID INT;
 
BEGIN TRY
    BEGIN TRANSACTION;
 
    -- 1. Inscribir a otro estudiante en el mismo curso
    EXEC usp_InscribirEstudiante
        @UsuarioID = 9,
        @CursoID = 9,
        @CohorteID = 4,
        @InscripcionID = @NuevaInscripcionID OUTPUT;
 
    SELECT @NuevaInscripcionID AS NuevaInscripcionID;
 
    -- 2. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'VENTANA 2: prueba revertida.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
SET LOCK_TIMEOUT -1;
GO
 
-- 5.8 Integracion entre inscripcion y solicitud de reembolso
DECLARE @InscripcionID INT;
DECLARE @ReembolsoID INT;
 
BEGIN TRANSACTION;
BEGIN TRY
 
    -- 1. Inscribir a Ricardo
    EXEC usp_InscribirEstudiante @UsuarioID = 17, @CursoID = 1, @CohorteID = 2, @InscripcionID = @InscripcionID OUTPUT;
 
    SELECT @InscripcionID AS NuevaInscripcionID;
 
    -- 2. Verificar la inscripción
    SELECT InscripcionID, UsuarioID, CursoID, CohorteID, Estado, PrecioPagado
    FROM INSCRIPCION
    WHERE InscripcionID = @InscripcionID;
 
    -- 3. Verificar el descuento en la billetera
    SELECT UsuarioID, Saldo
    FROM BILLETERA
    WHERE UsuarioID = 17;
 
    -- 4. Solicitar el reembolso
    EXEC usp_SolicitarReembolso @InscripcionID = @InscripcionID, @Motivo = N'Prueba de integración de procedimientos', @ReembolsoID = @ReembolsoID OUTPUT;
 
    -- 5. Verificar la solicitud
    SELECT ReembolsoID, InscripcionID, Estado, PorcentajeAvance
    FROM SOLICITUDREEMBOLSO
    WHERE ReembolsoID = @ReembolsoID;
 
    -- 6. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'PRUEBA FINALIZADA: cambios revertidos.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
 
END CATCH;
GO
 
-- 5.9 Integracion completa: inscripcion, solicitud y procesamiento del reembolso
DECLARE @InscripcionID INT;
DECLARE @ReembolsoID INT;
 
BEGIN TRANSACTION;
BEGIN TRY
 
    -- 1. Inscribir a Ricardo
    EXEC usp_InscribirEstudiante @UsuarioID = 17, @CursoID = 1, @CohorteID = 2, @InscripcionID = @InscripcionID OUTPUT;
 
    SELECT @InscripcionID AS NuevaInscripcionID;
 
    -- 2. Verificar el saldo después de la inscripción
    SELECT UsuarioID, Saldo
    FROM BILLETERA
    WHERE UsuarioID = 17;
 
    -- 3. Solicitar el reembolso
    EXEC usp_SolicitarReembolso  @InscripcionID = @InscripcionID, @Motivo = N'Prueba de integración completa', @ReembolsoID = @ReembolsoID OUTPUT;
 
    -- 4. Procesar el reembolso
    EXEC usp_ProcesarReembolso @ReembolsoID = @ReembolsoID, @PersonaAutoriza = 6;
 
    -- 5. Verificar la inscripción
    SELECT InscripcionID, UsuarioID, Estado, Liquidada
    FROM INSCRIPCION
    WHERE InscripcionID = @InscripcionID;
 
    -- 6. Verificar la solicitud
    SELECT ReembolsoID, Estado, MontoReembolsado, PersonaQueAutoriza
    FROM SOLICITUDREEMBOLSO
    WHERE ReembolsoID = @ReembolsoID;
 
    -- 7. Verificar el saldo final
    SELECT UsuarioID, Saldo
    FROM BILLETERA
    WHERE UsuarioID = 17;
 
    -- 8. Verificar las operaciones de billetera
    SELECT TipoOperacion, Monto, InscripcionID, ReembolsoID
    FROM OPERACIONBILLETERA
    WHERE InscripcionID = @InscripcionID
       OR ReembolsoID = @ReembolsoID;
 
    -- 9. Verificar la notificación del reembolso
    SELECT UsuarioID, Tipo, Asunto
    FROM NOTIFICACION
    WHERE UsuarioID = 17 AND Tipo = 'REEMBOLSO' AND Asunto = 'Reembolso procesado';
 
    -- 10. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'PRUEBA COMPLETA FINALIZADA: cambios revertidos.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
-- 5.10 Contracargo: reembolso de una inscripcion ya liquidada
DECLARE @ReembolsoID INT;
 
BEGIN TRY
    BEGIN TRANSACTION;
 
    -- 1. Solicitar el reembolso de la inscripción liquidada
    EXEC usp_SolicitarReembolso @InscripcionID = 31, @Motivo = N'Prueba de contracargos', @ReembolsoID = @ReembolsoID OUTPUT;
 
    SELECT @ReembolsoID AS NuevoReembolsoID;
 
    -- 2. Procesar el reembolso
    EXEC usp_ProcesarReembolso @ReembolsoID = @ReembolsoID, @PersonaAutoriza = 6;
 
    -- 3. Verificar la inscripción
    SELECT InscripcionID, Estado, Liquidada
    FROM INSCRIPCION
    WHERE InscripcionID = 31;
 
    -- 4. Verificar la solicitud
    SELECT ReembolsoID, Estado, MontoReembolsado
    FROM SOLICITUDREEMBOLSO
    WHERE ReembolsoID = @ReembolsoID;
 
    -- 5. Verificar el saldo de Elisa
    SELECT UsuarioID, Saldo
    FROM BILLETERA
    WHERE UsuarioID = 23;
 
    -- 6. Verificar los nuevos contracargos
    SELECT AjusteID, ReembolsoID, InstructorID, MontoOriginal, MontoPendiente
    FROM AJUSTECOMISION
    WHERE ReembolsoID = @ReembolsoID;
 
    -- 7. Verificar las notificaciones de contracargo
    SELECT UsuarioID, Tipo, Asunto
    FROM NOTIFICACION
    WHERE Tipo = 'CONTRACARGO'
      AND UsuarioID IN (1, 2);
 
    -- 8. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'PRUEBA DE CONTRACARGOS FINALIZADA: cambios revertidos.';
 
END TRY
 
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT ERROR_NUMBER() AS NumeroError, ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO
 
-- 5.11 Aplicacion de contracargo en la siguiente liquidacion
BEGIN TRY
    BEGIN TRANSACTION;
 
    -- 1. Consultar el ajuste antes de liquidar
    SELECT
        AjusteID,
        InstructorID,
        MontoOriginal,
        MontoPendiente
    FROM AJUSTECOMISION
    WHERE AjusteID = 1;
 
    -- 2. Liquidar septiembre
    EXEC usp_LiquidarPeriodo
        @PeriodoID = 3,
        @FechaReferencia = '2026-10-22';
 
    -- 3. Verificar el ajuste después de liquidar
    SELECT
        AjusteID,
        InstructorID,
        MontoOriginal,
        MontoPendiente
    FROM AJUSTECOMISION
    WHERE AjusteID = 1;
 
    -- 4. Verificar los descuentos registrados
    SELECT
        L.LiquidacionID,
        L.InstructorID,
        D.TipoDetalle,
        D.Monto,
        D.AjusteID
    FROM LIQUIDACION L
    INNER JOIN DETALLELIQUIDACION D
        ON D.LiquidacionID = L.LiquidacionID
    WHERE L.PeriodoID = 3
      AND D.TipoDetalle = 'AJUSTE';
 
    -- 5. Verificar los pagos realizados
    SELECT
        L.InstructorID,
        L.Estado,
        O.TipoOperacion,
        O.Monto
    FROM LIQUIDACION L
    INNER JOIN OPERACIONBILLETERA O
        ON O.LiquidacionID = L.LiquidacionID
    WHERE L.PeriodoID = 3
      AND O.TipoOperacion = 'PAGO_COMISION';
 
    -- 6. Revertir los cambios
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    PRINT 'PRUEBA DE APLICACION DE CONTRACARGO FINALIZADA: cambios revertidos.';
 
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
 
    SELECT
        ERROR_NUMBER() AS NumeroError,
        ERROR_MESSAGE() AS MensajeError;
END CATCH;
GO