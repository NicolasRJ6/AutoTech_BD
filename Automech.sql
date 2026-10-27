-- ==========================================================
-- EVALUACIÓN 2: TABLAS AUXILIARES (AUTO-TECH SERVICES)
-- ==========================================================

-- 1. Eliminar tablas previas si existieran
BEGIN
    EXECUTE IMMEDIATE 'DROP TABLE LOG_AUDITORIA CASCADE CONSTRAINTS';
    EXECUTE IMMEDIATE 'DROP TABLE HISTORICO_PAGOS CASCADE CONSTRAINTS';
EXCEPTION
    WHEN OTHERS THEN NULL;
END;
/

-- 2. Tabla para almacenar las liquidaciones que generarán los PROCEDIMIENTOS
CREATE TABLE HISTORICO_PAGOS (
    id_pago         NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    id_mecanico     NUMBER(4) NOT NULL,
    mes             NUMBER(2) NOT NULL,
    anio            NUMBER(4) NOT NULL,
    sueldo_base     NUMBER(9) NOT NULL,
    bono_comision   NUMBER(9) NOT NULL,
    sueldo_total    NUMBER(9) NOT NULL,
    fecha_proceso   DATE DEFAULT SYSDATE,
    CONSTRAINT fk_pago_mecanico FOREIGN KEY (id_mecanico) REFERENCES MECANICO(id_mecanico)
);

-- 3. Tabla para registrar los eventos que capturarán los TRIGGERS
CREATE TABLE LOG_AUDITORIA (
    id_log          NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tabla_afectada  VARCHAR2(30) NOT NULL,
    tipo_operacion  VARCHAR2(10) NOT NULL, -- INSERT, UPDATE o DELETE
    nivel_trigger   VARCHAR2(15) NOT NULL, -- FILA o SENTENCIA
    usuario_oracle  VARCHAR2(30) NOT NULL,
    fecha_evento    DATE DEFAULT SYSDATE,
    detalle         VARCHAR2(200)
);

COMMIT;

-- ==========================================================
-- 1. FUNCIÓN CON PARÁMETROS: FN_CALCULAR_PORCENTAJE_BONO
-- Propósito: Recibe el monto recaudado y devuelve el factor del bono(5%,10%o15%)
-- ==========================================================
CREATE OR REPLACE FUNCTION FN_CALCULAR_PORCENTAJE_BONO (
    p_monto_recaudado NUMBER
) RETURN NUMBER IS
    v_porcentaje NUMBER(4,2) := 0;
BEGIN
    IF p_monto_recaudado IS NULL OR p_monto_recaudado <= 0 THEN
        v_porcentaje := 0.00;
    ELSIF p_monto_recaudado >= 500000 THEN
        v_porcentaje := 0.15; -- 15% Tramo Alto
    ELSIF p_monto_recaudado >= 250000 THEN
        v_porcentaje := 0.10; -- 10% Tramo Medio
    ELSE
        v_porcentaje := 0.05; -- 5% Tramo Base
    END IF;

    RETURN v_porcentaje;
END FN_CALCULAR_PORCENTAJE_BONO;
/

-- ==========================================================
-- 2. FUNCIÓN SIN PARÁMETROS: FN_OBTENER_IVA
-- Propósito: Devuelve la tasa fija del IVA (19%) del negocio para 
-- no quemar números en el código
-- ==========================================================
CREATE OR REPLACE FUNCTION FN_OBTENER_IVA 
RETURN NUMBER IS
    v_iva CONSTANT NUMBER(3,2) := 0.19;
BEGIN
    RETURN v_iva;
END FN_OBTENER_IVA;
/
-- Demostración de ambas funciones usadas directamente en SQL:
SELECT 
    id_detalle,
    descripcion,
    costo_mano_obra,
    ROUND(costo_mano_obra * FN_OBTENER_IVA) AS impuesto_iva,
    FN_CALCULAR_PORCENTAJE_BONO(costo_mano_obra) AS factor_bono
FROM DETALLE_SERVICIO;



-- ==========================================================
-- 3. PROCEDIMIENTO CON PARÁMETROS: SP_LIQUIDAR_MECANICO
-- Propósito: Recibe ID de mecánico, mes y año. Calcula sueldo y lo guarda en HISTORICO_PAGOS
-- ==========================================================
CREATE OR REPLACE PROCEDURE SP_LIQUIDAR_MECANICO (
    p_id_mec   NUMBER,
    p_mes      NUMBER,
    p_anio     NUMBER
) IS
    v_sueldo_base     MECANICO.sueldo_base%TYPE;
    v_total_recaudado NUMBER := 0;
    v_pct_bono        NUMBER := 0;
    v_monto_bono      NUMBER := 0;
    v_sueldo_final    NUMBER := 0;
