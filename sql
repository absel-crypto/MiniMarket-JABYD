-- ======================================================
-- 📦 Base de Datos: inventariodb
-- Proyecto: MiniMarket JABYD
-- ======================================================

CREATE DATABASE IF NOT EXISTS inventariodb 
  DEFAULT CHARACTER SET utf8mb4 
  COLLATE utf8mb4_0900_ai_ci;
USE inventariodb;

-- ======================================================
-- TABLA: categoria
-- ======================================================
DROP TABLE IF EXISTS categoria;
CREATE TABLE categoria (
  id_categoria INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL UNIQUE,
  descripcion TEXT
) ENGINE=InnoDB;

INSERT INTO categoria (nombre, descripcion) VALUES
('Lácteos','Productos derivados de la leche.'),
('Bebidas','Refrescos, jugos, aguas y energizantes.'),
('Snacks','Galletas, papas fritas, dulces y golosinas.'),
('Aseo','Productos de limpieza y cuidado personal.'),
('Granos','Arroz, fríjoles, lentejas y similares.'),
('Enlatados','Alimentos y conservas enlatadas.');

-- ======================================================
-- TABLA: proveedor
-- ======================================================
DROP TABLE IF EXISTS proveedor;
CREATE TABLE proveedor (
  id_proveedor INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  direccion TEXT,
  telefono VARCHAR(50),
  correo VARCHAR(150) UNIQUE
) ENGINE=InnoDB;

-- ======================================================
-- TABLA: cliente
-- ======================================================
DROP TABLE IF EXISTS cliente;
CREATE TABLE cliente (
  id_cliente INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  tipo_cliente ENUM('INDIVIDUAL','EMPRESA') NOT NULL,
  identificacion VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- ======================================================
-- TABLA: usuario
-- ======================================================
DROP TABLE IF EXISTS usuario;
CREATE TABLE usuario (
  id_usuario INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(100) NOT NULL,
  apellido VARCHAR(100) NOT NULL,
  username VARCHAR(50) NOT NULL UNIQUE,
  correo VARCHAR(150) NOT NULL UNIQUE,
  password VARCHAR(255) NOT NULL,
  tipo ENUM('EMPLEADO','ADMINISTRADOR') DEFAULT 'EMPLEADO',
  activo TINYINT(1) DEFAULT 1
) ENGINE=InnoDB;

-- ======================================================
-- TABLA: producto
-- ======================================================
DROP TABLE IF EXISTS producto;
CREATE TABLE producto (
  id_producto INT AUTO_INCREMENT PRIMARY KEY,
  nombre VARCHAR(150) NOT NULL,
  descripcion TEXT,
  precio DECIMAL(10,2) NOT NULL CHECK (precio > 0),
  id_categoria INT NOT NULL,
  id_proveedor INT,
  stock_minimo INT DEFAULT 5,
  activo TINYINT(1) DEFAULT 1,
  estado VARCHAR(50) DEFAULT 'Activo',
  FOREIGN KEY (id_categoria) REFERENCES categoria(id_categoria),
  FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor)
) ENGINE=InnoDB;

-- TRIGGER: cuando se inserta un producto → se crea en inventario
DELIMITER //
CREATE TRIGGER after_insert_producto
AFTER INSERT ON producto
FOR EACH ROW
BEGIN
  INSERT INTO inventario (id_producto, producto_nombre, ingreso, salida, stock_actual)
  VALUES (NEW.id_producto, NEW.nombre, 0, 0, 0);
END;
//
DELIMITER ;

-- ======================================================
-- TABLA: inventario
-- ======================================================
DROP TABLE IF EXISTS inventario;
CREATE TABLE inventario (
  id_inventario INT AUTO_INCREMENT PRIMARY KEY,
  id_producto INT NOT NULL,
  producto_nombre VARCHAR(150) NOT NULL,
  ingreso INT DEFAULT 0,
  salida INT DEFAULT 0,
  stock_actual INT DEFAULT 0,
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
) ENGINE=InnoDB;

