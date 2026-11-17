use("autotech_db");

// CREATE (Individual)
db.ordenes_servicios.insertOne({
  "_id": "ORD-5001",
  "fecha_ingreso": "2024-05-10T09:00:00Z",
  "estado": "TERMINADA",
  "cliente": { "rut": "12345678-9", "nombre": "Juan Pérez", "tipo_cliente": "PARTICULAR" },
  "mecanico_asignado": { "id_mecanico": 101, "nombre": "Carlos Morales", "especialidad": "Frenos" },
  "detalles_servicio": [
    { "descripcion": "Cambio de pastillas y discos", "costo_mano_obra": 86000, "costo_repuestos": 120000 },
    { "descripcion": "Reparación de alternador", "costo_mano_obra": 60000, "costo_repuestos": 45000 }
  ],
  "totales": { "subtotal_mano_obra": 146000, "subtotal_repuestos": 165000, "total_neto": 311000, "iva": 59090, "total_facturado": 370090 }
});

// CREATE (Masivo)
db.ordenes_servicios.insertMany([
  {
    "_id": "ORD-5002",
    "fecha_ingreso": "2024-05-11T10:30:00Z",
    "estado": "FACTURADA",
    "cliente": { "rut": "9876543-2", "nombre": "María González", "tipo_cliente": "EMPRESA" },
    "mecanico_asignado": { "id_mecanico": 102, "nombre": "Andrea Valenzuela", "especialidad": "Transmisión" },
    "detalles_servicio": [{ "descripcion": "Cambio de embrague", "costo_mano_obra": 180000, "costo_repuestos": 250000 }],
    "totales": { "subtotal_mano_obra": 180000, "subtotal_repuestos": 250000, "total_neto": 430000, "iva": 81700, "total_facturado": 511700 }
  },
  {
    "_id": "ORD-5003",
    "fecha_ingreso": "2024-05-12T08:15:00Z",
    "estado": "EN PROCESO",
    "cliente": { "rut": "11223344-5", "nombre": "Pedro Rojas", "tipo_cliente": "PARTICULAR" },
    "mecanico_asignado": { "id_mecanico": 103, "nombre": "Felipe Soto", "especialidad": "Suspensión" },
    "detalles_servicio": [{ "descripcion": "Reparación de amortiguadores", "costo_mano_obra": 110000, "costo_repuestos": 90000 }],
    "totales": { "subtotal_mano_obra": 110000, "subtotal_repuestos": 90000, "total_neto": 200000, "iva": 38000, "total_facturado": 238000 }
  },
  {
    "_id": "ORD-5004",
    "fecha_ingreso": "2024-05-14T14:00:00Z",
    "estado": "TERMINADA",
    "cliente": { "rut": "15678901-3", "nombre": "Transportes Sur Ltda.", "tipo_cliente": "EMPRESA" },
    "mecanico_asignado": { "id_mecanico": 104, "nombre": "Rodrigo Silva", "especialidad": "Motor" },
    "detalles_servicio": [{ "descripcion": "Ajuste de distribución", "costo_mano_obra": 250000, "costo_repuestos": 150000 }],
    "totales": { "subtotal_mano_obra": 250000, "subtotal_repuestos": 150000, "total_neto": 400000, "iva": 76000, "total_facturado": 476000 }
  },
  {
    "_id": "ORD-5005",
    "fecha_ingreso": "2024-05-15T16:45:00Z",
    "estado": "CANCELADA",
    "cliente": { "rut": "18456123-7", "nombre": "Luis Contreras", "tipo_cliente": "PARTICULAR" },
    "mecanico_asignado": { "id_mecanico": 101, "nombre": "Carlos Morales", "especialidad": "Frenos" },
    "detalles_servicio": [{ "descripcion": "Revisión general de frenos", "costo_mano_obra": 50000, "costo_repuestos": 0 }],
    "totales": { "subtotal_mano_obra": 50000, "subtotal_repuestos": 0, "total_neto": 50000, "iva": 9500, "total_facturado": 59500 }
  }
]);

// READ
db.ordenes_servicios.find();
db.ordenes_servicios.find({ "mecanico_asignado.nombre": "Andrea Valenzuela" });

// UPDATE
db.ordenes_servicios.updateOne({ "_id": "ORD-5003" }, { $set: { "estado": "TERMINADA" } });

// DELETE
db.ordenes_servicios.deleteOne({ "_id": "ORD-5005" });