BEGIN
    -- Obtener sueldo base del mecánico
    SELECT sueldo_base INTO v_sueldo_base
    FROM MECANICO
    WHERE id_mecanico = p_id_mec;

    -- Calcular total facturado por el mecánico en el periodo
    SELECT NVL(SUM(d.costo_mano_obra + d.costo_repuestos), 0)
    INTO v_total_recaudado
    FROM ORDEN_SERVICIO o
    INNER JOIN DETALLE_SERVICIO d ON o.id_orden = d.id_orden
    WHERE o.id_mecanico = p_id_mec
      AND EXTRACT(MONTH FROM o.fecha) = p_mes
      AND EXTRACT(YEAR FROM o.fecha) = p_anio;

    -- Llamar a nuestra FUNCIÓN para obtener el porcentaje de bono
    v_pct_bono := FN_CALCULAR_PORCENTAJE_BONO(v_total_recaudado);
    v_monto_bono := ROUND(v_total_recaudado * v_pct_bono);
    v_sueldo_final := v_sueldo_base + v_monto_bono;

    -- Guardar de forma persistente en la tabla HISTORICO_PAGOS
    INSERT INTO HISTORICO_PAGOS (
        id_mecanico, mes, anio, sueldo_base, bono_comision, sueldo_total, fecha_proceso
    ) VALUES (
        p_id_mec, p_mes, p_anio, v_sueldo_base, v_monto_bono, v_sueldo_final, SYSDATE
    );

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Mecánico ID ' || p_id_mec || ' liquidado exitosamente. Total: $' || v_sueldo_final);
END SP_LIQUIDAR_MECANICO;
/

-- ==========================================================
-- 4. PROCEDIMIENTO SIN PARÁMETROS: SP_PROCESO_MASIVO_CIERRE
-- Propósito: Recorre a TODOS los mecánicos activos y los liquida masivamente
-- ==========================================================
CREATE OR REPLACE PROCEDURE SP_PROCESO_MASIVO_CIERRE IS
    v_mes_actual  NUMBER := EXTRACT(MONTH FROM SYSDATE);
    v_anio_actual NUMBER := EXTRACT(YEAR FROM SYSDATE);

    -- Cursor que trae todos los mecánicos activos
    CURSOR c_activos IS
        SELECT id_mecanico FROM MECANICO WHERE UPPER(estado) = 'ACTIVO';
BEGIN
    DBMS_OUTPUT.PUT_LINE('>>> INICIANDO PROCESO MASIVO DE CIERRE MENSUAL <<<');

    -- Para pruebas usamos Mayo 2024 (Mes 5) que es donde tenemos órdenes
    FOR r IN c_activos LOOP
        -- Llama al procedimiento con parámetros por cada mecánico
        SP_LIQUIDAR_MECANICO(r.id_mecanico, 5, 2024);
    END LOOP;

    DBMS_OUTPUT.PUT_LINE('>>> PROCESO MASIVO FINALIZADO CON ÉXITO <<<');
END SP_PROCESO_MASIVO_CIERRE;
/

-- Probar el procedimiento masivo (sin parámetros):
BEGIN
    SP_PROCESO_MASIVO_CIERRE;
END;
/

-- Comprobar que los datos quedaron guardados de verdad en la tabla:
SELECT * FROM HISTORICO_PAGOS;

-- ==========================================================
-- 5. ESPECIFICACIÓN DEL PACKAGE (PARTE PÚBLICA)
-- Aquí solo se declaran los elementos que otros usuarios pueden ver y usar
-- ==========================================================
CREATE OR REPLACE PACKAGE PKG_REMUNERACIONES_AUTOTECH IS
    -- Variable pública del paquete
    v_version_sistema CONSTANT VARCHAR2(10) := 'v2.0';

    -- Procedimiento público accesible desde fuera
    PROCEDURE SP_PROCESAR_NOMINA_MES(p_mes NUMBER, p_anio NUMBER);

    -- Función pública accesible desde fuera (o desde un SELECT)
    FUNCTION FN_OBTENER_TOTAL_ORDENES(p_id_mec NUMBER) RETURN NUMBER;