-- ======================================================
-- TABLAS DE MOVIMIENTOS
-- ======================================================
DROP TABLE IF EXISTS ingresoinventario;
CREATE TABLE ingresoinventario (
  id_ingreso INT AUTO_INCREMENT PRIMARY KEY,
  fecha DATE NOT NULL,
  id_proveedor INT,
  id_usuario INT,
  FOREIGN KEY (id_proveedor) REFERENCES proveedor(id_proveedor),
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS salidainventario;
CREATE TABLE salidainventario (
  id_salida INT AUTO_INCREMENT PRIMARY KEY,
  fecha DATE NOT NULL,
  id_usuario INT,
  id_cliente INT,
  FOREIGN KEY (id_usuario) REFERENCES usuario(id_usuario),
  FOREIGN KEY (id_cliente) REFERENCES cliente(id_cliente)
) ENGINE=InnoDB;

-- ======================================================
-- DETALLES DE MOVIMIENTOS
-- ======================================================
DROP TABLE IF EXISTS detalle_ingreso;
CREATE TABLE detalle_ingreso (
  id_detalle_ingreso INT AUTO_INCREMENT PRIMARY KEY,
  id_ingreso INT NOT NULL,
  id_producto INT NOT NULL,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  FOREIGN KEY (id_ingreso) REFERENCES ingresoinventario(id_ingreso),
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
) ENGINE=InnoDB;

-- Trigger: actualizar stock al ingresar producto
DELIMITER //
CREATE TRIGGER after_insert_detalle_ingreso
AFTER INSERT ON detalle_ingreso
FOR EACH ROW
BEGIN
  UPDATE inventario
  SET ingreso = ingreso + NEW.cantidad,
      stock_actual = stock_actual + NEW.cantidad
  WHERE id_producto = NEW.id_producto;
END;
//
DELIMITER ;

DROP TABLE IF EXISTS detalle_salida;
CREATE TABLE detalle_salida (
  id_detalle_salida INT AUTO_INCREMENT PRIMARY KEY,
  id_salida INT NOT NULL,
  id_producto INT NOT NULL,
  cantidad INT NOT NULL CHECK (cantidad > 0),
  FOREIGN KEY (id_salida) REFERENCES salidainventario(id_salida),
  FOREIGN KEY (id_producto) REFERENCES producto(id_producto)
) ENGINE=InnoDB;

-- Trigger: actualizar stock al vender producto
DELIMITER //
CREATE TRIGGER after_insert_detalle_salida
AFTER INSERT ON detalle_salida
FOR EACH ROW
BEGIN
  UPDATE inventario
  SET salida = salida + NEW.cantidad,
      stock_actual = stock_actual - NEW.cantidad
  WHERE id_producto = NEW.id_producto;
END;
//
DELIMITER ;

-- ======================================================
-- PROCEDIMIENTOS ALMACENADOS
-- ======================================================

-- Buscar producto por nombre o descripción
DELIMITER //
CREATE PROCEDURE BuscarProducto(IN text_param VARCHAR(255))
BEGIN
  SELECT * FROM producto
  WHERE nombre LIKE CONCAT('%', text_param, '%')
     OR descripcion LIKE CONCAT('%', text_param, '%');
END;
//
DELIMITER ;

-- Consultar inventario por nombre
DELIMITER //
CREATE PROCEDURE BuscarInventario(IN text_param VARCHAR(255))
BEGIN
  SELECT * FROM inventario
  WHERE producto_nombre LIKE CONCAT('%', text_param, '%')
     OR id_producto = text_param;
END;
//
DELIMITER ;

-- Movimientos generales
DELIMITER //
CREATE PROCEDURE MovimientoProductoGeneral()
BEGIN
  SELECT p.id_producto, i.fecha, p.nombre, di.cantidad, pr.nombre AS proveedor, 'Ingreso' AS movimiento
  FROM producto p
  INNER JOIN detalle_ingreso di ON p.id_producto = di.id_producto
  INNER JOIN ingresoinventario i ON di.id_ingreso = i.id_ingreso
  INNER JOIN proveedor pr ON i.id_proveedor = pr.id_proveedor
  UNION ALL
  SELECT p.id_producto, s.fecha, p.nombre, ds.cantidad, c.nombre AS cliente, 'Salida' AS movimiento
  FROM producto p
  INNER JOIN detalle_salida ds ON p.id_producto = ds.id_producto
  INNER JOIN salidainventario s ON ds.id_salida = s.id_salida
  INNER JOIN cliente c ON s.id_cliente = c.id_cliente
  ORDER BY fecha;
END;
//
DELIMITER ;
