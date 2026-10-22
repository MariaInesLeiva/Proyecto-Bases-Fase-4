# EduGT - Fase 4

Proyecto de Bases de Datos II · Sección 02 · Universidad Rafael Landívar

Catedrática: Ing. Diana Gutiérrez · Guatemala, 22 de octubre de 2026

| Integrante | Carné |
|---|---|
| Axel Guillermo Alvarado Taracena | 1284724 |
| Diego Andrés Díaz Estupiñan | 1214024 |
| María Inés Leiva Casiano | 1089524 |
| Javier Alessandro Rivera Lemus | 1241224 |
| Jennifer Fernanda Turcios Estrada | 1088724 |

## Antes de empezar

- Seleccionar la base de datos `EduGT` en SQL Server Management Studio antes de ejecutar los scripts.
- Respetar el orden de ejecución indicado a continuación.

## Orden de ejecución

Para ejecutar correctamente el proyecto EduGT, se deben ejecutar los siguientes archivos SQL en el orden indicado:

| # | Archivo | Descripción |
|---|---|---|
| 1 | `01_CreacionBD.sql` | Crea la estructura de la base de datos, tablas, relaciones y restricciones. |
| 2 | `02_Fase2Procedimientos.sql` | Crea los procedimientos almacenados de la Fase II. |
| 3 | `03_EduGT_Datos_Prueba.sql` | Carga los datos iniciales de prueba. |
| 4 | `05_Datos_Prueba_Fase3.sql` | Agrega los datos de prueba de la Fase III. |
| 5 | `06_Objetos_Fase3.sql` | Crea los objetos desarrollados en la Fase III. |
| 6 | `07_Datos_Prueba_Fase4.sql` | Agrega los datos de prueba de la Fase IV. |
| 7 | `08_Objetos_Fase4.sql` | Crea los procedimientos y objetos de la Fase IV. |
| 8 | `09_Pruebas_Fase4.sql` | Ejecuta las pruebas de funcionamiento de la Fase IV. |

### Notas importantes

- Los scripts de datos de prueba deben ejecutarse una sola vez para evitar conflictos por registros duplicados.
- Algunas pruebas modifican los datos, por lo que deben ejecutarse en el orden establecido.
- Los errores esperados en las pruebas de validación aparecen en la pestaña **Mensajes** de SSMS.

**Nota:** El archivo `04_Casos_de_Prueba.sql.sql` corresponde a las pruebas de fases anteriores y no es necesario ejecutarlo para esta fase.