END PKG_REMUNERACIONES_AUTOTECH;
/
-- ==========================================================
-- 6. CUERPO DEL PACKAGE (BODY: LÓGICA + ELEMENTOS PRIVADOS)
-- ==========================================================
CREATE OR REPLACE PACKAGE BODY PKG_REMUNERACIONES_AUTOTECH IS
    -- ELEMENTO PRIVADO (No está en la especificación pública):
    -- Función interna que valida si el mecánico está activo.
    -- Solo puede ser llamada desde adentro de este Package.
    FUNCTION FN_ES_MECANICO_ACTIVO(p_id_mec NUMBER) RETURN BOOLEAN IS
        v_estado VARCHAR2(15);
    BEGIN
        SELECT estado INTO v_estado FROM MECANICO WHERE id_mecanico = p_id_mec;
        RETURN (UPPER(v_estado) = 'ACTIVO');
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN FALSE;
    END FN_ES_MECANICO_ACTIVO;

    -- Implementación de la función pública
    FUNCTION FN_OBTENER_TOTAL_ORDENES(p_id_mec NUMBER) RETURN NUMBER IS
        v_cant NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO v_cant FROM ORDEN_SERVICIO WHERE id_mecanico = p_id_mec;
        RETURN v_cant;
    END FN_OBTENER_TOTAL_ORDENES;

    -- Implementación del procedimiento público
    PROCEDURE SP_PROCESAR_NOMINA_MES(p_mes NUMBER, p_anio NUMBER) IS
        CURSOR c_mec IS SELECT id_mecanico, nombre FROM MECANICO;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('--- EJECUTANDO PKG_REMUNERACIONES_AUTOTECH (' || v_version_sistema || ') ---');
        
        FOR r IN c_mec LOOP
            -- USAMOS LA FUNCIÓN PRIVADA PARA VALIDAR:
            IF FN_ES_MECANICO_ACTIVO(r.id_mecanico) THEN
                -- Si está activo, lo liquidamos
                SP_LIQUIDAR_MECANICO(r.id_mecanico, p_mes, p_anio);
            ELSE
                DBMS_OUTPUT.PUT_LINE('Mecánico ' || r.nombre || ' [INACTIVO] - Omitido por el sistema.');
            END IF;
        END LOOP;
        
        DBMS_OUTPUT.PUT_LINE('--- NÓMINA FINALIZADA EXITOSAMENTE DESDE PACKAGE ---');
    END SP_PROCESAR_NOMINA_MES;

END PKG_REMUNERACIONES_AUTOTECH;
/
-- 1. Probar la función pública del paquete directamente en SQL:
SELECT id_mecanico, nombre, PKG_REMUNERACIONES_AUTOTECH.FN_OBTENER_TOTAL_ORDENES(id_mecanico) AS total_atenciones
FROM MECANICO;

-- 2. Probar el procedimiento público del paquete:
BEGIN
    PKG_REMUNERACIONES_AUTOTECH.SP_PROCESAR_NOMINA_MES(5, 2024);
END;
/

-- ==========================================================
-- 7. TRIGGER A NIVEL DE FILA (FOR EACH ROW)
-- Se dispara por CADA fila modificada o borrada en ORDEN_SERVICIO.
-- Guarda los datos antiguos con :OLD para auditoría contra fraudes.
-- ==========================================================
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_ORDEN_FILA
AFTER UPDATE OR DELETE ON ORDEN_SERVICIO
FOR EACH ROW
DECLARE
    v_tipo VARCHAR2(10);
BEGIN
    IF UPDATING THEN
        v_tipo := 'UPDATE';
    ELSIF DELETING THEN
        v_tipo := 'DELETE';
    END IF;

    -- Guarda el registro en la tabla LOG_AUDITORIA
    INSERT INTO LOG_AUDITORIA (
        tabla_afectada, tipo_operacion, nivel_trigger, usuario_oracle, fecha_evento, detalle
    ) VALUES (
        'ORDEN_SERVICIO', 
        v_tipo, 
        'FILA', 
        USER, 
        SYSDATE, 
        'Orden ID: ' || :OLD.id_orden || ' | Mecánico asignado previo: ' || :OLD.id_mecanico || ' | Estado previo: ' || :OLD.estado
    );
END TRG_AUDITORIA_ORDEN_FILA;
/

-- ==========================================================
-- 8. TRIGGER A NIVEL DE SENTENCIA (STATEMENT LEVEL)
-- Se dispara UNA SOLA VEZ por cada instrucción SQL en DETALLE_SERVICIO,
-- sin importar si afectó a 1 o a 1000 filas.
-- ==========================================================
CREATE OR REPLACE TRIGGER TRG_AUDITORIA_DETALLE_SENTENCIA
AFTER INSERT OR UPDATE OR DELETE ON DETALLE_SERVICIO
DECLARE
    v_operacion VARCHAR2(10);
BEGIN
    IF INSERTING THEN
        v_operacion := 'INSERT';
    ELSIF UPDATING THEN
        v_operacion := 'UPDATE';
    ELSIF DELETING THEN
        v_operacion := 'DELETE';
    END IF;

    -- Registra que se ejecutó una operación masiva a nivel de tabla
    INSERT INTO LOG_AUDITORIA (
        tabla_afectada, tipo_operacion, nivel_trigger, usuario_oracle, fecha_evento, detalle
    ) VALUES (
        'DETALLE_SERVICIO',
        v_operacion,
        'SENTENCIA',
        USER,
        SYSDATE,
        'Se ejecutó una sentencia masiva de tipo ' || v_operacion || ' en la tabla de detalles.'
    );
END TRG_AUDITORIA_DETALLE_SENTENCIA;
/

-- Prueba 1: Modificamos una orden para disparar el Trigger de FILA
UPDATE ORDEN_SERVICIO 
SET estado = 'FACTURADA' 
WHERE id_orden = 5001;

-- Prueba 2: Modificamos los detalles para disparar el Trigger de SENTENCIA
UPDATE DETALLE_SERVICIO 
SET costo_mano_obra = costo_mano_obra + 1000 
WHERE id_orden = 5001;

COMMIT;

-- Comprobar que ambos triggers escribieron en la tabla de auditoría:
SELECT * FROM LOG_AUDITORIA;

