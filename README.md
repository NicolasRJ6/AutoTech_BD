# AutoTech_BD

# Sistema de Gestión y Remuneraciones AutoTech 🚗 🔧

Este es mi proyecto para la asignatura Taller de Base de Datos, abarcando tanto la arquitectura relacional en **Oracle PL/SQL** (Evaluación 2) como la implementación documental en **MongoDB NoSQL** (Evaluación 3).

## ¿De qué trata?

Es un sistema desarrollado para automatizar la operación del taller mecánico **"AutoTech Services Ltda."**, pasando de planillas manuales en Excel a una solución robusta en dos etapas:

* **Etapa Relacional (Oracle 21c):** Automatiza el cálculo de sueldos y bonos de los mecánicos (tramos del 5%, 10% y 15%) mediante Funciones, Procedimientos, un Package público/privado y Triggers de auditoría.
* **Etapa No Relacional (MongoDB Atlas):** Migra la gestión de órdenes de trabajo a un modelo orientado a documentos (`autotech_db` / `ordenes_servicios`), agrupando cliente, mecánico, detalles de reparación y totales en un solo JSON para evitar cruces (`JOIN`) y agilizar las operaciones CRUD.

## Archivos del proyecto

* `EV3_BD_MONGO/` : Carpeta de la Evaluación 3 con el modelo documental JSON, el script de consultas y operaciones CRUD en `mongosh`, el informe técnico y la presentación.
* `Automech.sql` : Script de la Evaluación 2 en Oracle con la creación de tablas, Funciones, Procedimientos, un Package público/privado y los Triggers de auditoría.
* `InformeBD.docx` : Informe técnico de la etapa relacional explicando cómo funciona el código, el uso de cursores complejos y las decisiones que tomé.
* `Sistema AutoTech - Taller de BD.pptx` : Presentación de apoyo de la Evaluación 2 para explicar el código y mostrar que el cierre de mes toma solo fracciones de segundo.
